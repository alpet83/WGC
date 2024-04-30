unit ChSrch;

interface
uses Windows, SysUtils, TlHelp32, ChTypes, ChShare, ChAlgs, ChStat, MemMap,
  ChSettings;
{
    Концепции поисковой системы WGC.

    Поиск в процессе осуществляется по нескольким критериям: тип, правило и образец.
 Фактически инициация запроса, порождает пустой список результатов с закрепленными
 за ним критериями. Если запрос смешанный (обычно несколько типов значения), то создается
 несколько пустых списков результатов. Даже на первом этапе поиска на эти списки действуют
 правила отсева: при нулевом количестве результатов, список уничтожается.

    Смешанный запрос: для поиска значений зараннее неизвестного типа. В поле запроса
 typeset указывается множество типов которые использует этот запрос. 

}

const
     szMBI = sizeof (TMemoryBasicInformation);

type
    // Обьект который и будет производить сканирование
TScaner = class (TObject)
  public
      fReadMem: boolean; // постоянное чтение памяти для предотвращения свопа
        oldmap: Boolean;
       funknow: Boolean;      // Используется поиск не известного значения
           rqs: byte;         // Номер запроса
     CopyCount: LongInt;      // Кол-во скопированных байт
       fRescan: boolean;
        t1, t2: dword;         // Времменные переменные
           map: TMemMap;
      fndstart: dword;         // Начало блока где есть найденые указатели
      fndlimit: dword;         // Конец блока где есть найденые указатели
    fException: Boolean;       // Исключение при поиске
     procedure                  ProcessCreateMap;
  private

     procedure                  AfterScan;
     function                   CopyBuff (size : dword): dword;
     // Создание/инициация действительных запросов
     procedure                  CreateRqsts;
     procedure                  ResetFound;
     // Сканирование буффера, возврат - кол-во найденых указателей
     function                   ScanBuff (size : word): dword;
     procedure                  ScanRegion (var r: TRegion);
     procedure                  ScanBBuff;
     // Отсев буффера ..
     function                   SieveBuff (size : word): dword;
     // Обработка буффера - копирование, поиск, отсев
     function                   ProcessBuff (size: dword): dword;
     function                   AliasTest: boolean;
     function                   InitScaner: boolean;
     // Вывод нескольких адресов в разделяемый список
     procedure                  ListAddrs;
    procedure SaveUnknow(const size: dword);
    public
     flBreak : Boolean;          // Флаг прерывания цикла

     constructor                Create;
     procedure                  LoadFileToCurr (const filename : string);
     procedure                  SaveCurrToFile (const filename : string);
     procedure                  SendScanResults;
     procedure                  Scan;
    end;

var
     lastmp : dword;  // Адрес при создании карты памяти
    // Таблица регионов : [0] - Ptr, [1] - Index32
    // Список буфферов для каждого запроса
       slim : dword;
      mscnt : word;
  HeapStart : dword;
        SIS : boolean = false;    
     scaner : TScaner;

function UpdateVMSMap (base, limit: Int64): Int64;

implementation
uses misk, TimeRts, ChCmd, ChPlugin2, ChConst, ChHeap, ChStorage,
     Mirror, SocketAPI, ChServer, DataProvider, ChLog;


var
   region : TRegion;

function UpdateVMSMap;
var n: Integer;

begin
 result := 0;
 //bLong := TRUE;
 ssm.fMap := false;
 scaner.oldmap := false;
 with ssm.svars.params do
 if (base >= 0) and (limit > base) then
  begin
   startofs := base;
   limitofs := limit;
   LogStr (Format ('Setting scan VM range from $%x to $%x', [base, limit]));
  end
 else
  begin
   if startofs <= 0 then startofs := $100000;
   if limitofs <= startofs then limitofs := $7FFF0000;
  end;
 n := 0;
 with ssm.svars.params do
 if (not ssm.svars.aliased) or
     (startofs >= limitofs) then exit;
 // timeouted loop
 scaner.map.SetRescan;
 LogStrEx ('Start creating map', 13);
 while (not ssm.fMap) and (n < 10000) do
  begin
   scaner.map.AddRegion;
   inc (n);
  end;
 LogStrEx ('Complete creating map', 13);
 result := scaner.map.GetVMSize;
 if result > 0 then
  begin
   LogStrEx(Format ('Map rescaning complete, RangeVMSize = %d',
         [scaner.map.GetVMSize]), 14);
   SendMsgEx (NM_MAPCOMPLETE, scaner.map.GetVMSize);
  end
 else LogStrEx ('Map rescaning result fails', 12); 
end; // UpdateVMSMap


constructor            TScaner.Create;
begin
 inherited;
 fReadMem := false;
 statman := TStatman.Create;
 map := TMemMap.Create;
 dllrng.min := HINSTANCE;
 dllrng.max := dllrng.min + 256 * 1024; // Либа занимает 256К.
 dynarng.min := 0;
 dynarng.max := 0;
end;

procedure              TScaner.CreateRqsts;
// Создание действительных запросов из выделенных в списке RqsLst
var
   n : byte;
begin
 // Цикл по визуальным запросам
 for n := 1 to maxRqs do
 with ssm.rqslst [n] do
 if Enabled then        // Если активен - добавление (замещение) или обновление
  begin
   // Unknow scan - безусловное добавление/замещение запроса
   if (sactn = _copy) or
      (sactn = _scan) and (not Unknow) // Сканирование с образцом
        then   AddRequest (n, ssm.rqslst [n]); // Добавление запроса
   if (sactn = _sieve) or
      (sactn = _scan) and Unknow // Сканирование неизвестных значений
        then   UpdRequest (n, ssm.rqslst [n]); // Обновление запроса
   ASSERT (founds [n] <> nil, 'Не выделено хранилище результатов.');
  end;
end;



function                TScaner.AliasTest: boolean;
begin
 result := true;
 if (ssm.svars.alias = 0) then
  begin
   SendStrMsg (' Нет алиаса процесса - в чем искать ?');
   ssm.fComplete := true;
   result := false;
  end;
end; // AliasTest

function              TScaner.InitScaner : boolean;
var
    rq : byte;

begin
 result := false;
 // Проверка алиаса
 ssm.fComplete := false;
 if not AliasTest then Exit;
 ssm.SVars.fbreak := false;
 // Проверка наличия запросов
 if ssm.SelRqsCnt = 0 then
  begin
   SendStrMsg ('Ошибка: Не выбран не один запрос.');
   exit;
  end;
 // Настройка адресных переменных
 ssm.svars.sofst := 0;
 StartCounter (2);      // Запоминание счетчика тактов 
 ssm.SVars.readAll := 0; // по нулям ... 
 ssm.svars.scanAll := 0;
 rqs := ssm.CurrRqs;     // Выделеный запрос
 ResetFound;   // Сброс результатов предыдущих поисков
 CreateRqsts;  // Создание/инициация действительных запросов
 // Засечение времени
 GetTimerElapsed (1, ssm.timers [3]);
 if ssm.SVars.orNeed then statman.Reset;
 if map.dwAddr = 0 then map.dwAddr := 65536;
 /// -------------- Начало поиска или сканирования -------------- ///
 t2 := 0;
 // Оценка размер сканируемой памяти
 // if ssm.svars.mmsize <= 256 * 1024 then ssm.fMap := false;
 // Настройка пределов поиска    
 map.sptr := ssm.svars.params.startofs;
 map.bptr := ssm.svars.params.limitofs;
 map.WorkFlags := CalcWorkFlags;
 map.CompleteMap; // добавление регионов отсутствующих в памяти
 map.Reset;
 // Подготовка хранилища к новому поиску или отсеву
 funknow := false;
 for rq := 1 to MaxRqs do
 if (founds [rq] <> nil) and (ssm.rqslst [rq].enabled) then
  begin
   founds [rq].Prepare (map.WorkFlags);
   funknow := funknow or founds [rq].common.Unknow; // Установка флага
   if (founds [rq].common.Unknow and (founds [rq].common.sactn = _copy)) then
       ssm.svars.fnds [rq].unk := true; // Пометить как событие
  end;
 result := true;
 if (funknow) then mirr.ResetRefs;      // Сброс счетчиков
 StartTimer (1);   // Запуск таймера для оценки прошедшего времени
 StartCounter (1); // Аппаратный счетчик тактов CPU
end;


// Глобальная функция сканирования памяти процесса
// Вызывается при поступлении сообщения от shell
procedure               TScaner.Scan;
begin
 if not InitScaner then exit;
 // Цикл поиска / отсева
 flBreak := false;
 repeat
  map.offset := 0;
  if not ssm.spyvars.fSpyMode
     and (ssm.svars.Priority <> THREAD_PRIORITY_TIME_CRITICAL)
     and (pWgcSet.bUpdateUI) then
   begin
    t1 := GetTickCount shr ssm.svars.stick;
    if (t1 <> t2) then
     begin
      t2 := t1;
      GetTimerElapsed (1, ssm.timers [9]);
      SendMsgEx (NM_SCANPROGRESS, ssm.svars.scanAll, GetElapsed (9));
     end;
    end;  
   flbreak := flbreak or (map.dwAddr >= map.BPtr);
   flBreak := flBreak or ssm.svars.fbreak;
   if (flBreak) then break;       // Прерывание итерации
   // Оценка кучи шпиена
   if ssm.SpyVars.fSpyMode then  map.HeapTest;
   //  -> Выброр региона для сканирования
   map.SelectRegion (map.dwAddr, region); // Выбор региона
   // Выбран регион с нулевым размером - баг однако
   if region.size = 0 then
   begin
    flBreak := flBreak or (region.ofst >= map.bptr); 
    if region.rsize = 0 then region.rsize := 4096;
    map.dwAddr := map.dwAddr + region.rsize;
    continue; // его нельзя сканировать!
   end;
  //  -> Копирование региона по кускам в большой буффер и сканирование
  ScanRegion (region);   // одна итерация поиска
 until flBreak;
 AfterScan;              // сохранение статистики
 ssm.fFileLoad := false;
end; // Scan

procedure               TScaner.ScanRegion;
var
    rcount, scount: Integer;
         s: string;

Begin
 scount := 0;
 rcount := region.size; // количество байт для чтения
 // нацеливание указателя на регион
 if map.dwAddr <> region.ofst then map.dwAddr := region.ofst;
   Repeat
    map.offset := 0; // сброс смещения
    try              // w - finnaly
    try              // w - except
    // - заполнение большого буффера данными из памяти исследуемого процесса
    CopyCount := map.CopyProcessMem (rcount); // used ipAddr @source ptr
    // -> Цикл сканирования большого буффера по запросам
    // %%%%%%%%%%%%%%%%%%%%%%%% SCANING or SIEVING %%%%%%%%%%%%%%%%%%%%%%%%%%%% //
    if copyCount > 0 then ScanBBuff;
    rcount := rcount - CopyCount;// Вычесть количество
    scount := scount + CopyCount;
     // =============================================================
     // Обслуживание данных статистики, это нужно для оптимизации отсева
     if (fndstart > 0) and (fndlimit > fndstart) then
      begin
       fndstart := Round4K (fndstart);
       fndlimit := Round4K (fndlimit);
       statman.AddStat (fndstart, fndlimit, region);
      end;
    except
     // обработка исключений
     s := '#ERROR: Не обработаное исключение в ScanRegion,';
     s := s + ' адрес сканирования: $' + dword2Hex (map.dwAddr);
     SendStrMsg (s);
     fException := true;
     ssm.svars.fbreak := true;
     ssm.fComplete := false;
     {$IFOPT D+}
     OutputDebugString (PChar (s)); // Отправление отладчику
     {$ENDIF}
     // asm int 3 end;
    end; // try - except;
    finally
    // Смещение указателя сканера внутри региона !
    if CopyCount > 0 then
      map.dwAddr := map.dwAddr + dword (CopyCount)  else
    // Если ничего не скопировано - пропуск блока
    if rcount > 4096 then
       begin
        map.dwAddr := map.dwAddr + 4096;
        rcount := rcount - 4096;
        // rcount := 0; // ??
       end
      else
      // Крайний случай - смещение по 4К страницам
      begin
       map.dwAddr := map.dwAddr + DWORD (rcount);
       rcount := 0;
      end;
    end; // try - finally
   Until rcount = 0;  // Пока не прочитается весь регион
    // - Получение статистики по считыванию регионов
    with ssm.SVars do ReadAll := ReadAll + scount;
end; // TScaner.ScanRegion

procedure TScaner.AfterScan;
var
   rq: byte;
begin
 statman.Save;
 ssm.svars.sofst := map.dwAddr;
 for rq := 1 to MaxRqs do
 if (founds [rq] <> nil) and (ssm.RqsLst [rq].enabled) then
     founds [rq].AfterScan;
 /// -------------- Конец поиска или сканирования -------------- ///
 mirr.FreeBlocks();
 ListAddrs;
 StartCounter (10);
 inc (_scanid);
end; // AfterScan 

procedure TScaner.ProcessCreateMap;
var n: Integer;
begin
 n := 0;
 scaner.map.hProcess := ssm.svars.alias; // описатель процесса
 // Получение информации о динамической памяти chdip.dll
 dynarng.min := dword (lastalc) and $FFFF0000; // 64K Base
 map.Lock;
 {shmrng.min := dword (theMap);
 shmrng.max := shmrng.min + MapSiz;}
 // Цикл сканирования регионов процесса
 if not fReadMem then
 repeat
  n := n + 1;
  // Это формирует у исследуемого процесса большую нагрузку!.
  scaner.map.AddRegion;
  if not Assigned (pWgcSet) then asm int 3 end; 
  fReadMem := ssm.fMap and pWgcSet.bIdleRead;  // закончено сканирование карты
  fReadMem := fReadMem and not (ssm.SpyVars.fSpyMode); // бессмыслено сканировать...
  scaner.map.ReadOfs := 0; // сброс смещение чтения
 until (n > 64) or (ssm.fMap and (n > 4)) or fReadMem // по одному региону обновлять
 else fReadMem := scaner.map.IdleRead;
 if not oldmap and ssm.fmap then
  begin
   // sends regions??
  end;
 oldmap := ssm.fmap;
 map.Unlock;
end;

{ Глобальные определения модуля }
var
   savedFile: string = '';

procedure      TScaner.SaveCurrToFile;
var
   hdr: TBankHdr;
   bnk: PBank;
   str: PStorage;
   rqs: Byte;
    ff: File;
    ns: Byte;
   fnd: Integer;
begin
 // Сохранение всех банков в файл
 rqs := ssm.CurrRqs;  // Текущий запрос
 if nil <> founds [rqs] then
 with Founds [rqs] do
  begin
   if (Found = 0) then exit;
   savedFile := tempDir + '\' + fileName;
   Assign (ff, savedFile);
   {$I-}
   ReWrite (ff, 1);
   if IOresult > 0 then savedFile := ''
   else // Продолжить. Записывать
   try
    fnd := Found;
    BlockWrite (ff, fnd, 4); // Количество найденных указателей
    for ns := 1 to MaxSubRqs do
    if (slist [ns] <> nil) then
    begin
     str := @slist [ns];
     bnk := @str.banks;
     hdr.subrqs := ns;
     Repeat // Цикл по банкам
      hdr.minofs := bnk.minofs;
      hdr.maxofs := bnk.maxofs;
      hdr.banksz := bnk.banksz;
      if (bnk.banksz > 0) then
       begin
        BlockWrite (ff, hdr, SizeOf (hdr));
        BlockWrite (ff, bnk.bptr^, bnk.banksz);
       end;
      bnk := bnk.next;
     Until (bnk = nil);
    end; // Цикл по под запросам
   finally
    CloseFile (ff);
   end; 
   {$I+}
  end;
end; // SaveCurrToFile;

procedure      TScaner.LoadFileToCurr;
var
   hdr: TBankHdr;
   bnk: PBank;
   rqs: Byte;
   srq: Byte;
    ff: File;
    ns: Byte;
   fnd: dword;
begin
 if (SavedFile = '') then
  begin
   ssm.fFileLoad := true; // Пусть листает что есть..
   exit; // Нет сохраненного файла
  end;
 rqs := ssm.CurrRqs;
 if (nil = founds [rqs]) then exit;
 Founds [rqs].Free; // Очистить все результы
 AssignFile (ff, SavedFile);
 {$I-}
 Reset (ff, 1);
 if IOresult = 0 then
 with Founds [rqs] do
  begin
   ssm.svars.fnds [rqs].foundCount := 0;
   // Удаление объектов хранилищ
   for ns := 1 to MaxSubRqs do
     if (slist [ns] <> nil) then
      begin
       slist [ns].Free();
       FreeAndNil (slist [ns]);
      end;
   BlockRead (ff, fnd, 4); // Количество найденных указателей
   if (fnd > 0) then // Есть чего послушать и посмотреть
   repeat // Read Cycle
    // Считывание заголовка банка
    BlockRead (ff, hdr, SizeOf (hdr));
    srq := hdr.subrqs;                     // Подзапрос
    // Анализ аномалий заголовка
    if (srq = 0) or (srq > MaxSubRqs) then break; // Нарушение чтения
    if (hdr.banksz = 0) then break;  // Тоже странно
    rlist [srq].enabled := true;     // Есть такой запрос
    // Создание нового хранилища или банка
    if (slist [srq] = nil) then slist [srq] := TStorage.Create
                           else slist [srq].AddBank; // Добавить банк!
    // Инициализация банка данными заголовка
    bnk := slist [srq].last;
    bnk.minofs := hdr.minofs;
    bnk.maxofs := hdr.maxofs;
    if (hdr.banksz > bnk.banksz) then hdr.banksz := bnk.banksz;
    // Чтение данных в банк из файла
    BlockRead (ff, bnk.bptr^, hdr.banksz, bnk.banksz); // Зачитать
    bnk.tail := nil;
    bnk.GetTailPtr;     // Поиски конца...
   until eof (ff);
   if eof (ff) and (fnd > 0) then
    begin
     ssm.svars.fnds [rqs].foundCount := fnd;
     Found := Fnd;
    end;
  end; // with
 Close (ff);
 {$I+}
 ListAddrs;
 ssm.fMap := false;
 map.fsieve := false;
 map.sievmap.full := false;
 map.lastmap.full := false;
 map.Reset;
 map.fRescan := true;
 ssm.fFileLoad := true;
end; // LoadFileToCurr;


procedure      StoreResults (const rqs: byte; const bank: PBank; pa: dword);
begin
  if (_Lcount = 0) or (_Found = 0) then exit; // Нечего добавлять
  if (_packalg = 0) then  // Упаковка из промежуточного тела
      bank.PackList (pa, pwhole, _Lcount);
  if (_packalg = SETPACK) then PackRLE (pwhole, @bank.tail.list, _Lcount);
  if (_packalg = RLESET) then OverPack (@bank.tail.list, _Lcount);
  if (_packalg = RLESETP) and (_Found > 0) and (_Lcount > 0) then bank.StorePacked (pa, _Lcount, _Found);
   // Регистрация результов
 with founds [rqs] do found := found + _Found;
end; // StoreResults

procedure               TScaner.SaveUnknow (const size: dword);
begin
 if (_Found > 0) then // Сохранение текущей инфы
    mirr.AddBlock(map.sbf, map.ipAddr, size);
end;

procedure       TScaner.SendScanResults;
const  dsize: Integer = sizeof (TFoundRec);
var
    dp: TDataPacket;
    sinf: ^TScanProcessInfo;
    n: Integer;
begin
 // ssm.svars.fnds;
 sinf := @dp.bindata;
 sinf.foundVals := ssm.FoundAll;
 sinf.scanCount := ssm.svars.scanAll;
 with ssm do
 sinf.scanTime := Tacts2sec (counters [10] - counters [1]);
 SendMsg (CM_LDATA);
 SendData (sSCANPSINFO, @dp);
 SendMsgEx (CM_CLEARLIST, IDADDRSLIST);
 if (dsize > sizeof (dp)) or
    (ssm.FoundAll = 0) then
    exit;
 with ssm.svars do
 for n := 1 to MAXRQS do
 with fnds [n] do
 begin
  if (fnds[n].foundCount = 0) then continue;
  Move (fnds [n], dp.bindata, dsize);
  SendMsg (CM_LDATA); // отправляются данные
  SendData (sFNDRESULTS, @dp);
 end;
end;

procedure       CheckBankFull (const stor: PStorage;var bank: PBank; const rqs, srq: byte);
begin
 // Проверка на завершение банка
 if (bank.GetRest < MinFree) or
        (dword (bank.tail) + MinFree >= bank.blimit) then
     begin
      stor.AddBank; // Добавить свежий банк
      bank := stor.last; // Заменить банк
     end;
end; // CheckBankFull


function                   TScaner.CopyBuff (size : dword): dword;
var
   n: dword;
   srq: TRequest;
  bank: PBank;

begin
 result := 0;
 { Инициализация по умолчанию:
   1. Выделение памяти для буффера
   2. Копирование буффера
   3. Запоминание в банк информации о предположительно возможном количестве информации
 - Функция обрабатывает один из первых трех подзапросов, текушего запроса
 }
 if (size > 64) then
 with founds [rqs] do
 for n := 1 to 3 do
 if rlist [n].enabled then
 begin
  srq := rlist [n];
  mirr.AddBlock (map.sbf, map.ipAddr, size); // Копировать буффер и увеличить счетчик
  GetLast (rqs, n, bank);
  _Lcount := 4;                 // Пустые смещения
  _Found := size;               // Типа найдено дофига
  result := _found;
  _Isize := 2;
  // Запомнить список без сканирования
  StoreResults (rqs, bank, map.ipAddr);
  CheckBankFull (@slist [n], bank, rqs, n);
  exit; // Повторения цикла не нужно
 end;
end; // CopyBuff

{\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\}
// процедура сканирования участка региона (буффера или @self)



function      TScaner.ScanBuff (size : word): dword;


 // Сканирование одного под-запроса
 function  ScanSubRqst (const num: byte): dword;
 var
         srq: TRequest;
    scanProc: TScanProc;
       plist: PPackList; // Список для архива
        bank: PBank;     // Используемый банк данных
        stor: PStorage;  // Хранилище куда кладутся указатели
        item: PPackItem;
        indx: dword;
 Begin
  result := 0;
  if (fException) then exit; // Предыдущее исключение не обработано
  srq := founds [rqs].rlist [num];
  ResetVars; // Сброс переменных поиска
  // Инициация образца
  InitExamples (srq);
  ScanProc := GetScanProc (srq);
  if (@ScanProc = nil) then exit;    // Если не удалось подобрать функцию
  stor := @founds [rqs].slist [num]; // Используется текущее хранилище!
  if (srq.Unknow) then
  with founds [rqs] do
   begin
    bank := slist [num].FindBank(map.ipAddr); // Найти банк в котором деньги лежат
    if (bank = nil) then exit;  // Я разочарован
    item := bank.FindPtr (map.ipAddr);
    if (item = nil) then exit;  // Ну что за беда
    // Поиск связанного блока памяти
    indx := mirr.FindBlock(map.ipAddr);
    // Получение указателя блока памяти
    _OldBuff := mirr.GetBlock (indx); // Замечательно - есть доступ к буфферу
    if (_oldbuff = nil) then exit; // Опять проблемы
    if (size > mirr.blist [indx].bsize) then
        size := mirr.blist [indx].bsize; // Коррекция размера буффера
    stor := founds [rqs].slist [num].nStor; // Новое хранилище результатов
    if (stor = nil) then exit;  // Печально
    plist := stor.LastPtr; // Последный указатель
    bank := stor.last;     // Последний банк
   end
  else
   begin
    // Инициация указателя списка для хранения
    plist := GetLast (rqs, num, bank);
   end;
  // Проверка на разрешение сканирования
  if (plist <> nil) then
  // Защищенный вызов
  try
   _found := 0;
   // Выборка оптимизированных функций
   ScanProc (map.sbf, plist, size); // Сканирование блока
   /// =========== сканирование завершено ================== ///
   // Добавление результов сканирования
   if (_Lcount > 0) and (_Found > 0) then
        StoreResults (rqs, bank, map.ipAddr);
   if (srq.Unknow) then SaveUnknow (size); // Сохранение текущего блока
   // UnkScan: Здесь и используется новое хранилище
   CheckBankFull (stor, bank, rqs, num); // Проверка на завершение банка
  except
   On EAccessViolation do
    begin
     fException := true; // Установка флажка
     ods ('Access Violation, Scan ptr: $' + dword2hex (map.dwAddr));
    end
   else
    begin
     ods ('Wild Exception on TScaner.ScanBuff');
     fException := true;
    end;
  end; // try-except
  result := _found;
 End;


var
   n : byte;

Begin
 result  := 0;
 // Сканирование части буффера по подзапросам
 try
  if (rqs in [1..MaxRqs]) then
  with founds [rqs] do
  for n := 1 to MaxSubRqs do
  if (rlist [n].enabled) then result := result +  ScanSubRqst (n);
 except
  On Exception do fException := true;
 end;
End; // ScanBuff

var // отладочные переменные
    err: String;
{!!!!!!@@@@@@@@@@@@@@@@@@@@@~~!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function       TScaner.SieveBuff;
 // Отсев в буффере sbf.
 function       SieveSubRqst (const num: byte): dword;
 var srq: TRequest;
     SieveProc: TSieveProc;
     bank: PBank;
     stor: PStorage;
    plist: PPackList;
   pslist: PPackItem; // Исходный список в множествах
    count: dword;
     indx: dword;
 begin
  result := 0;
  ASSERT (num <= MaxSubRqs, 'Попытка использования подзапроса с большим номером: ' + IntToStr (num));
  if (fException) then exit; // Не обработано предыдущее исключение

  with founds [rqs] do
   begin
    srq := rlist [num];   // Копирование запроса
    _Lcount := 0;
    ResetVars;            // Сброс общих переменных
    InitExamples (srq);   // Установка образца
    SieveProc := GetSieveProc (srq);
    if (@SieveProc = nil) then exit; // Нет функции по запросу
    // Поиск банка соответствующему текущему запросу
    bank := slist [num].FindBank (map.ipAddr);
    if (bank = nil) then exit;  // Не найден банк - не возможен отсев
    pslist := bank.FindPtr(map.ipAddr); // Поиск исходного списка
    if (pslist = nil) then exit;
    if (map.CorrectAddr (pslist.paddr)) then else exit;
    bank.curr := pslist;
    if (srq.Unknow) then
     begin
      // Отработка данных поиск/отсева неизвестного значения
      indx := mirr.FindBlock(map.ipAddr);
      _oldbuff := mirr.GetBlock (indx);
      if (_oldbuff = nil) then exit; // придется пропускать
      if (size > mirr.blist [indx].bsize) then
          size := mirr.blist [indx].bsize;
     end;
    count := pslist.count;      // Количество элементов списка
    if (dataneed = SETPACK) then
        UnpackRLE (@pslist.list, pprevd, count);
    if (dataneed = NPACKED) then
      begin
       _Lcount := bank.UnpackList (pprevd); // Нужна конкретно распаковка
       assert (_Lcount = bank.curr.found, 'Несоответствие при распаковке')
      end;
    stor := slist [num].nStor;  // Хранилище для складывания результатов
    ASSERT (stor <> nil);       // Если не найдено - гавкнуть
    plist := stor.LastPtr;
    passed := 2;
    SieveProc (map.sbf, pprevd, plist, _Lcount);  // Произвести отсев
    if (passed = 1) then
     begin
      err := 'Sieve: Отсев завершился через функцию поиска.';
      ods (err);
      raise Exception.Create (err);
     end;
    // Сохранить результы в новое хранилище
    ASSERT (stor <> nil, 'Сбой указателя нового хранилища');    // Если не найдено - гавкнуть 2
    if (srq.Unknow) then SaveUnknow (size); // Старый буффер запомнить
    StoreResults (rqs, stor.last, map.ipAddr);
    CheckBankFull (stor, stor.last, rqs, num);          // Проверка заполнености банка
   end;
   result := _Found; 
 end; // SieveSubRqst

var n: byte;
begin
 result := 0;
 try
  with founds [rqs] do
  for n := 1 to MaxSubRqs do
  if (n <= MaxSubRqs) and
    (rlist [n].enabled) and (slist [n] <> nil) then result := result + SieveSubRqst (n);
 except
  On EAccessViolation do
   begin
    ods ('Access Violation, Sieve ptr: $' + dword2hex (map.dwAddr));
    fException := true;
   end;
 end;
end; // SieveBuff

function      TScaner.ProcessBuff;
begin
 result := 0;
 // Выборка по типу поиска
 case ssm.RqsLst [rqs].sactn of
   _copy : result := CopyBuff  (size); // Копировать буффер
   _scan : result := ScanBuff  (size); // Сканировать буффер
  _sieve : result := SieveBuff (size); // Отсеивать буффер
 end; // else
 // Синхронизация результатов поиска
 if (founds [rqs] <> nil) then
 with ssm.svars.fnds [rqs] do
      foundCount := founds [rqs].found;
end;


procedure       TScaner.ListAddrs;
var n, nc: Integer;
begin
 // Частичная распаковка архивов для отсылки клиентскому процессу
 for n := 1 to MaxRqs do
 begin
  nc := 0;
  if ssm.RqsLst [n].Enabled and
     (founds [n].found > 0) then
   begin
    ssm.svars.fnds [n].rqsn := n;
    nc := founds [n].Unpack (ssm.svars.fnds [n].addrs);
    if (nc > founds [n].found) then founds [n].found := nc;
   end;
  ssm.svars.fnds [n].addedCount := nc;
 end;
end; // ListAddrs

procedure     TScaner.ScanBBuff;
     var
         n: byte;
    ccount: LongInt;     
     count: dword;
    lfound: dword;
BEGIN
 fndstart := 0;
 if CopyCount < 128 then exit; // маловато байтов
 ccount := copyCount;
 // Лимитация для SPY_MODE
 if ssm.SpyVars.fSpyMode and (ccount > 64) then Dec (ccount, 64);
 // Начальное смещение (в регионе)
 map.offset := 0;
 // Округление по размер кэш-линии
 ccount := (ccount shr 6) shl 6;

 Repeat // Цикл по буфферу
  ssm.svars.sofst := map.dwCurrPtr; // Interface variable
  count := ccount;
  if count > sbfSize then count := sbfSize; // Ограничение 1023 * 64
  // Сканирование основными функциями ведется блоками по 64 байта (развернутость цикла).
  if count > 64 then
   Begin
    // Ошибки SpyMode - проявятся здесь
    if pWgcSet.bPrefetch  // MMX uses PIII internal prefetch
                         then Prefetch ( map.sbf, count );
    fException := false;
    lfound := 0;
    /// ===================  ЦИКЛ СКАНИРОВАНИЯ ПО ЗАПРОСАМ ================= ///
    for n := 1 to MaxRqs do
       if ssm.RqsLst [n].enabled then // Запрос активен ?
        begin
         if (fException) then break; // Прервать сканирование этого региона
         rqs := n;                // Цикл по запросам
         lfound := lfound + ProcessBuff (count);     // Обработать буффер
        end; // Цикл по запросам
       if lfound > 0 then
         begin
           if fndstart = 0 then fndstart := map.ipAddr; // Адрес внутри процесса, для статистики
           fndlimit := map.ipAddr + count; // предел диапазона
         end;
       // Суммирование просканированной памяти
       Inc (ssm.svars.scanALL, LongInt (count));
        if (count >= 64) then
             map.offset := map.offset + count
        else Inc (map.offset, 64); // минимальное смещение в буффере
       End // count > 256
     else Break; // Прерывание цикла
  Dec (ccount, count);
 Until  ccount < 64; // последние байты не учитываются
END; // scanRegion

procedure              TScaner.ResetFound;
var
   n : byte;
begin
 pkfound := 0;
 for n := 1 to maxrqs do
 if (ssm.RqsLst [n].enabled) then
 with ssm.svars.fnds [n] do
  begin
   foundCount := 0;
   addedCount := 0;
   scaned := 0;
   unk := false;
  end;
end; // ResetFound

initialization
finalization
 if (SavedFile <> '') and FileExists (SavedFile) then
    DeleteFile (SavedFile); // Потереть нах
end.


