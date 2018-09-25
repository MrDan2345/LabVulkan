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
    property Memory: TVkDeviceMemory read _Memory;
    property Size: TVkDeviceSize read _Size;
    property IsMapped: Boolean read _Mapped;
    property BufferInfo: PVkDescriptorBufferInfo read GetBufferInfo;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ABufferSize: TVkDeviceSize;
      const AUsage: TVkBufferUsageFlags;
      const AQueueFamilyIndices: array of TVkUInt32;
      const ASharingMode: TVkSharingMode = VK_SHARING_MODE_EXCLUSIVE;
      const AMemoryFlags: TVkFlags = TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
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
    procedure FlushMappedMemoryRanges(const Ranges: array of TVkMappedMemoryRange);
  end;
  TLabBufferShared = specialize TLabSharedRef<TLabBuffer>;

  TLabVertexBufferAttributeFormat = record
    Format: TVkFormat;
    Offset: TVkUInt32;
  end;
  PLabVertexBufferAttributeFormat = ^TLabVertexBufferAttributeFormat;

  TLabVertexInputAttributeDescriptionArr = array of TVkVertexInputAttributeDescription;

  TLabVertexBuffer = class (TLabBuffer)
  private
    var _Stride: TVkUInt32;
    var _Attributes: array of TLabVertexBufferAttributeFormat;
    function GetAttribute(const Index: TVkInt32): PLabVertexBufferAttributeFormat; inline;
    function GetAttributeCount: TVkInt32; inline;
    procedure SetAttributeCount(const Value: TVkInt32); inline;
  public
    property Stride: TVkUInt32 read _Stride;
    property Attribute[const Index: TVkInt32]: PLabVertexBufferAttributeFormat read GetAttribute;
    property AttributeCount: TVkInt32 read GetAttributeCount write SetAttributeCount;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ABufferSize: TVkDeviceSize;
      const AStride: TVkUInt32;
      const AAttributes: array of TLabVertexBufferAttributeFormat;
      const AUsageFlags: TVkFlags = TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);
      const AMemoryFlags: TVkFlags = TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
    );
    destructor Destroy; override;
    procedure SetAttributes(const NewAttributes: array of TLabVertexBufferAttributeFormat);
    function MakeBindingDesc(
      const Binding: TVkUInt32;
      const InputRate: TVkVertexInputRate = VK_VERTEX_INPUT_RATE_VERTEX
    ): TVkVertexInputBindingDescription;
    function MakeAttributeDesc(
      const AttributeIndex: TVkInt32;
      const Location: TVkUInt32;
      const Binding: TVkUInt32
    ): TVkVertexInputAttributeDescription;
    function MakeAttributeDescArr(
      const StartingLocation: TVkUInt32;
      const Binding: TVkUInt32
    ): TLabVertexInputAttributeDescriptionArr;
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

  TLabPipelineVertexInputState = record
    CreateInfo: TVkPipelineVertexInputStateCreateInfo;
    Data: record
      InputBindings: array of TVkVertexInputBindingDescription;
      Attributes: array of TVkVertexInputAttributeDescription;
    end;
  end;

function LabVertexBufferAttributeFormat(
  const Format: TVkFormat;
  const Offset: TVkUInt32
): TLabVertexBufferAttributeFormat; inline;

function LabVertexAttributeDescription(
  const Location: TVkUInt32;
  const Binding: TVkUInt32;
  const Format: TVkFormat;
  const Offset: TVkUInt32
): TVkVertexInputAttributeDescription; inline;

function LabVertexInputBindingDescription(
  const Binding: TVkUInt32;
  const Stride: TVkUInt32;
  const InputRate: TVkVertexInputRate = VK_VERTEX_INPUT_RATE_VERTEX
): TVkVertexInputBindingDescription; inline;

function LabBufferCopy(
  const Size: TVkDeviceSize;
  const SrcOffset: TVkDeviceSize = 0;
  const DstOffset: TVkDeviceSize = 0
): TVkBufferCopy; inline;

function LabBufferImageCopy(
  const ImageOffset: TVkOffset3D;
  const ImageExtent: TVkExtent3D;
  const ImageAspectMask: TVkImageAspectFlags = TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT);
  const ImageMipLevel: TVkUInt32 = 0;
  const ImageBaseArrayLayer: TVkUInt32 = 0;
  const ImageArrayLayerCount: TVkUInt32 = 1;
  const BufferOffset: TVkDeviceSize = 0;
  const BufferRowLength: TVkUInt32 = 0;
  const BufferImageHeight: TVkUInt32 = 0
): TVkBufferImageCopy; inline;

function LabMappedMemoryRange(
  const Memory: TVkDeviceMemory;
  const Offset: TVkDeviceSize;
  const Size: TVkDeviceSize
): TVkMappedMemoryRange; inline;

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
  const AMemoryFlags: TVkFlags;
  const AFlags: TVkBufferCreateFlags
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

procedure TLabBuffer.FlushMappedMemoryRanges(const Ranges: array of TVkMappedMemoryRange);
begin
  Vulkan.FlushMappedMemoryRanges(_Device.Ptr.VkHandle, Length(Ranges), @Ranges[0]);
end;

function TLabVertexBuffer.GetAttribute(const Index: TVkInt32
  ): PLabVertexBufferAttributeFormat;
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

constructor TLabVertexBuffer.Create(const ADevice: TLabDeviceShared;
  const ABufferSize: TVkDeviceSize; const AStride: TVkUInt32;
  const AAttributes: array of TLabVertexBufferAttributeFormat;
  const AUsageFlags: TVkFlags;
  const AMemoryFlags: TVkFlags
);
begin
  LabLog('TLabVertexBuffer.Create');
  inherited Create(ADevice, ABufferSize, AUsageFlags, []);
  _Stride := AStride;
  SetAttributes(AAttributes);
end;

destructor TLabVertexBuffer.Destroy;
begin
  inherited Destroy;
  LabLog('TLabVertexBuffer.Destroy');
end;

procedure TLabVertexBuffer.SetAttributes(
  const NewAttributes: array of TLabVertexBufferAttributeFormat);
  var i: Integer;
begin
  AttributeCount := Length(NewAttributes);
  Move(NewAttributes[0], _Attributes[0], SizeOf(TLabVertexBufferAttributeFormat) * Length(NewAttributes));
end;

function TLabVertexBuffer.MakeBindingDesc(
  const Binding: TVkUInt32;
  const InputRate: TVkVertexInputRate
): TVkVertexInputBindingDescription;
begin
  Result.binding := Binding;
  Result.stride := _Stride;
  Result.inputRate := InputRate;
end;

function TLabVertexBuffer.MakeAttributeDesc(
  const AttributeIndex: TVkInt32;
  const Location: TVkUInt32;
  const Binding: TVkUInt32
): TVkVertexInputAttributeDescription;
begin
  Result.location := Location;
  Result.binding := Binding;
  Result.format := _Attributes[AttributeIndex].Format;
  Result.offset := _Attributes[AttributeIndex].Offset;
end;

function TLabVertexBuffer.MakeAttributeDescArr(
  const StartingLocation: TVkUInt32;
  const Binding: TVkUInt32
): TLabVertexInputAttributeDescriptionArr;
  var i: TVkUInt32;
begin
  SetLength(Result, Length(_Attributes));
  FillChar(Result[0], Length(Result) * SizeOf(TVkVertexInputAttributeDescription), 0);
  for i := 0 to High(_Attributes) do
  begin
    Result[i].location := StartingLocation + i;
    Result[i].binding := Binding;
    Result[i].format := _Attributes[i].Format;
    Result[i].offset := _Attributes[i].Offset;
  end;
end;

constructor TLabUniformBuffer.Create(
  const ADevice: TLabDeviceShared;
  const ABufferSize: TVkDeviceSize
);
begin
  inherited Create(ADevice, ABufferSize, TVkFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT), []);
end;

function LabVertexBufferAttributeFormat(
  const Format: TVkFormat;
  const Offset: TVkUInt32
): TLabVertexBufferAttributeFormat;
begin
  Result.Format := Format;
  Result.Offset := Offset;
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

function LabVertexInputBindingDescription(
  const Binding: TVkUInt32;
  const Stride: TVkUInt32;
  const InputRate: TVkVertexInputRate
): TVkVertexInputBindingDescription;
begin
  Result.binding := Binding;
  Result.stride := Stride;
  Result.inputRate := InputRate;
end;

function LabBufferCopy(
  const Size: TVkDeviceSize;
  const SrcOffset: TVkDeviceSize;
  const DstOffset: TVkDeviceSize
): TVkBufferCopy;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.srcOffset := SrcOffset;
  Result.dstOffset := DstOffset;
  Result.size := Size;
end;

function LabBufferImageCopy(
  const ImageOffset: TVkOffset3D;
  const ImageExtent: TVkExtent3D;
  const ImageAspectMask: TVkImageAspectFlags;
  const ImageMipLevel: TVkUInt32;
  const ImageBaseArrayLayer: TVkUInt32;
  const ImageArrayLayerCount: TVkUInt32;
  const BufferOffset: TVkDeviceSize;
  const BufferRowLength: TVkUInt32;
  const BufferImageHeight: TVkUInt32
): TVkBufferImageCopy;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.bufferOffset := BufferOffset;
  Result.bufferRowLength := BufferRowLength;
  Result.bufferImageHeight := BufferImageHeight;
  Result.imageSubresource.aspectMask := ImageAspectMask;
  Result.imageSubresource.mipLevel := ImageMipLevel;
  Result.imageSubresource.baseArrayLayer := ImageBaseArrayLayer;
  Result.imageSubresource.layerCount := ImageArrayLayerCount;
  Result.imageOffset := ImageOffset;
  Result.imageExtent := ImageExtent;
end;

function LabMappedMemoryRange(
  const Memory: TVkDeviceMemory;
  const Offset: TVkDeviceSize;
  const Size: TVkDeviceSize
): TVkMappedMemoryRange;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.sType := VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
  Result.memory := Memory;
  Result.offset := Offset;
  Result.size := Size;
end;

end.
