unit ChMsg;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  Menus, ComCtrls, ChLog;

type
  TfMessages = class(TForm)
    pmMsgs: TPopupMenu;
    miClean: TMenuItem;
    miClose: TMenuItem;
    Messages: TMemo;
    procedure FormResize(Sender: TObject);
    procedure miCleanClick(Sender: TObject);
    procedure miCloseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  fMessages: TfMessages = nil;
  outDC : HDC;
  bmp : TBitmap;
  msgdisp : boolean;
  msgadded : boolean = false;
  ssht: TBitmap;

procedure  AddMsg (const s : string);
procedure  UpdLastMsg (const s : string);
procedure  ClrScr;
// procedure  DrawMessages (const fsave : boolean);
procedure  RestoreRect;
procedure  Snapshot (fsave: boolean = true; attachMode: bool = false );
procedure  CopySmall;
procedure  InitBitmap;

implementation

{$R *.dfm}

uses ChForm, misk, ChShare, ChView, ChConsole, ChConst;


var
    fDrawed: boolean = false;
   nMsg, nLastMsg: Integer;
   sn : dword = 1;

procedure  InitBitmap;
begin
 bmp := TBitmap.Create ();
 bmp.Width := 640;
 bmp.Height := 250;
 bmp.PixelFormat := pf32bit;
end;

procedure  CopySmall;
var r: TRect;
begin
 if (ssht = nil) then exit;
 r.left := abs (gvpnt.x);
 r.top :=  abs (gvpnt.y);
 r.Right := r.Left + abs (mwrect.Right - mwrect.Left);
 r.Bottom := r.top + abs (mwrect.Bottom - mwrect.top);
 mform.sshot_panel.Visible := true;
 with mform.imGameView do
  begin
   Canvas.CopyRect (mwrect, ssht.Canvas, r);
   Canvas.Brush.Style := bsClear;
   Canvas.Rectangle(mwrect);
  end;
end;

procedure  Snapshot;
var
    w, h: Integer;
    sdc, mdc: HDC;
    mbmp: HBITMAP;
begin
 // Создание буффера
 if attachMode then sdc := GetDC (0)
  else sdc := CreateDC ('DISPLAY', nil, nil, nil);
 if sdc = 0 then exit;
 if (ssht <> nil) then   ssht.Free;
 w := screen.Width;
 h := screen.Height;
 ssht := TBitmap.Create;
 ssht.Width := w;
 ssht.Height := h;
 // ssht.Dormant;
 mbmp := CreateCompatibleBitmap (sdc, w, h);
 mdc := CreateCompatibleDC (sdc);
 SelectObject (mdc, mbmp);
 BitBlt (mdc, 0, 0, w, h, sdc, 0, 0, SRCCOPY or CAPTUREBLT);
 ssht.Canvas.CopyMode := SrcCopy;
 ssht.PixelFormat := pf32bit;
 with ssht do
  case GetDeviceCaps (sdc, BITSPIXEL) of
   8: pixelFormat := pf8bit;
  15: pixelFormat := pf15bit;
  16: pixelFormat := pf16bit;
  24: pixelFormat := pf24bit;
 end;
 BitBlt (ssht.Canvas.Handle, 0, 0,  w, h, mdc, 0, 0, SRCCOPY);
 if (fsave) then
  begin
   ssht.SaveToFile('sshot' + word2hex (sn) + '.bmp' );
   inc (sn);
  end;
 CopySmall;
 if attachMode then
    ReleaseDC (0, sdc)
 else DeleteDC (sdc);
 DeleteObject (mbmp);
 DeleteDC (mdc);
end;

procedure  RestoreRect;
var rect : TRect;
    dc : TCanvas;
begin
 if fDrawed and not msgdisp then
  begin
   fDrawed := false;
   dc := TCanvas.Create;
   dc.Handle := CreateDC ('DISPLAY', nil, nil, nil);
   rect.left := 0;
   rect.top := 0;
   rect.right := 639;
   rect.Bottom := 249;
   // Восстановить экран из битмэпа
   dc.CopyRect(rect, bmp.Canvas, rect);
   ReleaseDC (mform.handle, dc.Handle);
   dc.Free;
  end;
end; // RestoreRect

procedure AddMsg;
begin
 nLastMsg := -1;
 if Assigned (fMessages) then
 with fMessages do
  begin
   Inc (nMsg);
   nLastMsg := Messages.Lines.Add (IntToStr (nMsg) + '. ' + s);
   LogStr (s);
   if (Messages.Lines.Count > 255) then
    while Messages.Lines.Count > 128 do
        Messages.Lines.Delete (0);
        
    msgadded := true;
    if Assigned (con) then
       con.WriteText (s);
    // if (con.visible) then con.RepaintConsole;
  end;
end; // AddMsg

procedure UpdLastMsg;
begin
 with fMessages.Messages do
 if (nLastMsg >= 0) and (nLastMsg < Lines.Count) then
    Lines [nLastMsg] := IntToStr (nMsg) + '. ' + s;
 con.SetLast (s);
end;

procedure ClrScr;
begin
 fMessages.Messages.Clear;
end; // AddMsg

procedure TfMessages.FormResize(Sender: TObject);
begin
 Messages.Width := Width - 2;
 Messages.Height := Height - 2;
end;



procedure TfMessages.miCleanClick(Sender: TObject);
begin
 Messages.Clear;
end;

procedure TfMessages.miCloseClick(Sender: TObject);
begin
 mform.miMsgsClick(self);
end;

initialization
 outDC := 0;
finalization

end.
