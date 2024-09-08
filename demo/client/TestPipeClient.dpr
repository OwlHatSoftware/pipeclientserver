program TestPipeClient;

uses
  Forms,
  utestclientmain in 'utestclientmain.pas' {frmTestPipeClient},
  upipetypes in '..\..\src\shared\upipetypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmTestPipeClient, frmTestPipeClient);
  Application.Run;
end.
