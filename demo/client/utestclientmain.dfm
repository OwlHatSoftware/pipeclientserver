object frmTestPipeClient: TfrmTestPipeClient
  Left = 0
  Top = 0
  Caption = 'Test Pipe Client'
  ClientHeight = 462
  ClientWidth = 461
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDesigned
  OnCreate = FormCreate
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 461
    Height = 75
    Align = alTop
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 0
    DesignSize = (
      461
      75)
    object Label1: TLabel
      Left = 16
      Top = 39
      Width = 47
      Height = 13
      Caption = 'PipeName'
    end
    object Label2: TLabel
      Left = 16
      Top = 10
      Width = 59
      Height = 13
      Caption = 'ServerName'
    end
    object Edit1: TEdit
      Left = 108
      Top = 12
      Width = 189
      Height = 21
      TabOrder = 0
      Text = 'Edit1'
    end
    object btnConnect: TButton
      Left = 328
      Top = 12
      Width = 121
      Height = 50
      Anchors = [akTop, akRight]
      Caption = 'Connect'
      TabOrder = 1
      OnClick = btnConnectClick
    end
    object Edit2: TEdit
      Left = 108
      Top = 39
      Width = 189
      Height = 21
      TabOrder = 2
      Text = 'Edit2'
    end
  end
  object GroupBox1: TGroupBox
    Left = 0
    Top = 75
    Width = 461
    Height = 282
    Align = alClient
    Caption = 'Message To Send'
    TabOrder = 1
    object Panel2: TPanel
      Left = 248
      Top = 15
      Width = 211
      Height = 265
      Align = alRight
      BevelOuter = bvNone
      Caption = 'Panel2'
      ShowCaption = False
      TabOrder = 0
      DesignSize = (
        211
        265)
      object SendButton: TButton
        Left = 6
        Top = 220
        Width = 195
        Height = 41
        Anchors = [akLeft, akBottom]
        Caption = 'Send'
        TabOrder = 0
        OnClick = SendButtonClick
      end
      object GroupBox3: TGroupBox
        Left = 6
        Top = 40
        Width = 195
        Height = 174
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Anchors = [akLeft, akTop, akBottom]
        Caption = 'Clients'
        TabOrder = 1
        object liClients: TListBox
          AlignWithMargins = True
          Left = 5
          Top = 18
          Width = 185
          Height = 151
          Align = alClient
          ItemHeight = 13
          MultiSelect = True
          TabOrder = 0
        end
      end
      object RadioGroup1: TRadioGroup
        Left = 6
        Top = 0
        Width = 195
        Height = 33
        Caption = 'Send To'
        Columns = 2
        ItemIndex = 0
        Items.Strings = (
          'All'
          'Client')
        TabOrder = 2
      end
    end
    object Memo2: TMemo
      Left = 2
      Top = 15
      Width = 246
      Height = 265
      Align = alClient
      Lines.Strings = (
        'Memo2')
      TabOrder = 1
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 357
    Width = 461
    Height = 105
    Align = alBottom
    Caption = 'Messages'
    TabOrder = 2
    object Memo1: TMemo
      Left = 2
      Top = 15
      Width = 457
      Height = 88
      Align = alClient
      Lines.Strings = (
        'Memo1')
      TabOrder = 0
    end
  end
end
