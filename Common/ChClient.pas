unit ChClient;

interface
uses Windows, Dialogs, ChSettings, ChShare, LocalIPC, ChConst, DataProvider, ChTypes;

{ Обработка подключения/потери связи. Интеграция переменных состояния соединения.

}

type
     TNetClient = class
     public
      hWnd:  HWND;       // message destination
      serverPID: DWORD;  // process id of wgchost...
      hServer: THandle;  // process handle (localmode only)
      bConnectionStable: Boolean;
        bStopping: Boolean;
      prvConState: Boolean;
    reconnectMode: Boolean;
     prcsMsgsMode: Boolean;
      sConnection: Integer;
        localMode: Boolean;

      constructor       Create;

      procedure         CheckConnection;
      procedure         DataReceive;
      procedure         Disconnect;
      function          DispatchMsg (msgid: Integer;  wp, lp: Int64): Boolean;

      procedure         Init;
      procedure         OnConnect (wp, lp: Integer);
      procedure         OnConnectFail;
      procedure         OnConnectStart;
      procedure         OnDisconnect;
      procedure         OnTimer;
      procedure         OnMessage;
     end;

var pWgcSettings: ^TWgcSettings = NIL;
             csm: TShareMem = nil;

    Client: TNetClient;

implementation

uses Misk, ChLog, ChMsg, SysUtils, ChCmd, ChForm, Forms, netipc, prcsmap,
     ShellApi, SocketAPI, WinFuncs, CheatTable;


function NCWndProc(hwnd: HWND; msg: DWORD; wp, lp: Integer): Integer; stdcall;
var owner: TNetClient;
begin
 owner := TNetClient (GetWindowLong (hWnd, GWL_USERDATA));
 if Assigned (owner) then  // mistake of window handle?
 case msg of
  WM_CONNECTIONEVENT: owner.OnConnect (wp, lp);
  WM_CONNECTIONFAIL: owner.OnConnectFail;
  WM_CONNECTIONSTART: owner.OnConnectStart;
  WM_NETREADEVENT: owner.OnMessage ;
 end;

 result := DefWindowProc (hwnd, msg, wp, lp)
end;

{ TNetClient }

procedure TNetClient.CheckConnection;
begin
 if not cmgr.Ready and netReady then OnDisconnect;
end;

constructor TNetClient.Create;
const className = 'WGCNetClientMessageWnd';
var t: CREATESTRUCTA;
begin
 if not RegClassEx (className, @NCWndProc, 0) then exit;
 localMode := FALSE;
 bStopping := FALSE;
 InitTemplate (t, className, 'Msg');
 t.hwndParent := DWORD (HWND_MESSAGE);
 hWnd := MakeWindow (t);
 SetWindowLong (hWnd, GWL_USERDATA, Integer (self));
 bConnectionStable := FALSE;
 prvConState := FALSE;
 prcsMsgsMode := FALSE;
end;

procedure TNetClient.DataReceive;
var    dp: TDataPacket;
    pdata: Pointer;

begin
  if not ReceiveData (dp) then exit;
  pdata := @dp.bindata;
  if dp.subject = sMUTEXOPENED then
     mform.OnOpenMutex ( PAnsiChar (pdata), dp.bp.Data0 );
  // Обработка добавления элементов
  if dp.subject = sLISTADDITEMS then
    case dp.bp.Data0 of
     IDMODULELIST:
        AddModules (pdata, dp.uCount div sizeof (TModuleInfo));
     IDREGIONLIST:
        AddRegions (pdata, dp.uCount div sizeof (TRegion));
     IDTHREADLIST:
        AddThreads (pdata, dp.uCount div sizeof (TThreadInfo));
     // как список процессы не отправляются
    end;

   with mform do
   begin
    if dp.subject = sPROCESSREC then
       wplist.Add (PSmallPSArray (pdata)^, dp.uCount div sizeof (TProcessInfo) );
    if dp.subject = sPROCESSICON then
       wplist.AddIcon (PIconData (pdata)^, mform.IconList2, mform.plvx_cache);
    if dp.subject = sSCANPSINFO then
       ShowScanResults (pdata);
    if dp.subject = sFNDRESULTS then
       ReceiveScanResults (pdata);

    if dp.subject = sWTUPDVALS then
       vlist.UpdateItems (pdata, dp.bp.Data0);
    if dp.subject = sNUSERMSG then
         AddMsg (PChar (pdata));
   end;
   recvDataMode := False;
end;

procedure TNetClient.Disconnect;
begin
 bStopping := TRUE;
 LogStr('Закрытие сетевых подключений...');
 cmgr.ShutdownStart;
 Sleep (100);
 cmgr.Terminate;
end;

function TNetClient.DispatchMsg;
begin
 result := TRUE;
 with mform do
 case msgid of
    CM_IDENT:
      begin
       ClientId := wp; // реидентификация
       ServerPID := lp;
       AddMsg ('Идентификация завершена.');
       if localMode then
        begin
         hServer := OpenProcess (PROCESS_ALL_ACCESS, FALSE, lp);
         if hServer = 0 then LogStrEx ('#ERROR: cannot open server process handle', 12); 
         AddMsg ('Используется режим локального взаимодействия.');
        end;
      end;

    CM_SYNCMESSAGES..CM_SYNCMESSAGES + $200:
      OnSyncMessage (msgid, wp, lp);
    CM_CLEARLIST:
       case (wp) of
          IDADDRSLIST: ClearAddrs;
         IDMODULELIST: mArray.Clear;
        IDPROCESSLIST: wplist.Clear;
         IDREGIONLIST: rArray.Clear;
         IDTHREADLIST: thArray.Clear;
       end;

    NM_LISTADDCOMPLETE:
       case (wp) of
        IDPROCESSLIST: OnPSListAddComplete;
         IDMODULELIST: ListModules (tvMemBlocks);
         IDREGIONLIST: ListRegions (lvRegions);
         IDTHREADLIST: ListThreads (lbxThreads);
          IDWATCHLIST: RelistAddrs;
          IDICONLIST: CopyPSListCache;
       end;
       
     NM_MAPCOMPLETE: OnVMSMapCreated (wp);
        NM_PSOPENED: OnOpenProcess (msgpack);
        NM_PSCLOSED: OnProcessClosed;
    NM_PSTERMINATED: OnGameTerminated;


    NM_SCANCOMPLETE: OnScanComplete;
    NM_SCANPROGRESS: OnScanProgress (wp, lp);
    NM_CLOSEACCEPT:
      LogStr ('Connection closing accepted.');
    CM_SPYLOAD:; // dll infiltrated
    CM_LDATA:
    begin
     recvDataMode := true;
     result := FALSE;  // prevent recognition message in data
    end;
  else;//    DebugBreak; // unrecognized message
 end; // case
end;

procedure TNetClient.Init;
var n: Integer;
    he: THandle;
begin
 incoming.SetHWnd (hWnd);
 if (serverAddr = 'localhost') or
    (serverAddr = '127.0.0.1') then
   begin {LoadLIB;}
    localMode := TRUE;  // используется локальный сервер

    if psarray.FindByFile('wgchost', TRUE) < 0 then
    begin
     LogStr ('Trying to execute wgchost.exe...');
     {$IFOPT D+}
     //SW_SHOWNOACTIVATE
       n := ShellExecute (0, nil, 'wgchost.exe', '', '.', SW_MINIMIZE);
     {$ELSE}
       n := ShellExecute (0, nil, 'wgchost.exe', '', '.', SW_HIDE);
     {$ENDIF}
     he := 0;
     if (n > 32) then n := 20 else n := 0; // if success!
     if n <= 0 then
        LogStrEx ('Error executing wgchost.exe, check the file', 12)
     else
     repeat // попытка локального подключения
      Application.ProcessMessages;
      if he = 0 then
        begin
         he := OpenEvent (MUTEX_ALL_ACCESS, FALSE, 'WGSrvReady'); // test open
         LogStr ('Waiting for server initialized...');
         Sleep (10 * n);
        end
       else
        begin
         // выждать паузу инициализации локального сервера
         if WaitForSingleObject (he, 50) = WAIT_OBJECT_0 then n := 0;
        end;
      Dec (n);
     until n < 0;
     if he <> 0 then CloseHandle (he);
     Sleep (200);
     if n < 0 then LogStr ('Server started internally.');
    end;
   end;
 reconnectMode := FALSE;
 { -------------------------------------------------------------- }
 cmgr := TConnectionMgr.Create (FALSE);
 cmgr.hNotifyWnd := hWnd;
 ASSERT (IsWindow (cmgr.hNotifyWnd));
 n := cmgr.CreateSocket (serverAddr, serverPort);
 n := cmgr.FindSocket(n);
 if n >= 0 then
   begin
    if cmgr.CreateClientCon(n, 200) then
        LogStr ('~First connection starting');
   end;
end;

procedure TNetClient.OnConnect;
begin
 if conReady then exit;
 if wp >= 0 then
  begin
   sConnection := wp;
   if lp = IPCIdent then
   begin
    cmgr.Current := cmgr.FindSocket (wp);
    // Установка рабочего соедения
    cmgr.datacon := cmgr.GetConnection(wp);
    netReady := cmgr.Ready;
    conReady := netReady;
    LogStr (Format ('Connection initalized [%d,%d] ', [Integer (netReady), Integer(ConReady)]));
   end;
   if netReady then
    begin
     cmgr.Suspend; // новые соединения пока не устанавливать
     cmgr.SetConIOBuffSize(cmgr.datacon, IDRECVBUFF, 16384);
     cmgr.SetConIOBuffSize(cmgr.datacon, IDSENDBUFF, 16384);
     SendMsgEx (CM_IDENT, serverIdent);
     SendMsgEx (CM_PSLIST, 0, 0);
     SendMsgEx (CM_RESIZE, pWgcSettings.buffSize);
     SendMsg (CM_LDATA);
     SendDataEx (sOPENMUTEX, swtMutex, StrLen (swtMutex) + 1, ClientId);
    end;
   bConnectionStable := conReady;
   prvConState := conReady;
   mform.SetConState (TRUE);
   if reconnectMode then
    begin // переоткрытие процесса
     SendMsgEx (CM_PSOPEN, csm.prcs.pid);
     reconnectMode := FALSE;
    end;
  end;

end;

procedure TNetClient.OnConnectFail;
begin
 ShowMessage ('ОШИБКА: Не удалось установить соединение с сервером.');
 PostQuitMessage (0);
end;

procedure TNetClient.OnConnectStart;
begin
 AddMsg ('Начато соединение с сервером ' + ServerAddr +
         ' порт ' + IntToStr (serverPort));
end;

procedure TNetClient.OnDisconnect; // Обработка разрыва связи
begin
 if bStopping then exit;
 csm.svars.aliased := FALSE;
 reconnectMode := TRUE;
 netReady := FALSE;
 AddMsg (sNetworkError);
 AddMsg ('Процесс игры возможно потребуется выбрать заново.');
 cmgr.Resume;
 cmgr.ReCreateCon (200);
 mform.SetConState(FALSE); // соединение потеряно
end;

procedure TNetClient.OnMessage;
var
    m : DWORD;
    fmsg : boolean;
    ticks, aticks, hticks: Int64;
begin
 aticks := 0;
 hticks := 0;
 if not conReady then exit;
 // проверка на вторичный вход
 if prcsMsgsMode then exit;
 prcsMsgsMode := TRUE;
 try
  recvDataMode := recvDataMode or (GetDataIdent = 'Data');
  if recvDataMode then
     DataReceive
  else
 Repeat
  m := 0;
  ticks := GetTickCount;
  fmsg := GetMsg (m);
  aticks := aticks + (GetTickCount - ticks);
  ticks := GetTickCount;
  if fmsg then
     if not DispatchMsg (m, msgpack.Data0, msgpack.Data1) then break;
  hticks := hticks + (GetTickCount - ticks);
 Until not fmsg;
 finally
  prcsMsgsMode := FALSE;
 end;
 if (aticks > 100) or (hticks > 100) then
 begin
  ods (format ('#WARN: retreiving message time = %d msec, ' +
                 'handling message time = %d msec',
                [aticks, hticks]));
 end;
end; // PrcsMsgs

procedure TNetClient.OnTimer;
begin
 // regular processing
 if incoming.GetCount > 0 then
    OnMessage;
end;

initialization
 IPCIdent := 200;
 InitShare (ClientGlobalName, ServerGlobalName);
end.


