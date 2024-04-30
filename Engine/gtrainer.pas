unit gtrainer;

interface
uses Classes, SysUtils, Rects, IniFiles, Types, Windows,
        Messages, TlHelpEx, ChSource, ChTypes, ChConst;
{ Модуль глобальных определений как для конструктора, так и для загрузчика трейнеров }

type
    ShortStr = array [0..255] of AnsiChar;
    TVisControl = (vcArrow, vcButton, vcLabel, vcEdit, vcCheckBox, vcValue);
    TProperty = (prText, prName, prPos, prSize, prFont, prStyle,
                 prAddr, prType, prInOut, prTimer, prGame,
                 prRAction, prWAction, prHotKey);
    TPropSet = set of TProperty;


{ - ------------------------------------------------------------------------ - }

const
    CtrlClasses: array [TVisControl] of string =
      ('', 'Button', 'Static', 'Edit', 'Checkbox', 'Value');
    CtrlNames: array [TVisControl] of string =
      ('', 'btn', 'lbl', 'edt', 'cbx', 'val');

    CtrlSet: TPropSet = [prText, prName, prFont, prStyle, prPos,
                            prSize, prInOut, prHotKey];

    ValueSet: TPropSet = [prText, prName, prAddr, prType];
    MaxControl = 256;

type
    TValue = packed record
     styp: string;  // тип значения
     addr: string;  // адрес
    end;

    TCtrl = packed class
    public
       ctrl: TVisControl;
       hwnd: THandle;   // hWnd for visual controls
       alreadyPressed: Boolean;
         tx: AnsiString; // 31 symbols + 0
         nm: AnsiString; // название контрола
         iv: AnsiString; // источник значения
         ov: AnsiString; // приемник значения
       ract: AnsiString; // события на считывание
       wact: AnsiString; // события на запись
        err: AnsiString;
       hkey: dword;  // Горячая клавыша
         rt: TRct;
         ps: TPropSet; // флажки свойств
         vs: word;    // Индекс в списке визуальных характеристик
         vv: TValue;  // - значение, если контрол = vcValue;
       trig: Boolean; // триггер, напр. для CheckBox  
       mark: boolean;
     constructor Create;
     destructor  Destroy; override;
     procedure   CreateCtrl (hwndParent: THandle); // создать контрол на окне
     procedure   DestroyCtrl;
     procedure   FormatText (const s: string);
     procedure   SetVisual (const n, t: string; c: TVisControl);
    end; // TCtrl

   TMethodList = packed record
    // список указателей на обработчики
      OnWMTimer: procedure (timerID: dword) of object;
    OnWMCommand: procedure (hwnd: THandle) of object;
        OnClose: procedure;
      OnDestroy: procedure of object;
   end; // TMethodList

   TTrainer = class (TObject)
   private
         pl: TProcessArray;
    m_count: word;
    aliased: Boolean;
        pid: THandle; // game process id
     hAlias: THandle;
    procedure   OpenPrcs;
    procedure OnUpdateUI;     // обновление интерфейса и поддержка заморозки
    procedure OnHotKeysTest;  // проверка связанных горячих клавиш
    function  PokeValue (n: word): boolean;
   public
    constructor Create;
    destructor Destroy; override;
    // Constructor members
    function AddCtrl(const n, t: string; c: TVisControl): TCtrl;
    procedure CreateCtrls;
    function CreateWnd(hwndParent: THandle): boolean;
    procedure DelCtrl(n: word);
    procedure DelCtrls;
    function  FindCtrl(h: THandle): word; overload;
    function  FindCtrl (cname: string; start: word = 1): word; overload;
    function  FindCtrlTx (text: string; start: word = 1): word; 
    function  FindValue (vname: string): word;
    procedure LoadDesc(const fname: string);
    procedure SaveDesc(fname: string);
   public
      hwnd: THandle;
      capt: string;  // caption - 31 chars max
      game: string;  // файл игры (без путей)
      rect: TRct;    // границы
       tmr: word;    // значение таймера
     mlist: TMethodList;
     ctrls: array [1..MaxControl] of TCtrl; // about 256 ctrls max
    property    count: word read m_count;    // количество контролов
    // получение действительного значения поля In
    function    GetInVal (n: word): string;
    procedure   OnCommand (h: THandle);
    procedure   OnDestroy;
    procedure   OnTimer (timerID: DWORD);
    // считывание значения из памяти процесса
    function    ReadValue (v: TValue): string;
    // запись значения Out в память процесса или куда еще
    function    WriteOutVal (const sc, s: string): string;
    // записывание значения в память процесса
    function    WriteValue (v: TValue; const s: string): boolean;
   end;

procedure ReadRct (fs: TIniFile; const sc: string; r: TRct);

implementation
uses Misk, KbdApi, ChPointers;

const
     dclass = 'TrainerWndMain';

var
   g_hfont: HFONT;
   g_phwnd: HWND;
   g_cntr: Integer;
        


procedure ReadRct (fs: TIniFile; const sc: string; r: TRct);
begin
 r.x := fs.ReadInteger(sc, 'x', 10);
 r.y := fs.ReadInteger(sc, 'y', 10);
 r.cx := fs.ReadInteger(sc, 'cx', 100);
 r.cy := fs.ReadInteger(sc, 'cy', 25);
end; // ReadRct


{ TTrainer }

function TTrainer.AddCtrl(const n, t: string; c: TVisControl): TCtrl;
begin
 result := nil;
 if (count >= high (ctrls)) then exit;
 result := TCtrl.Create;
 result.SetVisual (n, t, c); // set visual properties
 if (c = vcValue) or (c = vcArrow) then
     else result.vs := 1;
 // insaving control
 inc (m_count);
 ctrls [m_count] := result;
end; // AddCtrl

constructor TTrainer.Create;
var n: word;
begin
 pl := TProcessArray.Create (1);
 aliased := false;
 mlist.OnWMTimer := nil;
 mlist.OnWMCommand := nil;
 mlist.OnClose := nil;
 mlist.OnDestroy := nil;
 for n := 1 to high (ctrls) do ctrls [n] := nil;
 m_count := 0;
 capt := 'New Trainer';
 rect := TRct.Create;
end; // TTrainer.create

var hArrowCur: HCURSOR;
function WndProcFx (h: HWND; msg, wParam, lParam: DWORD): Integer; stdcall;

var
   defres: LResult;
     wmsg: TMessage absolute msg;

procedure Default;
begin
 defres := DefWindowProc (h, msg, wParam, lParam);
end; // Default

var pobj: ^TMethodList;
       r: TRect;
begin
 // getting trainer object
 defres := 0;
 pobj := nil;
 if (h <> 0) then
   pobj := pointer (GetWindowLong (h, GWL_USERDATA));
 // checking for object is exists
 if pobj = nil then Default
  else // handling messages
 try
   with pobj^ do
   case msg of
      WM_QUIT: DestroyWindow (h);

      WM_TIMER: if (@OnWMTimer <> nil) then OnWMTimer (wParam);
      WM_DESTROY:
       begin
        if (@OnDestroy <> nil) then OnDestroy;
        defres := 0;
       end;
      WM_ERASEBKGND:
       begin
        Default;
        defres := 0;
       end;
      WM_PAINT:
       begin
        GetClientRect (h, r);
        Default;
        ValidateRect (h, @r);
       end;
      WM_COMMAND:
       begin
        if (wmsg.WParamHi = 0) and (@OnWMCommand <> nil) then
                    OnWMCommand (LParam);
        Default;
       end;
      WM_SYSCOMMAND:
       case wParam of
        SC_CLOSE:
          begin
           if (@OnClose <> nil) then OnClose;
           Default;
          end;
        else Default;
       end;
      WM_KEYDOWN:
       begin
        Default;
        if (wParam = VK_TAB) then
            PostMessage (h, WM_NEXTDLGCTL, 0, 0);  
       end;
      WM_MOUSEMOVE:
       if (GetCursor <> hArrowCur) then SetCursor (hArrowCur);
    else Default; // process other messages
   end;
 except
  On EAccessViolation do
     DebugBreak;
 end;
 result := defres;
 if (pobj = nil) then exit;
end; // WndProcFx


procedure TTrainer.CreateCtrls;
var n: dword;
begin
 if hwnd = 0 then exit; // parent window exist
 for n := 1 to count do  ctrls [n].CreateCtrl (hwnd);
end; // CreateCtrls

function TTrainer.CreateWnd(hwndParent: THandle): boolean;
{ Create Window with using Ansi functions }
var
     style, exStyle: dword;
     wclass: TWndClassEx;    // TWndClassExA
     r: TRect;
     rr: TRct;
     cx, cy: word;
begin
 result := false;
 if (hwnd <> 0) then exit;
 FillChar (wclass, sizeof (wclass), 0);
 wclass.cbSize := sizeof (wclass);
 ExStyle := WS_EX_NOPARENTNOTIFY or WS_EX_WINDOWEDGE or WS_EX_APPWINDOW;
 Style := WS_POPUPWINDOW or WS_CAPTION or WS_OVERLAPPED or WS_CLIPCHILDREN;
 // Filling WNDCLASSEXW struct
 if (not GetClassInfoEx (hInstance, dclass, wclass)) then
 begin
  wclass.style := CS_HREDRAW or CS_VREDRAW;
  wclass.lpfnWndProc := @WndProcFx;
  wclass.hInstance := HINSTANCE;
  wclass.hbrBackground := GetSysColorBrush (COLOR_BTNFACE);
  wclass.lpszClassName := dclass;
  wclass.hIcon := LoadIcon (hInstance, 'MAINICON');
  if RegisterClassEx (wclass) = 0 then exit;
 end;
 // Creating window
 hwnd := CreateWindowEx (ExStyle, dclass, PChar (capt), Style,
                         rect.x, rect.y,
                         rect.cx, rect.cy,
                         hWndParent, 0, 0, nil);
 if (hwnd <> 0) then
  begin
   // advance rect size to client rect
   GetClientRect (hwnd, r);
   rr := TRct.Create;
   rr.rect := r;
   // Window to client deviations calc
   cx := abs (rect.cx - rr.cx); // x-deviation
   cy := abs (rect.cy - rr.cy); // y-deviation
   rr.Free;
   g_phwnd := 0;
   g_cntr := 0;
   SetWindowPos (hwnd, HWND_TOP, 0, 0, rect.cx + cx, rect.cy + cy,
                           SWP_NOMOVE);
   SetWindowLong (hwnd, GWL_USERDATA, Integer (@mlist));
   // ShowWindow (hwnd, SW_SHOW);
   result := true;
   SetTimer (hwnd, 100, tmr, nil); // set update timer
   SetTimer (hwnd, 500, 24, nil); // set keyboard timer
   CreateCtrls;
   ShowWindow (hwnd, SW_SHOW);
  end;
End; // TTrainer.CreateWnd

procedure TTrainer.DelCtrl(n: word);
var nn: word;
begin
 if (n > m_count) or (n < 1) then exit;
 ctrls [n].Free;
 for nn := n to m_count - 1 do
     ctrls [nn] := ctrls [nn + 1];
 ctrls [m_count] := nil; // last control := nil;
 Dec (m_count);
end; // TTrainer.DelCtrl

procedure TTrainer.DelCtrls;
var n: word;
begin
 for n := count downto 1 do DelCtrl (n);
end; // DelCtrls

destructor TTrainer.Destroy;
begin
 if (hwnd <> 0) then DestroyWindow (hwnd);
 OnDestroy;
 rect.Free;
 pl.Free;
 DelCtrls; // delete all owned controls
 inherited;
end; // TTrainer Destroy

function TTrainer.FindCtrl(h: THandle): word;
var n: word;
begin
 for n := 1 to count do
  if ctrls [n].hwnd = h then
   begin
    result := n;
    exit;
   end;
 result := 0; // not found
end; // FindCtrl

function TTrainer.FindCtrl (cname: string; start: word): word;
var n: word;
begin
 cname := LowerCase (cname);
 ASSERT (start > 0);
 for n := start to count do
  if pos (cname, LowerCase (ctrls [n].nm)) > 0 then
   begin
    result := n;
    exit;
   end;
 result := 0; // not found
end; // FindCtrl

function TTrainer.FindCtrlTx(text: string; start: word): word;
var n: word;
begin
 text := LowerCase (text);
 for n := start to count do
  if pos (text, LowerCase (ctrls [n].tx)) > 0 then
   begin
    result := n;
    exit;
   end;
 result := 0; // not found
end; // FindCtrlTx

function TTrainer.FindValue(vname: string): word;
var n: word;
begin
 vname := LowerCase (vname);
 result := 0;
 for n := 1 to count do
  if (ctrls [n].ctrl = vcValue) and
     (pos (vname, LowerCase (ctrls [n].nm)) > 0) then
       begin
        result := n;
        exit;
       end;
end; // FindValue

function TTrainer.GetInVal(n: word): string;
var
    c: TCtrl;
    txt: WSTRZ256;
    v, e: Integer;
begin
 { Конечная задача функции вернуть число или текст.

   Функция рассматривает IN у визуальных элементов как текст
   окна, у cValues как адрес. По идее в in должно быть что-то одно.
   Если это случай cValues - значение вычитывается из памяти процесса.
 }
 result := 'WARN: Error Index';
 if (n = 0) or (n > count) then exit;
 result := 'WARN: Рекурсия';
 c := ctrls [n];
 if (c.mark)  then exit;
 c.mark := true;
 // strtok (
 if (c.iv = '') then // используется собственно значение элемента
  begin
   if (c.ctrl = vcValue) then result := ReadValue (c.vv)
    else
     begin
      GetWindowText (c.hwnd, txt, 256);
      txt [255] := #0;
      result := txt;
     end;
  end // read self
 else
  begin
   n := FindCtrl (c.iv); // поиск контрола или значения
   val (StrExt (c.iv), v, e);
   if (e = 0) and (v > e) then result := c.iv; // это число!
   if n <> 0 then result := GetInVal (n) // получить значение рекурсионно
   else
  end;
 c.mark := false;
end; // GetInVal

procedure TTrainer.LoadDesc(const fname: string);

var fs: TIniFile;

function ReadStr (const sc, id: string; lcase: byte = 0): string;
begin
 result := fs.ReadString(sc, id, '""');
 DelChar (result, '"');
 if (lcase <> 0) then result := LowerCase (result);
end; // LoadDesk::ReadStr

var
      st: TStrings;
   sc, s: string;
       n: word;
   cc, c: TVisControl;
    ctrl: TCtrl;
begin
 fs := TIniFile.Create (fname);
 capt := ReadStr ('form', 'caption');
 ReadRct (fs, 'form', rect);
 tmr := fs.ReadInteger('form', 'Timer', 25);
 game := ReadStr ('form', 'process');
 st := TStringList.Create;
 fs.ReadSections(st);
 DelCtrls;
 if st.count > 1 then
 for n := 1 to st.Count - 1 do
  begin
   sc := st [n];
   if LowerCase (s) = 'form' then continue;
   cc := vcArrow;
   s := ReadStr (sc, 'Ctrl', 1);
   for c := vcButton to vcValue do
   if s = LowerCase (CtrlClasses [c]) then cc := c;
   // если ничего не найдено
   if cc = vcArrow then continue;
   // add new control
   ctrl := AddCtrl (sc, ReadStr (sc, 'Text'), cc);
   // read bounds rect
   ReadRct (fs, sc, ctrls [count].rt);
   // read IO directors
   ctrl.iv := ReadStr (sc, 'In');
   ctrl.ov := ReadStr (sc, 'Out');
   if (cc = vcValue) then
    begin
     ctrls [count].ps := valueSet;
     ctrls [count].vv.styp := ReadStr (sc, 'Type');
     ctrls [count].vv.addr := ReadStr (sc, 'Addr');
    end
   else ctrls [count].ps := CtrlSet;
   ctrl.hkey := fs.ReadInteger (sc, 'HotKey', 0);
  end;
 st.Free;
 fs.Free;
end; // LoadDesk

procedure TTrainer.OnCommand;
const
    states: array [false..true] of dword =
     (BST_UNCHECKED, BST_CHECKED);

var
    n: word;
    rw: dword;
    sv, iv, ov: string;
    c: TCtrl;
begin
 n := FindCtrl (h);
 if (n = 0) then exit;
 iv := LowerCase (ctrls [n].iv);
 ov := LowerCase (ctrls [n].ov);
 c := ctrls [n];
 if (c.ctrl = vcCheckBox) then
  begin
   c.trig := not c.trig;
   SendMessageTimeOut (ctrls [n].hwnd, BM_SETCHECK, states [c.trig], 0,
                SMTO_ABORTIFHUNG, 100, rw);
   if c.trig then
    begin
     c.iv := c.ov;
     c.iv := GetInVal (n); // получить текущее значение
    end;
   exit;
  end;
 // checking function call
 if (pos ('()', ov) > 0) then
  begin
   if (pos ('close', ov) > 0) then
         PostQuitMessage (0);
  end;
 // копирование
 if (ov = '') then exit; // некуда писать
 sv := GetInVal (n);     // получить исходное значение
 WriteOutVal (ov, sv);   // записать значение в приемник
end; // OnCommand

procedure TTrainer.OnDestroy;
var n: word;
begin
 if (hwnd = 0) then exit;
 for n := 1 to count do
     ctrls [n].DestroyCtrl;
 SetWindowLong (hwnd, GWL_USERDATA, 0); // deassotiate with data
 if not IsWindow (hwnd) then UnregisterClass (dclass, hInstance);
 hwnd := 0;
end; // OnDestroy


procedure TTrainer.OnHotKeysTest;
var flags: word;
    n: dword;
    pkey: PHotKeyRec;    
begin
 flags := GetShiftStateFlags;
 for n := 1 to count do
 if ctrls [n].hkey <> 0 then
  begin
   pkey := @ctrls [n].hkey;
   if IsPressed (pkey.key) and (flags = pkey.flags) then    
     begin
      if not ctrls [n].AlreadyPressed then PokeValue (n);
      ctrls [n].AlreadyPressed := true; // Предотвращение частого повторения
     end else ctrls [n].AlreadyPressed := false;
  end;
end;// On HotKeyTest

procedure TTrainer.OnTimer;

begin
 if 100 = timerID then OnUpdateUI; // обновление и заморозка
 if 500 = timerID then OnHotKeysTest;
end; // TTrainer.OnTimer

procedure TTrainer.OnUpdateUI;
const acst: array [false..true] of string =(' ', ' [Ready]');
var   code: dword;
      n, nn: word;
       s: string;
       p: WSTRZ256;

begin
 s := capt + acst [aliased];
 GetWindowText (hwnd, p, 255);
 if p <> s then SetWindowText (hwnd, PChar (s));
 // uploading all controls with rAction = OnTimer
 if aliased and (hAlias <> 0) then
 if GetExitCodeProcess (hAlias, code) and (code <> STILL_ACTIVE) then
  begin
   aliased :=  false;
   CloseHandle (hAlias);
   hAlias := 0;
  end;
 nn := 0;
 repeat
  // поиск субстрочных контролов
  n := FindCtrlTx ('%s', nn + 1);
  nn := n + 1;
  if (n > 0) then
  begin
   if aliased then s := GetInVal (n) else s := 'n/a';
      ctrls [n].FormatText (s); // форматировать текст контрола
  end;
 until n = 0;
 // обеспечение полной заморозки значения
 if aliased then
 for n := 1 to count do
  if ctrls [n].trig then PokeValue (n);
  // if (code = 0) then exit;
  // Ods (GetInVal (code));
 if not aliased then OpenPrcs;
end; // OnUpdateUI

procedure TTrainer.OpenPrcs;
var n: dword;
begin
 if game = '' then exit; // нечего открывать
 n := pl.FindByFile (game, true);
 if n = 0 then exit; // нет процесса в памяти
 pid := pl.items [n].th32ProcessID;
 hAlias := OpenProcess (PROCESS_VM_OPERATION or
                        PROCESS_QUERY_INFORMATION or
                        PROCESS_VM_READ or PROCESS_VM_WRITE, false, pid);
 aliased := hAlias <> NULL;
 (dsrc as TProcessSrc).hProcess := hAlias;
end; // OpenPrcs

function TTrainer.PokeValue(n: word): boolean;
var s: string;
begin
 result := false;
 if not aliased then exit;
 s := GetInVal (n);
 result := WriteOutVal (ctrls [n].ov, s) <> '';
end;

function TTrainer.ReadValue(v: TValue): string;
var
    n: dword;
begin
 result := '0'; // default
 n := TypeOrd (v.styp);
 if n = 0 then exit; // unrecoginzed type
 if not aliased then
  begin
   result := 'n/a';
   exit;
  end;
 result := ReadProcessValue (DecodePtr (hAlias, v.addr), n);
end; // ReadValues

procedure TTrainer.SaveDesc(fname: string);
var
   fs: TIniFile;
   sect: string;

procedure  SaveInt (const id: string; i: Int64);
begin
 fs.WriteString (sect, id, IntToStr (i));
end; // SaveStr

procedure   SaveHex (const id: string; d: dword);
begin
 fs.WriteString(sect, id, '$' + dword2hex (d));
end;

procedure  SaveStr (const id, vl: string);
begin
 fs.WriteString (sect, id, '"' + vl + '"');
end; // SaveStr

procedure SaveRect (const r: TRct);
begin
 fs.WriteInteger (sect, 'x', r.x);
 fs.WriteInteger (sect, 'y', r.y);
 fs.WriteInteger (sect, 'cx', r.cx);
 fs.WriteInteger (sect, 'cy', r.cy);
end; // SaveRect

procedure SaveCtrl (const ctl: TCtrl);
// var sc: string;
begin
 sect := ctl.nm;
 if (sect = '') then exit;
 // string control class name
 SaveStr ('Ctrl', CtrlClasses [ctl.ctrl]);
 // if used - save caption/text
 if (prText in ctl.ps) then SaveStr ('Text', ctl.tx);
 SaveRect (ctl.rt);  // save bounds rect
 if (prInOut in ctl.ps) then 
  begin
   SaveStr ('In', ctl.iv);
   SaveStr ('Out', ctl.ov);
  end;
 if (prType in ctl.ps) then SaveStr ('Type', ctl.vv.styp);
 if (prAddr in ctl.ps) then SaveStr ('Addr', ctl.vv.addr);
 if (prHotKey in ctl.ps) then
                        SaveHex ('HotKey', ctl.hkey);
end;  // SaveCtrl

var
   n: word;
   h: HFILE;
begin
 //
 if (pos ('.ttd', lowerCase (fname)) = 0) then
        fname := fname + '.ttd';
 h := CreateFile (PChar (fname), GENERIC_WRITE, FILE_SHARE_DELETE, nil,
                        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
 if (h = 0) then exit else CloseHandle (h);                        
 fs := TIniFile.Create (fname);
 // сохранение формы
 sect := 'Form';
 SaveStr ('Caption', capt);
 SaveRect (rect);
 SaveInt ('Timer', tmr);
 SaveStr ('Process', game);
 // saving all controls
 for n := 1 to count do SaveCtrl (ctrls [n]);
 fs.UpdateFile;
 fs.Free;
end; // Save Trainer Description

function TTrainer.WriteOutVal (const sc, s: string): string;
var c: TCtrl;
    tok, ss: string;
    nn, fop, i, e: Integer;
    n: word;
begin
 // Tokenization
 ss := sc;    // возможно что это выражение
 DelChar (ss, ' '); // убрать пробелы
 nn := 0;
 fop := 0;  // ни какой операции
 tok := ss; // чисто пин лишенный пробелов
 if (pos ('+', ss) > 0) then
  begin
   tok := StrTok (ss, nn, ['+']);
   fop := 1; // что-то добавиться
  end;
 if (pos ('-', ss) > 0) then
  begin
   tok := StrTok (ss, nn, ['-']);
   fop := -1; // что-то вычтется
  end;
 n := FindCtrl (tok);           // поиск похожего контрола
 result := 'WARN: Not found ctrl';
 if (n = 0) then exit;          // нет контрола, ладно
 c := ctrls [n];                // make alias
 result := 'WARN: Recursion loop';
 if c.mark then exit;
 c.mark := true;                // mark for prevent recursion loop
 if n = 0 then exit;
 if (nn < Length (ss)) and (fop <> 0) then
  begin // таки это выражение со знаком плюсъ
   tok := StrTok (ss, nn, [' ']); // взять строку до конца
   val (StrExt (tok), i, e);      // сразу в число
   if fop < 0 then i := -i;       // отрицательное...
   val (StrExt (s), fop, e);      // исходное
   ss := IntToStr (fop + i);      // теперь все вместе!
  end else ss := s;               // по умолчанию
 if c.ctrl = vcValue then         // не должно быть других дренажей
  begin
   if WriteValue (c.vv, ss) then result := ss; // без приключений
  end
 else result := WriteOutVal (c.ov, ss); // using recursion
 c.mark := false;
end; // WriteOutVal

function TTrainer.WriteValue(v: TValue; const s: string): boolean;
var
    n: dword;
begin
 result := false; // default
 n := TypeOrd (v.styp);
 if n = 0 then exit; // unrecoginzed type
 if not aliased then exit; 
 result := WriteProcessValue (DecodePtr (hAlias, v.addr), n, s);
end; // WriteValue

{ TCtrl }


constructor TCtrl.Create;
begin
 rt := TRct.Create;
 trig := false;
 mark := false; // используется для предотвращения рекурсии
 hwnd := 0;
 vs := 0;
end; // TCtrl.Create

procedure TCtrl.CreateCtrl(hwndParent: THandle);
var
     style, exStyle: dword;
     nErr: LongInt;
     wclass: ASTRZ256;
begin
 err := '';
 if (ctrl = vcArrow) or (ctrl = vcValue) then exit;
 if (hwnd <> 0) then exit;
 ExStyle := 0;
 Style := WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS;
 if (ctrl = vcLabel) then _or (style, SS_LEFTNOWORDWRAP or SS_NOPREFIX)
  else _or (style, WS_TABSTOP);
 if (ctrl = vcEdit) then _or (style, WS_BORDER or ES_LEFT);
 if (ctrl = vcButton) then _or (style, BS_PUSHBUTTON or BS_TEXT);
 // TODO: adding from visual styles
 // Creating window
 StrPCopy (wclass, UpperCase (CtrlClasses [ctrl]));
 if (ctrl = vcCheckbox) then
  begin
   // исключение из правила
   StrPCopy (wclass, 'Button');
   _or (style, BS_CHECKBOX);
  end;
 SetLastError (0);
 {$R-}
 hwnd := CreateWindowExA (ExStyle,
                         @wclass,
                         PAnsiChar (tx), Style,
                         rt.x, rt.y,
                         rt.cx, rt.cy,
                         hWndParent, 0, 0, nil);
 nErr := GetLastError;
 if (not IsWindow (hwnd)) then
  begin
   hwnd := 0;
   err := SysErrorMessage (nErr);
   MessageBoxA (hwndParent, PAnsiChar (err), wclass, MB_OK or MB_ICONERROR);
  end
 else
  begin
   PostMessage (hwnd, WM_SETFONT, g_hfont, 0);
   SetWindowPos (hwnd, g_phwnd, 0, 0, 0, 0,
                 SWP_NOSIZE or SWP_NOMOVE);
   SetWindowLong (hwnd, GWL_ID, 100 + g_cntr);
   Inc (g_cntr);
   g_phwnd := hwnd;
  end;
end; // CreateCtrl

destructor TCtrl.Destroy;
begin
 rt.Free;
 if hwnd <> 0 then DestroyWindow (hwnd);
 inherited;
end; // Destroy

procedure TCtrl.DestroyCtrl;
begin
 if hwnd <> 0 then DestroyWindow (hwnd);
 hwnd := 0;
end; // DestroyCtrl

procedure TCtrl.FormatText(const s: string);
var ss: string;
    pp: WSTRZ256;
begin
 if hwnd = 0 then exit;
 ss := Format (tx, [s]);
 GetWindowText (hwnd, pp, 255);
 if ss <> pp then SetWindowText (hwnd, PChar (ss));
end; // FormatText;

procedure TCtrl.SetVisual(const n, t: string; c: TVisControl);
begin
 nm := n;   // name of control
 tx := t;   // text caption
 ctrl := c; // type of control
end; // SetVisual

var
   lf: tagLOGFONTA;
initialization
 hArrowCur := LoadCursor (NULL, IDC_ARROW);
 FillChar (lf, sizeof (lf), 0);
 lf.lfHeight := 8;
 lf.lfWeight := 400; // default
 lf.lfCharSet := RUSSIAN_CHARSET;
 StrPCopy (lf.lfFaceName, 'MS Sans Serif');
 g_hFont := CreateFontIndirectA (lf);
finalization
 DeleteObject (g_hFont); 
end.
