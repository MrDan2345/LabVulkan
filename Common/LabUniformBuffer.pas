unit LabUniformBuffer;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice;

type
  TLabUniformBuffer = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkBuffer;
    var _Memory: TVkDeviceMemory;
    var _Size: TVkDeviceSize;
    var _Mapped: Boolean;
    var _BufferInfo: TVkDescriptorBufferInfo;
    function GetBufferInfo: PVkDescriptorBufferInfo; inline;
  public
    property Size: TVkDeviceSize read _Size;
    property IsMapped: Boolean read _Mapped;
    property BufferInfo: PVkDescriptorBufferInfo read GetBufferInfo;
    constructor Create(const ADevice: TLabDeviceShared; const ABufferSize: TVkDeviceSize);
    destructor Destroy; override;
    function Map(
      var Buffer: PVkVoid;
      const Offset: TVkDeviceSize = 0;
      const MapSize: TVkDeviceSize = 0;
      const Flags: TVkMemoryMapFlags = 0
    ): Boolean;
    function Unmap: Boolean;
  end;
  TLabUniformBufferShared = specialize TLabSharedRef<TLabUniformBuffer>;

implementation

function TLabUniformBuffer.GetBufferInfo: PVkDescriptorBufferInfo;
begin
  Result := @_BufferInfo;
end;

constructor TLabUniformBuffer.Create(const ADevice: TLabDeviceShared; const ABufferSize: TVkDeviceSize);
  var buffer_info: TVkBufferCreateInfo;
  var memory_reqs: TVkMemoryRequirements;
  var alloc_info: TVkMemoryAllocateInfo;
begin
  LabLog('TLabUniformBuffer.Create', 2);
  inherited Create;
  _Device := ADevice;
  LabZeroMem(@buffer_info, SizeOf(TVkBufferCreateInfo));
  buffer_info.sType := VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
  buffer_info.usage := TVkFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT);
  buffer_info.size := ABufferSize;
  buffer_info.queueFamilyIndexCount := 0;
  buffer_info.pQueueFamilyIndices := nil;
  buffer_info.sharingMode := VK_SHARING_MODE_EXCLUSIVE;
  buffer_info.flags := 0;
  LabAssetVkError(Vulkan.CreateBuffer(_Device.Ptr.VkHandle, @buffer_info, nil, @_Handle));
  Vulkan.GetBufferMemoryRequirements(_Device.Ptr.VkHandle, _Handle, @memory_reqs);
  LabZeroMem(@alloc_info, SizeOf(TVkMemoryAllocateInfo));
  alloc_info.sType := VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  alloc_info.memoryTypeIndex := 0;
  alloc_info.allocationSize := memory_reqs.size;
  if not _Device.Ptr.MemoryTypeFromProperties(
    memory_reqs.memoryTypeBits,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
    alloc_info.memoryTypeIndex
  ) then
  begin
    LabLog('Error: could not find compatible memory type');
    Exit;
  end;
  LabAssetVkError(Vulkan.AllocateMemory(_Device.Ptr.VkHandle, @alloc_info, nil, @_Memory));
  _Size := memory_reqs.size;
  Vulkan.BindBufferMemory(_Device.Ptr.VkHandle, _Handle, _Memory, 0);
  _BufferInfo.buffer := _Handle;
  _BufferInfo.offset := 0;
  _BufferInfo.range := _Size;
end;

destructor TLabUniformBuffer.Destroy;
begin
  if _Mapped then Unmap;
  Vulkan.DestroyBuffer(_Device.Ptr.VkHandle, _Handle, nil);
  Vulkan.FreeMemory(_Device.Ptr.VkHandle, _Memory, nil);
  inherited Destroy;
  LabLog('TLabUniformBuffer.Destroy', -2);
end;

function TLabUniformBuffer.Map(var Buffer: PVkVoid; const Offset: TVkDeviceSize; const MapSize: TVkDeviceSize; const Flags: TVkMemoryMapFlags): Boolean;
  var map_size: TVkDeviceSize;
begin
  if _Mapped then Exit(False);
  if MapSize = 0 then map_size := _Size else map_size := MapSize;
  LabAssetVkError(Vulkan.MapMemory(_Device.Ptr.VkHandle, _Memory, Offset, map_size, Flags, @Buffer));
  _Mapped := True;
  Result := True;
end;

function TLabUniformBuffer.Unmap: Boolean;
begin
  if not _Mapped then Exit(False);
  Vulkan.UnmapMemory(_Device.Ptr.VkHandle, _Memory);
  Result := True;
end;

end.
