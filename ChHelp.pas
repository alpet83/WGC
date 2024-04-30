unit ChHelp;

interface
{ Модуль поддержки интегрированной справки }

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Menus;

type
  THelpForm = class(TForm)
    topics: TTreeView;
    outWin: TMemo;
    pmFSize: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    procedure topicsClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    paintDisable: Boolean;
    PrevProc: TWndMethod;
    procedure LoadContent(const i: integer);
    procedure WMSizing (var msg: TMessage); message WM_SIZING;
    procedure WMTimer (var msg: TMessage); message WM_TIMER;
    procedure MemoProc (var msg: TMessage);
  end;

var
  HelpForm: THelpForm;
    alltxt: TStringList;


 function  SearchByHead (const s : string) : integer;
 procedure InitStrings;

implementation
uses Misk, ChMsg;

{$R *.dfm}



procedure    InitStrings;
var
   pc: PAnsiChar;
   id: dword;
   cn: Integer;
   flag: boolean;
   s, ss: string;
begin
 GetMem (pc, 32768);
 alltxt := TStringList.Create;
 TStringList.Create;
 id := 13000;
 s := '';
 repeat
  cn := LoadStringA (HINSTANCE, id, pc, 32768);
  // ods (Err2str (GetLastError ()));
  flag := (pc = 'HELPISEND');
  ss := pc;
  if pos ('[end]', LowerCase (ss)) > 0 then ss := '[end]'#10;
  if (not flag) then s := s + ss;
  inc (id);
 until (cn <= 0) or flag;
 alltxt.Text := s;
 FreeMem (pc, 32768);
end;


function  SearchByHead (const s : string) : integer;
var i : Integer;
    c : String;
begin
 c := '[' + s + ']';
 for i := 1 to alltxt.Count do
 if (alltxt.Strings [i - 1] = c) then
  begin
   result := i - 1;
   exit;
  end;
 result := 0;
end; // SearchByHead

procedure SetFSize (const sz : dword);
begin
 HelpForm.outWin.Font.Size := sz;
end;

procedure THelpForm.LoadContent (const i: integer);
var n: Integer;
begin
 outWin.Lines.BeginUpdate;
 if (i < alltxt.Count) then
  begin
   outWin.Clear;
   n := i + 1;
   while ((n < alltxt.count) and
         (pos ('[end]', alltxt.strings [n]) = 0)) do
    begin
     outWin.Lines.Add(alltxt.Strings [n]);
     inc (n);
    end;
  end;
 outWin.Lines.EndUpdate;
end;

procedure THelpForm.topicsClick(Sender: TObject);
var i : Integer;
    t : TTreeNode;
    s : string;
begin
 t := topics.Selected;
 if (t <> nil) then
 begin
  s := t.Text;
  i := SearchByHead (s);  // поиск по заголовку
  if i > 0 then LoadContent (i);
 end;
end;
        
procedure THelpForm.N1Click(Sender: TObject);
begin
 SetFSize (14);
end;

procedure THelpForm.N2Click(Sender: TObject);
begin
 SetFSize (12);
end;

procedure THelpForm.N3Click(Sender: TObject);
begin
 SetFSize (10);
end;

procedure THelpForm.FormShow(Sender: TObject);
begin
 LoadContent (1);
 paintDisable := false;
end;

procedure THelpForm.FormCreate(Sender: TObject);
var oldStyle: LongInt;
begin
 oldStyle := GetWindowLong (Handle, GWL_STYLE);
 SetWindowLong (Handle, GWL_STYLE,
                oldStyle or WS_CLIPCHILDREN );
 oldStyle := GetWindowLong (outWin.Handle, GWL_STYLE);
 SetWindowLong (outWin.Handle, GWL_STYLE, oldStyle or WS_CLIPSIBLINGS);
 if (topics.Items.Count > 0) then
         topics.Items [0].Expand (true);
 paintDisable := false;         
 PrevProc := outWin.WindowProc;
 outWin.WindowProc := MemoProc;
 SetTimer (Handle, 1, 100, nil);
end;



procedure THelpForm.WMSizing(var msg: TMessage);
begin
 paintDisable := true;
 DefaultHandler (msg);
 // paintDisable := false;
end;

procedure THelpForm.FormResize(Sender: TObject);
begin
 paintDisable := false;
end;

procedure THelpForm.MemoProc;
begin
 msg.Result := 0;
 if paintDisable then
   case msg.msg of
    WM_PAINT: exit;
    WM_ERASEBKGND: begin msg.Result := 1; exit; end;
   end;
 PrevProc (msg);
end;

procedure THelpForm.WMTimer(var msg: TMessage);
begin
 if PaintDisable then
  begin
   PaintDisable := false;

  end; 
end;

end.
