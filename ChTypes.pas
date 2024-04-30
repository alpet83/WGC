unit ChTypes;

interface
uses Windows, TlHelp32, ChConst;

const
   IconWidth = 16;
   IconHeight = 16;

type
    AFILE_PATH = array [0..MAX_PATH] of AnsiChar;
    WFILE_PATH = array [0..MAX_PATH] of WideChar;

    ASTRZ256   = array [0..255] of AnsiChar;
    WSTRZ256   = array [0..255] of WideChar;


    TBitmapLine = array [0..IconWidth - 1] of DWORD;
    TIconBitmap = array [0..IconHeight - 1] of TBitmapLine;
    TIconData = packed record
     hWndOwner: HWND;
     IcoDataSz: Integer;
     IcoStream: array [0..2047] of Byte;
    end;
    PIconData = ^TIconData;
    TVMOffset = DWORD;
    TAnsiStr8 = array [0..7] of AnsiChar;
    TAnsiStr16 = array [0..16] of AnsiChar;
    TAnsiStr32 = array [0..31] of AnsiChar;
    TAnsiStr64 = array [0..63] of AnsiChar;
    TWideStr32 = array [0..31] of WideChar;
    TFileStr = array [0..260] of AnsiChar;
      str255 = array [0..255] of AnsiChar;
       str64 = TAnsiStr64;
    smallStr = str64;
    TOffsetArray = array [1..65536] of word;
    POffsetArray = ^TOffsetArray;


(* ================ Типы функций/процедур плагина ================== *)
    // Функция регистрации плагина
    TRegisterFunc = function (var pgName : PAnsiChar;var names : PPCharArray;
                              const hwnd : THandle) : dword; stdcall;
    // Функция отображения диалога настроек плагина
    TDisplayFunc = function (const num : dword;
                             var rqsset : dword) : dword; stdcall;
    // Функция сканирование плагина
    TSearchFirst = function (const buff : pointer;
                             const size : dword;
                             const offsets : POffsetArray) : dword; stdcall;
    // Функция отсева плагина
    TSearchNext = function (const buff : pointer;
                            const offsets : POffsetArray;
                            const count : dword) : dword; stdcall;
      // Функция освобождения памяти плагина
    TFreeFunc = function : boolean; stdcall;

    TFuncRec = record
    dispFunc : TDisplayFunc;
    scanFunc : TSearchFirst;
   sieveFunc : TSearchNext;
    freeFunc : TFreeFunc;
    dlgNames : PPCharArray; // Имена диалогов
    dlgCount : byte; // Количества диалогов
        hLib : THandle;
    end;

    TPluginRec = record
     pgNames : array [1..25] of PString;
     pgFiles : array [1..25] of PString;
     pgFuncs : array [1..25] of TFuncRec;
     pgCount : byte;
    end;

   (* ========================= Типизированные указатели ======================= *)
    PSingle = ^Single;
    PReal48 = ^Real48;
    PDouble = ^Double;
    PExtended = ^Extended;

    TProcess = packed record
       tid, pid: dword;
           hwnd: dword;
           hico: HICON;
           icon: Integer;
           game: dword;  // вероятность что это игра
          fname: array [0..260] of AnsiChar;
          title: array [0..127] of AnsiChar;
           name: array [0..127] of AnsiChar;
     end;


  TMsg = record
   msg : dword; // Код сообщение
   dst : dword; // Кому сообщение 
  end;


  TVClass = (st_int, st_real, st_text, st_wide, st_all, st_mix);
  TSAction = (_noact, _copy, _scan, _sieve);
  TVView = (_normal, _hex, _time);

  { ============================== Структура запроса ================================================ }
  TRequest = packed record
       enabled : boolean;
     min,  max : Int64;      // Целочисленный образец
    minr, maxr : extended;   // Вещественный образец
        textEx : SmallStr;   // Текстовый образец
          rule : dword;
      ruleText : SmallStr;
      typeText : SmallStr;
        Unknow : boolean;
         sactn : TSAction;     // пропуск, копирование, поиск, отсев
        _class : TVClass;    // Класс значения
         vsign : boolean;
         vsize : byte;
         cmpOp : word;      // Код машинной операции сравнения
         jmpOp : byte;      // Код машинной операции условного перехода
         setOp : byte;
       typeset : dword;     // Множество типов значений
         vview : TVView;  
//        szPref : byte;      // Префикс размера операнда
   PlgAssigned : Boolean;   // Данный запрос обрабатывает плагин
  end;


  TRqsList = array [1..MaxRqs] of TRequest;
  PRqsList = ^TRqsList;

const
     MaxPtrs = 655360;
     s32_len = 32;
type
     TPointer = record
        lp : pointer;
        sz : dword;
     end;

    TSegment = packed record
     sbase: pointer;
      size: dword;
     flags: dword;
      name: TAnsiStr16;
    end;


    TProcessInfo = packed record
        title: TAnsiStr64;
        fname: array [0..260] of AnsiChar;
        tid, pid: DWORD;
         icon: Integer; // index of stored icon
     hProcess: THandle;
         hWnd: THandle;
         game: Integer;
    end;

    PProcessInfo = ^TProcessInfo;
    TSmallPSArray = array [0..7] of TProcessInfo;
    PSmallPSArray = ^TSmallPSArray;

    TModuleInfo = packed record
         hModule: DWORD;
     modBaseSize: DWORD;
       szModule: array[0..MAX_MODULE_NAME32] of AnsiChar;
      szExePath: array[0..MAX_PATH - 1] of AnsiChar;
    end;

    TThreadInfo = packed record
     threadId: DWORD;
     ownerPID: DWORD;
    end;
    PThreadInfo = ^TThreadInfo;
    
    TMemBlockRec = packed record
     base: Pointer;
     size: DWORD;
    end;


    TPtrList = array [1..MaxPtrs] of TPointer;
    PPtrList = ^TPtrList;

    TRange = record
     min, max: dword;
    end;
    // Аттрибуты страниц для простого сравнения
    TPageAttrs = (paReadable, paWriteable, paExecutable,
                  paGuarded, paNoaccess);
    TProtSet = set of TPageAttrs;
    TRegionType = DWORD;
    TRegion = packed record
      state: dword;
      rtype: TRegionType;
    protect: dword;
    protset: TProtSet;
      rsize: dword;
       size: dword;
      limit: dword;
      case byte of
       0 : (ofst, abase : dword);
       1 : (lptr, pbase : pointer);
   end; // region

   PRegion = ^TRegion;


    TWgcFileRec = packed record
     flags: dword;                 // Флажки
     offst: TAnsiStr32; // адрес
     descr: TAnsiStr32; // описание
     chval: TAnsiStr32; // значение для патча
     stype: array [0..15] of AnsiChar; // Тип значения
     group: array [0..63] of AnsiChar; // про запас
    end;
    
    TWgcFileRecOld = packed record
     flags: dword;                 // Флажки
     offst: dword;                 // адрес
     descr: array [0..31] of AnsiChar; // описание
     chval: array [0..31] of AnsiChar; // значение для патча
     stype: array [0..15] of AnsiChar; // Тип значения
     group: array [0..63] of AnsiChar; // Группа
    end;

    TFAddr = packed record  // Структура результатов
      vaddr: DWORD;
     vclass: TVClass;   // тип значения (целое, вещественное, строка)
      vsize: Byte;      // Размер значения
    end;

    TFoundRec = packed record
     foundCount: Int64;      // Кол-во найденых
     addedCount: Integer;
         scaned: Integer;
           rqsn: Integer;      // Номер запроса (для автофильтрации)
            unk: boolean;
          addrs: array [1..128] of TFAddr; // Результаты поиска
    end;

    PFoundRec = ^TFoundRec;
    
    TScanProcessInfo = packed record
      scanTime: Double;   // время сканирования
     scanCount: Int64;    // сколько просканированно
     foundVals: Int64;    // Найдено всего значений
    end;
    PScanProcessInfo = ^TScanProcessInfo;
    
    TScanProcessParam = packed record
    { Параметры передаваемые серверу перед сканированием }
      startofs: TVMOffset;
      limitofs: TVMOffset;
     scanPages: record
               attrs: DWORD; // допустимые аттрибуты страниц
       MaxRegionSize: DWORD;
           fMemImage: Boolean;
          fMemMapped: Boolean;
         fMemPrivate: Boolean;
             fTestRW: Boolean;
     end;  // Множество флажков.
    end;

    PScanProcessParam = ^TScanProcessParam; 
 { ==================================== Структура условий поиска/отсева ================================== }
    TSVars = packed record
   aliased: ByteBool; // Флаг открытого процесса (создан алиас)
   aliasedPID: DWORD;
   ScanType: array [0..31] of AnsiChar;
    fbreak: ByteBool; // Флаг прерывания процесса поиска
     alias: THandle; // Хендл процесса
     sofst: dword;   // Смещение поиска
      orNeed: Boolean; // Флажок 1
     orBound: Boolean; // Флажок 2
    params: TScanProcessParam;
//   onlyPrivate: bool;  // Только страницы процесса
   readAll: Int64; // Сколько считано
   scanAll: Int64; // Сколько просканировано
     ticks: Int64;   // такты ЦП
   USearch: boolean; // Unknow search
  Priority: dword;   // Выбранный приориет
 // buffSize: dword;   // Размер буффера
     stick: dword;   // Сдвиг значения текущего времени
      fnds: array [1..MaxRqs] of TFoundRec; // Отчет о найденом
  fAligned: Boolean; // поиск выровненых значений для DWORD     
  end;


    TSpyVars = packed record
        answer: array [0..63] of AnsiChar;
     CanResume: boolean; // Поток можно продолжить
     CanUnload: boolean; // Можно выгрузить ChInit.dll
      fSpyInit: Boolean; // Режим инициализации SpyMode
      fSpyMode: Boolean; // Режим SpyMode
     fHookMode: boolean;
          fSIS: Boolean; // Поиск в себе (режим SpyMode)
      fTimeOut: Boolean; // Таймаут
           hhk: HHOOK;      // Ловушка CHINST      
    end;

    TMessageQueue = packed record
     msgs : array [1..16] of TMsg;
     count : integer;
    end;

    PMsgQueue = ^TMessageQueue;

    TRegrec = packed  record
       ofst: DWORD; // Смещение
      whole: DWORD; // Размер от первого региона
    end;


    // Структура описания потоков-серверов
    TChClient = packed record
     CommitSz: dword;    // Зарезевированно памяти
     ThreadId: THandle;  // ID потока
      hThread: THandle;  // Дескриптор потока
     hProcess: THandle;  // Дескриптор процесса сервера
     ThAlias: THandle;  // Алиас потока для клиентской части
        fDead: Boolean;  // Поток умер :-(
       active: Boolean;  // Поисковый клиент-поток
     hFileMap: THandle;  // Дескриптор проекции файла
     StCommit: dword;    // Зарезервированно хранилищем
     UsCommit: dword;    // Зарезервированно под поиск неизвестных значений   
    end;


  

    TFileBlock = packed record
    dwIndex : dword;
     dwSize : dword; // Размер всего блока данных
    dwBufSz : dword; // Размер буффера (региона) при поиске
   dwPackSz : dword; // Размер (упакованных) данных в словах
     dwAddr : dword; // Адрес в процессе
    dwCount : dword; // Количество смещений списке. Список может (должен) быть упакован
    dwPkAlg : dword; // Алгоритм упаковки
    dwCheck : dword; // Контрольная сумма
       data : array [1..65536] of word; // В реальности он никогда не будет заполен и наполовину
    end;

    SInfRec = record
      hFile : THandle;
        pid : THandle;
      ds : byte;
     end;

    TTextValue = packed record
            Index: Integer;
            flags: DWORD;
            sLock: TAnsiStr8;   // заморозка
     sDescription: TAnsiStr32;  // описание
         sAddress: TAnsiStr32;  // выражение адреса
           sValue: TAnsiStr32;  // текущее значение
      sPatchValue: TAnsiStr32;  // значение по умолчанию для записи
      sValueGroup: TAnsiStr32;  // группа значения
       sValueType: TAnsiStr16;  // тип значения
          sFilter: array [0..1] of AnsiChar;
    end;

    TWatchValue = packed record
           Index: Integer;
           sLock: TAnsiStr8;   // заморозка
        sAddress: TAnsiStr32;  // выражение адреса
     sPatchValue: TAnsiStr32;  // значение по умолчанию для записи
      sValueType: TAnsiStr16;
         sFilter: array [0..1] of AnsiChar;
    end;
     PWatchValue = ^TWatchValue;

     PTextValue = ^TTextValue;
     TTextUpdValue = packed record
       sAddr: TAnsiStr32; // используется для идентификации
      sValue: TAnsiStr32;
     end;  

     TBinaryValue = packed record
         ptr: DWORD;
       descr: TAnsiStr32;
          lock: ByteBool;
           hex: ByteBool;
       enabled: ByteBool;
     writeable: ByteBool;
        vald: Int64;
        valr: extended;
        valt: TAnsiStr32;
        valw: TWideStr32;
       vsize: byte;
       vtype: TVClass;
        rqsn: byte;           // Номер запроса для автофильтрации
     end;
    PBinaryValue = ^TBinaryValue;
    
    TSmallWatchList = array [0..15] of TWatchValue;
    PSmallWatchList = ^TSmallWatchList;


    TUpdValueList = array [0..31] of TTextUpdValue;
    PUpdValueList = ^TUpdValueList;
      
const
     BinaryValueSize = sizeof (TBinaryValue);
     THREAD_TERMINATE               = $0001;
     THREAD_SUSPEND_RESUME          = $0002;
     THREAD_GET_CONTEXT             = $0008;
     THREAD_SET_CONTEXT             = $0010;
     THREAD_SET_INFORMATION         = $0020;
     THREAD_QUERY_INFORMATION       = $0040;
     THREAD_SET_THREAD_TOKEN        = $0080;
     THREAD_IMPERSONATE             = $0100;
     THREAD_DIRECT_IMPERSONATION    = $0200;
     THREAD_ALL_ACCESS              = STANDARD_RIGHTS_REQUIRED or
                                      SYNCHRONIZE or  $3FF;


procedure StrCopyAL (dest: PAnsiChar; const source: String; len: Integer);
procedure StrCopy32 (var dest: TAnsiStr32; const source: String);

implementation
uses SysUtils;



procedure StrCopyAL (dest: PAnsiChar; const source: String; len: Integer);
var
   sa: AnsiString;
begin
 sa := AnsiString(source);
 StrLCopy (dest, PAnsiChar ( sa ), len );
end;

procedure StrCopy32;
begin
 StrCopyAL ( dest, source, 32 );
end;


end.
