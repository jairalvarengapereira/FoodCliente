unit UnitLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Edit, uLoading;

type
  TFrmLogin = class(TForm)
    Image3: TImage;
    Label10: TLabel;
    Layout1: TLayout;
    Layout2: TLayout;
    Label8: TLabel;
    rectEdtWhatsApp: TRectangle;
    edtWhatsapp: TEdit;
    rectLogin: TRectangle;
    btnLogin: TSpeedButton;
    procedure btnLoginClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure ThreadLoginTerminate(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmLogin: TFrmLogin;

implementation

{$R *.fmx}

uses DataModule.Global, UnitPrincipal, uSession;

procedure TFrmLogin.btnLoginClick(Sender: TObject);
var
  t: TThread;
begin
  TLoading.Show(FrmLogin,'');

  t:= TThread.CreateAnonymousThread(procedure
  begin
    Dm.Login(edtWhatsapp.Text);
    Dm.EditarUsuarioLocal(Dm.TabUsuario.FieldByName('id_usuario').AsInteger,
                          Dm.TabUsuario.FieldByName('fone'      ).AsString,
                          Dm.TabUsuario.FieldByName('endereco'  ).AsString);

    TSession.ID_USUARIO := Dm.TabUsuario.FieldByName('id_usuario').AsInteger;
    TSession.FONE       := Dm.TabUsuario.FieldByName('fone'      ).AsString;
    TSession.ENDERECO   := Dm.TabUsuario.FieldByName('endereco'  ).AsString;

  end);
  t.OnTerminate := ThreadLoginTerminate;
  t.Start;
end;

procedure ValidarUsuario;
begin
  Dm.ListarUsuarioLocal;

  if Dm.qryUsuario.RecordCount > 0 then
  begin
    TSession.ID_USUARIO := Dm.qryUsuario.FieldByName('id_usuario').AsInteger;
    TSession.FONE       := Dm.qryUsuario.FieldByName('fone'      ).AsString;
    TSession.ENDERECO   := Dm.qryUsuario.FieldByName('endereco'  ).AsString;

    Application.MainForm := FrmPrincipal;
    FrmPrincipal.Show;
    FrmLogin.Close;
  end;
end;

procedure TFrmLogin.FormShow(Sender: TObject);
begin
  ValidarUsuario;
end;

procedure TFrmLogin.ThreadLoginTerminate(Sender: TObject);
begin
  TLoading.Hide;
  if Sender is TThread then
  begin
    if Assigned(TThread(Sender).FatalException) then
    begin
      ShowMessage(Exception(TThread(Sender).FatalException).Message);
      Exit;
    end;
  end;

  FrmPrincipal.Show;
end;

end.
