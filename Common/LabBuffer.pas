unit LabBuffer;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice;

type
  TLabBuffer = class (TLabClass)
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
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ABufferSize: TVkDeviceSize;
      const AQueueFamilyIndices: array of TVkUInt32;
      const ASharingMode: TVkSharingMode = VK_SHARING_MODE_EXCLUSIVE;
      const AFlags: TVkBufferCreateFlags = 0
    );
    destructor Destroy; override;
    function Map(
      var Buffer: PVkVoid;
      const Offset: TVkDeviceSize = 0;
      const MapSize: TVkDeviceSize = 0;
      const Flags: TVkMemoryMapFlags = 0
    ): Boolean;
    function Unmap: Boolean;
  end;
  TLabBufferShared = specialize TLabSharedRef<TLabBuffer>;

implementation

function TLabBuffer.GetBufferInfo: PVkDescriptorBufferInfo;
begin
  Result := @_BufferInfo;
end;

constructor TLabBuffer.Create(const ADevice: TLabDeviceShared;
  const ABufferSize: TVkDeviceSize;
  const AQueueFamilyIndices: array of TVkUInt32;
  const ASharingMode: TVkSharingMode; const AFlags: TVkBufferCreateFlags);
  var buffer_info: TVkBufferCreateInfo;
  var memory_reqs: TVkMemoryRequirements;
  var alloc_info: TVkMemoryAllocateInfo;
begin
  LabLog('TLabBuffer.Create');
  inherited Create;
  _Device := ADevice;
  _Size := ABufferSize;
  LabZeroMem(@buffer_info, SizeOf(TVkBufferCreateInfo));
  buffer_info.sType := VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
  buffer_info.usage := TVkFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT);
  buffer_info.size := ABufferSize;
  buffer_info.queueFamilyIndexCount := Length(AQueueFamilyIndices);
  buffer_info.pQueueFamilyIndices := @AQueueFamilyIndices[0];
  buffer_info.sharingMode := ASharingMode;
  buffer_info.flags := AFlags;
  LabAssertVkError(Vulkan.CreateBuffer(_Device.Ptr.VkHandle, @buffer_info, nil, @_Handle));
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
  LabAssertVkError(Vulkan.AllocateMemory(_Device.Ptr.VkHandle, @alloc_info, nil, @_Memory));
  Vulkan.BindBufferMemory(_Device.Ptr.VkHandle, _Handle, _Memory, 0);
  _BufferInfo.buffer := _Handle;
  _BufferInfo.offset := 0;
  _BufferInfo.range := _Size;
end;

destructor TLabBuffer.Destroy;
begin
  if _Mapped then Unmap;
  Vulkan.DestroyBuffer(_Device.Ptr.VkHandle, _Handle, nil);
  Vulkan.FreeMemory(_Device.Ptr.VkHandle, _Memory, nil);
  inherited Destroy;
  LabLog('TLabBuffer.Destroy');
end;

function TLabBuffer.Map(var Buffer: PVkVoid; const Offset: TVkDeviceSize; const MapSize: TVkDeviceSize; const Flags: TVkMemoryMapFlags): Boolean;
  var map_size: TVkDeviceSize;
begin
  if _Mapped then Exit(False);
  if MapSize = 0 then map_size := _Size else map_size := MapSize;
  LabAssertVkError(Vulkan.MapMemory(_Device.Ptr.VkHandle, _Memory, Offset, map_size, Flags, @Buffer));
  _Mapped := True;
  Result := True;
end;

function TLabBuffer.Unmap: Boolean;
begin
  if not _Mapped then Exit(False);
  Vulkan.UnmapMemory(_Device.Ptr.VkHandle, _Memory);
  _Mapped := False;
  Result := True;
end;

end.
