unit LabSwapChain;

interface

uses
  LabWindow;

type
  TLabSwapChain = class (TInterfacedObject)
  public
    constructor Create(const Window: TLabWindow);
    destructor Destroy; override;
  end;

implementation

constructor TLabSwapChain.Create(const Window: TLabWindow);
begin

end;

destructor TLabSwapChain.Destroy;
begin
  inherited Destroy;
end;

end.
