unit Frame.Produto;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects;

type
  TFrameProduto = class(TFrame)
    imgFoto: TImage;
    Layout1: TLayout;
    lblNome: TLabel;
    lblDescricao: TLabel;
    lblPreco: TLabel;
    Line1: TLine;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
