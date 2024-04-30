unit splash;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls;

type
  TfrmSplash = class(TForm)
    pnDock: TPanel;
    btnBreak: TButton;
    pgBar: TProgressBar;
    lbMessage: TLabel;
    uTimer: TTimer;
    procedure btnBreakClick(Sender: TObject);
    procedure uTimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSplash: TFrmSplash;

implementation

{$R *.dfm}

procedure TfrmSplash.btnBreakClick(Sender: TObject);
begin
 PostQuitMessage (0);
end;

procedure TfrmSplash.uTimerTimer(Sender: TObject);
var p: Integer;
begin
 if not Visible then exit;
 p := pgBar.Position;
 inc (p);
 if p >= 100 then p := 0;
 pgBar.Position := p;
end;

end.
