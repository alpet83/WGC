{$DEFINE WINDOWS}
library wwork;

uses
  Windows,
  strtools in '..\Common\strtools.pas';

type SmallStr2 = string [2];
     SmallStr4 = string [4];
     SmallStr8 = string [8];

function byteToHex (w: word): SmallStr2;
var b: array [0..1] of byte absolute w;
begin
 b [1] := b [0] shr 4;
 if (b [0] > 9) then inc (b [0], $11);
 if (b [1] > 9) then inc (b [1], $11);
 w := w + $3030;
 result := Char (b [1]) + Char (b [0]);
end;

function wordToHex (w: word): SmallStr4;
var b: array [0..1] of byte absolute w;
begin
 result := byteToHex (b [1]) + byteToHex (b [0]);
end;
function DwordToHex (d: dword): SmallStr8;
var w: array [0..1] of word absolute d;
begin
 result := WordToHex (w [1]) + WordToHex (w [0]);
end; // DwordToHex

function chrcnt (p: PWideChar; ch: WideChar): dword; stdcall;
var n: dword;
begin
 result := 0;
 n := 0;
 while (p [n] <> #0) do
  begin
   if p [n] = ch then inc (result);
   inc (n);
  end;
end;

procedure strtrunc (p: PWideChar; ch: WideChar); stdcall;
var n: dword;
begin
 n := 0;
 while p [n] <> #0 do Inc (n);
 if n = 0 then exit;
 dec (n);
 while (n > 0) and (p [n] = ch) do Dec (n);
 p [n + 1] := #0;
end;


procedure SendMouseEvent (hConInput: THandle; const cpos: _COORD; btnState, kState, flags: dword); stdcall;
var
  r: TInputRecord;
  num: dword;
begin
 r.EventType := _MOUSE_EVENT;
 with r.Event do
  begin
   MouseEvent.dwMousePosition.X := cpos.x;
   MouseEvent.dwMousePosition.Y := cpos.y;
   MouseEvent.dwButtonState := btnState;
   MouseEvent.dwControlKeyState := kState;
   MouseEvent.dwEventFlags := flags;
   WriteConsoleInputW (hConInput, r, 1, num);
  end;
end; // SendMouseEvent

procedure SendInputKey (hConInput: THandle; vkcode, state: dword; press: Boolean); stdcall;
var
  r: TInputRecord;
  ch: char;
  num: dword;
begin
 FillChar (r, sizeof (r), 0);
 r.EventType := KEY_EVENT;
 with r.event do
 begin
  KeyEvent.dwControlKeyState := state;
  if (state and LEFT_ALT_PRESSED = 0) and
     (vkcode <> VK_MENU) and (vkcode <> VK_CONTROL) then
   begin
    KeyEvent.AsciiChar := chr (MapVirtualKey (vkcode, 2));
    KeyEvent.UnicodeChar := WideChar (MapVirtualKeyW (vkcode, 2));
   end;
  ch := KeyEvent.AsciiChar;
  if (state and SHIFT_PRESSED = 0) and (ch <> #0) then
  with KeyEvent do
   begin
    if (KeyEvent.AsciiChar in ['A'..'Z']) then
     begin
      AsciiChar := Char ( Byte(AsciiChar) or $20);
      UnicodeChar := WideChar ( word(UnicodeChar) or $20);
     end
   end
  else
   begin
    ch := UpperKey (KeyEvent.AsciiChar);
    KeyEvent.AsciiChar := ch;
    KeyEvent.UnicodeChar := WideChar (ch);
   end;
  KeyEvent.wRepeatCount := 0;
  KeyEvent.wVirtualKeyCode := vkcode;
  KeyEvent.wVirtualScanCode := MapVirtualKeyW (vkcode, 0);
  KeyEvent.bKeyDown := press;
  WriteConsoleInputW (hConInput, r, 1, num);
 end;
end;

procedure SendInputChar(hConInput: THandle; ch: char; vkcode, state: dword); stdcall;
var
  r: TInputRecord;
  uch: char;
  num: dword;
  vk: word;
begin
 uch := UpCase(ch);
 r.EventType := KEY_EVENT;
 with r.event do
 begin
  if (ch = uch) then
     KeyEvent.dwControlKeyState := SHIFT_PRESSED
  else
     KeyEvent.dwControlKeyState := SHIFT_PRESSED;
  KeyEvent.dwControlKeyState := KeyEvent.dwControlKeyState or state;
  KeyEvent.AsciiChar := ch;
  KeyEvent.UnicodeChar := WideChar (ch);
  KeyEvent.wRepeatCount := 0;
  vk := ord (uch);
  if KeyEvent.dwControlKeyState and SHIFT_PRESSED <> 0 then
  ch := UpperKey (ch);
   case ch of
     #0: vk := vkcode;
     #13, #10: vk := VK_RETURN;
     #$30..#$39: vk := ord (ch);
     // ';', ':': vk := $BA;
     '+', '=': vk := $BB;
     ',': vk := $BC;
     '-', '_': vk := $BD;
     '.': vk := $BE;
     #$27, '"': vk := $DE;
    end;
   KeyEvent.wVirtualKeyCode := vk;
   KeyEvent.wVirtualScanCode := MapVirtualKey (KeyEvent.wVirtualKeyCode, 0);
   KeyEvent.bKeyDown := true;
   WriteConsoleInputW (hConInput, r, 1, num);
   KeyEvent.bKeyDown := false;
   WriteConsoleInputW (hConInput, r, 1, num);
  end;
end;


function ChToOem (const s: string): string;
var p: array [0..255] of char;
begin
 CharToOemBuff (PChar (s), p, Length (s) + 1);
 result := p;
end; // PChar (s)

procedure SendInputStr (hConInput: THandle; s: PChar); stdcall;
var
  n: dword;
  ss: string;

begin
 ss := ChToOem (s);
 for n := 1 to Length (ss) do
     SendInputChar (hConInput, ss [n], 0, 0);
end;

function  ObjName (hDesk: cardinal): String;
var pc: array [0..256] of char;
    tmp: cardinal;
begin
 GetUserObjectInformationA (hDesk, UOI_NAME, @pc, 256, tmp);
 result := pc;
end;

function Err2str (n: dword): string; stdcall;
var
    p : array [0..255] of char;
    i : byte;
begin
 p := '';
 FormatMessage (FORMAT_MESSAGE_FROM_SYSTEM, nil, n,
    LANG_NEUTRAL or (SUBLANG_SYS_DEFAULT shl 10), P, 256, nil);
 for i := 0 to 255 do
  if (p [i] = #13) then p [i] := #0;
 result := p;
end; // Err2str

procedure Log (const s: string);
var tlog: Text;
begin
{$IFOPT D+}
 AssignFile (tlog, 'c:\temp\1t.log');
 {$I-}
 Append (tlog);
 if IOresult <> 0 then ReWrite (tlog);
 WriteLn (tlog, s);
 Flush (tlog);
 CloseFile (tlog)
{$ENDIF}
end;
procedure  SwitchToActiveDesktop (bInherit: Boolean); stdcall;

var
   hWsta, hDesk, hCurDesk: THandle;
   s1, s2: string;
begin
 //GetProcessWindowStation ();
 hWsta := OpenWindowStationW ('Winsta0', bInherit, MAXIMUM_ALLOWED);
 SetProcessWindowStation (hWsta);
 hDesk := OpenInputDesktop (0, bInherit, MAXIMUM_ALLOWED);
 hCurDesk := GetThreadDesktop ( GetCurrentThreadId () );
 s1 := ObjName (hCurDesk);
 s2 := ObjName (hDesk);
 Log (' Thread Desktop = ' + s1 + ', Input Desktop = ' + s2); 
 if (s1 <> s2) then
     begin
      CloseDesktop (hDesk);
      hDesk := OpenDesktopW ('Winlogon', 0, bInherit, MAXIMUM_ALLOWED);
      if (hDesk <> 0) then
        Log ('Opened Winlogon Desktop = ' + DwordToHex (hDesk));
      if (hDesk = 0) then
        begin
         Log ('Failed to Open Winlogon Desktop: ' + err2str (GetLastError));
         hDesk := OpenInputDesktop (0, bInherit, MAXIMUM_ALLOWED);
        end;
     end;
 if (hDesk <> hCurDesk) and (hDesk <> 0) then
  begin
   s1 := ObjName (hDesk);
   Log ('Changing to: ' + s1);
   SetThreadDesktop (hDesk );
   CloseDesktop ( hCurDesk );
  end
 else CloseDesktop (hDesk);

end;

exports
         SwitchToActiveDesktop name 'SwitchToActiveDesktop',
         SendInputChar name 'SendInputChar',
         SendInputKey name 'SendInputKey',
         SendInputStr name 'SendInputStr',
         SendMouseEvent name 'SendMouseEvent',
         chrcnt name 'chrcnt',
         strtrunc name 'strtrunc',
         err2str name 'ErrToStr';


begin
 SwitchToActiveDesktop (true);
end.