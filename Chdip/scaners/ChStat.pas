unit ChStat;
interface
uses Windows, ChTypes, ChConst;
{
  ������ ��������� ����������

  ���������� � ���������� ������������ ��� ����������� �������� ������.
  ��������� ������� ������������ �� ���������� ����� ������������ �������� ������� (ScanBBuff).

    AddStat - ��� ������� ��������� � ������� ������ (��� ������� �����)
  ���� ������ � ������� ��� ������/������ ���� �������� ���������.
  ��� ��������� ������ ����� �������������� ������ �� ������� �������
  ���� ������� � �������� ����� ����������/
}
type

    TStatRec = record
     reg : TRegion;
     fnd : dword; // Found values in region
     // tic : int64; // ����� �������� �������� ���������� � PerfTicks
    end;
    // ������ ����������

    TStatArray = array [1..MaxStat] of TStatRec;

    TStatMan = class (TObject)
      stats : TStatArray;
      stati : dword;    // ������� ������� ����������
      statc : dword;    // ���������� ��������� ����������
     nStatc : dword;    // ���������� ����������� ���������
      lastP : dword;
       NewF : Integer;    // ������� ������
      LastF : Integer;    // ������� � ���������� ���

      index : dword;    // ��� �����������
     constructor                Create;
     procedure                  Reset;
     procedure                  ResetX;
     procedure                  Save;
     procedure                  AddStat (paddr, plimit : dword; const src: TRegion);
     function                   TestPtr (const ptr : dword) : boolean;
     // ����� ������� � ��������� ����������
     function                   Find (const paddr: dword): dword;
  private

   end;


var
     statman : TStatMan;

implementation
uses  ChShare, ChServer;

 constructor            TStatMan.Create;
 begin
 end;

function               TStatMan.Find;
var n: dword;
begin
 result := 0;
 if (statc = 0) then exit;
 if (index > 0) and (stats [index].reg.ofst <= paddr) then
                      else index := 1; // ����� �������
 for n := index to statc do
 if (stats [n].reg.ofst >= paddr) and
    (stats [n].fnd > 0) then
  begin
   result := n;      // ������ ���������� ������
   index := n;       // �������� ������������
   exit;
  end;
end; //TStatMan.Find

procedure               TStatMan.ResetX;
begin
 LastF := 0;
 LastP := 0;
 nStatc := 0;      // ����� ����������
 statI := 0;
end; // ResetX

procedure              TStatMan.Reset;
begin
 statc := 0;
end;

procedure              TStatMan.Save;
begin
 Statc := nStatc; // ��������� ���������� ������ ����������
end;


function               TStatMan.TestPtr;
begin
 result :=  (ptr < LastP) and (LastP > 0);
end;
{
 function   TStatMan.TestMerge (const paddr, count: dword): boolean;
 begin
  result := false;
  if (nStatc = 0) then exit; // �� ������ ����������
  if (stats [nstatc].reg.limit + 64 >= paddr) then // ����� ����� ��� �������
  with stats [nstatc] do
   begin
    reg.limit := paddr + count;        // ��������� �����
    reg.size := reg.limit - reg.ofst;  // ��������������� ������ �������
    reg.rsize := reg.size;
    result := true; // ������� ������
   end;
 end; // TestMerge {}

 procedure   TStatMan.AddStat;
   var n : Integer;
    NewF : Integer;
    count: Integer;
 begin
  NewF := 0; // ����� ����� �������� �� �������� ����������
  count := plimit - paddr; // ���������� ����..
  for n := 1 to MaxRqs do
  if ssm.RqsLst [n].enabled then
     NewF := NewF + ssm.svars.Fnds [n].FoundCount; // �������� �����
  if (count > 0) and (NewF > LastF) and (paddr > LastP) then // ���� ������� ���������
   begin
    if (nStatc < MaxStat) then // ���� �� ����������� ������
     begin
      inc (nStatc); // ���������� ������� ����������
      with stats [nStatc] do
        begin
         fnd := Abs (NewF - LastF);
         reg.ofst := paddr;     // �������� � ��������
         reg.size := count;     // ������ �������
         reg.rsize := count;
         reg.limit := reg.ofst + DWORD(count); // ������ �������
         reg.state := src.state;        // ��������� �������
         reg.protect := src.protect;    // ������ � �������, ������
         LastF := NewF;
        end;
     end; // ���������� ������ ������� ����������   
   end;
  LastP := paddr; // ��������� ��������
 end;

end.
 