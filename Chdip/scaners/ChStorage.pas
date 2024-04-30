unit ChStorage;
interface
{  Новая система хранения/упаковки результатов поиска/отсева.

    В предыдущей системе использовался связанный список массивов
 смещений. Его основным недостатком было - обременительно большое количество
 операций выделения-освобождения виртуальной памяти.

   Новое хранилище работает по принципу потока (файла). Оно позволяет осуществлять
 запись в условный буффер упакованных значений (прямой доступ), и упаковывать списки
 смещений (доступ через функции упаковки). Так же и чтение из него может производится
 напрямую (упакованные значения) или с распаковкой. При этом связанный список упакованных
 данных использует только память банка.

   Внутри хранилища все данные храняться банками (по умолчанию один банк = 1024К).
 Когда в банке остается меньше 32Кбайт свободного места (минимальная эффективность
 упаковки 64К смещений), создается дополнительный банк. Указатели на банки сторятся
 как и раньше списком, но на этот раз односвязанным.

    Механизм упаковки немного усложнен по сравнению с предыдущими версиями. Упаковнанные
 данные сторятся следующими структурами:
  struct packed
  [
    DWORD       bitset;   // Множество 32-битное, еденичный бит означает задействованное смещение
    WORD        offset;   // Смещение от которого произведена выборка
    WORD        count;    // Количество регулярных повторений
  ]

    В множестве bitset каждому сравнению соответствует один бит. При этом нулевой бит
 соответствует нулевому смещению от offset, а 31-ый соответственно 31-му. Для регулярных
 значений (как правило $FFFFFFFF) используется поле count. Это позволяет даже при 100%
 совпадениях в буффере, описать все смещения одной структурой, вобщем по технике RLE.

   Наименьшая эффективность упаковки: 32 смешения могут быть максимально описаны 64 битами
 (полный размер структуры), или соответственно 32см=8байт. Если допустить что все множества
 будут различатся, для описания 64К указателей потребуется 16Кбайт памяти, то есть минимальный
 коэффициент сжатия 1 к 4.

   При отсеве, проверяемые банки после проверки обнуляются. Параллельно, с начала списка
 генерируются новые банки, с данными после отсева. В случае не хватки банков, они вставляются.

   Для более простой организации хранилища, подразумевается что для каждого запроса
 используется отдельный экземпляр класса хранилища. Для смешанного запроса может
 протребоваться нескольоко экземпляров.

   Действительный запрос состоит из одного или нескольких обычных (не более 7).
 Каждая позиция в списке подзапросов фиксирована, и привязывается к соответствующему
 типу значения. У каждого подзапроса есть экземпляр класса TStorage.



}

uses    Windows, ChTypes, ChConst;

const
        BankSize = 128 * 1024;         // 128 - умл. размер банка
         MinFree = 16384;              // Минимальный размер свободного места в банке
        MaxSubRqs = 9;                // Кол-во подзапросов в запросе


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

        TPackList = array [0..32767] of TPackRec; // Максимальный спискок смещений

        PPackList = ^TPackList;

        PPackItem = ^TPackItem;

        TPackItem = packed record    // Структура упакованных данных 6 байт + размер списка
         relnxt: DWORD;              // Смещение от текущего до следующего элемента
         relprv: DWORD;              // Смещение от текущего до предыдущего элемента
         paddr: DWORD;               // Адрес внутри изучаемого процесса
         count: WORD;                // Кол-во элементов
         found: WORD;                // Количество не упакованных элементов
         // list may be used not whole
         list: TPackList;          // Упакованные значения
        end;

        TBankHdr = packed record
         subrqs: Byte;        // Подзапрос внутри запроса
           res1: Byte;        // зарезервированно
           res2: Word;        // зарезервированно  
         minofs: dword;       // Минимальное смещение
         maxofs: dword;       // Максимальное смещение
         banksz: dword;       // Размер банка для исключения проблем
        end;

        PBank = ^TBank;
        TBank = class (TObject)
        public
         // Пределы указателей иследуемого процесса (IPR)
         locked: boolean;
         minofs: dword;       // Минимальное смещение
         maxofs: dword;
         blimit: dword;       // Предельный указатель в банке
         banksz: dword;       // Размер банка для исключения проблем
          valid: boolean;     // Доступен (на случай перезатирки)

           next: PBank;          // Следущий банк или nil.
           prev: PBank;          // Предыдущий банк
           curr: PPackItem;      // Указатель для навигации по банку
           bptr: PPackItem;      // Указатель на начало банка
           tail: PPackItem;      // Указатель на конец данных банка или текущие данные

         constructor        Create;
         function           Contains (const paddr: dword): boolean;
         procedure          Copy (const bank: TBank);
         procedure          Allocate;
         // Получение указатель на структуру связанную с paddr
         function           FindPtr (const paddr: dword): PPackItem;
         // Удаление экземпляра
         procedure          Free;
         // Возвращает указатель на конец банка
         function           GetTailPtr: PPackList;
         function           GetRest: dword; // Сколько еще можно данных упихать
         // Упаковка в блок tail
         procedure          PackList (pa: dword; list: POffsetArray;count : dword);
         // Распаковка блока tail
         function           UnpackList (list: POffsetArray): dword;
         // Распаковка блока bptr, не более 128 указателей
         function           UnpackListEx (var list: array of dword): dword;
         procedure          StorePacked (const pa: dword; const count, fcount: word);
        end;


        PStorage = ^TStorage;

        TStorage = packed class (TObject)
        scanid: dword;        // Номер сканирования
         banks: TBank;        // Список банков
          last: PBank;        // Указатель на последний банк
        // Флажок отсева - если установлен удаляются текущие результаты (банки)
        sieved: Boolean;
         // Используется при отсеве для хранения результов.
         nStor: PStorage;
          fnew: Boolean;   // Флажок нового хранилища
         constructor            Create;
         procedure              CreateNew; // Создание nStor
         procedure              AddBank;
         procedure              AfterSieve;
         // Поиск банка данных ассоциированных с указателем base
         function               FindBank (const base: dword): PBank;
         procedure              Init;
         // Указатель на начало последнего банка
         function               LastPtr : PPackList;
         // Проверка на экземпляр
         procedure              Free (delbanks: boolean = true);
  private
         procedure FreeBanks;
        end; // TStorage

        // Список действительных запросов
        TValidRqs = packed class
        private
         // Список экземпляров класса хранилища
         FoundCount: Integer; // Количество найденых значений по запросу
         procedure              InitSubRqs (const n: byte);
         procedure              FreeSubRqs (const n: byte);
         procedure              UpdSubRqs (const n: byte);
         function               GetFound: Integer;
         procedure              SetFound (nFound: Integer);
        public
         common : TRequest;  // Общий запрос
         subcnt : byte; // Кол-во подзапросов
         slist : array [1..MaxSubRqs] of TStorage;
         rlist : array [1..MaxSubRqs] of TRequest; // Список запросов
         rqsnum: dword; // Номер запроса конкренто

         property Found: Integer read GetFound write SetFound;
         constructor            Create (n: dword);
         procedure              AfterScan;
         // Высвобождение памяти
         procedure              Free;

         procedure              Prepare (const wtype: dword);
         // Разбиение смешанного запроса на подзапросы
         procedure              Split (const r : TRequest);
         // Распаковка архива в список полных смещений (не более 128)
         function               Unpack (var list: array of TFAddr): dword;
         // Обновление подзапросов
         procedure              Update (const r : TRequest);
        end;

       TBlock = record
         addr: pointer;
         size: dword;   // Старший бит - блок используется 
       end;

       TMemMan = class (TObject)  // Диспетчер крупных блоков памяти (кратным размеру страницы)
       private
          blist: array [1..2048] of TBlock;
         bcount: dword;
        public
         constructor            Create;
         function               Allocate (bsz: dword): Pointer;
         procedure              Release (p: pointer);  // Не удаляет блок на самом деле!
         procedure              Free;                  // Удаляет все блоки разом 
        end;


const
     UsedBlock = $80000000;
     AllocMask = $FFFF000;
// Список указателей на результаты поиска
var
    Founds : array [1..MaxRqs] of TValidRqs;
    MemMan : TMemMan;
    _scanid: dword;
    pkfound: dword;
    
// Данная процедура добавляет/замещает запрос, с размножением его по типам
procedure        AddRequest (const rn : byte; const src : TRequest);
// Обновление действительного запроса
procedure        UpdRequest (const rn : byte; const src : TRequest);
// Очистка действительного запроса
procedure        KillRequest (const rn : byte);

// Получение последнего банка и последнего указателя в нем
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
 if (b <> nil) then // Защитная проверка
    result := founds [rq].slist [sn].LastPtr;
end; // GetLast


function         RqsConvert (const r: TRequest) : dword;
begin
 result := 0;   // пустой запрос
 if (r._class = st_int) then
  case r.vsize of
   1: result := WHOLE1_TYPE;
   2: result := WHOLE2_TYPE;
   else result := WHOLE4_TYPE;
  end; // Целые числа
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
 KillRequest (rn); // старый должен умереть
 founds [rn] := TValidRqs.Create (rn);
 founds [rn].Split (src);
end; // AddRequest

procedure        UpdRequest;
begin
 // пересоздание
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
 // Перенос новых значений поиска
 for srq := 1 to MaxSubRqs do
  if (rlist [srq].enabled) and (slist [srq] <> nil) then
  if (slist [srq].sieved) then slist [srq].AfterSieve; // Замещение
end; // TValidRqs.AfterScan

procedure               TValidRqs.Free;
var n : byte;
begin
 for n := 1 to MaxSubRqs do FreeSubRqs (n);
end;

procedure              TValidRqs.InitSubRqs(const n: byte);
begin
 slist [n] := TStorage.Create;
 UpdSubRqs (n); // Обновление подзапроса
end; // TValidRqs.InitSubRqs

procedure              TValidRqs.UpdSubRqs;
begin
 rlist [n] := common;
 rlist [n]._class := SubRqsClass [n]; // Класс под запроса
 rlist [n].vsize := SubRqsSizes [n]; // Для текста размер образца определяется в ChAlgs
 if (rlist [n]._class = st_text) then
   rlist [n].vsize := StrLen (rlist [n].textEx);
 if (rlist [n]._class = st_wide) then
   rlist [n].vsize := StrLen (rlist [n].textEx) * 2; // 1 символ - 2 байта
 rlist [n].enabled := true;
 inc (subcnt);
end; // TValidRqs.UpdSubRqs

procedure              TValidRqs.FreeSubRqs;
begin
 if (slist [n] <> nil) then
  begin
   slist [n].fnew := false;
   slist [n].Free; // Попытка удаления хранилища
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
 ASSERT (self <> nil, 'Вызов метода объекта = NIL'); // Ложное обращение
 // Подготовка к поиску или отсеву
 for srq := 1 to MaxSubRqs do
  if (rlist [srq].enabled) then
  begin
   found := 0; // Сброс счетчика
   // Создать дополнительное хранилище для новых данных
   if ((wtype = 2) or (rlist [srq].Unknow and (rlist [srq].sactn = _scan)))  then
    begin
     slist [srq].CreateNew;
     slist [srq].sieved := true;
    end
   else
   if (wtype = 1) then
     begin
       slist [srq].Free; // Убить хранилище
       slist [srq] := TStorage.Create;   // Создать новое
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
   if not use then continue; // Не распаковывать
   gcnt := slist [srq].banks.UnpackListEx (tmp);
   for n := 1 to gcnt do  // Экспорт значений
   with rlist [srq] do
    begin
     sub := 0;
     if (_class = st_real) and (vsize > 6) then
      begin
       // if (vsize = 6) then  sub := 4;
       if (vsize = 8) then  sub := 4;
       if (vsize = 10) then  sub := 6;
      end;
     list [result].vaddr := tmp [n] - sub; // Коррекция после поиска
     list [result].vsize := vsize;
     list [result].vclass := _class;
     inc (result); // Следующее смещение
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
 else  FreeSubRqs (n); // Убивать лишних
end; // Update

// ######################################################################## //


constructor             TBank.Create;
begin
 next := nil;
 prev := nil;
 bptr := nil;
 tail := nil;
 // Настройка исключительных границ
 minofs := $80000000;
 maxofs := $00000000;
end; // TBank.Create

procedure               TBank.Allocate;

begin
 banksz := BankSize;            // Текущий размер банка
 curr := nil;
 tail := nil;
 bptr := memman.Allocate(banksz); // Попросить блок памяти
 valid := (bptr <> nil);
 if (valid) then
  begin;
   // Настройка остальных указателей
   FillChar (bptr, 0, sizeof (TPackItem)); // Обнулить первый элемент
   tail := bptr;
   blimit := dword (bptr) + banksz - MinFree; // Предельный указатель
   next := nil;
  end
 else
  begin
   banksz := 0;
   blimit := $1234;
   raise EInvalidPointer.Create('Не удалось память зарезервировать: ' + err2str (GetLastError));
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
 else  tmp := _next (tmp); // След. запись
end; // TBank.FindPtr;


procedure               TBank.Free;
begin
 if (bptr <> nil) then  memman.Release (bptr); // "высвободить блок памяти"
 bptr := nil;
 tail := nil;
 next := nil;
 banksz := $FFFFFFFF; // банк убит
 valid := false;
 inherited;
end;

function                TBank.GetTailPtr;
var p: PPackItem;
begin
 // Возвращаяет указатель на список
 result := nil;
 // Проверка не наличия tail
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
// Упаковка нескольких смещений в 32-х битное множество

var    n : byte;
    mask : dword;
begin
 result := 0;
 mask := 1;
 for n := 1 to 32 do
  begin
   if (index > count) then           // ограничение количеством
       break;
   if (ofst = list [index]) then     // смещения совпадают
    begin
     result := result or mask;        // Установка бита в множестве
     inc (index);                     // Прокрутка исходного индекса
    end;
   inc (ofst);
   mask := mask shl 1;           // Получение след. бита маски
  end;
end; // PackToSet

var
   i, id : dword;
   srofs  : WORD;

procedure    AddSet (const st: dword);
begin
  if (st <> tail.list [id].bitset) then // Множества не совпадают
   begin
    if (tail.list [id].rcount > 0) then inc (id); // Увеличить индекс
    tail.list [id].bitset := st;        // Запоминание множества
    tail.list [id].rcount := 1;         // Пока повторений нет
    tail.list [id].offset := srofs;     // Запоминание смещения
   end
   else
    Inc (tail.list [id].rcount);        // Зафиксировано повторение
end; // AddSet
{ -------------------------------------------------------------------------------- }
const
     M32 : dword = not DWORD ($1F);     // Маска

begin
 if (locked) then exit;
 id := 0;
 i := Low (list^);
 if ((count > 0) and (count <= 65536)) then
  begin  // Не оптимизированный вариант
   fillChar (Tail.list, 8, 0); // Забивание нулями основных значений и первого элемента
   tail.count := 0;
   tail.relnxt:= 0;
   repeat
    srofs := list [i] and M32; // Получение смещения,
    AddSet (PackToSet (srofs, i));     // Упаковка в множество и сохранение в список
   until (i > count);  // Прекратить по достижению предела списка  
   if (tail.list [id].rcount > 0) then // Сохранить упакованными
       StorePacked (pa, id + 1, count); // Кол-во = индекс + 1
  End; // По количеству - ОК
end; // TBank.PackList

function                TBank.UnpackList; // Не оптимизированный вариант
var
   index : dword;
   offst : dword;
   
procedure               UnpackSet (st : dword);
var  n : dword;
begin
 // Проверка битов с 0 по 31,  и выставление смещений
 {$IFNDEF _OPT}
 for n := 1 to 32 do
 begin
  if (st and 1 <> 0) then
   begin
    inc (index);
    list [index] := offst;    // Сохранение смещение
   end;
  inc (offst);
  st := st shr 1;             // множества
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
  // Бит в CF
  shr           ebx, 1
  // Если не еденичный - переход
  jnc           @nsave
  // Сохранить смещение
  mov           [2][list + edi * 2], eax
  add           edi, 1        // Индекс смещается
@nsave:
  // Увеличить смещение
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
end; // Распаковка множества

var i, lim, rep : dword;
//    oldofs : dword;
begin
 // Эта функция занимается лишь содержимым curr
 lim := High (TOffsetArray) - 32;
 index := 0;
 i := 0;
 //result := 0;
 if (curr <> nil) and (banksz = BankSize) then
 while (i < curr.count) and (index < lim) do
  Begin
   offst := curr.list [i].offset;  // Базовое смещение
   rep := 1;
   if (curr.list [i].rcount > 0) then
    repeat
     // Повторять нужно количество раз
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
 // Распаковка указателей банка в список адресов
 // Новая версия: распаковка последнего банка и последних  указателей
 // с убыванием адреса.
 {$R+}
 try
 repeat
  curr := bank.tail;
  repeat
   lcnt := UnpackList (@tmp);       // Распаковка в смещения
   lfst := lcnt; // поумолчанию от последнего элемента
   if (lcnt + start > 128) then
       lcnt := 128 - start; // Ограничение по месту назначения
   // Преобразования смещений в адреса
   for n := 1 to lcnt do
        list [start + n - 1] := tmp [lfst - n + 1] + curr.paddr;
   // Смещение в списке
   start := start + lcnt;
   curr := _prev (curr);
   // Условие завершения функции - список заполнен
   fbreak := fbreak or (start = 128) or (curr = nil);
   // Условие завершения цикла - конец банка
  until fbreak;
  // получение
  if (start < 128) then
   begin
    bank := bank.prev;
    fbreak := (bank = nil); // Получается достинут первый банк
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
 // Получение указателя на данные за списком
 rofst := sizeof (TPackRec) * count + 32; // 32 для запаса
 tail.relnxt := rofst;
 { with tail^ do
 if (relnxt and $3F > 0) then  relnxt := relnxt or $3F + 1; // выравнять по границе в 64 {}
 // Сохранение информации о текущем списке
 tail.count := count;
 tail.found := fcount; // количество найденых для проверки
 tail.paddr := pa;
 tail := _next (tail); // Смещение в конец списка
 {$IFOPT D+}
 if (dword (tail) >= blimit + MinFree) then
    raise ERangeError.Create('Явное переполнение банка.');
 {$ENDIF}
 tail.relprv := rofst;
 tail.relnxt := 0;  // Заземление указателя замыканием на себя
 tail.count := 0; // Здесь ничего не добавлено, то есть пока НЕТ
 curr := tail;
 inc (pkfound, fcount);
 // Настройка границ
 if (minofs > pa) then minofs := pa;
 if (maxofs < pa) then maxofs := pa;
except
 ods ('Явное переполнение банка.');
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
 last.next.prev := last; // связать с собой.
 last := last.next;
 last.Allocate;
 last.next := nil;
end;    // AddBank


procedure               TStorage.AfterSieve;
begin
 // НАЗНАЧЕНИЕ: Автоматическое перемещение данных нового хранилища
 // в хранилище - источник.
 FreeBanks;
 if (nStor <> nil) then
  begin
   banks := TBank.Create;
   banks.Copy (nStor.banks);
   last := nStor.last;
   nStor.Free (false); // Удалить это хранилищ, но нетрогать банки
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
  tmp := tmp.next; // Следующий банк
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
 // Удалить новое хранилище из обычного
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
   banks.FreeInstance; // Прямое удаление
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
  if (addr <> nil) and                  // Блок захвачен
     (size and UsedBlock = 0) and       // Не занят
     (size and $FFFF000 = bsz) then     // Подходит по размеру
   begin
    result := addr;                     // Вернуть его
    size := size or UsedBlock;          // Захват блока
    exit;                               // Прекратить поиск
   end;
 if (bcount >= High (blist)) then
    raise ERangeError.Create('Исчерпано пространство свободных блоков. Вероятна утечка памяти');
 p := VirtualAlloc (nil, bsz and AllocMask, MEM_COMMIT, PAGE_READWRITE);
 if (p <> nil) then
  begin
   Inc (bcount);
   blist [bcount].size := (bsz and AllocMask) or UsedBlock;
   blist [bcount].addr := p;
   result := p;
   // Теперь надо оповестить всех что память зарезервирована
   n := ssm.ActiveClient;
   if (n > 0) then inc (ssm.clients [n].StCommit, bsz and AllocMask);
  end;
end; // TMemMan.Allocate


constructor TMemMan.Create;
var n: dword;
begin
 // Инициация нулями всех блоков
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
 // Удаление всех блоков, и освобождение памяти
 for n := 1 to bcount do
 with blist [n] do
 if (addr <> nil) then
 if VirtualFree (addr, size and AllocMask, MEM_DECOMMIT) then // Удалить блок
  begin
   cl := ssm.ActiveClient;
   if (cl > 0) then dec (ssm.clients [cl].StCommit, size);
   blist [n].addr := nil;   // Этот блок освобожден
   blist [n].size := 0;
  end;
 bcount := 0;
end; // TMemMan.Free

procedure TMemMan.Release(p: pointer);
var n: dword;
begin
 // Поиск блока и его "высвобождение"
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
