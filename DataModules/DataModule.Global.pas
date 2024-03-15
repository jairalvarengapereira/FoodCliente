unit DataModule.Global;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.FMXUI.Wait,
  Data.DB, FireDAC.Comp.Client, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, System.IOUtils,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet,
  DataSet.Serialize.Config,
  RESTRequest4D,
  Dataset.Serialize.Adapter.RESTRequest4D,
  DataSet.Serialize,
  System.JSON;

type
  TDm = class(TDataModule)
    Conn: TFDConnection;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    qrySacola: TFDQuery;
    qryConfig: TFDQuery;
    TabPedido: TFDMemTable;
    TabCardapios: TFDMemTable;
    TabOpcional: TFDMemTable;
    qryUsuario: TFDQuery;
    TabUsuario: TFDMemTable;
    TabConfig: TFDMemTable;
    procedure DataModuleCreate(Sender: TObject);
    procedure ConnBeforeConnect(Sender: TObject);
    procedure ConnAfterConnect(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure LimparUsuarioLocal;
    procedure ListarConfig;
    procedure Login(fone: string);
    procedure ListarUsuarioLocal;
    procedure EditarUsuarioLocal(id_usuario: integer; fone, endereco: string);
    function JsonPedidoItem: TJsonArray;
    procedure ListarOpcionais;
    procedure ListarCardapios;
    function ListarPedidos(id_usuario: integer): TJSONArray;
    procedure LimparSacolaLocal;
    procedure ListarConfigLocal;
    procedure ListarSacolaLocal;
    procedure EditarConfigLocal(vl_entrega: double);
    procedure AdicionarCarrinhoLocal(id_produto, qtd: integer; nome, descricao,
      foto, obs: string; vl_unitario: double);
    function JsonPedido(id_usuario: integer;
                        fone, endereco: string;
                        vl_subtotal, vl_entrega, vl_total: double): TjsonObject;
    procedure FinalizarPedido(jsonPedido: TjsonObject);
  end;

var
  Dm: TDm;

Const
  Base_URL = 'http://3.23.126.19:3002'; //- AWS
//  Base_URL = 'http://192.168.0.2:3002'; //- Lenovo_R7
//  Base_URL = 'http://177.182.90.157:3002'; //- Lenovo_R7 - NoIP

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDm.ListarConfig;
var
  Resp : IResponse;
begin
  resp := TRequest.New.BaseURL(Base_URL)
          .Resource('/configs')
          .Accept('application/json')
          .Adapters(TDataSetSerializeAdapter.New(Dm.TabConfig))
          .GET;

  if (Resp.StatusCode <> 201) and (Resp.StatusCode <> 200) then
    raise Exception.Create('Erro ao caregar configurações: ' + resp.Content);
end;

function TDm.JsonPedidoItem(): TJsonArray;
var
  itens : TJSONArray;
begin
  ListarSacolaLocal;
  Result := qrySacola.ToJSONArray();
end;

function TDm.ListarPedidos(id_usuario: integer): TJSONArray;
var
  Resp : IResponse;
begin
  resp := TRequest.New.BaseURL(Base_URL)
          .Resource('/pedidos')
          .AddParam('id_usuario', id_usuario.ToString)
          .Accept('application/json')
//          .Adapters(TDataSetSerializeAdapter.New(TabPedido))
          .Get;

  if Resp.StatusCode <> 200 then
    raise Exception.Create('Erro ao consultar dados' + resp.Content)
  else
    Result := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(resp.Content),0) as TJSONArray;
end;

procedure TDm.ListarCardapios;
var
  Resp : IResponse;
begin
  resp := TRequest.New.BaseURL(Base_URL)
          .Resource('/cardapios')
          .Accept('application/json')
          .Adapters(TDataSetSerializeAdapter.New(TabCardapios))
          .Get;

  if Resp.StatusCode <> 200 then
    raise Exception.Create('Erro ao consultar produtos' + resp.Content);
end;

procedure TDm.ListarOpcionais;
var
  Resp : IResponse;
begin
  resp := TRequest.New.BaseURL(Base_URL)
          .Resource('/opcionais')
          .Accept('application/json')
          .Adapters(TDataSetSerializeAdapter.New(TabOpcional))
          .Get;

  if Resp.StatusCode <> 200 then
    raise Exception.Create('Erro ao consultar produtos' + resp.Content);

end;

procedure TDm.ConnAfterConnect(Sender: TObject);
begin
  // Zerar AutoIncremento
//  Conn.ExecSQL('  UPDATE sqlite_sequence SET seq=1     '+
//               '   WHERE name="Tab_usuario" and        '+
//               ' (SELECT count(*) FROM Tab_Usuario) = 0');

  Try
    Conn.ExecSQL('Drop table Tab_config ');
    Conn.ExecSQL('Drop table Tab_usuario ');
    Conn.ExecSQL('Drop table Tab_sacola_item');
  except
  End;

  Conn.ExecSQL(' create table if not exists '+
               ' Tab_usuario(id_usuario integer primary key autoincrement, '+
               ' fone  varchar(20), endereco varchar(200))');

  Conn.ExecSQL(' create table if not exists Tab_config(vl_entrega  decimal(9,2))');

  Conn.ExecSQL('Create table if not exists '+
               'Tab_Config(vl_entrega decimal (9,2),'+
                           'fone varchar(20),' +
                           'endereco varchar(200))');

  Conn.ExecSQL('Create table if not exists '+
               'Tab_Sacola_Item(id_item integer primary key autoincrement,'+
                               'fone varchar(20),' +
                               'nome        varchar(100),'+
                               'descricao   varchar(200),'+
                               'endereco    varchar(200),' +
                               'foto        varchar(1000),' +
                               'id_pedido   integer,'+
                               'id_produto  integer,'+
                               'obs         varchar(200),'+
                               'qtd         decimal(9,3),'+
                               'vl_unitario decimal(9,2),'+
                               'vl_total    decimal(9,2)'+')');
end;

procedure TDm.AdicionarCarrinhoLocal(id_produto,qtd: integer;
                                     nome,descricao,foto,obs: string;
                                     vl_unitario: double);
begin
  With qrySacola do
  begin
    Active := False;
    SQL.Clear;
    SQL.Add('Insert into Tab_Sacola_Item( id_produto, nome, descricao, foto,    ');
    SQL.Add('                             qtd, obs, vl_unitario, vl_total)      ');
    SQL.Add('                     Values( :id_produto, :nome, :descricao, :foto,');
    SQL.Add('                             :qtd, :obs, :vl_unitario, :vl_total)  ');
    ParamByName('id_produto' ).Value := id_produto;
    ParamByName('nome'       ).Value := nome;
    ParamByName('descricao'  ).Value := descricao;
    ParamByName('foto'       ).Value := foto;
    ParamByName('qtd'        ).Value := qtd;
    ParamByName('obs'        ).Value := obs;
    ParamByName('vl_unitario').Value := vl_unitario;
    ParamByName('vl_total'   ).Value := vl_unitario * qtd;
    ExecSQL;
  end;
end;

procedure TDm.EditarConfigLocal(vl_entrega: double);
begin
  With qryConfig do
  begin
    Active := False;
    SQL.Clear;
    SQL.Add('Delete from Tab_Config');
    ExecSQL;

    Active := False;
    SQL.Clear;
    SQL.Add('Insert into Tab_Config(vl_entrega)        ');
    SQL.Add('                     Values(:vl_entrega)');
    ParamByName('vl_entrega').Value := vl_entrega;
    ExecSQL;
  end;
end;

procedure TDm.EditarUsuarioLocal(id_usuario: integer;
                                 fone, endereco: string);
begin
  With qryConfig do
  begin
    Active := False;
    SQL.Clear;
    SQL.Add('Delete from Tab_Usuario');
    ExecSQL;

    Active := False;
    SQL.Clear;
    SQL.Add('Insert into Tab_Usuario(id_usuario, fone, endereco)');
    SQL.Add('                     Values(:id_usuario, :fone, :endereco)');
    ParamByName('id_usuario').Value := id_usuario;
    ParamByName('fone'      ).Value := fone;
    ParamByName('endereco'  ).Value := endereco;
    ExecSQL;
  end;
end;

procedure TDm.FinalizarPedido(jsonPedido: TjsonObject);
var
  Resp : IResponse;
begin
  resp := TRequest.New.BaseURL(Base_URL)
          .Resource('/pedidos')
          .Accept('application/json')
          .AddBody( jsonPedido.ToJSON)
          .Post;

  if Resp.StatusCode <> 201 then
    raise Exception.Create('Erro ao cadastrar pedido: ' + resp.Content);
end;

procedure TDm.Login(fone: string);
var
  Resp : IResponse;
  json : TJSONObject;
begin
  Try
  json := TJSONObject.Create;
  json.AddPair('fone', fone);
    resp := TRequest.New.BaseURL(Base_URL)
            .Resource('/usuarios/login')
            .Accept('application/json')
            .AddBody( json.ToJSON)
            .Adapters(TDataSetSerializeAdapter.New(Dm.TabUsuario))
            .Post;

    if (Resp.StatusCode <> 201) and (Resp.StatusCode <> 200) then
      raise Exception.Create('Erro ao validar usuário: ' + resp.Content);
  Finally
    json.DisposeOf;
  End;
end;

function TDm.JsonPedido(id_usuario: integer; fone, endereco: string;
  vl_subtotal, vl_entrega, vl_total: double): TjsonObject;
var
  json : TJSONObject;
begin
  json := TJSONObject.Create;

  json.AddPair('id_usuario' , TJSONNumber.Create(id_usuario));
  json.AddPair('fone'       , TJSONString.Create(fone));
  json.AddPair('endereco'   , TJSONString.Create(endereco));
  json.AddPair('vl_subtotal', TJSONNumber.Create(vl_subtotal));
  json.AddPair('vl_entrega' , TJSONNumber.Create(vl_entrega));
  json.AddPair('vl_total'   , TJSONNumber.Create(vl_total));

  Result := json;
end;

procedure TDm.ListarSacolaLocal;
begin
  With qrySacola do
  begin
    Active := False;
    SQL.Clear;
    SQL.Add('Select * from Tab_Sacola_item Order by id_item');
    Active := true;
  end;
end;

procedure TDm.LimparSacolaLocal;
begin
  With qrySacola do
  begin
    Active := False;
    SQL.Clear;
    SQL.Add('Delete from Tab_Sacola_item');
    ExecSQL;
  end;
end;

procedure TDm.LimparUsuarioLocal;
begin
  With qryUsuario do
  begin
    Active := False;
    SQL.Clear;
    SQL.Add('Delete from Tab_Usuario');
    ExecSQL;
  end;
end;

procedure TDm.ListarConfigLocal;
begin
  With qryConfig do
  begin
    Active := False;
    SQL.Clear;
    SQL.Add('Select * from Tab_Config');
    Active := true;
  end;
end;

procedure TDm.ListarUsuarioLocal;
begin
  With qryUsuario do
  begin
    Active := False;
    SQL.Clear;
    SQL.Add('Select * from Tab_Usuario');
    Active := true;
  end;
end;

procedure TDm.ConnBeforeConnect(Sender: TObject);
begin
  Conn.DriverName := 'SQLite';

  {$IFDEF MSWINDOWS}
  Conn.Params.Values['DataBase'] := System.SysUtils.GetCurrentDir + '\Banco.db';
  {$ELSE}
  Conn.Params.Values['DataBase'] := TPath.Combine(TPath.GetDocumentsPath, 'Banco.db');
  {$ENDIF}
end;

procedure TDm.DataModuleCreate(Sender: TObject);
begin
  TDataSetSerializeConfig.GetInstance.CaseNameDefinition := cndLower;
  Conn.Connected := True;
end;


end.

