unit ChView;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TGVform = class(TForm)
    btnClose: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormClick(Sender: TObject);
  private
    procedure SetDst;
    { Private declarations }
  public
    { Public declarations }
    procedure   Paint; override;
  end;

var
  GVform: TGVform;
  gvpnt: TPoint; // точка откуда береться изображение gameView
  mwrect: TRect;
  mwscroll: boolean;

implementation
uses ChMsg;

{$R *.dfm}
var
   src, dst: TRect;
   lmpnt : TPoint;

procedure TGVform.btnCloseClick(Sender: TObject);
begin
 close;
end;

procedure TGVform.FormShow(Sender: TObject);
begin
 modalResult := 0;
end;

procedure TGVform.FormCreate(Sender: TObject);
begin
 SetDst;
end;

procedure TGVform.SetDst;
begin
 dst.left := 1;
 dst.top := 1;
 dst.Right := width - 2;
 dst.Bottom := height - 2;
end; // setDst

procedure TGVform.FormResize(Sender: TObject);
begin
 SetDst;
 Paint;
end;

var
   oldrct: TRect;
   sx, sy: double;
   
procedure TGVform.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);

var
    pr: TRect;
    pw, ph: integer;
begin
 lmpnt.x := x;
 lmpnt.y := y;
 if (ssht <> nil) then
  begin
   canvas.Pen.Mode := pmXor;
   canvas.Brush.Style := bsSolid;
   pw := abs (src.Right - src.Left) + 1;
   ph := abs (src.bottom - src.Top) + 1;
   sx := (dst.Right - dst.left) / (pw); // коэффициент по X
   sy := (dst.bottom - dst.Top) / (ph); // коэффициент по Y
   pw := round ((mwrect.Right - mwrect.Left) * sx);
   ph := round ((mwrect.bottom - mwrect.Top) * sy);
   pr.left := x;
   pr.top := y;
   pr.Right := x + pw;
   pr.Bottom := y + ph;
   canvas.Rectangle (oldrct);
   canvas.Rectangle (pr);
   canvas.Pen.Mode := pmCopy;
   oldrct := pr;
  end;
end;

procedure TGVform.FormClick(Sender: TObject);
begin
 if (lmpnt.x < dst.left) or (lmpnt.x > dst.right) or
    (lmpnt.y < dst.Top) or (lmpnt.y > dst.bottom) then exit;
 if (sx = 0) or (sy = 0) then exit;    
 gvpnt.x := round ((lmpnt.x - 5) / sx);
 gvpnt.y := round ((lmpnt.y - 5) / sy);
 ModalResult := 1;
end;

procedure  TGVForm.Paint;
begin
 // рисование картинки поверх формы
 canvas.pen.style := psSolid;
 canvas.Pen.mode := pmCopy;
 canvas.Brush.style := bsClear;
 if (ssht <> nil) then
  begin
   src.left := 0;
   src.top := 0;
   src.Right := ssht.Width;
   src.Bottom := ssht.Height;
   Canvas.CopyRect (dst, ssht.Canvas, src);
  end
 else inherited;
 Canvas.Rectangle(dst);
 canvas.pen.style := psClear;
 canvas.Brush.style := bsClear;
end;

begin
 lmpnt.x := 0;
 lmpnt.y := 0;
 gvpnt.x := 0;
 gvpnt.y := 0;
end.
