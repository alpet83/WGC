unit ChModeDlg;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TModeSelDlg = class(TForm)
    btnSimple: TButton;
    btnClassic: TButton;
    AFrame: TBevel;
    ldesc: TLabel;
    procedure btnSimpleClick(Sender: TObject);
    procedure btnClassicClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;



procedure RunModeSelDialog (var result: Boolean);
implementation
uses ChForm;
{$R *.dfm}
var
  ModeSelDlg: TModeSelDlg = nil;

procedure RunModeSelDialog (var result: Boolean);
begin
 if ModeSelDlg = nil then ModeSelDlg := TModeSelDlg.Create (mform);
 result := ModeSelDlg.ShowModal <> idNo; // True = simple mode
end;

procedure TModeSelDlg.btnSimpleClick(Sender: TObject);
begin
 ModalResult := idYes;
end;

procedure TModeSelDlg.btnClassicClick(Sender: TObject);
begin
 ModalResult := idNo;
end;

procedure TModeSelDlg.FormCreate(Sender: TObject);
begin
 ldesc.Caption :=
  '�������� � ����� ����������� �� ������ ������ ������:'#13#10 +
  '     1. ���������� ��������� ������������ ��� ��������, � �������������' +
  ' ��� ���������� � ����������.'#13#10 +
  '     2. ������������ ��������� ��������� ������ � �������������� ������������' +
  ' ���������, �� ��� ���������� ������������� ����� ���� ������.' +
  ' ������������� ������������ ����� �������� �������� ������� ������ � WGC.'#13#10#10 +
  ' P.S. ��������� �� ���������� Interface (�����������) - ����� �������� ��� ���������';
end;

end.
