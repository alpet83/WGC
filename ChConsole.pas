unit ChConsole;
interface
uses Windows, Controls, Graphics, ChBtns, KbdAPI, conapi, wconapi,
     GDITools, KbdDefs, ChLog, ChClient;
{

   Модуль консольного управления программой.
   Рисование консоли, обеспечение ввода с клавиатуры, обработка комманд.

   Концепции: у консоли может быть несколько режимов работы.
   Каждый режим определяет набор комманд обрабатываемых консолью.
   Например консоль поиска/отсева обрабатывает ввод чисел и типа образца,
   и изменение правила поиска.

   30.01.2005. Кнопки для управления мышью
 }
 const
      ConWidth = 640;
     ConHeight = 380;
  defcolors: array [0..15] of TColor =
   ( clBlack, clNavy, clGreen, clTeal, clMaroon, clPurple, clOlive, clGray,
     clSilver, clBlue, clLime, clAqua, clRed, clFuchsia, clYellow, clWhite);

type
 TConsole = class (TObject)
   private
     colors: array [0..15] of TColor; // цвета, в текущей палитре
         pf: TPixelFormat;   // Разрешение
    loColor: boolean;        // низкое цветовое разрешение
     falloc: boolean;        // буфферы зарезервированны
     opened: boolean;
    fdrawed: boolean;
    fCancel: boolean;
      fxwin: THandle;           // Окно у которого берется DC
     sstate: dword;             // Shift/Alt/Ctrl
      first: dword;             // первая рисуемая строка
       buff: TGdiBuff;
     bgBuff: TGdiBuff;          // Для сохранения изображения
     imbuff: TGdiBuff;          // Для комбинации с полупрозрачным

     DispDC: HDC;
       hpal: HPALETTE;
     pcount: dword;             // Количество прорисовок
   nbtn, lbtn: string;            // Название нажатой кнопки
      mcntr: Integer;           // Счетчик показов курсора мыши
      showTime: dword;          // время показа консоли
      hProcess: THandle;        // внешний процесс запущеный в консоли
    hConThread: THandle;
      FVisible: Boolean;
       conBusy: Integer;        // 1 = busy, 0 = free
      sLast: String;
    function  ReadLoop (bStartThread: Boolean = true): String;
    function  GetKey: dword;
    procedure CloseDC;
    procedure OpenDC (const freopen: boolean = false);
    procedure CreateBuffs (BaseDC: HDC);
    procedure DeleteBuffs;
    function  BtnPressed: string;
    procedure ProcessMessages;
    procedure SaveBackground; // нажата виртуальная кнопка
    procedure SetVisible (bVisible: Boolean);
    procedure RestoreBackground;
    procedure StartCmd;
    procedure CancelTest;
    procedure ResetKeyboard;
   public
    conTimeout: dword;          // таймаут на показ консоли
    hEventHook: THandle;
       console: TAbsConsole;
      bGFXmode: Boolean;        // режим отображения графический   
     bReleased: Boolean;
  //     hConWnd: THandle;        // описатель самой консоли
          rect: TRect;
         outpt: TPoint; // точка вывода консоли
          mode: dword;
          btns: array [1..7] of TBtn; // add, cheat, clear, list, set, table, close
          hWnd: THandle;
         hFWnd: THandle;
     hInputWnd: THandle; // focused window
        sInput: String;
    bInputComplete: Boolean;
    bInputStart: Boolean;
    property  Visible: boolean read FVisible write SetVisible;

    constructor     Create;
    destructor      Destroy; override;
    function        HandleInput (const ct: dword): string;
    procedure       Hide (const delay: dword = 100);
    procedure       RedrawConsole (const full: boolean = false);
    procedure       SetLast (const S: String);
    procedure       Show;
    procedure       WriteText (const S: String);
   end;

var
    con: TConsole = nil;
   hConWnd: THandle;
   fcons: boolean; // Флаг возможно выведенной консоли
    inputBreak: boolean = false;

implementation

uses ChTypes, ChConst, ChForm, Forms, SysUtils, ChMsg, CheatTable,
     Misk, Messages, Types, ChCmd, ChShare, spthread, StrSrv, ChCodes, Dialogs, StrTools, ChSettings;

function StrRect (const r: TRect): string;
begin
 result := IntToStr (r.Left) + ', ' + IntToStr (r.Top) + ', ' +
           IntToStr (r.Right) + ', ' + IntToStr (r.Bottom);
end;

function GetCurThread: String;
begin
 result := '0x' + Dword2Hex (GetCurrentThreadId);
end;

var DefEditProc: function (hWnd: THandle; uMsg, wParam, lParam: Integer): Integer; stdcall = nil;
function EditSubclassProc (hWnd: THandle; uMsg, wParam, lParam: Integer): Integer; stdcall;
begin
 result := 0;
 if (uMsg = WM_PAINT) then
  begin
   ValidateRect (hWnd, nil);
   exit;
  end;
 result := DefWindowProc (hWnd, uMsg, wParam, lParam); 
end;

procedure ConEventProc (hWinEventHook, event, hWnd, idObject, idChild,
                         dwEventThread, dwmsEventTime: dword); stdcall;

begin
 if (con <> nil) and (con.Visible) then
  begin
  // con.console.bBlink := true;
   con.RedrawConsole();
   // ods ('#OnConEvent - redraw.');
  end;
end;

var dwDrvCycles: DWORD = 0;

function ConInputDriver (param: Pointer): DWORD; stdcall
var
   console: TConsole absolute param;
   sTemp: string;
   tcon: Text;
begin
 result := 0;
 if Assigned (console) then
  begin
   // проверка блокировки
   if console.bInputStart then exit;
   console.bInputStart := true
  end
 else exit;
 result := 1;
 // получение доступа к файлу ввода
 AssignFile (tcon, '');
 Reset (tcon);
 SetLength (sTemp, 512); // set default length.
 Readln (tcon, sTemp);
 Close (tcon);
   try
    console.sInput := sTemp; // copy fast what exist
    console.bInputComplete := true;
   except
    result := $8000C010;
   end;
 console.bInputStart := false;
end; // ConDriver

constructor     TConsole.Create;
var rct: TRect;
    pproc: Pointer;
begin
 // !!!
 conBusy := 0;
 console := nil;
 bInputStart := false;
 bReleased := false;
 Sleep (0);
 hConWnd := 0;
 console := MakeConsole;
 //hConWnd := console.GetConsoleWindow;
 SetConsoleTitleW ('WGC Command Console');
 {$IFOPT D-}
 ShowWindow (hConWnd, SW_HIDE);
 {$ENDIF}
 Visible := False;
 hEventHook := SetConsoleEventHook (@ConEventProc);
 conTimeout := 30 * 1000;
 outpt.x := 10;
 outpt.y := 50;
 rect.Left := 0;
 rect.Top := 0;
 rect.Right := rect.Left + ConWidth - 1;
 rect.Bottom := rect.Top + ConHeight - 1;
 hWnd := CreateWindowEx (0,
                 'edit', 'Console',
                 WS_CLIPSIBLINGS or
                 WS_CHILD,
                 outpt.x, outpt.y, ConWidth, ConHeight + 50,
                 mform.Handle, 0, hInstance, nil);
 if IsWindow (hWnd) then
  begin
   pproc := Pointer ( GetClassLong (hWnd, GCL_WNDPROC));
   @DefEditProc := pproc;
   SetWindowLong (hWnd, GWL_WNDPROC, Integer (@EditSubclassProc));
  end;
 falloc := false;
 fdrawed := false;
 opened := false;
 SetRect (rct, 20, 25, 100, 50);
 // Кнопкам задаются относительные координаты
 // TODO: нужно преобразовать в чисто консольный вариант

end;

destructor TConsole.Destroy;
begin
 if hEventHook <> 0 then UnhookWinEvent (hEventHook);
 bReleased := true;
 Hide; // освободить поток
 console.Free;
 DeleteBuffs; // Попытатся освободить буфферы
 DestroyWindow (hWnd);
 {$IFOPT D+}
 OutputDebugString ('TConsole.Destroy passed');
 {$ENDIF}
end;


procedure TConsole.CancelTest;
begin
 if hProcess <> 0 then
    fCancel := ( WaitForSingleObject (hProcess, 1) <> WAIT_TIMEOUT );
end;

function CreateSystemPalette(const Entries: array of TColor): HPALETTE;
var
  DC: HDC;
  SysPalSize: Integer;
  Pal: TMaxLogPalette;
begin
  Pal.palVersion := $300;
  Pal.palNumEntries := 16;
  Move(Entries, Pal.palPalEntry, 16 * SizeOf(TColor));
  DC := GetDC(0);
  try
    SysPalSize := GetDeviceCaps(DC, SIZEPALETTE);
    { Ignore the disk image of the palette for 16 color bitmaps.
      Replace with the first and last 8 colors of the system palette }
    if SysPalSize >= 16 then
    begin
      GetSystemPaletteEntries(DC, 0, 8, Pal.palPalEntry);
      { Is light and dark gray swapped? }
      if TColor(Pal.palPalEntry[7]) = clSilver then
      begin
        GetSystemPaletteEntries(DC, SysPalSize - 8, 1, Pal.palPalEntry[7]);
        GetSystemPaletteEntries(DC, SysPalSize - 7, 7, Pal.palPalEntry[Pal.palNumEntries - 7]);
        GetSystemPaletteEntries(DC, 7, 1, Pal.palPalEntry[8]);
      end
      else
        GetSystemPaletteEntries(DC, SysPalSize - 8, 8, Pal.palPalEntry[Pal.palNumEntries - 8]);
    end
    else
    begin
    end;
  finally
    ReleaseDC(0,DC);
  end;
  Result := CreatePalette(PLogPalette(@Pal)^);
end;

procedure       TConsole.OpenDC;
var
   h: THandle;
   n: dword;
   pt: TPoint;
begin
 if opened and not freopen then exit;
 if opened then CloseDC ();
 // ods ('#Trying OpenDC');
 n := 0;
 h := hWnd;
 if not IsWindowVisible (h) then
 while (h = 0) and (n < 200) do
  begin
   h := WindowFromPoint (point (n, n));
   inc (n);
  end;
 fxwin := h;
 hFWnd := h;
 DispDC := GetWindowDC (h);
 // Получить информацию о разрешении экрана
 pf := pf32bit;
 opened := DispDC <> 0;
 if opened then
 case GetDeviceCaps (DispDC, BITSPIXEL) of
   8: pf := pf8bit;
  15: pf := pf15bit;
  16: pf := pf16bit;
  24: pf := pf24bit;
  32: pf := pf32bit;
 end;
 hpal := 0;
 Move (defcolors,  colors, sizeof (TColor) * 16);
 loColor := not (pf in [pf15bit, pf16bit, pf24bit, pf32bit]);
 if loColor then
  begin
   //inc (colors [9], $8080);
   hpal := CreateSystemPalette (colors);
  end;
 // debug testing
 //  hBrush := GetStockObject (WHITE_BRUSH);
 // SetRect (r, 0, 0, 200, 200);
 // FillRect (buff.MemDC, r, hBrush);
 if hWnd <> hFWnd then
    SetViewportOrgEx (DispDC, outpt.x, outpt.y, @pt);
end; // DrawConsole

procedure       TConsole.CloseDC;
begin
 if (not opened) then exit;
 // ods('#Trying CloseDC');
 if hpal <> 0 then
  begin
   RealizePalette (DispDC);
   DeleteObject (hpal);
  end;
 // DeleteDC (DispDC);
 ReleaseDC (hFWnd, DispDC);
 hpal := 0;
 DispDC := 0;
 opened := false;
end; // CloseConsole

procedure       TConsole.CreateBuffs;
begin
 if falloc then exit;           // Проверка на необходимость
 buff := console.CreateBuff (BaseDC);
 // копирования и преобразования с минимумом затрат
 imbuff.Init (DispDC, Screen.Width, Screen.Height);

 console.SetFont ('Lucida Console', -12);
 // RedrawConsole (true);
 if hpal <> 0 then
  begin
   if RealizePalette (buff.MemDC) = GDI_ERROR then RaiseLastOSError;
   if SelectPalette (buff.MemDC, hpal, false) = 0 then RaiseLastOSError;
  end;
 falloc := true;
 fdrawed := false;
end; // CreateBuffs

procedure       TConsole.DeleteBuffs;
begin
 if not falloc then exit;
 buff.Release;
 bgbuff.Release;
 imbuff.Release;
 falloc := false;
 fdrawed := false;
end; // DeleteBuffs


type
     TKeybdState = array [0..255] of SmallInt;
var
     ks, lks: TKeybdState;
     fPressed: boolean;
const
    statekeys: set of byte =
      [VK_SHIFT, VK_CONTROL, VK_MENU, VK_LWIN, VK_RWIN, VK_CAPITAL, $A0];

function        TConsole.GetKey: dword;
var
    n: byte;
    press: boolean;
    kr: TKeyRec;
begin
 result := 0;
 sstate := 0;
 fPressed := false;
 if not gKbdInput.ReadKey(kr) then
  begin
   if IsPressed (VK_LBUTTON) then kr.key := VK_LBUTTON else  exit;
  end;
 n := kr.key;
 fillchar (ks, sizeof (ks), 0);
 //  n := $01 to $F5 do
  begin
   ks [n] := $1;
   press := true;
   if (n = VK_LBUTTON) then
    begin
     if press then nbtn := BtnPressed else lbtn := ''; // Сброс состояния
    end;
   if (press) then
   case n of
    VK_SHIFT: sstate := sstate or KF_SHIFT;
  VK_CONTROL: sstate := sstate or KF_CTRL;
     VK_MENU: sstate := sstate or KF_ALT;
  VK_LWIN,
     VK_RWIN: sstate := sstate or KF_WIN;
  VK_CAPITAL:;
   else fPressed := true; // установить флажок
   end;
  end;
  begin
   // цикл поиска нажатых клавиш
   result := n;
  end;
 lks := ks;
end; // GetKey




function       UpKeyStr (const s: string): string;
var n: dword;
begin
 result := '';
 for n := 1 to Length (s) do
     result := result + UpperKey (s [n]);
end;

procedure       TConsole.ProcessMessages;
{ Обработка сообщений для фонового окна }
var msg: tagMSG;
begin
 while (PeekMessage (msg, hWnd, 0, 0, PM_REMOVE)) do
  begin
   //TranslateMessage (msg);
   DispatchMessage (msg);
  end;
end;

function        TConsole.ReadLoop;
// Чтение клавиатуры до полной строки
var
    fBreak: Boolean;
    t, tid: DWORD;
    nIter: Integer;
    kr: TKeyRec;

 procedure EventTest;
 begin
  t := GetTickCount ();
  // оценка сколько прошло времени
  if t - tid > 250 then
   begin
    tid := t;
    console.bBlink := not console.bBlink;
    RedrawConsole (true);
   end;
  fCancel := IsPressed (VK_ESCAPE);
  fBreak := bInputComplete;
  CancelTest;
  Sleep (1);
 end; // EventTest

begin
 {   Алгоритм консольного ввода.
   Задачи ввода выполняются двумя потоками:
   1-ый:  Считывание строки (Readln, создается в основном).
   2-ой:  Отрисовка консоли (в игре), перехват ввода с клавиатуры, и
    трансляция его в консоль (если не показывается стандартное окно консоли).

 }
 // чтение целой строки
 fBreak := false;
 fCancel := false; // внешнее прерывание
 showTime := GetTickCount ();
 result := '';
 if gKbdInput.Handle = 0 then exit;
 sInput := '';
 bInputComplete := false;
 hConThread := 0;
 if (bStartThread) then
  begin
   hConThread := CreateThread (nil, 256 * 1024, @ConInputDriver,
                   self, 0, tid);
   if hConThread = 0 then exit;
   // поток пускай работает с большим приоритетом, все равно курить будет
   SetThreadPriority (hConThread, THREAD_PRIORITY_HIGHEST);
   if not gKbdInput.eatInput then
   // увеличить внутренний приоритет
      SetThreadPriority (GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL);
  end; 
 tid := GetTickCount();
 nIter := 0;
 // Циклическая обработка, посути ModalLoop
 repeat
  if bGFXmode then
   begin
    // обработка внешнего ввода
    if not gKbdInput.eatInput then gKbdInput.OnTimer;
    if gKbdInput.ReadKey (kr) then
       console.SendKbdInput (kr.key, kr.flags, false);
   end;
  Inc (nIter);
  if nIter and $03 = 0 then
   begin
    Application.HandleMessage; // if message exist, it has dispatched
    fCancel := fCancel or gbAppTerminate;    
   end;
  if (nIter and $3F = 0) then EventTest;
 until fBreak or fCancel; // условия завершения цикла
 // восстановление приоритетов
 SetThreadPriority (GetCurrentThread(), THREAD_PRIORITY_NORMAL);
 if fBreak then result := sInput;
 if hConThread <> 0 then
  begin
   if fCancel then TerminateThread (hConThread, 0);
   CloseHandle (hConThread);
  end; 
 hConThread := 0;
 ods ('#TRACE read str: ' + sInput);
 sLast := sInput + #13#10;
end; // ReadStr

function TConsole.HandleInput;
var
   s: string;
   sv: TStrSrv;
   indx: dword;
   err: Integer;
begin
 Show;
 { Обработка одного из режимов ввода. Предварительно выводится информация о
   текущем состоянии ввода. }
 inputBreak := false;
 sv := TStrSrv.Create;
 s := '';
 result := '';
 case ct of
  0:;
  1: s := 'Поиск ';
  2: s := 'Отсев ';
  3: repeat
      s := '';
      WriteText ('Command mode ->');
      GetKey;
      while (s = '') do
       begin
        inputBreak := false;
        s := ReadLoop;
        if (gbAppTerminate) then s := 'close';
       end;
      s := LowerCase (s);
      if (s <> '') then
       begin
        sv.Assign (s); // Для полного анализа
        s := sv.ReadSub; // считать часть строки
        if (s = 'exit') or (s = 'quit') then  s:= 'close'; // то же самое
        if (s = 'add') or (s = 'a') then mform.btnAddClick(mform);
        if (s = 'cheat') or (s = 'ch') then frmAddrs.btnCheatClick (mform);
        if (s = 'clear') or (s = 'cl') then frmAddrs.btnClearClick (mform);
        if (s = 'cmd') then StartCmd;
        if (s = 'list') or (s = 'ls') then mform.ListChCodes;
        if (s = 'lock') or (s = 'lc') then
         begin
          s := sv.ReadSub;
          if (s = '') then continue;
          val (s, indx, err);
          frmAddrs.sgCheat.Row := indx;
          frmAddrs.btnLockClick (mform);
         end;
        if (s = 'table') or (s = 't') then mform.ListTable;
        if (s = 'set') then
        // Изменение
         begin
          s := sv.ReadSub; // Индекс значения
          if (s = '') then continue;
          val (s, indx, err);
          if (err <> 0) or (indx = 0) then continue;
          s := sv.ReadRest; // Что осталось
          frmAddrs.sgCheat.cells [4, indx] := s;
          frmAddrs.btnCheatClick (mform);
         end;
        end; // if s <> '' then
     until s = 'close';
 end;
 sv.Free;
 if (s = 'close') then exit;
 WriteText (s + '-> '); // Ввод
 FillChar (lks, 256, 0);
 while GetKey <> 0 do; // считать нажатые клавиши
 result := ReadLoop;
 WriteText ('');
end;

procedure TConsole.Hide;
var
   tout: dword;
begin
 while (IsPressed (VK_SHIFT)) do Sleep (1);
 // выбор по режиму
 ShowWindow (hConWnd, SW_HIDE);
 ShowWindow (hWnd, SW_HIDE);
 if bGFXmode and not opened then OpenDC;
 if not visible then exit;
 visible := false; // suspending driver thread
 // Восстановление затертого участка игры
 // Sleep (delay); // для пользователя и заема проц. времени
 if bGFXmode then
  begin
   ShowWindow (hWnd, SW_HIDE);
   SetParent (hWnd, 0);
   RestoreBackground;
   //   RestoreBackground;
  end;
 fdrawed := false;
 if mouse.MousePresent then mcntr := ShowCursor (true);
 specho := 0;
 spcmd := CM_CLWIN;
 sleep (10);
 if (survive) then sthrd.Terminate;
 tout := 0;
 ods ('DrvThread cycles = ' + IntToStr (dwDrvCycles) + #10);
 // Ожидание глушения потока
 while (survive) and (tout < 10) do SleepInc (tout, 10);
 if (tout = 10) then
  begin
   ods ('Thread terminating timeout. ');
   TerminateThread (sthrd.Handle, 0);
  end;
 // Закрыть окна если остались
 KillCtrls;
 CloseDC (); // Закрыть DC
 DeleteBuffs;
 // visible = false, not need locking
 mform.Invalidate;
 if hInputWnd <> 0 then EnableWindow (hInputWnd, TRUE);
 gKbdInput.eatInput := false;
 ResetKeyboard;
end; // Hide

procedure TConsole.RedrawConsole;
var
    bf: TBlendFunction;
    alpha: dword;
    ur: TRectClass;
    conorg: TPoint;
    dbgs: string;
begin
 if not visible or not bGFXmode then exit;
 // ods ('#Trying redraw console');
 ASSERT (opened);
 // Если небыло прорисованно - сохранить регион
 // Обрисовать прямоугольник
 // font
 first := 1;
 ur.CopyRect (buff.Rect); // целиком и полностью


 if Assigned(console) then
  begin
   console.bFullRedraw := full;
   // console.SetHandles (hInput, hOutput);
   buff.SetTextColor ($FFFF);
   if console.RedrawConsole (0, console.conrect.Bottom) then
    begin
     // ods ('#drawing console success.');
    end;
   conorg.X := 0;
   conorg.Y := 0;
   ur := console.GetUpdatedRect;
   console.PrintTo (imbuff.MemDC, ur.rect, conorg);
   if full then
     MoveWindow (hWnd, outpt.x, outpt.y,
                ur.Width, ur.Height, FALSE);
   // ur := console.GetUpdatedRect; // расширенный прямоугольник
  end;

 // Наложение исходного изображения
 if not loColor then
   begin
    // Реализация полупрозрачности
    bf.BlendOp := AC_SRC_OVER;
    bf.BlendFlags := 0;

    alpha := pWgcSettings.nConsTransparent * 16;
    if (alpha > 0) then dec (alpha);

    bf.SourceConstantAlpha := alpha;
    bf.AlphaFormat := AC_SRC_ALPHA;
    ASSERT (imbuff.MemDC <> 0);
    dbgs := StrRect (ur.Rect);
    if not AlphaBlend (
             imbuff.MemDC,         // Dest DC
             ur.Left, ur.Top,
                ur.Width, ur.Height, // Dest Rect
             bgBuff.MemDC,             // Src DC
             ur.Left, ur.Top,
                ur.Width, ur.Height, // Src Rect
             bf    ) then {}
    ods ('#GDI ERROR: ' + GetLastErrorStr + ', rect = ' + dbgs);
   end;
 // Отображение результата на дисплейный контекст
 imbuff.CopyTo (DispDC, ur.Left, ur.Top,
                          ur.Width, ur.Height,
                        ur.Left, ur.Top);
 {}                          
 GdiFlush ();
 inc (pcount);
 // CloseDC ();
 GdiFlush ();
end;

procedure TConsole.ResetKeyboard;
var kbs: TKeyboardState;
begin
 FillChar (kbs, sizeof (kbs), 0);
 SetKeyboardState (kbs); // all key has released

end;
procedure TConsole.RestoreBackground;
begin
 bgbuff.CopyFull(DispDC);
end;

procedure TConsole.SaveBackground;
begin
 // if hFWnd = hWnd then ShowWindow (hFWnd, SW_HIDE);
 // Создание буффера для хранения копии экрана
 bgbuff.Init (DispDC, Screen.Width, Screen.Height);
 visible := true;
 fdrawed := false; // для захвата экрана
 specho := 0;
 //spcmd := CM_CRWIN; // отправить сообщение на создание окна поглощения
 pcount := 0;
 FillRect (bgbuff.MemDC, bgbuff.Rect,
           GetStockObject (WHITE_BRUSH));
 with bgbuff do
 BitBlt (MemDC,
         left, top,
         width, height, DispDC,
         left, top, SRCCOPY or CAPTUREBLT);
 // if hFWnd = hWnd then ShowWindow (hFWnd, SW_SHOW);
end;

procedure TConsole.SetVisible;
begin
 if FVisible = bVisible then exit; // changes
 FVisible := bVisible;
end;

procedure TConsole.SetLast;
begin
 sLast := s;
 write (#13 + Ansi2Oem (sLast));
end;

procedure TConsole.Show;
var tout: dword;
    t1, t2: dword;
    bPress: Boolean;
begin
 ResetKeyboard;
 t1 := GetTickCount;
 // waiting for releasing keys
 repeat
  t2 := GetTickCount;
  bPress := false;
  for tout := $08 to $FF do
      bPress := bPress or IsPressed (tout);
 until (not bPress) or (t2 - t1 > 10000);
 bGFXmode := not mform.Active;
 // if opened then SaveBackground;
 if (pWgcSettings.bSuspend) then
  begin
   tout := 0;
   while (specho = 0) and (tout < 100) do sleepInc (tout, 10);
  end;

 // устроение окон
 if bGFXmode then
  begin
   t1 := WindowFromPoint (point (0, 0));
   hInputWnd := GetFocus;
   if hInputWnd = 0 then hInputWnd := t1;
   EnableWindow (hInputWnd, FALSE);
   SetParent (hWnd, hInputWnd);
   ShowWindow (hWnd, SW_SHOW);
   // ShowWindow (hWnd, SW_SHOW);
   t1 := GetWindowThreadProcessId (hInputWnd);
   t2 := GetCurrentThreadId ();
   AttachThreadInput (t1, t2, true);
   ProcessMessages;
   SetActiveWindow (hWnd);
   SetFocus (hWnd);
   AttachThreadInput (t1, t2, false);
   visible := true; // signal for starting draw, resuming driver thread
   // подготовка графической подсистемы
   OpenDC;
   // Сохранить фон до вывода защитного окна
   CreateBuffs (DispDC);
   SaveBackground;

   gKbdInput.eatInput := pWgcSettings.bConsInputCapture;
  end
  else
  ShowWindow (hConWnd, SW_SHOWNORMAL);
  // RedrawConsole (true);
end; // Show

procedure TConsole.StartCmd;
var
   si: _STARTUPINFOA;
   pi: PROCESS_INFORMATION;
begin
 FillChar (si, sizeof (si), 0);
 FillChar (pi, sizeof (pi), 0);
 si.dwFlags := STARTF_USESTDHANDLES;
 si.hStdInput := console.hInput;
 si.hStdOutput := console.hOutput;
 si.hStdError := console.hOutput;
 hProcess := 0;
 if CreateProcessA (nil, 'cmd.exe', nil, nil, false, 0, nil,
                   '\Program Files',
                si, pi) then hProcess := pi.hProcess;

 if hProcess <> 0 then
  begin
   WaitForSingleObject (hProcess, 200); // дать время на размышления
   ReadLoop (false);
   CloseHandle (pi.hProcess);
   CloseHandle (pi.hThread);
  end;
 hProcess := 0;
 RedrawConsole (true);
end; // StartCmd;


function TConsole.BtnPressed: string;
var n: dword;
    pt: TPoint;
begin
 result := '';
 GetCursorPos (pt);
 dec (pt.x, outpt.x);
 dec (pt.y, outpt.y);
 for n := 1 to high (btns) do
  if (btns [n].HitTest (pt)) then result := LowerCase ( btns [n].caption );
 // Отключение повторений
 if (result <> '') then
  begin
   if (result = lbtn) then result := ''
                      else lbtn := result; // Запомнить
  end;
end;

procedure TConsole.WriteText;
begin
 if (sLast = '') or (sLast [Length (sLast)] <> #10) then
  sLast := #13#10 + s else sLast := s;
 Write (Ansi2Oem (sLast));
end;

initialization
finalization
 LogStr('#NOTFIY: ChConsole module - finalization...');
end.
