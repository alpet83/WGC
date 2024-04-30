unit ChTrain;
interface
{
  Конструктор трейнеров.
  Эта система в основном состоит из редактора форм трейнера, позволяющего
  создать произвольный интерфейс для любого трейнера. Все функции конструктора
  сходны с конструктором форм Delphi.
  Базовые функции конструктора: добавление на форму компонентов и связывание их
  с некоторыми значениями-адресами внутри процесса.
  Пока доступны след. компоненты: Button, Static, Edit.


  Основные задачи - фокусировка на любом контроле, отрисовка границ точками,
  возможность перемещения контрола и изменение его размера.
  Отображение главных свойств контрола, связывание с значением.
  Каждому контролу назначаются два свойства - in, out которые могут
  назначатся как на другие контролы, так и на значения в игре.

}


uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, Grids, ValEdit, ImgList, Menus,
  ComCtrls, gtrainer, rects, ChTypes, HotKeyDlg;

type

    TActMode = (amMoveCtrl, amSizeCtrl, amNone);


type
  TFormConstructor = class(TForm)
    btnHide: TButton;
    vledit: TValueListEditor;
    cbar: TControlBar;
    stdpan: TPanel;
    btnNew: TSpeedButton;
    btnOpen: TSpeedButton;
    btnSave: TSpeedButton;
    tcMainMenu: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    miExit: TMenuItem;
    N3: TMenuItem;
    miOpen: TMenuItem;
    miNew: TMenuItem;
    miSave: TMenuItem;
    ctrlpallete: TPanel;
    btnNewButton: TSpeedButton;
    btnNewLabel: TSpeedButton;
    btnNewEdit: TSpeedButton;
    btnArrow: TSpeedButton;
    cbControls: TComboBox;
    outpan: TPanel;
    mhandler: TMemo;
    btnDel: TButton;
    status: TStatusBar;
    cbGrid: TCheckBox;
    btnNewValue: TSpeedButton;
    odlg: TOpenDialog;
    sdlg: TSaveDialog;
    btnTest: TButton;
    miSaveAs: TMenuItem;
    btnNewCheckBox: TSpeedButton;
    procedure btnHideClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnNewButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbControlsSelect(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure outpanResize(Sender: TObject);
    procedure vleditSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure vleditExit(Sender: TObject);
    procedure vleditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure mhandlerKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure mhandlerKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnDelClick(Sender: TObject);
    procedure cbGridClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure miSaveAsClick(Sender: TObject);
    procedure vleditEditButtonClick(Sender: TObject);
  private
    { Private declarations }
    fsaved: Boolean;
    m_hkey: THotKeyData;
    function FCRect: TRect;
    function AddControl(vt: TVisControl; vs: Integer;
      pt: TPoint): boolean;
    procedure ListControls;

    // Drawing routines
    procedure    DrawAll(id: dword = 0);
    procedure    DrawCtrl (var cnv: TCanvas; n: dword);
    procedure    DrawDialog;
    procedure    DrawFocused(var cnv: TCanvas);
    // Control routines
    procedure    DeleteCtrl (n: word);
    procedure    FocusControl(n: word); overload;
    procedure    MoveControl(x, y, state: dword);
    procedure    MoveRel(dx, dy: Integer);
    procedure    PlaceControl(pt: TPoint);
    procedure    ResizeRel(dx, dy: Integer);
    procedure    ResizeControl(x, y, state: dword);
    // other routines
    function     InDlg (xp, yp: word): boolean; overload;
    function     InDlg (pt: TPoint): boolean; overload;
    procedure    MsMove (x, y, state: dword);
    function     FindHitCtrl(const pt: TPoint): dword;
    procedure    CtrlHitTest(pt: TPoint);
    procedure    DlgHitTest(pt: TPoint);   
    procedure    OnEdit;
    function     FocusedRect: PRct;
    procedure    Descript;
    procedure    OnStateChange (dw: dword);
  protected
    { Protected declarations }
    // some unused functions
  public
    { Public declarations }
        pdlg: TTrainer;     // форма-диалог трейнера
    nFocused: word;        // выбранный контрол
    clipRect: TRect;
    fRepaint: boolean;     // флаг полной перерисовки 
     fMoving: Boolean;     // режим перемещения
         spt: TPoint;      // точка клика (события WM_LBUTTONDOWN)
         ofs: TPoint;      // точка относительного попадания в контрол
         lpr: PRct;
        buff: TBitmap;     // буфер для рисования
       ptdlg: TPoint;      // точка начала диалога от начала формы
     hitmask: Dword;       // маска попадания
      hitObj: dword;       // обьект попадания
       amode: TActMode;    // текущий режим
        lact: TActMode;    // последнее действие
      ostate: TShiftState; // предыдущее состояние
       owndp: TWndMethod;
      msgcnt: dword;
      oldmvp: Integer;
     fileName: string;     // имя файла трейнера
    procedure    WndProcOver (var wmsg: TMessage);
    procedure    LBDown (x, y: dword);
    procedure    LoadEditor; // Загрузка свойств в редактор
   public
    // engine test functions 
   end;

var
  hdlg: HWND;

  FormConstructor: TFormConstructor = nil;




implementation

uses ChForm, misk, IniFiles, ChShare, ChCodes, ChClient;

const
     hitNone = 0;
     hitLeft = 1;
     hitTop = 2;
     hitRight = 4;
     hitBottom = 8;
     hitLeftTop = hitLeft or hitTop;
     hitLeftBottom = hitLeft or hitBottom;
     hitRightTop = hitRight or hitTop;
     hitRightBottom = hitRight or hitBottom;
     hitItem = $10;
     
     objDlg = $1000; // обьект попадания - диалог
var
    DEF_EDTSTYLE: dword = WS_TABSTOP or ES_LEFT or WS_BORDER;
    DEF_BTNSTYLE: dword = BS_PUSHBUTTON or WS_TABSTOP or BS_NOTIFY;
    DEF_LBLSTYLE: dword = WS_TABSTOP or SS_LEFT or SS_NOTIFY or SS_NOPREFIX or WS_BORDER;
{$R *.dfm}
var
   mwnd: THandle = 0;
   DlgOfsX: Word = 100;
   DlgOfsY: Word = 50;
   vctrl: TVisControl = vcArrow;


procedure Limitate (var v: word; max: dword);
begin
 if (v > max) then v := max;
end;

procedure ExtRect (var r: TRect; delta: Integer);
// delta > 0 = увеличение, delta < 0 = уменьшение
begin
 Dec (r.Left, delta);
 Dec (r.Top, delta);
 Inc (r.Right, delta);
 Inc (r.Bottom, delta);
end; // ExtRect;

procedure ExpandRect (var r: TRect; const rr: TRect);
// creating rect over 2 rect
begin
 r.Left := min (r.left, rr.Left);
 r.top := min (r.Top, rr.top);
 r.Right := max (r.Right, rr.Right);
 r.Bottom := max (r.Bottom, rr.Bottom);
end; // ExpandRect

function  RCvt (const r: TRct): TRect;
begin
 result.Left := r.x;
 result.Top := r.y;
 result.Right := r.x + r.cx;
 result.Bottom := r.y + r.cy;
end; // RCvt

function  InRct (const pt: TPoint; const r: TRct): boolean;
begin
 result := (r.x <= pt.x) and (pt.x <= r.x + r.cx) and
           (r.y <= pt.y) and (pt.y <= r.y + r.cy);
end; // InRct


procedure TFormConstructor.btnHideClick(Sender: TObject);
begin
 Hide;
end;

procedure  SetBtnImage (var btn: TSpeedButton; index: Dword);
var
   img: TBitmap;
begin
 img := TBitmap.Create;
 mform.toolbarImages.GetBitmap (index, img);
 btn.Glyph := img; // запомнить image
 // img.Free;
end;

function  TFormConstructor.FindHitCtrl (const pt: TPoint): dword;
var n: dword;
begin
 // функция определения контрола в точке
 result := objDlg; // по умолчанию форма
 with pdlg do
 for n := 1 to count do
  if InRct (pt, ctrls [n].rt) then
   begin
    result := n;
    exit;
   end;
end; // FindHitCtrl

function  TFormConstructor.FCRect: TRect;
begin
 result := Bounds (outpan.left, outpan.top, outpan.Width, outpan.Height);
{ SetRect (result,
                  , vledit.Top  + vledit.Height); {}
 if (pdlg = nil) then exit;
 ptdlg := result.TopLeft;
 inc (ptdlg.X, pdlg.rect.x);
 inc (ptdlg.Y, pdlg.rect.Y);
end;

procedure TFormConstructor.DrawAll;
var
   rct: TRect;
   cnv: TCanvas;
   cdc: TCanvas;
   rgn: HRGN;
begin
 cdc := TCanvas.Create;
 cdc.Handle := GetWindowDC (outpan.Handle);
 // Прорисовка всех элементов в буфере
 with buff, buff.canvas do
  begin
   cnv := buff.canvas;
   rct := FCRect;
   OffsetRect (rct, -rct.Left, -rct.Top); // в координаты буфера
   if (fRepaint) then
    begin
     SetRect (self.clipRect, 0, 0, buff.width, buff.height); 
     Brush.Color := clGray;
     Rectangle(rct);
    end;
   DrawDialog; // нарисовать диалог
  end;
  // Отображение на форму
  rgn := CreateRectRgnIndirect (self.clipRect);
  ExtSelectClipRgn (cdc.handle, rgn, RGN_COPY);
  cdc.CopyRect(rct, cnv, rct); // копировать изображение
  ExtSelectClipRgn (cdc.handle, rgn, RGN_DIFF);
  cdc.Brush.Style := bsClear;  // Добавочная рамка
  cdc.Rectangle (rct);
  rct := FCRect;
  ReleaseDC (outpan.Handle, cdc.Handle);
  DeleteObject (rgn);   // release region
  ValidateRgn (outpan.Handle, 0);
  cdc.Handle := 0;
  cdc.Free;     // release canvase
  fRepaint := false;
end; // DrawAll

procedure TFormConstructor.DrawFocused (var cnv: TCanvas);
var
       r: TRect;
      hw, hh: dword;

procedure BigPoint (x, y: word);
var rr: TRect;
begin
 SetRect (rr, x - 2, y - 2, x + 2, y + 2);
 cnv.FillRect(rr);
end; // BigPoint

begin
 if (nFocused = 0) then exit;
 // прорисовка точек у выбранного контрола
 r := RCvt (pdlg.ctrls [nFocused].rt);
 with pdlg.rect do OffsetRect (r, x, y);
 // Рисование точек с внешней стороны
 cnv.Brush.Color := $A0;
 cnv.Brush.Style := bsSolid;
 hw := (r.Left + r.Right) shr 1;
 hh := (r.bottom + r.Top) shr 1;
 BigPoint (r.Left, r.Top);      // 1, 1
 BigPoint (hw, r.Top);          // 2, 1
 BigPoint (r.Right, r.Top);     // 3, 1
 BigPoint (r.Right, hh);        // 3, 2
 BigPoint (r.Right, r.Bottom);  // 3, 3
 BigPoint (hw, r.Bottom);       // 2, 3
 BigPoint (r.Left, r.Bottom);   // 1, 3
 BigPoint (r.Left, hh);         // 1, 2
end; // DrawFocused

procedure       TFormConstructor.DrawCtrl (var cnv: TCanvas; n: dword);
var r, rr: TRect;
    af: dword;
    ay: Integer;
    bkcl: COLORREF;
begin
 // DrawCtrl
 with pdlg, pdlg.ctrls [n] do
  begin
   r := RCvt (rt);
   af := 0;
   SetBkMode (cnv.handle, OPAQUE);
   cnv.font.Color := clWindowText;
   cnv.font.Size := 9;
   bkcl := GetSysColor (COLOR_BTNFACE); // default face color
   SetBkColor (cnv.handle, bkcl);
   OffsetRect (r, rect.x, rect.y);
   if (ctrl = vcButton) then
    begin
     DrawFrameControl (cnv.Handle, r, DFC_BUTTON, DFCS_BUTTONPUSH);
     af := DT_CENTER or DT_VCENTER;
    end;
   if (ctrl = vcEdit) then
    begin
     af := DT_VCENTER;
     bkcl := GetSysColor (COLOR_WINDOW);
     cnv.Brush.Color := bkcl;
     cnv.Brush.Style := bsSolid;
     cnv.Pen.Color := clGray;
     cnv.Rectangle (r);
     inc (r.Left, 4);
    end;
   if (ctrl = vcCheckBox) then
    begin
     cnv.Pen.Color := $201010;   // dark blue
     cnv.Brush.Color := clWindow;  // for center
     cnv.Brush.Style := bsSolid;
     ay := ((r.Bottom - r.Top) - 13);
     if (ay > 0) then ay := ay shr 1 else ay := 0;
     SetRect (rr, r.Left, r.Top + ay, r.Left + 13, r.Top + 13 + ay);
     DrawFrameControl (cnv.Handle, rr, DFC_BUTTON, DFCS_BUTTONCHECK);
     af := DT_VCENTER;
     // cnv.Rectangle(rr);
     r.Left := r.left + 16;
    end;
   // adding
   SetBkColor (cnv.handle, bkcl);
   DrawText (cnv.handle, PAnsiChar (tx), Length (tx), r,
                DT_SINGLELINE or af);
  end;
end;

procedure       TFormConstructor.DrawDialog;
var
   cnv: TCanvas;
   rct, r: TRect;
   x, y, w, h: dword;
   xc, yc: dword;
   rgn: HRGN;
begin
 if (pdlg = nil) then exit;
 //  Прорисовка диалога
 cnv := buff.canvas;
 rgn := CreateRectRgnIndirect (ClipRect);
 SelectClipRgn (cnv.handle, rgn);
 DeleteObject (rgn);
 with pdlg.rect do
 if (cx < 100) then cx := 100;
 rct := RCvt (pdlg.rect);
 cnv.Brush.Color := clBtnFace;
 cnv.Brush.Style := bsSolid;
 cnv.Pen.Color := clBlack;
 cnv.Pen.Style := psSolid;
 cnv.FillRect (rct);
 r := rct;
 Dec (r.top, 25);
 r.bottom := r.top + 25;
 ExtRect (r, 1);

 // OffsetRect (r, 0, 0);
 SetLastError (0);
 cnv.brush.Color := clActiveCaption;
 cnv.Rectangle (r);
 DrawCaption (handle, cnv.handle, r, DC_ACTIVE or DC_ICON);
 // SetTextColor (cnv.handle, GetSysColor ();
 cnv.brush.Style := bsClear;
 cnv.Rectangle (r);
 inc (r.left, 32);
 cnv.Font.Color := clWindowText;
 cnv.Font.Name := 'MS Sans Serif';
 cnv.Font.Size := 11;
 // Drawing dialog caption
 DrawText (cnv.handle, pchar (pdlg.capt), Length (pdlg.capt), r,
                                        DT_SINGLELINE or DT_VCENTER);
 OffsetRect (r, -1, -1);
 cnv.Font.Color := clCaptionText;
 DrawText (cnv.handle, pchar (pdlg.capt), Length (pdlg.capt), r,
                                        DT_SINGLELINE or DT_VCENTER);
 w := rct.Right - rct.Left; // width
 h := rct.Bottom - rct.top; // height
 DrawFrameControl (cnv.Handle, rct,
        DFC_BUTTON, DFCS_BUTTONPUSH);
 xc := w div 10;
 yc := h div 10;
 if cbGrid.checked then
 with pdlg do
 for y := 1 to yc do
 for x := 1 to xc do
      cnv.Pixels [rect.x + x * 10, rect.y + y * 10] := clBlack;
 rgn := CreateRectRgn (rct.left + 2, rct.top + 2,
                        rct.Right - 2, rct.Bottom - 2);
 dec (rct.left);
 dec (rct.top);
 inc (rct.Right);
 inc (rct.Bottom);
 cnv.Brush.Style := bsClear;
 cnv.Rectangle (rct);
 ExtSelectClipRgn (cnv.Handle, rgn, RGN_AND);
 // Нарисовать контролы
 for x := 1 to pdlg.count do DrawCtrl (cnv, x);
 DrawFocused (cnv);
 ExtSelectClipRgn (cnv.Handle, rgn, RGN_DIFF);
 DeleteObject (rgn);
end; // DrawDialog

procedure TFormConstructor.FormCreate(Sender: TObject);
var
   r: TRect;

begin
 msgcnt := 0;
 fileName := '';
 pdlg := TTrainer.Create;
 fRepaint := true;
 // fsiz := sizeof (TFormDesc);
 // GetMem (pdlg, fsiz); // 256 controls limit
 r := FCRect;
 buff := TBitMap.Create;
 buff.Width := r.Right - r.Left;
 buff.Height := r.Bottom - r.Top;
 buff.PixelFormat := pf32bit;
 // Назначение картинок кнопкам
 SetBtnImage (btnNew, 0);
 SetBtnImage (btnOpen, 1);
 SetBtnImage (btnSave, 2);

 pdlg.capt := 'New Trainer';
 // координаты от начала буфера
 pdlg.rect.SetRect (50, 50, 250, 150);
 owndp := outpan.WindowProc;
 outpan.WindowProc := WndProcOver;
 mhandler.Width := 0; // сделать невидимым
 nFocused := 0;
 BtnNewClick (self);
 m_hkey := THotKeyData.Create('', 0, 0);
 fSaved := true;
 // hdlg := 0;
end;

function TFormConstructor.AddControl;
var
   s, ss: string;
   n, i: dword;
   fe: boolean;
   ctrl: TCtrl;
begin
 with pdlg do
  begin
   s := CtrlNames [vt];
   n := 1;
   // Назначение номера контролу
   repeat
    fe := false;
    ss := s + IntToStr (n);
    for i := 1 to count do
        fe := fe or (ss = ctrls [i].nm);
    inc (n);
   until not fe or (n >= MaxControl);
   result := (count < MaxControl);
   if not result then exit;
   // попытка добавления контрола
   ctrl := pdlg.AddCtrl (ss, ss, vt);
   if ctrl = nil then exit;
   
   if vt = vcValue then
     begin
      ctrl.ps := ValueSet;
      ctrl.vv.styp := 'DWORD';
     end
   else ctrl.ps := CtrlSet;
   ctrl.rt.SetRect(pt.x, pt.y, 100, 24); // pos & default size
  end;
end;

procedure TFormConstructor.ListControls;
var n: dword;
begin
 with cbControls, cbControls.Items, pdlg do
  begin
   BeginUpdate;
   Clear;
   Add ('Form');
   for n := 1 to count do Add (ctrls [n].nm);
   if (nFocused < items.count) then ItemIndex := nFocused
    else ItemIndex := items.count - 1;
   EndUpdate;
  end;
end;


procedure TFormConstructor.FocusControl (n: word);

begin
 OnEdit;
 if (nFocused = n) then exit;
 nFocused := n and $FF;
 cbControls.ItemIndex := nFocused;
 LoadEditor;
 DrawAll (0);
end; // FocusControl

procedure TFormConstructor.PlaceControl (pt: TPoint);
var
    ptx: WSTRZ256;
    wst: Integer;
begin
 pt.x := pt.x div 10 * 10;
 pt.Y := pt.y div 10 * 10;
 if vctrl <> vcArrow then
  begin
   wst := DEF_LBLSTYLE;
   case vctrl of
      vcEdit: wst := DEF_EDTSTYLE;
    vcButton: wst := DEF_BTNSTYLE;   
   end;
   wst := wst or WS_VISIBLE or WS_CHILD;
   StrPCopy (ptx, 'Text');
   if AddControl (vctrl, wst, pt) then DrawAll (1) else exit;
   btnArrow.Click;
   btnArrow.Down := true;
   ListControls;
  end;
end; // PlaceControl

procedure TFormConstructor.btnNewButtonClick(Sender: TObject);
var
    sbtn: TSpeedButton;
begin
 if (sender is TSpeedButton) then sbtn := (sender as TSpeedButton) else exit;
 if (sbtn = btnArrow) then vctrl := vcArrow;
 if (sbtn = btnNewButton) then vctrl := vcButton;
 if (sbtn = btnNewCheckBox) then vctrl := vcCheckBox;
 if (sbtn = btnNewEdit) then vctrl := vcEdit;
 if (sbtn = btnNewLabel) then vctrl := vcLabel;
 if (sbtn = btnNewValue) then vctrl := vcValue;
end;

var lhw: THandle = 0;

procedure TFormConstructor.FormShow(Sender: TObject);
begin
 // CreateDlg;
 // ShowWindow (outpan.Handle, SW_HIDE);
 DrawAll (3);
end;

procedure TFormConstructor.DeleteCtrl(n: word);
begin
 nFocused := 0;
 pdlg.DelCtrl (n); // delete control from list
 OnStateChange (7);
end; // DeleteCtrl

procedure TFormConstructor.cbControlsSelect(Sender: TObject);
begin
 FocusControl (cbControls.ItemIndex);
end;

procedure TFormConstructor.FormDestroy(Sender: TObject);
begin
 outpan.WindowProc := owndp;
 if not fSaved then
  if MessageBox (handle, 'Файл трейнера был не сохранен. Сохранить?',
                 'Конструктор трейнеров', MB_YESNO or MB_ICONQUESTION) = IDYES
                 then  btnSaveClick (self);             
 m_hkey.Free;
 pdlg.Free;  // memory release
 pdlg := nil;
end;

function TFormConstructor.InDlg (xp, yp: word): boolean;
begin
 FCRect;
 with pdlg.rect do
  begin
   dec (xp, x);
   dec (yp, y);
   result := (xp <= cx) and (yp <= cy);
 end;
end; // InDlg

function TFormConstructor.InDlg(pt: TPoint): boolean;
begin
 result := InDlg (pt.x, pt.y);
end;

procedure TFormConstructor.WndProcOver(var wmsg: TMessage);

begin
 // Subclassing for outpan
 clipRect := Rect (0, 0, buff.Width, buff.Height);
// OffsetRect (clipRect, 0, 0);
 lact := amNone;
 lpr := nil;
 wmsg.Result := 0;
 inc (msgcnt);
 if (pdlg = nil) or not visible then
  begin
   owndp (wmsg);
   exit;
  end;
 with wmsg do
 case msg of
  WM_MOUSEMOVE:
   begin
    if oldmvp <> LParam then MsMove (LParamLo, LParamHi, WParam);
    oldmvp := LParam;
   end;
  WM_LBUTTONDOWN:
   begin
    LBdown (LParamLo, LParamHi);
   end;
  WM_LBUTTONUP:
    begin
     if amode <> amNone then LoadEditor; // перезагрузить данные
     ReleaseCapture;
    end;
  WM_PAINT:
   begin
    //lbMsgs.Items.Add ('WMPaint');
    GetUpdateRect (outpan.Handle, clipRect, false);
    DrawAll (4);
   end;
  WM_NCPAINT:; 
  WM_NCHITTEST: wmsg.Result := HTCLIENT;
  WM_NCLBUTTONDOWN: wmsg.Result := 0;
  else
   begin
    owndp (wmsg); // old handler
   end;
 end;
 Descript;        
end; //

procedure TFormConstructor.Descript;
var s: string;
begin
 if (lact = amSizeCtrl) then
  begin
   if (lpr <> nil) then s := format (': cx=%d, cy=%d', [lpr.cx, lpr.cy]);
   status.panels [1].text := 'sizing' + s;
  end else
 if (lact = amMoveCtrl)then
   begin
    if (lpr <> nil) then s := format (': x=%d, y=%d', [lpr.x, lpr.y]);
    status.panels [1].text  := 'moving' + s
   end;
end;

procedure TFormConstructor.LBDown(x, y: dword);
var r: PRct;
    f: boolean;
begin
 amode := amNone;
 SetCapture (outpan.handle);
 // LBdown
 spt.x := x - pdlg.rect.x;
 spt.y := y - pdlg.rect.y;
 f := InDlg (x, y);
 // Если в поле контрол или форма - в режим рисайза
 if (hitObj <> 0) and (hitMask and $F <> 0) then amode := amSizeCtrl;
 if (hitObj and $FF <> 0) and (hitMask = hitItem) then
  begin
   amode := amMoveCtrl;
   // расчет точки попадания.
   r := @pdlg.ctrls [hitobj].rt;
   ofs.x := spt.x - r.x;
   ofs.y := spt.y - r.y;
  end;
 if (f) then mhandler.SetFocus;
 if (amode <> amSizeCtrl) and (hitObj <> 0) and f then
  begin
   if (hitObj = ObjDlg) then
    begin
     PlaceControl (spt);
     FocusControl (0);    // пока ничего не выбрано
    end
   else FocusControl (hitObj);
  end;
 // lbMsgs.Items.Add ('LButton Down');
end;

procedure TFormConstructor.DlgHitTest (pt: TPoint);
var rb: TPoint;
begin
 hitMask := 0;
 hitObj := 0; // по умолчанию не выбрано ничего
 // Поиск контрола в текущей точке
 hitObj := FindHitCtrl (pt);
 if (hitObj and $FF <> 0) then _or (hitMask, hitItem);  
 // предельная точка диалога
 rb.X := pdlg.rect.cx - 5;
 rb.y := pdlg.rect.cy - 5;
 if (pt.y >= rb.y) then _or (hitMask, hitBottom);
 if (pt.x >= rb.x) then _or (hitMask, hitRight);
end; // DlgHitTest

function  TFormConstructor.FocusedRect: PRct;
begin
 if nFocused = 0 then result := @pdlg.rect
 else result := @pdlg.ctrls [nFocused].rt;
end; // FocusedRect

procedure TFormConstructor.CtrlHitTest (pt: TPoint);

 function ptest (x, y: word): boolean;
 begin
  result := (x - 2 <= pt.x) and (pt.x <= x + 2) and
            (y - 2 <= pt.y) and (pt.y <= y + 2);
 end; // ptest

var  hw, hh, xx, yy : word;
begin
 if (hitMask and hitItem <> hitItem) or (nFocused = 0) then exit;
 hitMask := 0;
 with pdlg.ctrls [nFocused] do
  begin
   hw := rt.x + rt.cx div 2;
   hh := rt.y + rt.cy div 2;
   xx := rt.x + rt.cx;
   yy := rt.y + rt.cy;
   if ptest (rt.x, rt.y) then hitMask := hitLeftTop; // 1, 1
   if ptest (hw, rt.y) then hitMask := hitTop; // 2, 1
   if ptest (xx, rt.y) then hitMask := hitRightTop; // 3, 1
   if ptest (xx, hh) then hitMask := hitRight; // 3, 2
   if ptest (xx, yy) then hitMask := hitRightBottom;  // 3, 3
   if ptest (hw, yy) then hitMask := hitBottom; // 2, 3
   if ptest (rt.x, hh) then hitMask := hitLeft; // 1, 2
   if ptest (rt.x, yy) then hitMask := hitLeftBottom; // 1, 3
  end;
 if hitMask = 0 then inc (hitMask, hitItem);
end; // CtrlHitTest

procedure TFormConstructor.MoveRel (dx, dy: Integer);
var r: PRct;
begin
 if (nFocused = 0) then exit;
 r := FocusedRect;
 lpr := r;
 if (-dx < r.x) then inc (r.x, dx);
 if (-dy < r.y) then inc (r.y, dy);
 Limitate (r.x, pdlg.rect.cx - r.cx);
 Limitate (r.y, pdlg.rect.cy - r.cy);
 lact := amMoveCtrl;
 DrawAll;
 fSaved := false;
end; // MoveRel

procedure TFormConstructor.MoveControl (x, y, state: dword);
var r: PRct;
   old, rm: TRect;
begin
 if (nFocused = 0) then
  begin
   amode := amNone;
   exit;
  end;
 r := FocusedRect;
 old := RCvt (r^);
 lpr := r;
 if word (ofs.x) < x then r.x := x - word (ofs.x) else r.x := 1;
 if word (ofs.y) < y then r.y := y - word (ofs.y) else r.y := 1;
 if (state and MK_CONTROL <> 0) then
  begin
   r.x := r.x div 10 * 10;
   r.y := r.y div 10 * 10;
  end;
 rm := RCvt (r^);
 ExpandRect (rm, old);
 OffsetRect (rm, pdlg.rect.x, pdlg.rect.y);
 IntersectRect (rm, rm, RCvt (pdlg.rect));
 ExtRect (rm, 4);
 InvalidateRect (outpan.handle, @rm, false);
 lact := amMoveCtrl;
 fSaved := false;
end; // MoveControl


procedure TFormConstructor.ResizeRel (dx, dy: Integer);
var pr: PRct;
begin
 pr := FocusedRect;
 fRepaint := nFocused = 0;
 lpr := pr;
 if -dx < pr.cx then Inc (pr.cx, dx);
 if -dy < pr.cy then Inc (pr.cy, dy);
 DrawAll;
 lact := amSizeCtrl;
 fSaved := false;
end; // ResizeRel - used with keyboard

procedure TFormConstructor.ResizeControl (x, y, state: dword);
var pr: PRct;
    bx, by: dword;
begin
 if (hitObj = 0) then
  begin
   amode := amNone;
   exit;
  end;
 if (hitObj = ObjDlg) then nFocused := 0;  
 pr := FocusedRect;
 bx := 0;
 by := 0;
 if (nFocused > 0) then
  begin
   bx := pr.x;
   by := pr.y;
  end else fRepaint := true;
 lpr := pr;
 // расчет точек обьекта
 if (hitMask and hitRight <> 0) then
  begin // правая граница
   if (x > bx) then pr.cx := x - bx else pr.cx := 1;
  end;
  if (hitMask and hitBottom <> 0) then
  begin // нижняя граница
   if (y > by) then pr.cy := y - by else pr.cy := 1;
  end;
  // сложные изменения размера
 if (hitMask and hitTop <> 0) then
  begin
   by := pr.y + pr.cy; // old bottom
   if (y < by) then pr.y := y else pr.y := by - 1;
   pr.cy := by - pr.y;
  end;
 if (hitMask and hitLeft <> 0) then
  begin
   bx := pr.x + pr.cx; // old right
   if (x < bx) then pr.x := x else pr.x := bx - 1;
   pr.cx := bx - pr.x;
  end;
 if (state and MK_CONTROL <> 0) then
  begin
   pr.cx := pr.cx div 5 * 5;
   pr.cy := pr.cy div 5 * 5;
  end;

 DrawAll (6);
 lact := amSizeCtrl;
 fSaved := false;
end; // ResizeControl

procedure TFormConstructor.MsMove (x, y, state: dword);
var
   pt, lp: TPoint;
   lpress: boolean;
        s: string;
begin
 // сброс
 if hitObj = 0 then outpan.cursor := crArrow;
 lpress := (state and MK_LBUTTON <> 0);
 lpr := nil;
 if (not lpress) then  amode := amNone;
 with pdlg do
 if (x >= rect.x) and (y >= rect.y) then
  begin
   pt := Point (x, y); // point
   lp := pt;
   // в координаты формы-диалога
   dec (pt.x, rect.x);
   dec (pt.y, rect.y);
   if (amode = amSizeCtrl) then ResizeControl (pt.x, pt.y, state) else
   if (amode = amMoveCtrl) then MoveControl (pt.x, pt.y, state) else
    begin
     if InDlg (x, y)  then
      begin
       DlgHitTest (pt);
       CtrlHitTest (pt);
       with outpan do
       case hitMask and ($F) of
          hitNone: cursor := crArrow;
        hitBottom, hitTop: cursor := crSizeNS;
         hitRight, hitLeft: cursor := crSizeWE;
         hitRightTop,
         hitLeftBottom: cursor := crSizeNESW;
        hitRightBottom,
         hitLeftTop: cursor := crSizeNWSE;
       end; // case hitmask
      end  // if inDlg
       else hitObj := 0;
   end; // No operations
  end else hitObj := 0;
 s := '';
 if (hitObj = 0) then outpan.cursor := crArrow;
 if (amode = amNone) and (hitObj and $FF <> 0) then
    status.panels [1].text := pdlg.ctrls [hitObj].nm else
    status.panels [1].text := Format ('x = %d, y = %d',[pt.x, pt.y]);
end; // OnMouseMove


procedure TFormConstructor.LoadEditor;
var ptxt, pnm, pin, pout: PString;
    pr: TRct;
    ff: boolean;
    ps: TPropSet;
    pv: ^TValue;
    irow: Integer; // Index of Row
    iprop: TItemProp;
    
begin
 pin := nil;
 pout := nil;
 pnm := nil;
 pv := nil;
 ff := (nFocused = 0);
 with pdlg do
 if ff then
  begin
   ps := [prText, prSize, prGame, prTimer];
   ptxt := @pdlg.capt;
   pr := pdlg.rect;
  end
 else
  begin
   ps := ctrls [nFocused].ps;
   ptxt := @ctrls [nFocused].tx;
   pnm := @ctrls [nFocused].nm;
   pr := ctrls [nFocused].rt;
   pin := @ctrls [nFocused].iv;
   pout := @ctrls [nFocused].ov;
   pv := @ctrls [nFocused].vv;
  end;
 with vledit do
 begin
  Strings.Clear;
  if prSize in ps then InsertRow ('Text', ptxt^, true);
  if (prName in ps) and (pnm <> nil) then InsertRow ('Name', pnm^, true);
  if (prTimer in ps) then InsertRow ('Timer', IntToStr (pdlg.tmr), true);
  if (prGame in ps)  then InsertRow ('Process.exe', pdlg.game, true);
  if (prInOut in ps) and (pin <> nil) then InsertRow ('In', pin^, true);
  if (prInOut in ps) and (pout <> nil) then InsertRow ('Out', pout^, true);
  if (prPos in ps) then
   begin
    InsertRow ('Left', IntToStr (pr.x), true);
    InsertRow ('Top', IntToStr (pr.y), true);
   end;
  if (prSize in ps) then
   begin
    InsertRow ('Width', IntToStr (pr.cx), true);
    InsertRow ('Height', IntToStr (pr.cy), true);
   end;
  if (prHotKey in ps) then
   begin
    // setting properties wich should be edited via special dialog
    m_hkey.pack := pdlg.ctrls [nFocused].hkey;
    with m_hkey do
    irow := InsertRow ('HotKey', StrKey (key, flags), true);
    iprop := ItemProps [irow - 1];
    if assigned (iprop) then
     begin
      iprop.ReadOnly := true;
      iprop.EditStyle := esEllipsis;
     end;
   end;
  if (prAddr in ps) and (pv <> nil) then
        InsertRow ('Address', pv.addr, true);
  if (prType in ps) and (pv <> nil) then
      InsertRow ('Value Type', pv.styp, true);
 end;
end; // LoadEditor

procedure TFormConstructor.outpanResize(Sender: TObject);
var rct: TRect;
begin
 rct := FCRect;
 buff.Width := rct.Right - rct.Left;
 buff.Height := rct.Bottom - rct.Top;
 fRepaint := true;
 DrawAll;
 status.Invalidate;
 // lbmsgs.items.Add('Resize')
end;

procedure  TFormConstructor.OnEdit;
var    s: string;
    ptxt, pnm: PString;
     pin, pout: PString;
     phkey: PDword; 
      pv: ^TValue;
      pr: PRct;
       n: word;
       v: word;
       e: Integer;
      tmp: string;
begin
 pin := @tmp;
 pout := @tmp;
 pnm := @tmp;
 pv := nil;
 phkey := nil;
 // Updating
 if (nFocused = 0) then
  begin
   ptxt := @pdlg.capt;
   pr := @pdlg.rect;
  end
 else
  begin
   ptxt := @pdlg.ctrls [nFocused].tx;
   pnm := @pdlg.ctrls [nFocused].nm;
   pr := @pdlg.ctrls [nFocused].rt;
   pin := @pdlg.ctrls [nFocused].iv;
   pout := @pdlg.ctrls [nFocused].ov;
   pv := @pdlg.ctrls [nFocused].vv;
   phkey := @pdlg.ctrls [nFocused].hkey;
  end;

 with vledit do
 for n := 1 to RowCount - 1 do
  begin
   s := LowerCase (vledit.cells [0, n]);
   val (cells [1, n], v, e);
   if 'text' = s then ptxt^ := Cells [1, n];
   if 'name' = s then
    begin
     pnm^ := Cells [1, n];
     if (n = 1) then ptxt^ := pnm^;
    end;
   if 'in' = s then pin^ := cells [1, n];
   if 'out' = s then pout^ := cells [1, n];
   if 'left' = s then pr.x := v;
   if 'top' = s then pr.y := v;
   if 'width' = s then pr.cx := v;
   if 'height' = s then pr.cy := v;
   if Assigned (pv) then
    begin
     if s = 'address' then pv.addr := cells [1, n];
     if s = 'value type' then pv.styp := cells [1, n];
    end;
   if ('hotkey' = s) and Assigned (phkey)  then
                        phkey^ := m_hkey.pack;
  end;
 ListControls;
 outpan.Caption := pdlg.capt;
 fRepaint := true; 
 DrawAll;
 fSaved := false;
end; // OnEdit

procedure TFormConstructor.vleditSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
 OnEdit;
end;

procedure TFormConstructor.vleditExit(Sender: TObject);
begin
 OnEdit;
end;

procedure TFormConstructor.vleditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if (key = VK_RETURN) then OnEdit;
 if (key = VK_F8) and
    (nFocused > 0) then DeleteCtrl (nFocused);
end; // DelectCtrl

procedure TFormConstructor.mhandlerKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if (shift = [ssShift]) then
   // resize testing
   case key of
     VK_LEFT: ResizeRel (-1, 0);
    VK_RIGHT: ResizeRel (1, 0);
       VK_UP: ResizeRel (0, -1);
     VK_DOWN: ResizeRel (0, 1);
  end;
 if (shift = [ssCtrl]) then
  case key of
     VK_LEFT: MoveRel (-1, 0);
    VK_RIGHT: MoveRel (1, 0);
       VK_UP: MoveRel (0, -1);
     VK_DOWN: MoveRel (0, 1);
  end;
 if (shift = []) then
   case key of
    VK_TAB: if (pdlg.count > 1) then
            begin
             if (nFocused < pdlg.count) then
                 FocusControl (nFocused + 1) else FocusControl (1);
            end;
 VK_DELETE: DeleteCtrl (nFocused);           
     VK_F4: vledit.SetFocus;
   end;
 Descript;
 mhandler.Text := '';
end; // mhandlerKeyDown

procedure TFormConstructor.mhandlerKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if (key = VK_CONTROL) or (key = VK_SHIFT) then
  LoadEditor;
end;

procedure TFormConstructor.btnDelClick(Sender: TObject);
begin
 DeleteCtrl (nFocused);
end;

procedure TFormConstructor.cbGridClick(Sender: TObject);
begin
 DrawAll;
end;

procedure TFormConstructor.btnNewClick(Sender: TObject);
begin
 fileName := '';
 pdlg.capt := 'New Trainer';
 // координаты от начала буфера
 fRepaint := true;
 nFocused := 0;
 ListControls;
 if self <> sender then mhandler.SetFocus;
 pdlg.rect.SetRect (50, 50, 250, 150);
 if (csm <> nil) and csm.svars.aliased then
    pdlg.game := ExtractFileName (csm.prcs.fname);
 LoadEditor;
 DrawAll;
 fsaved := false;
end;

procedure TFormConstructor.btnSaveClick(Sender: TObject);
begin
 if (fileName = '') and sdlg.Execute then fileName := sdlg.FileName;
 if (fileName <> '') then
   begin
    pdlg.SaveDesc (fileName);
    fSaved := true;
   end;
end; // btnSaveClick

procedure TFormConstructor.btnOpenClick(Sender: TObject);
begin
 mhandler.SetFocus;
 if not odlg.Execute then exit;
 fileName := odlg.FileName;
 pdlg.LoadDesc (FileName);
 nFocused := 0;
 fRepaint := true;
 OnStateChange (7); // redraws and update
end;

procedure TFormConstructor.OnStateChange(dw: dword);
begin
 if (dw and 1 <> 0) then DrawAll;
 if (dw and 2 <> 0) then ListControls;
 if (dw and 3 <> 0) then LoadEditor;
end; // OnStateChange

procedure TrainerDestroy;
begin
 formConstructor.pdlg.OnDestroy;
end;

procedure TFormConstructor.btnTestClick(Sender: TObject);
var msg: tagMsg;
begin
 with pdlg.mlist do
   OnDestroy := pdlg.OnDestroy;
 pdlg.CreateWnd (0);
 while (pdlg.hwnd <> 0) do
  begin
   // simple cycle for message handling
   if PeekMessage (msg, pdlg.hwnd, 0, 0, PM_REMOVE) then
     begin
      TranslateMessage (msg);
      DispatchMessage (msg);
     end;
   Sleep (1);
   Application.ProcessMessages;
  end;
end;


procedure TFormConstructor.miSaveAsClick(Sender: TObject);
begin
 fileName := '';
 btnSaveClick (Sender);
end;

procedure TFormConstructor.vleditEditButtonClick(Sender: TObject);
begin
 // Вызов диалога получения горячей клавиши
 with pdlg, vledit do
 if 'HotKey' = keys [row] then
   begin
    RecieveHotKey (self, m_hkey);
    cells [1, row] := m_hkey.str;
    if nFocused > 0 then
       ctrls [nFocused].hkey := m_hkey.pack;
   end;
end;

end.

