unit ChLWorks;

interface

uses Windows, SysUtils, TlHelp32, ChTypes, ChShare, ChAlgs;

type

    PFoundResult = ^TFoundResult;


    { ������� ������� ������� �������� }
    PChainItem = ^TChainItem;
    TChainItem = record
    // Connection
    Next, Prev : PChainItem;  // ��������� ������� �������
    // DATA
         BaseOfs : dword;       // ������� ����� ������� � ��������
         BufSize : dword;       // ������������ �������
        ListSize : dword;       // ���-�� �������� � ������
     OffsetArray : POffsetArray;// ������ ��������
        LBufSize : dword;       // ������ ����������� �������
        LastData : Pointer;     // ���������� ������ (opt)
           LStep : word;        // ��� ������
         Updated : boolean;
         packalg : dword;       // �������� ���������
          packsz : dword;
    end;


 { ============================ ����� TListWorks =================================== }
     PListWorks = ^TListWorks;
     TListWorks = class
     public
      pOwner : PFoundResult;
      first, last, curr : PChainItem;
      constructor  Create (owner : Pointer);
      destructor   Destroy;  override;
      procedure    Next;  // ������� curr � last
      procedure    Prev;  // ������� curr � first
      function     GetNext : PChainItem;  // ���������� curr.next
      function     GetPrev : PChainItem;  // ���������� curr.prev
      procedure    Insert (VAR X : TChainItem); // ��������� x ����� curr
      procedure    Delete; // ������� curr
      procedure    Free;
      function     GetNeed (r : byte;curp : dword; var Size : dword) : dword;
      function     CalcFound  : dword;
      function     PackArray (var src : TOffsetArray; var xx : PChainItem) : dword;
      function     UnpackArray (var xx : PChainItem; var dst : TOffsetArray) : dword;
      procedure    SaveToFile (const filename: string);           // ���������� ����������� � ����
      function     LoadFromFile (const filename: string; stp: dword) : dword; // �������� �������� �� ����� � ���������� ������
     end; // ����� ������ �� ��������� �������
   // ��������� ���������� ������
   TFoundResult = record
      step : word; // ��� ����������
      Need : boolean; // SearchFlag
     FList : TListWorks;
   LastPtr : dword;
   fUnknow : boolean; // ����� ������������ ��������
   end;

var   
     founds : array [1..MaxRqs] of TFoundResult;
implementation
uses    ChHeap;


function    TListWorks.GetNeed;
var
       tmp : PChainItem;
       ptr, max : dword;
begin
 result := 0;
 max := 0;
 if  SM.RqsLst [r].enabled and
    (SM.RqsLst [r].stype = _sieve) then
 with founds [r].fList do
  begin
   tmp := first;
   if tmp = nil then exit;
   size := 0;
   while (tmp <> nil) and
         (tmp.BaseOfs < curp) do tmp := tmp.next;
   if tmp = nil then exit;
   // ��������� ���� � �������
   if (tmp.BaseOfs >= curp) then result := tmp.BaseOfs;
   // ������ �� ���������� �������
   while (tmp <> last) do tmp := tmp.next;
   // ����� ����������  �������
   ptr :=  tmp.BaseOfs + tmp.BufSize;
   size := abs (ptr - result); // ������������ ������ ������ �������
   if size > max then size := max;
  end;
end; // Need;

function    TListWorks.CalcFound;
var tmp : PChainItem;
begin
 result := 0;
 tmp := first;
 while (tmp <> nil) do
  begin
   result := result + tmp.ListSize;
   tmp := tmp.next;
  end;
end; // CalcFound

constructor  TListWorks.Create;
begin
 first := nil;
 last  := nil;
 curr := nil;
 pOwner := Owner; // ppslf := @FList; (ppself^ = @FList) ?it nil
end; // Create

destructor   TListWorks.Destroy;
begin
 Free;
 inherited;
end; // Destroy

procedure    TListWorks.Next;  // ������� curr � last
begin
 if curr <> last then curr := curr.next;
end; // Next

procedure    TListWorks.Prev;  // ������� curr � first
begin
 if curr <> first then curr := curr.prev;
end; // Prev

function     TListWorks.GetNext : PChainItem;  // ���������� curr.next
begin
 result := curr.next;
end; // GetNext
function     TListWorks.GetPrev : PChainItem;  // ���������� curr.prev
begin
 result := curr.prev;
end; // GetPrev

procedure    TListWorks.Insert; // ��������� x ����� curr
{ ������� X ������ ���� ������ }
begin
 if @x = nil then exit; 
 if first = nil then
  begin
   first := @x;
   last := @x;
   curr := @x;
   x.next := nil;
   x.prev := nil;
  end
 else
 if (curr <> nil) and ((curr = last) or (first = last)) then
  begin
   { � ���� ������ X ���������� ��������� ���������
     ��� ��������� ������ � ��������� �� ������� �����
     [LAST] <- X -> nil
     [LAST] -> X
   }
   last.next := @x; // Connect -->
   x.prev := last;  // Connect <--
   last := @x;      // Scroll
   x.next := nil;
   next;
  end
 else
if (curr <> nil) then
  begin
   x.next := curr.next;  // B-> == C
   x.prev := curr;       // B-< == A
   curr.next := @x;      // A-> == B
   next; // Set Next
  end;
end; // Insert

procedure   MemAvail (var result : dword);
var ms : _memorystatus;
    
 begin
  if result = 0 then ms.dwMemoryLoad := 4;
  ms.dwLength := sizeOf (ms);
  GlobalMemoryStatus (ms);
  result := ms.dwAvailVirtual;
 end; // MemAvail
 
procedure    TListWorks.Delete; // ������� curr
 procedure    FreeCurrent;
 begin
  if curr.OffsetArray <> nil then
          MemSrv (curr.offsetArray, curr.packsz * 2, MFREE);
  if curr.LastData <> nil then
          MemSrv (curr.LastData, curr.BufSize, MFREE);
  MemSrv (curr, sizeOf (TChainItem), MFREE);
 end; // FreeCurrent
 
var t : PChainItem;
begin
 if (curr = nil) then exit; // Failure;
 if (curr = first) and (curr = last) then // Last Item in List
  begin
   FreeCurrent; // ���������� �������
   curr := nil;
   first := nil;
   last := nil;
  end else
 if (curr = first) then // First Item of List
  begin
   first := first.next;
   first.prev := nil;
   FreeCurrent;
   curr := first;
  end else
 if (curr = last) then
  begin
   last := last.prev;
   last.next := nil;
   FreeCurrent;
   curr := last;
  end else
  begin
   // ReConnect
   curr.prev.next := curr.next;
   curr.next.prev := curr.prev;
   t := curr.prev;
   FreeCurrent;
   curr := t;
  end;
end; // Delete

procedure  TListWorks.free; // ������� ������� � ����� ��� ��������
begin
 curr := last;
 if curr = nil then exit;
 repeat
  delete;
 until first = nil;
end; // FreeList


procedure TListWorks.SaveToFile;
var f : file;
    tmp : PChainItem;
    fblck : TFileBlock;
    wrt, n : dword;
begin
 Assign (f, filename);
 ReWrite (f, 1);
 tmp := self.first;     // ������ ����
 n := 1;
 if (tmp <> nil) then
  repeat
   fblck.dwIndex := n;
   fblck.dwSize := sizeOf (fblck) - sizeOf (fblck.data) + tmp.packsz shl 1;
   fblck.dwBufSz := tmp.BufSize;
   fblck.dwAddr := tmp.BaseOfs;
   fblck.dwCount := tmp.ListSize;
   fblck.dwPackSz := tmp.packsz;
   fblck.dwPkAlg := tmp.packalg;
   FillChar (fblck.data, sizeOf (fblck.data), 0); // erase for debuging
   move (tmp.OffsetArray^, fblck.data, tmp.packsz shl 1);
   BlockWrite (f, fblck, fblck.dwSize, wrt);     
   tmp := tmp.Next;
   inc (n);
  until (tmp = nil) or (wrt = 0);
 Close (f); 
end; // TListWorks.SaveToFile

function TListWorks.LoadFromFile;
var f : file;
    tmp : PChainItem;
    fblck : TFileBlock;
    ofs, rd : dword;
    offsets : POffsetArray;
    found : dword;
    lastIndex : dword;
const
    hsz : dword = sizeof (fblck) - sizeof (fblck.data);

begin
 result := 0;
 found := 0;
 AssignFile (f, filename);
 {$I-}
 Reset (f, 1);
 if IOresult <> 0 then exit;
 {$I+}

 if (fileSize (f) > 0) then
 begin
  ofs := 0;
  Free (); // ������� ���������� ���������� ������.
  curr := nil;
  LastIndex := 0;
  repeat

   BlockRead (f, fblck, hsz, rd); // �������� ��������� �����
   Seek (f, ofs);
   BlockRead (f, fblck, fblck.dwSize, rd); // ������ ������ ������
   ofs := ofs + rd;
   if (fblck.dwSize - hsz > 0) then
    begin //
     MemSrv (tmp, sizeOf (TChainItem), MALLOC);
     tmp.BaseOfs := fblck.dwAddr;                // Address of region
     tmp.packsz := fblck.dwPacksz;               // Size of (may be packed) data
     tmp.ListSize := fblck.dwCount and $1ffff;   // Offset count
     tmp.packalg := fblck.dwPkAlg;               // Pack Algorithm
     tmp.BufSize := fblck.dwBufSz and  $1ffff;   // Buffer size
     tmp.LBufSize := 0;
     tmp.LastData := nil;
     MemSrv (offsets, tmp.packsz shl 1, MALLOC );     // Reserving memory for data
     Move (fblck.data, offsets^, tmp.packsz shl 1);  // Copying offsets to new var
     tmp.OffsetArray := offsets;
     tmp.LStep := stp;
     self.Insert (tmp^);
     if (fblck.dwIndex - lastIndex <> 1) then break; // ��������� ��������
     lastIndex := fblck.dwIndex;
     curr := tmp;
     found := found + tmp.ListSize;
    end;
  until (integer (ofs) >= fileSize (f)) or (rd = 0); // ����� ����� ���������
 end;
 Close (f);
 result := found;
end; // TListWorks.LoadFromFile

function  TListWorks.PackArray;

begin
 if xx = nil then raise EInvalidPointer.Create('������������� nil')
   else
with xx^ do
begin
 packalg := NPACKED; // �� ��������� - �� ���������
 packsz := ListSize;
 result := packsz;
 if PENABLE then else exit;
 // �������� �� ����������� ��������� ��������.
 // ������ ��������� ������� ������ ��������� 57�����
 if (packsz > $D830) and (_packalg = 0) then
  begin
   MemSrv (OffsetArray, revsz (packsz) shl 1, MALLOC);
   reverse (src, OffsetArray^, packsz); // ��������� ������� ������
   packalg := packalg or INVPACK;
  end
 else
 if (packsz > $2000) and (_packalg = 0) then
  begin
   OffsetArray := OverPack (src, packsz);
   packalg := packalg or OVRPACK;
  end
 else
  begin
   packalg := _packalg;
   if packalg <> 0 then
      packsz := _lsize
   else
      packsz := listSize;      
   MemSrv (offsetArray, packsz shl 1, MALLOC);
   Move (src, OffsetArray^, packsz shl 1);
  end;
 if packsz = 0 then
    packalg := packalg or 128;
end;
if xx <> nil then
 result := xx.packsz;
end; // packArray

function  TListWorks.UnpackArray;
var pa : dword;
    sz : dword;
begin
 if xx = nil then raise EInvalidPointer.Create('������������� nil');
 pa := xx.packalg;
 with xx^ do
  begin // �������� ������ ����� ������������� - �� ������������
   sz := packsz;
   if (pa and OVRPACK2 <> 0) then
    Over2Unpack (offsetArray^, dst, sz);
   if (pa and OVRPACK <> 0) then
       OverUnpack (offsetArray^, dst, sz);
  if pa and SETPACK <> 0 then
       BitSetUnpack (offsetArray^, dst, sz);   {}
   if pa and INVPACK <> 0 then
       Reverse (offsetArray^, dst, sz); // Priority - Last
   if pa = 0 then
    begin
     move (offsetArray^, dst, sz shl 1); // WORD
     xx.ListSize := sz;
    end;
  end;

 ASSERT (sz = xx.ListSize,
 format ('Unpack alg%u deviation, lsize = %u, must be %u',
         [xx.packalg, sz, xx.ListSize]));{}
 result := sz;
end; // UnpackArray

end.
