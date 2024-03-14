unit UnitPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.TabControl, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts,
  FMX.ListBox, uLoading, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo, System.Json;

type
  TFrmPrincipal = class(TForm)
    TabControl: TTabControl;
    tbCardapio: TTabItem;
    tbPedido: TTabItem;
    tbConfig: TTabItem;
    rectAbas: TRectangle;
    imgCardapio: TImage;
    imgPedido: TImage;
    imgConfig: TImage;
    rectToolbarConfig: TRectangle;
    rectToolbarPedido: TRectangle;
    rectToolbarCardapio: TRectangle;
    Image1: TImage;
    imgSacola: TImage;
    Label1: TLabel;
    Rectangle1: TRectangle;
    Label2: TLabel;
    lbCardapio: TListBox;
    lvPedidos: TListView;
    ListBox1: TListBox;
    ListBoxItem1: TListBoxItem;
    Image3: TImage;
    Image4: TImage;
    Label3: TLabel;
    lbiLogout: TListBoxItem;
    Image5: TImage;
    Image6: TImage;
    Label4: TLabel;
    Line1: TLine;
    Line2: TLine;
    lytProduto: TLayout;
    reftFundo: TRectangle;
    rectProduto: TRectangle;
    imgFecharProd: TImage;
    imgProduto: TImage;
    lblNome: TLabel;
    lblDescricao: TLabel;
    lblPreco: TLabel;
    lblObservações: TLabel;
    memObs: TMemo;
    lytProdutoBotoes: TLayout;
    imgMenos: TImage;
    imgMais: TImage;
    lblQtdProd: TLabel;
    rectSacola: TRectangle;
    btnSacola: TSpeedButton;
    lblExtras: TLabel;
    lbOpcional: TListBox;
    lytImgProduto: TLayout;
    lytFoto: TLayout;
    lytPreco: TLayout;
    lytOpcional: TLayout;
    procedure imgCardapioClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lbCardapioItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure imgFecharProdClick(Sender: TObject);
    procedure imgSacolaClick(Sender: TObject);
    procedure lvPedidosItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure imgMenosClick(Sender: TObject);
    procedure btnSacolaClick(Sender: TObject);
    procedure lbOpcionalItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure lbiLogoutClick(Sender: TObject);
    procedure FormVirtualKeyboardShown(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardHidden(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
  private
    procedure MudarAba(img: timage);
    procedure AddProduto(id_produto: integer; opcional, url_foto, nome, descricao,
      categoria: string; preco: double);
    procedure ListarProdutos;
    procedure AddCategoria(id_categoria: integer; descricao: string);
    procedure ThreadProdutosTerminate(Sender: TObject);
    procedure AddPedido(id_pedido: integer;
                        dt_pedido: string;
                        vl_total: double;
                        jsonStr: string);
    procedure ListarPedidos;
    procedure OpenProduto(item: TListBoxItem);
    procedure CloseProduto;
    procedure OpenDetalhePedido(jsonpedido: string);
    procedure Qtd(valor: integer);
    procedure DownloadFoto(lb: Tlistbox);
    procedure AddOpcional(id_opcional: integer; url_foto, nome,
      descricao: string; preco: double);
    procedure ListarOpcionais(ItemTag:integer);
    procedure ThreadOpcionaisTerminate(Sender: TObject);
    procedure AdicionaVlOpcional;
    procedure SelecionarOpcional(item: TListBoxItem);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.fmx}

uses Frame.Produto, Frame.Categoria, UnitCheckout, UnitPedido,
     DataModule.Global, uFunctions, Frame.Opcional, uSession, UnitLogin;

procedure TFrmPrincipal.ListarPedidos;
var
  t: TThread;
begin
  lvPedidos.Items.Clear;
  TLoading.Show(FrmPrincipal,'');

  t:= TThread.CreateAnonymousThread(procedure
  var
    i : integer;
    json : TJSONArray;
  begin
    json := Dm.ListarPedidos(TSession.ID_USUARIO);

    for i := 0 to json.Size -1 do
    begin

      TThread.Synchronize(TThread.CurrentThread, procedure
      begin
        AddPedido(json[i].GetValue<integer>('id_pedido',0),
                  json[i].GetValue<string>('dt_pedido',''),
                  json[i].GetValue<double>('vl_total',0),
                  json[i].ToJSON);
      end);
    end;

  end);
  t.OnTerminate := ThreadProdutosTerminate;
  t.Start;
end;

procedure TFrmPrincipal.AddPedido(id_pedido: integer;
                                  dt_pedido: string;
                                  vl_total: double;
                                  jsonStr: string);
var
  item : TListViewItem;
  txt  : TListItemText;
begin
  item  := lvPedidos.Items.Add;
  item.Height := 50;
  item.Tag := id_pedido;
  item.TagString := jsonStr;

  txt := TListItemText(item.Objects.FindDrawable('txtPedido'));
  txt.Text := 'Pedido ' + id_pedido.ToString;

  txt := TListItemText(item.Objects.FindDrawable('txtData'));
  txt.Text := dt_pedido;

  txt := TListItemText(item.Objects.FindDrawable('txtValor'));
  txt.Text := FormatFloat('R$ #,##0.00', vl_total);
end;

procedure TFrmPrincipal.ThreadProdutosTerminate(Sender: TObject);
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

  //Carregar fotos
  DownloadFoto(lbCardapio);

  //Buscar configurações do app
  Try
    Dm.ListarConfig;
    Dm.EditarConfigLocal(Dm.TabConfig.FieldByName('vl_entrega').AsFloat);
  except on ex:Exception do
    ShowMessage(ex.message);

  End;
end;

procedure TFrmPrincipal.ThreadOpcionaisTerminate(Sender: TObject);
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

  //Carregar fotos
  DownloadFoto(lbOpcional);
end;

procedure TFrmPrincipal.DownloadFoto(lb: Tlistbox);
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

procedure TFrmPrincipal.ListarProdutos;
var
  t: TThread;
  categoria_anterior : string;
begin
  categoria_anterior := '';
  lbCardapio.Items.Clear;
  TLoading.Show(FrmPrincipal,'');

  t:= TThread.CreateAnonymousThread(procedure
  begin
    Dm.ListarCardapios;

    while not Dm.TabCardapios.Eof do
    begin
      TThread.Synchronize(TThread.CurrentThread, procedure
      begin

        if Dm.TabCardapios.FieldByName('categoria').AsString <> categoria_anterior  then
        begin
          AddCategoria(Dm.TabCardapios.FieldByName('id_categoria').AsInteger,
                       Dm.TabCardapios.FieldByName('categoria').AsString);
          categoria_anterior := Dm.TabCardapios.FieldByName('categoria').AsString;
        end;

        AddProduto(Dm.TabCardapios.FieldByName('id_produto').AsInteger,
                   Dm.TabCardapios.FieldByName('opcional'  ).AsString,
                   Dm.TabCardapios.FieldByName('foto'      ).AsString,
                   Dm.TabCardapios.FieldByName('nome'      ).AsString,
                   Dm.TabCardapios.FieldByName('descricao' ).AsString,
                   Dm.TabCardapios.FieldByName('categoria' ).AsString,
                   Dm.TabCardapios.FieldByName('preco'     ).Asfloat);
        Dm.TabCardapios.Next;
      end);
    end;
  end);
  t.OnTerminate := ThreadProdutosTerminate;
  t.Start;
end;

procedure TFrmPrincipal.lbOpcionalItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin
  SelecionarOpcional(item);
end;

procedure TFrmPrincipal.ListarOpcionais(ItemTag:integer);
var
  t: TThread;
begin
  Dm.TabCardapios.Locate('id_produto',ItemTag.ToString);
  if Dm.TabCardapios.FieldByName('opcional').AsString = 'T' then
  begin
    lytOpcional.Visible := True;
    lbOpcional.Items.Clear;
    TLoading.Show(FrmPrincipal,'');

    t:= TThread.CreateAnonymousThread(procedure
    begin
      Dm.ListarOpcionais;

      while not Dm.TabOpcional.Eof do
      begin
        TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          AddOpcional(Dm.TabOpcional.FieldByName('id_opcional').AsInteger,
                      Dm.TabOpcional.FieldByName('foto').AsString,
                      Dm.TabOpcional.FieldByName('nome').AsString,
                      Dm.TabOpcional.FieldByName('descricao').AsString,
                      Dm.TabOpcional.FieldByName('preco').Asfloat);
          Dm.TabOpcional.Next;
        end);
      end;
    end);
    t.OnTerminate := ThreadOpcionaisTerminate;
    t.Start;
  end
  else
    lytOpcional.Visible := False;
end;

procedure TFrmPrincipal.OpenDetalhePedido(jsonpedido: string);
begin
  if not Assigned(FrmPedido) then
    Application.CreateForm(TFrmPedido,FrmPedido);

  FrmPedido.json := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(jsonPedido),0)
                    as TJSONObject ;

  FrmPedido.Show;
end;

procedure TFrmPrincipal.lvPedidosItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  OpenDetalhePedido(AItem.TagString); // Enviando o Json completo de cada item.
end;

procedure TFrmPrincipal.AddProduto(id_produto: integer;
                                   opcional, url_foto, nome, descricao, categoria: string;
                                   preco: double);
var
  item: TListBoxItem;
  frame: TFrameProduto;
begin
  item := TListBoxItem.Create(lbCardapio);
  item.Selectable := False;
  item.Text := '';
  item.Height := 80;
  item.Tag := id_produto;

  // Frame...
  frame := TFrameProduto.Create(item);
  frame.lblNome.Text := nome;
  frame.lblDescricao.Text := descricao;
  frame.lblPreco.Text := FormatFloat('R$ #,##0.00', preco);
  frame.lblPreco.TagFloat := preco;
  frame.imgFoto.TagString := url_foto;
  item.AddObject(frame);

  lbCardapio.AddObject(item);
end;

procedure TFrmPrincipal.AddOpcional(id_opcional: integer;
                                    url_foto, nome, descricao: string;
                                    preco: double);
var
  item: TListBoxItem;
  frame: TFrameOpcional;
begin
  item := TListBoxItem.Create(lbOpcional);
  item.Selectable := False;
  item.Text := '';
  item.Height := 70;
  item.Width := 120;
  item.Tag := id_opcional;

  // Frame...
  frame := TFrameOpcional.Create(item);
  frame.lblNomeOpcional.Text := nome;
  frame.lblPrecoOpcional.Text := FormatFloat('R$ #,##0.00', preco);
  frame.lblPrecoOpcional.TagFloat := preco;
  frame.imgFotoOpcional.TagString := url_foto;
  item.AddObject(frame);

  lbOpcional.AddObject(item);
end;

procedure TFrmPrincipal.AdicionaVlOpcional;
var
  i, cont : integer;
  frame   : TFrameOpcional;
  Obs     : string;
begin
  Obs  := '';
  cont := 0;
  //carrega dados do produto
  for i := 0 to lbOpcional.Items.count -1 do
  begin
    frame := TFrameOpcional(lbOpcional.ItemByIndex(i).Components[0]);
    if frame.chbOpcional.IsChecked then
    begin
      lblPreco.TagFloat := lblPreco.TagFloat + frame.lblPrecoOpcional.TagFloat;
      Obs := Obs + frame.lblNomeOpcional.Text + ', ';
      frame.chbOpcional.IsChecked := False;

      inc(cont);
    end;
  end;
  if (memObs.Text <> '') and (cont > 0) then
    memObs.Text := memObs.Text + sLineBreak + 'Extra(s): ' + Copy(Obs,1,length(Obs)-2)
  else
  if (cont > 0) then
    memObs.Text := memObs.Text + 'Extra(s): ' + Copy(Obs,1,length(Obs)-2);
end;

procedure TFrmPrincipal.btnSacolaClick(Sender: TObject);
begin
  try
    AdicionaVlOpcional;
    Dm.AdicionarCarrinhoLocal(imgProduto.Tag, lblQtdProd.Tag, lblNome.Text, lblDescricao.Text,
                              imgProduto.TagString, memObs.Text, lblPreco.TagFloat);
    CloseProduto;
  except on ex:exception do
    ShowMessage('Erro ao salvar item' + ex.Message);
  end;
end;

procedure TFrmPrincipal.AddCategoria(id_categoria: integer;
                                     descricao: string);
var
  item: TListBoxItem;
  frame: TFrameCategoria;
begin
  item := TListBoxItem.Create(lbCardapio);
  item.Selectable := False;
  item.Text := '';
  item.Height := 40;
  item.Tag := 0;

  // Frame...
  frame := TFrameCategoria.Create(item);
  frame.lblDescricao.Text := descricao;
  item.AddObject(frame);

  lbCardapio.AddObject(item);
end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
  ListarProdutos;
  MudarAba(imgCardapio);
  CloseProduto;
end;

procedure TFrmPrincipal.FormVirtualKeyboardHidden(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  if lytProduto.Visible then
  begin
    lytProduto.Margins.Bottom := 0;
  end;

end;

procedure TFrmPrincipal.FormVirtualKeyboardShown(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  if lytProduto.Visible then
  begin
    lytProduto.Margins.Bottom := 200;
  end;
end;

procedure TFrmPrincipal.imgCardapioClick(Sender: TObject);
begin
  MudarAba(TImage(Sender));
end;

procedure TFrmPrincipal.imgFecharProdClick(Sender: TObject);
begin
  CloseProduto;
end;

procedure TFrmPrincipal.Qtd(valor: integer);
begin
  lblQtdProd.Tag := lblQtdProd.Tag + valor;
  lblQtdProd.Text := FormatFloat('00',lblQtdProd.Tag);

  btnSacola.Text :=  'Adicionar ao pedido (R$ ' +
                     FormatFloat('#,##0.00', btnSacola.TagFloat * lblQtdProd.Tag ) + ')';
end;

procedure TFrmPrincipal.imgMenosClick(Sender: TObject);
begin
  Qtd(TImage(Sender).Tag);
end;

procedure TFrmPrincipal.imgSacolaClick(Sender: TObject);
begin
  if not Assigned(FrmCheckout) then
    Application.CreateForm(TFrmCheckout,FrmCheckout);
  FrmCheckout.Show;
end;

procedure TFrmPrincipal.OpenProduto(item: TListBoxItem);
var
  frame : TFrameProduto;
begin
  //carrega dados do produto
  frame := TFrameProduto(item.Components[0]);
  imgProduto.Bitmap     := frame.imgFoto.Bitmap;
  imgProduto.Tag        := item.Tag;
  imgProduto.TagString  := frame.imgFoto.TagString;
  lblNome.Text          := frame.lblNome.Text;
  lblPreco.Text         := frame.lblPreco.Text;
  lblPreco.TagFloat     := frame.lblPreco.TagFloat;
  lblQtdProd.Text       := '01';
  lblQtdProd.Tag        := 1;
  lblDescricao.Text     := frame.lblDescricao.Text;
  btnSacola.Text        := 'Adicionar ao pedido (R$ '+ FormatFloat('#,##0.00',lblPreco.TagFloat) +')';
  btnSacola.TagFloat    := lblPreco.TagFloat;
  memObs.Lines.Clear;

  ListarOpcionais(item.Tag);

  lytProduto.Visible := True;
end;

procedure TFrmPrincipal.SelecionarOpcional(item: TListBoxItem);
var
  frame : TFrameOpcional;
begin
  //carrega dados do produto
  frame := TFrameOpcional(item.Components[0]);
  frame.chbOpcional.IsChecked := not frame.chbOpcional.IsChecked;

  if frame.chbOpcional.IsChecked then
  begin
    btnSacola.TagFloat := btnSacola.TagFloat + frame.lblPrecoOpcional.TagFloat;
    btnSacola.Text := 'Adicionar ao pedido (R$ ' +
                      FormatFloat('#,##0.00', btnSacola.TagFloat * lblQtdProd.Tag) + ')';
  end
  else
  begin
    btnSacola.TagFloat := btnSacola.TagFloat - frame.lblPrecoOpcional.TagFloat;
    btnSacola.Text := 'Adicionar ao pedido (R$ ' +
                      FormatFloat('#,##0.00', btnSacola.TagFloat * lblQtdProd.Tag) + ')';
  end
end;

procedure TFrmPrincipal.CloseProduto;
begin
  lytProduto.Visible := False;
end;

procedure TFrmPrincipal.lbCardapioItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin
  if Item.Tag > 0 then
  begin
    OpenProduto(Item);
  end;
end;

procedure TFrmPrincipal.lbiLogoutClick(Sender: TObject);
begin
  Dm.LimparSacolaLocal;
  Dm.LimparUsuarioLocal;

  // Matando a App e voltando para a tela de login
  //================================
  Application.MainForm := FrmLogin;
  FrmLogin.Show;
  FrmPrincipal.Close;
  //================================

end;

procedure TFrmPrincipal.MudarAba(img: timage);
begin
  imgCardapio.Opacity := 0.5;
  imgPedido.Opacity   := 0.5;
  imgConfig.Opacity   := 0.5;

  img.Opacity := 1;
  TabControl.GotoVisibleTab(img.Tag);

  if (img.Tag = 1)  then
    ListarPedidos;
end;

end.
