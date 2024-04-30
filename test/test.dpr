program test;

uses
  Forms,
  tester in 'tester.pas' {FormX};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'WGC Test Program';
  Application.CreateForm(TFormX, FormX);
  Application.Run;
end.
