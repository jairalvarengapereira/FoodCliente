unit UnitCheckout;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.ListBox,
  FMX.TabControl, FMX.Edit, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  System.JSON,
  uLoading;

type
  TFrmCheckout = class(TForm)
    rectToolbarPedido: TRectangle;
    Label1: TLabel;
    imgVoltar: TImage;
    rectFinalizar: TRectangle;
    btnFinalizar: TSpeedButton;
    rectTotal: TRectangle;
    rectEndereco: TRectangle;
    lytSubTotal: TLayout;
    Label2: TLabel;
    lblSubTotal: TLabel;
    lytTotal: TLayout;
    Label4: TLabel;
    lblTotal: TLabel;
    lytTaxaEntrega: TLayout;
    Label6: TLabel;
    lblTaxaEntrega: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lbCardapio: TListBox;
    TabControl: TTabControl;
    tbFinalizarPedido: TTabItem;
    tbPedidoFinalizado: TTabItem;
    imgFechar: TImage;
    Image3: TImage;
    Label10: TLabel;
    edtWhatsapp: TEdit;
    rectEdtWhatsApp: TRectangle;
    StyleBook1: TStyleBook;
    edtEndereco: TMemo;
    recEdtEndereco: TRectangle;
    SpeedButton1: TSpeedButton;
    Image1: TImage;
    tbSacolaVazia: TTabItem;
    Label3: TLabel;
    Image2: TImage;
    Image4: TImage;
    procedure FormShow(Sender: TObject);
    procedure imgVoltarClick(Sender: TObject);
    procedure imgFecharClick(Sender: TObject);
    procedure btnFinalizarClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SpeedButton1Click(Sender: TObject);
    procedure FormVirtualKeyboardHidden(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardShown(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
  private
    procedure AddProduto(id_produto, qtd: integer; foto, nome, obs: string; vl_unitario: double);
    procedure CarregarSacola;
    procedure DownloadFoto(lb: Tlistbox);
    procedure ThreadPedidoTerminate(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmCheckout: TFrmCheckout;

implementation

{$R *.fmx}

uses Frame.Produto, DataModule.Global, uSession, uFunctions;

procedure TFrmCheckout.DownloadFoto(lb: Tlistbox);
var
  t : TThread;
  foto : TBitmap;
  frame : TFrameProduto;
begin
  //Carrega imagens
  t := TThread.CreateAnonymousThread(procedure
  var
    i : integer;
  begin
    for i := 0 to lb.Items.count -1 do
    begin
      frame := TFrameProduto(lb.ItemByIndex(i).Components[0]);

      //TagString = url da foto...
      if frame.imgFoto.TagString <> '' then
      begin
        foto := TBitmap.Create;
        LoadImageFromURL(foto, frame.imgFoto.TagString);

        //frame.imgfoto.Tagstring := '';
        frame.imgFoto.Bitmap := foto;
      end;
    end;
  end);
  t.Start;
end;

procedure TFrmCheckout.AddProduto(id_produto, qtd: integer;
                                   foto, nome, obs: string;
                                   vl_unitario: double);
var
  item: TListBoxItem;
  frame: TFrameProduto;
begin
  item := TListBoxItem.Create(lbCardapio);
  item.Selectable := False;
  item.Text := '';
  item.Height := 100;
  item.Tag := id_produto;

  // Frame...
  frame                   := TFrameProduto.Create(item);
  frame.lblNome.Text      := nome;
  frame.lblDescricao.Text := FormatFloat('00', qtd) + ' x ' +
                             FormatFloat('R$ #,##0.00', vl_unitario) + sLineBreak +
                             obs;
  frame.lblPreco.Text     := FormatFloat('R$ #,##0.00', (vl_unitario * qtd));
  frame.imgFoto.TagString := foto;
  item.AddObject(frame);

  lbCardapio.AddObject(item)

end;

procedure TFrmCheckout.ThreadPedidoTerminate(Sender: TObject);
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

  Dm.LimparSacolaLocal;
  Dm.EditarConfigLocal(lblTaxaEntrega.TagFloat);
  Dm.EditarUsuarioLocal(TSession.ID_USUARIO, edtWhatsapp.Text, edtEndereco.Text);

  TabControl.GotoVisibleTab(1);

end;

procedure TFrmCheckout.btnFinalizarClick(Sender: TObject);
var
  t : TThread;
  jsonPedido : TJSONObject;
begin
  TLoading.Show(FrmCheckout,'');

  t := TThread.CreateAnonymousThread(procedure
  begin
    Try
      jsonPedido := Dm.JsonPedido(TSession.ID_USUARIO,
                                  edtWhatsapp.Text,
                                  edtEndereco.Text,
                                  lblSubTotal.TagFloat,
                                  lblTaxaEntrega.TagFloat,
                                  lblTotal.TagFloat);
      jsonPedido.AddPair('itens', Dm.JsonPedidoItem());

      Dm.FinalizarPedido(jsonPedido);
    Finally
      jsonPedido.DisposeOf;
    End;

  end);

  t.onTerminate := ThreadPedidoTerminate;
  t.start;

end;

procedure TFrmCheckout.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  FrmCheckout := nil;
end;

procedure TFrmCheckout.FormShow(Sender: TObject);
begin
  TabControl.GotoVisibleTab(0);
  CarregarSacola;
end;

procedure TFrmCheckout.FormVirtualKeyboardHidden(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  TabControl.Margins.Bottom := 0;
end;

procedure TFrmCheckout.FormVirtualKeyboardShown(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  TabControl.Margins.Bottom := 400;
end;

procedure TFrmCheckout.CarregarSacola;
var
  subtotal: double;
begin
  Try
    dm.ListarConfigLocal;
    Dm.ListarSacolaLocal;
    Dm.ListarUsuarioLocal;

    // Dados Config
    lblTaxaEntrega.Text     := FormatFloat('R$ #,##0.00', Dm.qryConfig.FieldByName('vl_entrega').AsFloat);
    lblTaxaEntrega.TagFloat := Dm.qryConfig.FieldByName('vl_entrega').AsFloat;
    edtWhatsapp.Text        := Dm.qryUsuario.FieldByName('fone'     ).AsString;
    edtEndereco.Lines.Clear;
    edtEndereco.Lines.Text  := Dm.qryUsuario.FieldByName('endereco'  ).AsString;

    //Dados do Pedido
    subtotal := 0;
    lbCardapio.Items.Clear;

    Dm.ListarSacolaLocal;
    With Dm.qrySacola do
    begin
      First;
      while not Eof do
      begin
        AddProduto(FieldByName('id_produto' ).AsInteger,
                   FieldByName('qtd'        ).Asinteger,
                   FieldByName('foto'       ).AsString,
                   FieldByName('nome'       ).AsString,
                   FieldByName('obs'        ).AsString,
                   FieldByName('vl_unitario').AsFloat);
        subtotal := subtotal + FieldByName('vl_total').AsFloat;
        Next;
      end;
    end;

    //Valores
    lblSubTotal.Text     := FormatFloat('R$ #,##0.00', subtotal);
    lblSubTotal.TagFloat := subtotal;
    lblTotal.Text     := FormatFloat('R$ #,##0.00', subtotal + lblTaxaEntrega.TagFloat);
    lblTotal.TagFloat := subtotal + lblTaxaEntrega.TagFloat;

    //Fotos dos produtos
    DownloadFoto(lbCardapio);

    //Trata Sacola vazia
    if lbCardapio.items.Count = 0 then
      TabControl.GotoVisibleTab(2);
  Except on e:Exception do
    ShowMessage('Erro ao carrega itens do pedido: ' + e.Message);
  End;

end;

procedure TFrmCheckout.imgVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmCheckout.SpeedButton1Click(Sender: TObject);
begin
  try
    Dm.LimparSacolaLocal;
    Close;
  except on e:exception do
    ShowMessage('Erro ao limpar pedido ' + e.Message);
  end;
end;

procedure TFrmCheckout.imgFecharClick(Sender: TObject);
begin
  Close;
end;

end.
