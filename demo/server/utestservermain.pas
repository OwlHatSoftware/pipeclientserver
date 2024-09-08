unit utestservermain;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.AnsiStrings,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TfrmTestPipeServer = class(TForm)
    Panel1: TPanel;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Edit2: TEdit;
    btnStartServer: TButton;
    btnStopServer: TButton;
    GroupBox1: TGroupBox;
    Memo1: TMemo;
    GroupBox2: TGroupBox;
    Panel2: TPanel;
    RadioGroup1: TRadioGroup;
    GroupBox3: TGroupBox;
    btnBroadCast: TButton;
    Memo2: TMemo;
    liClients: TListBox;
    procedure btnStartServerClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnStopServerClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBroadCastClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmTestPipeServer: TfrmTestPipeServer;

implementation

{$R *.dfm}

uses upipetypes, superobject, supertypes;

type
  TStringArray = array of string;

function InitPipeServer(PipeName: PAnsiChar; CallBack: TCallBackFunction)
  : PAnsiChar; register; stdcall; external('PipeServer.dll');
function StartPipeServer(): boolean; register; stdcall;
  external('PipeServer.dll');
function StopPipeServer(): boolean; register; stdcall;
  external('PipeServer.dll');
procedure GetConnectedPipeClients; register; stdcall;
  external('PipeServer.dll');
procedure BroadcastPipeServerMessage(Msg: PAnsiChar; Size: integer); register;
  stdcall; external('PipeServer.dll');
procedure PipeServerMessageToClient(Pipe: integer; Msg: PAnsiChar); register;
  stdcall; external('PipeServer.dll');
procedure DonePipeServer(); register; stdcall; external('PipeServer.dll');

procedure ParseDelimited(const sl: TStrings; const value: string;
  const delimiter: string);
var
  dx: integer;
  ns: string;
  txt: string;
  delta: integer;
begin
  delta := Length(delimiter);
  txt := value + delimiter;
  sl.BeginUpdate;
  sl.Clear;
  try
    while Length(txt) > 0 do
    begin
      dx := Pos(delimiter, txt);
      ns := Copy(txt, 0, dx - 1);
      sl.Add(ns);
      txt := Copy(txt, dx + delta, MaxInt);
    end;
  finally
    sl.EndUpdate;
  end;
end;

function StringListToArray(sl: TStringList): TStringArray;
var
  i: integer;
begin
  // Convert from TStringList to Array of String
  SetLength(Result, sl.Count);
  For i := 0 To sl.Count - 1 Do
    Result[i] := sl[i];
end;

procedure ArrayToStringList(StringArray: TStringArray; out sl: TStringList);
var
  i: integer;
begin
  // Convert from Array of String to TStringList
  sl.Clear;
  for i := Low(StringArray) to High(StringArray) Do
    sl.Add(StringArray[i]);
end;

function CallBack(msgType: integer; var pipeID: integer; var answer: PAnsiChar;
  var param: DWORD): boolean; stdcall;
var
  pid, i, v: integer;
  s, m: AnsiString;
  json, arrobj: ISuperObject;
  jsonarray: TSuperArray;
  p: DWORD;
  sl: TStringList;
  method: string;
begin
  Result := True;
  m := '';
  pid := pipeID;
  s := System.AnsiStrings.StrPas(answer);
  p := param;
  case msgType of
    MSG_PIPESENT:
      m := 'MSG_PIPESENT';
    MSG_PIPECONNECT:
      begin
        m := 'MSG_PIPECONNECT';
        json := TSuperObject.Create();
        json.s['method'] := 'GetClientID';
        json.i['ClientID'] := pid;
        PipeServerMessageToClient(pid, PAnsiChar(AnsiString(json.AsJSon())));
        GetConnectedPipeClients;
      end;
    MSG_PIPEDISCONNECT:
      begin
        m := 'MSG_PIPEDISCONNECT';
        GetConnectedPipeClients;
      end;
    MSG_PIPEMESSAGE:
      begin
        m := 'MSG_PIPEMESSAGE';
        try
          json := TSuperObject.ParseString(PSOChar(WideString(s)), True);
          if not assigned(json) then
            raise Exception.Create('Incorrect JSON string!');
          method := json.GetS('method');
          if method = 'SendMessageTo' then
          begin
            jsonarray := json.GetA('targetPIDs');
            for i := 0 to jsonarray.Length - 1 do
              PipeServerMessageToClient(jsonarray[i].AsInteger,
                PAnsiChar(AnsiString(json.AsJSon())));
          end;
        except
          on E: Exception do
            ShowMessage(E.Message);
        end;
      end;
    MSG_PIPEERROR:
      m := 'MSG_PIPEERROR';
    MSG_GETPIPECLIENTS:
      begin
        m := 'MSG_GETPIPECLIENTS';
        sl := TStringList.Create;
        try
          ParseDelimited(sl, s, ';');
          frmTestPipeServer.liClients.Items := sl;
          json := SO();
          json.s['method'] := 'GetConnectedPipeClients';
          arrobj := SA([]);
          for i := 0 to sl.Count - 1 do
            if TryStrToInt(sl[i], v) then
              arrobj.i['ID'] := v;
          json.O['ClientIDs'] := arrobj;
          BroadcastPipeServerMessage(PAnsiChar(AnsiString(json.AsString)),
            Length(json.AsString));
        finally
          FreeAndNil(sl);
        end;
      end;
  else
    Result := False;
  end;
  if m <> '' then
    frmTestPipeServer.Memo1.Lines.Insert(0, Format('%s: %s, PID: %d, Param: %d',
      [m, s, pid, p]));
end;

procedure TfrmTestPipeServer.btnStartServerClick(Sender: TObject);
begin
  if StartPipeServer() then
  begin
    Memo1.Lines.Insert(0, 'PipeServer Started!');
    btnStartServer.Enabled := False;
    btnStopServer.Enabled := True;
  end
  else
    Memo1.Lines.Insert(0, 'Unable to -START- PipeServer!')
end;

procedure TfrmTestPipeServer.btnStopServerClick(Sender: TObject);
begin
  if not StopPipeServer() then
  begin
    Memo1.Lines.Insert(0, 'PipeServer Stopped!');
    btnStartServer.Enabled := True;
    btnStopServer.Enabled := False;
  end
  else
    Memo1.Lines.Insert(0, 'Unable to -STOP- PipeServer!');
end;

procedure TfrmTestPipeServer.btnBroadCastClick(Sender: TObject);
var
  s: string;
  json, jsonarray: ISuperObject;
  i, v: integer;
begin
  json := SO();
  if RadioGroup1.ItemIndex = 0 then
  begin
    json.s['method'] := 'BroadcastPipeServerMessage';
    json.s['message'] := Memo2.Text;
    // for i:=0 to liClients.Count-1 do
    // if TryStrToInt(liClients.Items[i], v) then
    // jsonarray.I['ID']:=v;
    // json.O['targetPIDs']:=jsonarray;
    BroadcastPipeServerMessage(PAnsiChar(AnsiString(json.AsJSon())),
      Length(json.AsJSon()));
  end
  else
  begin
    json.s['method'] := 'PipeServerMessageToClient';
    json.s['message'] := Memo2.Text;
    for i := 0 to liClients.Count - 1 do
      if liClients.Selected[i] then
        if TryStrToInt(liClients.Items[i], v) then
          PipeServerMessageToClient(v, PAnsiChar(AnsiString(json.AsJSon())));
  end;

end;

procedure TfrmTestPipeServer.FormCreate(Sender: TObject);
begin
  Memo1.Clear;
  Memo2.Clear;
  // Edit3.Text:='';
  Edit2.Text := 'PipeServer';
  btnStartServer.Enabled := True;
  btnStopServer.Enabled := False;
  Edit1.Text := System.AnsiStrings.StrPas
    (InitPipeServer(PAnsiChar(AnsiString(Edit2.Text)), @CallBack));
end;

procedure TfrmTestPipeServer.FormDestroy(Sender: TObject);
begin
  DonePipeServer();
end;

end.
