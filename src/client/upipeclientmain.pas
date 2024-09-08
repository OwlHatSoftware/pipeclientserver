unit upipeclientmain;

interface

uses
  system.Types, system.SysUtils, system.Classes,
  pipes, //the famous unit of Russel Libby modified by Francis Piette
  upipetypes;

  function InitPipeClient(PipeName: PAnsiChar; CallBack: TCallBackFunction)
  : PAnsiChar; stdcall;
  function ConnectPipeClient(WaitTime: integer): boolean; stdcall;
  procedure PipeClientMessageToServer(Msg: PAnsiChar); stdcall;

implementation

resourcestring
  StrClientConnected = 'Client %d Connected!';
  StrClientDisconnected = 'Client %d Disconnected!';

type
  // dummy class to hold the event handlers
  TEventHandlers = class
  private
    class procedure DoPipeSent(Sender: TObject; Pipe: HPIPE; Size: DWORD);
    class procedure DoPipeDisconnect(Sender: TObject; Pipe: HPIPE);
    class procedure DoPipeMessage(Sender: TObject; Pipe: HPIPE;
      Stream: TStream);
    class procedure DoPipeError(Sender: TObject; Pipe: HPIPE;
      PipeContext: TPipeContext; ErrorCode: integer);
  end;

var
  fPipeClient: TPipeClient;
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
  aPipe: Int32;
begin
  if Assigned(fCallBack) then
  begin
    Answer := nil;
    Param := Size;
    aPipe:=Pipe;
    fCallBack(MSG_PIPESENT, aPipe, Answer, Param);
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
  aPipe: Int32;
begin
  if Assigned(fCallBack) then
  begin
    Answer := PAnsiChar(AnsiString(Format(StrClientDisconnected,
      [integer(Pipe)])));
    Param := Length(StrClientDisconnected);
    aPipe:=integer(Pipe);
    fCallBack(MSG_PIPEDISCONNECT, aPipe, Answer, Param);
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
  aPipe: Int32;
begin
  if Assigned(fCallBack) then
  begin
    Reader := TStreamReader.Create(Stream, TEncoding.Unicode);
    try
      s := Reader.ReadToEnd;
      Answer := PAnsiChar(AnsiString(s));
      Param := Length(s);
      aPipe:=integer(Pipe);
      fCallBack(MSG_PIPEMESSAGE, aPipe, Answer, Param);
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
  aPipe: Int32;
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
    aPipe:=integer(Pipe);
    fCallBack(MSG_PIPEERROR, aPipe, Answer, Param);
  end;
end;

// *****************************************************************************
function InitPipeClient(PipeName: PAnsiChar; CallBack: TCallBackFunction)
  : PAnsiChar; stdcall;
// *****************************************************************************
// * Initialize the pipeclient
// * ---------------------------------------------------------------------------
// * @PipeName: is the name of the pipe to communicate with
// *            make sure your client is initialized with the same name
// * Returns: computername of the pipeserver
// *****************************************************************************
begin
  fCallBack := CallBack;
  fPipeClient := TPipeClient.CreateUnowned;
  fPipeClient.PipeName := StrPas(PipeName);
  fPipeClient.OnPipeSent := TEventHandlers.DoPipeSent;
  fPipeClient.OnPipeDisconnect := TEventHandlers.DoPipeDisconnect;
  fPipeClient.OnPipeMessage := TEventHandlers.DoPipeMessage;
  fPipeClient.OnPipeError := TEventHandlers.DoPipeError;
  Result := PAnsiChar(AnsiString(pipes.ComputerName));
end;

// *****************************************************************************
function ConnectPipeClient(WaitTime: integer): boolean; stdcall;
// *****************************************************************************
// *  Connect the pipe client
// * ---------------------------------------------------------------------------
// * Returns: True when started, False when not.
// *****************************************************************************
begin
  Result := False;
  if Assigned(fPipeClient) and not Result then
  begin
    if fPipeClient.Connect(WaitTime, True) then
      Result := True;
  end;
end;

// *****************************************************************************
procedure PipeClientMessageToServer(Msg: PAnsiChar); stdcall;
// *****************************************************************************
// * Sends a message to the Server
// * ---------------------------------------------------------------------------
// * @Msg: the message to broadcast
// *****************************************************************************
var
  m: string;
  MemStream: TMemoryStream;
  Writer: TStreamWriter;
begin
  if Assigned(fPipeClient) then
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
      fPipeClient.SendStream(MemStream);
    finally
      MemStream.Free;
    end; 
  end;
end;

end.
