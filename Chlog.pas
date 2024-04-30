unit ChLog;

interface
uses windows, ChTypes;
{$WARN IMPLICIT_STRING_CAST OFF}

{ Модуль по обработке ошибок }
var
   logFileName: String = '_application.log';
   bConsoleCreated: Boolean = FALSE;
   
procedure       LogStr (const s: String; addeol: Boolean = True;
                        bClearLog: Boolean = FALSE);
procedure       LogStrEx (const s: String; textAttr: BYTE);
procedure       TestLogError (const msg: String = '');
function        GetLastErrorStr (const dscr: string = ''): string;



implementation
uses misk, ConThread;

var curAttr: BYTE = 7;
    prvAttr: BYTE = 0;
    sLog: String = '';

procedure       LogStrEx (const s: String; textAttr: BYTE);
begin
 curAttr := textAttr;
 LogStr (s);
end; // LogStrEx   

function        GetLastErrorStr;
begin
 result := '';
 if (dscr <> '') then result := result + dscr + ' ';
 result := result + err2str (GetLastError);
end; // GetLastError;

const eol: array [0..1] of AnsiChar = #13#10;

var _prvtime: Int64 = 0;
        path: WFILE_PATH;

procedure  LogToFile (const s: String; addEol, bClearLog: Boolean);
var spath: String;
    disp: DWORD;
    hFile: THandle;
    w: DWORD;
    
begin
 spath := ExtractFilePath (path);
 if bClearLog then
  begin
   DeleteFile (PChar (spath + logFileName));
   disp := CREATE_ALWAYS;
  end else disp := OPEN_ALWAYS;

 hFile := CreateFile (PChar (path + logFileName),
          GENERIC_WRITE, FILE_SHARE_READ, nil, disp, 0, 0);
 if not bClearLog then
         SetFilePointer (hFile, 0, nil, FILE_END);

 if hFile = INVALID_HANDLE_VALUE then
  begin
   OutputDebugString (PChar ('Неудалось открыть файл журнала ошибок: ' + logFileName));
   exit;
  end;
 try
  ODS (s);
  WriteFile (hFile, PAnsiChar ( AnsiString(s) )^, Length (s), w, nil);
  if addeol then WriteFile (hFile, eol, 2, w, nil);
 finally
  CloseHandle (hFile);
 end;

end;

procedure  LogStr;
var
    oems: array [0..1023] of AnsiChar;
    ss: String;
    dta: Int64;
begin
 // if s <> '' then exit;
 dta := GetTickCount - _prvtime; // получение дельты времени
 _prvtime := GetTickCount;
 Str (dta, ss);
 ss := '(' + ss + ')';
 while Length (ss) < 10 do ss := ' ' + ss;
 ss := #13 + GetStrTime + ss + #9;
 ss := ss + s;
 LogToFile (ss, addEol, bClearLog);
 if bConsoleCreated then
 begin
  AnsiToOem ( PAnsiChar ( AnsiString(ss) ), oems);
  WriteConStr (oems, CurAttr);
  prvAttr := curAttr;
 end;
end; // LogStr

procedure TestLogError;
var err: DWORD;
begin
 err := GetLastError;
 if err = 0 then exit;
 LogStr ('#ERROR captured ' + err2str (err));
 // asm int 3 end;
end;

initialization
 GetModuleFileName (0, path, 260);
end.
