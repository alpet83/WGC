unit ChHeap;
{$WARN SYMBOL_PLATFORM OFF}
interface
uses Windows, ChTypes, ChConst;

type

    TDMSrvCmd = (MALLOC, MFREE, MRESIZ);


var
//   getMem, freeMem, ReAllocMem : dword;  // ��� �� �� ������������ � ���������



    cThreadId: THandle; // ������� �����
      errorId: dword;
      lastDel: Pointer; // ��������� ������������ ���������
      lastAlc: Pointer; // ��������� ���������� ���������.
        error: string;


function         MemSrv (var dst; const size : LongInt; const cm : TDMSrvCmd) : boolean;


implementation
uses SysUtils, Misk, ChShare;


function  MemSrv;
var p : pointer absolute dst;

begin
 result := false;
 case cm of
  malloc :
   begin // �������������� ����� ������.
    try
     p := nil;
     system.GetMem (P, Size);
     lastAlc := p;
    except
     on E:EOutOfMemory do ODS ('��������� ������ / ����� ���������.');
    end; // try
    result := p <> nil;
   end; // malloc
  mresiz :
   begin  // ��������� ������� ����� ������
    if size = 0 then
     begin // �������� ����� ������
      system.FreeMem (p);
      lastdel := p;
      p := nil;
      result := true;
     end
    else
     begin
      system.ReallocMem (p, size);  // Allocating
      result := (p <> nil);
      lastAlc := p;
     end;
   end; // MRESIZ:
  mfree:
  if p <> nil then // ��� �����������
   try // �������� ����� ������
    system.FreeMem (p);
    lastdel := p;
    p := nil;
    result := true;
   except
    On EAccessViolation do
      raise EInvalidPointer.Create
      (format
        ('���������� ��� ������� ������������ ����� �� ������ %p ',
           [p]));
   end;
 end; // case
 if (result and (smobj <> nil)) then smobj.MemInfo;
end;

end.
