unit KbdAPI;

interface
uses Windows, KbdDefs;
{
    Модуль универсального ввода с клавиатуры. Используется один из нескольких механизмов ввода,
  для заполнения кодами нажатых клавиш, внутренней очереди
}

type
     TKeyRec = packed record
      case byte of
       0:(
            key: WORD;
          flags: WORD;
         );         // Флажки
        1:(pack: CARDINAL);
      end; // record
     PHotKeyRec = ^TKeyRec;

type
 TClassWndProc = function (a, b, c, d, e, f, g: Integer): Integer register of object;
 TInputMode = (IM_ASYNC, IM_HOOK);

 TKeybInput = class (TObject)
 { Класс клавиатурного ввода. Поддерживает несколько механизмов:
   1. Асинхронная проверка состояния клавиш
   2. Глобальные ловушки WH_KEYBOARD_LL }
 private
   buff: array [0..kbbuff_len - 1] of TKeyRec; // массив виртуальных клавиш, с флажками
   qstart, ccount: Short; // индекс в кольце буфера и количество символов
   FActive: Boolean;      // Активность системы ввода
   FHandle: THandle;      // дескриптор окна
   lpresstime: dword;     // Время с генерации последнего знака
   prflags: dword;        // флажки нажатия
   lkey: TKeyRec;
   delay, sdelay: DWORD;
   keytab: array [BYTE] of SHORT;
   bStickingMode: Boolean;
   procedure            Activate (bActive: Boolean);
   function             XWindowProc (reax, recx, redx,
                                     lParam, wParam, Msg, hWnd: Integer): Integer; register;
   function             Get (index: Short): TKeyRec;
   procedure            SetKey (index: Short; key, flags: word);
   function             LimIndex (n: Short): Short;
    function TestKeyPressed(nKey: BYTE; flags: DWORD): Boolean;
 public
   imode: TInputMode;
   // Переменные для асинхронного режима.
   speriod: dword;      // период проверки
   rdelay: dword;       // задержка повторения
   eatInput: Boolean;   // Поглощение ввода (при использовании ловушек!).
   property             Active: Boolean read FActive write Activate;
   property             Handle: THandle read FHandle;

   constructor          Create;
   procedure            AsyncKbdRead; // Проверка состояния всех клавиш, сравнение с таблицей
   procedure            OnTimer; virtual; // afx_msg :))
   function             ReadKey (var krec: TKeyRec): Boolean;
   procedure            WriteKey (key, flags: word);
 end;



function         IsPressed (vkey: word): boolean;
function         IsPressedEx (vkey, flags: word): boolean;
function         GetShiftStateFlags: word;

var  gKbdInput: TKeybInput;

implementation
uses Misk, Messages, Types;
{ KbdAPI routines }

function         IsPressed (vkey: word): boolean;
begin
 result := (GetAsyncKeyState (vkey) and $F000 > 0);
end; // IsPressed

function         IsPressedEx (vkey, flags: word): boolean;
begin
 result := IsPressed (vkey) and (flags = GetShiftStateFlags);
end; // IsPressed

function         GetShiftStateFlags: word;
var flags: byte;
begin
 flags := 0;
 // Mouse buttons not added to out set
 if IsPressed (VK_MENU)    then flags := flags or KF_ALT;
 if IsPressed (VK_SHIFT)   then flags := flags or KF_SHIFT;
 if IsPressed (VK_CONTROL) then flags := flags or KF_CTRL;
 if IsPressed (VK_LWIN)    then flags := flags or KF_WIN;
 if IsPressed (VK_APPS)    then flags := flags or KF_APPS;
 if (flags <> 0) then flags := flags or KF_PRESS;
 result := flags;
end; // GetShiftStateFlags;

type KBDLLHOOKSTRUCT = record
        vkCode: dword;
      scanCode: dword;
         flags: dword;
          time: dword;
   dwExtraInfo: dword; 
  end;

type PKBDLLHOOKSTRUCT = ^KBDLLHOOKSTRUCT;
var
   kbdHook: THandle = 0;

function KbdLLHookProc (nCode, kbMsg: Integer; pKbds: PKBDLLHOOKSTRUCT): Integer; stdcall;
var flags, add_res: WORD;
    bReady: Boolean;
    ls: KBDLLHOOKSTRUCT;
    ticks: DWORD;
begin
 result := 0;
 add_res := 0;
 bReady := (nil <> gKbdInput) and gKbdInput.eatInput;
 Move (pKbds^, ls, sizeof (ls));
{
 if bReady and (ls.vkCode <> VK_SNAPSHOT) then
    begin
     pKbds.vkCode := 0;
     pKbds.scanCode := 0;
     add_res := 1;
    end; {}

 if kbdHook <> 0 then
 begin
  ticks := GetTickCount;
  result := CallNextHookEx (kbdHook, nCode, kbMsg, DWORD (pKbds));
  ods ('%%% kbdll  event, time of handle =  ' +
       IntToStr (GetTickCount - ticks) );
 end;
 if bReady and
    ((kbmsg = WM_KEYDOWN) or (kbmsg = WM_KEYUP) or
     (kbmsg = WM_SYSKEYDOWN) or (kbmsg = WM_SYSKEYUP)) then
   begin
    // (gKbdInput.imode = IM_HOOK)
    flags := GetShiftStateFlags;
    if pKbds.flags and LLKHF_ALTDOWN <> 0 then
       flags := flags or KF_ALT;
    if (pKbds.flags and LLKHF_UP = 0) then // release events skipped
       flags := flags or KF_PRESS;
    // требуется механизм конвертации флагов
    gKbdInput.WriteKey (ls.vkCode, flags); // unconverted once
   // save out
  end;
 if (nCode >= 0) then result := result or add_res;
end;

{ TKeybInput }

procedure TKeybInput.Activate;
begin
 FActive := bActive;
 if (bActive) then SetTimer (Handle, 100, speriod, nil)
              else KillTimer (Handle, 100);
 qstart := 0; // очистка очереди
 ccount := 0;
end; // Activate



function IsSpecKey (key: BYTE): Boolean;
const spkeys: set of BYTE =  [VK_SHIFT, VK_CONTROL, VK_MENU, VK_CAPITAL,
                      VK_LSHIFT, VK_RSHIFT, VK_LCONTROL, VK_RCONTROL,
                      VK_LMENU, VK_RMENU, VK_RWIN, VK_LWIN];
begin
 result := (key in spkeys);
end; // IsSpecKey
function  StdKey (key: byte): boolean;
begin
 result := not IsSpecKey (key);
end;

function KeyPressed (nKeySet: SHORT): Boolean;
begin
 result := nKeySet and $8000 <> 0;
end;

function KeyToggled (nKeySet: SHORT): Boolean;
begin
 result := nKeySet and $0001 <> 0;
end;

function TKeybInput.TestKeyPressed (nKey: BYTE; flags: DWORD): Boolean;
var
   keystate, lkeystate: SHORT;
   std, kp, kt, lkp, lkt, stmode: Boolean;

begin
  result := false;
  keystate := GetAsyncKeyState (nKey); // возвратить изменения с последнего вызова.
  lkeystate := keytab [nKey];
  // extracting flags
  kp := KeyPressed (keystate); // выборка крайнего бита
  kt := KeyToggled (keystate);
  lkp := KeyPressed (lkeystate);
  lkt := KeyToggled (lkeystate);
  stmode := (lkeystate and KF_REPEAT <> 0) and lkt and kt; // режим повторения
  std := stdkey (nKey); // проверка - клавиша обычная

  if kp or kt then // keystate is pressed
   Begin
    result := true;
    flags := flags or KF_PRESS; // нажатие зарегистрированно
    if not (lkp or lkt) and kp then // Before it the keystate was released
      begin
       WriteKey (nKey, flags);
       // ods ('#key press ' + BYTE2HEX (nKey));
      end;
    // Если включен режим повторение и подошло время
    if stmode and (delay > rdelay) then // prevoisly keystate has been pressed
       WriteKey (nKey, flags); // отработка повторения
     // включение повторения
    if lkt and kt and std and (delay > sdelay) then
      begin
       keystate := keystate or KF_REPEAT;
       stmode := true;
       WriteKey (nKey, flags);
      end;
    // пост-обработка нажатия
    bStickingMode := stmode; {}
   End
  Else
   if keytab [nKey] <> 0 then
    begin
     // отпускание клавиши
     flags := (flags or KF_KEYUP) and not (KF_PRESS);
     WriteKey (nKey, flags);
    end;                     {}
  keytab [nKey] := keyState;  // save new flags configuration
end; // TKeybInput.TestReadKey

procedure TKeybInput.AsyncKbdRead;

var
   n, flags: dword;
   pkey :byte;
   ctime: dword;
   somePressed, bPress: Boolean;
begin
 pkey := lkey.key;
 ctime := GetTickCount; // время проверки состояния клавы
 if 0 = lpresstime then lpresstime := ctime;
 // анализ - сколько прошло времени с предыдущего нажатия
 delay := ctime - lpresstime;
 // получение флажков клавиатуры
 flags := GetShiftStateFlags;
 somePressed := false;
 for n := 8 to 255 do
 begin
  bPress := TestKeyPressed (n, flags);
  somePressed := somePressed or bPress;
  if stdkey (n) and bPress then break;
 end;
 // lpresstime := 0;
 if somePressed then
 begin
  // Если изменилось состояние клавы.
  // время начала нажатия сбрасывается.
  if (lkey.flags <> flags) or
     (lkey.flags and KF_PRESS = 0) then
     begin
      lpresstime := ctime;
      bStickingMode := false;
     end;
  lkey.key := pkey;
  lkey.flags := flags;
  _or (prflags, 1);
 end
 else
 begin
  lkey.pack := 0;
  bStickingMode := false;
  _clear (prflags, 1);
  lpresstime := 0;
 end;
end; // AsyncKbdRead

constructor TKeybInput.Create;

var
    LWndMethod: TClassWndProc;
    LWndProc: Pointer absolute LWndMethod;
    WClass: TWndClassEx;
begin
 LWndMethod := XWindowProc; // WndProc HACK
 qstart := 0;
 ccount := 0;
 speriod := 20;
 sdelay := 500;
 rdelay := 50;
 prflags := 0;
 bStickingMode := false;
 imode := IM_ASYNC; // IM_ASYNC or IM_HOOK
 if not GetClassInfoEx (hInstance, KbdWindowClass, WClass) then
  begin
   // Forcing registration
   memsetb (@WClass, 0, sizeof (WClass));
   WClass.style := CS_CLASSDC or CS_HREDRAW or CS_VREDRAW or CS_SAVEBITS;
   WClass.hInstance := Hinstance;
   WClass.lpfnWndProc := LWndProc; // XWindowProc method as Proc!
   // WClass.lpfnWndProc := @DefWindowProc;
   WClass.lpszClassName := KbdWindowClass;
   WClass.cbSize := sizeof (WClass);
   RegisterClassEx (WClass);
  end;
 // Parent  HWND_MESSAGE
 FHandle := CreateWindowEx (WS_EX_NOPARENTNOTIFY, WClass.lpszClassName,
                          'AFX',
                          WS_THICKFRAME, // window must be hidden
                          0, 0, 100, 100, Dword (0), 0,
                          Hinstance, self);
 SetWindowLong (FHandle, GWL_USERDATA, Integer (self));
 // ShowWindow (FHandle, SW_SHOW);
end;

function TKeybInput.Get;
begin
 ASSERT (index < kbbuff_len);
 result := buff [index];
end;

function TKeybInput.LimIndex(n: Short): Short;
begin
 while ( n >= kbbuff_len ) do dec (n, kbbuff_len);
 result := n;
end;

procedure TKeybInput.OnTimer;
begin
 if not Assigned (self) or not Active then exit;
 if imode = IM_ASYNC then AsyncKbdRead;
 // if IsWindowVisible (Handle) then else ShowWindow (Handle, SW_SHOW);
end;

function TKeybInput.ReadKey(var krec: TKeyRec): Boolean;
begin
 result := ccount > 0;
 if not result then exit;
 // qstart := LimIndex (qstart);
 krec := Get (qstart);
 buff [qstart].pack := 0;
 qstart := LimIndex (qstart + 1);
 Dec (ccount); // уменьшить количество
end;

procedure TKeybInput.SetKey(index: Short; key, flags: word);
begin
 ASSERT (index < kbbuff_len);
 buff [index].key := key;
 buff [index].flags := flags;
end;

procedure TKeybInput.WriteKey(key, flags: word);
var index: dword;
begin
 index := LimIndex (qstart + ccount); // rool
 if ccount >= KbBuff_len then
   qstart := LimIndex (qstart + 1) // rool increment
 else inc (ccount);
 SetKey (index, key, flags);
end;

function TKeybInput.XWindowProc;
var
    rct: TRect;
begin
 result := 0;
 self := nil;
 // pObject := nil; // self overlapps lParam
 if IsWindow (hWnd) then
    self := TKeybInput (GetWindowLong (hWnd, GWL_USERDATA));
 case Msg of
    WM_CREATE: ; // default return 0
  WM_NCCREATE: result := 1; // return TRUE
  WM_ERASEBKGND:
     begin
      GetClientRect (hwnd, rct);
      FillRect (wParam, rct, (COLOR_BTNFACE + 1));
     end;
  WM_USER + 100:;
  WM_TIMER:
        OnTimer;

  WM_GETMINMAXINFO:
   with PMinMaxInfo (lParam)^ do
    begin
     ptMaxSize := Point (100, 100);
     ptMaxPosition := Point (1000, 1000);
     ptMinTrackSize := Point (0, 0);
     ptMaxTrackSize := Point (1000, 1000);
    end;
  else result := DefWindowProc (hwnd, msg, wParam, lParam);
 end;
 //
end;

initialization
 {$IFOPT D-}
 // kbdHook := SetWindowsHookEx (WH_KEYBOARD_LL, @KbdLLHookProc, hInstance, 0);
 {$ENDIF}
finalization
 UnRegisterClass (KbdWindowClass, hInstance);
 if kbdHook <> 0 then UnHookWindowsHookEx (kbdHook);
end.
