unit upipeservicemain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Win.Registry,
  Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs;

const
  C_SERVICEDESCRIPTION = 'Test Pipe Service';

type
  TPipeTestService = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceAfterUninstall(Sender: TService);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  PipeTestService: TPipeTestService;

implementation

{$R *.dfm}
{$R MyServiceMessageResource.res}

uses upipetypes, superobject, supertypes;

function InitPipeServer(PipeName: PAnsiChar; CallBack: TCallBackFunction): PAnsiChar; register; stdcall; external('PipeServer.dll');
function StartPipeServer(): boolean; register; stdcall; external('PipeServer.dll');
function StopPipeServer(): boolean; register; stdcall; external('PipeServer.dll');
procedure GetConnectedPipeClients; register; stdcall; external('PipeServer.dll');
procedure BroadcastPipeServerMessage(Msg: PAnsiChar; Size: integer); register; stdcall; external('PipeServer.dll');
procedure PipeServerMessageToClient(Pipe: integer; Msg: PAnsiChar); register; stdcall; external('PipeServer.dll');
procedure DonePipeServer(); register; stdcall; external('PipeServer.dll');

procedure ParseDelimited(const sl : TStrings; const value : string;
  const delimiter : string) ;
var
   dx : integer;
   ns : string;
   txt : string;
   delta : integer;
begin
   delta := Length(delimiter) ;
   txt := value + delimiter;
   sl.BeginUpdate;
   sl.Clear;
   try
     while Length(txt) > 0 do
     begin
       dx := Pos(delimiter, txt) ;
       ns := Copy(txt,0,dx-1) ;
       sl.Add(ns) ;
       txt := Copy(txt,dx+delta,MaxInt) ;
     end;
   finally
     sl.EndUpdate;
   end;
end;

function CallBack(msgType: integer;
    var pipeID: integer; var answer: PAnsiChar; var param: DWORD):boolean; stdcall;
var
  pid, i, v: integer;
  s,m: AnsiString;
  json, arrobj: ISuperObject;
  jsonarray: TSuperArray;
  p: DWORD;
  SL: TStringList;
  method: string;
begin
  m:='';
  pid:=pipeID;
  s:=StrPas(answer);
  p:=param;
  case msgType  of
    MSG_PIPESENT       : m:='MSG_PIPESENT';
    MSG_PIPECONNECT    :
      begin
        m:='MSG_PIPECONNECT';
        json:=TSuperObject.Create();
        json.S['method']:='GetClientID';
        json.I['ClientID']:=pid;
        PipeServerMessageToClient(pid, PansiChar(AnsiString(json.AsJSon())));
        GetConnectedPipeClients;
      end;
    MSG_PIPEDISCONNECT :
      begin
        m:='MSG_PIPEDISCONNECT';
        GetConnectedPipeClients;
      end;
    MSG_PIPEMESSAGE    :
      begin
        m:='MSG_PIPEMESSAGE';
        try
          json:=TSuperObject.ParseString(PSOChar(WideString(s)), true);
          if not assigned(json) then
            raise Exception.Create('Incorrect JSON string!');
          method:=json.GetS('method');
          if method='SendMessageTo' then
          begin
            jsonarray:=json.GetA('targetPIDs');
            for i:=0 to jsonarray.Length-1 do
              PipeServerMessageToClient(jsonarray[i].AsInteger, PansiChar(AnsiString(json.AsJSON())));
          end;
        except
          on E: Exception do
            ShowMessage(E.Message);
        end;
      end;
    MSG_PIPEERROR      : m:='MSG_PIPEERROR';
    MSG_GETPIPECLIENTS :
      begin
        m:='MSG_GETPIPECLIENTS';
        SL:=TStringList.Create;
        try
          ParseDelimited(SL, s, ';');
          json:=SO();
          json.S['method']:='GetConnectedPipeClients';
          arrobj:=SA([]);
          for i:=0 to SL.Count-1 do
          if TryStrToInt(SL[i], v) then
            arrobj.I['ID']:=v;
          json.O['ClientIDs']:=arrobj;
          BroadcastPipeServerMessage(PansiChar(AnsiString(json.AsString)), Length(json.AsString));
        finally
          FreeAndNil(SL);
        end;
      end;
  end;
  if m<>'' then
    PipeTestService.LogMessage(Format('%s: %s, PID: %d, Param: %d',[m,s,pid,p]), EVENTLOG_INFORMATION_TYPE, 0, 2);
end;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  PipeTestService.Controller(CtrlCode);
end;

function TPipeTestService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TPipeTestService.ServiceAfterInstall(Sender: TService);
var
  Reg: TRegistry;
  Key: string;
begin
  // Create a service description
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('\SYSTEM\CurrentControlSet\Services\' + Name, false) then
    begin
      Reg.WriteString('Description', C_SERVICEDESCRIPTION);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
  // Create registry entries so that the event viewer show messages
  // properly when we use the LogMessage method.
  Key := '\SYSTEM\CurrentControlSet\Services\Eventlog\Application\' + Self.Name;
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey(Key, True) then
    begin
      Reg.WriteString('EventMessageFile', ParamStr(0));
      Reg.WriteInteger('TypesSupported', 7);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TPipeTestService.ServiceAfterUninstall(Sender: TService);
var
  Reg: TRegistry;
  Key: string;
begin
  // Delete registry entries for event viewer.
  Key := '\SYSTEM\CurrentControlSet\Services\Eventlog\Application\' + Self.Name;
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.KeyExists(Key) then
      Reg.DeleteKey(Key);
  finally
    Reg.Free;
  end;
end;

procedure TPipeTestService.ServiceStart(Sender: TService; var Started: Boolean);
begin
  //First initialize the pipeservice
  InitPipeServer(PAnsiChar(AnsiString('PipeServer')), @CallBack);
  if StartPipeServer() then
    LogMessage('PipeServer Started!', EVENTLOG_INFORMATION_TYPE, 0, 2)
  else
  LogMessage('Unable to -START- PipeServer!', EVENTLOG_INFORMATION_TYPE, 0, 2);
end;

procedure TPipeTestService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  if not StopPipeServer() then
    LogMessage('PipeServer Stopped!', EVENTLOG_INFORMATION_TYPE, 0, 2)
  else
  LogMessage('Unable to -STOP- PipeServer!', EVENTLOG_INFORMATION_TYPE, 0, 2);
  DonePipeServer();
end;

end.
