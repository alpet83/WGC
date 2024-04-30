program eat;

uses
  Windows,
  SysUtils,
  CommDlg,
  rects in '..\Common\rects.pas',
  engine in 'engine.pas',
  ChSource in '..\ChSource.pas',
  KbdAPI in '..\Common\KbdAPI.pas',
  KbdDefs in '..\Common\KbdDefs.pas',
  ChPointers in '..\Common\ChPointers.pas',
  PSLists in '..\Common\PSLists.pas',
  SimpleArray in '..\Common\SimpleArray.pas',
  ConThread in '..\Console\ConThread.pas',
  ChStrings in '..\Common\ChStrings.pas',
  misk in '..\Misk.pas';

procedure   ZMem (var obj; sz: dword);
begin
 fillchar (obj, sz, 0);
end; // ZMem


{$R *.res}
{$R ..\Res\visual.res}

var s: string;
    fn: array [0..256] of char;
    ofn: tagOFN;

begin
 s := ParamStr (1);
 InitComCtrls;
 if s = '' then
  begin
   ZMem (ofn, sizeof (ofn)); // fill zerro
   ofn.lStructSize := sizeof (ofn);
   ofn.hInstance := hInstance;
   ofn.lpstrFilter := 'Текстовое описание трейнера'#0'*.ttd'#0#0;
   ofn.lpstrInitialDir := PChar (GetCurrentDir);
   ofn.lpstrTitle := 'Открыть трейнер';
   ofn.Flags := OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST;
   ofn.lpstrFile := fn;
   ofn.nMaxFile := 256;
   GetOpenFileName (ofn);
   s := fn;
  end;
 if s <> '' then StartEngine (s);
end.
