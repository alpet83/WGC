unit TlHelpEx;

interface
uses TlHelp32, SysUtils, Windows, SimpleArray, PSLists, ChConst;
(*----------------------------
  В данном модуле механизмы TlHelp реализуется в виде
  класса.
 -----------------------------*)
 {$WARN IMPLICIT_STRING_CAST OFF}

const
    // флажки включения процессов в список
    PMF_INVISIBLE       = $0001;
    PMF_CHILDWND        = $0002;
    PMF_VOIDCAP         = $0004;
    PMF_WNDLESS         = $0008;
    PMF_ADDPID          = $0010;

type

     TPsNotifyHandler = procedure (dwPID: DWORD) of object;

     TTlh32 = object
     private
      flags: dword;
      _srcpid: dword;
     public
      Handle : THandle;
      procedure              Init (dwFlags : dword; SrcPid : dword = 0);
      function               ModuleFirst (var me: TModuleEntry32A): boolean;
      function               ModuleNext (var me: TModuleEntry32A): boolean;
      function               ProcessFirst (var pe : TProcessEntry32A) : boolean;
      function               ProcessNext (var pe : TProcessEntry32A) : boolean;
      function               ThreadFirst (var te : TThreadEntry32) : boolean;
      function               ThreadNext (var te : TThreadEntry32) : boolean;
      procedure              Update; // UpdateSnapshot
      procedure              Close;
     end;
     PTlh32 = ^TTlh32;

     TProcessArray = class (TSimpleArray)
     // Упрощенный список процессов
     protected
      pslist: array of TProcessEntry32A;
      prvpds: array of DWORD;
      prvcount: Integer;
      function GetPSinfo (i: Integer): TProcessEntry32A;
      function GetFileName (i: Integer): String;
      procedure SetSize (nSize: Integer); override;
     public
      th: TTlh32;
      property Names [Index: Integer]: String read GetFileName;
      property Items [Index: Integer]: TProcessEntry32A read GetPSInfo; default;
    public  
      // Обработчики изменения карты процессов
      OnNewProcessAdded: TPsNotifyHandler;
      OnProcessRemoved: TPsNotifyHandler;

      constructor       Create (arrayIdent: Integer);
      destructor        Destroy; override;
      function          FindByFile (const fname: string;
                                    updateBefore: boolean = false): Integer;
      function          FindById (pid: DWORD): Integer;
      function          GetDataPtr: Pointer; override;
      function          ItemSize: Integer; override;

      function          ListHash: DWORD;
      function          Update(unused: DWORD = 0): Boolean; override;
      function          UpdateCheck: Boolean;
     end;

     TModuleArrayEx = class (TModuleArray)
     private
      lastCount: Integer;
     public
      th: tTlh32;
      constructor       Create (arrayIdent: Integer);
      destructor        Destroy; override;
      function          Find (const s: string): dword;
      function          Update (srcpid: DWORD): Boolean; override;
     end;

     TThreadArrayEx = class (TThreadArray)
     protected
      lhash: Integer;
      function          CalcHash: Integer;
     public
      constructor       Create (ident: Integer);
      function          Update (pid: DWORD): Boolean; override;
     end;

     TWndProcess = record
      hwnd: THandle;
      pid, tid: DWORD;
      title: array [0..63] of AnsiChar;
     end; // TWndProcess



     TWndProcessArray = class (TSimpleArray)
     protected
      // что будет добавляться
      bInvisible: Boolean;
      bWindowless: Boolean;
      bPrimaryOnly: Boolean;
      bVoidCaptions: Boolean;
      FItems: array of TWndProcess;
      prvphash: DWORD;
      function      FlagInclude (flag: DWORD): Boolean;
      function      GetItem (i: Integer): TWndProcess;
      procedure     SetSize (nSize: Integer); override;
     public

      pid_hash: DWORD;
      bUpdated: Boolean;
      addMask: DWORD;
      maskPID: DWORD;
      psArray: TProcessArray;
      thArray: TThreadArrayEx;
      property      Items [Index: Integer]: TWndProcess read GetItem; default;
      function      AddWindow (hWnd: THandle): Boolean; virtual;
      constructor   Create (lIdent: Integer);
      destructor    Destroy; override;
      function      FindByPID (pid: DWORD): Integer;    
      function      GetDataPtr: Pointer; override;
      function      GetPSTitle (pid: DWORD): String;
      function      ItemSize: Integer; override;        
      function      Update (dwUnused: DWORD = 0): Boolean; override;
     end;



implementation



{ TTlh32 }

procedure TTlh32.Close;
begin
 if Handle <> 0 then CloseHandle (Handle);
 Handle := 0;
end;

procedure TTlh32.Init (dwFlags, srcPid: dword);
begin
 handle := 0;
 flags := dwFlags;
 _srcpid := srcpid;
end;

// Нахождение первого процесса


function TTlh32.ModuleFirst(var me: TModuleEntry32A): boolean;
begin
 me.dwSize := sizeof (me);
 result := Module32FirstA (handle, me);
end;

function TTlh32.ModuleNext(var me: TModuleEntry32A): boolean;
begin
 me.dwSize := sizeof (me);
 result := Module32NextA (handle, me);
end;

function TTlh32.ProcessFirst(var pe: TProcessEntry32A): boolean;
begin
 pe.dwSize := SizeOf (pe);
 result := Process32FirstA (Handle, pe);
end;

// Нахождение следующего процесса
function TTlh32.ProcessNext(var pe: TProcessEntry32A): boolean;
begin
 pe.dwSize := SizeOf (pe);
 result := Process32NextA (Handle, pe);
end;

function TTlh32.ThreadFirst(var te: TThreadEntry32): boolean;
begin
 te.dwSize := SizeOf (te);
 result := Thread32First (Handle, te);
end;

function TTlh32.ThreadNext(var te: TThreadEntry32): boolean;
begin
 te.dwSize := SizeOf (te);
 result := Thread32Next (Handle, te);
end;

procedure TTlh32.Update;
begin
 Close;
 Handle := CreateToolHelp32Snapshot (flags, _srcPid);
end; // Update handle 

{ TProcessArray }

constructor TProcessArray.Create;
begin
 inherited;
 OnNewProcessAdded := nil;
 OnProcessRemoved := nil;
 prvcount := 0;
end;

destructor TProcessArray.Destroy;
begin
 th.Close;
 inherited;
end;

function TProcessArray.FindByFile;
var
   n: Integer;
   s: string;
begin
 result := -1;
 if (updateBefore) then Update;
 s := LowerCase (fName);
 for n := 0 to ItemsCount - 1 do
  if ( pos (s, LowerCase (pslist [n].szExeFile)) > 0 ) then
   begin
    result := n;
    break;
   end;
end; // FindByFile



function TProcessArray.FindById;
var
    n: Integer;
begin
 result := -1;
 for n := 0 to ItemsCount - 1 do
 if Items [n].th32ProcessID = pid then
  begin
   result := n;
   exit;
  end;
end;  // TPrcsListEx.find

function TProcessArray.GetPSinfo;
begin
 FillChar (result, sizeof (result), 0);
 if (i > 0) and (i <= ItemsCount) then
   result := pslist [i]; 
end;

function TProcessArray.ListHash: DWORD;
var n: Integer;
begin
 result := 0;
 for n := 0 to ItemsCount - 1 do
     result := result xor pslist [n].th32ProcessID + 1;
end;


function TProcessArray.Update;
var n: Integer;
    
begin
 th.Init (TH32CS_SNAPPROCESS);
 th.Update;
 Clear;
 n := self.AddItems(1);
 if th.ProcessFirst(pslist [n]) then
  repeat
   n := self.AddItems (1); // предварительное выделение
  until (not th.ProcessNext (pslist [n]));
 if FCount > 0 then Dec (FCount);
 result := TRUE;
 th.Close;
end; // Update

function TProcessArray.GetFileName(i: Integer): String;
begin
 result := '';
 if (i >= ItemsCount) or (i < 0) then exit;
 result := pslist [i].szExeFile;
end;

{ TModuleArray }

constructor TModuleArrayEx.Create;
begin
 lastCount := 0;
 SetSize (16);
 inherited;
end;

destructor TModuleArrayEx.Destroy;
begin
 th.Close;
 inherited;
end; // ml destroy

function TModuleArrayEx.Find (const s: string): DWORD;
var n: Integer;
begin
 result := 0;
 for n := 0 to ItemsCount - 1 do
  if (pos (LowerCase (s), LowerCase (Items [n].szModule)) > 0) then
   begin
    result := n;
    exit;
   end;
end; // ModuleList.Find

function TModuleArrayEx.Update;
var
    iadd: Integer;
    me: TModuleEntry32A;
begin
 result := FALSE;
 th.Init (TH32CS_SNAPMODULE, srcpid);
 th.Update;
 Clear;
 if th.ModuleFirst (me) then
  repeat
   iadd := AddItems (1);
   if iadd >= 0 then
    begin
     FItems [iadd].hModule := me.hModule;
     FItems [iadd].modBaseSize := me.modBaseSize;
     StrLCopy (FItems [iadd].szModule, me.szModule, 256);
     StrLCopy (FItems [iadd].szExePath, me.szExePath, 260);
    end;
  until not th.ModuleNext (me)
 else exit;
 th.Close;
 result := ItemsCount <> lastCount;
 lastCount := ItemsCount;
end; // ml update

procedure TProcessArray.SetSize(nSize: Integer);
begin
 inherited;
 SetLength (pslist, FSize);
 SetLength (prvpds, FSize);
end;

function TProcessArray.GetDataPtr: Pointer;
begin
 result := pslist;
end;

function TProcessArray.ItemSize: Integer;
begin
 result := sizeof (pslist [0]);
end;

function TProcessArray.UpdateCheck: Boolean;
var psadd: Boolean;
    n, i: Integer;
begin
 // Проверка различий списков.
 result := FALSE;
 for n := 0 to FCount - 1 do
 begin
  psadd := TRUE; // по умолчанию считается что процесс новый
  for i := 0 to prvcount - 1 do
   if pslist [n].th32ProcessID = prvpds [i] then
    begin
     psadd := FALSE;
     prvpds [i] := 0; // маркировать добавленным.
    end;
  // Если процесс все таки новый
  if psadd and Assigned (OnNewProcessAdded) then
        OnNewProcessAdded (pslist [n].th32ProcessID);
  result := result or psadd;
 end;
 // Проверка на исчезновение процессов.
 if Assigned (OnProcessRemoved) then
 for n := 0 to prvcount - 1 do
  if prvpds [n] <> 0 then
   begin
    OnProcessRemoved (prvpds [n]);
    result := TRUE; // изменение списка
   end;
 // Запоминание текущей картины
 for n := 0 to FCount - 1 do
   prvpds [n] := pslist [n].th32ProcessID;
 prvcount := FCount;
end; // UpdateCheck;


{ TWndProcessArray }

function TWndProcessArray.AddWindow(hWnd: THandle): Boolean;
var
    bAdd: Boolean;
    stitle: array [0..256] of AnsiChar;
    iadd: Integer;
    pp, tt: DWORD;
begin
 //
 result := TRUE;
 bAdd := IsWindow (hWnd);
 bAdd := bAdd and ( IsWindowVisible (hWnd) or bInvisible );
 bAdd := bAdd and ( (0 = GetParent (hWnd)) and
                    (0 = GetWindow (hWnd, GW_OWNER)) or
                    (not bPrimaryOnly) );
 stitle [0] := #0;
 if bAdd then
  begin
   tt := GetWindowThreadProcessId (hWnd, pp);
   bAdd := (maskPID = 0) or (maskPID = pp);
  end else tt := 0;
 if bAdd then GetWindowTextA (hWnd, stitle, 256);
 if bAdd and (bVoidCaptions or (StrLen (stitle) > 0)) then
  begin
   iadd := AddItems (1);
   FItems [iadd].hWnd := hWnd;
   with FItems [iadd] do
    begin
     tid := tt;
     pid := pp;
     pid_hash := 1 + pid_hash xor pid;
     StrLCopy (title, sTitle, 63);
    end;
  end;
end; // AddWindow

constructor TWndProcessArray.Create;
begin
 //
 addMask := 0;
 maskPID := 0;
 psArray := TProcessArray.Create (IDPROCESSLIST);
 thArray := TThreadArrayEx.Create (2);
 bPrimaryOnly := true;
 inherited;
end;


function EnWinProc (h: THandle; p: LPARAM): boolean; stdcall;
var
   wlist: TWndProcessArray;
begin
 result := false;
 wlist := TWndProcessArray (p);
 if not Assigned (wlist) then exit;
 // Добавление окна
 result := wlist.AddWindow (h);
end; // EnWinProc


destructor TWndProcessArray.Destroy;
begin
 psArray.Free;
 thArray.Free;
end;

function TWndProcessArray.FindByPID(pid: DWORD): Integer;
var n: Integer;
begin
 result := -1;
 for n := 0 to ItemsCount - 1 do
  if FItems [n].pid = pid then
   begin
    result := n;
    break;
   end;
end;

function TWndProcessArray.FlagInclude(flag: DWORD): Boolean;
begin
 result := addMask and flag <> 0;
end;

function TWndProcessArray.GetDataPtr: Pointer;
begin
 result := FItems;
end;

function TWndProcessArray.GetItem(i: Integer): TWndProcess;
begin
 FillChar (result, sizeof (result), 0);
 if ChkIndex (i) then result := FItems [i];
end; // GetItem

function TWndProcessArray.GetPSTitle(pid: DWORD): String;
var n: Integer;
begin
 result := '[untitled]';
 n := FindByPid (pid);
 if n >= 0 then
    result := Items [n].title
 else
  begin
   n := psArray.FindById(pid);
   if n >= 0 then result := ExtractFileName (psArray [n].szExeFile);
  end;
end;

function TWndProcessArray.ItemSize: Integer;
begin
 result := sizeof (FItems [0]);
end;

procedure TWndProcessArray.SetSize(nSize: Integer);
begin
 inherited;
 SetLength (FItems, nSize);
end;

function TWndProcessArray.Update;
var n, i: Integer;

    pp: DWORD;
    sa: AnsiString;
begin
 Clear;
 bInvisible :=  FlagInclude (PMF_INVISIBLE);
 bPrimaryOnly := not FlagInclude (PMF_CHILDWND);
 //bShowPID := FlagInclude (PMF_ADDPID);
 bWindowless := FlagInclude (PMF_WNDLESS);
 bVoidCaptions := FlagInclude (PMF_VOIDCAP);
 pid_hash := 0;
 EnumWindows (@EnWinProc, Integer (self));
 psArray.Update ();
 psArray.UpdateCheck ();
 // добавление процессов, еще не перечисленных в списке
 if bWindowless then
 begin
  for n := 0 to psArray.ItemsCount - 1 do
  begin
   pp := psArray [n].th32ProcessID;
   if (FindByPID (pp) < 0) and
      (maskPID = 0) or (maskPID = pp) then
    begin
     // далее используются методы toolhelp32.
     i := AddItems (1);
     with FItems [i] do
     begin
      pid := pp;
      hwnd := $FFFFFFFF;
      pid_hash := 1 + pid_hash xor pid;
      thArray.Update(pid);
      sa := AnsiString ( ExtractFileName (psArray [n].szExeFile) );
      StrLCopy (title, PAnsiChar (sa) , 32);
      if (pid = 0) and (title = '') then title := '[Idle]';
      if thArray.ItemsCount > 0 then
         tid := thArray [0].threadId else tid := 0;
     end;
    end;
   end;
 end; // ek - 4 end
 bUpdated := prvphash <> pid_hash;
 prvphash := pid_hash;
 result := bUpdated;
end;

{ TThreadArrayEx }

function TThreadArrayEx.CalcHash: Integer;
var n: Integer;
begin
 result := 0;
 for n := 0 to ItemsCount - 1 do
  result := result + Integer (DWORD (n) xor Items [n].threadId);
end;

constructor TThreadArrayEx.Create;
begin
 lhash := -1;
 inherited;
end;


function TThreadArrayEx.Update;
var tl: TTlh32;
    te: TThreadEntry32;
    iadd, hash: Integer;
begin
 tl.Init (TH32CS_SNAPTHREAD, pid);
 tl.Update;
 Clear;
 if tl.ThreadFirst (te) then
  repeat
   if te.th32OwnerProcessID = pid then
    begin
     iadd := AddItems (1);
     with FItems [iadd] do
     begin
      threadId := te.th32ThreadID;
      ownerPID := te.th32OwnerProcessID;
     end;
     {----------------------}
    end;
  until not tl.ThreadNext (te);
 tl.Close;
 hash := CalcHash;
 result := hash <> lhash;
 lhash := hash;
end;

end.

