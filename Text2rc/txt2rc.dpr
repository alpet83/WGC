program txt2rc;

{$APPTYPE CONSOLE}

uses Windows, SysUtils;

procedure       ErrExit (const msg: string);
begin
 WriteLn (msg);
 Halt (0);
end; // ErrExit;

var
   fs, fd: TextFile;
   sn, sd: string;
   id: dword;
   ss: string;
begin
 sn := ParamStr (1);
 sd := ParamStr (2);
 if (sn = '') or (sd = '') then exit;
 if (not FileExists (sn)) then ErrExit ('File ' + sn + ' not found.');
 AssignFile (fs, sn);
 AssignFile (fd, sd);
 {$I-}
 Reset (fs);
 if IOresult <> 0 then ErrExit ('Cannot open file ' + sn);
 Rewrite (fd);
 if IOresult <> 0 then ErrExit ('Cannot create flie ' + sd);
 {$I+}
 id := 13000;
 WriteLn (fd, 'STRINGTABLE LOADONCALL DISCARDABLE');
 WriteLn (fd, 'BEGIN');
 repeat
  ReadLn (fs, ss);
  if (ss = '') then ss := '   ';
  WriteLn (fd, IntToStr (id) + ', "' + ss + '"');
  inc (id);
 until Eof (fs);
 WriteLn (fd, 'END');
 Close (fs);
 Close (fd);
end.
