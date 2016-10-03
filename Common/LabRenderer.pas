unit LabRenderer;

interface

uses
  Vulkan,
  LabSwapChain;

type

  TLabRenderer = class (TInterfacedObject)
  private
    class var _VulkanEnabled: Boolean;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

class constructor TLabRenderer.CreateClass;
begin
  _VulkanEnabled := LoadVulkanLibrary;
end;

class destructor TLabRenderer.DestroyClass;
begin

end;

constructor TLabRenderer.Create;
  var InstanceCreateInfo: TVkInstanceCreateInfo;
begin
  FillChar(InstanceCreateInfo, SizeOf(TVkInstanceCreateInfo), 0);
  InstanceCreateInfo.sType := VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  InstanceCreateInfo.enabledExtensionCount := 2;
  InstanceCreateInfo.ppEnabledExtensionNames:=PPVkChar(pointer(@extensionNames));
  if vk.CreateInstance(@instanceCreateInfo,nil,@inst)=VK_SUCCESS then begin
end;

destructor TLabRenderer.Destroy;
begin
  inherited Destroy;
end;

end.
