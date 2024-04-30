unit ChBtns;
{ Класс элементарных кнопок для консоли }
interface

uses Windows, SysUtils, Graphics, Controls;

type
    TBtn = class (TObject)
     bgColor: TColor;           // Цвет фона
     frameColor: TColor;         // Цвет прямоугольника кнопки
     captColor: TColor;         // Цвет надписи кнопки
     selColor: TColor;          // Цвет надписи подсвеченой кнопки
     selBgColor: TColor;        // Цвет фона подсвеченой кнопки
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
 // Настройка цветов примитива
 canvas.Pen.Color := frameColor;
 canvas.Pen.Width := 1;
 canvas.Pen.Style := psSolid;
 canvas.Brush.Style := bsSolid;
 if (sel) then canvas.brush.Color := selBgColor
          else canvas.Brush.color := bgColor;
 // Рисование кнопки          
 canvas.Rectangle (rect);
 canvas.Font.Size := 10;
 if (sel) then canvas.Font.Color := selColor
          else canvas.Font.Color := captColor;
 x := (rect.Left + rect.Right) shr 1; // середина
 x := x - canvas.TextWidth(caption) shr 1;  // позиция вывода
 y := (rect.Top + rect.Bottom) shr 1; // центр по Y
 y := y - canvas.TextHeight(caption) shr 1;
 canvas.TextOut (x, y, caption);        // Вывод надписи
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
