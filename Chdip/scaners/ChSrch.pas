unit ChSrch;

interface
uses Windows, SysUtils, TlHelp32, ChTypes, ChShare, ChAlgs, ChStat, MemMap,
  ChSettings;
{
    ��������� ��������� ������� WGC.

    ����� � �������� �������������� �� ���������� ���������: ���, ������� � �������.
 ���������� ��������� �������, ��������� ������ ������ ����������� � �������������
 �� ��� ����������. ���� ������ ��������� (������ ��������� ����� ��������), �� ���������
 ��������� ������ ������� �����������. ���� �� ������ ����� ������ �� ��� ������ ���������
 ������� ������: ��� ������� ���������� �����������, ������ ������������.

    ��������� ������: ��� ������ �������� �������� ������������ ����. � ���� �������
 typeset ����������� ��������� ����� ������� ���������� ���� ������. 

}

const
     szMBI = sizeof (TMemoryBasicInformation);

type
    // ������ ������� � ����� ����������� ������������
TScaner = class (TObject)
  public
      fReadMem: boolean; // ���������� ������ ������ ��� �������������� �����
        oldmap: Boolean;
       funknow: Boolean;      // ������������ ����� �� ���������� ��������
           rqs: byte;         // ����� �������
     CopyCount: LongInt;      // ���-�� ������������� ����
       fRescan: boolean;
        t1, t2: dword;         // ���������� ����������
           map: TMemMap;
      fndstart: dword;         // ������ ����� ��� ���� �������� ���������
      fndlimit: dword;         // ����� ����� ��� ���� �������� ���������
    fException: Boolean;       // ���������� ��� ������
     procedure                  ProcessCreateMap;
  private

     procedure                  AfterScan;
     function                   CopyBuff (size : dword): dword;
     // ��������/��������� �������������� ��������
     procedure                  CreateRqsts;
     procedure                  ResetFound;
     // ������������ �������, ������� - ���-�� �������� ����������
     function                   ScanBuff (size : word): dword;
     procedure                  ScanRegion (var r: TRegion);
     procedure                  ScanBBuff;
     // ����� ������� ..
     function                   SieveBuff (size : word): dword;
     // ��������� ������� - �����������, �����, �����
     function                   ProcessBuff (size: dword): dword;
     function                   AliasTest: boolean;
     function                   InitScaner: boolean;
     // ����� ���������� ������� � ����������� ������
     procedure                  ListAddrs;
    procedure SaveUnknow(const size: dword);
    public
     flBreak : Boolean;          // ���� ���������� �����

     constructor                Create;
     procedure                  LoadFileToCurr (const filename : string);
     procedure                  SaveCurrToFile (const filename : string);
     procedure                  SendScanResults;
     procedure                  Scan;
    end;

var
     lastmp : dword;  // ����� ��� �������� ����� ������
    // ������� �������� : [0] - Ptr, [1] - Index32
    // ������ �������� ��� ������� �������
       slim : dword;
      mscnt : word;
  HeapStart : dword;
        SIS : boolean = false;    
     scaner : TScaner;

function UpdateVMSMap (base, limit: Int64): Int64;

implementation
uses misk, TimeRts, ChCmd, ChPlugin2, ChConst, ChHeap, ChStorage,
     Mirror, SocketAPI, ChServer, DataProvider, ChLog;


var
   region : TRegion;

function UpdateVMSMap;
var n: Integer;

begin
 result := 0;
 //bLong := TRUE;
 ssm.fMap := false;
 scaner.oldmap := false;
 with ssm.svars.params do
 if (base >= 0) and (limit > base) then
  begin
   startofs := base;
   limitofs := limit;
   LogStr (Format ('Setting scan VM range from $%x to $%x', [base, limit]));
  end
 else
  begin
   if startofs <= 0 then startofs := $100000;
   if limitofs <= startofs then limitofs := $7FFF0000;
  end;
 n := 0;
 with ssm.svars.params do
 if (not ssm.svars.aliased) or
     (startofs >= limitofs) then exit;
 // timeouted loop
 scaner.map.SetRescan;
 LogStrEx ('Start creating map', 13);
 while (not ssm.fMap) and (n < 10000) do
  begin
   scaner.map.AddRegion;
   inc (n);
  end;
 LogStrEx ('Complete creating map', 13);
 result := scaner.map.GetVMSize;
 if result > 0 then
  begin
   LogStrEx(Format ('Map rescaning complete, RangeVMSize = %d',
         [scaner.map.GetVMSize]), 14);
   SendMsgEx (NM_MAPCOMPLETE, scaner.map.GetVMSize);
  end
 else LogStrEx ('Map rescaning result fails', 12); 
end; // UpdateVMSMap


constructor            TScaner.Create;
begin
 inherited;
 fReadMem := false;
 statman := TStatman.Create;
 map := TMemMap.Create;
 dllrng.min := HINSTANCE;
 dllrng.max := dllrng.min + 256 * 1024; // ���� �������� 256�.
 dynarng.min := 0;
 dynarng.max := 0;
end;

procedure              TScaner.CreateRqsts;
// �������� �������������� �������� �� ���������� � ������ RqsLst
var
   n : byte;
begin
 // ���� �� ���������� ��������
 for n := 1 to maxRqs do
 with ssm.rqslst [n] do
 if Enabled then        // ���� ������� - ���������� (���������) ��� ����������
  begin
   // Unknow scan - ����������� ����������/��������� �������
   if (sactn = _copy) or
      (sactn = _scan) and (not Unknow) // ������������ � ��������
        then   AddRequest (n, ssm.rqslst [n]); // ���������� �������
   if (sactn = _sieve) or
      (sactn = _scan) and Unknow // ������������ ����������� ��������
        then   UpdRequest (n, ssm.rqslst [n]); // ���������� �������
   ASSERT (founds [n] <> nil, '�� �������� ��������� �����������.');
  end;
end;



function                TScaner.AliasTest: boolean;
begin
 result := true;
 if (ssm.svars.alias = 0) then
  begin
   SendStrMsg (' ��� ������ �������� - � ��� ������ ?');
   ssm.fComplete := true;
   result := false;
  end;
end; // AliasTest

function              TScaner.InitScaner : boolean;
var
    rq : byte;

begin
 result := false;
 // �������� ������
 ssm.fComplete := false;
 if not AliasTest then Exit;
 ssm.SVars.fbreak := false;
 // �������� ������� ��������
 if ssm.SelRqsCnt = 0 then
  begin
   SendStrMsg ('������: �� ������ �� ���� ������.');
   exit;
  end;
 // ��������� �������� ����������
 ssm.svars.sofst := 0;
 StartCounter (2);      // ����������� �������� ������ 
 ssm.SVars.readAll := 0; // �� ����� ... 
 ssm.svars.scanAll := 0;
 rqs := ssm.CurrRqs;     // ��������� ������
 ResetFound;   // ����� ����������� ���������� �������
 CreateRqsts;  // ��������/��������� �������������� ��������
 // ��������� �������
 GetTimerElapsed (1, ssm.timers [3]);
 if ssm.SVars.orNeed then statman.Reset;
 if map.dwAddr = 0 then map.dwAddr := 65536;
 /// -------------- ������ ������ ��� ������������ -------------- ///
 t2 := 0;
 // ������ ������ ����������� ������
 // if ssm.svars.mmsize <= 256 * 1024 then ssm.fMap := false;
 // ��������� �������� ������    
 map.sptr := ssm.svars.params.startofs;
 map.bptr := ssm.svars.params.limitofs;
 map.WorkFlags := CalcWorkFlags;
 map.CompleteMap; // ���������� �������� ������������� � ������
 map.Reset;
 // ���������� ��������� � ������ ������ ��� ������
 funknow := false;
 for rq := 1 to MaxRqs do
 if (founds [rq] <> nil) and (ssm.rqslst [rq].enabled) then
  begin
   founds [rq].Prepare (map.WorkFlags);
   funknow := funknow or founds [rq].common.Unknow; // ��������� �����
   if (founds [rq].common.Unknow and (founds [rq].common.sactn = _copy)) then
       ssm.svars.fnds [rq].unk := true; // �������� ��� �������
  end;
 result := true;
 if (funknow) then mirr.ResetRefs;      // ����� ���������
 StartTimer (1);   // ������ ������� ��� ������ ���������� �������
 StartCounter (1); // ���������� ������� ������ CPU
end;


// ���������� ������� ������������ ������ ��������
// ���������� ��� ����������� ��������� �� shell
procedure               TScaner.Scan;
begin
 if not InitScaner then exit;
 // ���� ������ / ������
 flBreak := false;
 repeat
  map.offset := 0;
  if not ssm.spyvars.fSpyMode
     and (ssm.svars.Priority <> THREAD_PRIORITY_TIME_CRITICAL)
     and (pWgcSet.bUpdateUI) then
   begin
    t1 := GetTickCount shr ssm.svars.stick;
    if (t1 <> t2) then
     begin
      t2 := t1;
      GetTimerElapsed (1, ssm.timers [9]);
      SendMsgEx (NM_SCANPROGRESS, ssm.svars.scanAll, GetElapsed (9));
     end;
    end;  
   flbreak := flbreak or (map.dwAddr >= map.BPtr);
   flBreak := flBreak or ssm.svars.fbreak;
   if (flBreak) then break;       // ���������� ��������
   // ������ ���� ������
   if ssm.SpyVars.fSpyMode then  map.HeapTest;
   //  -> ������ ������� ��� ������������
   map.SelectRegion (map.dwAddr, region); // ����� �������
   // ������ ������ � ������� �������� - ��� ������
   if region.size = 0 then
   begin
    flBreak := flBreak or (region.ofst >= map.bptr); 
    if region.rsize = 0 then region.rsize := 4096;
    map.dwAddr := map.dwAddr + region.rsize;
    continue; // ��� ������ �����������!
   end;
  //  -> ����������� ������� �� ������ � ������� ������ � ������������
  ScanRegion (region);   // ���� �������� ������
 until flBreak;
 AfterScan;              // ���������� ����������
 ssm.fFileLoad := false;
end; // Scan

procedure               TScaner.ScanRegion;
var
    rcount, scount: Integer;
         s: string;

Begin
 scount := 0;
 rcount := region.size; // ���������� ���� ��� ������
 // ����������� ��������� �� ������
 if map.dwAddr <> region.ofst then map.dwAddr := region.ofst;
   Repeat
    map.offset := 0; // ����� ��������
    try              // w - finnaly
    try              // w - except
    // - ���������� �������� ������� ������� �� ������ ������������ ��������
    CopyCount := map.CopyProcessMem (rcount); // used ipAddr @source ptr
    // -> ���� ������������ �������� ������� �� ��������
    // %%%%%%%%%%%%%%%%%%%%%%%% SCANING or SIEVING %%%%%%%%%%%%%%%%%%%%%%%%%%%% //
    if copyCount > 0 then ScanBBuff;
    rcount := rcount - CopyCount;// ������� ����������
    scount := scount + CopyCount;
     // =============================================================
     // ������������ ������ ����������, ��� ����� ��� ����������� ������
     if (fndstart > 0) and (fndlimit > fndstart) then
      begin
       fndstart := Round4K (fndstart);
       fndlimit := Round4K (fndlimit);
       statman.AddStat (fndstart, fndlimit, region);
      end;
    except
     // ��������� ����������
     s := '#ERROR: �� ����������� ���������� � ScanRegion,';
     s := s + ' ����� ������������: $' + dword2Hex (map.dwAddr);
     SendStrMsg (s);
     fException := true;
     ssm.svars.fbreak := true;
     ssm.fComplete := false;
     {$IFOPT D+}
     OutputDebugString (PChar (s)); // ����������� ���������
     {$ENDIF}
     // asm int 3 end;
    end; // try - except;
    finally
    // �������� ��������� ������� ������ ������� !
    if CopyCount > 0 then
      map.dwAddr := map.dwAddr + dword (CopyCount)  else
    // ���� ������ �� ����������� - ������� �����
    if rcount > 4096 then
       begin
        map.dwAddr := map.dwAddr + 4096;
        rcount := rcount - 4096;
        // rcount := 0; // ??
       end
      else
      // ������� ������ - �������� �� 4� ���������
      begin
       map.dwAddr := map.dwAddr + DWORD (rcount);
       rcount := 0;
      end;
    end; // try - finally
   Until rcount = 0;  // ���� �� ����������� ���� ������
    // - ��������� ���������� �� ���������� ��������
    with ssm.SVars do ReadAll := ReadAll + scount;
end; // TScaner.ScanRegion

procedure TScaner.AfterScan;
var
   rq: byte;
begin
 statman.Save;
 ssm.svars.sofst := map.dwAddr;
 for rq := 1 to MaxRqs do
 if (founds [rq] <> nil) and (ssm.RqsLst [rq].enabled) then
     founds [rq].AfterScan;
 /// -------------- ����� ������ ��� ������������ -------------- ///
 mirr.FreeBlocks();
 ListAddrs;
 StartCounter (10);
 inc (_scanid);
end; // AfterScan 

procedure TScaner.ProcessCreateMap;
var n: Integer;
begin
 n := 0;
 scaner.map.hProcess := ssm.svars.alias; // ��������� ��������
 // ��������� ���������� � ������������ ������ chdip.dll
 dynarng.min := dword (lastalc) and $FFFF0000; // 64K Base
 map.Lock;
 {shmrng.min := dword (theMap);
 shmrng.max := shmrng.min + MapSiz;}
 // ���� ������������ �������� ��������
 if not fReadMem then
 repeat
  n := n + 1;
  // ��� ��������� � ������������ �������� ������� ��������!.
  scaner.map.AddRegion;
  if not Assigned (pWgcSet) then asm int 3 end; 
  fReadMem := ssm.fMap and pWgcSet.bIdleRead;  // ��������� ������������ �����
  fReadMem := fReadMem and not (ssm.SpyVars.fSpyMode); // ����������� �����������...
  scaner.map.ReadOfs := 0; // ����� �������� ������
 until (n > 64) or (ssm.fMap and (n > 4)) or fReadMem // �� ������ ������� ���������
 else fReadMem := scaner.map.IdleRead;
 if not oldmap and ssm.fmap then
  begin
   // sends regions??
  end;
 oldmap := ssm.fmap;
 map.Unlock;
end;

{ ���������� ����������� ������ }
var
   savedFile: string = '';

procedure      TScaner.SaveCurrToFile;
var
   hdr: TBankHdr;
   bnk: PBank;
   str: PStorage;
   rqs: Byte;
    ff: File;
    ns: Byte;
   fnd: Integer;
begin
 // ���������� ���� ������ � ����
 rqs := ssm.CurrRqs;  // ������� ������
 if nil <> founds [rqs] then
 with Founds [rqs] do
  begin
   if (Found = 0) then exit;
   savedFile := tempDir + '\' + fileName;
   Assign (ff, savedFile);
   {$I-}
   ReWrite (ff, 1);
   if IOresult > 0 then savedFile := ''
   else // ����������. ����������
   try
    fnd := Found;
    BlockWrite (ff, fnd, 4); // ���������� ��������� ����������
    for ns := 1 to MaxSubRqs do
    if (slist [ns] <> nil) then
    begin
     str := @slist [ns];
     bnk := @str.banks;
     hdr.subrqs := ns;
     Repeat // ���� �� ������
      hdr.minofs := bnk.minofs;
      hdr.maxofs := bnk.maxofs;
      hdr.banksz := bnk.banksz;
      if (bnk.banksz > 0) then
       begin
        BlockWrite (ff, hdr, SizeOf (hdr));
        BlockWrite (ff, bnk.bptr^, bnk.banksz);
       end;
      bnk := bnk.next;
     Until (bnk = nil);
    end; // ���� �� ��� ��������
   finally
    CloseFile (ff);
   end; 
   {$I+}
  end;
end; // SaveCurrToFile;

procedure      TScaner.LoadFileToCurr;
var
   hdr: TBankHdr;
   bnk: PBank;
   rqs: Byte;
   srq: Byte;
    ff: File;
    ns: Byte;
   fnd: dword;
begin
 if (SavedFile = '') then
  begin
   ssm.fFileLoad := true; // ����� ������� ��� ����..
   exit; // ��� ������������ �����
  end;
 rqs := ssm.CurrRqs;
 if (nil = founds [rqs]) then exit;
 Founds [rqs].Free; // �������� ��� ��������
 AssignFile (ff, SavedFile);
 {$I-}
 Reset (ff, 1);
 if IOresult = 0 then
 with Founds [rqs] do
  begin
   ssm.svars.fnds [rqs].foundCount := 0;
   // �������� �������� ��������
   for ns := 1 to MaxSubRqs do
     if (slist [ns] <> nil) then
      begin
       slist [ns].Free();
       FreeAndNil (slist [ns]);
      end;
   BlockRead (ff, fnd, 4); // ���������� ��������� ����������
   if (fnd > 0) then // ���� ���� ��������� � ����������
   repeat // Read Cycle
    // ���������� ��������� �����
    BlockRead (ff, hdr, SizeOf (hdr));
    srq := hdr.subrqs;                     // ���������
    // ������ �������� ���������
    if (srq = 0) or (srq > MaxSubRqs) then break; // ��������� ������
    if (hdr.banksz = 0) then break;  // ���� �������
    rlist [srq].enabled := true;     // ���� ����� ������
    // �������� ������ ��������� ��� �����
    if (slist [srq] = nil) then slist [srq] := TStorage.Create
                           else slist [srq].AddBank; // �������� ����!
    // ������������� ����� ������� ���������
    bnk := slist [srq].last;
    bnk.minofs := hdr.minofs;
    bnk.maxofs := hdr.maxofs;
    if (hdr.banksz > bnk.banksz) then hdr.banksz := bnk.banksz;
    // ������ ������ � ���� �� �����
    BlockRead (ff, bnk.bptr^, hdr.banksz, bnk.banksz); // ��������
    bnk.tail := nil;
    bnk.GetTailPtr;     // ������ �����...
   until eof (ff);
   if eof (ff) and (fnd > 0) then
    begin
     ssm.svars.fnds [rqs].foundCount := fnd;
     Found := Fnd;
    end;
  end; // with
 Close (ff);
 {$I+}
 ListAddrs;
 ssm.fMap := false;
 map.fsieve := false;
 map.sievmap.full := false;
 map.lastmap.full := false;
 map.Reset;
 map.fRescan := true;
 ssm.fFileLoad := true;
end; // LoadFileToCurr;


procedure      StoreResults (const rqs: byte; const bank: PBank; pa: dword);
begin
  if (_Lcount = 0) or (_Found = 0) then exit; // ������ ���������
  if (_packalg = 0) then  // �������� �� �������������� ����
      bank.PackList (pa, pwhole, _Lcount);
  if (_packalg = SETPACK) then PackRLE (pwhole, @bank.tail.list, _Lcount);
  if (_packalg = RLESET) then OverPack (@bank.tail.list, _Lcount);
  if (_packalg = RLESETP) and (_Found > 0) and (_Lcount > 0) then bank.StorePacked (pa, _Lcount, _Found);
   // ����������� ���������
 with founds [rqs] do found := found + _Found;
end; // StoreResults

procedure               TScaner.SaveUnknow (const size: dword);
begin
 if (_Found > 0) then // ���������� ������� ����
    mirr.AddBlock(map.sbf, map.ipAddr, size);
end;

procedure       TScaner.SendScanResults;
const  dsize: Integer = sizeof (TFoundRec);
var
    dp: TDataPacket;
    sinf: ^TScanProcessInfo;
    n: Integer;
begin
 // ssm.svars.fnds;
 sinf := @dp.bindata;
 sinf.foundVals := ssm.FoundAll;
 sinf.scanCount := ssm.svars.scanAll;
 with ssm do
 sinf.scanTime := Tacts2sec (counters [10] - counters [1]);
 SendMsg (CM_LDATA);
 SendData (sSCANPSINFO, @dp);
 SendMsgEx (CM_CLEARLIST, IDADDRSLIST);
 if (dsize > sizeof (dp)) or
    (ssm.FoundAll = 0) then
    exit;
 with ssm.svars do
 for n := 1 to MAXRQS do
 with fnds [n] do
 begin
  if (fnds[n].foundCount = 0) then continue;
  Move (fnds [n], dp.bindata, dsize);
  SendMsg (CM_LDATA); // ������������ ������
  SendData (sFNDRESULTS, @dp);
 end;
end;

procedure       CheckBankFull (const stor: PStorage;var bank: PBank; const rqs, srq: byte);
begin
 // �������� �� ���������� �����
 if (bank.GetRest < MinFree) or
        (dword (bank.tail) + MinFree >= bank.blimit) then
     begin
      stor.AddBank; // �������� ������ ����
      bank := stor.last; // �������� ����
     end;
end; // CheckBankFull


function                   TScaner.CopyBuff (size : dword): dword;
var
   n: dword;
   srq: TRequest;
  bank: PBank;

begin
 result := 0;
 { ������������� �� ���������:
   1. ��������� ������ ��� �������
   2. ����������� �������
   3. ����������� � ���� ���������� � ���������������� ��������� ���������� ����������
 - ������� ������������ ���� �� ������ ���� �����������, �������� �������
 }
 if (size > 64) then
 with founds [rqs] do
 for n := 1 to 3 do
 if rlist [n].enabled then
 begin
  srq := rlist [n];
  mirr.AddBlock (map.sbf, map.ipAddr, size); // ���������� ������ � ��������� �������
  GetLast (rqs, n, bank);
  _Lcount := 4;                 // ������ ��������
  _Found := size;               // ���� ������� ������
  result := _found;
  _Isize := 2;
  // ��������� ������ ��� ������������
  StoreResults (rqs, bank, map.ipAddr);
  CheckBankFull (@slist [n], bank, rqs, n);
  exit; // ���������� ����� �� �����
 end;
end; // CopyBuff

{\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\}
// ��������� ������������ ������� ������� (������� ��� @self)



function      TScaner.ScanBuff (size : word): dword;


 // ������������ ������ ���-�������
 function  ScanSubRqst (const num: byte): dword;
 var
         srq: TRequest;
    scanProc: TScanProc;
       plist: PPackList; // ������ ��� ������
        bank: PBank;     // ������������ ���� ������
        stor: PStorage;  // ��������� ���� �������� ���������
        item: PPackItem;
        indx: dword;
 Begin
  result := 0;
  if (fException) then exit; // ���������� ���������� �� ����������
  srq := founds [rqs].rlist [num];
  ResetVars; // ����� ���������� ������
  // ��������� �������
  InitExamples (srq);
  ScanProc := GetScanProc (srq);
  if (@ScanProc = nil) then exit;    // ���� �� ������� ��������� �������
  stor := @founds [rqs].slist [num]; // ������������ ������� ���������!
  if (srq.Unknow) then
  with founds [rqs] do
   begin
    bank := slist [num].FindBank(map.ipAddr); // ����� ���� � ������� ������ �����
    if (bank = nil) then exit;  // � �����������
    item := bank.FindPtr (map.ipAddr);
    if (item = nil) then exit;  // �� ��� �� ����
    // ����� ���������� ����� ������
    indx := mirr.FindBlock(map.ipAddr);
    // ��������� ��������� ����� ������
    _OldBuff := mirr.GetBlock (indx); // ������������ - ���� ������ � �������
    if (_oldbuff = nil) then exit; // ����� ��������
    if (size > mirr.blist [indx].bsize) then
        size := mirr.blist [indx].bsize; // ��������� ������� �������
    stor := founds [rqs].slist [num].nStor; // ����� ��������� �����������
    if (stor = nil) then exit;  // ��������
    plist := stor.LastPtr; // ��������� ���������
    bank := stor.last;     // ��������� ����
   end
  else
   begin
    // ��������� ��������� ������ ��� ��������
    plist := GetLast (rqs, num, bank);
   end;
  // �������� �� ���������� ������������
  if (plist <> nil) then
  // ���������� �����
  try
   _found := 0;
   // ������� ���������������� �������
   ScanProc (map.sbf, plist, size); // ������������ �����
   /// =========== ������������ ��������� ================== ///
   // ���������� ��������� ������������
   if (_Lcount > 0) and (_Found > 0) then
        StoreResults (rqs, bank, map.ipAddr);
   if (srq.Unknow) then SaveUnknow (size); // ���������� �������� �����
   // UnkScan: ����� � ������������ ����� ���������
   CheckBankFull (stor, bank, rqs, num); // �������� �� ���������� �����
  except
   On EAccessViolation do
    begin
     fException := true; // ��������� ������
     ods ('Access Violation, Scan ptr: $' + dword2hex (map.dwAddr));
    end
   else
    begin
     ods ('Wild Exception on TScaner.ScanBuff');
     fException := true;
    end;
  end; // try-except
  result := _found;
 End;


var
   n : byte;

Begin
 result  := 0;
 // ������������ ����� ������� �� �����������
 try
  if (rqs in [1..MaxRqs]) then
  with founds [rqs] do
  for n := 1 to MaxSubRqs do
  if (rlist [n].enabled) then result := result +  ScanSubRqst (n);
 except
  On Exception do fException := true;
 end;
End; // ScanBuff

var // ���������� ����������
    err: String;
{!!!!!!@@@@@@@@@@@@@@@@@@@@@~~!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function       TScaner.SieveBuff;
 // ����� � ������� sbf.
 function       SieveSubRqst (const num: byte): dword;
 var srq: TRequest;
     SieveProc: TSieveProc;
     bank: PBank;
     stor: PStorage;
    plist: PPackList;
   pslist: PPackItem; // �������� ������ � ����������
    count: dword;
     indx: dword;
 begin
  result := 0;
  ASSERT (num <= MaxSubRqs, '������� ������������� ���������� � ������� �������: ' + IntToStr (num));
  if (fException) then exit; // �� ���������� ���������� ����������

  with founds [rqs] do
   begin
    srq := rlist [num];   // ����������� �������
    _Lcount := 0;
    ResetVars;            // ����� ����� ����������
    InitExamples (srq);   // ��������� �������
    SieveProc := GetSieveProc (srq);
    if (@SieveProc = nil) then exit; // ��� ������� �� �������
    // ����� ����� ���������������� �������� �������
    bank := slist [num].FindBank (map.ipAddr);
    if (bank = nil) then exit;  // �� ������ ���� - �� �������� �����
    pslist := bank.FindPtr(map.ipAddr); // ����� ��������� ������
    if (pslist = nil) then exit;
    if (map.CorrectAddr (pslist.paddr)) then else exit;
    bank.curr := pslist;
    if (srq.Unknow) then
     begin
      // ��������� ������ �����/������ ������������ ��������
      indx := mirr.FindBlock(map.ipAddr);
      _oldbuff := mirr.GetBlock (indx);
      if (_oldbuff = nil) then exit; // �������� ����������
      if (size > mirr.blist [indx].bsize) then
          size := mirr.blist [indx].bsize;
     end;
    count := pslist.count;      // ���������� ��������� ������
    if (dataneed = SETPACK) then
        UnpackRLE (@pslist.list, pprevd, count);
    if (dataneed = NPACKED) then
      begin
       _Lcount := bank.UnpackList (pprevd); // ����� ��������� ����������
       assert (_Lcount = bank.curr.found, '�������������� ��� ����������')
      end;
    stor := slist [num].nStor;  // ��������� ��� ����������� �����������
    ASSERT (stor <> nil);       // ���� �� ������� - ��������
    plist := stor.LastPtr;
    passed := 2;
    SieveProc (map.sbf, pprevd, plist, _Lcount);  // ���������� �����
    if (passed = 1) then
     begin
      err := 'Sieve: ����� ���������� ����� ������� ������.';
      ods (err);
      raise Exception.Create (err);
     end;
    // ��������� �������� � ����� ���������
    ASSERT (stor <> nil, '���� ��������� ������ ���������');    // ���� �� ������� - �������� 2
    if (srq.Unknow) then SaveUnknow (size); // ������ ������ ���������
    StoreResults (rqs, stor.last, map.ipAddr);
    CheckBankFull (stor, stor.last, rqs, num);          // �������� ������������ �����
   end;
   result := _Found; 
 end; // SieveSubRqst

var n: byte;
begin
 result := 0;
 try
  with founds [rqs] do
  for n := 1 to MaxSubRqs do
  if (n <= MaxSubRqs) and
    (rlist [n].enabled) and (slist [n] <> nil) then result := result + SieveSubRqst (n);
 except
  On EAccessViolation do
   begin
    ods ('Access Violation, Sieve ptr: $' + dword2hex (map.dwAddr));
    fException := true;
   end;
 end;
end; // SieveBuff

function      TScaner.ProcessBuff;
begin
 result := 0;
 // ������� �� ���� ������
 case ssm.RqsLst [rqs].sactn of
   _copy : result := CopyBuff  (size); // ���������� ������
   _scan : result := ScanBuff  (size); // ����������� ������
  _sieve : result := SieveBuff (size); // ��������� ������
 end; // else
 // ������������� ����������� ������
 if (founds [rqs] <> nil) then
 with ssm.svars.fnds [rqs] do
      foundCount := founds [rqs].found;
end;


procedure       TScaner.ListAddrs;
var n, nc: Integer;
begin
 // ��������� ���������� ������� ��� ������� ����������� ��������
 for n := 1 to MaxRqs do
 begin
  nc := 0;
  if ssm.RqsLst [n].Enabled and
     (founds [n].found > 0) then
   begin
    ssm.svars.fnds [n].rqsn := n;
    nc := founds [n].Unpack (ssm.svars.fnds [n].addrs);
    if (nc > founds [n].found) then founds [n].found := nc;
   end;
  ssm.svars.fnds [n].addedCount := nc;
 end;
end; // ListAddrs

procedure     TScaner.ScanBBuff;
     var
         n: byte;
    ccount: LongInt;     
     count: dword;
    lfound: dword;
BEGIN
 fndstart := 0;
 if CopyCount < 128 then exit; // �������� ������
 ccount := copyCount;
 // ��������� ��� SPY_MODE
 if ssm.SpyVars.fSpyMode and (ccount > 64) then Dec (ccount, 64);
 // ��������� �������� (� �������)
 map.offset := 0;
 // ���������� �� ������ ���-�����
 ccount := (ccount shr 6) shl 6;

 Repeat // ���� �� �������
  ssm.svars.sofst := map.dwCurrPtr; // Interface variable
  count := ccount;
  if count > sbfSize then count := sbfSize; // ����������� 1023 * 64
  // ������������ ��������� ��������� ������� ������� �� 64 ����� (������������� �����).
  if count > 64 then
   Begin
    // ������ SpyMode - ��������� �����
    if pWgcSet.bPrefetch  // MMX uses PIII internal prefetch
                         then Prefetch ( map.sbf, count );
    fException := false;
    lfound := 0;
    /// ===================  ���� ������������ �� �������� ================= ///
    for n := 1 to MaxRqs do
       if ssm.RqsLst [n].enabled then // ������ ������� ?
        begin
         if (fException) then break; // �������� ������������ ����� �������
         rqs := n;                // ���� �� ��������
         lfound := lfound + ProcessBuff (count);     // ���������� ������
        end; // ���� �� ��������
       if lfound > 0 then
         begin
           if fndstart = 0 then fndstart := map.ipAddr; // ����� ������ ��������, ��� ����������
           fndlimit := map.ipAddr + count; // ������ ���������
         end;
       // ������������ ���������������� ������
       Inc (ssm.svars.scanALL, LongInt (count));
        if (count >= 64) then
             map.offset := map.offset + count
        else Inc (map.offset, 64); // ����������� �������� � �������
       End // count > 256
     else Break; // ���������� �����
  Dec (ccount, count);
 Until  ccount < 64; // ��������� ����� �� �����������
END; // scanRegion

procedure              TScaner.ResetFound;
var
   n : byte;
begin
 pkfound := 0;
 for n := 1 to maxrqs do
 if (ssm.RqsLst [n].enabled) then
 with ssm.svars.fnds [n] do
  begin
   foundCount := 0;
   addedCount := 0;
   scaned := 0;
   unk := false;
  end;
end; // ResetFound

initialization
finalization
 if (SavedFile <> '') and FileExists (SavedFile) then
    DeleteFile (SavedFile); // �������� ���
end.


