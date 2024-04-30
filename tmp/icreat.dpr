program icreat;

uses
  Forms,
  icreater in 'icreater.pas' {FormX};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormX, FormX);
  Application.Run;
end.
