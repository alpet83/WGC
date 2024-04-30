unit ChCmd;

interface
uses Windows, SysUtils, ChTypes, ChShare, Messages, DataProvider;

function   GetMsg (var msg: UINT) : boolean;
procedure  SendMsg (const msgId: UINT);
procedure  SendMsgEx (msgId: UINT; wp: Integer = 0; lp: Integer = 0);
procedure  SendStrMsg (const sMsg: string);
procedure  WaitMsg (const timeOut : Dword; var msg : dword);


procedure  LoadLib;


implementation
uses Misk, ChConst, ChLog;


procedure LoadLib;
var h : THandle;
    p : WSTRZ256;
    e : Integer;
    sstart: Procedure; stdcall;
begin
 h := GetModuleHandle (PChar (MainLib));
 if (h <> 0) then
  begin
   sstart := GetProcAddress (h, 'SpyStart');
   if (@sstart <> nil) then sstart;
  end
 else
  try
   h := LoadLibrary (PChar (MainLib)); // Полная загрузка библиотеки
  except
   ods ('Сбой при загрузке chdip.dll');
  end;
 if h = 0 then
  begin
   e := GetLastError;
   strPCopy (p, 'Неудалось загрузить CHDIP.DLL: ' + Err2str (e));
   MessageBox (0, p, 'Неправильная ошибка', MB_OK);
   PostQuitMessage (e);
   exit;
  end;
end;// LoadLib

function  GetMsg;
{ Получение сообщений с кодом SrcID }
begin
 result := false;
 msg := 0;
 if conReady then
  begin
   result := ReceivePacket (msgpack) and msgpack.IsMessage;
   if result then msg := msgpack.msgid;
  end;
end;

procedure  SendMsg;
begin
 msgpack.Ident := 'Message';
 msgpack.msgid := msgid;
 if conReady then SendPacket (@msgpack);
end; // SendMsg

procedure  SendMsgEx;
begin
 FillChar (msgpack, sizeof (msgpack), 0);
 msgpack.Data0 := wp;
 msgpack.Data1 := lp;
 SendMsg (msgid);
end;

procedure  SendStrMsg (const sMsg: string);
begin
 SendDataEx (sNUSERMSG, PAnsiChar ( AnsiString (sMsg) ), Length (smsg));
end;

procedure  WaitMsg;
var n, Elapsed : dword;
begin
 n := GetTickCount;
 Elapsed := TimeOut;
 while (not GetMsg (msg)) and
       (Elapsed > TimeOut) do
  begin
   Sleep (1);
   Elapsed := abs (GetTickCount - n);
  end; 
end;


end.
