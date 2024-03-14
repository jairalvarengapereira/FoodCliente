unit uSession;

interface

type
  TSession = class
  private
    class var FID_USUARIO: integer;
    class var FFONE: string;
    class var FENDERECO: string;
  public
     class property ID_USUARIO: integer read FID_USUARIO write FID_USUARIO;
     class property FONE: string read FFONE write FFONE;
     class property ENDERECO: string read FENDERECO write FENDERECO;
  end;

implementation

end.

