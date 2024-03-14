program Food;

uses
  System.StartUpCopy,
  FMX.Forms,
  Frame.Produto in 'Frames\Frame.Produto.pas' {FrameProduto: TFrame},
  uLoading in 'uLoading.pas',
  UnitCheckout in 'UnitCheckout.pas' {FrmCheckout},
  UnitPedido in 'UnitPedido.pas' {FrmPedido},
  Frame.Categoria in 'Frames\Frame.Categoria.pas' {FrameCategoria: TFrame},
  UnitPrincipal in 'UnitPrincipal.pas' {FrmPrincipal},
  DataModule.Global in 'DataModules\DataModule.Global.pas' {Dm: TDataModule},
  Frame.Opcional in 'Frames\Frame.Opcional.pas' {FrameOpcional: TFrame},
  UnitLogin in 'UnitLogin.pas' {FrmLogin},
  uFunctions in 'Units\uFunctions.pas';

//  uSession in 'uSession.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDm, Dm);
  Application.CreateForm(TFrmLogin, FrmLogin);
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
