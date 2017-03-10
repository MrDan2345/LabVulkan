unit LabVertexBuffer;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice;

type
  TLabVertexBuffer = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkBuffer;
    var _Memory: TVkDeviceMemory;
    var _Size: TVkDeviceSize;
    var _Mapped: Boolean;
    var _Binding: TVkVertexInputBindingDescription;
    var _Attributes: array of TVkVertexInputAttributeDescription;
    function GetAttribute(const Index: TVkInt32): PVkVertexInputAttributeDescription; inline;
    function GetAttributeCount: TVkInt32; inline;
    procedure SetAttributeCount(const Value: TVkInt32); inline;
    function GetBinding: PVkVertexInputBindingDescription; inline;
  public
    property VkHandle: TVkBuffer read _Handle;
    property Size: TVkDeviceSize read _Size;
    property Binding: PVkVertexInputBindingDescription read GetBinding;
    property Attribute[const Index: TVkInt32]: PVkVertexInputAttributeDescription read GetAttribute;
    property AttributeCount: TVkInt32 read GetAttributeCount write SetAttributeCount;
    constructor Create(const ADevice: TLabDeviceShared; const BufferSize: TVkDeviceSize);
    destructor Destroy; override;
    function Map(var Buffer: PVkVoid; const Offset: TVkDeviceSize = 0; const MapSize: TVkDeviceSize = 0; const Flags: TVkMemoryMapFlags = 0): Boolean;
    function Unmap: Boolean;
  end;
  TLabVertexBufferShared = specialize TLabSharedRef<TLabVertexBuffer>;

implementation

function TLabVertexBuffer.GetAttribute(const Index: TVkInt32): PVkVertexInputAttributeDescription;
begin
  Result := @_Attributes[Index];
end;

function TLabVertexBuffer.GetAttributeCount: TVkInt32;
begin
  Result := Length(_Attributes);
end;

procedure TLabVertexBuffer.SetAttributeCount(const Value: TVkInt32);
begin
  if Length(_Attributes) = Value then Exit;
  SetLength(_Attributes, Value);
end;

function TLabVertexBuffer.GetBinding: PVkVertexInputBindingDescription;
begin
  Result := @_Binding;
end;

constructor TLabVertexBuffer.Create(const ADevice: TLabDeviceShared; const BufferSize: TVkDeviceSize);
  var buffer_info: TVkBufferCreateInfo;
  var mem_reqs: TVkMemoryRequirements;
  var alloc_info: TVkMemoryAllocateInfo;
  var data: PVkUInt8;
begin
  LabLog('TLabVertexBuffer.Create');
  _Mapped := False;
  _Device := ADevice;
  LabZeroMem(@buffer_info, SizeOf(buffer_info));
  buffer_info.sType := VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
  buffer_info.usage := TVkBufferUsageFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);
  buffer_info.size := BufferSize;
  buffer_info.queueFamilyIndexCount := 0;
  buffer_info.pQueueFamilyIndices := nil;
  buffer_info.sharingMode := VK_SHARING_MODE_EXCLUSIVE;
  buffer_info.flags := 0;
  LabAssertVkError(Vulkan.CreateBuffer(_Device.Ptr.VkHandle, @buffer_info, nil, @_Handle));

  Vulkan.GetBufferMemoryRequirements(_Device.Ptr.VkHandle, _Handle, @mem_reqs);
  _Size := mem_reqs.size;
  LabZeroMem(@alloc_info, SizeOf(alloc_info));
  alloc_info.sType := VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  alloc_info.memoryTypeIndex := 0;
  alloc_info.allocationSize := mem_reqs.size;
  if not _Device.Ptr.MemoryTypeFromProperties(
    mem_reqs.memoryTypeBits,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
    alloc_info.memoryTypeIndex
  ) then
  begin
    LabLog('Error: could not find compatible memory type');
    Exit;
  end;
  LabAssertVkError(Vulkan.AllocateMemory(_Device.Ptr.VkHandle, @alloc_info, nil, @_Memory));
  LabAssertVkError(Vulkan.BindBufferMemory(_Device.Ptr.VkHandle, _Handle, _Memory, 0));

  _Binding.binding := 0;
  _Binding.inputRate := VK_VERTEX_INPUT_RATE_VERTEX;
  _Binding.stride := 0;
end;

destructor TLabVertexBuffer.Destroy;
begin
  if LabVkValidHandle(_Handle) then Vulkan.DestroyBuffer(_Device.Ptr.VkHandle, _Handle, nil);
  if LabVkValidHandle(_Memory) then Vulkan.FreeMemory(_Device.Ptr.VkHandle, _Memory, nil);
  inherited Destroy;
  LabLog('TLabVertexBuffer.Destroy');
end;

function TLabVertexBuffer.Map(var Buffer: PVkVoid; const Offset: TVkDeviceSize; const MapSize: TVkDeviceSize; const Flags: TVkMemoryMapFlags): Boolean;
  var map_size: TVkDeviceSize;
begin
  if _Mapped then Unmap;
  if MapSize = 0 then map_size := _Size else map_size := MapSize;
  LabAssertVkError(Vulkan.MapMemory(_Device.Ptr.VkHandle, _Memory, Offset, map_size, 0, @PVkVoid(Buffer)));
  _Mapped := True;
  Result := True;
end;

function TLabVertexBuffer.Unmap: Boolean;
begin
  if not _Mapped then Exit(False);
  Vulkan.UnmapMemory(_Device.Ptr.VkHandle, _Memory);
  Result := True;
end;

end.
