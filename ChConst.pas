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
     sNetworkError = '���������� �������� - ��������� ���������� �������.';

const
    types_all : array [1..7] of string =
     ('BYTE', 'TEXT', 'WIDE', 'SINGLE', 'REAL', 'DOUBLE', 'EXTENDED');
    rules_str : array [1..14] of string =
     ('=', '<', '>', '>=', '<=', '<>', '*', '_', '+', '-', '+=', '-=', '+-', '?');


     MaxRegion = 8192;          // ������������ ���������� ��������

    ExecutablePages = PAGE_EXECUTE or PAGE_EXECUTE_READ or PAGE_EXECUTE_READWRITE;
    // �������������� �������
    IDADDRSLIST         = $1002; // ������ ������� �� ���������� � �������
    IDMODULELIST        = $1003;
    IDPROCESSLIST       = $1004;
    IDREGIONLIST        = $1005;
    IDTHREADLIST        = $1006;
    IDWATCHLIST         = $1007;
    IDICONLIST          = $1008;    
     
   // ������ ����� ������� ��������
   WHOLE1_TYPE = $00000001;    //  1 - ������� �����
   WHOLE2_TYPE = $00000002;    //  2 - ������� �����
   WHOLE4_TYPE = $00000004;    //  4 - ������� �����
   WHOLE8_TYPE = $00000008;    //  8 - ������� �����

   SINGLE_TYPE = $00000400;    //  4 - ������� ������������
   REAL48_TYPE = $00000600;    //  6 - ������� ������������
   DOUBLE_TYPE = $00000800;    //  8 - ������� ������������
   EXTEND_TYPE = $00000A00;    // 10 - ������� ������������

   ANTEXT_TYPE = $00001000;    //  ANSI Text
   WDTEXT_TYPE = $00002000;    //  WIDE Text


    GMEM_LIMIT = $7FFF0000;
    CM_SPYLOAD = $ABBA; // ����� ������ � ��������� �������
       CM_NONE = $0000;
     CM_IDENT =  $0013; // ������������� �������
    CM_CLEARLIST = $F0A; // ������� �� ������� ���������� ������

    CM_SPARAMS = $1000; // ��������� ����������
    CM_LPARAMS = $1100; // �������� ����������
    CM_UPDMAP  = $1222; // �������� �����
    CM_PSLIST  = $1224; // �������� ������ ���������
    CM_PSOPEN  = $1227; // ������ �� �������� ��������
    CM_PSCLOSE = $1228; // ������ �� �������� ��������
     CM_PSKILL = $1229; // ������ �� ���������� ��������
     CM_SEARCH = $2000; // ����� ��� �����
      CM_SIEVE = $4000; // ����������� �����


    { ------------ Messages(1) for work with watch table ---------- }
    CM_WTMESSAGES = $5000;
  //          CM_WTCLEAR = CM_WTMESSAGES + $01;
            CM_WTCHEAT = CM_WTMESSAGES + $01;
       //  CM_WTADDSTART = CM_WTMESSAGES + $03;
      // NM_WTACCEPT = CM_WTMESSAGES + $05;
    CM_WTMSGSLIM = CM_WTMESSAGES + $400;
    { ============================================================ }
    { ��������� ������������ ��� ������������� ������� � �������� }
        CM_SYNCMESSAGES = $5500;
        CM_ACQUIREMUTEX = CM_SYNCMESSAGES + $01;
        CM_RELEASEMUTEX = CM_SYNCMESSAGES + $02;
       NM_MUTEXACQUIRED = CM_SYNCMESSAGES + $11;
       NM_MUTEXRELEASED = CM_SYNCMESSAGES + $12;

    { }
      CM_LDATA = $7005;
       CM_TEST = $FDDE; // ������ �� ����� ��������� ���������
       CM_WMIN = $AC00; // ������������� ����
       CM_WMAX = $AC01; // ��������������� ����
       CM_WRST = $AC02; // ��c��������� ����
       CM_WTXT = $ACFF; // �������� ���������
       CM_ECHO = $0001; // ��������� ������� �� ���������
   CM_COMPLETE = $0002; // ��������� ���������
    CM_SAVERES = $2801; // ��������� ���������� �������� ������/������
    CM_LOADRES = $2802; // ��������� ���������� � ������� ������
     CM_RESIZE = $AF03; // �������� ������ �������� �������
     CM_DISPPG = $B101; // ���������� ������ �������
       CM_HOOK = $0FCB;  // �������� ���������� �������
     CM_UNHOOK = $0FCD; //
      CM_CRWIN = $3333; // ������� ���� ��� ���������� �����
      CM_CLWIN = $3334; // ������� ���� ���������� �����
     CM_UNLOAD = $F0000020; // �������� ��������
     CM_EXITOK = $FFFFFFFE; // ���������� ���������
        ID_SPY = $12233445; // ��������� ������ chdip
        ID_WGC = $74338842; // ��������� ������ wgc

     _NOTIFIES = $1280000;
      NM_MAPCOMPLETE = _NOTIFIES + $0001; // ��������� � ���������� (����)�������� �����
         NM_PSOPENED = _NOTIFIES + $0002; // �������� ���������
         NM_PSCLOSED = _NOTIFIES + $0003; // �������� ���������
     NM_PSTERMINATED = _NOTIFIES + $0004; // ������� ��������

     NM_SCANCOMPLETE = _NOTIFIES + $0015; // ������������ ���������
     NM_SCANPROGRESS = _NOTIFIES + $0016; // ��� ���������� ������� ��������� ������������

    NM_LISTADDCOMPLETE = _NOTIFIES + $0017; // ��������� ���������� ��������� � ������
      NM_CLOSEACCEPT = _NOTIFIES + $FFFF; // ������������ �������� ����������

     // ��������� ������������ ���������� ������ ������
     MBT_MODULE = 0;
       MBT_TEXT = $20;
      MBT_IDATA = $40;
      MBT_UDATA = $80;
      MBT_EXECS = $20000000;



   PAR_RQSINFO = $001; // ������ �� �����

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



