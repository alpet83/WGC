unit netipc;

interface
uses SysUtils, ChTypes, SimpleArray;
{
   ������ �� ����������� �������� IPC.
  1. ������� � ������������� ���� ��������� � ���������������� ���������
     ������, ���� ��� ����� ����� ���������/��������� ���� �������.
  2. �������� ���������� �������� ������ �� �������� ������ ������ �������.
  3. ���������� �������������� ��������� ����������.
  4. ��� �������� �������� � ������� ����� �������������� ��������� � �������
     ������.
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
    LogStr ('������: ���������� �� �����������');
  end;
end;


end.
