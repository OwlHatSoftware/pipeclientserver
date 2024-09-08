unit utestclientmain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmTestPipeClient = class(TForm)
    Panel1: TPanel;
    Edit1: TEdit;
    btnConnect: TButton;
    GroupBox1: TGroupBox;
    Panel2: TPanel;
    SendButton: TButton;
    Memo2: TMemo;
    GroupBox2: TGroupBox;
    Memo1: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    Edit2: TEdit;
    GroupBox3: TGroupBox;
    liClients: TListBox;
    RadioGroup1: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure SendButtonClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
  private
    { Private declarations }
    fConnected: boolean;
    fID: integer;
  public
    { Public declarations }
    property ClientID: integer read fID write fID;
  end;

var
  frmTestPipeClient: TfrmTestPipeClient;

implementation

{$R *.dfm}

uses upipetypes, superobject, supertypes;

function InitPipeClient(PipeName: PAnsiChar; CallBack: TCallBackFunction)
  : PAnsiChar; register; stdcall; external('PipeClient.dll');
function ConnectPipeClient(WaitTime: integer): boolean; register; stdcall;
  external('PipeClient.dll');
procedure PipeClientMessageToServer(Msg: PAnsiChar); register; stdcall;
  external('PipeClient.dll');

function CallBack(msgType: integer; var pipeID: integer; var answer: PAnsiChar;
  var param: DWORD): boolean; stdcall;
var
  pid, i: integer;
  s, m: AnsiString;
  method: string;
  p: DWORD;
  json: ISuperObject;
  jsonarray: TSuperArray;
begin
  Result := True;
  pid := pipeID;
  s := StrPas(answer);
  p := param;
  case msgType of
    MSG_PIPESENT:
      m := 'MSG_PIPESENT';
    MSG_PIPECONNECT:
      m := 'MSG_PIPECONNECT';
    MSG_PIPEDISCONNECT:
      begin
        m := 'MSG_PIPEDISCONNECT';
        frmTestPipeClient.btnConnect.Enabled := True;
        frmTestPipeClient.fConnected := False;
        with frmTestPipeClient do
        begin
          fID := -1;
          fConnected := False;
          Memo1.Clear;
          Memo2.Clear;
          liClients.Items.Clear;
          Caption := 'Test Pipe Client';
        end;
      end;
    MSG_PIPEMESSAGE:
      begin
        m := 'MSG_PIPEMESSAGE';
        try
          json := TSuperObject.ParseString(PSOChar(WideString(s)), True);
          if not assigned(json) then
            raise Exception.Create('Incorrect JSON string!');
          method := json.GetS('method');
          if method = 'GetClientID' then
          begin
            frmTestPipeClient.ClientID := json.GetI('ClientID');
            frmTestPipeClient.Caption := frmTestPipeClient.Caption + ' - #' +
              IntToStr(frmTestPipeClient.ClientID);
          end;
          if method = 'GetConnectedPipeClients' then
          begin
            frmTestPipeClient.liClients.Items.Clear;
            jsonarray := json.GetA('ClientIDs');
            for i := 0 to jsonarray.Length - 1 do
              if jsonarray[i].AsInteger <> 0 then
                if jsonarray[i].AsInteger <> frmTestPipeClient.ClientID then
                  frmTestPipeClient.liClients.Items.Add
                    (jsonarray[i].AsInteger.ToString);
          end;
        except
          on E: Exception do
            ShowMessage(E.Message);
        end;
      end;
    MSG_PIPEERROR:
      m := 'MSG_PIPEERROR';
    MSG_GETPIPECLIENTS:
      m := 'MSG_GETPIPECLIENTS';
  else
    Result := False;
  end;
  frmTestPipeClient.Memo1.Lines.Insert(0, Format('%s: %s, PID: %d, Param: %d',
    [m, s, pid, p]));
end;

procedure TfrmTestPipeClient.btnConnectClick(Sender: TObject);
begin
  fConnected := ConnectPipeClient(20000);
  if not fConnected then
    Memo1.Lines.Insert(0, 'PipeClient connect failed')
  else
  begin
    Memo1.Lines.Insert(0, 'PipeClient connected');
    btnConnect.Enabled := False;
  end;
end;

procedure TfrmTestPipeClient.FormCreate(Sender: TObject);
begin
  fID := -1;
  fConnected := False;
  Memo1.Clear;
  Memo2.Clear;
  Edit2.Text := 'PipeServer';
  Edit1.Text := StrPas(InitPipeClient(PAnsiChar(AnsiString(Edit2.Text)),
    @CallBack));
end;

procedure TfrmTestPipeClient.SendButtonClick(Sender: TObject);
var
  json, jsonarray: ISuperObject;
  i, v: integer;
begin
  if fConnected then
  begin
    json := SO();
    json.s['method'] := 'SendMessageTo';
    json.s['message'] := Memo2.Text;
    jsonarray := SA([]);
    case RadioGroup1.ItemIndex of
      0:
        begin
          for i := 0 to liClients.Count - 1 do
            if TryStrToInt(liClients.Items[i], v) then
              jsonarray.i['ID'] := v;
        end;
      1:
        begin
          // i:=StrToInt(liClients.Items[liClients.ItemIndex]);
          for i := 0 to liClients.Count - 1 do
            if liClients.Selected[i] then
              if TryStrToInt(liClients.Items[i], v) then
                jsonarray.i['ID'] := v;
        end;
    end;
    json.O['targetPIDs'] := jsonarray;
    // json.I['targetID']:=i;
    PipeClientMessageToServer(PAnsiChar(AnsiString(json.AsJSon())))
  end
  else
    ShowMessage('Connect to the server first!');
end;

end.
