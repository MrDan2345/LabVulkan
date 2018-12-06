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
    var _Device: TLabDeviceShared;
    var _Handle: TVkCommandPool;
  public
    property VkHandle: TVkCommandPool read _Handle;
    property Device: TLabDeviceShared read _Device;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const AQueueFamilyIndex: TVkUInt32;
      const ACreateFlags: TVkCommandPoolCreateFlags = TVkFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
    );
    destructor Destroy; override;
    procedure Reset(const ReleaseResources: Boolean = False);
  end;
  TLabCommandPoolShared = specialize TLabSharedRef<TLabCommandPool>;

implementation

//TLabCommandPool BEGIN
constructor TLabCommandPool.Create(
  const ADevice: TLabDeviceShared;
  const AQueueFamilyIndex: TVkUInt32;
  const ACreateFlags: TVkCommandPoolCreateFlags
);
  var command_pool_create_info: TVkCommandPoolCreateInfo;
begin
  LabLog('TLabCommandPool.Create');
  _Device := ADevice;
  LabZeroMem(@command_pool_create_info, SizeOf(TVkCommandPoolCreateInfo));
  command_pool_create_info.sType := VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
  command_pool_create_info.queueFamilyIndex := AQueueFamilyIndex;
  command_pool_create_info.flags := ACreateFlags;
  LabAssertVkError(Vulkan.CreateCommandPool(_Device.Ptr.VkHandle, @command_pool_create_info, nil, @_Handle));
end;

destructor TLabCommandPool.Destroy;
begin
  Vulkan.DestroyCommandPool(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabCommandPool.Destroy');
end;

procedure TLabCommandPool.Reset(const ReleaseResources: Boolean);
  var flags: TVkCommandPoolResetFlags;
begin
  if ReleaseResources then flags := TVkFlags(VK_COMMAND_POOL_RESET_RELEASE_RESOURCES_BIT) else flags := 0;
  Vulkan.ResetCommandPool(_Device.Ptr.VkHandle, _Handle, flags);
end;

//TLabCommandPool END

end.
