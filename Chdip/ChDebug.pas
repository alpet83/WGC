unit ChDebug;

interface

uses
  Windows, Messages, SysUtils, Classes, 
  ComCtrls, Buttons, ChShare, ChMsg,
  TlHelpEx, Misk, Forms, ChLog;



type
    ThreadRec = record
      h : THandle;
     id : THandle;
   susp : boolean;
    end;

    TValueRec = record
     p : pointer;
     v, uv, lv : dword;
     vals : array [1..10] of  dword; // Последние 10 записей
     valc : byte;                    // Количество записей
     cnt : dword;                    // Кол-во срабатываний
     ords : array [1..16] of dword;   // Порядок срабатывания
     ordc : byte;                    // len (ords)   
     num : byte;
    end;

    TBreakPoint = record
     addr : dword;
     onWrite : boolean;
     onRead : boolean;
     atPtr : boolean;
     lastVal : dword;
     size : byte;
       rw : byte;
    end;


procedure   HandleEvents (msec : word);
procedure   DebugSelected; // Attached selected process
procedure   SetBreakPoint (n : byte);
procedure   UpdatePtrList;
procedure   ShowContext (n : byte);
procedure   SaveDbgInfo (name : string);
procedure   ClearDbgInfo;
procedure   RunProcess (fNonstopped : boolean); 
procedure   Dump (const sc : string;const typ, p, cnt : dword);
function    ReadDwordAt (const ofs : dword) : dword;
function    SuspendT (n : byte) : boolean;
function    ResumeT (n : byte) : boolean;
procedure   UpdateBtns;
procedure   DeleteLost;
procedure   WriteExtra;
procedure   SetTraceMode (fTrace : boolean);
procedure   TraceInto;
procedure   OpenThreads;        // Открытие дескрипторов потоков
procedure   DbgReset;           // Сброс состояния модуля отладки
function    IsDebuggerPresent: boolean; 
procedure   SuspendProcess;
procedure   ResumeProcess (const force:boolean = false);
procedure   DestroyWin (const hwnd: THandle);
function    QueryAccessRights: boolean;

var
   de : TDebugEvent;
   hPrcsModule : THandle;
   he : Boolean = false;
   WaitEvent : Boolean;
   EventCode : dword;
   TrapEvent : dword;
   breakPoints: array [1..8] of TBreakPoint;
   // 4 последние бряки для резерва, например для сохранения бряков
    ThrdArray: array [1..255] of ThreadRec;
    ThrdCount: dword;
   PtrList : array [1..256] of TValueRec;
   DbgInfoUpdated : Boolean;
   PtrCount : word;

   Waiting : Boolean;
   ShowNow : Boolean;
   fBreakpoint: Boolean = false;
//   TimeOut : dword;
    ThChanged: boolean;
      cThread: dword;
      ThIndex: dword;
      hThread: dword;
      iThread: dword;
     Attached: dword;
     animated: boolean;
        hKrnl: THandle; // Дескриптор библиотеки Kernel32.dll
          
implementation
uses ChForm, PrcsMap, ChCmd, ChSpy, ChTypes, ChClient;



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
 if result then AddMsg ('OK. Получены дополнительные права (SeDebugPrivilege)');
end; // QAR

var
   order : dword;
   idp: function: boolean; stdcall;
   
function    IsDebuggerPresent: boolean;
begin
 result := false;
 if (@idp = nil) then
  begin
   idp := GetProcAddress (hkrnl, 'IsDebuggerPresent');
   if (@idp <> nil) then result := idp;
  end;
end; // IsDebuggerPresent

procedure   CloseThreads;
begin
 while (ThrdCount > 0) do
  begin
   CloseHandle (ThrdArray [ThrdCount].h);
   dec (ThrdCount);
  end;
end; // CloseThreads

procedure   DbgReset;
begin
 CloseThreads;
end; // DbgReset

procedure   OpenThreads;
{
var
   OpenThread: function (access: DWORD; fInherit: BOOL; tid: DWORD): THandle; stdcall;
   addr: Pointer;
      n: dword;{}
begin
 (*
 addr := GetProcAddress (hKrnl, 'OpenThread');
 CloseThreads;
 if (addr <> nil) then
  begin
   @OpenThread := addr; // set function start
   for n := 1 to th32count do
    begin
     // Открытие потоков
     inc (ThrdCount);
     ThrdArray [ThrdCount].id := Th32List [n].th32ThreadID;
     ThrdArray [ThrdCount].h := OpenThread (THREAD_ALL_ACCESS, false,
                                        Th32List [n].th32ThreadID);
     ThrdArray [ThrdCount].susp := false; // наобум                                           
    end;
  end;
 UpdateBtns;           (**)
end; // OpenThreads

procedure   TraceInto;
begin
 HandleEvents (0);
 SetTraceMode (true);
end;


procedure   SetTraceMode (fTrace : boolean);
var c : TContext;
begin
 DeleteLost;
 if attached <> 0 then
  begin
   if cThread = 0 then cThread := ThrdArray [1].h;
   c.ContextFlags := context_control;
   GetThreadContext (cThread, c);
   if fTrace then c.EFlags := c.EFlags or 256
             else c.EFlags := (c.EFlags or 256) xor 256;
   SetThreadContext (cThread, c);
  end;
end; // SetTraceMode

function    ReadDwordAt;
var r : dword;
begin
 ReadProcessMemory (csm.svars.alias, ptr (ofs), @result, 4, r);
end; // ReadDwordAt

function    ThrdExists (n : word) : boolean;
var
   c : TContext;
begin
 c.ContextFlags := Context_full;
 result := false;
 if (n > 0) and (n <= ThrdCount) then
    result := GetThreadContext (ThrdArray [n].h, c);
end;

var LastThCount : word;

procedure   DeleteLost;
var
   n, nn : dword;
begin
 nn := 0;
 for n := 1 to ThrdCount do
 if ThrdExists (n) then
  begin
   inc (nn);
   ThrdArray [nn].h := ThrdArray [n].h;
  end;
 ThrdCount := nn;
 if nn <> LastThCount then ThChanged := false; // Сброс флажка
 LastThCount := nn;
end; // DeleteLost

{ Обновление кнопок выбора потоков }
procedure  UpdateBtns;
var
   n : byte;
   t : TComponent;
begin
 for n := 1 to 10 do
  Begin
    t := MForm.FindComponent ('bt' + intToStr (n));
    if (t <> nil) and (t is TSpeedButton) then
      begin
       (t as TSpeedButton).Enabled := n <= ThrdCount;
       (t as TSpeedButton).Hint := 'Thread Handle = $' +
                dword2hex (ThrdArray [n].h);
      end;
  End;
end;


var
   sav : dword;
   sc : TContext;

procedure  DisableBPS;
begin
 if cThread = 0 then exit;
 sc.ContextFlags := context_debug_registers;
 GetThreadContext (cThread, sc);
 sav := sc.dr7;
 sc.Dr7 := sc.Dr7 and $FFFF0000; // Disable all Breakpoints
 SetThreadContext (cThread, sc);
end;

procedure  EnableBPS;
begin
 sc.Dr7 := sav;
 SetThreadContext (cThread, sc);
end; // EnableBPS


procedure AddPtr (p : pointer; v, lv : dword; num : byte);
var n : word;
    f : boolean;
    i, c : dword; 
begin
 f := false;   
 if PtrCount > 0 then
  begin
   for n := 1 to PtrCount do
       f := f or (PtrList [n].p = p);
  end;
 if not f then
  begin // Добавление указателя
   inc (PtrCount);
   PtrList [PtrCount].cnt := 1;
   PtrList [PtrCount].valc := 1;
   PtrList [PtrCount].vals [1] := v;
   PtrList [PtrCount].p := p;
   PtrList [PtrCount].v := v;
   PtrList [PtrCount].uv := v;
   PtrList [PtrCount].lv := v;
   PtrList [PtrCount].num := num;
   PtrList [PtrCount].ordc := 1;
   inc (order);
   PtrList [PtrCount].ords [1] := order and $FF;
  end
 else
 for n := 1 to PtrCount do
  if PtrList [n].p = p then
   begin // Обновление указателя
    Inc (PtrList [PtrCount].cnt);
    PtrList [n].uv := PtrList [n].v; // Изменение
    PtrList [n].lv := lv;       // Предыдущее значение
    PtrList [n].v := v;         // Текущее значение
    c := PtrList [n].valc;      // Кол-во запомненых значений
    if c < 10 then
     begin
      inc (c);
      PtrList [n].vals [c] := v;
      PtrList [n].valc := c;
     end
    else
     begin
      PtrList [n].valc := 10;
      for i := 1 to 9 do
          PtrList [n].vals [i] := PtrList [n].vals [i + 1];
      PtrList [n].vals [10] := v; // Последнее значение
     end;

    inc (order);
    c := PtrList [n].ordc;
    with PtrList [n] do
    if c < 15 then
     begin
      inc (c);
      ords [c] := order and $FF;
      ordc := c;
     end
    else
     begin
      ordc := 15;
      for i := 1 to 14 do
          ords [i] := ords [i + 1];
      ords [15] := order and $FF;
     end;
    PtrList [n].num := num;
   end;
 DbgInfoUpdated := True;
end; // AddPtr

function StrArray (const x : array of dword; cnt : byte) : string;
var
   s : String;
   i, ii : dword;

begin
 s := '';
 i := 0;
 cnt := cnt + (low (x) - 1);
 repeat
  s := s + intToStr (x [i]);
  ii := i;
  // Проверка на автосокращение
  while ((ii < cnt) and (x [ii] + 1 = x [ii + 1])) do Inc (ii);
  // Реализация автосокращения
  if (ii > i) then
    begin
     s := s + ' - ' + IntToStr (x [ii]);
     i := ii;
    end;
   if i < cnt then s := s + ', ';
   inc (i);
  until i > cnt;
 result := s;
end;

procedure UpdatePtrList;
var n : dword;
    s : string;
    r, x : TTreeNode;
begin
 r := nil;
if DbgInfoUpdated then
with mForm.tvDbgPtrs do
Begin
 DbgInfoUpdated := false;
 items.BeginUpdate;
 items.Clear;
 for n := 1 to PtrCount do
   begin // Добавление элемента
    s := format ('Breakpoint at $%p', [ptrList [n].p]);
    r := Items.Add (r, s);
    s := 'SRC: ' + IntToStr (PtrList [n].num);
    x := Items.AddChild (r, s);
    s := 'CUR: ' + IntToStr (PtrList [n].v);    // Текущее значение
    x := Items.Add (x, s);
    s := 'PRV: ' + IntToStr (PtrList [n].lv);   // Предыдущее значение
    x := Items.Add (x, s);
    s := 'LST: ' + IntToStr (PtrList [n].uv);   // Предыдушее изменение
    x := Items.Add (x, s);
    s := 'CNT: ' + IntToStr (PtrList [n].cnt);  // Количество срабатываний
    x := Items.Add (x, s);
    s := 'ORD: ';  // Порядок срабатываний
    s := s + StrArray (PtrList [n].ords, PtrList [n].ordc);
    x := Items.Add (x, s);
    s := 'ALL: ';
    s := s + StrArray (PtrList [n].vals, PtrList [n].valc);
    Items.Add (x, s);
   end;
 items.EndUpdate;
End; 
end; //

procedure UpdTimerTimer(Sender: TObject);
begin
 UpdatePtrList;
end;

procedure  Dump;
{
var
   n, r : dword;
   o : word;
   v : array [0..255] of byte;
   vw : array [0..127] of word absolute v;
   vd : array [0..63] of dword absolute v;
   s : string;{}
begin
 (*
 n := SearchMB (p);
 if n > 0 then
  AddMsg (sc + ' модуля: ' + M32List [n].szModule)
 else
  AddMsg (sc + ':');
 if csm.SVars.aliased then
  begin
   o := 0;
   ReadProcessMemory (csm.SVars.alias, ptr (p), @v, 256, r);
   while (r > 0) and (o < cnt) do
    begin
     s := '';
     case typ of
      1 : begin
           for n := 0 to 15 do s := s + Byte2Hex (v [o + n]) + ' ';
           for n := 0 to 15 do
              if char (v [n + n]) in [' '..'~'] then
                 s := s + char (v [o + n]) else  s := s + '.';
          end; // BYTES
      2 : for n := 0 to 7 do s := s + Word2Hex (vw [o div 2 + n]) + ' ';
      4 : for n := 0 to 3 do s := s + Dword2Hex (vd [o div 4 + n]) + ' ';
     end; // case typ
     AddMsg (format ('$%P:', [pointer (p + o)]) + s);
     r := r - 16;
     o := o + 16;
    end;
  end;
  (**)
end;

procedure WriteExtra;
var c : TContext;
    h : THandle;
begin
 h := ThrdArray [1].h;  
 c.ContextFlags := context_full or context_control;
 GetThreadContext (h, c);
 WriteMsg (1, 20, 'Registers:');
 with c do
  begin
   WriteMsg (1, 40, format ('eax=%p ebx=%p ecx=%p edx=%p',
           [pointer (eax), pointer (ebx),
            pointer (ecx), pointer (edx)]));
   WriteMsg (1, 60, format ('esi=%p edi=%p esp=%p ebp=%p EIP=%p',
           [pointer (esi), pointer (edi),
            pointer (esp), pointer (ebp), pointer (eip)]));
  end;
end;

procedure AddMaxInfo (th : THandle);
var c : TContext;
begin
 c.ContextFlags := context_full or context_control;
 GetThreadContext (th, c);
 AddMsg ('Registers:');
 with c do
  begin
   AddMsg (format ('eax=%p ebx=%p ecx=%p edx=%p',
           [pointer (eax), pointer (ebx),
            pointer (ecx), pointer (edx)]));
   AddMsg (format ('esi=%p edi=%p esp=%p ebp=%p EIP=%p',
           [pointer (esi), pointer (edi),
            pointer (esp), pointer (ebp), pointer (eip)]));
  end;
 Dump ('Дамп стека', 4, c.Esp, 16);
end;


function  ResumeT;
begin
 result := false;
 if ThrdCount = 0 then DebugSelected;
 if (n <= ThrdCount) then result := ResumeThread (ThrdArray [n].h) = 0;
end; // ResumeCurr

function  SuspendT;
begin
 result := false;
 if ThrdCount = 0 then DebugSelected;
 if (n <= ThrdCount) then result := SuspendThread (ThrdArray [n].h) > 0;
end; // SuspendCurr

procedure HandleEvents;
var
    event : dword;
    c : TContext;
    ss, s : string;
    p, p2 : pointer;
    bpn : byte;
    r, v : dword;
    pc : array [0..255] of char;
    notShow : boolean;
begin
 if he then exit;
 he := true;
 if not Waiting then
 while WaitForDebugEvent (de, msec) do
  begin
   notShow := false;
   event := de.dwDebugEventCode;
   if Event = CREATE_PROCESS_DEBUG_EVENT then
     begin
      hThread := de.CreateProcessInfo.hThread;
      iThread := de.dwThreadId;
      hPrcsModule := dword (de.CreateProcessInfo.lpBaseOfImage);
      inc (ThrdCount);
      cThread := hThread;
      ThIndex := 1;
      ThrdArray [ThrdCount].h := hThread;
      ThrdArray [ThrdCount].id := iThread;
      UpdateBtns;
     end;
   case event of
    EXCEPTION_DEBUG_EVENT :
     begin
      s := ' ИС:';
      p := de.Exception.ExceptionRecord.ExceptionAddress;
      p2 := nil;
      if de.Exception.ExceptionRecord.ExceptionRecord <> nil then
         p2 := de.Exception.ExceptionRecord.ExceptionRecord.ExceptionAddress;
     with de.Exception.ExceptionRecord do
     case ExceptionCode of
       EXCEPTION_BREAKPOINT :
         begin
          s := s + ' BREAKPOINT';
          fBreakpoint := true;
         end; 
       EXCEPTION_ACCESS_VIOLATION :
        begin
         s := s + ' ACCESS_VOILATION: ';
         if NumberParameters >= 2 then
          begin
           if ExceptionInformation [0] = 0  then
             s := s + ' read from address' else
             s := s + ' write to address';
           s := s + ' $' + dword2hex (ExceptionInformation [1]);
          end;
         MForm.cb_hev.Checked := false;
        end;
       EXCEPTION_ARRAY_BOUNDS_EXCEEDED : s := s + ' ARRAY_BOUNDS_EXCEEDED';
       EXCEPTION_SINGLE_STEP :
        begin
         s := s + ' Пошаговый режим ';
         notShow := mform.cb_tracelog.Checked;
         c.ContextFlags := context_debug_registers;
         GetThreadContext (cThread, c);
         ShowContext (ThIndex);
         if MForm.cb_traceLog.checked then 
            AddMaxInfo (cThread);
         bpn := 0;
         if c.dr6 and 1 <> 0 then bpn := 1;
         if c.dr6 and 2 <> 0 then bpn := 2;
         if c.dr6 and 4 <> 0 then bpn := 3;
         if c.dr6 and 8 <> 0 then bpn := 4;
         if bpn in [1..4] then
          begin
           v := 0;
           ReadProcessMemory (csm.SVars.alias, ptr (BreakPoints [bpn].addr),
                            @v, BreakPoints [bpn].size, R);
           AddPtr (p, v, BreakPoints [bpn].LastVal, bpn);
           if p2 <> nil then AddPtr (p2, v, BreakPoints [bpn].LastVal, bpn);
           BreakPoints [bpn].lastVal := v;
         end;  
        end;
      end;
       s := s + format (' at EIP=$%p', [p]);
     end;
    CREATE_PROCESS_DEBUG_EVENT : s := ' Запущен процесс';
    CREATE_THREAD_DEBUG_EVENT :
        begin
         s := 'Создан поток : ';
         inc (ThrdCount);
         ThrdArray [ThrdCount].h := de.CreateThread.hThread;
         ThrdArray [ThrdCount].id := de.dwThreadId;
         if SpyWait then
            hSpyThrd := de.CreateThread.hThread;
         SpyWait := false;
         ss := format ('$%x', [ThrdArray [ThrdCount].h]);
         s := s + ' Handle=' + ss + ' ID=$' + dword2hex (de.dwThreadId);
         ss := format ('$%p', [de.CreateThread.lpStartAddress]);
         if ss <> '$00000000' then
            s := s + ' START=' + ss;
         UpdateBtns;
        end;
      LOAD_DLL_DEBUG_EVENT:
       begin
        s := 'Загружена DLL';
        FillChar (pc, 256, 0);
        r := dword (de.LoadDll.lpBaseOfDll);
        s := s + ' HINST:$' + dword2hex (r);
        GetModuleFileName (r, pc, 256);
        s := s + ' ' + pc;
        //ListModules (tvMemBlocks);
       end;
    UNLOAD_DLL_DEBUG_EVENT:
       begin
        FillChar (pc, 256, 0);
        r := dword (de.UnLoadDll.lpBaseOfDll);
        GetModuleFileName (r, pc, 256);
        s := 'Выгружена DLL HINST:$' + dword2hex (r)
                + ' ' + pc; 
       end;
    EXIT_THREAD_DEBUG_EVENT :
        begin
         s := ' Поток завершен, ThreadID= $' + dword2hex (de.dwThreadId);
         ThChanged := true;
        end;
    EXIT_PROCESS_DEBUG_EVENT :
        begin
         s := ' Процесс завершен';
         hThread := 0;
         cThread := 0;
         ThrdCount := 0;
        end;
   OUTPUT_DEBUG_STRING_EVENT :
        begin
         s := ' Сообщение отладки';
         p := de.DebugString.lpDebugStringData;
         FillChar (pc, 256, 0);
         ReadProcessMemory (csm.SVars.alias, p, @pc,
           Min (256, de.DebugString.nDebugStringLength), R);
         ss := pc;
         s := s + ': ' + ss;
        end;
    else s := format ('$%x', [de.dwDebugEventCode])
   end;
   if notShow then else
   AddMsg  ('DE: ' + format ('$%x ', [de.dwDebugEventCode]) +
            'TID: ' + format ('$%x ', [de.dwThreadID])+
                                s);

   // Режим остановки
   if (mForm.cb_stop.checked) and
      ((event = EXCEPTION_DEBUG_EVENT) and
      (de.Exception.dwFirstChance = 0))
        then
    begin
     mForm.btnContinue.Enabled := true;
     WaitEvent := false;
     waiting := true;
     showNow := true;
     break; // Процесс остановлен
    end
   else
    begin
     DisableBPS;
     if event = trapEvent then
      begin
       WaitEvent := false;
       EventCode := de.dwDebugEventCode;
      end;
     ContinueDebugEvent (de.dwProcessId, de.dwThreadId, DBG_CONTINUE);
     if (event = EXCEPTION_DEBUG_EVENT) and
        (de.Exception.ExceptionRecord.ExceptionCode =
         EXCEPTION_BREAKPOINT) then Sleep (10);
     EnableBPS;
    end;
    Application.ProcessMessages;
    if mform.cb_hev.Checked then else break;
  end;
 he := false; 
end;

procedure RunProcess;
begin
 DisableBPS;
 ContinueDebugEvent (de.dwProcessId, de.dwThreadId, DBG_CONTINUE);
 mForm.cb_stop.Checked := not fNonstopped;
 Sleep (100);
 EnableBPS;
 waiting := false;
end; // RunProcess;

procedure DebugSelected;
var
   pid : dword;

begin
 // Attaching
 DbgReset;
 pid := csm.prcs.pid;
 if pid = 0 then
   begin
    AddMsg ('Не выбран процесс для отладки!');
    exit;
   end; 
 if DebugActiveProcess (pid) then
  begin
   Attached := csm.prcs.pid;
   HandleEvents (200);
   AddMsg ('Начата отладка процесса $' + dword2hex (attached));
   AddMsg ('Главный поток, ID = $' + dword2hex (iThread));
   AddMsg ('Описатель потока = $' + dword2hex (hThread));
   AddMsg ('Внимание! Процесс отладки связывает программу ' +
            'с отладчиком.' );
   AddMsg ('Перед выходом используй Detach (поддерживается только в XP&2003Server)');
  end
 else
  begin
   AddMsg ('Attach Failed!');
   AddMsg ('ExERROR: ' + Err2Str (GetLastError));
   exit;
  end;
end; // DebugSelected

procedure ShowContext;

const
    gl : array [0..3] of string = ('00', '0L', 'G0', 'GL');
    rw : array [0..3] of string = ('EX', 'WO', 'RS', 'RW');
    ln : array [0..3] of string = ('B1', 'W2', 'RS', 'D4');
var c : TContext;
    h : THandle;
    
function  b2 (n : byte) : byte;
begin
 result := (c.dr7 shr n) and 3;
end; // b2

var tc : dword;
    e : dword;
begin
 if ThrdCount = 0 then DebugSelected;
 FillChar (c, sizeOf (c), 0);
 if cThread = 0 then exit;
 c.ContextFlags :=  context_full or
                    context_control or context_debug_registers;
// SuspendThread (oThread);
 if (n > 0) and (n <= ThrdCount) then h := ThrdArray [n].h
                                 else exit;
 tc := SuspendThread (h);
 if GetThreadContext (h, c) then
 else
  begin
   e := GetLastError;
   DeleteLost;
   UpdateBtns;
   AddMsg ('GetThreadContext ERROR: ' + Err2Str (e));
   exit;
  end;
 with mForm.lbRegisters do
 with Items do
  begin
   clear;
   BeginUpdate;
   Add ('Handle=' + format ('$%x', [h]));
   if tc > 0 then
      Add ('Thread Suspended') else Add ('Thread Active');
   Add ('Priority : ' + dword2hex (dword (GetThreadPriority (h))));
   Add ('eax= ' + dword2hex (c.eax));
   Add ('ebx= ' + dword2hex (c.ebx));
   Add ('ecx= ' + dword2hex (c.ecx));
   Add ('edx= ' + dword2hex (c.edx));
   Add ('esi= ' + dword2hex (c.esi));
   Add ('edi= ' + dword2hex (c.edi));
   Add ('ebp= ' + dword2hex (c.ebp));
   Add ('esp= ' + dword2hex (c.ebp));
   Add ('eip= ' + dword2hex (c.eip));
   Add (format ('dr0 = %P', [pointer (c.dr0)]));
   Add (format ('dr1 = %P', [pointer (c.dr1)]));
   Add (format ('dr2 = %P', [pointer (c.dr2)]));
   Add (format ('dr3 = %P', [pointer (c.dr3)]));
   Add (format ('dr6 = %P', [pointer (c.dr6)]));
   Add (format ('dr7 = %P', [pointer (c.dr7)]));
   EndUpdate;
  end;
  ResumeThread (h)
end;

procedure  SetBreakPoint (n : byte);
var c : TContext;
   xmask : dword;
    mask : dword;
   mask2 : dword;
   shift : byte;
  shift2 : byte;
    h : THandle;
begin
 if Attached = 0 then DebugSelected;
 shift := 0;
 shift2 := 0;
 if n in [1..4] then shift := (n - 1) * 2;
 if n in [1..4] then shift2 := (n - 1) * 4 + 16;
 if cThread = 0 then exit;
 with BreakPoints [n] do
 if (onWrite or onRead or atPtr) then mask := (1 shl shift) else mask := 0;
 if BreakPoints [n].size = 4 then BreakPoints [n].size := 3;
 mask2 := mask;
 if BreakPoints [n].onWrite then
    mask2 := mask or (1 shl shift2); // On Write
 if breakPoints [n].onRead then
    mask2 := mask2 or (3 shl shift2); // On Read or Write
 mask2 := mask2 or ((BreakPoints [n].size and 3) shl
                    (shift2 + 2)); // Size = dword
 xmask := (1 shl shift) or (3 shl shift2) or (3 shl (shift2 + 2));

 h := ThrdArray [1].h;

 if SuspendThread (h) = $FFFFFFFF then
  begin
   AddMsg ('Suspend Thread Error');
   AddMsg ('ExERROR: ' + Err2Str (GetLastError));
   exit;
  end;
 c.ContextFlags := context_debug_registers;
 if GetThreadContext (h, c) then
  begin
   case n of
    1 : c.Dr0 := Breakpoints [1].addr;
    2 : c.Dr1 := Breakpoints [2].addr;
    3 : c.Dr2 := Breakpoints [3].addr;
    4 : c.Dr3 := Breakpoints [4].addr;
   end;
   if n in [1..4] then
     begin
      c.Dr7 := (c.dr7 or xmask) xor xmask;
      c.Dr7 := c.Dr7 or mask2;
     end;
   c.ContextFlags := context_debug_registers;
   if SetThreadContext (h, c) then;
  end;
 ResumeThread (h);
end;

procedure ClearDbgInfo;
begin
 PtrCount := 0;
 order := 0;
end;

procedure SaveDbgInfo;
var f : TextFile;
    n : byte;
begin
 AssignFile (f, name);
 ReWrite (f);
 for n := 1 to PtrCount do
  WriteLn (f, Format ('%p', [PtrList [n].p]));
 CloseFile (f);
end;

var
   SuspendCount: Integer = 0;

procedure       SuspendProcess;
var n: dword;
begin
 if (suspendCount = 0) then
 begin
  for n := 1 to ThrdCount do
    if (ThrdArray [n].h <> hSpyThrd) then
        SuspendThread (ThrdArray [n].h);
 end;
 inc (SuspendCount);
end; // SuspendProcess

procedure       ResumeProcess;
var n: dword;
    nSusp, tt: Integer;
begin
 // Возобновление процесса
 if (suspendCount <= 0) and (not force) then exit;
 tt := 0;
 if (suspendCount = 1) or force then
 repeat
  nSusp := 0;
  inc (tt);
  for n := 1 to ThrdCount do
      nSusp := nSusp + Integer ( ResumeThread (ThrdArray [n].h) and $1 );
  if (suspendCount > 0) then dec (suspendCount);
 until (nSusp = 0) and force or (tt > 100); // полное разлочивание. 
end; // ResumeProcess;

procedure      DestroyWin;
var r: dword;
    msg: tagMSG;
begin
 if (hwnd = 0) then exit;
 if SendMessageTimeOut (hwnd, WM_CLOSE, 0, 0, SMTO_ABORTIFHUNG, 200, r) = 0 then
 if not DestroyWindow (hwnd) then
  begin
   GetWindowThreadProcessId (hwnd, r);
   r := OpenProcess (PROCESS_TERMINATE, false, r);
   while (PeekMessage (msg, hwnd, 0, WM_USER, PM_REMOVE)) do sleep (1);
   if (r > 0) then TerminateProcess (r, 1);
  end;
end;

initialization
 hKrnl := LoadLibrary ('kernel32.dll');
 ThrdCount := 0;
 idp := nil;
end.
