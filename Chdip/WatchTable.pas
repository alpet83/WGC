unit WatchTable;
{ Серверная сторона поддержки значений }
interface
uses ChTypes, Windows, ChConst, ChValues;

const  MAXUPDVCNT = sizeof (TUpdValueList) div sizeof (TTextUpdValue);

type
     TWatchTable = class (TValuesTable)
     private
      Hashes: array of Integer;
      FWatches: array of TWatchValue;
      FUpdValues: array of TTextUpdValue; // собственно значение
      FValues: array of TBinaryValue;
     public
      wtUpdate: Boolean;
      nMutex: Integer; // номер сетевого мьютекса доступа
      constructor       Create;
      function          CheckChanged (nVal: Integer): Boolean;
      procedure         Display;
      procedure         OnMessage (msgId: Integer); virtual;
      procedure         PatchValues;
      procedure         ReceiveItems (ilist: PSmallWatchList; cnt: Integer);
      procedure         SetSize (nSize: Integer); override;
      procedure         SendBack;
      procedure         Update;
     end;
var
   wtable: TWatchTable;


implementation
uses Misk, ChShare, ChPointers, SysUtils, ChSource, Math, ChCmd,
     SocketAPI,  NetIPC, DataProvider,
     ChServer, ChLog;
{ TValuesTable }

function   ReadProcessInt (var v: TBinaryValue;
                           var s: String): Boolean;
var
    sz: byte;
    d: Int64;
begin
 result := FALSE;
 // if ssm.svars.aliased then else exit;
 with v do
 begin
  if Enabled then else exit;
  sz := vsize;
  if sz > 8 then sz := 8;
  d := dsrc.ReadInt (ptr, sz) and CalcMask (sz); // Reading and masking
  if hex then s := format ('$%x', [d]) // formating to hex
  else s := IntToStr (d);
  result := dsrc.dwResult = sz;
  if not result then s := 'n/a';
 end;
end; // get Integer value

function    ReadProcessText (var v: TBinaryValue;
                            var s: String): Boolean;
var
    sz: word;
begin
 result := false;
 s := '';
 if v.enabled then else exit;
 sz := v.vsize;
 if sz = 0 then sz := 64;
 if sz > 256 then sz := 256;
 s := dsrc.ReadText (v.ptr, sz,  // ptr, size
                     v.vtype = st_wide); // fWide
 result := dsrc.dwResult > 0;
end; // ReadStrValue

function    ReadProcessFloat (var v: TBinaryValue;
                             var s: String): Boolean;
var
   sz: dword;
    e: extended;
begin
 result := false;
 if v.enabled then else exit;
 sz := v.vsize;
 try
  e := dsrc.ReadFloat (v.ptr, sz);
  if IsNan (e) then  s := 'Nan' else s := FloatToStr (e);
  result := dsrc.dwResult = sz;
 except
  On EInvalidOp do
   begin
    s := 'NAN'; // Прямой конвертации не вышло
    result := false; // indicating error
   end;
 end;
 if not result then s := 'n/a';
end; // GetChReal

function    WriteProcessFloat (const v: TBinaryValue): Boolean;
var
    sz: byte;
begin
 result := false;
 if v.enabled and v.writeable then else exit;
 sz := v.vsize;
 if sz in [4..10] then else exit;
 dsrc.WriteFloat (v.ptr, sz, v.valr);
 result := TRUE;
end;

function   WriteProcessInt (const v: TBinaryValue): Boolean;
begin
 result := False;
 if v.enabled and v.writeable then else exit;
 dsrc.WriteInt (v.ptr, v.vsize, v.vald);
 result := true;
end; // CheatIt

function    WriteProcessText (const v: TBinaryValue): Boolean;
var
    sz: word;
begin
 result := False;
 if v.enabled and v.writeable then else exit;
 sz := v.vsize;
 if sz > 32 then sz := 32;
 dsrc.WriteText (v.ptr, sz, v.vtype = st_wide, v.valt);
 result := true;
end;


function  StrToBinary (const item: TWatchValue; var v: TBinaryValue): Boolean;
var e: Integer;
begin
 with v do
 begin
  FillChar (v, sizeof (v), 0);
  ptr := DecodePtr (ssm.svars.alias, item.sAddress);
  // StrLCopy (descr, item.sDescription, 32);
  lock := item.sLock <> '';
  v.writeable := item.sPatchValue <> '';
  if v.writeable then
  begin
   valr := DigDecode (Item.sPatchValue);
   vald := Round (valr);
   StrLCopy (valt, item.sPatchValue, s32_len);
   StringToWideChar (item.sPatchValue, valw, 32);
  end;
  Val (item.sFilter, rqsn, e);
  Enabled := item.sAddress <> '';
  str2type (item.sValueType, vtype, vsize);
  hex := (vtype = st_int) and
  (pos ('H', UpperCase (item.sValueType)) > 0);
  if item.sValueType = '' then vsize := 4; // default
 end;
 result := TRUE;
end;


function CalcHash (pdata: Pointer; count: Integer): Integer;
var x: PBytePage absolute pdata;
    n: Integer;
begin
 result := 1;
 for n := 0 to Count - 1 do
     result := ((x [n] + result) xor n);
end;


{ TWatchTable }

function TWatchTable.CheckChanged(nVal: Integer): Boolean;
var h: Integer;
begin
 result := false;
 if not ChkIndex (nVal) then exit;
 h := CalcHash (@FWatches [nVal], sizeof (TWatchValue));
 h := h + CalcHash (@FUpdValues [nVal], sizeof (TTextUpdValue)) shl 16;
 result := h <> hashes [nVal];
 hashes [nVal] := h;
end; // CheckChanged;

constructor TWatchTable.Create;
begin
 inherited;
 nMutex := -1; // default
end;

procedure TWatchTable.Display;
var n: Integer;
begin
 for n := 0 to Count - 1 do
 begin
  WriteLn (n, '. ', FWatches[n].sAddress, ' ', FWatches[n].sPatchValue);
 end;
end; // Display

procedure TWatchTable.OnMessage(msgId: Integer);
begin
 {wtSendMode := wtSendMode and wtUpdate;}
 case msgId of    
  CM_WTCHEAT:
    PatchValues;

 end;
 inherited;
end;

procedure TWatchTable.PatchValues;
var n: Integer;
begin                                      
 Update;
 for n := 0 to count - 1 do
 with FValues [n] do
 case vtype of
  st_int : WriteProcessInt (FValues [n]);
  st_wide,
  st_text : WriteProcessText (FValues [n]);
  st_real : WriteProcessFloat (FValues [n]);
 end;
 wtUpdate := TRUE;
end;

procedure TWatchTable.ReceiveItems;
var n, i: Integer;
begin
 if (ilist = nil) or (cnt = 0) then exit;
 for n := 0 to cnt - 1 do
 begin
  i := AddValue;
  FWatches [i] := ilist [n];
 end;
 // WriteLn ('Recieved ', cnt, ' watch values, total = ', Count);
 Update;
 //wtRecvMode := FALSE;
end; // ReceiveItems;

procedure TWatchTable.SendBack;
var n: Integer;
    sl: TUpdValueList;
    cnt: Integer;

begin
 // Отправка всех значений списка клиенту
 cnt := 0;     
 if not cmgr.AcquireNetMutex(nMutex, 1) then exit;
 try
  for n := 0 to Count - 1 do
  begin
   sl [cnt] := FUpdValues [n];
   Inc (cnt);
   // if array filled, or last iteration
   if (cnt >= MAXUPDVCNT) or (n = Count - 1) then
   begin
    SendMsg (CM_LDATA);
    SendDataEx (sWTUPDVALS, @sl, sizeof (TUpdValueList), cnt);
    cnt := 0;
   end;
  end;
  wtUpdate := FALSE;
  SendMsgEx (NM_LISTADDCOMPLETE, IDWATCHLIST); // operations finished
 finally
  cmgr.ReleaseNetMutex(nMutex, 1);
 end;
end; // SendList

procedure TWatchTable.SetSize(nSize: Integer);
begin
 SetLength (hashes, nSize);
 SetLength (FWatches, nSize);
 SetLength (FValues, nSize);
 SetLength (FUpdValues, nSize);
 // FillChar (FWatches, sizeof (TWatchValue) * nSize, 0);
 inherited;
end;

procedure TWatchTable.Update;
var n: Integer;
    v: PBinaryValue;
    watch: PWatchValue;
    s: String;
    bChanged: Boolean;
begin
 bChanged := FALSE;
 for n := 0 to Count - 1 do
 begin
  v := @FValues [n];
  watch := @FWatches [n]; 
  StrToBinary (watch^, v^);
  s := 'n/a';
  case v.vtype of
   st_int: // Integer values 8-64 bits
     begin
      ReadProcessInt (v^, s);
      { Запись замороженных значений }
      if v.lock then WriteProcessInt (v^);
     end;
   st_real:
     begin
      ReadProcessFloat (v^, s);
      if v.lock then WriteProcessFloat (v^);
     end;
   st_text:
     begin
      ReadProcessText(v^, s);
      if v.lock then WriteProcessText (v^);
     end;
  end; // CASE
  StrLCopy (FUpdValues [n].sAddr, watch.sAddress, s32_len);
  StrCopyAL (FUpdValues [n].sValue, s, s32_len);
  bChanged := bChanged or CheckChanged (n);
 end;
 // обновление в клиенте
 if bChanged then
  begin
   wtUpdate := TRUE;
   // LogStrEx ('Watch values changed',13);
  end;
 if wtUpdate then SendBack;
end;

end.
