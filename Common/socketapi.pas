unit SocketAPI;

interface
uses WinSock, Messages, Windows, SysUtils, SyncObjs,
        Classes, ShareData, ChConst;

{$WARN IMPLICIT_STRING_CAST OFF}
{
   Механизм сетевого IPC для обмена данными между процессами.

   + Используются асинхронные сокеты, с синхронизацией по
    событиям.
    + Запись производится
}

const

   BUFFALLOC = 16384;
   log_rwops = FALSE;
   CON_STABLE = 10;
   CON_CLOSED = 2;
  CON_CLOSING = 1; // соединение скоро будет закрыто
   CON_NOTCON = 0;
   CON_LOSTED = -1;
   MAX_MUTEX = 16;
   IDSENDBUFF = 1;
   IDRECVBUFF = 2;

type
    TBuffPage = array [0..BUFFALLOC-1] of Byte;
    PBuffPage = ^TBuffPage;
    TConType = (CON_OFFLINE, CON_CLIENT, CON_SERVER);
    TSimpleBuffer = object
     pdata: Pointer;
     size: Integer;
     procedure          AdjustSize (maxsz: Integer);
     procedure          ReAlloc (buffsz: Integer);
    end;

    TNetMutex = class
       sMutexName: String;
     currentOwner: Integer;
    public
     constructor        Create (const sName: String);
     destructor         Destroy; override;
     function           TryAcquire (ownerId: Integer): Boolean;
     procedure          Release (ownerId: Integer);
    end; // TNetMutex


    TConnection = packed record
     {InitializeCriticalSection}
       scshare: TRTLCriticalSection;  // используется для разделения соединения
       szAddr: array [0..256] of AnsiChar;
         name: sockaddr_in;
       source, dest: TShareData;
        binded: Boolean;
         error: Integer;   // last error
         state: Integer;   // connection state
       contype: TConType;
       rwEvent: THandle;
       daEvent: THandle;
          addr: Integer;
          port: Integer;
        socket: TSocket;
       cmdmask: WORD;
         bsize: Integer;
      ravaible: Integer;
        wcount: Integer;
         count: Integer;
         index: Integer;
         hNWnd: THandle;
       hThread: THandle;  // рабочий поток
      scshInit: Boolean;
     bAsyncMode: Boolean;
    hAsyncEvent: THandle;
    end;
    PConnection = ^TConnection;

   TConRequest = packed record
     serverCon: Boolean; { отправляется обычно один раз }
     clientCon: Boolean;
       Enabled: Boolean;
        Socket: TSocket; { Для создания соединения }
       newsock: TSocket; 
         saddr: TSOCKADDR;
          ssin: sockaddr_in;
        rqsnum: Integer;
    hNotifyWnd: THandle;
     hConEvent: THandle;
   end;
   PConRequest = ^TConRequest;

  TConnectionMgr = class (TThread)
  private
    procedure LockSelf;
    procedure UnlockSelf;
    procedure AdjustLists;
    function FindRequest(rqs: Integer): PConRequest;
  protected
     FConnections: array of TConnection; // потоки обслуживающие собственно
     FSize: Integer;
     ItemsCount: Integer;
     FCurrent: Integer;
     FLock: Integer;
     asect: TCriticalSection;
      g_state: Integer; // 1 = stable, -1 = terminating
     con_rqst: array of TConRequest;
     rqscount: Integer;
     ServerSocket: TSocket;
     nServerCon: Integer;
     bMakeClientCon: Boolean; // своего рода флаг команды
     bServerMode: Boolean;
     function           GetSocket (nConnection: Integer): Integer;
     procedure          SetSize (nSize: Integer);
     procedure          SetCurrent (nPos: Integer);
     procedure          Execute; override;
     function           InitServer(prqst: PConRequest): Integer;
    public
     bShowSplash: Boolean;
      hNotifyWnd: THandle;
      // Событие устанавливаемое при каждом соединении
       hConEvent: THandle;
     datacon: PConnection;
      mutexList: array [0..MAX_MUTEX - 1] of TNetMutex;

     property   Current: Integer read FCurrent write SetCurrent;
     property   Count: Integer read ItemsCount;
     property   Sockets[Index: Integer]: TSocket read GetSocket;

     constructor        Create (bCreateSuspended: Boolean);
     destructor         Destroy; override;
     function           AddRequest (rqs: Integer): PConRequest;
     procedure          DelRequest(nRqs: Integer);

     procedure          CloseCon (sock: TSocket; optlist: Boolean = TRUE);
     function           CreateSocket (hostName: AnsiString;
                              portNum: Integer;
                              pssin: PSockAddrIn = nil): Integer;
     function           CreateClientCon (nConnection: Integer; rqs: Integer): Boolean;
     { Создание вместе с тем и потока обслуживающего  новые соединения }
     function           CreateServerCon (nConnection: Integer; rqs: Integer;
                                         closeSource: Boolean): Boolean;
     function           AcquireNetMutex (nMutex, nOwnerId: Integer): Boolean;
     function           ReleaseNetMutex (nMutex, nOwnerId: Integer): Boolean;

     function           AddConnection (s: TSocket; rqs: Integer = -1): Integer;
     function           FindNetMutex (szMutexName: PAnsiChar): Integer;
     function           FindSocket (s: TSocket): Integer;
     function           FindPacketStart (pcon: PConnection; psize: SmallInt): SmallInt;
     function           GetConnection (s: TSocket): PConnection;
     function           GetConIOBuffSize (pcon: PConnection; buffId: Integer): Integer;
     function           SetConIOBuffSize (pcon: PConnection; buffId, buffSz: Integer): Boolean;
     procedure          ReCreateCon (rqs: Integer);
     // синхронный прием данных
     function           RecvData (pcon: PConnection;
                                  buff: Pointer; recvCount: Integer): Integer;
     // синхронная отправка данных
     function           SendData (pcon: PConnection;
                                  buff: Pointer; sendCount: Integer): Integer;
     procedure          SetAsyncMode (pcon: PConnection);                             
     procedure          ShiftBuff (buff: Pointer; start, scount: Integer);
     procedure          ShutdownStart;
     procedure          MakeSrvThreads (nConnection: Integer; asyncMode: Boolean);
     function           Ready: Boolean;
     function           WaitConnection (rqs, timeOut: Integer): TSocket;
     function           WaitData (dwTimeOut: DWORD): Boolean;
     procedure          Lock;
     procedure          Unlock;
    end; // TConnectionMgr

    PConnectionMgr = ^TConnectionMgr;


var
   WSAData: TWSADATA;
   cmgr: TConnectionMgr;
   ClientId: Integer = 0;
   clientCounter: Integer = 0;

function  CheckAvaibleToReceive (pcon: PConnection; minCount: Integer): Integer;
function  LockConnection (pcon: PConnection): Boolean;
procedure UnlockConnection (pcon: PConnection);

function        MakeSplashWindow (hParent: HWND): HWND;


implementation
uses ChLog, misk, netipc, DataProvider, LocalIPC;

type
    TXFuncParam = record
      mgr: TConnectionMgr;
      rqs: Integer;
      pcon: PConnection;
      bCloseSource: Boolean;
    end;

    PXFuncParam = ^TXFuncParam;
    TSimpleFunc = function (fparam: PXFuncParam) : Integer;

var errCount: Integer = 0;

procedure LogError (const smsg: String);
begin
 LogStrEx (smsg, 12);
 Inc (errCount);
 if errCount < 100 then exit;
 {$IFOPT D+}
  // raise Exception.Create (smsg);
  asm int 3 end;
 {$ELSE}
  Halt;
 {$ENDIF}
end;

function        NetErrCheck (iResult: Integer = 0;
                             rExcept: Boolean = FALSE; const Context: String = ''): Boolean;
var err: Integer;

begin
 result := iResult = 0;
 if result then exit;
 err := WSAGetLastError();
 if err <> 0 then
 begin
  netError := TRUE;
  LogError ('#NetError: ' + Err2str (err) + '; ' + Context);
  if IsDebuggerPresent then
     asm
      int 3
     end;

  if rExcept then
     raise Exception.Create ('Network Failure: ' + Err2str (err));
 end;
end;

function NetError2state (err: Integer): Integer;
begin
 result := CON_NOTCON;
 case err of
  0: result := CON_STABLE;
  WSAENOTCONN: result := CON_NOTCON;
  WSAENETDOWN, WSAENETUNREACH, WSAENETRESET,
  WSAECONNABORTED,WSAECONNRESET, WSAESHUTDOWN,
  WSAETIMEDOUT, WSAECONNREFUSED, WSAEHOSTDOWN,
  WSAEHOSTUNREACH: result := CON_LOSTED;
  WSAEDISCON: result := CON_CLOSED;
 end;
end;

const
    wsock_dll = 'ws2_32.dll';


function  WSACreateEvent: THandle; stdcall; external wsock_dll;
function  WSAEventSelect (s: TSocket; hEvent: THandle; lNetEvents: LongInt): Integer; stdcall; external wsock_dll;

function  WSATransfer (socket: TSocket; buff: Pointer; dsize: Integer;
                                        bRead: Boolean): Integer;
var
   ticks: Int64;
   pbuff: PAnsiChar;
   lr: Integer;
begin
 WSASetLastError (0);
 ticks := GetTickCount ();
 result := 0;
 pbuff := buff;
  Repeat
   // Циклическое считывание/запись данных из сокета
   if bRead then
     lr := recv (socket, pbuff [result], dsize, 0)
   else
     lr := send (socket, pbuff [result], dsize, 0);
   if lr > 0 then
    begin
     Inc (result, lr);   //{}
     Dec (dsize, lr);
    end;
  Until (lr < 0) or (dsize <= 0);

 if lr = SOCKET_ERROR then
    NetErrCheck (lr, FALSE, 'WSATransfer')
 else
  begin
   ticks := GetTickCount () - ticks;
   if ticks > 200 then
     LogStr (format ('#WARN: Transfer operation used %d msec',
                [ticks]));
  end;
end;


function  CheckAvaibleToReceive;
begin
 result := 0;
 if not LockConnection (pcon) then exit;
 with pcon^ do
 try
  if state <> CON_STABLE then exit;
  if ioctlsocket (socket, FIONREAD, rAvaible) <> SOCKET_ERROR then
     result := rAvaible;
  if (result < minCount) then exit;
  if daEvent <> 0 then SetEvent (daEvent);
 finally
  UnlockConnection (pcon);
 end;
 { if bSendMsg then
       PostMessage (hWnd, WM_NETREADEVENT, pcon.socket, 0);{}
end;

procedure SetSockAddr (var saddr: TSockAddr; addr, port: DWORD);
begin
 memsetz (@saddr, sizeof (saddr)); // clear
 saddr.sin_family := AF_INET;
 saddr.sin_addr.S_addr := addr;
 saddr.sin_port := port;
end; // SetSockAddr

procedure SetSockAddrIn (var saddr: TSockAddrIn; addr, port: DWORD);
begin
 memsetz (@saddr, sizeof (saddr)); // clear
 saddr.sin_family := AF_INET;
 saddr.sin_addr.S_addr := addr;
 saddr.sin_port := port;
end; // SetSockAddr

procedure TConnectionMgr.ReCreateCon;
var prqst: PConRequest;
begin
 prqst := FindRequest (rqs);
 if not Assigned (prqst) then exit;
 // переработка сокета
 if prqst.clientCon then // make new socket
   begin
    closesocket (prqst.socket);
    prqst.Socket := socket (AF_INET, SOCK_STREAM, 0);
   end;
 prqst.Enabled := TRUE;
end;   

function TConnectionMgr.SendData;
var dvx: Integer;
begin
 result := 0;
 if g_state < 0 then exit;
 if pcon = nil then pcon := datacon;
 if not LockConnection (pcon) then exit;
 dvx := sendCount;
 if pcon.state <> CON_STABLE then
   begin
    netError := TRUE;
    conReady := FALSE;
    LogError ('#ERROR: Попытка записи в сокет с неустановленным соединением.'+
         format (' state = %d, error = %s',
                   [pcon.state, err2str (pcon.error)]));
                   
    exit;
   end;
 try
  // просьба оботправке некоторго кол-ва байт
  if log_rwops then
     ods (format ('~Trying send %d bytes from buff $%p ' +
                ' with connection $%p', [sendCount, buff, pcon]));
  result := WSATransfer (pcon.socket, buff, sendCount, FALSE);
 finally
  if result <= 0 then
  begin
   pcon.error := WSAGetLastError;
   pcon.state := NetError2state (pcon.error);
  end;
  if dvx = sendCount then
     UnlockConnection (pcon) else DebugBreak;
  if log_rwops then ods (format ('~sended %d bytes ', [result]));
 end;
end; // SendData

function TConnectionMgr.RecvData;
begin
 result := 0;
 if g_state < 0 then exit;
 if pcon = nil then pcon := datacon;
 if not LockConnection (pcon) then exit;
 if pcon.state <> CON_STABLE then
   begin
    netError := TRUE;
    LogStr ('#ERROR: Попытка чтения сокета с неустановленным соединением.' +
            format (' state = %d, error = %s',
                   [pcon.state, err2str (pcon.error)] )); 
    exit;
   end;
 try
  // просьба об отправке некоторго кол-ва байт
  if log_rwops then ods (format ('~Trying read %d bytes to buff $%p ' +
                ' with connection $%p', [recvCount, buff, pcon]));
  result := WSATransfer (pcon.socket, buff, recvCount, TRUE);
  if result < 0 then
   begin
    pcon.error := WSAGetLastError;
    pcon.state := NetError2state (pcon.error);
   end
  else
   // Сброс события наличия данных
   if pcon.daEvent <> 0 then
      ResetEvent (pcon.daEvent);
 finally
  UnlockConnection (pcon);
  if log_rwops then ods (format ('~received %d bytes ', [result]));
 end;
end; // RecvData

type
   TThreadParams = record
    params: PXFuncParam;
    func: TSimpleFunc;
   end;

   PThreadParams = ^TThreadParams;

function SWndFunc (hWnd: HWND; msg: DWORD; wParam, lParam: Integer): Integer; stdcall;
begin
 result := 0;
 case msg of
 // WM_CREATE:;
  WM_CONNECTIONEVENT:
   begin
     if lParam = GetWindowLong (hWnd, GWL_USERDATA) then
      DestroyWindow (hWnd);
   end;
  WM_COMMAND:
   if LoWord (wParam) = 120 then DestroyWindow (hWnd);
  else result := DefWindowProc (hWnd, Msg, wParam, lParam);
 end;
end;

function        MakeSplashWindow;
const
     wndclassName = 'NetSplashWindowClass';
     sCaption = 'Waiting to establish connection...';
var
   wclass: WNDCLASSEXA;
   hButton: HWND;
begin
 result := 0;
 FillChar (wclass, sizeof (wclass), 0);
 wclass.cbSize := sizeof (wclass);
 if not GetClassInfoExA (hInstance, wndClassName, wclass) then
  begin
   wclass.style := CS_HREDRAW or CS_VREDRAW or CS_OWNDC;
   wclass.hInstance := hInstance;
   wclass.lpfnWndProc := @SWndFunc;
   wclass.hbrBackground := GetSysColorBrush (COLOR_3DFACE);
   wclass.hCursor := LoadCursor (0, IDC_ARROW);
   wclass.lpszClassName := wndClassName;
   if RegisterClassExA (wclass) = 0 then
     begin TestLogError; exit  end;
  end;

 result := CreateWindowEx (WS_EX_DLGMODALFRAME,
                        wndClassName, 'Connection...',
                        WS_VISIBLE or WS_OVERLAPPEDWINDOW or
                        WS_CLIPCHILDREN,
                        Integer(CW_USEDEFAULT),
                        Integer(CW_USEDEFAULT),
                        400, 140,  hParent, 0, hInstance, nil);

 if IsWindow (result) then
 begin
  exit;
  CreateWindow ('static', sCaption,
                WS_VISIBLE or WS_CHILD or WS_CLIPSIBLINGS,
                10, 10, 380, 25, result, 0, hInstance, nil);
  hButton := CreateWindow ('button', 'Break',
                WS_VISIBLE or WS_CHILD or WS_CLIPSIBLINGS or BS_DEFPUSHBUTTON,
                130, 40, 80, 25, result, 0, hInstance, nil);
  SetWindowLong (hButton, GWL_ID, 120);
 end;
end; // MakeSplashWindow



function        FormatAddr (const addr: PChar): String;
 function       GetAsStr (n: Integer): String;
 var
    v: ShortString;
 begin
  Str ( ord (addr [n]), v );
  result := String (v);
 end; // GetAsStr

var n: Integer;
begin
 result := '';
 for n := 0 to 3 do
 begin
  result := result + '.';
  result := result + GetAsStr (n);
 end;
 delete (result, 1, 1);
end; // FormatAddr;

function NetResolve(Host: PAnsiChar): Integer;
var
 HostEnt: PHostEnt;
begin
  Result := inet_addr(Host);
  if Result = Integer (INADDR_NONE) then
   begin
     HostEnt := gethostbyname(Host);
     if (HostEnt = nil) and not NetErrCheck (-1, FALSE, 'NetResolve ' + Host ) then
        Result := 0 else
        Result := PLongint(HostEnt^.h_addr_list^)^;
   end;
end; // NetResolve

function    TConnectionMgr.CreateSocket (hostName: AnsiString;
                              portNum: Integer;
                              pssin: PSockAddrIn = nil
                              ): Integer;
var
   ssin: sockaddr_in;
   // sent: *servent;
   n, s: Integer;
   szHostName: array [0..512] of AnsiChar;

begin
 if hostName = 'localhost' then
 begin
  gethostname (szHostName, 512);
  if szhostName <> '' then hostName := szHostName;
  LogStr ('~starting with client/server name ' + String(hostName) );
 end;
 SetSockAddrIn (ssin, NetResolve (PAnsiChar (hostName)), portNum);
 s := socket (AF_INET, SOCK_STREAM, 0);
 result := s;
 if (s < 0) and (not NetErrCheck (s, FALSE, 'CreateSocket')) then exit;
 if Assigned (pssin) then CopyMemory (pssin, @ssin, sizeof (ssin));
 n := AddConnection (s);
 if n < 0 then exit;
 FConnections [n].addr := ssin.sin_addr.S_addr;
 FConnections [n].port := portNum;
 StrLCopy (FConnections [n].szAddr, PAnsiChar (hostName), 256);
end;



function MakeParams (pmgr: TConnectionMgr; pcon: PConnection; rqs: Integer): PXFuncParam;
begin
 GetMem (result, SizeOf (TXFuncParam));
 result.mgr := pmgr;
 result.pcon := pcon;
 result.rqs := rqs;
end;




procedure       RunMessageLoop (hWnd: HWND; timeOut: Integer);
var msg: tagMSG;
    time: Int64;
begin
 time := GetTickCount;
 while IsWindow (hWnd) do
  if PeekMessage (msg, hWnd, 0, 0, PM_REMOVE) then
  begin
   TranslateMessage (msg);
   DispatchMessage (msg);
   if (GetTickCount - time > timeOut) then
       DestroyWindow (hWnd);
  end else Sleep (50);
end;

function   NetTransferProc (param: Pointer): Integer;
var
   mread: Integer;
   pcon: PConnection;
   tid: DWORD;
   rsize: Integer;
   buff: array [0..65535] of byte;
begin
 // Данная функция потока осуществляет асинхронное чтение
 // из сокета соединения в циклич       еском режиме
 result := 0;
 pcon := param;
 ASSERT (Assigned (pcon));
 tid := GetCurrentThreadId ();
 LogStr ('#NOTIFY: Transfer thread ' + FormatHandle (tid) + ' started.');

 incoming.AddRef;
 outcoming.AddRef;
 with pcon^ do
 if socket > 0 then
 try
  repeat
   if bDirectMode then break;
   if netReady then
    begin
     mread := recv(pcon.socket, buff, BPacketSize, 0);
     if mread < 0 then
      begin
       LogStrEx ('NetTransferProc: Connection lost', 12);
       netReady := FALSE;
      end;
     if mread <= 0 then Sleep (20);
     // записать первую часть
     if mread > 0 then incoming.Write (buff, mread);
     // получить кол-во оставшихся данных в буфере
     mread := CheckAvaibleToReceive (pcon, 4);
     if mread > 0 then
      repeat
       rsize := mread;
       if rsize > sizeof (buff) then rsize := sizeof (buff);
       WSATransfer (pcon.socket, @buff, rsize, TRUE);
       mread := mread - rsize;
       // Данные помещаются в буфер входящих данных
       incoming.Write(buff, rsize);
      until mread <= 0;
     // Ожидание данных
    end else sleep (100);
   if not Assigned (pcon) then break;
   if (pcon.state <> CON_STABLE) then break;
 until (pcon.cmdmask and 1 = 0);

 finally
  if Assigned (pcon) then
   begin
    CloseHandle (hThread);
    hThread := 0;
   end;
 LogStr (Format ('#NOTIFY: Transfer thread %d exited.', [tid]));
 end;
end;


{
function        ThreadStart (func: TSimpleFunc;
                             fparams: PXFuncParam;
                             hWndDefault: THandle;
                             makeWnd: Boolean = false): HWND;
var tid: DWORD;
    hThread: THandle;
    params: PThreadParams;

begin
 result := hWndDefault;
 if not Assigned (fparams) then exit;
 GetMem (params, Sizeof (TThreadParams));
 params.params := fparams;
 params.func := func;
 if makeWnd then
    result := MakeSplashWindow (hWndDefault);
 hThread := CreateThread (nil, 16384, @ThreadProc, params, 0, tid);
 if hThread <> 0 then CloseHandle (hThread);
end;

{ TConnectionMgr }

constructor TConnectionMgr.Create;
var n, err: Integer;

begin
 WSASetLastError (0);
 for n := 0 to MAX_MUTEX - 1 do
   mutexList [n] := nil;
 bServerMode := FALSE;
 asect := TCriticalSection.Create;
 datacon := nil;
 recvDataMode := false;
 bShowSplash := false;
 err := WSAstartup (MAKEWORD (2,0), WSAData);
 NetErrCheck (err, FALSE, 'WSAStartup');
 if err >= 0 then LogStr ('~Network initialized successfully.')
  else PostQuitMessage (0);
 hNotifyWnd := 0;
 ItemsCount := 0;
 g_state := 1;
 FCurrent := -1;
 FLock := 0;
 SetSize (4);
 inherited;
end;

destructor TConnectionMgr.Destroy;
var n: Integer;
    t: Int64;
begin
 if not Assigned (@self) then exit;
 t := GetTickCount;
 for n := 0 to Count - 1 do CloseCon (n, FALSE);
 t := GetTickCount - t;
 if t > 100 then
  LogStrEx (format ('#WARN: Closing all conections time = %d msec', [t]), 12);
 for n := 0 to MAX_MUTEX - 1 do
  if Assigned (mutexList [n]) then
  begin
   mutexList [n].Free;
   mutexList [n] := nil;
  end;
 SetSize (0);
 WSACleanup;
 asect.Free;
end;

function TConnectionMgr.AddConnection;
var pcon: PConnection;
begin
 LockSelf;
 if ItemsCount >= FSize then SetSize (ItemsCount + 4);
 result := ItemsCount;
 Inc (ItemsCount);
 FCurrent := result;
 pcon := @FConnections [result];
 FillChar (pcon^, sizeof (TConnection), 0);
 with pcon^ do
 begin
  InitializeCriticalSection (scshare);
  scshInit := True;
  daEvent := CreateEvent (nil, TRUE, FALSE, nil);
  hNWnd := hNotifyWnd; // default set
  while not LockConnection (pcon) do Sleep (10);
  Socket := S;
  UnlockConnection (pcon);
 end;
 UnlockSelf;   
end;


function TConnectionMgr.CreateClientCon;
var prqst: PConRequest;
begin
 result := false;
 with FConnections [nConnection] do
 begin
  if socket < 0 then exit;
  Lock;
  prqst := AddRequest (rqs);
  prqst.Socket := socket;
  prqst.clientCon := TRUE;
  prqst.hNotifyWnd := hNotifyWnd;
  // копирование (инициация) параметров
  with prqst^ do
        SetSockAddrIn (ssin, addr, port);
  prqst.Enabled := TRUE;
  Unlock;
  result := true;
 end;
end;

function TConnectionMgr.CreateServerCon;
var prqst: PConRequest;
begin
 result := false;
 ServerSocket := 0;
 with FConnections [nConnection] do
 begin
  if Socket < 0 then exit;
  AdjustLists;
  { Озадачивается поток менеджера }
  Lock;
  prqst := AddRequest (rqs);
  prqst.Socket := socket;
  prqst.serverCon := TRUE;
  prqst.hNotifyWnd := hNotifyWnd;
  with prqst^ do
   SetSockAddr (saddr, addr, port);
  nServerCon := nConnection;
  bServerMode := TRUE; // global mode
  // копирование (инициация) параметров
  with prqst^ do
        SetSockAddrIn (ssin, addr, port);
  prqst.Enabled := TRUE;
  Unlock;
  result := True;
 end;
end; // CreateServerCon

function TConnectionMgr.GetSocket(nConnection: Integer): Integer;
begin
 result := -1;
 if nConnection >= ItemsCount then exit;
 result := FConnections [nConnection].socket;
end;

procedure TConnectionMgr.SetSize(nSize: Integer);
var n: Integer;
begin
 FSize := nSize;
 ASSERT (FSize <= 1024, 'Impossible size(?), check addr of self'); // limitation
 SetLength (FConnections, FSize);
 SetLength (con_rqst, FSize);
 for n := Count to FSize - 1 do
  begin
   FillChar (FConnections [n], sizeof (TConnection), 0);
   FillChar (con_rqst [n], sizeof (TConRequest), 0);
  end;
end;


procedure NotifyConnect(prqs: PConRequest);
begin
 // nothing!
 if Assigned (prqs) then
 with prqs^ do
 begin
  if IsWindow (hNotifyWnd) then
   PostMessage (hNotifyWnd, WM_CONNECTIONEVENT, newsock, rqsnum);
  SetEvent (prqs.hConEvent);
 end;
end;

procedure TConnectionMgr.LockSelf;
var n: Integer;
begin
 for N := 1 to 10 do
  if FLock > 0 then Sleep (100); // not above 1 sec wait
 if FLock = 0 then InterlockedIncrement (FLock);
end;

procedure TConnectionMgr.UnlockSelf;
begin
 if FLock > 0 then InterlockedDecrement (FLock);
end;

procedure TConnectionMgr.SetCurrent(nPos: Integer);
begin
 if (nPos >= 0) and (nPos < Count) then
     FCurrent := nPos;
end;

function TConnectionMgr.FindRequest(rqs: Integer): PConRequest;
var n: Integer;
begin
 result := nil;
 for n := 0 to rqsCount - 1 do
  if rqs = con_rqst [n].rqsnum then
   begin
    result := @con_rqst [n];
    break;
   end;
end; // FindRequest

function TConnectionMgr.FindSocket(s: TSocket): Integer;
var n: Integer;
begin
 result := -1;
 for N := 0 to Count - 1 do
  if Sockets [N] = S then
   begin
    result := N;
    break;
   end;
end;

function TConnectionMgr.WaitConnection(rqs, timeOut: Integer): TSocket;
var
   prqst: PConRequest;
begin
 prqst := FindRequest (rqs);
 result := -1;
 if prqst = nil then exit;
 with prqst^ do
   if WaitForSingleObject (hConEvent, timeOut) =
     WAIT_OBJECT_0 then
      begin
       result := newsock;
       ResetEvent (hConEvent);
      end;
end; // WaitConnection

function TConnectionMgr.Ready: Boolean;
begin
 result := Assigned (datacon) and
           (datacon.state = CON_STABLE);
end;

procedure TConnectionMgr.MakeSrvThreads;
var tid: DWORD;
    pcon: PConnection;
begin
 if (nConnection < 0) or (nConnection > Count) then exit;
 pcon := GetConnection (Sockets [nConnection]);
 if pcon <> nil then
 with pcon^ do
 begin
  bsize := BUFFALLOC;
  bAsyncMode := AsyncMode;
  count := 0;
  cmdmask := 3; // stable mode
  hNWnd := hNotifyWnd;
  rwEvent := 0; // WSACreateEvent;
  // Проблемами транспортировки данных будет заниматься
  // отдельный поток
  hThread := BeginThread (nil, 0,
                             @NetTransferProc,
                             pcon, 0, tid);
  ods (format ('~creating service thread $%x, for connection %p ',
                  [hThread, pcon]));
  // Данный поток читает сокет в буфер входящих данных                  
  SetThreadPriority (hThread, 3);
  bAsyncMode := FALSE;
 end;
end;

function TConnectionMgr.FindPacketStart;

{
var i, minstart: Integer;
    ppack: PBasePacket;
    htest: Integer;
    stest: SmallInt;{}
begin
 result := -1;
 (*
 with pcon^ do
 minstart := count - psize;
 while (i <= minstart) do
 begin
  ppack := @rbuff [i];
  if not Assigned (ppack) then
     exit;
  htest := ppack.Header;
  stest := ppack.PacketSize;
  if (htest = BPHDRVALUE) and
     (stest = psize) then
     begin
      result := i;
      break;
     end;
  Inc (i);
 end; (**)
end;



function LockConnection;
begin
 result := false;
 if (pcon = nil) or
     (not Assigned (pcon)) then exit;
 if pcon.scshInit then
    result := TryEnterCS (pcon.scshare);

end;

procedure UnlockConnection;
begin
 if pcon <> nil then
   LeaveCriticalSection (pcon.scshare);
end;

procedure TConnectionMgr.ShiftBuff(buff: Pointer; start, scount: Integer);
begin
 //
end;

function TConnectionMgr.GetConnection(s: TSocket): PConnection;
var n: Integer;
begin
 result := nil;
 n := FindSocket (s);
 if (n >= 0) then
   result := @FConnections [n];
end;

procedure TConnectionMgr.Lock;
begin
 asect.Enter;
end;

procedure TConnectionMgr.Unlock;
begin
 asect.Leave;
end;

procedure TConnectionMgr.AdjustLists;
var cnt: Integer;
begin
 cnt := rqsCount;
 if Count > cnt then cnt := Count;
 if cnt >= FSize then SetSize (cnt + 16);
end;

procedure TConnectionMgr.DelRequest (nRqs: Integer);
var n: Integer;
begin
 if (nRqs >= rqscount) or (rqscount <= 0) then exit;
 for n := nRqs to rqscount - 2 do
   con_rqst [n] := con_rqst [n + 1];
 Dec (rqscount);
end;

function TConnectionMgr.InitServer;
begin
 with prqst^ do
 begin
  serverSocket := socket;
  // Ассоциация локального адреса и порта
  result := bind (socket, saddr, sizeof (saddr));
  if not NetErrCheck (result, FALSE, 'bind ' + inet_ntoa (saddr.sin_addr) + ':' + IntToStr(saddr.sin_port) ) then exit;
  LogStr('listen server socket ' + IntToStr (socket));
  result := listen (socket, SOMAXCONN);
  if not NetErrCheck (result, FALSE, 'listen') then exit;
 end;
end;

function WaitClientConnection(socket: TSocket;
                var saddr: TSOCKADDR): TSocket;
{ Функция ожидает присоединения клиента }
var
    L: Integer;
    sname: AnsiString;

begin
 //result := -1;
 LogStr ('~trying accept new connection...');
 L := sizeof (saddr);
 result := accept (socket, @saddr, @L);
 if (result < 0) then NetErrCheck (result, FALSE, 'accept')
  else
  begin
   LogStr ('SERVER: new connection established');
   sname := inet_ntoa (saddr.sin_addr);
   LogStr ('SERVER: connected client at ' + sname);
  end;
end; // WaitClientConnection


function ConnectToServer(rqst: PConRequest): Boolean;
var err, cnt: Integer;
         ctx: String;
begin
 cnt := 0;
 with rqst^ do
 repeat
  sleep (100);
  ctx := 'connect to ' + inet_ntoa (ssin.sin_addr);
  LogStr('Trying ' + ctx);
  err := connect (socket, ssin, sizeof (ssin));
  Inc (cnt);
  if err < 0 then Sleep (400);
  NetErrCheck (err, FALSE, 'connect');
 until (err >= 0) and (cnt < 100);
 result := err >= 0;
end;

procedure TConnectionMgr.Execute;

var
    ds: TSocket;
    n: Integer;
    scon, ccon: PConnection;
    prqs: PConRequest;
    rsaddr: TSOCKADDR;
    srvInitialized: Boolean;
    tid: DWORD;
begin
 // Поток обслуживающий создание новых соединений
 srvInitialized := FALSE;
 tid := GetCurrentThreadId ();
 LogStr (Format ('#NOTIFY: Connection thread %d started.', [tid]));
 repeat
  sleep (10);
  if bServerMode then
   begin
    if rqsCount <= 0 then continue;
    prqs := @con_rqst [0]; // dynamic array
    if not prqs.Enabled then continue;
    // prqs.Enabled := FALSE;
    // Связывание сокета если что.
    if not srvInitialized then
       srvInitialized := InitServer (prqs) >= 0;
    if not srvInitialized then continue;
    // TODO: Реализовать отсев по списку IP
    FillChar (rsaddr, sizeof(rsaddr), 0);
     // Прослушивание на соединения
    ds := WaitClientConnection (serverSocket, rsaddr);
    if ds < 0 then continue;
    Lock; // Блокировка списка соединений для добавления нового
    try
     n := AddConnection (ds, prqs.rqsnum); // добавить клиентское соединение
     scon := GetConnection(ds);
     if Assigned (scon) then
       begin
        scon.name := rsaddr;
        scon.contype := CON_SERVER;
        scon.state := CON_STABLE;
        prqs.newsock := ds; // обновляем информацию о сокете
       end;
      // Создание потока обслуживающего соединение
      MakeSrvThreads (n, true);
      // Уведомление кого можно о создании соединения
      NotifyConnect(prqs);
     finally
      Unlock;
     end;
   end; // ServerMode handling
  // Обработка запроса на подключение к серверу
  prqs := @con_rqst[0];
  if (rqsCount > 0) and Assigned (prqs) and
      prqs.Enabled then
  with prqs^ do
  begin
   prqs.Enabled := FALSE;
   if not clientCon then continue;
   if IsWindow (prqs.hNotifyWnd) then
   PostMessage (prqs.hNotifyWnd, WM_CONNECTIONSTART,
                   prqs.Socket, prqs.rqsnum);
   if ConnectToServer (prqs) then
    begin
     Lock;
     try
      ccon := GetConnection (socket);
      if Assigned (ccon) then
       begin
        ccon.contype := CON_CLIENT;
        ccon.state := CON_STABLE;
        prqs.newSock := socket; // обновляем информацию о сокете
       end;
      MakeSrvThreads (FindSocket (socket), TRUE);
      NotifyConnect (prqs);
     finally
      Unlock;
     end;
    end
    else
     if IsWindow (prqs.hNotifyWnd) then
      PostMessage (prqs.hNotifyWnd, WM_CONNECTIONFAIL,
                        prqs.Socket, prqs.rqsnum);
  end;
  sleep (10);
 until Terminated;
 LogStr (Format ('#NOTIFY: Connection thread %d exited.', [tid]));
end;

function TConnectionMgr.AddRequest;
begin
 AdjustLists;
 result := @con_rqst [rqsCount];
 FillChar (result^, sizeof (TConRequest), 0);
 // неименованное событие
 result.hConEvent := CreateEvent (nil, TRUE, FALSE, nil);
 result.rqsnum := rqs;
 Inc (rqsCount);
end;

procedure TConnectionMgr.CloseCon;
var i, n: Integer;
    bOK: Boolean;
begin
 n := FindSocket (sock);
 if (n < 0) or (n >= Count) then exit;
 Lock;
 with FConnections [n] do
 begin
  cmdmask := 0;
  bOK := FALSE;
  ods ('#NET: performing shutdown socket...');
  shutdown (socket, SD_BOTH);
  if hThread <> 0 then
   begin
    if ResumeThread (hThread) = INVALID_HANDLE_VALUE then
     begin
      hThread := 0;
      ods ('#ERROR: net-thread handle losted.');
     end
      else
       begin
        SetThreadPriority (hThread, THREAD_PRIORITY_NORMAL);
        bOK := WaitForSingleObject (hThread, 100) = WAIT_OBJECT_0;
       end; 
   end;
  if (hThread <> 0) and not bOK then
   begin
    ods ('#WARN: Needs to terminate network thread');
    TerminateThread (hThread, 0);
    if WaitForSingleObject (hThread, 500) = WAIT_TIMEOUT then
       ods ('#WARN: Thread termination timeout');
    CloseHandle (hThread);
    hThread := 0;
   end;
  DeleteCriticalSection (scshare);
  CloseSyncHandle (hConEvent);
  CloseSyncHandle (daEvent);
  CloseSyncHandle (hAsyncEvent);           
  closesocket (socket);
  FillChar (FConnections[n], sizeof (TConnection), 0);
 end;
 // Оптимизация списка соединений
 if optlist then
 begin
  for i := n to count - 2 do
      FConnections [n] := FConnections [n + 1];
  Dec (ItemsCount);
 end;
 Unlock;
end;

{ TSimpleBuffer }

procedure TSimpleBuffer.AdjustSize(maxsz: Integer);
begin
 if size < maxsz then ReAlloc (maxsz);
end;

procedure TSimpleBuffer.ReAlloc(buffsz: Integer);
begin
 if pdata <> nil then FreeMem (pdata);
 if buffsz <> 0 then GetMem (pdata, buffsz);
 size := buffsz;
end;

{ TNetMutex }

constructor TNetMutex.Create(const sName: String);
begin
 sMutexName := sName;
 currentOwner := 0;  { Released state } 
end;

destructor TNetMutex.Destroy;
begin
 // if used additional synchronization objects
end;

procedure TNetMutex.Release(ownerId: Integer);
begin
 if ownerId = currentOwner then
  begin
   // LogStr (format('client %d released mutex $%p', [ownerId, pself]));
   currentOwner := 0;
  end;
end;

function TNetMutex.TryAcquire(ownerId: Integer): Boolean;
begin
 result := FALSE;
 if (currentOwner <> 0) and
    (ownerId <> currentOwner) then exit;
 if (ownerId <> currentOwner) then
  begin
   currentOwner := ownerId
  end
 else
  begin
   LogStr (format('client %d already acquired mutex $%p', [ownerId, Pointer (self)]));
   LogStr ('WARNING: Вторичный захват сетевого мьютекса');
  end;
 result := TRUE;
end;

function TConnectionMgr.FindNetMutex(szMutexName: PAnsiChar): Integer;
var n: Integer;
begin
 result := -1;
 for n := 0 to MAX_MUTEX - 1 do
 if Assigned (mutexList [n]) then
  begin
   if mutexList [n].sMutexName = szMutexName then result := n;
  end;
end;

procedure TConnectionMgr.ShutdownStart;
var n: Integer;
begin
 g_state := -1;
 Resume;
 for n := 0 to Count - 1 do
 with FConnections [n] do              
 begin
  FConnections [n].cmdmask := 0; //
  FConnections [n].state := CON_CLOSING;
  if socket <> 0 then shutdown (socket, SD_BOTH);
 end;
end;

function TConnectionMgr.AcquireNetMutex(nMutex,
  nOwnerId: Integer): Boolean;
begin
 result := FALSE;
 if (nMutex < 0) or (nMutex >= MAX_MUTEX) then exit;
 if Assigned (mutexList [nMutex]) then
    result := mutexList [nMutex].TryAcquire(nOwnerId)
end;

function TConnectionMgr.ReleaseNetMutex(nMutex,
  nOwnerId: Integer): Boolean;
begin
 result := FALSE;
 if (nMutex < 0) or (nMutex >= MAX_MUTEX) then exit;
 if Assigned (mutexList [nMutex]) then
  begin
   mutexList [nMutex].Release(nOwnerId);
   result := mutexList [nMutex].currentOwner = 0;
  end;
end;

function TConnectionMgr.GetConIOBuffSize(pcon: PConnection;
  buffId: Integer): Integer;
var
   oval: array [0..4095] of AnsiChar;
   olen: Integer;
begin
 result := 0;
 olen := 4096;
 if not Assigned (pcon) then exit;
 case buffId of
  IDSENDBUFF: result := getsockopt (pcon.socket, SOL_SOCKET, SO_SNDBUF, oval, olen);
  IDRECVBUFF: result := getsockopt (pcon.socket, SOL_SOCKET, SO_RCVBUF, oval, olen);
 end;
 if (result <> SOCKET_ERROR) and (olen > 0) then
     Move (oval, result, 4);

end; // GetConIOBuffer

function TConnectionMgr.SetConIOBuffSize (pcon: PConnection; buffId, buffSz: Integer): Boolean;
var ires: Integer;
    oval: array [0..4095] of AnsiChar;
    olen: Integer;
begin
 ires := -1;
 // StrPCopy (oval, IntToStr (buffSz));
 Move (buffSz, oval, 4);
 olen := 4;
 case buffId of
  IDSENDBUFF:  ires := setsockopt (pcon.socket, SOL_SOCKET, SO_SNDBUF, oval, olen);
  IDRECVBUFF:  ires := setsockopt (pcon.socket, SOL_SOCKET, SO_RCVBUF, oval, olen);
 end;
 result := ires >= 0;
end;

function TConnectionMgr.WaitData;
var t: DWORD;
begin
 { по идее до прихода данных, при использовании
  блокируемого сокета, здесь создастся зона ожидания }
 result := FALSE;
 if not Ready then exit;
 if datacon.bAsyncMode and (datacon.hAsyncEvent <> 0) then
  begin
   result := WaitForSingleObject (datacon.hAsyncEvent, 100) =
               WAIT_OBJECT_0;
   Exit;
  end;

 t := 0;
 with datacon^ do
 repeat
  rAvaible := 0;
  if SOCKET_ERROR = ioctlsocket (socket, FIONREAD, rAvaible) then
     Break;
  result := rAvaible > 0;
  if result then Break;
  Inc (t);
  SleepEx(1, FALSE);
 until (t > dwTimeOut);    
 // result := recv (datacon.socket, buff, 1, MSG_PEEK) > 0;
end;

procedure TConnectionMgr.SetAsyncMode(pcon: PConnection);
begin
 if not Assigned (pcon) then exit;
 with pcon^ do
  begin
   hAsyncEvent := WSACreateEvent;
   WSAEventSelect (socket, hAsyncEvent, FD_READ or FD_WRITE);
   cmdmask := 4;
   bAsyncMode := TRUE;
  end;
end;

initialization
 cmgr := nil;
finalization
 if Assigned (cmgr) then
  begin
   cmgr.FreeOnTerminate := FALSE;
   cmgr.Free;
  end;
end.
