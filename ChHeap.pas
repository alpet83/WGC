unit ChHeap;
{$WARN SYMBOL_PLATFORM OFF}
interface
uses Windows, ChTypes, ChConst;

type

    TDMSrvCmd = (MALLOC, MFREE, MRESIZ);


var
//   getMem, freeMem, ReAllocMem : dword;  // Что бы не использовать в программе



    cThreadId: THandle; // текущий поток
      errorId: dword;
      lastDel: Pointer; // Последний освобожденый указатель
      lastAlc: Pointer; // Последний выделенный указатель.
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
   begin // Резервирование блока памяти.
    try
     p := nil;
     system.GetMem (P, Size);
     lastAlc := p;
    except
     on E:EOutOfMemory do ODS ('Нехватает памяти / много запрошено.');
    end; // try
    result := p <> nil;
   end; // malloc
  mresiz :
   begin  // Изменение размера блока памяти
    if size = 0 then
     begin // Удаление блока памяти
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
  if p <> nil then // Для оптимизации
   try // Удаление блока памяти
    system.FreeMem (p);
    lastdel := p;
    p := nil;
    result := true;
   except
    On EAccessViolation do
      raise EInvalidPointer.Create
      (format
        ('Исключение при попытке освобождения блока по адресу %p ',
           [p]));
   end;
 end; // case
 if (result and (smobj <> nil)) then smobj.MemInfo;
end;

end.
