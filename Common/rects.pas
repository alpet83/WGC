unit rects;

interface
uses SysUtils, Types;


 type
    TRct = packed class
   private
     function    GetRight: word;
     procedure   SetRight (const r: word);
     function    GetBottom: word;
     procedure   SetBottom (const r: word);
     procedure   FSetRect (const r: TRect);
     function    GetRect: TRect;
   public
       x, y: word;   // Координаты
     cx, cy: word;   // Размеры
     property    rect: TRect read GetRect write FSetRect;
     property    right: word read GetRight write SetRight;
     property    bottom: word read GetBottom write SetBottom;
     procedure   SetRect (const xx, yy, ww, hh: word); 
    end;
    PRct = ^TRct;

implementation

{ TRct }

function TRct.GetBottom: word;
begin
 result := y + cy;
end; // GetBottom

function TRct.GetRight: word;
begin
 result := x + cx;
end; // GetRight

procedure TRct.SetRect(const xx, yy, ww, hh: word);
begin
 x := xx;
 y := yy;
 cx := ww;
 cy := hh;
end;

procedure TRct.SetBottom(const r: word);
begin

end;

procedure TRct.FSetRect(const r: TRect);
begin
 x := r.left;
 y := r.top;
 cx := abs (r.right - r.left);
 cy := abs (r.bottom - r.top);
end;

procedure TRct.SetRight(const r: word);
begin
 if (r > x) then cx := x - r
            else cx := 0; // не удалось задать правую сторону
end; // SetRight

function TRct.GetRect: TRect;
begin
 result.Left := x;
 result.Top := y;
 result.Right := GetRight;
 result.Bottom := GetBottom; 
end; // GetRect

end.


