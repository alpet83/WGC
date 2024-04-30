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


(* ================ ���� �������/�������� ������� ================== *)
    // ������� ����������� �������
    TRegisterFunc = function (var pgName : PAnsiChar;var names : PPCharArray;
                              const hwnd : THandle) : dword; stdcall;
    // ������� ����������� ������� �������� �������
    TDisplayFunc = function (const num : dword;
                             var rqsset : dword) : dword; stdcall;
    // ������� ������������ �������
    TSearchFirst = function (const buff : pointer;
                             const size : dword;
                             const offsets : POffsetArray) : dword; stdcall;
    // ������� ������ �������
    TSearchNext = function (const buff : pointer;
                            const offsets : POffsetArray;
                            const count : dword) : dword; stdcall;
      // ������� ������������ ������ �������
    TFreeFunc = function : boolean; stdcall;

    TFuncRec = record
    dispFunc : TDisplayFunc;
    scanFunc : TSearchFirst;
   sieveFunc : TSearchNext;
    freeFunc : TFreeFunc;
    dlgNames : PPCharArray; // ����� ��������
    dlgCount : byte; // ���������� ��������
        hLib : THandle;
    end;

    TPluginRec = record
     pgNames : array [1..25] of PString;
     pgFiles : array [1..25] of PString;
     pgFuncs : array [1..25] of TFuncRec;
     pgCount : byte;
    end;

   (* ========================= �������������� ��������� ======================= *)
    PSingle = ^Single;
    PReal48 = ^Real48;
    PDouble = ^Double;
    PExtended = ^Extended;

    TProcess = packed record
       tid, pid: dword;
           hwnd: dword;
           hico: HICON;
           icon: Integer;
           game: dword;  // ����������� ��� ��� ����
          fname: array [0..260] of AnsiChar;
          title: array [0..127] of AnsiChar;
           name: array [0..127] of AnsiChar;
     end;


  TMsg = record
   msg : dword; // ��� ���������
   dst : dword; // ���� ��������� 
  end;


  TVClass = (st_int, st_real, st_text, st_wide, st_all, st_mix);
  TSAction = (_noact, _copy, _scan, _sieve);
  TVView = (_normal, _hex, _time);

  { ============================== ��������� ������� ================================================ }
  TRequest = packed record
       enabled : boolean;
     min,  max : Int64;      // ������������� �������
    minr, maxr : extended;   // ������������ �������
        textEx : SmallStr;   // ��������� �������
          rule : dword;
      ruleText : SmallStr;
      typeText : SmallStr;
        Unknow : boolean;
         sactn : TSAction;     // �������, �����������, �����, �����
        _class : TVClass;    // ����� ��������
         vsign : boolean;
         vsize : byte;
         cmpOp : word;      // ��� �������� �������� ���������
         jmpOp : byte;      // ��� �������� �������� ��������� ��������
         setOp : byte;
       typeset : dword;     // ��������� ����� ��������
         vview : TVView;  
//        szPref : byte;      // ������� ������� ��������
   PlgAssigned : Boolean;   // ������ ������ ������������ ������
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
    // ��������� ������� ��� �������� ���������
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
     flags: dword;                 // ������
     offst: TAnsiStr32; // �����
     descr: TAnsiStr32; // ��������
     chval: TAnsiStr32; // �������� ��� �����
     stype: array [0..15] of AnsiChar; // ��� ��������
     group: array [0..63] of AnsiChar; // ��� �����
    end;
    
    TWgcFileRecOld = packed record
     flags: dword;                 // ������
     offst: dword;                 // �����
     descr: array [0..31] of AnsiChar; // ��������
     chval: array [0..31] of AnsiChar; // �������� ��� �����
     stype: array [0..15] of AnsiChar; // ��� ��������
     group: array [0..63] of AnsiChar; // ������
    end;

    TFAddr = packed record  // ��������� �����������
      vaddr: DWORD;
     vclass: TVClass;   // ��� �������� (�����, ������������, ������)
      vsize: Byte;      // ������ ��������
    end;

    TFoundRec = packed record
     foundCount: Int64;      // ���-�� ��������
     addedCount: Integer;
         scaned: Integer;
           rqsn: Integer;      // ����� ������� (��� ��������������)
            unk: boolean;
          addrs: array [1..128] of TFAddr; // ���������� ������
    end;

    PFoundRec = ^TFoundRec;
    
    TScanProcessInfo = packed record
      scanTime: Double;   // ����� ������������
     scanCount: Int64;    // ������� ���������������
     foundVals: Int64;    // ������� ����� ��������
    end;
    PScanProcessInfo = ^TScanProcessInfo;
    
    TScanProcessParam = packed record
    { ��������� ������������ ������� ����� ������������� }
      startofs: TVMOffset;
      limitofs: TVMOffset;
     scanPages: record
               attrs: DWORD; // ���������� ��������� �������
       MaxRegionSize: DWORD;
           fMemImage: Boolean;
          fMemMapped: Boolean;
         fMemPrivate: Boolean;
             fTestRW: Boolean;
     end;  // ��������� �������.
    end;

    PScanProcessParam = ^TScanProcessParam; 
 { ==================================== ��������� ������� ������/������ ================================== }
    TSVars = packed record
   aliased: ByteBool; // ���� ��������� �������� (������ �����)
   aliasedPID: DWORD;
   ScanType: array [0..31] of AnsiChar;
    fbreak: ByteBool; // ���� ���������� �������� ������
     alias: THandle; // ����� ��������
     sofst: dword;   // �������� ������
      orNeed: Boolean; // ������ 1
     orBound: Boolean; // ������ 2
    params: TScanProcessParam;
//   onlyPrivate: bool;  // ������ �������� ��������
   readAll: Int64; // ������� �������
   scanAll: Int64; // ������� ��������������
     ticks: Int64;   // ����� ��
   USearch: boolean; // Unknow search
  Priority: dword;   // ��������� ��������
 // buffSize: dword;   // ������ �������
     stick: dword;   // ����� �������� �������� �������
      fnds: array [1..MaxRqs] of TFoundRec; // ����� � ��������
  fAligned: Boolean; // ����� ���������� �������� ��� DWORD     
  end;


    TSpyVars = packed record
        answer: array [0..63] of AnsiChar;
     CanResume: boolean; // ����� ����� ����������
     CanUnload: boolean; // ����� ��������� ChInit.dll
      fSpyInit: Boolean; // ����� ������������� SpyMode
      fSpyMode: Boolean; // ����� SpyMode
     fHookMode: boolean;
          fSIS: Boolean; // ����� � ���� (����� SpyMode)
      fTimeOut: Boolean; // �������
           hhk: HHOOK;      // ������� CHINST      
    end;

    TMessageQueue = packed record
     msgs : array [1..16] of TMsg;
     count : integer;
    end;

    PMsgQueue = ^TMessageQueue;

    TRegrec = packed  record
       ofst: DWORD; // ��������
      whole: DWORD; // ������ �� ������� �������
    end;


    // ��������� �������� �������-��������
    TChClient = packed record
     CommitSz: dword;    // ��������������� ������
     ThreadId: THandle;  // ID ������
      hThread: THandle;  // ���������� ������
     hProcess: THandle;  // ���������� �������� �������
     ThAlias: THandle;  // ����� ������ ��� ���������� �����
        fDead: Boolean;  // ����� ���� :-(
       active: Boolean;  // ��������� ������-�����
     hFileMap: THandle;  // ���������� �������� �����
     StCommit: dword;    // ���������������� ����������
     UsCommit: dword;    // ���������������� ��� ����� ����������� ��������   
    end;


  

    TFileBlock = packed record
    dwIndex : dword;
     dwSize : dword; // ������ ����� ����� ������
    dwBufSz : dword; // ������ ������� (�������) ��� ������
   dwPackSz : dword; // ������ (�����������) ������ � ������
     dwAddr : dword; // ����� � ��������
    dwCount : dword; // ���������� �������� ������. ������ ����� (������) ���� ��������
    dwPkAlg : dword; // �������� ��������
    dwCheck : dword; // ����������� �����
       data : array [1..65536] of word; // � ���������� �� ������� �� ����� ������� � ����������
    end;

    SInfRec = record
      hFile : THandle;
        pid : THandle;
      ds : byte;
     end;

    TTextValue = packed record
            Index: Integer;
            flags: DWORD;
            sLock: TAnsiStr8;   // ���������
     sDescription: TAnsiStr32;  // ��������
         sAddress: TAnsiStr32;  // ��������� ������
           sValue: TAnsiStr32;  // ������� ��������
      sPatchValue: TAnsiStr32;  // �������� �� ��������� ��� ������
      sValueGroup: TAnsiStr32;  // ������ ��������
       sValueType: TAnsiStr16;  // ��� ��������
          sFilter: array [0..1] of AnsiChar;
    end;

    TWatchValue = packed record
           Index: Integer;
           sLock: TAnsiStr8;   // ���������
        sAddress: TAnsiStr32;  // ��������� ������
     sPatchValue: TAnsiStr32;  // �������� �� ��������� ��� ������
      sValueType: TAnsiStr16;
         sFilter: array [0..1] of AnsiChar;
    end;
     PWatchValue = ^TWatchValue;

     PTextValue = ^TTextValue;
     TTextUpdValue = packed record
       sAddr: TAnsiStr32; // ������������ ��� �������������
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
        rqsn: byte;           // ����� ������� ��� ��������������
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
