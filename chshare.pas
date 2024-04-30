{$WARN SYMBOL_PLATFORM OFF}
unit ChShare;

interface
uses Windows, ChTypes, ChConst, ChSettings, PSLists;


type
  {$A4}
  TShareMem = class
  public
   // =============== Общие переменные =============================== //
    objSize: DWORD;      // Размер экземпляра класса
     wgcver: array [0..16] of AnsiChar; // строковая версия WGC
    CopyNum: DWORD;      // Номер копии библиотеки CHDIP
    OwnerID: THandle;           // Ид потока wgc
    wgcPath: array [0..255] of AnsiChar;  // Путь к wgc
       prcs: TProcessInfo;   // Текущий процесс (в котором производится поиск)
    fLocked: Integer;    // Флажок блокировки потоком
      hFile: THandle;    // Дескриптор на FileMap
      msgs1: TMessageQueue;  // Очередь сообщений wgc to chdip
      msgs2: TMessageQueue;  // Очередь сообщений chdip to wgc
      // Массив общих запросов
     RqsLst: TRqsList;
  SelRqsCnt: byte;        // Выбранно запросов
    CurrRqs: byte;        // Текущий запрос (shell)
    bReserv: byte;
    bUpload: ByteBool;        // Флажок загрузки библиотеки
     // Переменные поиска
      svars: TSVars;    // Главная структура поисковых установок
    SpyVars: TSpyVars;
     WDelay: DWORD;             // Задержка при поиске
   Settings: TWgcSettings; 
     timers: array [1..10] of TSystemTime;
   counters: array [1..10] of Int64;
  fComplete: Boolean;
  fScanmode: Boolean; // режим сканирования
        usr: DWORD;
       fMap: boolean; // Флаг наличия карты памяти
 ThreadExit: boolean; // Флаг завершения потока
  fFileLoad: boolean; // Флаг загруженности файлика
    plugRec: TPluginRec;
     plgNum: DWORD;   // Номер плагина (.dll)
     plgRet: DWORD;
     dlgNum: DWORD;   // Номер диалога
  plgRqsSet: DWORD;   // Множество запросов обрабатываемых плагином
   fPlgDisp: boolean;
    fUnload: boolean;
     vmsize: Int64;   // Размер виртуальной памяти в котором поиск идет
     daWait: DWORD;   // Ожидание в режиме пассивности.
    mainWnd: HWND;    // Главное окно (класс. режима ?)
 // ===================== массив локальных переменных ====================
 // Массив клиентов обьекта ShareMem, 1 из них = WGC
    clients: array [1..10] of TChClient; // одновременно - серваки
      clCnt: byte;
//   uiUpdate: Boolean; // acceleration: disabling delays in scaner rountines
// fIdleRead: Boolean; // Idle Reading memory flag
  wgcActive: Boolean; // wgc Is active  
 {private}
  constructor           Create;
  constructor           Attach;
  destructor            Destroy; override;
  {
    // Создание разделяeмого класса
    class function        NewInstance: TObject; override;
    class function        InitInstance (Instance: Pointer): TObject;
  }
  function              ActiveClient: BYTE; // Индекс активного клиента
  procedure             AddRef (const _ThreadID, _hThread : THandle);
  //procedure             AfterConstruction; override;
  function              AllCommit: DWORD;
  function              CheckVer (fExcept: Boolean = true): Boolean;
  function              FoundAll: Int64;
  //procedure             FreeInstance; override;
  procedure             MemInfo;
  procedure             SetActiveClient;    // Назначает текущий клиент активным
  procedure             SetInternalEvent (nEvent: DWORD; bState: boolean);
  procedure             SubRef;
  function              Valid: Boolean;
  function              WaitEvent (nEvent, timeOut: DWORD): Boolean;
 end;


 TFileMapping = object
      hFile: THandle;
       hMap: THandle;
   refCount: Integer;
 end;


 PFileMapping = ^TFileMapping;



const
        stdLimit = $77100000;
         SM_Size = SizeOf (TShareMem);
        libUploadEvent: PAnsiChar = 'WGC_LIBUPLOAD_EVENT0';
        // Для ожидания выгрузки
        wgcSpyModeEvent: PAnsiChar = 'WGC_SPYMODE_EVENT0';
var
    firstLoad: Boolean = true;
      makeAlias: Boolean; // Используется при создании обьекта
    FileMapName: Array [0..1023] of AnsiCHAR = 'ChSharedRecord';

var
   smObj: TShareMem = nil;
  {    sm: TShareMem = nil;}
   SMref: Integer;
  MapSiz: DWORD = 0;
  fOverride: Boolean; // Произошло перекрытие потока
   hEvents: array [1..10] of THandle; // для синхронизаций


//function         AllocShareMem (size: DWORD): pointer;
//procedure        CloseShareMem;
//function         ShareMemSize : DWORD;
procedure        KillLibs; // Выгрузка копии chdip.dll
procedure        _CloseHandle (var h: THandle);


implementation
uses SysUtils, Misk, ChHeap, ChCmd;
{var
   hFileMap : THandle;}


procedure               _CloseHandle (var h: THandle);
begin
 if h <> 0 then CloseHandle (h);
 h := 0;
end;

constructor             TShareMem.Create;
var h: THandle;
begin
 // Инициация переменных класса
 msgs1.count := 0;
 msgs2.count := 0;
 CopyNum := 0;
 clCnt := 1;
 // Главное событие инициации библиотеки
 hEvents [1] := CreateEventA (nil, true, false, LibUploadEvent);
 hEvents [2] := CreateEventA (nil, true, false, wgcSpyModeEvent);
 clients [1].CommitSz := 0;
 clients [1].ThreadId := cThreadId;
 clients [1].hThread := GetCurrentThread;
 clients [1].ThAlias := 0;
 h := GetCurrentProcess ();
 // Процесс - клиент
 DuplicateHandle (h, h, h, @clients [1].hProcess, PROCESS_ALL_ACCESS, true, 0);
 // Заполнение нулями
 FillChar (svars, sizeof (svars), 0);  // данные поиска
 FillChar (prcs, sizeof (prcs), 0);    // данные процесса 
 svars.Priority := THREAD_PRIORITY_NORMAL; // Приоритет по умолчанию
 svars.stick := 9; // 0.5Sec
 MemInfo;
 smRef := 1;
 fUnload := false;
 mainWnd := 0;
end;

constructor            TShareMem.Attach;

begin
 // Down glown
 hEvents [1] := OpenEventA (EVENT_ALL_ACCESS, false, LibUploadEvent);
 hEvents [2] := OpenEventA (EVENT_ALL_ACCESS, false, wgcSpyModeEvent);
end;

{procedure              TShareMem.AfterConstruction;
begin
 ObjSize := smsize;
 hFile := hFileMap; // Замыкание на себя
end;{}
{
class function                TShareMem.NewInstance: TObject;
begin
 smsize := InstanceSize;
 MapSiz := smsize;
 theMap := AllocShareMem (smsize);
 if (theMap = nil) then
   raise EInvalidPointer.Create ('Проблемы инициации общей памяти в TShareMem.NewInstance');
 result :=  InitInstance (theMap);
end;


class function          TShareMem.InitInstance (Instance: Pointer): TObject;
var
    tmpbuff : pointer;
    inst : Pointer;
begin
 if (makeAlias) then   // Сохранять содержимое обьекта
  begin
   inst := pointer (DWORD (Instance) + 4); // Пропуск указателя на VMT
   system.GetMem (tmpBuff, smsize - 4);
   move (inst^, tmpbuff^, smsize - 4);   // Предварительное сохранение
   result := TObject.InitInstance(Instance);
   move (tmpbuff^, inst^, smsize - 4);   // Восстановление данных
   system.FreeMem (tmpBuff);
  end
 else result := TObject.InitInstance(instance);
end;

procedure               TShareMem.FreeInstance;
var p: pointer;
begin
 system.GetMem (p, 128);
 self := p;
 inherited;
 system.FreeMem (p);
 CloseShareMem;
end; // VDSM{}


{function                AllocShareMem;

begin
 SetLastError (0);
 StrPCopy (FileMapName, format ('NETWGCFILEMAP%x', [GetCurrentThreadId]));
 ods (fileMapName);// +

 // Создание файла
 hFileMap := CreateFileMapping ($FFFFFFFF, nil, PAGE_READWRITE, 0,
                    size, FileMapName);
 if (GetLastError = ERROR_ALREADY_EXISTS) and
    not makeAlias then
  begin
   MessageBox (0, 'Не контролируемая ситуация:' + #13#10 +
                   'Повторное создание объекта ShareMem',
                   'Не исправимая ошибка.',
                   MB_OK or MB_ICONERROR);
   ExitProcess ($10);
  end;
 // Маппинг проекции файла
 theMap := MapViewOfFile (hFileMap, FILE_MAP_ALL_ACCESS, 0, 0, size);
 result := theMap;
end; {}



{procedure              CloseShareMem;
begin
 if theMap <> nil then UnmapViewOfFile (theMap);
 if hFileMap <> 0 then _CloseHandle (hFileMap);
 theMap := nil;
end;{}


function              TShareMem.ActiveClient: BYTE;
var n: byte;
begin
 result := 0;
 ASSERT (self <> nil);
 for n := 1 to clcnt do
 if clients [n].active then result := n; // Возвратить индекс
end; // TShareMem.ActiveClient

procedure             TShareMem.SetActiveClient;
var n: byte;
begin
 for n := 1 to clcnt do
 // Активный клиент - текущий поток
  clients [n].active := (clients [n].ThreadId = cThreadID); 
end; // SetActiveClient

procedure             TShareMem.AddRef;
var h, dh: THandle;
begin
 fOverride := (clcnt > 0) and (clients [clcnt].fDead);
 if not fOverride then
  begin
   Inc (smRef);
   inc (clCnt);
  end;
 with clients [clcnt] do
  begin
   clients [clcnt].CommitSz := 0;
   clients [clcnt].StCommit := 0;
   clients [clcnt].ThreadId := _ThreadId;
   clients [clcnt].hThread := _hThread;
   clients [clcnt].hFileMap := hFileMap;
   clients [clcnt].ThAlias := 0;
   h := GetCurrentProcess;
   dh := clients [1].hProcess; // WGC process handle
   if (dh <> 0) then
    begin
     DuplicateHandle (h, hThread, dh, @thAlias,
                        THREAD_ALL_ACCESS, true, 0); // open thread
     DuplicateHandle (h, h, dh, @hProcess,
                        PROCESS_ALL_ACCESS, true, 0); // open process
    end;
   clients [clcnt].fDead := false;
  end; 
 SetActiveClient; // последний поток должен быть активным клиентом
 MemInfo;
end; // AddRef

procedure               TShareMem.SubRef;
var i, n : DWORD;
begin
 Dec (smRef);
 i := 0;
 // Поиск индекса элемента текущего потока
 for n := 1 to clcnt do
     if clients [n].ThreadId = cThreadId then i := n;
 // Смещение данных (удаление элемента)
 if (i > 0) then
 begin
  for n := i to clcnt - 1 do
      clients [n] := clients [n + 1];
  dec (clcnt);
 end;
end; // SubRef


function         TShareMem.Valid: Boolean;
begin
 result := true;
 result := result and (@self <> nil);
 if (result) then
  begin
   result := result and (ObjSize > 0);
   result := result and (clcnt > 0);
  end;  
end;
{ ================= Роутины управления кучей ================== }


procedure        TShareMem.MemInfo;
var n : byte;
begin
 for n := 1 to clcnt do
 with clients [n] do
   if ThreadId = cThreadId then
      CommitSz := DWORD (AllocMemSize) +
                StCommit + UsCommit; // Сколько памяти зарезервировано
end;

function        TShareMem.AllCommit : DWORD;
var n : byte;
begin
 result := 0;
 for n := 1 to clcnt do
     result := result + clients [n].CommitSz;
end;



function         ShareMemSize : DWORD;
begin
 result := TShareMem.InstanceSize;
end;





procedure  KillLibs;
var timeOut, oldNum : DWORD;
begin
 if  (smobj = nil) then exit;
 oldNum := smobj.CopyNum;
 SendMsg (CM_UNHOOK); // Если выйти без восстановления ловушки, плохо будет
 sleep (100);
 SendMsg (CM_UNHOOK); 
 sleep (100);
 timeOut := 10;
 smobj.fUnload := true;
 while ((smobj.CopyNum >= oldNum) and (timeOut > 0)) do
 begin
  dec (timeOut);
  sleep (100);
 end;
 if (timeOut = 0) then
  begin
   if (smobj.copyNum > 0) then dec (smobj.copyNum);
   // FreeLibrary (GetModuleHandle ('chdip.dll'));
  end;
end;


function TShareMem.FoundAll;
var n: Integer;
begin
 result := 0;
 for n := 1 to maxrqs do
  result := result + svars.fnds [n].foundCount;
end;



function TShareMem.CheckVer(fExcept: Boolean): Boolean;
var s: string;
begin
 s := GetVersionStr;
 result := ( s = wgcver );
 if (not result) then
  begin
   if fExcept then
     raise exception.Create
      (format ('Проблема. Не совпадают версии wgc.exe(%s) и chdip.dll(%s).' +
                #13#10'Требуется переустановка программы.',
                  [wgcver, s]));
  end;
end;

destructor TShareMem.Destroy;
begin
end;

function TShareMem.WaitEvent(nEvent, timeOut: DWORD): Boolean;
begin
 result := false;
 if (hEvents [nEvent] <> 0) then
  result := WaitForSingleObject (hEvents [nEvent], timeOut) = WAIT_OBJECT_0; 
end;

procedure TShareMem.SetInternalEvent(nEvent: DWORD; bState: boolean);
begin
 if hEvents [nEvent] = 0 then exit;
 if bState then Windows.SetEvent (hEvents [nEvent])
           else Windows.ResetEvent (hEvents [nEvent]);
end;

procedure CloseEvents;
var nn: DWORD;
begin
 for nn := 1 to High (hEvents) do _CloseHandle (hEvents [nn]);
end;

var nn: DWORD;

initialization
 if smobj = nil then smobj := TShareMem.Create;
 for nn := 1 to high (hEvents) do hEvents [nn] := 0;
 cThreadId := GetCurrentThreadId;
finalization
 CloseEvents; // вообще можно и не удалять...
 smobj.Free;
end.

