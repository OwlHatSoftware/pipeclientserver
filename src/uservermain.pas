unit uservermain;

interface

uses pipes, system.SysUtils;

procedure InitPipeServer(PipeName: PChar); stdcall;

implementation

var
  fPipeServer: TPipeServer;

//******************************************************************************
procedure InitPipeServer(PipeName: PChar); stdcall;
//******************************************************************************
//* Initialize the pipeserver
//* -------------------------
//* @PipeName: is the name of the pipe to communicate with
//*            make sure your client is initialized with the same name
//******************************************************************************
begin
  fPipeServer:=TPipeServer.CreateUnowned;
  fPipeServer.PipeName:=StrPas(PipeName);
  fPipeServer.OnPipeSent:=DoPipeSent;
  fPipeServer.OnPipeConnect:=DoPipeConnect;
  fPipeServer.OnPipeDisconnect:=DoPipeDisconnect;
  fPipeServer.OnPipeMessage:=DoPipeMessage;
  fPipeServer.OnPipeError:=DoPipeError;
end;

procedure StartServer();
begin

end;

procedure StopServer();
begin

end;

procedure DonePipeServer;
begin
  if fPipeServer<>nil then
    FreeAndNil(fPipeServer);
end;

procedure DoPipeSent(Sender : TObject; Pipe : HPIPE; Size : DWORD);
begin

end;

end.
