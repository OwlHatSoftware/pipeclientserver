unit upipeservermain;

interface

uses
  system.Types, system.SysUtils, system.Classes
  ,pipes //the famous unit of Russel Libby modified by Francis Piette
  ,upipetypes //some types and constants for use in this dll's
//  ,uhelperfuncs
  ; //some helper functions and procedures

function InitPipeServer(PipeName: PAnsiChar; CallBack: TCallBackFunction)
  : PAnsiChar; stdcall;
function StartPipeServer(): boolean; stdcall;
function StopPipeServer(): boolean; stdcall;
procedure GetConnectedPipeClients; stdcall;
procedure BroadcastPipeServerMessage(Msg: PAnsiChar; Size: integer); stdcall;
procedure PipeServerMessageToClient(Pipe: integer; Msg: PAnsiChar); stdcall;
procedure DonePipeServer(); stdcall;

implementation

resourcestring
  StrClientConnected = 'Client %d Connected!';
  StrClientDisconnected = 'Client %d Disconnected!';

type
  // dummy class to hold the event handlers
  TEventHandlers = class
  private
    class procedure DoPipeSent(Sender: TObject; Pipe: HPIPE; Size: DWORD);
    class procedure DoPipeConnect(Sender: TObject; Pipe: HPIPE);
    class procedure DoPipeDisconnect(Sender: TObject; Pipe: HPIPE);
    class procedure DoPipeMessage(Sender: TObject; Pipe: HPIPE;
      Stream: TStream);
    class procedure DoPipeError(Sender: TObject; Pipe: HPIPE;
      PipeContext: TPipeContext; ErrorCode: integer);
  end;

var
  fPipeServer: TPipeServer;
  fCallBack: TCallBackFunction;

// *****************************************************************************
class procedure TEventHandlers.DoPipeSent(Sender: TObject; Pipe: HPIPE;
  Size: DWORD);
// *****************************************************************************
// * Event triggered when Data message is sent through pipe
// * ---------------------------------------------------------------------------
// * @Sender: calling object
// * @Pipe: the pipe handle
// * @Size: size of the message
// *****************************************************************************
var
  Answer: PAnsiChar;
  Param: DWORD;
  LPipe: Int32;
begin
  if Assigned(fCallBack) then
  begin
    Answer := nil;
    Param := Size;
    LPipe := Int32(Pipe);
    fCallBack(MSG_PIPESENT, LPipe, Answer, Param);
  end;
end;

// *****************************************************************************
class procedure TEventHandlers.DoPipeConnect(Sender: TObject; Pipe: HPIPE);
// *****************************************************************************
// * Captures connect event
// * ---------------------------------------------------------------------------
// * @Sender: calling object
// * @Pipe: the pipe handle
// *****************************************************************************
var
  Answer: PAnsiChar;
  Param: DWORD;
  LPipe: Int32;
begin
  if Assigned(fCallBack) then
  begin
    Answer := PAnsiChar(AnsiString(Format(StrClientConnected,
      [integer(Pipe)])));
    Param := Length(StrClientConnected);
    LPipe := Int32(Pipe);
    fCallBack(MSG_PIPECONNECT, LPipe, Answer, Param);
  end;
end;

// *****************************************************************************
class procedure TEventHandlers.DoPipeDisconnect(Sender: TObject; Pipe: HPIPE);
// *****************************************************************************
// * Captures disconnect event
// * ---------------------------------------------------------------------------
// * @Sender: calling object
// * @Pipe: the pipe handle
// *****************************************************************************
var
  Answer: PAnsiChar;
  Param: DWORD;
  LPipe: Int32;
begin
  if Assigned(fCallBack) then
  begin
    Answer := PAnsiChar(AnsiString(Format(StrClientDisconnected,
      [integer(Pipe)])));
    Param := Length(StrClientDisconnected);
    LPipe := Int32(Pipe);
    fCallBack(MSG_PIPEDISCONNECT, LPipe, Answer, Param);
  end;
end;

// *****************************************************************************
class procedure TEventHandlers.DoPipeMessage(Sender: TObject; Pipe: HPIPE;
  Stream: TStream);
// *****************************************************************************
// * Captures the message event
// * ---------------------------------------------------------------------------
// * @Sender: calling object
// * @Pipe: the pipe handle
// * @Stream: the message stream
// *****************************************************************************
var
  s: string;
  Answer: PAnsiChar;
  Param: DWORD;
  Reader: TStreamReader;
  LPipe: Int32;
begin
  if Assigned(fCallBack) then
  begin
    Reader := TStreamReader.Create(Stream, TEncoding.Unicode);
    try
      s := Reader.ReadToEnd;
      Answer := PAnsiChar(AnsiString(s));
      Param := Length(s);
      LPipe:= Int32(Pipe);
      fCallBack(MSG_PIPEMESSAGE, LPipe, Answer, Param);
    finally
      Reader.Free;
    end;
  end;
end;

// *****************************************************************************
class procedure TEventHandlers.DoPipeError(Sender: TObject; Pipe: HPIPE;
  PipeContext: TPipeContext; ErrorCode: integer);
// *****************************************************************************
// * Captures an error
// * ---------------------------------------------------------------------------
// * @Sender: calling object
// * @Pipe: the pipe handle
// * @PipeContext: Worker or Listener Thread
// * @ErrorCode: the generated errorcode
// *****************************************************************************
var
  s: AnsiString;
  Answer: PAnsiChar;
  Param: DWORD;
  LPipe: Int32;
begin
  if Assigned(fCallBack) then
  begin
    case PipeContext of
      pcWorker:
        s := 'Worker Thread: ' + SysErrorMessage(ErrorCode);
      pcListener:
        s := 'Listener Thread: ' + SysErrorMessage(ErrorCode);
    end;
    Answer := PAnsiChar(AnsiString(s));
    Param := ErrorCode;
    LPipe:= Int32(Pipe);
    fCallBack(MSG_PIPEERROR, LPipe, Answer, Param);
  end;
end;

// *****************************************************************************
function InitPipeServer(PipeName: PAnsiChar; CallBack: TCallBackFunction)
  : PAnsiChar; stdcall;
// *****************************************************************************
// * Initialize the pipeserver
// * ---------------------------------------------------------------------------
// * @PipeName: is the name of the pipe to communicate with
// *            make sure your client is initialized with the same name
// * Returns: computername of the pipeserver
// *****************************************************************************
begin
  fCallBack := CallBack;
  fPipeServer := TPipeServer.CreateUnowned;
  fPipeServer.PipeName := StrPas(PipeName);
  fPipeServer.OnPipeSent := TEventHandlers.DoPipeSent;
  fPipeServer.OnPipeConnect := TEventHandlers.DoPipeConnect;
  fPipeServer.OnPipeDisconnect := TEventHandlers.DoPipeDisconnect;
  fPipeServer.OnPipeMessage := TEventHandlers.DoPipeMessage;
  fPipeServer.OnPipeError := TEventHandlers.DoPipeError;
  Result := PAnsiChar(AnsiString(pipes.ComputerName));
end;

// *****************************************************************************
function StartPipeServer(): boolean; stdcall;
// *****************************************************************************
// * Start the pipeserver
// * ---------------------------------------------------------------------------
// * Returns: True when started, False when not.
// *****************************************************************************
begin
  Result := fPipeServer.Active;
  if Assigned(fPipeServer) and not Result then
  begin
    fPipeServer.Active := True;
    Result := fPipeServer.Active;
  end;
end;

// *****************************************************************************
function StopPipeServer(): boolean; stdcall;
// *****************************************************************************
// * Stop the pipeserver
// * ---------------------------------------------------------------------------
// * Returns: False when stopped, True when not.
// *****************************************************************************
begin
  Result := fPipeServer.Active;
  if Assigned(fPipeServer) and Result then
  begin
    fPipeServer.Active := False;
    Result := fPipeServer.Active;
  end;
end;

// *****************************************************************************
procedure GetConnectedPipeClients; stdcall;
// *****************************************************************************
// * Get all connected clients. The callback event returns the ID's of the
// * connected clients as a delimited string
// *****************************************************************************
const
  Delimiter=';';
var
  i: Int32;
  s: string;
  Answer: PAnsiChar;
  Param: DWORD;
begin
  if Assigned(fPipeServer) and Assigned(fCallBack) then
  begin
    s:='';
    for i:=0 to fPipeServer.ClientCount-1 do
      if (i<>fPipeServer.ClientCount-1) then
        s:=s+IntToStr(fPipeServer.Clients[i])+Delimiter
      else s:=s+IntToStr(fPipeServer.Clients[i]);
    Answer:=PAnsiChar(AnsiString(s));
    Param:=Length(s);
    i:=-1;
    fCallBack(MSG_GETPIPECLIENTS, i, Answer, Param);
  end;
end;

// *****************************************************************************
procedure BroadcastPipeServerMessage(Msg: PAnsiChar; Size: integer); stdcall;
// *****************************************************************************
// * Broadcasts a string message to all connected clients
// * ---------------------------------------------------------------------------
// * @Msg: the message to broadcast
// * @Size: size of the message
// *****************************************************************************
var
  m: string;
begin
  if Assigned(fPipeServer) then
  begin
    m := StrPas(Msg);
    fPipeServer.Broadcast(PChar(m)^, Length(m) * SizeOf(Char));
  end;
end;

// *****************************************************************************
procedure PipeServerMessageToClient(Pipe: integer; Msg: PAnsiChar); stdcall;
// *****************************************************************************
// * Sends a string message to a specific client
// * ---------------------------------------------------------------------------
// * @Pipe: the client pipe ID
// * @Msg: the message to broadcast
// *****************************************************************************
var
  m: string;
  MemStream: TMemoryStream;
  Writer: TStreamWriter;
begin
  if Assigned(fPipeServer) then
  begin
    m := StrPas(Msg);
    MemStream := TMemoryStream.Create;
    try
      try
        Writer := TStreamWriter.Create(MemStream, TEncoding.Unicode);
        Writer.Write(m);
      finally
        Writer.Free
      end;
      fPipeServer.SendStream(Pipe, MemStream);
    finally
      MemStream.Free;
    end;
  end;
end;

// *****************************************************************************
procedure DonePipeServer(); stdcall;
// *****************************************************************************
// * Frees the pipeserver class
// * ---------------------------------------------------------------------------
// *
// *****************************************************************************
begin
  if Assigned(fPipeServer) then
    FreeAndNil(fPipeServer);
  fCallBack := nil;
end;

end.
