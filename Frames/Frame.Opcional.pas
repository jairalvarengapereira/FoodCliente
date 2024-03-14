unit Frame.Opcional;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts;

type
  TFrameOpcional = class(TFrame)
    imgFotoOpcional: TImage;
    lblNomeOpcional: TLabel;
    lblPrecoOpcional: TLabel;
    Rectangle1: TRectangle;
    chbOpcional: TCheckBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
