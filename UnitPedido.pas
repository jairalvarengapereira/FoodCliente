unit UnitPedido;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.StdCtrls, FMX.Controls.Presentation, FMX.ListBox,
  System.JSON;

type
  TFrmPedido = class(TForm)
    lbItensPedido: TListBox;
    rectEndereco: TRectangle;
    lblPedido: TLabel;
    lblEndereco: TLabel;
    rectToolbarPedido: TRectangle;
    Label1: TLabel;
    imgVoltar: TImage;
    rectTotal: TRectangle;
    lytSubTotal: TLayout;
    Label2: TLabel;
    lblSubTotal: TLabel;
    lytTotal: TLayout;
    Label4: TLabel;
    lblTotal: TLabel;
    lytTaxaEntrega: TLayout;
    Label6: TLabel;
    lblTaxaEntrega: TLabel;
    lblData: TLabel;
    Label11: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure imgVoltarClick(Sender: TObject);
  private
    procedure AddProduto(id_produto: integer;
                         foto, nome, descricao, categoria, obs: string;
                         vl_unitario, qtd: double);
    procedure ListarProdutos;
    procedure DownloadFoto(lb: Tlistbox);
    { Private declarations }
  public
    { Public declarations }
    json : TJSONObject;
  end;

var
  FrmPedido: TFrmPedido;

implementation

{$R *.fmx}

uses Frame.Produto, uFunctions;

procedure TFrmPedido.AddProduto(id_produto: integer;
                                foto, nome, descricao, categoria, obs: string;
                                vl_unitario, qtd: double);
var
  item: TListBoxItem;
  frame: TFrameProduto;
begin
  item := TListBoxItem.Create(lbItensPedido);
  item.Selectable := False;
  item.Text := '';
  item.Height := 100;
  item.Tag := id_produto;

  // Frame...
  frame                   := TFrameProduto.Create(item);
  frame.lblNome.Text      := nome;
  frame.lblDescricao.Text := FormatFloat('00', qtd) + ' x ' +
                             FormatFloat('R$ #,##0.00', vl_unitario) + sLineBreak +
                             {descricao + ' ' +} obs;
  frame.lblPreco.Text     := FormatFloat('R$ #,##0.00', (vl_unitario * qtd));
  frame.imgFoto.TagString := foto;
  item.AddObject(frame);

  lbItensPedido.AddObject(item)

end;

procedure TFrmPedido.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  FrmPedido := nil;
end;

procedure TFrmPedido.FormShow(Sender: TObject);
begin
  ListarProdutos;
end;

procedure TFrmPedido.imgVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmPedido.ListarProdutos;
var
  itens : TJSONArray;
  i : integer;
begin
  lbItensPedido.Items.Clear;

  lblPedido.Text      := 'Pedido: ' + json.GetValue<string>('id_pedido','');
  lblEndereco.Text    := 'Entrega: ' + json.GetValue<string>('endereco','');
  lblData.Text        := json.GetValue<string>('dt_pedido','')+'h';
  lblSubTotal.Text    := FormatFloat('R$ #,##0.00', json.GetValue<double>('vl_subtotal',0));
  lblTotal.Text       := FormatFloat('R$ #,##0.00', json.GetValue<double>('vl_total',0));
  lblTaxaEntrega.Text := FormatFloat('R$ #,##0.00', json.GetValue<double>('vl_entrega',0));

  itens := json.GetValue<TJSONArray>('itens');

  for i := 0 to itens.Size - 1 do
  begin
    AddProduto(itens[i].GetValue<integer>('id_produto',0),
               itens[i].GetValue<string>('foto',''),
               itens[i].GetValue<string>('nome',''),
               itens[i].GetValue<string>('descricao',''),
               itens[i].GetValue<string>('categoria',''),
               itens[i].GetValue<string>('obs',''),
               itens[i].GetValue<double>('vl_unitario',0),
               itens[i].GetValue<double>('qtd',0));
  end;

  DownloadFoto(lbItensPedido);

end;

procedure TFrmPedido.DownloadFoto(lb: Tlistbox);
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

end.
