unit LabCommandPool;

interface

uses
  LabTypes,
  LabUtils,
  LabDevice,
  Vulkan;

type
  TLabCommandPool = class (TLabClass)
  private
    var _Device: TLabDeviceRef;
    var _Handle: TVkCommandPool;
  public
    property VkHandle: TVkCommandPool read _Handle;
    property Device: TLabDeviceRef read _Device;
    constructor Create(
      const ADevice: TLabDeviceRef;
      const AQueueFamilyIndex: TVkUInt32;
      const ACreateFlags: TVkCommandPoolCreateFlags = TVkFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
    );
    destructor Destroy; override;
  end;
  TLabCommandPoolRef = specialize TLabRefCounter<TLabCommandPool>;

implementation

//TLabCommandPool BEGIN
constructor TLabCommandPool.Create(
  const ADevice: TLabDeviceRef;
  const AQueueFamilyIndex: TVkUInt32;
  const ACreateFlags: TVkCommandPoolCreateFlags
);
  var command_pool_create_info: TVkCommandPoolCreateInfo;
begin
  LabLog('TLabCommandPool.Create', 2);
  _Device := ADevice;
  LabZeroMem(@command_pool_create_info, SizeOf(TVkCommandPoolCreateInfo));
  command_pool_create_info.sType := VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
  command_pool_create_info.queueFamilyIndex := AQueueFamilyIndex;
  command_pool_create_info.flags := ACreateFlags;
  LabAssetVkError(Vulkan.CreateCommandPool(_Device.Ptr.VkHandle, @command_pool_create_info, nil, @_Handle));
end;

destructor TLabCommandPool.Destroy;
begin
  Vulkan.DestroyCommandPool(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabCommandPool.Destroy', -2);
end;
//TLabCommandPool END

end.
