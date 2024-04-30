unit ChStorage;
interface
{  ����� ������� ��������/�������� ����������� ������/������.

    � ���������� ������� ������������� ��������� ������ ��������
 ��������. ��� �������� ����������� ���� - �������������� ������� ����������
 �������� ���������-������������ ����������� ������.

   ����� ��������� �������� �� �������� ������ (�����). ��� ��������� ������������
 ������ � �������� ������ ����������� �������� (������ ������), � ����������� ������
 �������� (������ ����� ������� ��������). ��� �� � ������ �� ���� ����� ������������
 �������� (����������� ��������) ��� � �����������. ��� ���� ��������� ������ �����������
 ������ ���������� ������ ������ �����.

   ������ ��������� ��� ������ ��������� ������� (�� ��������� ���� ���� = 1024�).
 ����� � ����� �������� ������ 32����� ���������� ����� (����������� �������������
 �������� 64� ��������), ��������� �������������� ����. ��������� �� ����� ��������
 ��� � ������ �������, �� �� ���� ��� �������������.

    �������� �������� ������� �������� �� ��������� � ����������� ��������. ������������
 ������ �������� ���������� �����������:
  struct packed
  [
    DWORD       bitset;   // ��������� 32-������, ��������� ��� �������� ��������������� ��������
    WORD        offset;   // �������� �� �������� ����������� �������
    WORD        count;    // ���������� ���������� ����������
  ]

    � ��������� bitset ������� ��������� ������������� ���� ���. ��� ���� ������� ���
 ������������� �������� �������� �� offset, � 31-�� �������������� 31-��. ��� ����������
 �������� (��� ������� $FFFFFFFF) ������������ ���� count. ��� ��������� ���� ��� 100%
 ����������� � �������, ������� ��� �������� ����� ����������, ������ �� ������� RLE.

   ���������� ������������� ��������: 32 �������� ����� ���� ����������� ������� 64 ������
 (������ ������ ���������), ��� �������������� 32��=8����. ���� ��������� ��� ��� ���������
 ����� ����������, ��� �������� 64� ���������� ����������� 16����� ������, �� ���� �����������
 ����������� ������ 1 � 4.

   ��� ������, ����������� ����� ����� �������� ����������. �����������, � ������ ������
 ������������ ����� �����, � ������� ����� ������. � ������ �� ������ ������, ��� �����������.

   ��� ����� ������� ����������� ���������, ��������������� ��� ��� ������� �������
 ������������ ��������� ��������� ������ ���������. ��� ���������� ������� �����
 �������������� ���������� �����������.

   �������������� ������ ������� �� ������ ��� ���������� ������� (�� ����� 7).
 ������ ������� � ������ ����������� �����������, � ������������� � ����������������
 ���� ��������. � ������� ���������� ���� ��������� ������ TStorage.



}

uses    Windows, ChTypes, ChConst;

const
        BankSize = 128 * 1024;         // 128 - ���. ������ �����
         MinFree = 16384;              // ����������� ������ ���������� ����� � �����
        MaxSubRqs = 9;                // ���-�� ����������� � �������


   SubRqsTypes : array [1..MaxSubRqs] of DWORD =
    (WHOLE1_TYPE, WHOLE2_TYPE, WHOLE4_TYPE,
     SINGLE_TYPE, REAL48_TYPE, DOUBLE_TYPE, EXTEND_TYPE,
     ANTEXT_TYPE, WDTEXT_TYPE);

   SubRqsClass : array [1..MaxSubRqs] of TVClass =
    (st_int, st_int, st_int,
     st_real, st_real, st_real, st_real,
     st_text, st_wide);

   SubRqsSizes : array [1..MaxSubRqs] of Byte =
    (1, 2, 4,
     4, 6, 8, 10,
     1, 1);  

type
        TPackRec = packed record
         bitset : DWORD;
         rcount : WORD;
         offset : WORD;
        end;

        TPackList = array [0..32767] of TPackRec; // ������������ ������� ��������

        PPackList = ^TPackList;

        PPackItem = ^TPackItem;

        TPackItem = packed record    // ��������� ����������� ������ 6 ���� + ������ ������
         relnxt: DWORD;              // �������� �� �������� �� ���������� ��������
         relprv: DWORD;              // �������� �� �������� �� ����������� ��������
         paddr: DWORD;               // ����� ������ ���������� ��������
         count: WORD;                // ���-�� ���������
         found: WORD;                // ���������� �� ����������� ���������
         // list may be used not whole
         list: TPackList;          // ����������� ��������
        end;

        TBankHdr = packed record
         subrqs: Byte;        // ��������� ������ �������
           res1: Byte;        // ����������������
           res2: Word;        // ����������������  
         minofs: dword;       // ����������� ��������
         maxofs: dword;       // ������������ ��������
         banksz: dword;       // ������ ����� ��� ���������� �������
        end;

        PBank = ^TBank;
        TBank = class (TObject)
        public
         // ������� ���������� ����������� �������� (IPR)
         locked: boolean;
         minofs: dword;       // ����������� ��������
         maxofs: dword;
         blimit: dword;       // ���������� ��������� � �����
         banksz: dword;       // ������ ����� ��� ���������� �������
          valid: boolean;     // �������� (�� ������ �����������)

           next: PBank;          // �������� ���� ��� nil.
           prev: PBank;          // ���������� ����
           curr: PPackItem;      // ��������� ��� ��������� �� �����
           bptr: PPackItem;      // ��������� �� ������ �����
           tail: PPackItem;      // ��������� �� ����� ������ ����� ��� ������� ������

         constructor        Create;
         function           Contains (const paddr: dword): boolean;
         procedure          Copy (const bank: TBank);
         procedure          Allocate;
         // ��������� ��������� �� ��������� ��������� � paddr
         function           FindPtr (const paddr: dword): PPackItem;
         // �������� ����������
         procedure          Free;
         // ���������� ��������� �� ����� �����
         function           GetTailPtr: PPackList;
         function           GetRest: dword; // ������� ��� ����� ������ �������
         // �������� � ���� tail
         procedure          PackList (pa: dword; list: POffsetArray;count : dword);
         // ���������� ����� tail
         function           UnpackList (list: POffsetArray): dword;
         // ���������� ����� bptr, �� ����� 128 ����������
         function           UnpackListEx (var list: array of dword): dword;
         procedure          StorePacked (const pa: dword; const count, fcount: word);
        end;


        PStorage = ^TStorage;

        TStorage = packed class (TObject)
        scanid: dword;        // ����� ������������
         banks: TBank;        // ������ ������
          last: PBank;        // ��������� �� ��������� ����
        // ������ ������ - ���� ���������� ��������� ������� ���������� (�����)
        sieved: Boolean;
         // ������������ ��� ������ ��� �������� ���������.
         nStor: PStorage;
          fnew: Boolean;   // ������ ������ ���������
         constructor            Create;
         procedure              CreateNew; // �������� nStor
         procedure              AddBank;
         procedure              AfterSieve;
         // ����� ����� ������ ��������������� � ���������� base
         function               FindBank (const base: dword): PBank;
         procedure              Init;
         // ��������� �� ������ ���������� �����
         function               LastPtr : PPackList;
         // �������� �� ���������
         procedure              Free (delbanks: boolean = true);
  private
         procedure FreeBanks;
        end; // TStorage

        // ������ �������������� ��������
        TValidRqs = packed class
        private
         // ������ ����������� ������ ���������
         FoundCount: Integer; // ���������� �������� �������� �� �������
         procedure              InitSubRqs (const n: byte);
         procedure              FreeSubRqs (const n: byte);
         procedure              UpdSubRqs (const n: byte);
         function               GetFound: Integer;
         procedure              SetFound (nFound: Integer);
        public
         common : TRequest;  // ����� ������
         subcnt : byte; // ���-�� �����������
         slist : array [1..MaxSubRqs] of TStorage;
         rlist : array [1..MaxSubRqs] of TRequest; // ������ ��������
         rqsnum: dword; // ����� ������� ���������

         property Found: Integer read GetFound write SetFound;
         constructor            Create (n: dword);
         procedure              AfterScan;
         // ������������� ������
         procedure              Free;

         procedure              Prepare (const wtype: dword);
         // ��������� ���������� ������� �� ����������
         procedure              Split (const r : TRequest);
         // ���������� ������ � ������ ������ �������� (�� ����� 128)
         function               Unpack (var list: array of TFAddr): dword;
         // ���������� �����������
         procedure              Update (const r : TRequest);
        end;

       TBlock = record
         addr: pointer;
         size: dword;   // ������� ��� - ���� ������������ 
       end;

       TMemMan = class (TObject)  // ��������� ������� ������ ������ (������� ������� ��������)
       private
          blist: array [1..2048] of TBlock;
         bcount: dword;
        public
         constructor            Create;
         function               Allocate (bsz: dword): Pointer;
         procedure              Release (p: pointer);  // �� ������� ���� �� ����� ����!
         procedure              Free;                  // ������� ��� ����� ����� 
        end;


const
     UsedBlock = $80000000;
     AllocMask = $FFFF000;
// ������ ���������� �� ���������� ������
var
    Founds : array [1..MaxRqs] of TValidRqs;
    MemMan : TMemMan;
    _scanid: dword;
    pkfound: dword;
    
// ������ ��������� ���������/�������� ������, � ������������ ��� �� �����
procedure        AddRequest (const rn : byte; const src : TRequest);
// ���������� ��������������� �������
procedure        UpdRequest (const rn : byte; const src : TRequest);
// ������� ��������������� �������
procedure        KillRequest (const rn : byte);

// ��������� ���������� ����� � ���������� ��������� � ���
function         GetLast (const rq, sn: byte; var b: PBank): PPackList;
function         _next (const pit: PPackItem): PPackItem;
function         _prev (const pit: PPackItem): PPackItem;

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//             Implementation part of ChStorage.pas                    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


implementation
uses ChShare, ChHeap, SysUtils, Misk, ChLog, ChServer;

function         _next (const pit: PPackItem): PPackItem; 
begin
 if (pit = nil) or (pit.relnxt = 0) then result := nil
 else result := PPackItem (dword (pit) + pit.relnxt);
end; // _next

function         _prev;
begin
 if (pit = nil) or (pit.relprv = 0) then result := nil
 else result := PPackItem (dword (pit) - pit.relprv);
end; // _prev

function         GetLast;
begin
 result := nil;
 if (founds [rq].slist [sn] = nil) then exit;
 b := founds [rq].slist [sn].Last;
 if (b <> nil) then // �������� ��������
    result := founds [rq].slist [sn].LastPtr;
end; // GetLast


function         RqsConvert (const r: TRequest) : dword;
begin
 result := 0;   // ������ ������
 if (r._class = st_int) then
  case r.vsize of
   1: result := WHOLE1_TYPE;
   2: result := WHOLE2_TYPE;
   else result := WHOLE4_TYPE;
  end; // ����� �����
 if (r._class = st_real) then
  case r.vsize of
   4: result := SINGLE_TYPE;
   6: result := REAL48_TYPE;
   8: result := DOUBLE_TYPE;
  10: result := EXTEND_TYPE;
  end;
 if (r._class = st_text) then result := ANTEXT_TYPE;
 if (r._class = st_wide) then result := WDTEXT_TYPE;
end;

procedure        AddRequest;
begin
 KillRequest (rn); // ������ ������ �������
 founds [rn] := TValidRqs.Create (rn);
 founds [rn].Split (src);
end; // AddRequest

procedure        UpdRequest;
begin
 // ������������
 if (founds [rn] = nil) then
     founds [rn] := TValidRqs.Create (rn);
 founds [rn].Update (src); 
end; // UpdRequest


procedure        KillRequest;
begin
 if (founds [rn] <> nil) then
  begin
   founds [rn].Free;
   founds [rn] := nil;
  end;
end;

constructor             TValidRqs.Create;
begin
 found := 0;
 rqsnum := n;
end; // TValidRqs.Create

procedure TValidRqs.AfterScan;
var srq: byte;
begin
 // ������� ����� �������� ������
 for srq := 1 to MaxSubRqs do
  if (rlist [srq].enabled) and (slist [srq] <> nil) then
  if (slist [srq].sieved) then slist [srq].AfterSieve; // ���������
end; // TValidRqs.AfterScan

procedure               TValidRqs.Free;
var n : byte;
begin
 for n := 1 to MaxSubRqs do FreeSubRqs (n);
end;

procedure              TValidRqs.InitSubRqs(const n: byte);
begin
 slist [n] := TStorage.Create;
 UpdSubRqs (n); // ���������� ����������
end; // TValidRqs.InitSubRqs

procedure              TValidRqs.UpdSubRqs;
begin
 rlist [n] := common;
 rlist [n]._class := SubRqsClass [n]; // ����� ��� �������
 rlist [n].vsize := SubRqsSizes [n]; // ��� ������ ������ ������� ������������ � ChAlgs
 if (rlist [n]._class = st_text) then
   rlist [n].vsize := StrLen (rlist [n].textEx);
 if (rlist [n]._class = st_wide) then
   rlist [n].vsize := StrLen (rlist [n].textEx) * 2; // 1 ������ - 2 �����
 rlist [n].enabled := true;
 inc (subcnt);
end; // TValidRqs.UpdSubRqs

procedure              TValidRqs.FreeSubRqs;
begin
 if (slist [n] <> nil) then
  begin
   slist [n].fnew := false;
   slist [n].Free; // ������� �������� ���������
  end;
 slist [n] := nil;
 rlist [n].enabled := false;
end;

function TValidRqs.GetFound: Integer;
begin
 result := 0;
 if Assigned (self) then
    result := FoundCount;
end;

procedure TValidRqs.SetFound(nFound: Integer);
begin
 ASSERT (Assigned (self), 'TValidRqs object ptr invalid');
 FoundCount := nFound;
end;


procedure TValidRqs.Prepare (const wtype: dword);
var srq: byte;
begin
 ASSERT (self <> nil, '����� ������ ������� = NIL'); // ������ ���������
 // ���������� � ������ ��� ������
 for srq := 1 to MaxSubRqs do
  if (rlist [srq].enabled) then
  begin
   found := 0; // ����� ��������
   // ������� �������������� ��������� ��� ����� ������
   if ((wtype = 2) or (rlist [srq].Unknow and (rlist [srq].sactn = _scan)))  then
    begin
     slist [srq].CreateNew;
     slist [srq].sieved := true;
    end
   else
   if (wtype = 1) then
     begin
       slist [srq].Free; // ����� ���������
       slist [srq] := TStorage.Create;   // ������� �����
     end;
  end;
end; // Prepare

procedure              TValidRqs.Split;
var n : BYTE;
    tset : dword;
begin
 subcnt := 0;
 common := r;
 tset := r.typeset;
 if (tset = 0) then tset := RqsConvert (r);
 for n := 1 to MaxRqs do
   if (tset and SubRqsTypes [n] <> 0) then InitSubRqs (n)
 else FreeSubRqs (n);
end; // TValidRqs.Split


var tmp: array [1..128] of dword;
function                TValidRqs.Unpack;
var
   use: boolean;
   srq, sub: dword;
   n: dword;
   gcnt: dword;
begin
 result := 0;
 for srq := 1 to MaxSubRqs do
  begin
   use := (rlist [srq].enabled) and
          (slist [srq].banks <> nil) and
          (slist [srq].banks.bptr <> nil);
   if not use then continue; // �� �������������
   gcnt := slist [srq].banks.UnpackListEx (tmp);
   for n := 1 to gcnt do  // ������� ��������
   with rlist [srq] do
    begin
     sub := 0;
     if (_class = st_real) and (vsize > 6) then
      begin
       // if (vsize = 6) then  sub := 4;
       if (vsize = 8) then  sub := 4;
       if (vsize = 10) then  sub := 6;
      end;
     list [result].vaddr := tmp [n] - sub; // ��������� ����� ������
     list [result].vsize := vsize;
     list [result].vclass := _class;
     inc (result); // ��������� ��������
     if (result > dword (high (list))) then exit;
    end;
  end;
end; // TValidRqs.Unpack

procedure               TValidRqs.Update (const r : TRequest);
var
   n : BYTE;
   tset : dword;
begin
 subcnt := 0;
 common := r;
 tset := r.typeset;
 if (tset = 0) then tset := RqsConvert (r);
 for n := 1 to MaxRqs do
 if (tset and SubRqsTypes [n] <> 0) then UpdSubRqs (n)
 else  FreeSubRqs (n); // ������� ������
end; // Update

// ######################################################################## //


constructor             TBank.Create;
begin
 next := nil;
 prev := nil;
 bptr := nil;
 tail := nil;
 // ��������� �������������� ������
 minofs := $80000000;
 maxofs := $00000000;
end; // TBank.Create

procedure               TBank.Allocate;

begin
 banksz := BankSize;            // ������� ������ �����
 curr := nil;
 tail := nil;
 bptr := memman.Allocate(banksz); // ��������� ���� ������
 valid := (bptr <> nil);
 if (valid) then
  begin;
   // ��������� ��������� ����������
   FillChar (bptr, 0, sizeof (TPackItem)); // �������� ������ �������
   tail := bptr;
   blimit := dword (bptr) + banksz - MinFree; // ���������� ���������
   next := nil;
  end
 else
  begin
   banksz := 0;
   blimit := $1234;
   raise EInvalidPointer.Create('�� ������� ������ ���������������: ' + err2str (GetLastError));
  end;
end; // TBank.Allocate

function                TBank.FindPtr;
var tmp : PPackItem;
begin
 result := nil;
 tmp := bptr;
 while (tmp <> nil) do
 if (tmp.paddr >= paddr) then
 begin
  result := tmp;
  exit;
 end
 else  tmp := _next (tmp); // ����. ������
end; // TBank.FindPtr;


procedure               TBank.Free;
begin
 if (bptr <> nil) then  memman.Release (bptr); // "����������� ���� ������"
 bptr := nil;
 tail := nil;
 next := nil;
 banksz := $FFFFFFFF; // ���� ����
 valid := false;
 inherited;
end;

function                TBank.GetTailPtr;
var p: PPackItem;
begin
 // ����������� ��������� �� ������
 result := nil;
 // �������� �� ������� tail
 if (tail = nil) then
  begin
   p := bptr;
   while (p <> nil) do
    begin
     tail := p;
     p := _next (p);
    end;
  end;
 if tail <> nil then
 with tail^ do result := @list;
end;

function                TBank.GetRest;
begin
 // CheckValid ('GetRest');
 result := BankSize - (dword (tail) - dword (bptr));
end; // TBank.getRest

procedure               TBank.PackList;

function                PackToSet (ofst : word; var index: dword) : dword;
// �������� ���������� �������� � 32-� ������ ���������

var    n : byte;
    mask : dword;
begin
 result := 0;
 mask := 1;
 for n := 1 to 32 do
  begin
   if (index > count) then           // ����������� �����������
       break;
   if (ofst = list [index]) then     // �������� ���������
    begin
     result := result or mask;        // ��������� ���� � ���������
     inc (index);                     // ��������� ��������� �������
    end;
   inc (ofst);
   mask := mask shl 1;           // ��������� ����. ���� �����
  end;
end; // PackToSet

var
   i, id : dword;
   srofs  : WORD;

procedure    AddSet (const st: dword);
begin
  if (st <> tail.list [id].bitset) then // ��������� �� ���������
   begin
    if (tail.list [id].rcount > 0) then inc (id); // ��������� ������
    tail.list [id].bitset := st;        // ����������� ���������
    tail.list [id].rcount := 1;         // ���� ���������� ���
    tail.list [id].offset := srofs;     // ����������� ��������
   end
   else
    Inc (tail.list [id].rcount);        // ������������� ����������
end; // AddSet
{ -------------------------------------------------------------------------------- }
const
     M32 : dword = not DWORD ($1F);     // �����

begin
 if (locked) then exit;
 id := 0;
 i := Low (list^);
 if ((count > 0) and (count <= 65536)) then
  begin  // �� ���������������� �������
   fillChar (Tail.list, 8, 0); // ��������� ������ �������� �������� � ������� ��������
   tail.count := 0;
   tail.relnxt:= 0;
   repeat
    srofs := list [i] and M32; // ��������� ��������,
    AddSet (PackToSet (srofs, i));     // �������� � ��������� � ���������� � ������
   until (i > count);  // ���������� �� ���������� ������� ������  
   if (tail.list [id].rcount > 0) then // ��������� ������������
       StorePacked (pa, id + 1, count); // ���-�� = ������ + 1
  End; // �� ���������� - ��
end; // TBank.PackList

function                TBank.UnpackList; // �� ���������������� �������
var
   index : dword;
   offst : dword;
   
procedure               UnpackSet (st : dword);
var  n : dword;
begin
 // �������� ����� � 0 �� 31,  � ����������� ��������
 {$IFNDEF _OPT}
 for n := 1 to 32 do
 begin
  if (st and 1 <> 0) then
   begin
    inc (index);
    list [index] := offst;    // ���������� ��������
   end;
  inc (offst);
  st := st shr 1;             // ���������
 end;
 {$ELSE}
 asm
  push          eax
  push          ebx
  push          ecx
  push          edi
  mov           edi, index
  mov           eax, offst
  mov           ebx, st
  mov           cl, 20h
@rept:
  // ��� � CF
  shr           ebx, 1
  // ���� �� ��������� - �������
  jnc           @nsave
  // ��������� ��������
  mov           [2][list + edi * 2], eax
  add           edi, 1        // ������ ���������
@nsave:
  // ��������� ��������
  inc           eax
  dec           ecx
  jnz           @rept
  mov           offst, eax
  pop           edi
  pop           ecx
  pop           ebx
  pop           eax
 end;
 {$ENDIF}
end; // ���������� ���������

var i, lim, rep : dword;
//    oldofs : dword;
begin
 // ��� ������� ���������� ���� ���������� curr
 lim := High (TOffsetArray) - 32;
 index := 0;
 i := 0;
 //result := 0;
 if (curr <> nil) and (banksz = BankSize) then
 while (i < curr.count) and (index < lim) do
  Begin
   offst := curr.list [i].offset;  // ������� ��������
   rep := 1;
   if (curr.list [i].rcount > 0) then
    repeat
     // ��������� ����� ���������� ���
     UnpackSet (curr.list [i].bitset);
     inc (rep);
    until (index > lim) or (rep > curr.list [i].rcount);
   inc (i);
  End;
 result := index;
end; // UnpackList

function                TBank.UnpackListEx;
var tmp: TOffsetArray;
    n, lcnt, lfst : dword;
    start: dword;
    fbreak: boolean;
    bank: PBank;
begin
 start := 0;
 fbreak := false;
 bank := @self;
 while (bank.next <> nil) do bank := bank.next;
 // ���������� ���������� ����� � ������ �������
 // ����� ������: ���������� ���������� ����� � ���������  ����������
 // � ��������� ������.
 {$R+}
 try
 repeat
  curr := bank.tail;
  repeat
   lcnt := UnpackList (@tmp);       // ���������� � ��������
   lfst := lcnt; // ����������� �� ���������� ��������
   if (lcnt + start > 128) then
       lcnt := 128 - start; // ����������� �� ����� ����������
   // �������������� �������� � ������
   for n := 1 to lcnt do
        list [start + n - 1] := tmp [lfst - n + 1] + curr.paddr;
   // �������� � ������
   start := start + lcnt;
   curr := _prev (curr);
   // ������� ���������� ������� - ������ ��������
   fbreak := fbreak or (start = 128) or (curr = nil);
   // ������� ���������� ����� - ����� �����
  until fbreak;
  // ���������
  if (start < 128) then
   begin
    bank := bank.prev;
    fbreak := (bank = nil); // ���������� �������� ������ ����
   end;
 until fbreak;
 {$R-}
 except
  DebugBreak;
 end;
 result := start;
end;

procedure               TBank.StorePacked;
var rofst: dword;
begin
try
 {$IFOPT D+}
  if (locked) then asm int 3 end;
 {$ENDIF}
 // ��������� ��������� �� ������ �� �������
 rofst := sizeof (TPackRec) * count + 32; // 32 ��� ������
 tail.relnxt := rofst;
 { with tail^ do
 if (relnxt and $3F > 0) then  relnxt := relnxt or $3F + 1; // ��������� �� ������� � 64 {}
 // ���������� ���������� � ������� ������
 tail.count := count;
 tail.found := fcount; // ���������� �������� ��� ��������
 tail.paddr := pa;
 tail := _next (tail); // �������� � ����� ������
 {$IFOPT D+}
 if (dword (tail) >= blimit + MinFree) then
    raise ERangeError.Create('����� ������������ �����.');
 {$ENDIF}
 tail.relprv := rofst;
 tail.relnxt := 0;  // ���������� ��������� ���������� �� ����
 tail.count := 0; // ����� ������ �� ���������, �� ���� ���� ���
 curr := tail;
 inc (pkfound, fcount);
 // ��������� ������
 if (minofs > pa) then minofs := pa;
 if (maxofs < pa) then maxofs := pa;
except
 ods ('����� ������������ �����.');
end;
end;


function                TBank.Contains;
begin
 result := (minofs <= paddr) and (paddr <= maxofs);
end;

constructor             TStorage.Create;
begin
 Init;
 sieved := false;
 fnew := false;
 nStor := nil;
 scanid := _scanid;
end;    // Create

procedure TStorage.CreateNew;
begin
 if (nStor <> nil) then nStor.Free;
 memsrv (nStor, sizeof (TStorage), MALLOC);
 nStor^ := TStorage.Create;
 nStor.nStor := nil;
 nStor.fnew := true;
end; // TStorage.CreateNew

procedure               TStorage.AddBank;

begin
 memsrv (last.next, sizeof (TBank), MALLOC);
 last.next^ := TBank.Create;
 last.next.prev := last; // ������� � �����.
 last := last.next;
 last.Allocate;
 last.next := nil;
end;    // AddBank


procedure               TStorage.AfterSieve;
begin
 // ����������: �������������� ����������� ������ ������ ���������
 // � ��������� - ��������.
 FreeBanks;
 if (nStor <> nil) then
  begin
   banks := TBank.Create;
   banks.Copy (nStor.banks);
   last := nStor.last;
   nStor.Free (false); // ������� ��� ��������, �� ��������� �����
   nStor := nil;
  end;
 scanid := _scanid;
end; // TBank.AfterSieve


function                TStorage.FindBank;
var tmp : PBank;
begin
 result := nil;
 tmp := @banks;
 while (tmp <> nil) do
 if (tmp.Contains(base)) then
 begin
  result := tmp;
  exit;
 end
 else
 begin
  if (tmp = nil) then exit;
  tmp := tmp.next; // ��������� ����
 end;
end; // TStorage.FindBank


procedure               TStorage.FreeBanks;
var
   tmp : PBank;
begin
 if (self = nil) or (banks = nil) then exit;
 try
  last := banks.next;
  tmp := banks.next;
  while (tmp <> nil) do
  begin
   last := tmp.next;
   tmp.Free;
   tmp := last;
  end;
  banks.Free;
  banks := nil;
 finally
 end;
end; // TStorage

procedure               TStorage.Free;
begin
 // ������� ����� ��������� �� ��������
 if (nStor <> nil) and (not fnew) then
  begin
   nStor.fnew := true;
   nStor.nStor := nil;
   nStor.Free;
   memsrv (nStor, sizeof (TStorage), MFREE);
   nStor := nil;
  end;
 if (delbanks) then FreeBanks
 else
  begin
   banks.FreeInstance; // ������ ��������
   banks := nil;
  end;          
end; // Free

procedure TStorage.Init;
begin
 banks := TBank.Create;
 banks.Allocate;
 last := @banks;
 nStor := nil;
end; // TStorage.Init;

function              TStorage.LastPtr;
begin
 result := nil;
 if (last <> nil) then result := last.GetTailPtr;
end;


var n : BYTE;  

procedure TBank.Copy(const bank: TBank);
begin
 bptr := bank.bptr;
 tail := bank.tail;
 next := bank.next;
 curr := bptr;
 banksz := bank.banksz;
 valid := bank.valid;
 minofs := bank.minofs;
 maxofs := bank.maxofs;
end;


{ TMemMan }

function TMemMan.Allocate;
var n: dword;
    p: pointer;
begin
 result := nil;
 if (bcount > 0) then
  for n := 1 to bcount do
  with blist [n] do
  if (addr <> nil) and                  // ���� ��������
     (size and UsedBlock = 0) and       // �� �����
     (size and $FFFF000 = bsz) then     // �������� �� �������
   begin
    result := addr;                     // ������� ���
    size := size or UsedBlock;          // ������ �����
    exit;                               // ���������� �����
   end;
 if (bcount >= High (blist)) then
    raise ERangeError.Create('��������� ������������ ��������� ������. �������� ������ ������');
 p := VirtualAlloc (nil, bsz and AllocMask, MEM_COMMIT, PAGE_READWRITE);
 if (p <> nil) then
  begin
   Inc (bcount);
   blist [bcount].size := (bsz and AllocMask) or UsedBlock;
   blist [bcount].addr := p;
   result := p;
   // ������ ���� ���������� ���� ��� ������ ���������������
   n := ssm.ActiveClient;
   if (n > 0) then inc (ssm.clients [n].StCommit, bsz and AllocMask);
  end;
end; // TMemMan.Allocate


constructor TMemMan.Create;
var n: dword;
begin
 // ��������� ������ ���� ������
 for n := 1 to High (blist) do
  begin
   blist [n].addr := nil;
   blist [n].size := 0;
  end;
 bcount := 0;
end; // TMemMan.Create

procedure TMemMan.Free;
var n, cl : dword;
begin
 // �������� ���� ������, � ������������ ������
 for n := 1 to bcount do
 with blist [n] do
 if (addr <> nil) then
 if VirtualFree (addr, size and AllocMask, MEM_DECOMMIT) then // ������� ����
  begin
   cl := ssm.ActiveClient;
   if (cl > 0) then dec (ssm.clients [cl].StCommit, size);
   blist [n].addr := nil;   // ���� ���� ����������
   blist [n].size := 0;
  end;
 bcount := 0;
end; // TMemMan.Free

procedure TMemMan.Release(p: pointer);
var n: dword;
begin
 // ����� ����� � ��� "�������������"
 for n := 1 to bcount do
 with blist [n] do
 if (addr = p) then
  begin
   size := size and AllocMask;
   exit;
  end;
end; // TMemMan.Release



initialization
 _scanid := 0;
 for n := 1 to MaxRqs do founds [n] := nil;
finalization
end.
