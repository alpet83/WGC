unit ChLWorks;

interface

uses Windows, SysUtils, TlHelp32, ChTypes, ChShare, ChAlgs;

type

    PFoundResult = ^TFoundResult;


    { Элемент цепочки списков смещений }
    PChainItem = ^TChainItem;
    TChainItem = record
    // Connection
    Next, Prev : PChainItem;  // Следующий элемент цепочки
    // DATA
         BaseOfs : dword;       // Базовый адрес буффера в процессе
         BufSize : dword;       // Заполненость буффера
        ListSize : dword;       // Кол-во смещений в списке
     OffsetArray : POffsetArray;// Список смещений
        LBufSize : dword;       // Размер предыдущего буффера
        LastData : Pointer;     // Предыдущие данные (opt)
           LStep : word;        // Шаг поиска
         Updated : boolean;
         packalg : dword;       // Алгоритм запаковки
          packsz : dword;
    end;


 { ============================ Класс TListWorks =================================== }
     PListWorks = ^TListWorks;
     TListWorks = class
     public
      pOwner : PFoundResult;
      first, last, curr : PChainItem;
      constructor  Create (owner : Pointer);
      destructor   Destroy;  override;
      procedure    Next;  // Смещает curr к last
      procedure    Prev;  // Смещает curr к first
      function     GetNext : PChainItem;  // Возвращает curr.next
      function     GetPrev : PChainItem;  // Возвращает curr.prev
      procedure    Insert (VAR X : TChainItem); // Добавляет x после curr
      procedure    Delete; // Удаляет curr
      procedure    Free;
      function     GetNeed (r : byte;curp : dword; var Size : dword) : dword;
      function     CalcFound  : dword;
      function     PackArray (var src : TOffsetArray; var xx : PChainItem) : dword;
      function     UnpackArray (var xx : PChainItem; var dst : TOffsetArray) : dword;
      procedure    SaveToFile (const filename: string);           // Сохранение результатов в файл
      function     LoadFromFile (const filename: string; stp: dword) : dword; // Загрузка смещений из файла с выделением памяти
     end; // Класс работы со связанным списком
   // Структура результата поиска
   TFoundResult = record
      step : word; // Шаг отсеивания
      Need : boolean; // SearchFlag
     FList : TListWorks;
   LastPtr : dword;
   fUnknow : boolean; // Поиск неизвестного значение
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
   // Начальный блок в регионе
   if (tmp.BaseOfs >= curp) then result := tmp.BaseOfs;
   // Проход до последнего буффера
   while (tmp <> last) do tmp := tmp.next;
   // Лимит последнего  буффера
   ptr :=  tmp.BaseOfs + tmp.BufSize;
   size := abs (ptr - result); // Максимальный размер нового региона
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

procedure    TListWorks.Next;  // Смещает curr к last
begin
 if curr <> last then curr := curr.next;
end; // Next

procedure    TListWorks.Prev;  // Смещает curr к first
begin
 if curr <> first then curr := curr.prev;
end; // Prev

function     TListWorks.GetNext : PChainItem;  // Возвращает curr.next
begin
 result := curr.next;
end; // GetNext
function     TListWorks.GetPrev : PChainItem;  // Возвращает curr.prev
begin
 result := curr.prev;
end; // GetPrev

procedure    TListWorks.Insert; // Добавляет x после curr
{ Элемент X должен быть создан }
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
   { В этом случае X становится последним элементом
     Его заземляют справа и соединяют со списком слева
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
 
procedure    TListWorks.Delete; // Удаляет curr
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
   FreeCurrent; // Освободить текущий
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

procedure  TListWorks.free; // Удаляет начиная с конца все элементы
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
 tmp := self.first;     // Первый итем
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
  Free (); // Удалить предыдущие результаты поиска.
  curr := nil;
  LastIndex := 0;
  repeat

   BlockRead (f, fblck, hsz, rd); // Загрузка заголовка файла
   Seek (f, ofs);
   BlockRead (f, fblck, fblck.dwSize, rd); // Теперь полное чтение
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
     if (fblck.dwIndex - lastIndex <> 1) then break; // Нарушение индексов
     lastIndex := fblck.dwIndex;
     curr := tmp;
     found := found + tmp.ListSize;
    end;
  until (integer (ofs) >= fileSize (f)) or (rd = 0); // Конец файла достигнут
 end;
 Close (f);
 result := found;
end; // TListWorks.LoadFromFile

function  TListWorks.PackArray;

begin
 if xx = nil then raise EInvalidPointer.Create('Использование nil')
   else
with xx^ do
begin
 packalg := NPACKED; // По умолчанию - не упаковано
 packsz := ListSize;
 result := packsz;
 if PENABLE then else exit;
 // Проверка на возможность инвертной упаковки.
 // Размер исходного массива должен превышать 57КБайт
 if (packsz > $D830) and (_packalg = 0) then
  begin
   MemSrv (OffsetArray, revsz (packsz) shl 1, MALLOC);
   reverse (src, OffsetArray^, packsz); // Запомнить остаток списка
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
 if xx = nil then raise EInvalidPointer.Create('Использование nil');
 pa := xx.packalg;
 with xx^ do
  begin // Исходный массив после использования - не уничтожается
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
