program TestPipeServer;

uses
  Vcl.Forms,
  utestservermain in 'utestservermain.pas' {frmTestPipeServer},
  upipetypes in '..\..\src\shared\upipetypes.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmTestPipeServer, frmTestPipeServer);
  Application.Run;

end.
