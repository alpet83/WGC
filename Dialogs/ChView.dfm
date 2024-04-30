object GVform: TGVform
  Left = 282
  Top = 131
  Width = 640
  Height = 450
  Caption = 'GameView'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClick = FormClick
  OnCreate = FormCreate
  OnMouseMove = FormMouseMove
  OnResize = FormResize
  OnShow = FormShow
  DesignSize = (
    632
    416)
  PixelsPerInch = 96
  TextHeight = 13
  object btnClose: TButton
    Left = 552
    Top = 392
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    TabOrder = 0
    OnClick = btnCloseClick
  end
end
