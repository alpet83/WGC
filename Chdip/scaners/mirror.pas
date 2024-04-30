unit mirror;
{ ������ ��������� ��������������� ������ ������

  �������� �����-��������� ������.
  ��� ������/������ ����������� �������� ����� ����������� ������
  ������������ � ��� ���������, ���� � ���������� ����� ���� �� ���� �� ��������
  ���-���� �����.

  ������ ������:
   1. ���������� ����� � ��������� ������ ��������
   2. ���������� �����
   3. ������ ��������� �� ���� �� ��������� ������ ��������.
   4. �������� ����� � ������� �������� ���������

  ������� ������ ������������ ��� ��������������� �������� �����, ��� ��������������
  ������. ��� ��������� ���������� ��� ���������� �����, � ��������� ������������
  ��������������� ����� dec (refc). ����� ������� �������� ���� ������ ������������ � 0.
  ����� ������/������ ��������� ����� � ��������� ������ ��� ������� 0.

}
interface
uses Windows, SysUtils, Misk;

type
     TMBlock = record
      baddr: pointer;            // �������������� ��������� �� ����
      paddr: dword;             // ��������� ������ ��������
      bsize: dword;              // ������ ����� � ������
      refc: Integer;            // ������� ������ �� ����(��� �������������� ��������)
     end;

     TMirror = class (TObject)
     public
        blist: array [1..32768] of TMBlock; // ������ ������ = 512K
       bcount: dword; // ���������� ��������������� ������.
        index: dword; // ������ ���������� ������������ �����.
       allocated: Integer;
       constructor      Create; 
       // ���������� ��� ���������� �����
       procedure        AddBlock (const src: pointer;const pdd, size: dword);
       // ����� ����� �� ��������� ������ ��������
       function         FindBlock (const pdd: dword): dword; // ���������� ������ �����
       // ��������� ��������� ����� � ����������� refc
       function         GetBlock (const indx: dword): pointer;
       // ������� ������������ ������
       procedure        Free;
       // ������� ������������ ������ (���������� � ������).
       procedure        FreeBlocks (all: boolean = false);
       // ����� ��������� � 0
       procedure        ResetRefs;
     end;


var
   mirr: TMirror;

implementation
uses ChShare;
{ TMirror - ���������� ������ }

procedure TMirror.AddBlock(const src: pointer; const pdd, size: dword);
// ����������/���������� ����� � ������
var
   ii, c: Integer;
begin
 if pdd = 0 then exit; // ����� ����� ��
 ii := FindBlock (pdd);
 if (ii <= 0) then
  begin // ��������� ����� � ����������� ��� � ����� ������
   if (bcount < high (blist)) then inc (bcount)
   else raise ERangeError.Create ('���������� ������ ������');
   ii := bcount;  // ���������� ������
   blist [ii].refc := 0; // ��������� ���� ���������
  end;

 with blist [ii] do // ������������� �����
 begin
  // �������� �� ������� ����� � ������
  if baddr = nil then
   begin // ��������� �����
    baddr := VirtualAlloc (nil, size or $3FFF + 1, MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE);
    if (baddr = nil) then raise EInvalidPointer.Create ('�� ������� �������� ������');
    inc (allocated, size);
    c := smobj.ActiveClient;
    smobj.clients [c].UsCommit := allocated;    
    bsize := size; // ����������� �������
    refc := 0;
   end;
  if (bsize > size) then bsize := size; // ���������� �������.
  // ���������� ����� ������ ������ ������� (���� ��� �� ������!)
  if (refc = 0) then move (src^, baddr^, bsize); // ���������� ������
  inc (refc);   // ��������� ������� ������
  blist [ii].paddr := pdd;
 end;

end; // AddBlock

constructor TMirror.Create;
begin
 allocated := 0;
 bcount := 0;
 fillchar (blist, sizeof(blist), 0); // ��������� ���������
 index := 0;
end; // Create

function TMirror.FindBlock(const pdd: dword): dword;
var i: dword;
begin
 i := index;
 result := 0;
 if (bcount < 1) then exit;     // �� � ��� ������
 if (i < 1) then i := 1;
 if (i > bcount) then i := bcount;
 // ������������ ���������������� ����� ������������ �������
 while (i > 0) and (blist [i].paddr > pdd) do dec (i);
 while (i <= bcount) and (blist [i].paddr < pdd) do inc (i);
 if (blist [i].paddr = pdd) then
  begin
   result := i;
   index := i;
   exit;
  end;
 // ����� � ������ ��������� �������
 for i := 1 to bcount do
 if (blist [i].paddr = pdd) then
  begin
   result := i;
   index := i;
   exit;
  end;
end; // FindBlock

procedure TMirror.Free;
begin
 FreeBlocks (true);
 if (allocated > 0) then
     ods (format ('� ������� ������ �� ������������ %d ���� ', [allocated]));
 inherited;
end; // Free

procedure TMirror.FreeBlocks(all: boolean);
var
   c, n: dword;
begin
 for n := 1 to bcount do
 with blist [n] do // ������� ������ �� ����� ������� �������� ��� ��������
 if (all or (refc <= 0)) and (baddr <> nil) then
  begin
   refc := 0;
   VirtualFree (baddr, 0, MEM_RELEASE); // ������� ������ ������
   baddr := nil;
   dec (allocated, bsize); // ��� �������
   c := smobj.ActiveClient;
   smobj.clients [c].UsCommit := allocated;
   bsize := 0;
  end;
 if all then bcount := 0; // ��� ���.  
end; // FreeBlocks

function TMirror.GetBlock;
begin
 result := nil;
 index := indx;
 // ���������� ����������� �����
 if (index > 0) and (index <= bcount) then  result := blist [index].baddr;
end; // GetBlock

procedure TMirror.ResetRefs;
var n: dword;
begin
 index := 1;
 for n := 1 to bcount do blist [n].refc := 0;          // ����� ��������
end; // ResetRefs

end.
