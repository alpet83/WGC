unit tester;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Grids;

type
  TFormX = class(TForm)
    T1: TTimer;
    btnClose: TButton;
    btnAdd: TButton;
    BtnSub: TButton;
    edSize: TEdit;
    btnSetSize: TButton;
    lOffset: TLabel;
    Table: TStringGrid;
    cbStay: TCheckBox;
    edText: TEdit;
    ltext: TLabel;
    lwtext: TLabel;
    lbptr: TLabel;
    edCount: TEdit;
    btnWrite: TButton;
    edAddr: TEdit;
    cbType: TComboBox;
    cbDTLBpref: TCheckBox;
    msgs: TMemo;
    procedure T1Timer(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure BtnSubClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnSetSizeClick(Sender: TObject);
    procedure cbStayClick(Sender: TObject);
    procedure btnHaltClick(Sender: TObject);
    procedure TableSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure btnWriteClick(Sender: TObject);
  private
    procedure Allocate (const s: string);
    procedure DTLBprefetch;
    procedure AddMsg(const s: string);
    procedure UpdWatch(nWatch: dword);
    procedure UpdTable;
    function ReadVar(pvar: pointer; vtyp: dword): string;
    procedure UpdCell(x, y: dword; const s: string);
    procedure WriteVar(pvar: pointer; vtyp: dword; const s: string);
    procedure AddX(const x: integer);
    { Private declarations }
  public
    { Public declarations }
    prvRow: Integer;
  end;

var
  FormX: TFormX;

implementation

{$R *.DFM}
const
     vecsz = 1024 * 1024;
     maxblck = 2048;
     stdtypes: array [1..10] of string =
      ('BYTE', 'WORD', 'DWORD', 'SINGLE', 'REAL', 'DOUBLE', 'EXTENDED', 'COMP',
       'ANSI_TEXT', 'WIDE_TEXT');
     sizes: array [1..10] of dword = (1, 2, 4, 4, 6, 8, 10, 8, 0, 0);
     types : array [1..8] of string =
      ('DWORD','DWORD','DWORD','SINGLE','REAL','DOUBLE','EXTENDED', 'COMP');

type
    tBigVec = array [0..vecsz - 1] of byte;

    pBigVec = ^tBigVec;

    tWatch = record
     wtyp: dword;   // индекс типа
     case BYTE of
      0:( wptr: dword );   // адрес переменной
      1:( lptr: pointer );
    end;

var
   plist: array [1..maxblck] of pBigVec; // списочек векторов по 1 мб
   olist: array [1..maxblck] of dword absolute plist; // dword alias
   vindex: dword = 1;
   vcount: dword = 0;
   wlist: array [1..8] of TWatch;
   vsz : dword;
   ofst : dword;

   vtext: array [0..127] of char;
   wtext: array [0..127] of WideChar;

      s1: string;
      s2: WideString;
      s3: array [0..255] of WideChar;
   ffill: boolean;
  fbreak: boolean;
   t, ot: dword;
    aptr: pdword;
    dptr: dword absolute aptr;
  dwtest: dword; // volatile

function FindType (const typ: string): dword;
var n: dword;
begin
 result := 0;
 for n := 1 to high (stdtypes) do
  if pos (typ, stdtypes [n]) > 0 then result := n;
end;

function varsize (nType: dword; const txt: string): dword;
begin
 result := 0;
 if (0 = nType) or (nType > High (sizes)) then exit;
 result := sizes [nType];
 if 0 = result then
  begin
   result := length (txt);
   if 10 = nType then result := result * 2; // widestring
  end;
end; // varsize

procedure TFormX.AddMsg (const s: string);
begin
 msgs.Lines.Add (s);
 if (msgs.Lines.Count > 1000) then
  begin
   msgs.Lines.Delete (0);
  end;
end;

procedure TFormX.DTLBprefetch;
const nPages = vecsz div 4096;
var n: dword;
begin
 lOffset.Caption := format ('Read Offset : $%p', [(@plist [vindex]^[ofst])]);
 try
  for n := 1 to nPages do
      dwtest := dwtest + plist [vindex]^[ofst + (n - 1) * 4096];
 except
  On EAccessViolation do
    AddMsg ('#ERROR: fail access to page, DTLBprefetch');
 end;
 if dwtest = dwtest and $FF + 1 then AddMsg ('+dwtest');
 ofst := ofst + 4096 * nPages;
 if ofst > vecsz - 4096 * nPages then
  begin
   inc (vindex);
   if vindex > vcount then vindex := 1;
   ofst := 0;
  end;
end; // DTLBprefetch

function  TFormX.ReadVar (pvar: pointer; vtyp: dword): string;
var vsize: dword;
   s: string;
begin
 result := 'n\a';
 vsize := varsize (vtyp, '1234');
 if dword (pvar) < $1000 then exit;
 if IsBadReadPtr (pvar, vsize) or not Assigned (pvar) then exit;
 s := '';
 try
  case vtyp of
   1: s := IntToStr (PByte (pvar)^ );
   2: s := IntToStr (PWord (pvar)^ );
   3: s := IntToStr (PDword (pvar)^);
   4: s := FormatFloat ('0.0000', Single (pvar^));
   5: s := FormatFloat ('0.0000', Real (pvar^));
   6: s := FormatFloat ('0.0000', Double (pvar^));
   7: s := FormatFloat ('0.0000', Extended (pvar^));
   8: s := FormatFloat ('0.0000', Comp (pvar^));
   9: s := PChar (pvar);
  10: s := WideCharToString (PWideChar (pvar));
  end;
 except
  s := 'n/a';
 end;
 result := s;
end; // ReadVar

procedure TFormX.WriteVar (pvar: pointer; vtyp: dword; const s: string);
var vsize: dword;
    x: Int64;
    e: Integer;
    f: extended;
begin
 vsize := varsize (vtyp, s);
 if dword (pvar) < $1000 then exit;
 if IsBadWritePtr (pvar, vsize) or not Assigned (pvar) then exit;
 val (s, x, e);
 if (vtyp < 9) and (e <> 0) then exit;
 f := 0;
 if vtyp in [4..8] then
  try
   f := StrToFloat (s);
  except
   On EConvertError do f := 0.0;
  end;
 try
  case vtyp of
   1: PByte (pvar)^ := x;
   2: PWord (pvar)^ := x;
   3: PDword (pvar)^ := x;
   4: Single (pvar^) := f;
   5: Real (pvar^) := f;
   6: Double (pvar^) := f;
   7: Extended (pvar^) := f;
   8: Comp (pvar^) := f;
   9: StrPCopy (PChar (pvar), s);
  10: StringToWideChar (s, PWideChar (pvar), vsize);
  end;
 except
 end;
end;

procedure TFormX.UpdCell (x, y: dword; const s: string);
begin
 if s <> table.Cells [x, y] then table.Cells [x, y] := s;
end;

procedure TFormX.UpdWatch (nWatch :dword);
var s: string;
begin
 ASSERT (nWatch <= High (wlist));
 s := format ('$%x', [wlist [nWatch].wptr]);
 UpdCell (3, nWatch, s);
 s := stdtypes [wlist [nWatch].wtyp];
 UpdCell (2, nWatch, s);
 s := ReadVar (wlist [nWatch].lptr, wlist [nWatch].wtyp);
 UpdCell (1, nWatch, s);
end;

procedure TFormX.UpdTable;
var n: dword;
begin
 for n := 1 to High (wlist) do UpdWatch (n);
end;

procedure TFormX.T1Timer(Sender: TObject);
var p : array [0..255] of char;
    s : string;
begin
 strPcopy (p, self.caption);
 SetWindowText (application.Handle, p);
 t := getTickCount div 100;
 if t <> ot then
 with table do
  begin
   UpdTable;
   ot := t;
  end;
  if (vtext <> ltext.Caption) then ltext.caption := vtext;
  s := WideCharToString (wtext);
  if (s <> lwtext.Caption) then lwtext.Caption := s;
 { Взбалтывание памяти }
 if cbDTLBpref.Checked then DTLBprefetch;

end; // OnTimer

procedure TFormX.btnCloseClick(Sender: TObject);
begin
 T1.Enabled := false;
 fbreak := true;
 PostQuitMessage (0);
end; // btnCloseClick

procedure TFormX.AddX (const x : integer);
var n: dword;
    s: string;
    e: Extended;
    i: Int64;
    err: Integer;
begin
 for n := 1 to high (wlist) do
 with wlist [n] do
  begin
   s := ReadVar (lptr, wtyp);
   if wtyp in [1..3, 9..10] then
    begin
     val (s, i, err);
     if err = 0 then WriteVar (lptr, wtyp, IntToStr (i + x));
    end;
   if wtyp in [4..8] then
    begin
     e := StrToFloat (s);
     WriteVar (lptr, wtyp, FloatToStr (e + x));
    end;
  end;
end;

procedure TFormX.btnAddClick(Sender: TObject);
begin
 addX (1);
end;
 
procedure TFormX.BtnSubClick(Sender: TObject);
begin
 addX (-1);
end;

procedure TFormX.Allocate;
var e: Integer;
    n, old: dword;
    ptrmin, ptrmax: dword;
begin
 old := vcount;
 val (s, vcount, e);
 if (vcount = 0) or (vcount > high (plist)) then
  begin
   vcount := high (plist);
   edSize.Text := IntToStr (vcount);
  end;
 if old > vcount then
 for n := vcount + 1 to old do VirtualFree (plist [n], vecsz, MEM_DECOMMIT);
 if old < vcount then
 for n := old + 1 to vcount do
    begin
     plist [n] := VirtualAlloc (nil, vecsz, MEM_COMMIT, PAGE_READWRITE);
     ASSERT (plist [n] <> nil, 'Allocation Failure. Currently allocated blocks ' + IntToStr (n));
    end;
 ptrmax := 0;
 ptrmin := $FFFFFFFF;    
 for n := 1 to vcount do
  begin
   if olist [n] > ptrmax then ptrmax := olist [n];
   if olist [n] < ptrmin then ptrmin := olist [n];
  end;
 AddMsg (Format ('Reserved Min_ptr = $%x, Max_ptr = $%x', [ptrmin, ptrmax])); 
end;

procedure TFormX.FormCreate(Sender: TObject);
var n: dword;
begin
 Randomize;
 vsz := vecsz;
 prvRow := 1;
 Allocate (edSize.Text);
 for n := 1 to high (stdtypes) do cbType.Items.Add(stdtypes [n]);
 cbType.ItemIndex := 2;
 with table do
  begin
   cells [0, 0] := 'Index';
   cells [1, 0] := 'Value';
   cells [2, 0] := 'Type';
   cells [3, 0] := 'Addr';
   for n := 1 to high (wlist) do
    begin
     wlist [n].wtyp := 3;
     wlist [n].wptr := 0;
     cells [0, n] := IntToStr (n);
    end;
  end;
 s1 := '1';
 s2 := '1';
 s3 [0] := '1';
 s3 [1] := #0;
 ofst := 0;
 ffill := true;
 StrPCopy (vtext, edText.Text);
 StringToWideChar (vtext, wtext, 128);
 aptr := pointer (plist [vindex]);
end;

procedure TFormX.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var n: dword;
begin          // SEH
 for n := 1 to vcount do VirtualFree (plist [n], vecsz, MEM_DECOMMIT);
 canClose := true;
end;

procedure TFormX.btnSetSizeClick(Sender: TObject);
begin
 try
  Allocate (edSize.text);
 except
  on E:Exception do
    begin
     edSize.Text := '128';
     ShowMessage ('Не возможно выделить столько памяти!');
   end;
 end; // try
end;

procedure TFormX.cbStayClick(Sender: TObject);
begin
 if cbStay.Checked then
  formStyle := fsStayOnTop else formStyle := fsNormal;
end;

procedure TFormX.btnHaltClick(Sender: TObject);
begin
 fbreak := true;
end;

procedure TFormX.TableSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
 // changing watch table
 try
  wlist [prvRow].wptr := StrToInt (edAddr.Text);
  wlist [prvRow].wtyp := cbType.ItemIndex + 1;
 except
  on EConvertError do wlist [prvRow].wptr := 0;
 end;
 if prvRow = ARow then exit;
 // updating input controls
 edAddr.text := table.cells [3, ARow];
 cbType.ItemIndex := FindType (table.cells [2, ARow]) - 1;
 prvRow := ARow;
end;

procedure TFormX.btnWriteClick(Sender: TObject);
var vptr: dword;
    err: Integer;
begin
 val (edAddr.Text, vptr, err);
 if err <> 0 then exit;
 WriteVar (Ptr (vptr), cbType.ItemIndex + 1, edText.Text);
end;

end.
