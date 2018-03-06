unit LabBuffer;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice;

type
  TLabBuffer = class (TLabClass)
  protected
    var _Device: TLabDeviceShared;
    var _Handle: TVkBuffer;
    var _Memory: TVkDeviceMemory;
    var _Size: TVkDeviceSize;
    var _Mapped: Boolean;
    var _BufferInfo: TVkDescriptorBufferInfo;
    function GetBufferInfo: PVkDescriptorBufferInfo; inline;
  public
    property VkHandle: TVkBuffer read _Handle;
    property Size: TVkDeviceSize read _Size;
    property IsMapped: Boolean read _Mapped;
    property BufferInfo: PVkDescriptorBufferInfo read GetBufferInfo;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ABufferSize: TVkDeviceSize;
      const AUsage: TVkBufferUsageFlags;
      const AQueueFamilyIndices: array of TVkUInt32;
      const ASharingMode: TVkSharingMode = VK_SHARING_MODE_EXCLUSIVE;
      const AFlags: TVkBufferCreateFlags = 0;
      const AMemoryFlags: TVkFlags = TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
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

  TLabVertexBuffer = class (TLabBuffer)
  private
    var _Binding: TVkVertexInputBindingDescription;
    var _Attributes: array of TVkVertexInputAttributeDescription;
    function GetAttribute(const Index: TVkInt32): PVkVertexInputAttributeDescription; inline;
    function GetAttributeCount: TVkInt32; inline;
    procedure SetAttributeCount(const Value: TVkInt32); inline;
    function GetBinding: PVkVertexInputBindingDescription; inline;
  public
    property Binding: PVkVertexInputBindingDescription read GetBinding;
    property Attribute[const Index: TVkInt32]: PVkVertexInputAttributeDescription read GetAttribute;
    property AttributeCount: TVkInt32 read GetAttributeCount write SetAttributeCount;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ABufferSize: TVkDeviceSize;
      const AStride: TVkUInt32;
      const Attributes: array of TVkVertexInputAttributeDescription;
      const ABinding: TVkUInt32 = 0
    );
    destructor Destroy; override;
    procedure SetAttributes(const Attributes: array of TVkVertexInputAttributeDescription);
  end;
  TLabVertexBufferShared = specialize TLabSharedRef<TLabVertexBuffer>;

  TLabUniformBuffer = class (TLabBuffer)
  public
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ABufferSize: TVkDeviceSize
    );
  end;
  TLabUniformBufferShared = specialize TLabSharedRef<TLabUniformBuffer>;

function LabVertexAttributeDescription(
  const Location: TVkUInt32;
  const Binding: TVkUInt32;
  const Format: TVkFormat;
  const Offset: TVkUInt32
): TVkVertexInputAttributeDescription;

implementation

function TLabBuffer.GetBufferInfo: PVkDescriptorBufferInfo;
begin
  Result := @_BufferInfo;
end;

constructor TLabBuffer.Create(
  const ADevice: TLabDeviceShared;
  const ABufferSize: TVkDeviceSize;
  const AUsage: TVkBufferUsageFlags;
  const AQueueFamilyIndices: array of TVkUInt32;
  const ASharingMode: TVkSharingMode;
  const AFlags: TVkBufferCreateFlags;
  const AMemoryFlags: TVkFlags
);
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
  buffer_info.usage := AUsage;
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
  if not _Device.Ptr.MemoryTypeFromProperties(memory_reqs.memoryTypeBits, AMemoryFlags, alloc_info.memoryTypeIndex) then
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

function TLabVertexBuffer.GetAttribute(const Index: TVkInt32): PVkVertexInputAttributeDescription;
begin
  if (Index < 0) or (Index > High(_Attributes)) then Exit(nil);
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

constructor TLabVertexBuffer.Create(
  const ADevice: TLabDeviceShared;
  const ABufferSize: TVkDeviceSize;
  const AStride: TVkUInt32;
  const Attributes: array of TVkVertexInputAttributeDescription;
  const ABinding: TVkUInt32
);
begin
  LabLog('TLabVertexBuffer.Create');
  inherited Create(ADevice, ABufferSize, TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT), []);
  _Binding.binding := ABinding;
  _Binding.inputRate := VK_VERTEX_INPUT_RATE_VERTEX;
  _Binding.stride := AStride;
  SetAttributes(Attributes);
end;

destructor TLabVertexBuffer.Destroy;
begin
  inherited Destroy;
  LabLog('TLabVertexBuffer.Destroy');
end;

procedure TLabVertexBuffer.SetAttributes(
  const Attributes: array of TVkVertexInputAttributeDescription
);
  var i: Integer;
begin
  AttributeCount := Length(Attributes);
  Move(Attributes[0], _Attributes[0], SizeOf(TVkVertexInputAttributeDescription) * Length(Attributes));
end;

constructor TLabUniformBuffer.Create(
  const ADevice: TLabDeviceShared;
  const ABufferSize: TVkDeviceSize
);
begin
  inherited Create(ADevice, ABufferSize, TVkFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT), []);
end;

function LabVertexAttributeDescription(
  const Location: TVkUInt32;
  const Binding: TVkUInt32;
  const Format: TVkFormat;
  const Offset: TVkUInt32
): TVkVertexInputAttributeDescription;
begin
  Result.location := Location;
  Result.binding := Binding;
  Result.format := Format;
  Result.offset := Offset;
end;

end.
