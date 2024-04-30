program Installer;
uses
  Windows,
  SysUtils,
  CommCtrl,
  Messages,
  ShlObj,
  ShellApi,
  ActiveX,
  ChConst in '..\chconst.pas',
  ChTypes in '..\chtypes.pas',
  Misk in '..\misk.pas';

resourcestring
Caption = 'Установка программы WGC';

{$R instdlg.res}
{$R ..\wgc.res}

const
     IID_IPersistFile: TGUID = (
            D1:$0000010B;D2:$0000;D3:$0000;D4:($C0,$00,$00,$00,$00,$00,$00,$46));


const
     readme = 'readme.txt';
var
      finst: boolean = false;    
       hdlg: HWND;
       flag: boolean;
   filepath: string;
    dsktopd: string; 
       hmsg: THandle;



procedure  AddMsg (const s: string);
begin
 if (hmsg <> 0) then
    SendMessage (hmsg, LB_ADDSTRING, 0, LongInt (PChar (s)));
end; // pp;

procedure  ClearMsgs;
begin
 if (hmsg <> 0) then
    SendMessage (hmsg, LB_RESETCONTENT, 0, 0);
end; // ClearMsgs

procedure  ProcessMessage;
var
   msg: tagMsg;
begin
 if (PeekMessage (msg, 0, 0, 0, PM_REMOVE)) then else exit;
 if (not IsWindow (hdlg)) or (not IsDialogMessage (hdlg, msg)) then
  begin
   TranslateMessage (msg);
   DispatchMessage (msg);
  end;
end; // ProcessMessage


procedure  ExitApp;
begin
 flag := false;
 PostQuitMessage (0);
end; // ExitApp

procedure  CreateLink;
var
   ppf: IPersistFile;
   psl: IShellLink;
   hres: HRESULT;
   pc: array [0..512] of char;
   wsz: array [0..512] of widechar;
begin
 FillChar (pc, sizeof (pc), 0);
 FillChar (wsz, sizeof (wsz), 0);
 hres := CoInitialize (nil);
 if (hres = S_OK) or (hres = S_FALSE) then else exit; 
 hres := CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER,
                            IID_IShellLinkA, psl);
 if SUCCEEDED (hres) then
  begin
   StrPCopy (pc, filepath);
   psl.SetWorkingDirectory(pc);
   StrPCopy (pc, filepath + 'wgc.exe');
   psl.SetPath (pc);
   psl.SetShowCmd (SW_SHOWNORMAL);
   psl.SetHotkey(byte ('~') or (HOTKEYF_ALT or HOTKEYF_CONTROL) shl 8);
   psl.SetDescription('Winner Game Cheater - программа для взлома игр');
   hres := psl.QueryInterface(IID_IPersistFile, ppf);
   if not SUCCEEDED (hres) then exit;
   StrPCopy (pc, dsktopd);
   StrCat (pc, '\W.G.C.lnk');
   MultiByteToWideChar (CP_ACP, MB_PRECOMPOSED, pc, StrLen (pc), wsz, 512);
   hres := ppf.Save (wsz, true);
   if (hres <> E_FAIL) then
       AddMsg ('Создан ярлык на рабочем столе'); // Аблом 
  end;
end; // CreateLink


procedure  AddSlash (var
 s: string);
begin
 if (s = '') then exit;
 if (s [length (s)] <> '\') then s := s + '\';
end; // AddSlash

function GetCheck (h: HWND): boolean;
var r: dword;
begin
 result := false;
 if (h = 0) then exit;
 SendMessageTimeOut (h, BM_GETCHECK, 0, 0, SMTO_ABORTIFHUNG, 300, r);
 result := (r = BST_CHECKED);
end; // GetCheck

procedure SetCheck (h: HWND; chk: Boolean);
const list: array [false..true] of Integer = (BST_UNCHECKED, BST_CHECKED);
var r: dword;
begin
 if (h = 0) then exit;
 SendMessageTimeOut (h, BM_SETCHECK, list [chk], 0, SMTO_ABORTIFHUNG, 300, r);
end; // SetCheck


var sysdir: string;

function   CreatePath (const s: string): boolean;
var l, p: dword;
    ss: string;
    pc: array [0..MAX_PATH] of char;
begin
 result := true;
 if DirectoryExists (s) then exit;
 result := false;
 l := Length (s);
 p := pos ('\', s);
 repeat
  ss := copy (s, 1, p);
  inc (p);
  while (p < l) and (s [p] <> '\') do inc (p);
  if (not DirectoryExists (ss)) then
    if not CreateDirectory (pc,nil) then exit;
 until (p >= l);
 result := true;
end; // CreatePath


const IDD_INSTDLG       = 1;
const IDC_LABEL1        = 120;
const IDC_EDPATH        = 121;
const IDC_BNBROWSE1     = 122;
const IDC_EDSYSDIR      = 131;
const IDC_BNBROWSE2     = 132;

const IDC_CBSHOWREADME = 101;
const IDC_CBSHCUT = 102; // создать иaрлык
const IDC_LBMSGS = 104;  // окно сообщений
const IDC_BNDEL = 105;


procedure     BrowseFolder(ident: Integer);
var
   bi: TBrowseInfo;
   dst: array [0..MAX_PATH] of char;
   rslt: PItemIDlist;
begin
 FillChar (bi, sizeof (bi), 0); // обнулить
 FillChar (dst, sizeof (dst), 0);
 bi.hwndOwner := hdlg;
 bi.pszDisplayName := dst;
 bi.lpszTitle := 'Выбор папки для установки';
 bi.ulFlags := BIF_EDITBOX or BIF_RETURNONLYFSDIRS;
 rslt := SHBrowseForFolder (bi);
 if (rslt <> nil) then
  begin
   SHGetPathFromIDList (rslt, dst);
   if 1 = ident then SetDlgItemText (hdlg, IDC_EDPATH, dst);
   if 2 = ident then SetDlgItemText (hdlg, IDC_EDSYSDIR, dst);
  end;
end; // BrowseFolder

function GetCaption: string;
begin
 result := Caption + ' ' + GetVersionStr;
end;

procedure     Initialize;
begin
 // setting the system directory
 if hDlg = 0 then exit;
 SetDlgItemText (hdlg, IDC_EDSYSDIR, PChar (sysdir));
 // setting caption
 SendMessage (hDlg,WM_SETTEXT, 0, Integer(PChar (GetCaption)));
 InvalidateRect (hDlg, nil, true);
end; // Init

procedure      OnComplete;
begin
 SetDlgItemText (hdlg, IDCANCEL, 'Выход');
end;

function     SaveRes (const id: dword; const filename: string): boolean;
var h,  hinfo: THandle;
    pc: array [0..31] of char;
    p: pointer;
    sz, wsz: dword;
    f: file;
begin
 result := false;
 StrPCopy (pc, '#' + IntToStr (id));
 hinfo := FindResource (HINSTANCE, pc, RT_RCDATA );
 if (hinfo = 0) then
  begin
   AddMsg ('Ненайден ресурс #' + IntToStr (id));
   exit;
  end;
 sz := SizeOfResource (HINSTANCE, hinfo); // Получить размер
 h := LoadResource (HINSTANCE, hinfo);   // Получить дескриптор
 if (h = 0) or (sz = 0) then exit;
 p := LockResource (h);
 Assign (f, filename);
 {$I-}
 ReWrite (f, 1);
 if IOresult <> 0 then
  begin
   AddMsg ('Проблема: Неудалось создать ' + filename);
   exit; // Ошибка
  end;
 BlockWrite (f, p^, sz, wsz);
 Close (f);
 {$I+}
 result := (sz = wsz);
 if (result) then
  AddMsg ('Записан файл ' + filename +
          ' = ' + IntToStr (wsz shr 10) + ' Кбайт');
end; // SaveRes

procedure     Install;
var path: array [0..MAX_PATH] of char;
    h: HWND;
begin
 ClearMsgs;
 AddMsg ('Начата устанвка');
 GetDlgItemText (hdlg, IDC_EDSYSDIR, path, MAX_PATH);
 sysdir := path; // set common files directory
 AddSlash (sysdir);
 GetDlgItemText (hdlg, IDC_EDPATH, path, MAX_PATH);

 if not ForceDirectories (path) then
  begin
   AddMsg ('Проблема: Неудалось создать папку, попробуйте выбрать другую');
   exit;
  end;
 filepath := path;
 AddSlash (filepath);
 SaveRes (1200, filepath + 'wgc.exe');
 SaveRes (1202, filepath + 'wgceng.txt');
 SaveRes (1204, filepath + 'wgchost.exe');
 SaveRes (1201, sysdir + 'chdip.dll');
 SaveRes (1203, sysdir + 'wconapi.dll');
 h := GetDlgItem (hdlg, IDC_CBSHCUT);
 if (h = 0) then ExitApp;
 if GetCheck (h) then CreateLink;
 h := GetDlgItem (hdlg, IDC_CBSHOWREADME);
 if (h = 0) then ExitApp;
 if GetCheck (h) and FileExists (readme) then
   ShellExecute (0, 'open', readme, '', '.\', SW_SHOWDEFAULT);
 AddMsg ('Все операции завершены');
 EnableWindow (GetDlgItem (hdlg, IDOK), false);
 EnableWindow (GetDlgItem (hdlg, IDC_BNDEL), true);
 finst := true;
 OnComplete; 
end; // Install

procedure     DelFile (const fname: string);
begin
 if (FileExists (fname)) then else exit;
 if (DeleteFile (fname)) then
   AddMsg ('Удален файл ' + fname)
 else
   AddMsg ('Не удалсь удалить Файл ' + fname );
end; // AddMsg

procedure     Uninstall;
var path: array [0..512] of char;
begin
 ClearMsgs;
 GetWindowText (GetDlgItem (hdlg, IDC_EDPATH),
                        path, MAX_PATH); // Взять текст
 filepath := path;
 AddSlash (filepath);
 if (MessageBox (hdlg, 'Удалить программу с этого компьютера?',
                        'Потверждение',
                MB_ICONQUESTION or MB_YESNO) = ID_NO)
                                then exit;
 if (DirectoryExists (filepath)) then
  begin
   DelFile (filepath + 'wgc.exe');
   DelFile (filepath + 'wgchost.exe');
   DelFile (filepath + 'wgc.ini');
   DelFile (filepath + 'wgceng.txt');
  end; 
 DelFile (sysdir + 'chdip.dll');
 DelFile (sysdir + 'wconapi.dll');
 DelFile (dsktopd + '\W.G.C.lnk');
 EnableWindow (GetDlgItem (hdlg, IDOK), true);
 EnableWindow (GetDlgItem (hdlg, IDC_BNDEL), false);
 finst := true;
 OnComplete;
end; // Uninstall

procedure     OnCommand (const wp, lp: DWORD);
var
   id: word;
begin
 id := LoWord (wp);
 case id of
         0: exit;               // не проверять дальше
      IDOK: Install;
 IDC_BNDEL: Uninstall;
  IDCANCEL: if finst or
        ( MessageBox (hdlg,
                'Установка не завершена'#13#10 +
                        'Вы действительно хотите прекратить установку?'
                        ,'Потверждение',
         MB_ICONQUESTION or MB_YESNO ) = ID_YES) then  ExitApp;
  IDC_BNBROWSE1: BrowseFolder (1);
  IDC_BNBROWSE2: BrowseFolder (2);
 end;
end;
// var hFont: dword = 0; // font of dialog
function      DlgFunc (h: HWND;msg: DWORD; wp: WPARAM; lp: LPARAM): DWORD; stdcall;
begin
 result := 0;
  case msg of
   WM_INITDIALOG, WM_CREATE:
    begin
     hDlg := h;
     result := 1;
     Initialize;
    end;
   {WM_GETTEXT, WM_GETTEXTLENGTH:
   if h = hDlg then
    begin
     StrPCopy (p, GetCaption);
     result := StrLen (p);
     if (WM_GETTEXT = msg) and (result > 0) then StrCopy (PChar (lp), p);
    end; {}

   WM_COMMAND: OnCommand (wp, lp);
   WM_CLOSE, WM_QUIT: DestroyWindow (hdlg);
   WM_DESTROY: flag := false;
   // else result := DefDlgProc (h, msg, wp, lp);
  end;
end; // DlgFunc


var
   buff: array [0..256] of char;
   hi: HICON;
begin
 flag := true;
 GetSystemDirectory (buff, 256);
 sysdir := buff;
 if sysdir = '' then sysdir := 'C:\Windows\System32';

 CreateDialog (HINSTANCE, MAKEINTRESOURCE (1), GetDesktopWindow, @dlgFunc);
 if not IsWindow (hdlg) then exit;
 hi := LoadIcon (HINSTANCE, MAKEINTRESOURCE (1));
 if hi <> 0 then SendMessage (hdlg, WM_SETICON, ICON_SMALL, hi);
 hmsg := GetDlgItem (hdlg, IDC_LBMSGS);

 SHGetSpecialFolderPath (0, buff, CSIDL_DESKTOPDIRECTORY, false);
 dsktopd := buff;
 AddSlash (sysdir);
 if not IsWindowVisible (hdlg) then
         ShowWindow (hdlg, SW_SHOWDEFAULT);

 while flag do // Пока окно не закрыто
  begin
   ProcessMessage; // Обработать сообщение
   sleep (10);
   flag := flag and IsWindow (hdlg);
  end;
end.