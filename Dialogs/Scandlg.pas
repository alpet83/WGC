unit Scandlg;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls, Gauges;

type
  Tscpdlg = class (TForm)
    btnBreakClose: TButton;
    Bevel1: TBevel;
    gprogress: TGauge;
    lFound: TLabel;
    lbSpeed: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnBreakCloseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    fscan: boolean;
    prcsn: string;
    procedure           SetProgress (const p, found: dword);
    procedure           OnComplete (const spd, time, bts : string);
  end;

var
  scpdlg: Tscpdlg;

implementation
uses ChShare;

{$R *.dfm}

{ Tscpdlg }

procedure Tscpdlg.SetProgress(const p, found: dword);
begin
 //
 gprogress.Progress := p;
 lFound.Caption := 'Найдено значений: ' + IntToStr (found);
end;

procedure Tscpdlg.FormShow(Sender: TObject);
var
   s: string;
begin
 lbspeed.Hide;
 SetProgress (0, 0);
 gprogress.Show;
 btnBreakClose.Caption := 'Прервать';
 s := prcsn + ' значений';
 if (s [1] = 'п') then s [1] := 'П';
 if (s [1] = 'о') then s [1] := 'О';
 scpdlg.Caption := s;
 fscan := true;
end;

procedure Tscpdlg.btnBreakCloseClick(Sender: TObject);
begin
 if (fscan) then
  begin
   btnBreakClose.caption := 'Закрыть';
   fscan := false;
   exit;
  end;
 close;
end;

procedure Tscpdlg.OnComplete;
begin
 gprogress.Progress := 999;
 gprogress.hide;
 gprogress.Progress := 0;
 fscan := false;
 lbspeed.caption := 'Средняя скорость ' + prcsn + 'а: ' + spd + '/сек.'#13#10 +
                    'Время ' + prcsn + 'а: ' + time + ' сек.'#13#10 + 
                    'Всего просканировано: ' + bts;
 lbspeed.Show;
 btnBreakClose.caption := 'Закрыть';
end;

end.
