unit ChCodes;
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ChTypes, Misk, KbdAPI, HotKeyDlg, KbdDefs;

const
   russian = '00000419';
   english = '00000409';
   hkScanStart = 'ScanStart';
   hkPrintScrn = 'PrintScreen';
   hkSieveStart = 'SieveStart';
   hkSendChCode = 'SendCheatCode';
   hkPrintCodes = 'PrintCheatCodes';
   hkRunProcess = 'RunProcess';
       hkToGame = 'PopupGame';
       hkFreeze = 'FreezeGame';
     hkUnfreeze = 'UnFreezeGame';
     hkPopupApp = 'PopupApp';
    hkBreakScan = 'BreakScan';
     hkShowCons = 'ShowConsole';
      hkNextTab = 'NextTab';
      hkPrevTab = 'PrevTab'; 

    hkList : array [1..9] of string =
     (hkScanStart, hkSieveStart, hkBreakScan, hkSendChCode, hkFreeze,
        hkUnfreeze, hkPopupApp, hkToGame, hkShowCons);

type
  Tfcodes = class(TForm)
    CodesMemo: TMemo;
    btnHide: TButton;
    edNum: TEdit;
    btnLoad: TButton;
    btnSave: TButton;
    opendlg: TOpenDialog;
    savedlg: TSaveDialog;
    lTest: TLabel;
    cbAutoenter: TCheckBox;
    tbDelay: TTrackBar;
    lbDelay: TLabel;
    btnHelp: TButton;
    procedure btnHideClick(Sender: TObject);
    procedure edNumKeyPress(Sender: TObject; var Key: Char);
    procedure btnLoadClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure tbDelayChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
    procedure SendCheatCode (i : byte);
    procedure SendCheatAuto;
    function  SendCheatByHotKey: boolean;
  end;



var
   fcodes: Tfcodes;
   gLastKey: TKeyRec;
   hotkeys: array [0..20] of THotKeyData;
   hkcount: dword = 0;
   layouts: array [1..2] of THandle;

// ��������� �������
procedure        AddHotKey (const act: string;key: word;flags: byte);
function         HkIndex (const act: string) : dword;
function         HotKeyPress (const hkact: string): boolean;
function         IsLastPressed (vkey, flags: word): boolean;
function         StateCvt (const ss: TShiftState): word;
function         StrKey (vkey, flags: word): string;
procedure        StoreHotKey (hk: TObject; key, flags: word);


implementation
uses ChHelp, ChConst;

{$R *.dfm}
var
    sdelay: dword;

function         StateCvt;
asm
 and al, 7Fh
end;

procedure        StoreHotKey;
begin
 if Assigned (hk) and (hk is THotKeyData) then
   begin
    THotKeyData (hk).key := key;
    THotKeyData (hk).flags := flags;
   end;
end; // StoreHotKey


procedure       AddHotKey;
begin
 if (hkcount < high (hotkeys)) then Inc (hkcount);
 hotkeys [hkcount] := THotKeyData.Create(act, key, flags); // ��������� �������
end;

function         StrKey;
var skey: string;
begin
 result := '';
 if (flags and KF_CTRL <> 0)  then result := result + 'Ctrl + ';
 if (flags and KF_ALT <> 0)   then result := result + 'Alt + ';
 if (flags and KF_SHIFT <> 0) then result := result + 'Shift + ';
 if (flags and KF_WIN <> 0)   then result := result + 'Win + ';
 if (flags and KF_APPS <> 0)  then result := result + 'Apps + ';
 skey := '';
 case vkey of
  VK_NUMPAD0..VK_NUMPAD9: skey := 'Numpad ' + IntToStr (vkey - VK_NUMPAD0); // Fx �������
               VK_ESCAPE: skey := 'Esc';
   VK_SPACE, ord ('='),
   ord ('0')..ord('9'),
   ord('A')..ord ('Z'): skey := chr (vkey and $FF);
           VK_F1..VK_F24: skey := 'F' + IntToStr (vkey - VK_F1 + 1); // Fx �������

              VK_NUMLOCK: skey := 'NumLock';
               VK_SCROLL: skey := 'ScrollLock';
           VK_PROCESSKEY: skey := 'ProcessKey';
               VK_RETURN: skey := 'ENTER';
                 VK_ATTN: skey := 'Attn';
                 VK_PLAY: skey := 'Play';
                 VK_ZOOM: skey := 'Zoom';
                  VK_ADD: skey := 'Numpad +';
             VK_SUBTRACT: skey := 'Numpad -';
              VK_DECIMAL: skey := 'Numpad ?';
             VK_MULTIPLY: skey := 'Numpad *';
               VK_DIVIDE: skey := 'Numpad /';
               VK_INSERT: skey := 'Ins';
               VK_DELETE: skey := 'Del';
                VK_PRIOR: skey := 'PgUp';
                 VK_NEXT: skey := 'PgDn';
                  VK_END: skey := 'End';
                 VK_HOME: skey := 'Home';
                 VK_LEFT: skey := 'Left';
                   VK_UP: skey := 'Up';
                VK_RIGHT: skey := 'Right';
                 VK_DOWN: skey := 'Down';
                 VK_BACK: skey := 'Backspace';
                VK_PAUSE: skey := 'Pause/Break';
 end;
 result := result + skey;
end; // StrKey

function         hkIndex;
var n: dword;
begin
 result := 0;
 for n := 1 to hkcount do
  if (hotkeys [n].action = act) then
   begin
    result := n;     // ����������� �������
    exit;
   end;
end; // hkIndex

function         HotKeyPress;
var n: dword;
begin
 result := false;
 n := HkIndex (hkact);
 if (n > 0) then
 with hotkeys [n] do
 result := IsLastPressed (key, flags); // ������ ��� �������
 if result then gLastKey.pack := 0; // clear this selection
end; // KeyPress

procedure Tfcodes.btnHideClick(Sender: TObject);
begin
 hide;
end;

var
   extkey: dword = 0;
const
  extkeys: set of byte =
  [VK_LWIN, VK_RWIN, VK_APPS, VK_F1..VK_F24, VK_NUMLOCK, VK_SCROLL] +
  [$21..$2C, $F6..$FE];

  HexChars: set of WideChar = ['0'..'9', 'A'..'F'];

function  IsExtKey (const key: byte): boolean;
begin
 result := (key in extkeys);
end; // Extended key

function  IsLastPressed (vkey, flags: word): boolean;
begin
 result := (vkey = gLastKey.key) and
               (flags and $FFF = gLastKey.flags and $FFF);
end;

procedure SimKeyUp(Key : byte);
begin
 keybd_event (Key, 0, KEYEVENTF_KEYUP or extkey, 0);
end;

procedure SimKeyDn (Key : byte);
begin
 keybd_event (Key, 0, extkey, 0);
 sleep (sdelay);
end;

procedure SimKeystroke (Key : byte; scan : DWORD);
begin
 keybd_event(Key, scan, extkey, 0);
 sleep (sdelay);
 keybd_event(Key, scan, KEYEVENTF_KEYUP or extkey, 0);
end;

function GetLayoutName : string;
var
   p : WSTRZ256;
begin
 GetKeyboardlayoutName (p);
 result := p;
end; // getLayoutName

function SwitchLayout (indx: dword;var hkl : THandle) : boolean;
const css: array [1..2] of dword =
        (DEFAULT_CHARSET, RUSSIAN_CHARSET);
var
   h: THandle;
   r: dword;
begin
 result := false;
 if (indx < 1) or (indx > 2) then exit;
 h := GetForegroundWindow ();
 hkl := layouts [indx];
 Sleep (1);
 ActivateKeyboardLayout (hkl, 0);
 SendMessageTimeOut (h, WM_INPUTLANGCHANGEREQUEST, 0, hkl,
                        SMTO_ABORTIFHUNG, 200, r);
 SendMessageTimeOut (h, WM_INPUTLANGCHANGEREQUEST, css [indx], hkl,
                        SMTO_ABORTIFHUNG, 200, r);
 Sleep (1);                       
 result := true; // ��������� �����
end;  // SwLayout

procedure SendKeys(s : string);
var
   l, i, e : integer;
   flag : bool;
   last, hx : string;
   w : word;
   ch : char;
   h : THandle;
begin
 // ������� �� ����� Caps Lock
 flag := not GetKeyState(VK_CAPITAL) and 1 = 0;
 // ���� ����, ���������, ����� ������ �� ���������
 if flag then SimKeystroke(VK_CAPITAL, 0);
 // ��������� ���������
 // layout := GetLayoutName;
 // SwitchLayout (1, h);
 i := 1;          // ������ ��������
 extkey := 0;

 repeat
  l := Length (s); // ����� ������
  if (i > l) then break; // ��������� ���������� �����

  if (i < Length (s)) and (s [i] = '\') then // �������� ������
    begin
     if (s [i + 1] = '\') then Delete (s, i, 1) else  // ������� ������ �����
     if (s [i + 1] = '0') then
        begin
         inc (i, 2);
         continue; // ������� ����
        end else
     if (s [i + 1] = 'b') then // �����
        begin
         SimKeystroke (VK_BACK, 0); // Backspace
         inc (i, 2);
         continue;
        end else
     if (s [i + 1] = 't') then
        begin
         SimKeystroke (VK_TAB, 0); // ���������
         inc (i, 2);
         continue;
        end else
     if (s [i + 1] = 'r') then
        begin
         SwitchLayout (2, h);
         last := russian;
         inc (i, 2);
         continue;
        end else
     if (s [i + 1] = 'e') then
        begin
         SwitchLayout (1, h);
         last := english;
         inc (i, 2);
         continue;
        end else
     if (s [i + 1] = 'x') then
      begin
       hx := '$';
       i := i + 2;
       // ��������� ������������ ���� �������, � ����������������� �������
       while ((i <= l) and
              (Upcase (s [i]) in HexChars) and
              (length (hx) <= 4) // �� ����� 3 ���. ��������
               ) do
        begin
         hx := hx + s [i]; // ���������� �������
         inc (i);
        end;
       if (length (hx) > 2) then
        begin
         val (hx, w, e);
         if (w = 0) then continue;
         extkey := 0;
         if IsExtKey (LoByte (w)) then extkey := KEYEVENTF_EXTENDEDKEY;
         if ((e = 0) and (w and $300 = $300)) then SimKeystroke (LoByte (w), 0) else
         if ((e = 0) and (w and $100 <> 0)) then SimKeyDn (LoByte (w)) else
         if ((e = 0) and (w and $200 <> 0)) then SimKeyUp (LoByte (w));
         if (w and $200 <> 0) then extkey := 0; 
        end;
       if (i >= Length (s)) then break;          
       continue;
      end; // �������� ������� ��������� �������
    end;
   ch := s [i];
   if (byte (ch) < $80) then
    begin
     if last <> english then
       begin
        SwitchLayout (1, h); // ������������� �� ���������� ���������
        last := english;
       end;
     w := VkKeyScanEx (ch, h);
    end
   else
    begin
     if last <> russian then
       begin
        SwitchLayout (2, h); // ������������� �� ������� ���������
        last := russian;
       end;
     w := VkKeyScanEx (ch, h);
    end;
    {If there is not an error in the key translation}

    if ((HiByte(w) <> $FF) and (LoByte(w) <> $FF)) then
      begin
       {If the key requires the shift key down - hold it down}
       if HiByte(w) and 1 = 1 then
       SimKeyDn (VK_SHIFT);
       // �������� ����� - ������� ����� ������!
       SimKeystroke(LoByte(w), 0);
       if fcodes.edNum.Focused then
          Application.ProcessMessages; // ��������� ���������
       {If the key required the shift key down - release it}
       if HiByte(w) and 1=1 then SimKeyUp(VK_SHIFT);
      end;
  inc (i);
  l := Length (s)
 until i > l;
 SwitchLayout (1, h);
 {if the caps lock key was on at start, turn it back on}
 if flag then SimKeystroke(VK_CAPITAL, 0);   
end;

procedure Tfcodes.SendCheatAuto;
{ ����� ���� � �������� ����� }
var
   s : string;
   hwnd : THandle;
   p : WSTRZ256;
   i, e : Integer;   
begin
 hwnd := GetFocus;
 // GetClassName (hwnd, p, 256);
 GetWindowText (hwnd, p, 256);
 s := p;
 val (s, i, e);
 if e = 0 then SendCheatCode (i);
end;


function Tfcodes.SendCheatByHotKey;
var n: byte;
begin
 result := false;
 // ������������ ������� �������
 for n := 0 to 9 do
 begin
  if (IsPressed ($30 + n)) then
   begin
    if n = 0 then SendCheatCode (10)  // ������ �����������
              else SendCheatCode (n);
    result := true;             
    break;             // ����� �� �����
   end;
 end; // for control
end; // SendCheatByHotKey

procedure Tfcodes.SendCheatCode (i : byte);
var
   s : string;
   hwnd : THandle;
   p : WSTRZ256;

begin
 hwnd := GetFocus;
 GetClassName (hwnd, p, 256);
 s := p;
 s := UpperCase (s);
 if Pos ('EDIT', s) > 0 then SetWindowText (hwnd, '') else SimKeystroke (VK_BACK, 0);
 s := codesMemo.Lines [i - 1];
 if s = '' then exit;
 i := pos ('::', s);
 if (i > 0) then s := copy (s, 1, i - 1);
 for i := 1 to length (s) - 1 do
  if (s [i] ='\') and (s [i + 1] = 'n') then
   begin
    s [i] := #13;
    s [i + 1] := #10;
   end;
 if cbAutoEnter.Checked then SimKeystroke (VK_RETURN, 0); // �������� ENTER �� ���� � messages
 SendKeys (s);                                            // ���� ���-����
 if cbAutoEnter.Checked then SimKeystroke (VK_RETURN, 0); // �������� ENTER
end; 

procedure Tfcodes.edNumKeyPress(Sender: TObject; var Key: Char);
var i, e : integer;
begin
 if key <> #13 then exit;
 val (edNum.text, i, e);
 if  (e > 0) or (i <= 0) or
     (i > codesMemo.Lines.Count) then exit;
 SendCheatCode (i);
end;

procedure Tfcodes.btnLoadClick(Sender: TObject);
begin
 if opendlg.Execute then
    CodesMemo.Lines.LoadFromFile (opendlg.FileName);
end;

procedure Tfcodes.btnSaveClick(Sender: TObject);
begin
 if savedlg.execute then
    CodesMemo.Lines.SaveToFile(savedlg.FileName);
end;


procedure Tfcodes.tbDelayChange(Sender: TObject);
begin
 sdelay := tbDelay.Position * 10;
 tbDelay.Hint := '�������� ' + IntToStr (sdelay) + ' ��';
end; // tbDelay


procedure Tfcodes.FormCreate(Sender: TObject);
begin
 sdelay := 0;
end;

procedure Tfcodes.btnHelpClick(Sender: TObject);
var i: Integer;
begin
 i := SearchByHead ('���-����');
 if (i > 0) then
  begin
   helpform.Show;
   helpform.LoadContent(i);
  end;
end;

initialization
 hotkeys [0] := THotKeyData.Create('Bug!!!', 0, 0);
 AddHotKey (hkSendChCode, VK_F12, KF_WIN); // ����� �������� ���-����
 AddHotKey (hkScanStart, VK_F11, KF_CTRL);
 AddHotKey (hkSieveStart, VK_F12, KF_CTRL);
 AddHotKey (hkBreakScan, VK_PAUSE, KF_CTRL); // ���������� ������/������
 AddHotKey (hkPrintCodes, VK_F11, KF_WIN); // ���������� ���-�����
 AddHotKey (hkPrintScrn, VK_SNAPSHOT, KF_WIN); // ����������� ������ � ����
 AddHotKey (hkFreeze, VK_SUBTRACT, KF_CTRL);         // ��������� ����
 AddHotKey (hkUnFreeze, VK_ADD, KF_CTRL); // ���������� ����
 AddHotKey (hkPopupApp, VK_PRIOR, KF_CTRL or KF_ALT); // �������� wgc
 AddHotKey (hkToGame, VK_NEXT, KF_CTRL); // �������� ����
 AddHotKey (hkRunProcess, VK_F9, KF_CTRL); // ������� ������� ������������� ��������
 AddHotKey (hkShowCons, VK_F10, KF_ALT); // ����� ������� !
 AddHotKey (hkNextTab, VK_NEXT, KF_CTRL); // ������������ ������� ������
 AddHotKey (hkPrevTab, VK_PRIOR, KF_CTRL); // ������������ ������� �����
 layouts [1] := LoadKeyboardLayout (english, 0);
 layouts [2] := LoadKeyboardLayout (russian, 0);
 // ods (format ('sizeof THotKeyData = %d', [sizeof (THotKeyData.InstanceSize)]));
end.
