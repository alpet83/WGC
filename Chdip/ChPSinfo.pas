unit ChPSinfo;

interface
uses Windows, SysUtils, TlHelp32, ChShare, ChTypes, PSLists;

function   SearchMB (ptr: DWORD) : WORD;
procedure  UpdateLists (pid: DWORD);

implementation
uses Misk, ChCmd, TlHelpEx, netipc, ChServer, MemMap, ChConst,
     SimpleArray, DataProvider;


var
       buff: array [0..8191] of BYTE;
      mArray: TModuleArrayEx = nil;
   Segments: array [1..255] of TSegment;
     thArray: TThreadArrayEx = nil;
     SegCnt: byte;



function  SearchMB;
var n : WORD;
    p : DWORD;
begin
 result := 0;
 for n := 1 to mArray.ItemsCount do
  begin
   p := mArray [n].hModule;
   if (ptr >= p) and (ptr < P + mArray [n].modBaseSize) then
    result := n;
  end;
end; // SearchSMB

procedure  ExtractSegments (base: Pointer);
var   rd: DWORD;
     ofs: DWORD;
   count: DWORD;
    scnt: WORD; // Кол-во секции в файле
       n: byte;
       s,sname: string;
   hProcess: THandle;
begin
 SegCnt := 0;
 hProcess := ssm.SVars.Alias;
 if hProcess = 0 then exit;
 ReadProcessMemory (hProcess, base, @buff, 8192, rd);
 if rd < 8192 then exit;
 // Проверка на MZ
 if (buff [$00] = ord ('M')) and
    (buff [$01] = ord ('Z')) and
    (buff [$18] = $40)  then else exit;
 ofs := pDWORD (@buff [$3C])^;
 if ofs = 0 then exit;
 ReadProcessMemory (hProcess, ptr (DWORD (base) + ofs), @buff, 8192, rd);
 // Проверка на PE/0/0
 if (buff [$00] = ord ('P')) and
    (buff [$01] = ord ('E')) and
    (PWORD (@buff [$02])^ = 0) then else exit;

 count := PWORD (@buff [$14])^; // Размер дополнительного заголовка
 count := count + 24; // Размер заголовка общий
 scnt := PWORD (@buff [$06])^;
 if scnt > 0 then
  repeat
   // Считывание секций
   ReadProcessMemory (hProcess, ptr (DWORD (base) + ofs + count), @buff, 8192, rd);
   s := '';
   inc (SegCnt);
   with segments [segcnt] do
    begin
     sname := '';
     for n := 0 to 7 do
       if buff [n] = 0 then break
       else sname := sname +  (chr (buff [n]));
     if (sname = '') then sname := '[Unnamed]'  else
      if sname [1] <> '.' then sname := '.' + sname;
     sname :=  LowerCase (sname);
     if sname = '.code' then sname := '.text';
     StrCopyAL (name, sname, 16);
    end; // With Name
    Segments [SegCnt].sbase := ptr (pDWORD (@buff [$0C])^ + DWORD (base));
    Segments [SegCnt].size :=  PDWORD (@buff [$08])^;
    Segments [SegCnt].flags := PDWORD (@buff [$24])^;
    count := count + 40;
  until SegCnt = scnt;    
end;// ExtactSegments

var
   GetModuleFileNameEx: function (hProcess, hModule: THandle;
                                  lpFileName: PChar; nSize: DWORD): DWORD; stdcall = nil;

procedure InitPsApi;
var
   hLib: THandle;
begin
 hLib := LoadLibrary ('psapi.dll');
 if hLib <> 0 then
   @GetModuleFileNameEx :=
    GetProcAddress (hLib, 'GetModuleFileNameExA');
end;

procedure  UpdateSingleList (list: TSimpleArray; pid: DWORD);
begin
 if List.TryLock(100) then
  try
   if List.Update (pid) then SendArray (List);
  finally
   List.Unlock;
  end;
end;  // UpdateSingleList

procedure  UpdateLists;

begin
 if pid = 0 then exit;
 UpdateSingleList (thArray, pid);
 UpdateSingleList (mArray, pid);
end; // UpdateLists;


initialization
 InitPsApi;
 mArray := TModuleArrayEx.Create (IDMODULELIST);
 // mblist := TMemBlockList.Create (sMEMBLOCKLIST);
 thArray := TThreadArrayEx.Create (IDTHREADLIST);
finalization
 mArray.Free;
 // mbList.Free;
 thArray.Free;
end.
