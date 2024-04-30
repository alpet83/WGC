unit misk;
// Содержит различные функции для читера и не только
interface
// $D+}
{$WARN IMPLICIT_STRING_CAST OFF}
uses Windows, SysUtils, ChTypes, CommCtrl;

var defdc : THandle;
    tempDir: string = 'C:\';
    DebuggerPresent: Boolean = FALSE;
    winver: DWORD = 0;
type
    TCharSet = set of AnsiChar;
    TBytePage = array [0..4095] of Byte;
    PBytePage = ^TBytePage;
const    NULL = 0;


function        Min (a, b: dword) : dword;
function        Max (a, b: Integer): Integer;
procedure       WriteMsg (const x, y : dword;const s : string);
function        CalcMask (sz : byte) : int64;
function        FloatMask (const vs, mm, qm : dword) : dword;

procedure       Str2type (const s : string;var vtype: TVClass;var vsize : byte);
function        Str2Int (const s: String; perr: PInteger = nil): Int64;        
function        FloatV (ex : Extended;const s : byte) : dword;stdcall;
procedure       Float2V (e1, e2 : Extended;const s : byte; var v1, v2 : dword); stdcall;
function        str2f (s : string) : Extended;
function        decr (var x : cardinal) : cardinal;    overload;
function        decr (var x, d : cardinal) : cardinal; overload;
// Hexadecimal convertors
function        Byte2Hex (const b : byte) : string;
function        Word2Hex (const w : word) : string;
function        Dword2Hex (const d : dword) : string;
// debug string outer
procedure       ODS (const smsg : string);

function        S2I (const s : string) : Int64;
function        bound (const v: dword; const rng: TRange) : boolean;
function        _T (const p : pchar) : string;
function        Round4K (const d: dword): dword;
function        ConvType (s: string): string;
function        ConvType2 (var s: string): boolean;

function        Time2dword (const s: string): dword;
function        Dword2time (v: dword): string;

function        UniHex (s: string): string;
procedure       DelChar (var s: string; const ch: char);
// divider and formater sizes
function        msdiv (d: extended) : string;
function        IsType (const src : string; var dst : string) : boolean;
function        IsRule (const s : string; var dst : string) : boolean;
function        ActiveThread: dword;
function        _Len (const s: string): dword;
procedure       AddSpaces (var s: string; const len: Integer);
function        StrExt (const s: string): string;
function        StrInQts (const s, q1, q2: string): string;
function        TestDigits (const s: string): boolean;
procedure       SleepInc (var dd: dword; const dl: dword);
procedure       DbgBreak;
procedure       _or (var dd: dword; const d: dword);
procedure       InitComCtrls;
function        TypeOrd (s: string): dword;
function        StrTok (s: string; var n: Integer; const
                        chars: TCharSet): string;

function        GetVersionStr (szModule: PChar = nil) : string;
procedure       LoadModuleVersion;
function        _test (a, b: dword): boolean;
procedure       _clear (var a: dword; b: dword);
procedure       memsetb (const x: pointer; const value, size: dword);
procedure       memsetz (const x: pointer; size: DWORD);
function        SetBit (src, bits: dword; fset: boolean): dword;
function        Ansi2Oem (const s: string): string;
procedure       ModifyStyle (hWnd: THandle; rems, adds: DWORD);
function        InRect (x, y: Integer; const rt: TRect): Boolean;
function        IntToStr (const i: Int64): String;
function        TextFileOpen (var t: Text; const sFileName: String;
                                bRewrite, bAppend: Boolean): Boolean;

function        ExtractFilePath (const sFileName: String): String;


procedure       CopyMemory (dest, source: Pointer; size: DWORD);
function        CheckIndex (I, Count: Integer): Boolean;
function        Err2str (n : dword): string;
procedure       CloseSyncHandle (var h: THandle);
function        WaitOneObject (hObj: THandle; dwMsec: DWORD;bLogExpire: Boolean): Boolean;
function        GetStrTime (ptime: PSystemTime = nil) : String;
function        IsDebuggerPresent: Boolean; stdcall;
function        CalcHash (const data; szBytes: Integer): Int64;

function        DigDecode (const sdig: string): Extended; // decoding digital value with suffixes
function        scmpi (const s1, s2: String): Boolean; // compares 2 string, case insensetive
function        TryEnterCS (var cs: TRTLCriticalSection ): Boolean;
function        FormatHandle (h: THandle): String;

var IsReleaseBuild: Boolean = false;
    sVersion: String;

implementation
uses ChConst;


function        IsDebuggerPresent; stdcall; external kernel32;

function        FormatHandle;
begin
 if (Integer (h) < 0) or (h > $10000) then
    result := '$' + DWORD2HEX (h) else result := IntToStr (h);
end;

function        TryEnterCS;
begin
 result := TRUE;
 if winver > 4 then result := TryEnterCriticalSection (cs)
  else EnterCriticalSection (cs);
end;

function        scmpi;
begin
 result := LowerCase (s1) = LowerCase (s2)
end;

function        DigDecode;
var bHex: Boolean;
    s: String;
    l, n, e: Integer;
    scal: Extended;
begin
 bHex := FALSE;
 s := '';
 l := Length (sdig);
 scal := 1;                
 // parsing suffixes
 for n := 1 to l do
  case UpCase (sdig [n]) of
  '$': bHex := (n = 1);
  'H': scal := scal * 100;
  'X': bHex := (n = 2) and (sdig [1] = '0');
  'T': scal := scal * 1000; // thousand
  'M': scal := scal * 1e6; // million
  'B': scal := scal * 1e9; // billion
  'K': scal := scal * (1 shl 10); // Kibibyte
  'G': scal := scal * (1 shl 30); // Gebibyte
  else s := s + sdig [n];
 end;
 if bHex then result := str2int ('$' + s) else val (s, result, e);
 result := result * scal;
end; // Digdecode

function        CalcHash (const data; szBytes: Integer): Int64;
type TBytesPage = array [0..63355] of Byte;
     PBytesPage = ^TBytesPage;
var
   pb: PBytesPage;
   n: Integer;
begin
 pb := @data;
 result := 0;
 // упрощенная хэш функция
 for n := 0 to szBytes - 1 do
     result := result xor n + pb [n];
end;

function        GetStrTime;
var lt: _SYSTEMTIME;
begin
 if ptime = nil then
    GetLocalTime (lt)
 else lt := ptime^;
 result := format('%d:%.2d:%.2d,%.3d', [lt.wHour, lt.wMinute, lt.wSecond, lt.wMilliseconds]);
end;

function        WaitOneObject (hObj: THandle; dwMsec: DWORD;bLogExpire: Boolean): Boolean;
var r: DWORD;
begin
 r := WaitForSingleObject (hobj, dwMsec);
 result := (r = WAIT_OBJECT_0) or (r = WAIT_ABANDONED);
 if r = WAIT_FAILED then
    asm int 3 end;
 if bLogExpire and (r = WAIT_TIMEOUT) then
   ods ('#Wait-Timeout expired.');
end;

procedure       CloseSyncHandle;
var hh: THandle;
begin
 if h = 0 then exit;
 hh := h;
 h := 0;
 CloseHandle (hh);
end; // CloseSyncHandle

function        Str2Int (const s: String; perr: PInteger = nil): Int64;
var err: Integer;
begin
 Val (s, result, err);
 if perr <> nil then perr^ := err;
end;

function Err2str;
var
    p : WSTRZ256;
    i : byte;
begin
 p := '';
 FormatMessage (FORMAT_MESSAGE_FROM_SYSTEM, nil, n,
    LANG_NEUTRAL or (SUBLANG_SYS_DEFAULT shl 10), P, 256, nil);
 for i := 0 to 255 do
  if (p [i] = #13) then p [i] := #0;
 str (n, result);
 result := ' ' + result + '.- ' +  p;
end;


function        CheckIndex (I, Count: Integer): Boolean;
begin
 result := (i >= 0) and (i < count);
end;
procedure       CopyMemory;
begin
 ASSERT ((source <> nil) and (dest <> nil));
 Move (source^, dest^, size);
end;

function        ExtractFilePath (const sFileName: String): String;
var p: Integer;
begin
 p := Length (sFileName);
 while (p > 1) and  not ( CharInSet (sFileName [p], ['\', '/'] ) )  do Dec (p);
 result := Copy (sFileName, 1, p);
end;

function        TextFileOpen;

begin
 {$I-}
 result := FALSE;
 try
  AssignFile (t, sFileName);
  if IOresult <> 0 then exit;
  if bRewrite then Rewrite (t) else
  if bAppend then Append (t);
  result := IOresult = 0;
 except
  asm int 3; end;
 end;
 {$I+}
end;

function IntToStr (const i: Int64): String;
begin
 str (i, result);
end; // IntToStr

function InRect;
begin
 with rt do
   result := (x >= Left) and (x <= Right) and
              (y >= Top) and (y <= Bottom);
end;

procedure       ModifyStyle (hWnd: THandle; rems, adds: DWORD);
var style: DWORD;
begin
 style := GetWindowLong (hWnd, GWL_STYLE);
 style := (style and (not rems)) or adds;
 SetWindowLong (hWnd, GWL_STYLE, style);
end;

function        Ansi2Oem (const s: string): string;
var p: PAnsiChar;
begin
 GetMem (p, Length (s) or $15 + 1);
 AnsiToOem ( PAnsiChar ( AnsiString(s) ), p );
 result := p;
end;

function SetBit (src, bits: dword; fset: boolean): dword;
begin
 src := src and (not bits); // clear bits
 if (fset) then src := src or bits; // set bits
 result := src;
end;

procedure       _clear (var a: dword; b: dword);
begin
 b := not b;
 a := a and b;
end; // _clear

procedure       memsetb;
assembler
asm
 push           eax
 push           ebx
 push           ecx
 push           edx
 push           edi
 mov            edi, x
 mov            eax, size
 mov            ecx, value
 mov            edx, value
 add            edi, eax
 shr            eax, 2
 neg            eax     // to negative
 mov            bl, cl
@floop:
 mov            [edi + eax * 4 + 0], cl
 mov            [edi + eax * 4 + 1], dl
 mov            [edi + eax * 4 + 2], bl
 mov            [edi + eax * 4 + 3], cl
 add            eax, 1
 jnz            @floop
 pop            edi
 pop            edx
 pop            ecx
 pop            ebx
 pop            eax
end;

procedure       memsetz;
begin
 memsetb (x, 0, size);
end;

function        _test (a, b: dword): boolean;
begin
 result := a and b <> 0;
end; // _test

function GetVersionStr;

var
   pc: WFILE_PATH;
    p: pointer;
   sz: dword;
   xx: dword;
 data: ^VS_FIXEDFILEINFO;

begin
 StrPCopy (pc, ParamStr (0));   // Имя модуля: wgc.exe default
 if szModule <> nil then
    StrLCopy (pc, szModule, 260);
 sz := GetFileVersionInfoSize (pc, xx); // Размер инфы
 result := '0.0';
 GetMem (p, sz);
 if GetFileVersionInfo (pc, 0, sz, p) then
  begin
   VerQueryValue (p, '\', pointer (data), sz);
   result := IntToStr (data.dwFileVersionMS shr 16) + '.' +
             IntToStr (data.dwFileVersionMS and $FFFF);
  end;
 FreeMem (p);
end; // GetVersionStr

procedure       LoadModuleVersion;
var szModule: WFILE_PATH;
begin
 GetModuleFileName (hInstance, szModule, 260);
 sVersion := GetVersionStr (szModule);
end;

function       StrTok;
begin
 result := '';
 if (n <= 0) then n := 1; 
 while (n <= Length (s)) and
          not CharInSet ( s [n], chars ) do
  begin
   result := result + s [n];
   inc (n);
  end;
 while (n <= Length (s)) and CharInSet (s [n], chars) do
            inc (n); // skipping left chars
end;

function        TypeOrd;
begin
 result := 0;
 s := LowerCase (s);
 if pos ('byte', s) > 0 then result := WHOLE1_TYPE;
 if pos ('word', s) > 0 then result := WHOLE2_TYPE;
 if (pos ('dword', s) > 0) or
    (pos ('long', s) > 0) then result := WHOLE4_TYPE;
 if (pos ('qword', s) > 0) or
    (pos ('int64', s) > 0) then result := WHOLE8_TYPE;
 if pos ('single', s) > 0 then result :=  SINGLE_TYPE;
 if pos ('real', s) > 0 then result :=    REAL48_TYPE;
 if pos ('double', s) > 0 then result :=  DOUBLE_TYPE;
 if pos ('extended', s) > 0 then result := EXTEND_TYPE;
 if pos ('text', s) > 0 then result := ANTEXT_TYPE;
 if pos ('wide', s) > 0 then result := WDTEXT_TYPE;    
end; // TypeOrd

procedure InitCommonControls (); stdcall; external 'comctl32.dll';

procedure       InitComCtrls;
begin
 InitCommonControls;
end; // InitComCtrls

procedure       _or; 
begin
 dd := dd or d;
end; // _or


procedure       DbgBreak;
asm
 int 3  // int 3 - debug break
end; // DbgBreak

procedure       SleepInc;
begin
 sleep (dl);
 inc (dd);
end;

const
     digits: set of AnsiChar = ['0'..'9', 'A'..'F'];

function        TestDigits;
var n: dword;
begin
 result := false;
 for n := 1 to Length (s) do
  if CharInSet ( upcase (s [n]), digits) then result := true;
end;

function        StrInQts;
var p1, p2: dword;
begin
 result := '';
 p1 := pos (q1, s);
 p2 := pos (q2, s);
 if (p1 > 0) and (p2 > p1) then
  result := copy (s, p1 + 1, p2 - p1 - 1);
end;

function   StrExt (const s: string): string;
var
   ss: string;
    c: Integer;
   fhex: boolean; 
begin
 ss := '';
 fhex := pos ('$', s) > 0;
 fhex := fhex or (pos ('0x', LowerCase (s)) > 0);
 if (fhex) then ss := '$'; 
 for c := 1 to Length (s) do
  case upcase (s [c]) of
   'A'..'F': // Обработка шестнацетиричного числа
      if fhex then ss := ss + s [c]  else
       // Обработка суффикса миллиардов
        if upcase (s [c]) = 'B' then ss := ss + '000000000';
   '-', '0'..'9' : ss := ss + s [c];
   ',','.': ss := ss + '.';
   else if not fhex then
   // Работа с суффиксами
     case upcase (s [c]) of
      'H': ss := ss + '00';
      'T': ss := ss + '000';
      'M': ss := ss + '000000';
      'G': ss := ss + '000000000';
     end;
  end;
 result := ss;
end; // strExt

procedure       AddSpaces;
begin
 while (length (s) < len) do s := s + ' ';
end;

function        _Len;
begin
 result := dword (Length (s));
end;

function        ActiveThread;
var pid: dword;
begin
 // получение активного потока
 result := GetWindowThreadProcessId (GetFocus, pid);
end;

function  msdiv (d: extended) : string;
var pfix : char;

procedure  div1k (const ch : char);
 begin
  d := d / 1024;
  pfix := ch;
 end; // div1k
var s : string;
begin
 pfix := ' ';
 if d > 1024 then div1k ('K');
 if d > 1024 then div1k ('M');
 if d > 1024 then div1k ('G');
 s := FormatFloat ('0.0 ', d) + pfix + 'iB ';
 //if pos (',0', s) > 0 then delete (s, length (s) - 2, 2);
 result := s;
end;

function IsType (const src : string; var dst : string) : boolean;
 var tt : string;
     s : string;
 begin
  tt := '';
  s :=  UpperCase (src);
  if (s = 'B') or     (s = 'BYTE')    then tt := 'BYTE' else
  if (s = 'W') or     (s = 'WORD')    then tt := 'WORD' else
  if (s = 'D') or     (s = 'DWORD')   then tt := 'DWORD' else
  if (s = 'WD') or    (s = 'WIDE')    then tt := 'WIDE' else
  if (s = 'T') or     (s = 'TEXT')    then tt := 'TEXT' else
  if (s = 'S') or     (s = 'SINGLE')  or (s = 'FLOAT') then tt := 'SINGLE' else
  if (s = 'R') or     (s = 'REAL')    then tt := 'REAL' else
  if (s = 'DB') or    (s = 'DOUBLE')  then tt := 'DOUBLE' else
  if (s = 'E')  or    (s = 'EXTENDED') then tt := 'EXTENDED' else
  if (s = 'A')  or    (s = 'ALL')      then tt := 'ALL';
  result := tt <> '';
  if result then dst := tt;
 end; // IsType

function IsRule (const s : string; var dst : string) : boolean;
var rr : string;
    i : integer;
begin
 rr := '';
 for i := 1 to High (rules_str) do
     if (s = rules_str [i]) then rr := s;
 result := rr <> '';
 if result then dst := rr;
end;

procedure       DelChar (var s: string; const ch: char);
var n: dword;
begin
 repeat
  n := pos (UpCase (ch), UpperCase (s));
  if (n = 0) then break;
  delete (s, n, 1);
 until false;
end; // DelChar
function        UniHex;
begin
 if (pos ('0x', s) = 1) then
  begin
   delete (s, 1, 2);
   s := '$' + s;
  end;
 if (pos ('H', UpperCase (s)) = Length (s)) then
  begin
   delete (s, Length (s), 1);
   s := '$' + s;
  end;
 result := s; 
end;

function        Time2dword (const s: string): dword;
function        Extract (var index: integer): string;
begin
 result := '';
 while  (index <= length (s)) and
         CharInSet ( s [index], ['0'..'9'])  do
  begin
   result := result + s [index];
   index := index + 1;
  end;
end; // Extract

var
   sms: string;
   d, i : integer;
   e : Integer;
begin
 result := 0;
 i := 1;
 while (i <= Length (s)) do
  begin
   sms := Extract (i);
   val (sms, d, e);
   if (e > 0) then d := 0;
   result := result * 60 + dword  (d);
   inc (i);
  end;
end; // Time2dword

function       LZerro (const s: string) : string;
begin
 if (length (s) = 1)  then result := '0' + s else result := s;
end;

function       Dword2time (v: dword): string;
var
   s: string;
begin
 s := '';
 // Если больше одного часа
 if (v > 3600) then s := s + IntToStr (v div 3600) + ':';
 // Если больше минуты
 if (v > 60) then  s := s + LZerro (IntToStr ((v div 60) mod 60)) + ':';
 // и секунды
 v := v mod 60;
 s := s + LZerro (IntToStr (v));
 result := s;
end; // Dword2time


function        ConvType;
begin
 if s = 'BYTE'   then s := 'I1' else
 if s = 'WORD'   then s := 'I2' else
 if s = 'DWORD'  then s := 'I4' else
 if s = 'QWORD'  then s := 'I8' else
 if s = 'SINGLE' then s := 'R4' else
 if s = 'REAL'   then s := 'R6' else
 if s = 'DOUBLE' then s := 'R8' else
 if s = 'EXTENDED' then s := 'R10' else
 if s = 'TEXT' then s := 'T' else // String Size - autodetect
 if s = 'WIDE' then s := 'W' else // String Size - autodetect
 if s = 'ALL' then s := 'A';      // Поиск значений разных типов
 result := s;
end;

function        ConvType2;
begin
 result := true;
 if (s = 'BYTE') then s := '1' else
 if (s = 'WORD') then s := '2' else
 if (s = 'DWORD') then s := '4' else
 if (s = 'SINGLE') then s := 'R4' else
 if (s = 'REAL') then s := 'R6' else
 if (s = 'DOUBLE') then s := 'R8' else
 if (s = 'EXTENDED') then s := 'R10' else
 if (s = 'TEXT') then s := 'T0' else
 if (s = 'WIDE') then s := 'W0' else
 if (s = 'HEX') then  else
 result := false;
end;

function        Round4K;
begin
 result := (d shr 12) shl 12;           // Отрезаем биты
 if (d > result) then inc (result, 4096);    // Добавляем 4К
end; // Round4k

function        _T;
var n, count : dword;

begin
 result := '';
 count := StrLen (p);
 for n := 1 to count do result := result + p [n - 1];
end;




function S2I;
var e : integer;
begin
 Val (s, result, e);
 if e <> 0 then result := 0;
end; // S2i



function  decr (var x : cardinal) : cardinal;
begin
 dec (x);
 result := x;
end;

function  decr (var x, d : cardinal) : cardinal;
begin
 dec (x, d);
 result := x;
end;

function  FloatMask;
const
     data : array [1..4, 0..1] of byte =
      ((8,24), (8,24), (11, 21), (15, 16));

var o : byte;
    fill, mask : dword;
begin
 fill := $FFFFFFFF;
 o   := data [vs shr 1 - 1, 1];
 mask := (fill and qm) shl o; // Характеристика числа
 mask := mask or (mm and (fill shr (32 - qm))); // Мантисса числа
 mask := mask or $80000000; // Знак числа
 result := mask;
end; // FloatMask

function  str2f;
var n : byte;
    e : integer;
begin
 for n := 1 to Length (s) do
  if s [n] = ',' then s [n] := '.';
 val (s, result, e);
 if e <> 0 then result := 0.0;
end;

function  FloatV;
var
   v4 : single;
   v6 : packed record
   case byte of
    0: (r: real48);
    1: (d:dword;w:word);
   end;
   v8 : packed record
   case byte of
    0: (r:double);
    1: (d1:dword; d2:dword);
   end;

  v10 : packed record
   case byte of
    0: (r:extended);
    1: (w:word; d1:dword;d2:dword);
   end;

   dw : dword;
begin
 dw := 0;
 result := 0;
 try
  v4 := ex;
  v6.r := ex;
  v8.r := ex;
  v10.r := ex;
  case s of
   4 : dw := pdword(@v4)^;
   6 : dw := v6.d;
   8 : dw := v8.d2;
  10 : dw := v10.d2;
  end;
 except
  exit;  // Исключительно в целях перехвата
 end;  
 if (dw > 0) then  result := dw;
end;

procedure Float2V;
begin
 v1 := FloatV (e1, s);          // Собственно число
 v2 := FloatV (e2 + 0.0001, s); // Дополнение
 if (v2 < v1) or (v2 - v1 > 1000) then
  begin
   v2 := v1;    // поправиться...
  end; 
end;

procedure  Str2type;
var n : byte;
    strSz : string;
    e : Integer;
begin
 strSz := '';
 for n := 1 to Length (s) do
 case s [n] of
  'A' : vtype := st_all;
  'I' : vtype := st_int;
  'T' : vtype := st_text;
  'W' : vtype := st_wide; // Это не WORD, а PWideChar
  'R' : vtype := st_real;
  '0','1'..'9' : strSz := strSz + s [n];
  'E' : vsize := 10;
 end;
 if strSz <> '' then val (strsz, vsize, e);
end;

function CalcMask;
begin
 if sz > 8 then sz := 8;
 result := (not Int64 (0)) shr ((8 - sz) * 8);
end;

procedure WriteMsg (const x, y : dword;const s : string);
var p: WSTRZ256;
begin
 StrPCopy (p, s);
 if defdc <> 0 then
   TextOut (defdc, x, y, p, StrLen (p));
end;


function Min;
begin
 if a < b then result := a else result := b;
end; // Min

function Max;
begin
 if a > b then result := a else result := b;
end; // Max



function Byte2Hex;
const hash : string = ('0123456789ABCDEF');

begin
 Byte2Hex := hash [b shr 4 + 1] + hash [b and 15 + 1];
end;

function  Word2Hex;
begin
 result := Byte2Hex (Hi (w)) + Byte2Hex (Lo (w));
end;

function  Dword2Hex;
begin
 result := Word2Hex (HiWord (d)) + Word2Hex (LoWord (d));
end;

var prvtime: Int64 = 0;
procedure ODS;
var ws: String;
    tid: DWORD;
    dta: Int64;
begin
 if IsReleaseBuild or not DebuggerPresent then exit;
 tid := GetCurrentThreadID;
 dta := GetTickCount - prvtime; // получение дельты времени
 prvtime := GetTickCount;
 ws := Format ('  • TID=$%X [%d] • %s •   '#13#10,
                [tid, dta, smsg]);
 OutputDebugString (PChar (ws));
end; // ODS

function bound;
begin
with rng do result := (min <= v) and (v <= max);
end;

var  p: WSTRZ256;

initialization
 DebuggerPresent := IsDebuggerPresent;
 winver := GetVersion and $FF;
 tempDir := GetEnvironmentVariable ('TEMP');
 if (tempDir = '') then
  begin
   GetWindowsDirectory (p, 255);
   tempDir := p + '\Temp';
  end;
 LoadModuleVersion;
end.
