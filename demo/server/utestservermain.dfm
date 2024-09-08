object frmTestPipeServer: TfrmTestPipeServer
  Left = 0
  Top = 0
  Caption = 'Test Pipe Server'
  ClientHeight = 499
  ClientWidth = 677
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 677
    Height = 73
    Align = alTop
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 11
      Width = 59
      Height = 13
      Caption = 'ServerName'
    end
    object Label2: TLabel
      Left = 16
      Top = 38
      Width = 47
      Height = 13
      Caption = 'PipeName'
    end
    object Edit1: TEdit
      Left = 81
      Top = 11
      Width = 184
      Height = 21
      TabOrder = 0
      Text = 'Edit1'
    end
    object Edit2: TEdit
      Left = 81
      Top = 38
      Width = 184
      Height = 21
      TabOrder = 1
      Text = 'Edit2'
    end
    object btnStartServer: TButton
      Left = 304
      Top = 9
      Width = 75
      Height = 25
      Caption = 'Start'
      TabOrder = 2
      OnClick = btnStartServerClick
    end
    object btnStopServer: TButton
      Left = 304
      Top = 40
      Width = 75
      Height = 25
      Caption = 'Stop'
      TabOrder = 3
      OnClick = btnStopServerClick
    end
  end
  object GroupBox1: TGroupBox
    Left = 0
    Top = 381
    Width = 677
    Height = 118
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alBottom
    Caption = 'Messages'
    Padding.Left = 5
    Padding.Top = 5
    Padding.Right = 5
    Padding.Bottom = 5
    TabOrder = 1
    object Memo1: TMemo
      Left = 7
      Top = 20
      Width = 663
      Height = 91
      Align = alClient
      Lines.Strings = (
        'Memo1')
      TabOrder = 0
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 73
    Width = 677
    Height = 308
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alClient
    Caption = 'Broadcast'
    Padding.Left = 5
    Padding.Top = 5
    Padding.Right = 5
    Padding.Bottom = 5
    TabOrder = 2
    object Panel2: TPanel
      Left = 416
      Top = 20
      Width = 254
      Height = 281
      Align = alRight
      BevelOuter = bvNone
      Caption = 'Panel2'
      ShowCaption = False
      TabOrder = 0
      DesignSize = (
        254
        281)
      object RadioGroup1: TRadioGroup
        Left = 16
        Top = 0
        Width = 233
        Height = 34
        Caption = 'Broadcast To'
        Columns = 2
        ItemIndex = 0
        Items.Strings = (
          'All'
          'Client')
        TabOrder = 0
      end
      object GroupBox3: TGroupBox
        Left = 16
        Top = 40
        Width = 233
        Height = 178
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Anchors = [akLeft, akTop, akBottom]
        Caption = 'Client ID'
        TabOrder = 1
        object liClients: TListBox
          AlignWithMargins = True
          Left = 5
          Top = 18
          Width = 223
          Height = 155
          Align = alClient
          ItemHeight = 13
          MultiSelect = True
          TabOrder = 0
        end
      end
      object btnBroadCast: TButton
        Left = 16
        Top = 224
        Width = 233
        Height = 55
        Anchors = [akLeft, akBottom]
        Caption = 'Broadcast'
        TabOrder = 2
        OnClick = btnBroadCastClick
      end
    end
    object Memo2: TMemo
      Left = 7
      Top = 20
      Width = 409
      Height = 281
      Align = alClient
      Lines.Strings = (
        'Memo2')
      TabOrder = 1
    end
  end
end
