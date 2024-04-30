unit ChConst;

interface
uses Windows, Messages;


const
     CAPTUREBLT = $40000000;
     BPHDRVALUE: Integer = $27ABCDEF;

     MaxRqs  = 9;
     MaxMsgs = 32;
     MaxStat = 64 * 1024;
     DefaultBufferSize = 56 * 1024;
   // IPC messages
   WM_CONNECTIONEVENT = WM_USER + 4620;
   WM_CONNECTIONSTART = WM_CONNECTIONEVENT + $01;
    WM_CONNECTIONFAIL = WM_CONNECTIONEVENT + $02;
      WM_NETREADEVENT = WM_CONNECTIONEVENT + $10;


   sLISTADDITEMS = 'LISTADDITEMS';
     sPROCESSREC = 'PROCESSINFORECS';
    sPROCESSICON = 'PROCESSICON';
      sWTADDVALS = 'WTADDVALUES';
      sWTUPDVALS = 'WTUPDVALUES';
      sOPENMUTEX = 'CMDOPENMUTEX';
     sMUTEXOPENED = 'MUTEXOPENED';
     sFNDRESULTS = 'FOUNDRESULTS';
     sSCANPSINFO = 'SCANPSINFO';
     sSCANPARAMS = 'SCANPARAMS';
       sNUSERMSG = 'NOTIFYUSRMSG';
        sRQSLIST = 'RQSLIST';
     sCONFIGCOPY = 'CONFIGCOPY';
     swtMutex: PAnsiChar = 'WTABLEMUTEX';
     sNetworkError = 'Соединение потеряно - требуется перезапуск сервера.';

const
    types_all : array [1..7] of string =
     ('BYTE', 'TEXT', 'WIDE', 'SINGLE', 'REAL', 'DOUBLE', 'EXTENDED');
    rules_str : array [1..14] of string =
     ('=', '<', '>', '>=', '<=', '<>', '*', '_', '+', '-', '+=', '-=', '+-', '?');


     MaxRegion = 8192;          // Максимальное количество регионов

    ExecutablePages = PAGE_EXECUTE or PAGE_EXECUTE_READ or PAGE_EXECUTE_READWRITE;
    // Идентификаторы списков
    IDADDRSLIST         = $1002; // список адресов не добавленых в таблицу
    IDMODULELIST        = $1003;
    IDPROCESSLIST       = $1004;
    IDREGIONLIST        = $1005;
    IDTHREADLIST        = $1006;
    IDWATCHLIST         = $1007;
    IDICONLIST          = $1008;    
     
   // Флажки типов искомых значений
   WHOLE1_TYPE = $00000001;    //  1 - байтное целое
   WHOLE2_TYPE = $00000002;    //  2 - байтное целое
   WHOLE4_TYPE = $00000004;    //  4 - байтное целое
   WHOLE8_TYPE = $00000008;    //  8 - байтное целое

   SINGLE_TYPE = $00000400;    //  4 - байтное вещественное
   REAL48_TYPE = $00000600;    //  6 - байтное вещественное
   DOUBLE_TYPE = $00000800;    //  8 - байтное вещественное
   EXTEND_TYPE = $00000A00;    // 10 - байтное вещественное

   ANTEXT_TYPE = $00001000;    //  ANSI Text
   WDTEXT_TYPE = $00002000;    //  WIDE Text


    GMEM_LIMIT = $7FFF0000;
    CM_SPYLOAD = $ABBA; // Поток создан и сообщения обрабат
       CM_NONE = $0000;
     CM_IDENT =  $0013; // Идентификация клиента
    CM_CLEARLIST = $F0A; // Команда на очистку некоторого списка

    CM_SPARAMS = $1000; // Установка параметров
    CM_LPARAMS = $1100; // Загрузка параметров
    CM_UPDMAP  = $1222; // обновить карту
    CM_PSLIST  = $1224; // обновить список процессов
    CM_PSOPEN  = $1227; // запрос на открытие процесса
    CM_PSCLOSE = $1228; // запрос на закрытие процесса
     CM_PSKILL = $1229; // запрос на терминацию процесса
     CM_SEARCH = $2000; // Поиск или отсев
      CM_SIEVE = $4000; // Определенно отсев


    { ------------ Messages(1) for work with watch table ---------- }
    CM_WTMESSAGES = $5000;
  //          CM_WTCLEAR = CM_WTMESSAGES + $01;
            CM_WTCHEAT = CM_WTMESSAGES + $01;
       //  CM_WTADDSTART = CM_WTMESSAGES + $03;
      // NM_WTACCEPT = CM_WTMESSAGES + $05;
    CM_WTMSGSLIM = CM_WTMESSAGES + $400;
    { ============================================================ }
    { Сообщения используемые для синхронизации доступа к ресурсам }
        CM_SYNCMESSAGES = $5500;
        CM_ACQUIREMUTEX = CM_SYNCMESSAGES + $01;
        CM_RELEASEMUTEX = CM_SYNCMESSAGES + $02;
       NM_MUTEXACQUIRED = CM_SYNCMESSAGES + $11;
       NM_MUTEXRELEASED = CM_SYNCMESSAGES + $12;

    { }
      CM_LDATA = $7005;
       CM_TEST = $FDDE; // Запрос на прием тестового сообщения
       CM_WMIN = $AC00; // Минимзировать окно
       CM_WMAX = $AC01; // Максимизировать окно
       CM_WRST = $AC02; // Воcстановить окно
       CM_WTXT = $ACFF; // Рисовать сообщение
       CM_ECHO = $0001; // Сообщение принято на обработку
   CM_COMPLETE = $0002; // Обработка завершена
    CM_SAVERES = $2801; // Сохранить результаты текущего поиска/отсева
    CM_LOADRES = $2802; // Загрузить результаты в текущий запрос
     CM_RESIZE = $AF03; // Изменить размер большого буффера
     CM_DISPPG = $B101; // Отобразить диалог плагина
       CM_HOOK = $0FCB;  // Загрузка посредсвом ловушки
     CM_UNHOOK = $0FCD; //
      CM_CRWIN = $3333; // Создать окно для поглощения ввода
      CM_CLWIN = $3334; // закрыть окно поглощения ввода
     CM_UNLOAD = $F0000020; // комманда выгрузки
     CM_EXITOK = $FFFFFFFE; // Подготовка завершена
        ID_SPY = $12233445; // Сообщение потоку chdip
        ID_WGC = $74338842; // Сообщение потоку wgc

     _NOTIFIES = $1280000;
      NM_MAPCOMPLETE = _NOTIFIES + $0001; // Сообщение о завершении (пере)создания карты
         NM_PSOPENED = _NOTIFIES + $0002; // открытие завершено
         NM_PSCLOSED = _NOTIFIES + $0003; // закрытие завершено
     NM_PSTERMINATED = _NOTIFIES + $0004; // процесс завершен

     NM_SCANCOMPLETE = _NOTIFIES + $0015; // сканирование завершено
     NM_SCANPROGRESS = _NOTIFIES + $0016; // для обновление полоски прогресса сканирования

    NM_LISTADDCOMPLETE = _NOTIFIES + $0017; // завершено добавление элементов в список
      NM_CLOSEACCEPT = _NOTIFIES + $FFFF; // потверждение закрытия соединения

     // константы определяющие назначение секции модуля
     MBT_MODULE = 0;
       MBT_TEXT = $20;
      MBT_IDATA = $40;
      MBT_UDATA = $80;
      MBT_EXECS = $20000000;



   PAR_RQSINFO = $001; // Запрос на поиск

resourcestring
   WGC_TEXT = 'WinnerGameCheater';
   InstInject = 'Install Inject';
   InstFirst = 'Install First';
   MainLib = 'CHDIP.DLL';
   ProgSite = 'http://www.alpet.hotmail.ru';

   
const
     protList: array [1..7] of dword =
     (PAGE_NOACCESS, PAGE_READONLY, PAGE_READWRITE, PAGE_WRITECOPY,
      PAGE_EXECUTE, PAGE_EXECUTE_READ, PAGE_EXECUTE_READWRITE   );

     protStrs: array [1..9] of string =
     ('n/a', 'r', 'rw', 'wc', 'e', 're', 'rwe', 'g', 'nc');


var  bOldWin: Boolean = FALSE;
     TryLockCriticalSection: Boolean = FALSE;
implementation

initialization
 bOldWin := GetVersion () and $FF <= 4;
end.



