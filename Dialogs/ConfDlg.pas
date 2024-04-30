unit ConfDlg;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

const
   r_cancel = 0;
   r_append = 1;
   r_overwr = 2;
   r_other  = 3;

type
  TConfirmDlg = class(TForm)
    btnAppend: TButton;
    btnOverwr: TButton;
    btnCancel: TButton;
    Label1: TLabel;
    btnOther: TButton;
    procedure btnAppendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnOverwrClick(Sender: TObject);
    procedure btnOtherClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    result : byte;
  end;

var
  ConfirmDlg: TConfirmDlg;

implementation

{$R *.DFM}

procedure TConfirmDlg.btnAppendClick(Sender: TObject);
begin
 result := r_append;
 close;
end;

procedure TConfirmDlg.FormCreate(Sender: TObject);
begin
 result := 0;
end;

procedure TConfirmDlg.btnOverwrClick(Sender: TObject);
begin
 result := r_overwr;
 close;
end;

procedure TConfirmDlg.btnOtherClick(Sender: TObject);
begin
 result := r_other;
 close;
end;

procedure TConfirmDlg.btnCancelClick(Sender: TObject);
begin
 result := r_cancel;
 close;
end;

end.
