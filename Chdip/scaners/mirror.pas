unit mirror;
{ Модуль поддержки ассоциированных блоков памяти

  Включает класс-хранилище блоков.
  При поиске/отсеве неизвестных значений блоки проверяемой памяти
  отображаются в это хранилище, если в конкретном блоке хотя бы один из запросов
  что-либо нашел.

  Задачи класса:
   1. Добавление блока и указателя уровня процесса
   2. Обновление блока
   3. Выдача указателя на блок по указателю уровня процесса.
   4. Удаление блока с нулевым референс счетчиком

  Счетчик ссылок используется для автоматического удаления блока, при многозапросном
  поиске. Его инкремент происходит при обновлении блока, а декремент производится
  непосредственно через dec (refc). Перед отсевом счетчики всех блоков сбрасываются в 0.
  После поиска/отсева удаляются блоки с счетчиком равным или меньшим 0.

}
interface
uses Windows, SysUtils, Misk;

type
     TMBlock = record
      baddr: pointer;            // Действительный указатель на блок
      paddr: dword;             // Указатель уровня процесса
      bsize: dword;              // Размер блока в байтах
      refc: Integer;            // Счетчик ссылок на блок(для предотвращения удаления)
     end;

     TMirror = class (TObject)
     public
        blist: array [1..32768] of TMBlock; // список блоков = 512K
       bcount: dword; // Количество задействованных блоков.
        index: dword; // Индекс последнего возвращеного блока.
       allocated: Integer;
       constructor      Create; 
       // Добавление или обновление блока
       procedure        AddBlock (const src: pointer;const pdd, size: dword);
       // Поиск блока по указателю уровня процесса
       function         FindBlock (const pdd: dword): dword; // Возвращяет индекс блока
       // Получение указателя блока с инкрементом refc
       function         GetBlock (const indx: dword): pointer;
       // Функция освобождения память
       procedure        Free;
       // Функция освобождения блоков (выборочное и полное).
       procedure        FreeBlocks (all: boolean = false);
       // Сброс счетчиков в 0
       procedure        ResetRefs;
     end;


var
   mirr: TMirror;

implementation
uses ChShare;
{ TMirror - Реализация класса }

procedure TMirror.AddBlock(const src: pointer; const pdd, size: dword);
// Обновление/добавление блока в список
var
   ii, c: Integer;
begin
 if pdd = 0 then exit; // Фигня какая то
 ii := FindBlock (pdd);
 if (ii <= 0) then
  begin // Выделение блока с добавлением его в конец списка
   if (bcount < high (blist)) then inc (bcount)
   else raise ERangeError.Create ('Закончился список блоков');
   ii := bcount;  // Установить индекс
   blist [ii].refc := 0; // Поскольку блок создается
  end;

 with blist [ii] do // Инициализация блока
 begin
  // Проверка на наличие блока в памяти
  if baddr = nil then
   begin // Выделение блока
    baddr := VirtualAlloc (nil, size or $3FFF + 1, MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE);
    if (baddr = nil) then raise EInvalidPointer.Create ('Не удалось выделить память');
    inc (allocated, size);
    c := smobj.ActiveClient;
    smobj.clients [c].UsCommit := allocated;    
    bsize := size; // Определение размера
    refc := 0;
   end;
  if (bsize > size) then bsize := size; // Сокращение размера.
  // Обновление блока памяти новыми данными (один раз на запрос!)
  if (refc = 0) then move (src^, baddr^, bsize); // Копировать память
  inc (refc);   // Увеличить счетчик ссылок
  blist [ii].paddr := pdd;
 end;

end; // AddBlock

constructor TMirror.Create;
begin
 allocated := 0;
 bcount := 0;
 fillchar (blist, sizeof(blist), 0); // начальная инициация
 index := 0;
end; // Create

function TMirror.FindBlock(const pdd: dword): dword;
var i: dword;
begin
 i := index;
 result := 0;
 if (bcount < 1) then exit;     // Не в чем искать
 if (i < 1) then i := 1;
 if (i > bcount) then i := bcount;
 // Используется последовательный поиск относительно индекса
 while (i > 0) and (blist [i].paddr > pdd) do dec (i);
 while (i <= bcount) and (blist [i].paddr < pdd) do inc (i);
 if (blist [i].paddr = pdd) then
  begin
   result := i;
   index := i;
   exit;
  end;
 // Поиск с учетом нарушения порядка
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
     ods (format ('В объекте класса не высвобождено %d байт ', [allocated]));
 inherited;
end; // Free

procedure TMirror.FreeBlocks(all: boolean);
var
   c, n: dword;
begin
 for n := 1 to bcount do
 with blist [n] do // Удалять только те блоки которые подходят для удаления
 if (all or (refc <= 0)) and (baddr <> nil) then
  begin
   refc := 0;
   VirtualFree (baddr, 0, MEM_RELEASE); // Удалить регион памяти
   baddr := nil;
   dec (allocated, bsize); // Для отладки
   c := smobj.ActiveClient;
   smobj.clients [c].UsCommit := allocated;
   bsize := 0;
  end;
 if all then bcount := 0; // Вот так.  
end; // FreeBlocks

function TMirror.GetBlock;
begin
 result := nil;
 index := indx;
 // Безопасное возвращение блока
 if (index > 0) and (index <= bcount) then  result := blist [index].baddr;
end; // GetBlock

procedure TMirror.ResetRefs;
var n: dword;
begin
 index := 1;
 for n := 1 to bcount do blist [n].refc := 0;          // Сброс счетчика
end; // ResetRefs

end.
