unit ChBtns;
{ ����� ������������ ������ ��� ������� }
interface

uses Windows, SysUtils, Graphics, Controls;

type
    TBtn = class (TObject)
     bgColor: TColor;           // ���� ����
     frameColor: TColor;         // ���� �������������� ������
     captColor: TColor;         // ���� ������� ������
     selColor: TColor;          // ���� ������� ����������� ������
     selBgColor: TColor;        // ���� ���� ����������� ������
     rect:  TRect;
     caption: string;
     constructor        Create (const cp: string; const rct: TRect);
     procedure          Draw (const canvas: TCanvas; sel: boolean = false);
     function           HitTest (point: TPoint): boolean; overload;
     function           HitTest: boolean; overload;
    end;

implementation

{ TBtn }

constructor TBtn.Create(const cp: string; const rct: TRect);
begin
 frameColor := $707070;
 captColor := clSilver;
 selColor := clWhite;
 bgColor := $101010;
 selBgColor := $404040;
 caption := cp;
 rect := rct;
end;

procedure TBtn.Draw;
var x, y: Integer;
begin
 // ��������� ������ ���������
 canvas.Pen.Color := frameColor;
 canvas.Pen.Width := 1;
 canvas.Pen.Style := psSolid;
 canvas.Brush.Style := bsSolid;
 if (sel) then canvas.brush.Color := selBgColor
          else canvas.Brush.color := bgColor;
 // ��������� ������          
 canvas.Rectangle (rect);
 canvas.Font.Size := 10;
 if (sel) then canvas.Font.Color := selColor
          else canvas.Font.Color := captColor;
 x := (rect.Left + rect.Right) shr 1; // ��������
 x := x - canvas.TextWidth(caption) shr 1;  // ������� ������
 y := (rect.Top + rect.Bottom) shr 1; // ����� �� Y
 y := y - canvas.TextHeight(caption) shr 1;
 canvas.TextOut (x, y, caption);        // ����� �������
end;

function TBtn.HitTest(point: TPoint): boolean;
begin
 result := (point.x >= rect.left) and (point.y >= rect.top) and
           (point.x <= rect.Right) and (point.y <= rect.Bottom);
end;

function TBtn.HitTest: boolean;
var pt: TPoint;
begin
 pt := mouse.CursorPos;
 result := HitTest (pt);
end;

end.
