unit LabCommandPool;

interface

uses
  LabUtils,
  Vulkan;

type
  TLabCommandPool = class (TInterfacedObject)
  private
    var _LogicalDevice: TVkDevice;
    var _CommandPool: TVkCommandPool;
  public
    constructor Create(
      const LogicalDevice: TVkDevice;
      const QueueFamilyIndex: TVkUInt32;
      const CreateFlags: TVkCommandPoolCreateFlags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT
    );
    destructor Destroy; override;
  end;

implementation

constructor TLabCommandPool.Create(
  const LogicalDevice: TVkDevice;
  const QueueFamilyIndex: TVkUInt32;
  const CreateFlags: TVkCommandPoolCreateFlags
);
  var command_pool_create_info: TVkCommandPoolCreateInfo;
begin
  _LogicalDevice := LogicalDevice;
  LabZeroMem(@command_pool_create_info, SizeOf(TVkCommandPoolCreateInfo));
  command_pool_create_info.sType := VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
  command_pool_create_info.queueFamilyIndex := QueueFamilyIndex;
  command_pool_create_info.flags := CreateFlags;
  LabAssetVkError(vk.CreateCommandPool(LogicalDevice, @command_pool_create_info, nil, @_CommandPool));
end;

destructor TLabCommandPool.Destroy;
begin
  vk.DestroyCommandPool(_LogicalDevice, _CommandPool, nil);
  inherited Destroy;
end;

end.
