unit LabCommandBuffer;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabCommandPool;

type
  TLabCommandBuffer = class (TLabClass)
  private
    var _CommandPool: TLabCommandPoolRef;
    var _Handle: TVkCommandBuffer;
  public
    property CommandPool: TLabCommandPoolRef read _CommandPool;
    property VkHandle: TVkCommandBuffer read _Handle;
    constructor Create(
      const ACommandPool: TLabCommandPoolRef;
      const ALevel: TVkCommandBufferLevel = VK_COMMAND_BUFFER_LEVEL_PRIMARY
    );
    destructor Destroy; override;
  end;
  TLabCommandBufferRef = specialize TLabRefCounter<TLabCommandBuffer>;

implementation

//TLabCommandBuffer BEGIN
constructor TLabCommandBuffer.Create(
  const ACommandPool: TLabCommandPoolRef;
  const ALevel: TVkCommandBufferLevel
);
  var command_buffer_info: TVkCommandBufferAllocateInfo;
begin
  LabLog('TLabCommandBuffer.Create', 2);
  _CommandPool := ACommandPool;
  LabZeroMem(@command_buffer_info, SizeOf(TVkCommandBufferAllocateInfo));
  command_buffer_info.sType := VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
  command_buffer_info.commandPool := ACommandPool.Ptr.VkHandle;
  command_buffer_info.level := ALevel;
  command_buffer_info.commandBufferCount := 1;
  LabAssetVkError(Vulkan.AllocateCommandBuffers(_CommandPool.Ptr.Device.Ptr.VkHandle, @command_buffer_info, @_Handle));
end;

destructor TLabCommandBuffer.Destroy;
begin
  if LabVkValidHandle(_Handle) then
  begin
    Vulkan.FreeCommandBuffers(_CommandPool.Ptr.Device.Ptr.VkHandle, _CommandPool.Ptr.VkHandle, 1, @_Handle);
  end;
  inherited Destroy;
  LabLog('TLabCommandBuffer.Destroy', -2);
end;
//TLabCommandBuffer END

end.
