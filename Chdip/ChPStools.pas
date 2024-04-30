unit ChPSTools;

interface
uses Windows, ChIcons, TlHelpEx, SysUtils, ChTypes, ChConst, Messages;

type
 TWndProcessArrayEx = class (TWndProcessArray)
 protected
  prvIcons: array of HICON;
  hIcons: array of HICON;
  procedure          SetSize (nSize: Integer); override;
 public
  icostore: TIconStorage;     
  constructor           Create (aIdent: Integer);
  destructor            Destroy; override;
  procedure             OnPSadd (pid: DWORD);
  procedure             OnPSrm (pid: DWORD);
  procedure             SendProcessList;
  procedure             SendIcons;
  function              Update (unused: DWORD = 0): Boolean; override;
 end;



var
    warray: TWndProcessArrayEx;

function  IsGame (hwnd: THandle): DWORD;
procedure MemoryUnlock;
procedure OpenGameProcess;
// procedure SendProcessList;
procedure KillSelected;

implementation
uses ChShare, NetIPC, DataProvider, ChCMD, ChLog, SimpleArray, ChSource;

var   mlist: TModuleArrayEx = nil;

procedure  MemoryUnlock;
var old: dword;
    mbi: TMemoryBasicInformation;
      p: pointer;
      d: dword absolute p;
     st: dword;
begin
 st := GetModuleHandle (PChar (mainLib));
 d := st;
 if st > 0 then
  repeat
    VirtualQuery (p, mbi, SizeOf (mbi));
    if mbi.Protect and (PAGE_GUARD or PAGE_NOACCESS) = 0 then
       VirtualProtect (mbi.BaseAddress, mbi.RegionSize,
                     PAGE_EXECUTE_READWRITE, @OLD);
    d := d + mbi.RegionSize;
  until d >= st + $200000;
  if mbi.RegionSize  = 0 then d := d + 4096;
end; // MemoryUnlock

function ExtractIconEx (lpszFile: PChar;
                            nIconIndex:Integer;
                            phiconLarge: PICON;
                            phiconSmall: PICON;
                            nIcons: DWORD): DWORD; stdcall; external 'shell32.dll';




function  GetWinProcess (hwnd: THANDLE): dword;
var pid: dword;
begin
 result := 0;
 GetWindowThreadProcessId (hwnd, pid);
 if (pid <> 0) then result := warray.psArray.FindById (pid);
end;

function  IsGame (hwnd: THandle): dword;
// определят принадлежность процесса к играм.
procedure TestAdd (t: dword; var v: dword);
begin
 if (t > 0) then inc (v, 100);
end; // TestAdd


var
   pc: WSTRZ256;
   s: string;
   n: dword;

begin
 result := 0;
 if (hwnd = 0) then exit;
 GetWindowText (hwnd, pc, 256);
 s := LowerCase (pc); // в строку
 if (pos ('game', s) > 0) then result := result + 100; // 100 балов
 n := GetWinProcess (hwnd);
 if (n <> 0) then
  begin
   mlist.Update (warray.psArray.items [n].th32ProcessID);
   TestAdd (mlist.Find ('ddraw'), result);
   TestAdd (mlist.Find ('d3d'), result);
   TestAdd (mlist.Find ('dinput'), result);
   TestAdd (mlist.Find ('dplay'), result);
   TestAdd (mlist.Find ('dshow'), result);
   // Другие оценки
   s := LowerCase ( warray.psArray.names [n] );
   if (pos ('game', s) > 0) then result := result + 100; // 100 балов
   if (pos ('games\', s) > 0) then result := result + 200; // 200 балов
   if (pos ('program files', s) > 0) then result := result + 10;
  end;
end;

function    QueryAccessRights: boolean;

var
   _OpenProcessToken: function (ProcessHandle: THandle; DesiredAccess: DWORD;
          var TokenHandle: THandle): BOOL; stdcall;
   _LookupPrivilegeValue: function (lpSystemName, lpName: PChar;
          var lpLuid: TLargeInteger): BOOL; stdcall;
   _AdjustTokenPrivileges: function  (TokenHandle: THandle; DisableAllPrivileges: BOOL;
  const NewState: TTokenPrivileges; BufferLength: DWORD;
        PreviousState: PTokenPrivileges; ReturnLength: PDWORD): BOOL; stdcall;
var
   ts: TOKEN_PRIVILEGES;
   hToken: THandle;
   pvalue: Int64;
   hlib: THandle;
begin
 result := false;
 hToken := 0;
 hlib := LoadLibrary (advapi32);
 if hlib = 0 then exit;
 _OpenProcessToken := GetProcAddress (hlib, 'OpenProcessToken');
 _LookupPrivilegeValue := GetProcAddress (hlib, 'LookupPrivilegeValueA');
 _AdjustTokenPrivileges := GetProcAddress (hlib, 'AdjustTokenPrivileges');
 if (@_OpenProcessToken <> nil) and
    (@_LookupPrivilegeValue <> nil) and
    (@_AdjustTokenPrivileges <> nil) then
 repeat
  if not _OpenProcessToken (GetCurrentProcess,
                   TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,
                   hToken) then break;

  if not _LookupPrivilegeValue(nil, 'SeDebugPrivilege',  pvalue) then break;
  ts.PrivilegeCount := 1;
  ts.Privileges [0].Luid := pvalue;
  ts.Privileges [0].Attributes := SE_PRIVILEGE_ENABLED;
  result := _AdjustTokenPrivileges (hToken, FALSE, ts, sizeof (ts), nil, nil);
 until true;
 if hToken > 0 then CloseHandle (hToken);
 FreeLibrary (hlib);
 // if result then AddMsg ('OK. Получены дополнительные права (SeDebugPrivilege)');
end; // QAR

procedure TWndProcessArrayEx.SendProcessList;
var
    pp: TProcessInfo;
    pa: TSmallPSArray;
    c, i: Integer;
    wp: TWndProcess;
begin
 i := 0;
 netError := FALSE;
 //LogStr('Sending process list to client');
 SendMsgEx (CM_CLEARLIST, wArray.Ident);
 c := 0;
 while (i < ItemsCount) do
 begin
  if netError then exit;
  wp := Items [i];
  FillChar (pp, sizeof(TProcessInfo), 0);
  StrLCopy (pp.title, wp.title, 64);
  pp.pid := wp.pid;
  pp.tid := wp.tid;
  pp.hWnd := wp.hwnd;
  pp.icon := -1; // debug
  if (wp.hWnd <> $FFFFFFF) then pp.game := IsGame (wp.hWnd);
  inc (i);
  pa [c] := pp; // save to small array;
  inc (c);
  if (c = 8) or (i = ItemsCount) then
   begin
    SendArrayData (sPROCESSREC, @pa, sizeof (TProcessInfo), c, Ident);
    c := 0;
   end;
  end;
 SendMsgEx (NM_LISTADDCOMPLETE, Ident);
 SendIcons;
end; // SendProcessList

procedure ClosePrevious;
begin
 if not smobj.svars.aliased then exit;
 // Избавится от старого процесса
 if CloseHandle (smobj.SVars.alias) then
    smobj.SVars.alias := 0;
 smobj.SVars.aliased := false;
 SendMsg (NM_PSCLOSED);
end;

procedure OpenGameProcess;

function    OpenSelected: dword;
begin
 SetLastError (0);
 Assert (smobj <> nil, 'smobj = nil !!!');
 smobj.SVars.alias := OpenProcess
  (PROCESS_ALL_ACCESS, FALSE, smobj.prcs.pid);
 TProcessSrc (dsrc).hProcess := smobj.svars.alias;
 result := GetLastError;
end; // OpenSelected

var
   err: dword;
   n: Integer;
begin
 // Проверка на загрузку в SpyMODE
 ClosePrevious;
 if FirstLoad then else smobj.prcs.pid := GetCurrentProcessId;
 if (not smobj.SVars.aliased) and (smobj.prcs.pid <> 0) then
  begin
   err := OpenSelected;
   if err = 5 then
      begin
       // AddMsg ('Нужны дополнительные права, для доступа к процессу');
       SetLastError (0);
       if QueryAccessRights then // reopen if success
                  OpenSelected;
      end;
   smobj.SVars.aliased := smobj.SVars.alias <> 0;
   if  smobj.svars.aliased  then
    begin
     smobj.fMap := false;
     smobj.svars.aliasedPID := smobj.prcs.pid;
    end;
  end;
  n := warray.psArray.FindById (smobj.prcs.pid);
  if n >= 0 then
     StrPCopy (smobj.prcs.fname, LowerCase (warray.psArray.names [n]));
  // additional for send
 SendMsgEx (NM_PSOPENED, smobj.svars.alias, smobj.prcs.pid);
end;


procedure KillSelected;
var excode: DWORD;
begin
 with smobj.Svars do
 begin
  PostMessage (smobj.prcs.hwnd, WM_CLOSE, 0, 0);
  // Добить несчастного
  sleep (100);
  if not aliased then exit;
  GetExitCodeProcess (alias, excode);
  if (excode = STILL_ACTIVE) then
  if WaitForSingleObject (alias, 500) = WAIT_TIMEOUT then
       TerminateProcess (alias, 0);
 end;

end;


{ TWndProcessArrayEx }

constructor TWndProcessArrayEx.Create(aIdent: Integer);
begin
 inherited;
 icostore := TIconStorage.Create;
 psArray.OnNewProcessAdded := OnPSAdd;
 psArray.OnProcessRemoved := OnPSrm;
end;

destructor TWndProcessArrayEx.Destroy;
begin
 icostore.Free;
end;

procedure TWndProcessArrayEx.OnPSadd(pid: DWORD);
var s: String;
begin
 s := GetPSTitle (pid);
 LogStrEx (format ('PSMAP: process added (PID = %d) ', [pid]) + s, 10);
end;

procedure TWndProcessArrayEx.OnPSrm(pid: DWORD);
begin
 LogStrEx (format ('PSMAP: process removed (PID = %d) ', [pid]), 12);
end;

procedure TWndProcessArrayEx.SetSize(nSize: Integer);
begin
 inherited;
 SetLength (prvIcons, nSize);
 SetLength (hIcons, nSize);
end;

function TWndProcessArrayEx.Update;
var n: Integer;
    t: Int64;
    prvCnt: Integer;
begin
 t := GetTickCount;
 // LogStrEx ('PSMAP: Start update', 14);
 prvCnt := FCount;
 result := inherited Update (unused);
 icostore.Clear; // убрать все значки.
 for n := 0 to FCount - 1 do
 begin
  if Items [n].hWnd <> 0 then
     hIcons [n] := icostore.AddWindowIcon(Items [n].hWnd);
 end;
 t := GetTickCount - t;
 if prvCnt <> FCount then
  begin
   //LogStrEx (#10'....'#13#10, 7);
   LogStrEx (Format ('PSMAP: End update, time = %d msec, pscount = %d'#13#10,
        [t, ItemsCount]), 14);
   //LogStrEx (#10'....'#13#10, 9);
  end;
end; // Update with icons

procedure TWndProcessArrayEx.SendIcons;
var n: Integer;
    dd: TIconData;
begin
 for n := 0 to icostore.Count - 1 do
 with icostore.Icons [n]^ do
  if dataSize > 0 then
   begin
    SendMsg (CM_LDATA);
    dd.hWndOwner := hWnd;
    dd.IcoDataSz := dataSize;
    Move (StreamData, dd.IcoStream, dataSize);
    SendDataEx (sPROCESSICON, @dd, sizeof (TIconData));
   end;
 SendMsgEx (NM_LISTADDCOMPLETE, IDICONLIST);  
end;

initialization
 mlist := TModuleArrayEx.Create (IDMODULELIST);
finalization
 mlist.Free;
end.
