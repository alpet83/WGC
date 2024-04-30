unit ChThread;
interface

uses
  Windows, Classes, Messages, ChPStools, Conmgr,
  SysUtils, Misk, ChTypes, WinSock, TlHelpEx, ChIcons, WatchTable,
  ChShare, ChCmd, ChStorage, ChSettings, SocketAPI, LocalIPC;

resourcestring
  cfg_filename = 'wgcsrv.ini';
  stdHost = 'WGCHOST.EXE';

var
      hServerThread: THandle = 0;
      hStartupEvent: THandle = 0;
           host_tid: DWORD; // thread Id
            bHosted: Boolean = false;
        bDisconnect: Boolean = FALSE; // требуется порвать подключения при выгрузке
          bStopping: Boolean = FALSE;

{ ВНИМАНИЕ: Все потоковые функции программы ориентированы на
   использование BeginThread }
function  PrimaryThreadProc (param: Pointer): Integer;
procedure OnLoad;

implementation
uses ChSrch, ChPlugin2, ChHook, ChConst, ChHeap, MemMap, Mirror, ChLog,
     ChPSInfo, ChServer, DataProvider, NetIPC, ShareData, ConThread;


{ DipThread }
const
  errp1: pchar = 'Потоку Spy не удалось получить доступ к FileMap.';
  errp2: pchar = 'Поток Spy находиться вне цикла обработки сообщений.';
 errp10: pchar = 'Handle Not Duplicated!';
 szDllName : pchar = 'CHDIP.DLL';

var
   dp: TDataPacket;
   nIterations: Integer;
        loaded: Boolean = FALSE;
          hLib: THandle;
       AppExit: boolean = FALSE;
         fInit: boolean = FALSE;
     dptHandle: THandle; // копия описателя главного потока
  hInputThread: THandle;
    hRTMThread: THandle;
    hStopEvent: THandle = 0; // для остановки RTM-потока  
   bClientIdent: Boolean;
        dwIdent: Integer = 0; // Число идентификации
   net_down: Boolean; // общее закрытие подключений
       fMsg: boolean;
       fWgc: boolean;

procedure ClearList (nList: Integer);
begin
 case nList of
  IDWATCHLIST: wtable.Clear;
 end;
end;



function InputThreadProc (param: Pointer): Integer;
var s: String;
    i: Integer;
begin
 result := 0;
 Repeat
  Readln (s);
  bStopping := bStopping or (s = 'exit') or (s = 'down');
  bStopping := bStopping or ((s = 'close') and (0 = conman.nActiveCon));
  if s = 'addcon' then
     begin
      conman.AddConsole;
      i := conman.Count - 1;
      conman.SwitchConsole(i);
      WriteConStr (Format ('Active console %d', [i]), 7, i);
     end;
  if not bStopping and (s = 'close') and (conman.count > 1) then
   begin
    conman.Delete (conman.count - 1);
    conman.SwitchConsole(0);
   end;
  if s = 'watches' then wtable.Display;
 Until net_down;
end; // InputThreadProc

procedure StopInputThread;
const dcmd: PChar = 'down';

var hInput: THandle;
    w: DWORD;
    irec: _INPUT_RECORD;
begin
 hInput := GetStdHandle (STD_INPUT_HANDLE);
 irec.EventType := KEY_EVENT;
 with irec.Event do
 begin
  FillChar (KeyEvent, sizeof (KeyEvent), 0);
  KeyEvent.wVirtualKeyCode := VK_RETURN;
  KeyEvent.AsciiChar := #13;
 end;
 WriteFile (hInput, dcmd, 5, w, nil);
 WriteConsoleInput (hInput, irec, 1, w);
 if WaitForSingleObject (hInputThread, 1000) = WAIT_TIMEOUT then
   begin
    TerminateThread (hInputThread, 1000);
    LogStr ('WARN: Delayed termination of input thread');
   end;
 CloseHandle (hInputThread);
end;

procedure DataReceive;
var
   pdata: Pointer;
   cntr, i: Integer;
   tmp: TAnsiStr32;
   subj: String;
   fOK: Boolean;
begin
 cntr := 0;
 repeat
  Sleep (100);
  fOK := ReceiveData (dp);
  Inc (cntr);
 until fOK or (cntr > 100);
 if not fOK then Exit; // error!
 pdata := @dp.bindata;
 subj := dp.subject;
 if subj = sRQSLIST then
  begin
   Move (pdata^, ssm.rqslst, sizeof (TRqsList));
   ssm.SelRqsCnt := dp.bp.Data0;
   {$IFOPT D+}
   with ssm.rqslst [1] do
   LogStrEx (format ('rqslst [1]>> Example = %d, varsz = %d, rule = "%s"',
              [min, vsize, ruleText]), 14);
   {$ENDIF}

  end;
 if subj = sSCANPARAMS then
   Move (pdata^, ssm.svars.params, sizeof (TScanProcessParam));
 if subj = sWTADDVALS then
   wtable.ReceiveItems (pdata, dp.bp.data0);
   
 if subj = sOPENMUTEX then
  begin
   i := cmgr.FindNetMutex (PAnsiChar (pdata));
   if i < 0 then
    begin
     LogStr('#ERROR: Requested mutex has not found ' +
            PAnsiChar (pdata));
     exit;
    end;
   ASSERT (i < $100, 'Невероятный индекс для сетевого мьютекса'); 
   StrLCopy (tmp, PAnsiChar (pdata), 32);
   LogStr ('Return number of requested mutex ' + PAnsiChar (@tmp));
   SendMsg (CM_LDATA);
   SendDataEx (sMUTEXOPENED, @tmp, StrLen (tmp) + 1,
                        i, dp.bp.Data0);
  end;
end;


procedure OnLoad;
var s: String;
begin
 with scaner.map do
  begin
   fWgc := false;
   bHosted := GetModuleHandle (PChar (stdHost)) > 0;
   if bHosted then
      SetPriorityClass (GetCurrentProcess, $8000);

   ssm.SpyVars.CanResume := True; // Вся работа сделана
   s := '@CHDIP DEBUG: Loaded copy: ' + IntToStr (ssm.CopyNum);
   if not bHosted then
   begin
    ssm.spyVars.fSpyMode := true;
    ssm.SpyVars.fSIS := true;
    s := s + ' SpyMode';
   end
   else s :=s + ' StdMode';
   LogStr (s);
  end;
end;

procedure OnSyncMessage (msg, wp, lp: Integer);
begin
 case msg of
  // wp=mutex index lp=owner id
  CM_ACQUIREMUTEX:
   begin
    ASSERT (lp > 1, 'Ошибка идентификации сетевого клиента');
    if cmgr.AcquireNetMutex (wp, lp) then
       SendMsgEx (NM_MUTEXACQUIRED, wp, lp);
   end;
  CM_RELEASEMUTEX:
   if cmgr.ReleaseNetMutex(wp, lp) then
    SendMsgEx (NM_MUTEXRELEASED, wp, lp);
 end;
end;

procedure DispatchMsg (msg, wp, lp: DWORD);
var
    ticks: Int64;
    bLong: Boolean;
    tmp: array [0..260] of AnsiChar;
begin
 bLong := FALSE;
 ticks := GetTickCount;
 if msg = CM_IDENT then
  begin
   //hServer := 0; // возможно повторная идентификация
   bClientIdent := wp = DWORD (dwIdent);
   if bClientIdent then
    begin
     Inc (ClientCounter);
     LogStr ('Identification sucessfull - registered client № ' +
             IntToStr (ClientCounter));
     SendMsgEx (CM_IDENT, ClientCounter, GetCurrentProcessId ());
    end
   else LogStr (format ('Identification fail: %d <> %d',
                        [wp, dwIdent]));
   // TODO: Нужно добавить сброс соединения при неверной идентификации
  end;

 if not bClientIdent then Exit;
 case msg of
    CM_SYNCMESSAGES..CM_SYNCMESSAGES + $200:
        OnSyncMessage (msg, wp, lp);
    CM_CLEARLIST: ClearList (wp);     
    CM_UNLOAD:
     begin
      net_down := TRUE;
      bStopping := TRUE;
      bDisconnect := TRUE;
      SendMsg (NM_CLOSEACCEPT);
      cmgr.Resume;
      cmgr.ShutdownStart;
      sleep (1);
      LogStr ('#DISPMSG: Unload command dispatched.');
     end;
    CM_ECHO:
     begin
      // Используется для проверки на зависание.
      Sleep (10);
      SendMsg (CM_ECHO);
     end;
    CM_TEST:
     begin
      /// OutputDebugString ('@CHDIP DEBUG: Spy aSkEd!');
      GetModuleFileNameA (0, tmp, 260); // попытка узнать процесс
      SendStrMsg ('ECHO - OK: main module = ' + tmp);
     end;
    CM_SEARCH:
     begin
      bLong := TRUE;
      ssm.fComplete := false;
      ASSERT (Assigned (scaner));
      LogStrEx (' Starting scan/sieve process.', 10);
      scaner.Scan;
      LogStrEx (' Scaning/sieving complete', 10);
      ssm.fComplete := true;
      scaner.SendScanResults; // отправка результатов по сетке
      SendMsg (NM_SCANCOMPLETE);
     end;
    CM_WRST:
     begin
      SendMsg (CM_ECHO);
      with ssm.SVars do
           DefWindowProc (ssm.prcs.hwnd, WM_SYSCOMMAND, SC_RESTORE, 0);
      SendMsg (CM_COMPLETE);
     end;
    CM_WTXT:
     begin
      SendMsg (CM_ECHO);
      SendMsg (CM_COMPLETE);
     end;
    CM_WMIN:
     begin
      SendMsg (CM_ECHO);
      with ssm.SVars do
           DefWindowProc (ssm.prcs.hwnd, WM_SYSCOMMAND, SC_MINIMIZE, 0);
      SendMsg (CM_COMPLETE);
     end;
    CM_WMAX:
     begin
      SendMsg (CM_ECHO);
      with ssm.SVars do
           DefWindowProc (ssm.prcs.hwnd, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
      SendMsg (CM_COMPLETE);
     end;
      CM_HOOK: InstallTo (ssm.prcs.tid);
    CM_UNHOOK:
     begin
      ssm.SpyVars.fHookMode := false;
      ssm.SetInternalEvent (2, true); // Для прекращения ожидания
     end;
    CM_RESIZE :
    with scaner.map do
     begin
      InitBuff (msgpack.Data0);
     end;
    CM_SAVERES: scaner.SaveCurrToFile ('tempres.bin');
    CM_LOADRES: scaner.LoadFileToCurr ('tempres.bin');
    CM_DISPPG :
     begin
      ssm.plgRet := DisplayPlugin;
      SendMsg (CM_COMPLETE);
      Sleep (100);
     end;
    CM_PSKILL: KillSelected;
    CM_PSLIST:
     begin
      // попытка обновления списка
      LogStrEx ('CM_PSLIST dispathed', 10);
      wArray.addMask := wp;
      wArray.maskPID := lp;
      if wArray.TryLock (12000) then
         try
          wArray.Update;
          wArray.bUpdated := TRUE; // для принудительной отправки списка
         finally
          wArray.Unlock;
         end;
     end;
    CM_PSOPEN:
     begin
      ssm.prcs.pid := msgpack.data0;
      LogStr(format('PSOPEN: Opening process pid=$%x', [ssm.prcs.pid]));
      OpenGameProcess;
      LogStr(format('  process alias = $%x', [ssm.svars.alias]));
      scaner.map.hProcess := ssm.svars.alias;
      UpdateVMSMap (-1, -1);
     end;
    CM_UPDMAP: UpdateVMSMap (wp, lp);

    CM_WTMESSAGES..CM_WTMSGSLIM:
       wtable.OnMessage (msg);

   end; // Case MSG
 ticks := GetTickCount - ticks;
 if (ticks > 500) and (not bLong) then
    ods (format ('#WARN: sever handling message time = %d msec, ',
                [ticks]));
end;



procedure PerformTerminate;
begin
 LogStr ('Unload operation performed');
 Scaner.Free;
 MemMan.Free;
 FreePlugins;
 Mirr.Free;
 wtable.Free;
 if (ssm.CopyNum > 0) then dec (ssm.CopyNum);
 SendMSG (CM_EXITOK);
 if (bDisconnect) then
    cmgr.Terminate;
 // CloseShareMem;
 SetLastError (0);
 SetThreadPriority (GetCurrentThread, THREAD_PRIORITY_NORMAL);
 TestLogError;
 if not bStopping then
   LogStr ('#ERROR: External termination used.');
 LogStr ('Server thread trying to terminate..');
 WaitForSingleObject (dptHandle, 500);
 wArray.Destroy;
 if hLib <> 0 then
    FreeLibraryAndExitThread (hLib, 0);
end;

{}

procedure InitNetwork;
var
    i: Integer;
    msocket: TSocket;
    crd: COORD;
begin
 AllocConsole;
 crd.X := 160;
 crd.y := 80;
 SetConsoleScreenBufferSize (GetStdHandle (STD_OUTPUT_HANDLE), crd);
 bClientIdent := FALSE;
 net_down := FALSE;
 bConsoleCreated := TRUE;
 cmgr := TConnectionMgr.Create(FALSE);
 LogStr('~used server port ' + IntToStr (serverPort));
 i := cmgr.CreateSocket ('localhost', serverPort);
 cmgr.mutexList [0] := TNetMutex.Create (swtMutex);
 clientCounter := 1; // server id
 cmgr.bShowSplash := FALSE;
 if i >= 0 then
 begin
  msocket := cmgr.FindSocket (i);
  cmgr.CreateServerCon (msocket, IPCIdent, true);
  conReady := FALSE;
 end;
end; // InitNetwork




procedure Initialize;
var pc: WSTRZ256;
    hProcess: THandle;
    s, ss: String;
         n: Integer;
begin
 s := GetCommandLine ();
 ssm := smobj;
 n := 1;
 ss := StrTok (s, n, [' ']); // command line splitting
 ss := StrTok (s, n, [' ']);
 if (ss = '') and
   (GetPrivateProfileString ('Network', 'ListenPort',
                             '4096', pc, 255,
                             PChar (cfg_filename)) > 0) then ss := pc;
 if ss <> '' then serverPort := Str2Int (ss);
 if (GetPrivateProfileString ('Network', 'ServerIdent',
                             '0', pc, 255,
                             PChar (cfg_filename)) > 0) then
   dwIdent := Str2Int (pc);
 InitNetwork;
 Writeln;
 LogStr ('HINT: Type "down" to shutdown server');
 Writeln (#10#10);
 nIterations := 0;
 fInit := true;
 bStopping := FALSE;
 fmsg := false;
 FillChar (pc, 256, 0);
 hProcess := GetCurrentProcess;
 wtable := TWatchTable.Create;
 wtable.nMutex := 0;
 dptHandle := 0;
 if DuplicateHandle (hProcess, hServerThread, hProcess, @dptHandle,
                 0, False, DUPLICATE_SAME_ACCESS) then
                 else LogStr ('PrimaryThread handle not duplicated');

 wArray := TWndProcessArrayEx.Create (IDPROCESSLIST);
 wArray.Update;   
 mirr := TMirror.Create;
 // Разблокирование памяти
 MemoryUnlock;
 sis := true;
 cThreadID := GetCurrentThreadId;
 scaner := TScaner.Create;
 scaner.map.InitBuff(112 * 1024);
 ods ('@CHDIP DEBUG: Filemap opended');
 ssm.ThreadExit := false;
 Sleep (100); // external initialization wait
 if not fOverride then Inc (ssm.CopyNum);
 ssm.fMap := false;
 lastmp := ssm.svars.params.startofs;
 memman := TMemMan.Create;
 PostThreadMessage (ssm.OwnerID, WM_USER, 0, 0);
 ssm.fUnload := false;
 //if netMode then Inc (ssm.CopyNum);
 // Обработка первой загрузки
 //
 // Обработка вторичной загрузки
 if ssm.CopyNum > 1 then
    OnLoad;
 if ssm <> nil then
 begin
  fmsg := (ssm.CopyNum >= 1);
  ods ('@CHDIP: Init complete');
 end;
 if fmsg then
 begin
  ods ('@CHDIP DEBUG: Message translation started');
  SendMsg (CM_SPYLOAD);
  SetThreadPriority (dptHandle, THREAD_PRIORITY_NORMAL);
  fInit := true;
  fmsg := false;
 end;
end; // Initialize





procedure RTMProc (allowUpdate: Boolean);
begin
 { Процедура выполняет работу по обновлению карты памяти процесса
   и следит за изменениями в списке процессов.
   Вызов процедуры в настоящее время осуществляется из главного потока
 }
 if (allowUpdate) then
 if (ssm.svars.aliased) and (not net_down) then // авто сканирование, {только при активной программе}
    begin
     { Здесь только обслуживание открытого процесса }
     Scaner.ProcessCreateMap;
     ssm.MemInfo; // сбор инфы о затратах памяти
     if WaitForSingleObject (ssm.svars.alias, 10) =  WAIT_OBJECT_0 then
      begin
       ssm.svars.aliased := FALSE;
       ssm.svars.alias := 0;
       SendMsg (NM_PSTERMINATED);
       exit;
      end;
     // Отправка списков потоков и т.д.
     if conReady then UpdateLists (ssm.prcs.pid);
    end;

 if (allowUpdate) then
 if not wArray.bUpdated then // Если обновление обработано
   begin
    // Общее регулярное обслуживание
    if wArray.TryLock (30) then
     try
      wArray.Update; // update window/process list
     finally
      wArray.Unlock;
     end;
   end; // if ... then
 // Отправка списка процессов - событие может быть
 // инициировано извне
 if wArray.bUpdated and bClientIdent then
 if wArray.TryLock (20) then
  try
   wArray.SendProcessList;
   wArray.bUpdated := FALSE;
  finally
   wArray.Unlock;
  end;
end; // RTMThreadProc

function RTMThreadProc (param: Pointer): Integer;
begin
 hStopEvent := CreateEvent (nil, TRUE, TRUE, nil);
 repeat
  // Обновление watches
  if ssm.svars.aliased and (nIterations and $3 = 0) and
      (wtable.Count > 0) then wtable.Update;
  Sleep (1);
  // Проверка стабильности соединения
  if not conReady and (nIterations and 3 = 0) then CheckConReady;
  Inc (nIterations);
  WaitForSingleObject (hStopEvent, 10000);
 until bStopping;
 CloseSyncHandle (hStopEvent);
 result := 0;
end;


function PrimaryThreadProc;
var
   tid: DWORD;
   msgid: DWORD;
   smsg: TagMsg;
   xready, fdata: Boolean;
   state: DWORD;
   nIters: DWORD; // cчетчик итераций главного цикла
   he: THandle; // startup sync event
begin
 he := CreateEvent (nil, TRUE, FALSE, 'WGSrvReady');
 result := 0;
 nIters := 0;
 LogStr ('PrimaryThread - startup initialization...');
 if loaded then exit;
 loaded := true;
 PeekMessage (smsg, 0, WM_USER, WM_USER, PM_NOREMOVE);
 try
  makeAlias := true;
  ssm := TShareMem.Attach;
  ssm.AddRef (GetCurrentThreadId, GetCurrentThread);
  pWgcSet := @ssm.settings;
  smObj := ssm;
  ssm.bUpload := true; // Загрузка осуществляется
  //ssm.SetEvent (1, true); // Установить событие в сигнальное состояние
  Initialize; // общая инициация
 except
  LogStr ('Суръезная проблема при инициации потока');
  ssm := nil;
 end;
 if ssm = nil then
  LogStr ('FileMap not opened!')
 else
 if ssm <> nil then
 try
  netError := FALSE;
  if hStartupEvent <> 0 then
   begin
    SetEvent (hStartupEvent);
    LogStr ('Initialization step performed');
   end;

  hInputThread := BeginThread (nil, 0, @InputThreadProc, nil, 0, tid);
  hRTMThread := BeginThread (nil, 0, @RTMThreadProc, nil, 0, tid);
  SetThreadPriority(GetCurrentThread, 2);
  SetPriorityClass (GetCurrentProcess, $8000);
  state := 0;
  xready := FALSE;
  
  with ssm do
  Repeat
   if state <> 1 then state := 1;
   // Автоматическая выгрузка при потере соединения
   if Assigned (cmgr.datacon) and
      (cmgr.datacon.state = CON_LOSTED) then
    begin
     LogStr ('Аварийное прекращение потока - соединение потеряно.');
     bStopping := TRUE;
     break;
    end;

   if not xready and conReady then // on connect event
     begin
      SetEvent (he); // поток запущен, сеть готова - уведомить клиентский локальный процесс
      xready := TRUE;
     end;

   // Ожидание установки события отправления данных
   if not incoming.WaitEvent (_SENDEVENT, 250) then
    begin
     RTMProc (TRUE); // синхронные операции
     continue;
    end;
   // LogStrEx ('->>data incoming', 15);
   state := 2;
   // Блокировка действий вторичного потока
   if hStopEvent <> 0 then ResetEvent (hStopEvent);
   if not incoming.bOwned and not incoming.NeedUnlock then
      incoming.TryLock (10); // fast locking
   try // фрейм защиты события

    while (incoming.GetCount > 0) do
    begin
     fdata := GetDataIdent = 'Data';
     if not fdata then fmsg := GetMsg (msgid);
     // Обработка сообщения, если оно получено
     if fmsg then
        try
         DispatchMsg (msgid, msgpack.Data0, msgpack.Data1);
        except
         LogStrEx ('#ERROR: Exception durning call DispatchMsg', 13);
        end;
      // Получение данных - если это данные
      if fdata then DataReceive;
    end; // while data exist
   finally
    if hStopEvent <> 0 then SetEvent (hStopEvent);
   end;
   RTMProc (FALSE); // синхронные операции
   Inc (nIters);
   if nIters mod 1000 = 0 then
      LogStrEx ('MainLoop iterations = ' + IntToStr (nIters), 14);
   if incoming.bOwned and incoming.NeedUnlock then
      incoming.Unlock;
  Until bStopping;
 finally
  LogStrEx ('shutdowning server...', 15);
  CloseHandle (he);
  StopInputThread;
  WaitForSingleObject (hRTMThread, 200);
  CloseHandle (hRTMThread);
  PerformTerminate;
 end;
end; // PrimaryThreadProc

procedure LibProc (reason: Integer);
var
    pid: DWORD;
    s: String;
    pc: TFileStr;
begin
 pid := GetCurrentProcessId ();
 if hLib = 0 then
  begin
   LogStr (MainLib + ' has been not found in memory.');
   exit;
  end;
 GetModuleFileNameA (0, pc, 260);
 s := MainLib;
 case reason of
  DLL_PROCESS_ATTACH: s := s + ' attached to process $' + dword2hex (pid) +
                        ' at ' + DWORD2HEX (hLib);
  DLL_PROCESS_DETACH: s := s + ' detached from process $' + dword2hex (pid);
  else exit;
 end;
 s := s + ', main module ' + pc;
 LogStr (s);
end; // LibProc

var
   callCounter: Integer = 0;
procedure  WaitSurvive;
var test, n: DWORD;
    s: String;
begin
 Sleep (500);
 if callCounter > 0 then
   asm int 3 end;
 Inc (callCounter);
 bStopping := TRUE; 
 if bHosted then
    PostThreadMessage (host_tid, WM_QUIT, 0, 0);
 for n := 1 to 10 do
 try
  if hServerThread = 0 then exit;
  if n >= 10 then TerminateThread (hServerThread, 0);
  s := Format ('Waiting for termination main thread %d, 500ms', [hServerThread]);
  s := Format ('%d. ', [n]) + s;
  LogStr (s);
  test := WaitForSingleObject (hServerThread, 500);
  case test of
   WAIT_OBJECT_0: s := ' Thread has normally terminated';
   WAIT_TIMEOUT:  s := ' Thread has currently not terminated';
   WAIT_FAILED: s := ' Thread termination waiting error: "' + GetLastErrorStr + '"';
  else s := 'Strainge wait result ' + IntToStr (test);
  end;
  LogStr (s);
  if (test <> WAIT_TIMEOUT) then
   begin
    CloseHandle (dptHandle);
    hServerThread := 0;
    exit;
   end;
 except
 end;
end;

initialization
 OutputDebugString ('ChThread module initialization'#13#10);
 logFileName := '_chdip.log';
 LogStr('WGCServer Startup Initialization.', TRUE, TRUE);
 hLib := GetModuleHandle (PChar (MainLib));
 LibProc (DLL_PROCESS_ATTACH);
finalization
 WaitSurvive;
 LibProc (DLL_PROCESS_DETACH);
 //  CloseHandle (hServerThread);
end.
