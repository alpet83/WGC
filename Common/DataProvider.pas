unit DataProvider;

interface
uses Windows, ChTypes, SimpleArray, ChConst;

type
    TBasePacket = packed record
    public
     Header: Integer;
     PacketSize: WORD;
     PacketType: SmallInt;
     // идентифицирует тип пакета
     FIdent: array [0..15] of AnsiChar;
     FControl: array [0..15] of AnsiChar;
     function   GetIdent: String;
     procedure  SetIdent (s: String);
    public
     // данные малого размера - для одиночных пакетов
     Data0, Data1: Int64;
     msgid: Integer;
     number: Integer;  // номер пакет
     // время отправления пакета
     sendtime: _SYSTEMTIME;  
     property Ident: String read GetIdent write SetIdent;
     function   IsPacket: Boolean;
     function   IsMessage: Boolean;
     procedure  Mark (num: Integer);
    end;

    PBasePacket = ^TBasePacket;

const bindatasz = 4096 - Sizeof (TBasePacket) - 48;

type

    TDataPacket = packed record
          bp: TBasePacket;
     subject: TAnsiStr32;
      uCount: WORD;
     bindata: array [0..bindatasz - 1] of byte; // ~4kb of data
    end;

    PDataPacket = ^TDataPacket;

    TMixedPacket = packed record
    case BYTE of
     0: ( dp: TDataPacket );
     1: ( bb: array [0..sizeof (TDataPacket) - 1 ] of BYTE );
    end;


const
     BPacketSize = sizeof (TBasePacket);
     DPacketSize = sizeof (TDataPacket);

var
    logTimeout: Boolean = FALSE;
    msgpack: TBasePacket;
    recvDataMode: Boolean;

   conReady: Boolean = FALSE; // Глобальный флаг соединения
   IPCIdent: Integer;  // Идентификатор в связке

function           CheckConReady: Boolean;

function           ReceivePacket (var packet: TBasePacket;
                                        bPeekData: Boolean = FALSE): Boolean;
function           ReceiveData (var packet: TDataPacket): Boolean;
function           SendPacket (const ppacket: PBasePacket): Boolean;
function           SendData (const subj: String; ppacket: PDataPacket): Boolean;
function           SendDataEx (const subj: String;
                              pdata: Pointer;
                              count: SmallInt;
                              wp: Integer = 0;
                              lp: Integer = 0): Boolean;

// производит порционную отправку данных
function           SendArrayData (const subj: String;
                                  pdata: Pointer;
                                  ItemSize, ItemsCount: Integer;
                                  subIdent: Integer = 0): Boolean;

procedure          SendArray (sarray: TSimpleArray);

function           GetDataIdent: String;

implementation
uses NetIPC, LocalIPC, SocketAPI, Misk, SysUtils, ChCMD, ShareData, ChLog;


var
   oPacketCounter: Integer = 0;
   iPacketCounter: Integer = 0; // для входящих пакетов
   enterCounter: Integer = 0;

function           CheckConReady: Boolean;
begin
 TestConnected (IPCIdent);
 if netReady then
    CheckNetConnection;
 conReady := netReady;
 if Assigned (incoming) then
    conReady := conReady or (incoming.GetRefCount > 1);
 result := ConReady;
end; // CheckConReady

procedure          CheckPacketNum (const sPacket: String;
                                  const packet: TBasePacket);
begin
 if enterCounter > 0 then
    exit; // reentration
 InterlockedIncrement (enterCounter);
 InterlockedIncrement (iPacketCounter);
 if iPacketCounter <> packet.number then
 begin
  ods (format ('Потеря пакетов. counter = %d, packetnum = %d',
        [iPacketCounter, packet.number]));
  iPacketCounter := packet.number;    
 end
 else
 if iPacketCounter mod 100 = 0 then
  ods ('Принят ' + IntToStr (packet.number) + ' пакет.');
 InterlockedDecrement (enterCounter);
end;

function           GetDataIdent: String;
begin
 result := '';
 if ReceivePacket (msgpack, TRUE) then
 result := msgpack.Ident;
end;

function           GetTimeMsec (const st: _SYSTEMTIME): DWORD;
begin
 result := ((st.wHour * 60 + st.wMinute) * 60 + st.wSecond) * 1000
                + st.wMilliseconds;
end;

function           ReceiveData;
var lt: _SYSTEMTIME;
    dwms: DWORD;
begin
 result := FALSE;
 if incoming.GetCount >= DPacketSize then
 repeat
  result := incoming.Read (packet, DPacketSize) = DPacketSize;
 until result
 else exit;
 if not (packet.bp.IsPacket and
        (packet.bp.Ident = 'Data')) then exit;
 GetLocalTime (lt);
 dwms := GetTimeMsec (lt);
 dwms := Abs (dwms - GetTimeMsec (packet.bp.Sendtime));
 CheckPacketNum ('DATA', packet.bp);
 // if bDirectMode  then
 if logTimeout and (dwms > 200) then
  LogStr (format ('DATAPACKET time = ' + GetStrTime (@packet.bp.sendtime) +
                  ' TTL = %d msec, overload = %d',
                        [dwms, incoming.GetCount]));

 result := TRUE;
end;

function           ReceivePacket;
var flags: DWORD;
    rr: Integer;
    lt: _SYSTEMTIME;
    dwms: DWORD;
begin
 result := FALSE;
 if not conReady then exit;
 flags := 0;
 if bPeekData then flags := FREADPEEK;
 if incoming.GetCount >= BPacketSize then
 repeat
  rr := incoming.Read (packet, BPacketSize, flags);
  result := rr = BPacketSize;
 until result or (rr < 0)
 else exit;
 if bPeekData then exit;
 if result then result := packet.IsPacket;
 if result then
  begin
   CheckPacketNum ('BASE', packet);
   GetLocalTime (lt);
   dwms := GetTimeMsec (lt);
   dwms := Abs (dwms - GetTimeMsec (packet.sendtime));
   // if bDirectMode then
   if logTimeout and (dwms > 200) then
      LogStr (format ('BASEPACKET time = ' +
                  GetStrTime (@packet.sendtime) +
                  ' TTL = %d msec, overload = %d',
                        [dwms, incoming.GetCount]));
  end;
end; // RecievePacket

function          SendPacket;
var avail, tcount: DWORD;
    overflow: Boolean;
begin
 result := FALSE;
 if not conReady then exit;
 InterlockedIncrement (oPacketCounter);
 if Assigned (ppacket) then
  begin
   ppacket.Mark (oPacketCounter);
   ppacket.PacketType := $100;
   ppacket.PacketSize := sizeof (TBasePacket);
   tcount := 0;
   with outcoming do
   repeat
    avail := outcoming.SpaceAvail;
    overflow := avail < BPacketSize;
    if not overflow then
     begin
      GetLocalTime (ppacket.sendtime);
      if bDirectMode then
         result := outcoming.Write (ppacket^, BPacketSize) = BPacketSize
      else
         result := cmgr.SendData(nil, ppacket, BPacketSize) = BPacketSize;
     end;
    if overflow then
       outcoming.WaitEvent (_RECVEVENT, 50); // ожидать очистки
    if not result then Sleep (20);
    Inc (tcount);
   until result or (tcount > 100);
   if not result then
      InterlockedDecrement (oPacketCounter);
  end;
end; // SendPacket

function          SendData;
var avail, tcount, t: DWORD;
    overflow: Boolean;
begin
 result := False;
 if not conReady then
   begin
    LogStr('SendData: connection not stable - exiting');
    exit;
   end;
 InterlockedIncrement (oPacketCounter);
 if Assigned (ppacket) then
 with ppacket.bp do
  begin
   Ident := 'Data';
   Mark (oPacketCounter);
   PacketType := $200;
   PacketSize := sizeof (TDataPacket);
   StrPCopy (ppacket.subject, subj);
   tcount := 0;
   t := GetTickCount;
   with outcoming do
   repeat
    avail := outcoming.SpaceAvail;
    overflow := avail < DPacketSize;
    if overflow then
      begin
       LogStr ('#DANGER: IPC buffer overflow');
       outcoming.Optimize(1500);
      end
    else
     begin
      GetLocalTime (sendtime);
      if bDirectMode then
         result := outcoming.Write (ppacket^, DPacketSize) = DPacketSize
      else
         result := cmgr.SendData(nil, ppacket, DPacketSize) = DPacketSize;
      outcoming.GetCount;
     end;
    //if overflow then outcoming.WaitFlush (50);
    Inc (tcount);
   until result or (tcount > 100) or NetError;
   t := GetTickCount - t;
   if t > 100 then
      LogStr (format ('SendData time = %d msec', [t]));
   if tcount > 10 then conReady := False; // условие завершения
   if outcoming.SpaceAvail < DPacketSize * 2 then
    outcoming.Optimize (1500) // ожидать принятие всех пакетов
   else
     // ожидать принятие всех пакетов
     outcoming.WaitFlush (50);
   if not result then
      InterlockedDecrement (oPacketCounter);
  end;
end;
{ TBasePacket }
function           SendDataEx;
var
    tmp: array [0..DPacketSize -1 ] of BYTE;
     dp: TDataPacket absolute tmp;
begin
 if (bindatasz < count) then asm int 3 end;

 FillChar (tmp, DPacketSize, 0);
 Move (pdata^, dp.bindata, count);
 dp.uCount := Count;
 dp.bp.Data0 := wp;
 dp.bp.Data1 := lp;
 result := SendData (subj, @dp);
end;


function           SendArrayData;
var parray: PChar absolute pdata;
    count, maxsend: Integer;
    offset, datasz: Integer;
begin
 result := FALSE;
 if (ItemSize <= 0) or (ItemsCount <= 0) then exit;
 maxsend := bindatasz div ItemSize;
 offset := 0;
 result := TRUE;
 if maxsend > 0 then
 repeat
  if ItemsCount > maxsend then count := maxsend
                          else  count := ItemsCount;
  datasz := count * ItemSize;
  if datasz > 0 then
  begin
   SendMsg (CM_LDATA);
   result := result and SendDataEx (subj, @parray [offset],
                                datasz, subIdent, ItemSize);
   offset := offset + datasz;
   Dec (ItemsCount, count);
  end;
 until (ItemsCount <= 0) or (not result) or (count = 0);
end; // SendArrayData

function TBasePacket.GetIdent: String;
begin
 result := FIdent;
end;


function TBasePacket.IsMessage: Boolean;
begin
 result := IsPacket and (Ident = 'Message');
end;

function TBasePacket.IsPacket: Boolean;
begin
 result := FControl = 'BASEPACKET';
end;

procedure TBasePacket.Mark;
begin
 Header := BPHDRVALUE;
 number := num;
 StrPCopy (FControl, 'BASEPACKET');
end;

procedure TBasePacket.SetIdent(s: String);
begin
 if Length (s) + 1 > sizeof (FIdent) then exit;
 StrPCopy (FIdent, s); 
end;


procedure   SendArray (sarray: TSimpleArray);
var pdata: Pointer;
begin
 ASSERT (Assigned (sarray), 'Объект списка был освобожден до его использования');
 pdata := sarray.GetDataPtr;
 ASSERT (Assigned (sarray), 'array.data is invalid memory address.');
 //ods ('sarray.ListIdent = ' + IntToStr (sarray.listIdent));
 SendMsgEx (CM_CLEARLIST, sarray.Ident);
 SendArrayData (sLISTADDITEMS, pdata,
                sarray.ItemSize, sarray.ItemsCount,
                sarray.Ident);
 SendMsgEx (NM_LISTADDCOMPLETE, sarray.Ident);
end; // Send List


end.
