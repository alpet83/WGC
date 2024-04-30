unit netipc;

interface
uses SysUtils, ChTypes, SimpleArray;
{
   «адачи по оптимизации сетевого IPC.
  1. ѕерейти к использованию двух содениний с однонаправленной передачей
     данных, если это имеет смысл ускорени€/упрощени€ всей системы.
  2. ќтладить надежность передачи данных до нулевого уровн€ потер€ пакетов.
  3. ѕроизвести профилирование прослойки накоплени€.
  4. ƒл€ снижени€ задержек в сервере можно буферизировать выводимые в консоль
     данные.
}

var
   serverAddr: String = 'localhost';
   serverPort: Integer = 4096;
   serverIdent: Integer = 0;
   netReady: Boolean = FALSE;
   netError: Boolean = FALSE;
   net_down: Boolean = FALSE;
   
procedure CheckNetConnection;
procedure TestConnected (idcon: Integer);

implementation
uses Windows, Misk, ChCmd, ChConst, ChLog, Winsock, SocketAPI;

procedure CheckNetConnection;
begin
 if (netReady and (not cmgr.Ready)) or (netError) then
 begin
  if Assigned (cmgr.datacon) then
     cmgr.CloseCon (cmgr.datacon.socket);
  netReady := FALSE;
  netError := FALSE;
  if net_down then
     LogStr('NET: Connection closed')
  else
   begin
    LogStr('NET: Connection lost.');
    cmgr.Resume;
    cmgr.ReCreateCon(100);
   end;
   Sleep (1000);
  end; // if ... then
end; // CheckConnection

procedure TestConnected;
var sock: TSocket;
    i: Integer;
begin
  sock := cmgr.WaitConnection (idcon, 1000);
  if sock >= 0 then
  begin
   LogStr('Connection accepted - checking stable.');
   ods (format ('~working data socket = %d', [sock]));
   cmgr.datacon := cmgr.GetConnection(sock);
   if Assigned (cmgr.datacon) then
    begin
     cmgr.SetConIOBuffSize(cmgr.datacon, IDSENDBUFF, 16384);
     cmgr.SetConIOBuffSize(cmgr.datacon, IDRECVBUFF, 16384);
     i := cmgr.GetConIOBuffSize(cmgr.datacon, IDSENDBUFF);
     ods (format ('~socket write buffer = %d', [i]));
     i := cmgr.GetConIOBuffSize(cmgr.datacon, IDRECVBUFF);
     ods (format ('~socket read buffer = %d', [i]));
    end;
   netReady := cmgr.Ready;
   if netReady then cmgr.Suspend else
    LogStr ('ќшибка: соединение не установлено');
  end;
end;


end.
