{$DEFINE Windows}
unit MemMap;

interface
uses Windows, ChTypes, ChConst, SimpleArray, PSLists, SyncObjs;

{ ����� ����� ������, ������������ ��� ��������� ������� �������� ������ ��������

  proc AddRegion;
     Idle-Time ������� ���������� ����� ��������. �� ����� �����������
  ��� �������� ���������� ����� ����� ��������, ������� ����� �������� ������.
  ����������� ��� ���� �� ���� ������ fRescan � ������� FindRegion ������� ����
  ������ ���������.
  ---------------------------------------------------------------------------
  proc FindRegion;
     ��� fReScan = true, ���������� ������� VirtualQuery* ��� �����������
  ����������� ������� � ������� dwAddr.
     ��� fRescan = false, ���������� ����� ����� ��� ��������� ��������, �
  �������� �� ��� ���� � ������ �������, ���� � ��������� �������.
  ---------------------------------------------------------------------------
  proc SelectRegion;
     ������� ������� ��� ������ ������������ ������  dwAddr. ������� ���������
  ����������� ������������� ��������, �������� ��� ������ ���������� ������
  �� ��� �� ��������� ����� ���� �� ���� �������� ��������.
  ---------------------------------------------------------------------------
  proc NextSieveReg;
     ������������ ������������� � �������� ������ ������. ���� �������
  ��� � FindRegion, �� ������ � ������� �� ����� ���-���� ����������.
  ---------------------------------------------------------------------------
  proc EndRegion
     ��������� ������-���������� � ����� ������. ����� ���� ����� ���������
  �����������.       

  FAddr ������������� � bbf

}

const

     MaxBuffer = 1024;

     maxbbfSz  = 8 * 1024 * 1024; // ������������ ������ ������� = 8MB
     sbfdef =  56; // ������ ������� �� ���������
var
     sbfSize: DWORD = 56 * 1024; { 768 cache line, as whole buffer }

type
    tBBF = array [0..maxbbfSz] of byte;
    pBBF = ^tBBF;
    TWild = array [1..256] of byte;
    TPtrUnion = record
     case Byte of
      0:(lp : Pointer);
      1:(dw : DWORD);
    end;

type

 TRegionArrayEx = class (TRegionArray)
 protected
  procedure                     SetSize (nSize: Integer); override;
 public
  index: Integer;
   full: boolean; // ������ ������������
  lastPtr: DWORD;
  FUsed: array of Boolean;
  constructor                   Create (lIdent: Integer); // ��������� �� ���������
  procedure                     AddRegion (const reg: TRegion); override;
  procedure                     Clear; override;
  function                      Find (const ofst: DWORD; var r:TRegion): Boolean;
  procedure                     Get (var r: TRegion);
  procedure                     SetAllUnused;
  procedure                     Load (src: TRegionArrayEx);
  procedure                     SetUsed (const r: TRegion);
 end;

 ///////////////////// MEMORY MAP CLASS //////////////////////////
 TMemMap = class (TObject)
 private
    FAddr: TPtrUnion;    // ��������� ������ ������������ ��������
    FBuffSize: DWORD;
 function       GetSbf: pointer;
 function       GetOfs: DWORD;


 // ���������� ������� � ������������ �����
 procedure      EndRegion (var reg: TRegion);

 procedure      FilterReg (var reg: TRegion);
 function       FindRegion (const ofst: DWORD;var reg : TRegion) : boolean;
 function       RWTestReg (const reg: TRegion; selfTest: boolean): boolean;
 procedure      StoreRegion (var reg: TRegion);
 procedure      TestMapUpdate;
 
 public
    WorkFlags : DWORD;        // ������ ���������� ��������
      fRescan : boolean;      // ���� ������ ����������������� ����� ������
      bbf : pointer;          // ����� �������� �������
      sptr, bptr :DWORD;     // ��������� � ���������� ����� ������������
          offset :DWORD;         // �������� ������ �������� �������

      hProcess: THandle;
      lastmap, // ��������� ������ �����
      tempmap,  // ����� ����������� ���������
      sievmap,  // ����� ����������� ����� �������
      regions   // ����� ������������ ��� ������
              : TRegionArrayEx;
      tmpofst : DWORD;

       fsieve: Boolean; // ������� �����
      ReadOfs: DWORD;
      scshare: TCriticalSection;
      property    sbf : pointer read GetSbf; // ����� ������ �������

      property    dwAddr: DWORD read FAddr.dw write FAddr.dw;
      property    lpAddr: pointer read FAddr.lp write FAddr.lp;

      property    ipAddr: DWORD read GetOfs; // ������ ��������
      property    bbfSize: DWORD read FBuffSize;
      procedure                AddRegion;
      function                 CopyProcessMem (count: DWORD): DWORD;  overload;
      function                 CopyProcessMem (ipa: DWORD; count: DWORD; buffsz: DWORD): DWORD; overload;
      constructor              Create;
      procedure                CompleteMap; // ���������� ������ ��������
      function                 CorrectAddr (const ofst: DWORD): boolean;
      procedure                Free;
      function                 GetVMSize: Int64; 
      procedure                HeapTest;
      function                 IdleRead: boolean;
      procedure                InitBuff (const size : DWORD);
      procedure                FreeBuff;
      function                 NextSieveReg (cptr: DWORD; var reg: TRegion): boolean;
      procedure                Reset;
      procedure                SetRescan; // ��������� �� ���������������� �����
      procedure                SelectRegion (const ofst: DWORD;
                                              var reg: TRegion);
      // ������� ��������� ������ ������ ��������
      function                 dwCurrPtr: DWORD;
      function                 lpCurrPtr: pointer;

      procedure                Lock;
      procedure                Unlock; 
     end;

// ������������
var
      dynarng: TRange;        // ���� chdip.dll
       dllrng: TRange;        // ���� ����
       shmrng: TRange;        // ����� ������

function       CalcWorkFlags : BYTE;


implementation
uses ChShare, Misk, ChSrch, ChStat, SysUtils, ChHeap, ChCMD, ChLog,
     netipc, ChServer, DataProvider;


procedure             SetRegion (var rg: TRegion;
                                 const prot: DWORD;
                                 const rsiz: DWORD;
                                 const size: DWORD;
                                 const ofst: DWORD);
begin
 rg.protect := prot;
 rg.rsize := rsiz;
 rg.size := size;
 rg.ofst := ofst;
 rg.abase := ofst;
end;

// ��������� ����� ������� ��� ��������� ��������
function       CalcWorkFlags : BYTE;
var n : BYTE;
begin
 Result := 0;
 for n := 1 to Maxrqs do
 if ssm.RqsLst [n].enabled then
   case ssm.RqsLst [n].sactn of
    _copy, _scan : result := result or 1; // �������� ������������ ��� �����
          _sieve : result := result or 2;
   end; // case
end; // WorkMask


constructor           TRegionArrayEx.Create;
begin
 inherited;
 Clear;
end; // TRegionArrayEx.Create


procedure               TRegionArrayEx.Clear;
begin
 full := false;
 FCount := 0;
 Index := 0;
 VirtualSize := 0;
 lastPtr := 0;
 inherited;
end; // TRegionArrayEx.Clean

function                TRegionArrayEx.Find;
var n: DWORD;
begin
 result := false;
 // �������� ���������� �������
 if (FItems [index].ofst > ofst) then index := 1;
 // ������������ ��������� (���� ��� ����� ������� �������)
 for n := index to ItemsCount do
 if FItems [n].ofst >= ofst then
 begin
  r := FItems [n];
  index := n;
  result := true;
  break;
 end;
end; // TRegionArrayEx.Find

procedure               TRegionArrayEx.Get;
begin
 r := GetItem (Index);
 Inc (Index); // Next Item
end;

procedure               TRegionArrayEx.Load;
var n: Integer;
begin
 if not Assigned (src) then  exit;
 full := src.full;
 Index := 0;
 Clear; // destination must be cleared
 for n := 0 to src.ItemsCount - 1 do
  if src.FUsed [n] then AddRegion (src.FItems [n]);
 VirtualSize := src.VirtualSize;
end; //  TRegionArrayEx.Load



constructor           TMemMap.Create;
begin
 inherited Create ();
 bbf := nil;
 scshare := TCriticalSection.Create;
 hProcess := 0;
 regions := TRegionArrayEx.Create (IDREGIONLIST);
 sievmap := TRegionArrayEx.Create (IDREGIONLIST);
 tempmap := TRegionArrayEx.Create (IDREGIONLIST);
 lastmap := TRegionArrayEx.Create (IDREGIONLIST);
 tmpofst := 0;
end;


procedure             TMemMap.CompleteMap;
begin
 // ����, ����� ������� ��������� ����� ������
 if (WorkFlags =  1) and fsieve then
 // ���� ��������� ��������� �����
 if (lastmap.full) then
  begin
   regions.Load (lastmap);
   fsieve := false;
   ssm.vmsize := lastmap.VirtualSize; // ������ ������ ��������
   ssm.fMap := true;
  end;
 // ����, ����� ������� ����� ������
 if (WorkFlags = 2) and not ssm.fMap then
 if (sievmap.full) then
  begin
   regions.Load(sievmap);
   fsieve := false;
   ssm.fMap := true;
  end;
 while not ssm.fMap do AddRegion;
end;


function              TMemMap.CopyProcessMem (ipa: DWORD; count, buffsz: DWORD): DWORD;

var
   pptr, dst: pointer;
   ptro: DWORD absolute pptr;
   dsto: DWORD absolute dst;
   ptrl: DWORD;         // ������ ������� �����������
   reads: DWORD;
   blocksz: DWORD;

Begin           
 if ssm.spyVars.fSpyMode  then result := count
  else
   begin
    blocksz := sbfSize * 2;   // ������ ����� ����������� - 112K (������������ �� ��� ������ L2)
    pptr := ptr (ipa);        // ����� ������ ��������
    if (count > buffsz) then
       ptrl := ptro + buffsz  // ptr limit insure
    else
       ptrl := ptro + count; // ��������� �������
    dst := bbf;   // ������ �������� �������
    result := 0;
    if blocksz < 4096 then
     begin
      blocksz := 4096;
      ods('#Warining: Blocksize for CopyProcessMemory below 4K');
     end;
    repeat
     // �������������� ������ �����
     if (ptrl - ptro < blocksz) then blocksz := ptrl - ptro; // ������� �� �������������
     ReadProcessMemory (hProcess, pptr, dst, blocksz, reads); // ����������� ���� �����
     if blocksz > reads then
       ods ('ReadProcessMemory error. ');
     ptro := ptro + blocksz;
     dsto := dsto + blocksz;
     result := result + reads;
    until (ptro >= ptrl) or (blocksz = 0) or (reads = 0);
   end;
End; // CopyRegion

function              TMemMap.CopyProcessMem (count: DWORD): DWORD;
begin
 ASSERT ((bbfSize > 0) and
         (bbfSize < 2048 * 2048)); // not above 4Mb
 result := CopyProcessMem (ipAddr, count, bbfSize);
 ASSERT (bbfSize > 0);
end;

Function              TMemMap.dwCurrPtr;
Begin
 result := dwAddr + offset;
End;

Function              TMemMap.lpCurrPtr;
begin
 result := pointer (dwCurrPtr);
End;


function              TMemMap.GetOfs;
begin
 result := dwAddr + offset;
end;

function              TMemMap.GetSbf;
Begin
 if (ssm.spyvars.fSpyMode) then
   result := pointer (ipAddr)  // ������ ������������ � ����������� ���������
 else
   result := pointer (DWORD (bbf) + offset); // ����� ������������ ������ �������
End;


function TMemMap.RWTestReg(const reg: TRegion; selfTest: boolean): boolean;
var
   tmp, rw: DWORD;
begin
 result := false;
 if hProcess = 0 then exit;
 if (selfTest) then
 begin
  try
   if IsBadReadPtr (reg.lptr, 4) then exit;
   if IsBadWritePtr (reg.lptr, 4) then exit;
   tmp := reg.ofst;
   asm
    push eax
    push ebx
    mov  eax, tmp
    mov  ebx, $FFFFFFFF
    and  [eax], ebx  ;;// rw-test
    pop  ebx
    pop  eax
   end;
  except
   // DebugBreak 
   exit;
  end;
  result := true;
  exit;
 end;
 // ������ ���������� true, ���� ������ �������� �� ������/������
 if not ReadProcessMemory (hProcess, reg.lptr, @tmp, 4, rw) then exit;
 if rw <> 4 then exit;
 if not WriteProcessMemory (hProcess, reg.lptr, @tmp, 4, rw)  then
   begin
    if random (1) = 3 then ods ('Rejecting wrong region.');
    exit;
   end;
 result := rw = 4;
end;

procedure             TMemMap.FilterReg;


   var
       fbad, test: boolean;

procedure Reject (frj: boolean);
begin
 fbad := fbad or frj;
end; // ����������

Begin
 with reg do
 Begin            { ����������� �� ������������ ������ �����-��������� }
  if ssm.SpyVars.fSpyMode then
   Begin
    // �������� �������� �� ��������� � �� ������ �������
    test := bound (abase, dynarng) or bound (abase, dllrng) or
                bound (abase, shmrng);
    if test then size := 0; // ����������� ������
    while (size > 0) and
     (bound (limit, dynarng) or bound (limit, dllrng) or bound (limit, shmrng)) do
     begin
      size := size - Min (size, 4096);
      limit := ofst + size;
     end;// while
   End; // if SpyMode
  //  fbad := false; // ��������
  // ������������� ������� �������� - ��������� ��� ������ � ������
  with smobj.svars.params.scanPages do
   begin
    fbad := (attrs and protect = 0); // ��� �����
    if not fbad then
    begin
     Reject (not fMemImage and (MEM_IMAGE = rtype));
     Reject (not fMemMapped and (MEM_MAPPED = rtype));
     Reject (not fMemPrivate and (MEM_PRIVATE = rtype));
     if (fTestRW) and not fbad and
         (paWriteable in protset)
        and not RWTestReg (reg, ssm.SpyVars.fSpyMode) then
        Reject (true);
     Reject (size > (maxRegionSize shl 20));
    end;
   end;


  Reject (protect and (PAGE_NOACCESS or PAGE_GUARD) <> 0);
  Reject ((state = MEM_RESERVE) or (state = MEM_FREE));
  // fbad := fbad or (ssm.svars.onlyPrivate) and (rtype <> MEM_PRIVATE);
  Reject (state and MEM_COMMIT = 0);
  if fbad then size := 0; // �����������
  limit := ofst + size;
  End; // with
End; // FilterReg

function  GetProtSet (const prot: DWORD): TProtSet;
var bRead, bWrite, bExecute: Boolean;
begin
 bRead := prot in [PAGE_READONLY, PAGE_EXECUTE_READ, PAGE_READWRITE,
                   PAGE_EXECUTE_READWRITE];
 bWrite := prot in [PAGE_READWRITE, PAGE_EXECUTE_READWRITE, PAGE_WRITECOPY,
                                    PAGE_EXECUTE_WRITECOPY];
 bExecute := prot in [PAGE_EXECUTE, PAGE_EXECUTE_READWRITE, PAGE_EXECUTE_WRITECOPY];
 result := [];
 if (bRead) then result := result + [paReadable];
 if (bWrite) then result := result + [paWriteable];
 if (bExecute) then result := result + [paExecutable]; 
 if (prot = PAGE_GUARD) then result := result + [paGuarded];
 if (prot = PAGE_NOACCESS) then result := result + [paNoaccess];
end;

var mbi : TMemoryBasicInformation;

procedure  GetNearReg (hProcess, ofst: DWORD; var reg: TRegion);
begin
 FillChar (mbi, sizeof (mbi), 0);
 // � ������ Spy, ������� �������� ����� ���������� �������
 if ssm.SpyVars.fSIS or ssm.SpyVars.fSpyMode then
  begin
   if (VirtualQuery (ptr (ofst), mbi, sizeOf (mbi)) = 0) then
    if (GetLastError <>  0) then ssm.svars.aliased := false;
  end
 else
  begin
   if (VirtualQueryEx (hProcess, ptr (ofst), mbi, sizeOf (mbi)) = 0) then
     LogStrEx ('Error durning call VirtualQueryEx: ' + Err2str(GetLastError), 12);
  end;
 SetRegion (reg, mbi.protect, mbi.RegionSize, mbi.RegionSize, DWORD(mbi.BaseAddress));
{ if nil <> mbi.AllocationBase then
     reg.pbase := mbi.AllocationBase    // and abase as DWORD}
 reg.pbase := reg.lptr;
 reg.protset := GetProtSet (reg.protect);
 reg.state := mbi.state;                // ��������� (COMMIT, RESERVED(
 reg.rtype := TRegionType (mbi.Type_9);
 reg.limit := reg.ofst + reg.size;      // ������
end; // GetNearReg

Function              TMemMap.FindRegion (const ofst: DWORD;var reg : TRegion) : boolean;
  { ����� ������� � ������� ������ ��� ������� ofst }

Begin
 reg.size := 0;
 if fRescan then
  begin
   GetNearReg (hProcess, ofst, reg);
   result := true;
  end
else
 // ����� ����� ��������� ��������
 result := regions.Find (ofst, reg);
End; // TMemMap.FindRegion

Function                      TMemMap.NextSieveReg;
var n : DWORD;
Begin
 result := false;
 n := statman.Find (cptr);
 if (n > 0) then
 begin
  reg := statman.stats [n].reg;
  result := true;
 end;
End; // Only on siv

procedure             TMemMap.EndRegion;
begin
 reg.ofst := bptr;
 reg.rsize := 4096;
 reg.size := 0;
end; // EndRegion


procedure       TMemMap.StoreRegion;
var fchange: boolean;
    wmap: TRegionArrayEx;
begin
 // ������ ����������� � ����� �����, ��� ����� ������
 wmap := tempmap;
 // if (workFlags = 2) then wmap := sievmap;
 if (workFlags = 2) then
  begin // ����������� ����������� �������� ��� ���������� �����.
   if sievmap.lastPtr > reg.ofst then sievmap.SetUsed (reg) else
   if sievmap.lastPtr < reg.ofst then sievmap.AddRegion(reg);
  end;
 wmap.AddRegion (reg);
 {$IFOPT D+}
 // �������� �� ������� ������� ����������� ������
 if wmap.VirtualSize > 1024 * 1024 * 1024 then asm int 3 end;
 {$ENDIF}
 fchange := false;
 // �������� ����������� � ������
 if (regions.ItemsCount >= wmap.ItemsCount) and (ssm.fMap) then
     fchange := (regions [wmap.ItemsCount - 1].rsize <>
                 wmap [wmap.ItemsCount - 1].rsize);

 if (wmap.VirtualSize > ssm.vmsize) or fchange then
    begin
     ssm.vmsize := tempmap.VirtualSize; // ������������ ��������
     ssm.fMap := false; // ��������� � ������ ��������
    end; 
end; // TMemMap.StoreRegion


procedure       TMemMap.TestMapUpdate;
var prvsz: Int64;
begin
 // �������� ���������� ����� �����
 if (tmpofst < bptr) or (bptr <= 0) then Exit;
 // ������� �� ������� ������������
 fsieve := (WorkFlags = 2);
 // ����������� ����� ����� ������ � �������
 tempmap.Full := TRUE; // ����� ��
 prvsz := regions.VirtualSize;
 if (fsieve) then
  begin
   if sievmap.ItemsCount = 0 then ods ('#ERROR: Sieve map is void');

   regions.Load (sievmap);  // ����� ��� ������
   sievmap.SetAllUnused;   // �������� ���������������
  end
 else
  begin
   regions.Load (tempmap); // ����� ��� ������
   sievmap.Clear;
  end;
 SendArray (regions); // ��������� ��������� �������
 lastmap.Load (regions); // ��������� �����
 tempmap.Clear;  // ����������� � ���������� ��������
  // ����������� ������� � ���������� ������������
  with smobj do
  begin
   vmsize := lastmap.VirtualSize;
   fMap := vmsize > 0;
   if vmsize <> prvsz then
   begin
    FillChar (msgpack, sizeof (msgpack), 0);
    msgpack.data1 := vmsize;
    SendMsgEx (NM_MAPCOMPLETE, vmsize);
    LogStrEx (Format ('VMSize = %d Kb, and sended to client.', [vmsize shr 10]), 11);
   end;
  end;
 tmpofst := sptr; // ����� �� ������ ������
end; // TestMapUpdate;

procedure       TMemMap.AddRegion;
 var
     reg : TRegion;
Begin
 // ������������� ����������� ����������
 if ssm.svars.aliased then else exit;
 sptr := ssm.svars.params.startofs;
 if sptr = 0 then sptr := $00100000;
 bptr := ssm.svars.params.limitofs;
 if bptr = 0 then bptr := GMEM_LIMIT;
 if (tmpofst < sptr) then tmpofst := sptr;
 // ����� �������� ����������
 statman.ResetX;
 fRescan := true;                // ����� ������ ��������
 SelectRegion (tmpofst, reg);    // ������� ������� �� ������
 with ssm.svars, ssm do
 if (reg.size > 0) then
  // ������ ������� ������
  Begin
   StoreRegion (reg);
   with reg do tmpofst := ofst + size; // �������� ���������
  End
 else // region good size = 0
  // ������ ������ ������
  Begin
   if reg.rsize = 0 then reg.rsize := 4096; // �������
      tmpofst := tmpofst + reg.rsize;
  End;
 TestMapUpdate; 
 fRescan := false;
End; // CreateMap


procedure       TMemMap.HeapTest;
var p : pointer;
begin
 MemSrv (p, 4096, MALLOC);
 dynarng.max := DWORD (p);
 MemSrv (p, 4096, MFREE);
end; // �������� ��������� heap


procedure TMemMap.SelectRegion;
  var  t : Byte;
Begin
 SetRegion (reg, 0, 65536, 0, ofst);
 // ����������� ����� ��������
 t := WorkFlags;
 if (t <> 0) or fRescan then else exit; // ��� ��������
 if (t = 2) and (not fRescan) and (not ssm.fFileLoad) then
 // ������ ���� ������ ����������
 begin
  if NextSieveReg (ofst, reg) then
  else EndRegion (reg);
 end
 else
 // �������� �������� �� �����������
 if FindRegion (ofst, reg) then else EndRegion (reg);
 // �������� �� ����������� �������
 FilterReg (reg);
End; // SelectRegion


procedure             TMemMap.SetRescan;
begin
 lastmap.Clear;
 sievmap.Clear;
 tempmap.Clear;
 tmpofst := 0;
 Reset;
end; // SetRescan

procedure             TMemMap.Reset;
begin
 dwAddr := sptr; // ��������� ����� ������������
 WorkFlags := CalcWorkFlags;
end;
                          
procedure TMemMap.InitBuff(const size: DWORD);
begin
 if bbfSize > 0 then FreeBuff;
 FBuffSize := size;
 if (size = 0) then
   begin
    LogStr ('#Error: Buffer intialized to zero bytes');
   end;
 sbfSize := sbfdef * 1024;
 if bbfSize < sbfSize then sbfSize := bbfSize;
 bbf := VirtualAlloc (nil, bbfSize + 512 * 1024, MEM_RESERVE or MEM_COMMIT, PAGE_READWRITE);
 if bbf = nil then ExitThread (0);
end; // InitBuff


procedure              TMemMap.Free;
begin
 regions.Free;
 sievmap.Free;
 tempmap.Free;
 lastmap.Free;
 scshare.Free;
 inherited;
end;

procedure              TMemMap.FreeBuff;
begin
 if (bbf <> nil) then VirtualFree (bbf, 0, MEM_RELEASE);
 bbf := nil;
 FBuffSize := 0;
end; // FreeBuff

function TMemMap.CorrectAddr(const ofst: DWORD): boolean;

begin
 result := (ofst = ipAddr); 
end;

function TMemMap.IdleRead: boolean;
const
      MAX_READ = 512 * 1024;
var lr: TRegion;
    rcnt: LongInt;
begin
 // ������ ������ �������� ����� �� ������ � swap.
 // ������� - ��������� ����������� ������.  ���������� true, ���� ���� ��� ������
 // ������������ ����� �� ������ - 512�����
 result := false;
 if (tempmap.ItemsCount = 0) then exit;
 lr := tempmap [tempmap.ItemsCount];
 rcnt := lr.size;
 if (rcnt > MAX_READ) then rcnt := MAX_READ;
 CopyProcessMem (lr.ofst + ReadOfs, rcnt, 512 * 1024); // 512K buff always avaible
 ReadOfs := ReadOfs + Dword (rcnt);
 result := ReadOfs < lr.size; // ���� ������ �� ������
end;


procedure TMemMap.Unlock;
begin
 //ods (' --- map.unlock ' + IntToStr (GetCurrentThreadId));
 scshare.Leave;
end;

procedure TMemMap.Lock;
begin
 //ods (' --- map.lock   ' + IntToStr (GetCurrentThreadId));
 scshare.Enter;
end;

function TMemMap.GetVMSize: Int64;
begin
 result := lastmap.VirtualSize;
end;

procedure TRegionArrayEx.SetUsed(const r: TRegion);
var tr: TRegion;
begin
 if Find (r.ofst, tr) then else exit;
 if IsBadWritePtr (@FUsed [index], 1) then asm int 3 end;
 FItems [index].size := r.size;
 FUsed [index] := TRUE;
end;

procedure TRegionArrayEx.SetSize(nSize: Integer);
begin
 inherited SetSize (nSize);
 SetLength (FUsed, FSize);
end;

procedure TRegionArrayEx.SetAllUnused;
begin
 if (FCount > 0) and Assigned (FUsed) then
    FillChar (FUsed [0], sizeof (Boolean) * FCount, 0);
end;

procedure TRegionArrayEx.AddRegion(const reg: TRegion);
begin
 if reg.ofst = lastPtr then
  begin
   LogStrEx ('#WARNING: trying adding region what offset equal previous.', 12);
   exit;
  end;
 inherited;
 lastPtr := reg.ofst;
 FUsed [FCount - 1] := TRUE;
end;

end.
