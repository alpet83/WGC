unit icreater;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TFormX = class(TForm)
    files: TListBox;
    btnBrowse: TButton;
    fpath: TEdit;
    odlg: TOpenDialog;
    btnAdd: TButton;
    btnDel: TButton;
    btnPack: TButton;
    btnExit: TButton;
    sbar: TStatusBar;
    procedure btnExitClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnPackClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormX: TFormX;

implementation
uses packer;

{$R *.dfm}

procedure TFormX.btnExitClick(Sender: TObject);
begin
 close;
end;

procedure TFormX.btnBrowseClick(Sender: TObject);
var n : integer;

begin
 if odlg.Execute then
  begin
    for n := 1 to odlg.files.Count do
     files.items.add (
       LowerCase (odlg.files [n - 1]));
  end;
end;

procedure TFormX.btnAddClick(Sender: TObject);
begin
 if fpath.Text <> '' then
    files.items.Add(fpath.text); 
end;

procedure TFormX.btnDelClick(Sender: TObject);
var n : integer;
begin
 n := 0;
 with files, files.items do
  repeat
   if selected [n] then
      items.Delete (n) else inc (n);
  until n >= count;
end;

procedure TFormX.btnPackClick(Sender: TObject);
var strs : array [1..100] of string;
       n : dword;    
begin
 for n := 1 to files.items.Count do
       strs [n] := files.items [n - 1];
 sbar.SimplePanel := true;
 sbar.SimpleText := 'Идет запаковка...';
 application.ProcessMessages;      
 enabled := false;
 PackFiles (strs, files.items.count, 'data.cab');
 enabled := true;
 sbar.SimpleText := 'Готово';
end;

procedure TFormX.FormCreate(Sender: TObject);
begin
 application.Title := 'InstallCreater';
end;

end.
