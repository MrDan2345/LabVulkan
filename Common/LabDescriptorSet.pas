unit LabDescriptorSet;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice,
  LabDescriptorPool;

type
  TLabDescriptorSetLayout = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Bindings: array of TVkDescriptorSetLayoutBinding;
    var _Flags: TVkDescriptorSetLayoutCreateFlags;
    var _Handle: TVkDescriptorSetLayout;
    var _Hash: TVkUInt32;
  public
    property VkHandle: TVkDescriptorSetLayout read _Handle;
    property Hash: TVkUInt32 read _Hash;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ABindings: array of TVkDescriptorSetLayoutBinding;
      const AFlags: TVkDescriptorSetLayoutCreateFlags = 0
    );
    destructor Destroy; override;
  end;
  TLabDescriptorSetLayoutShared = specialize TLabSharedRef<TLabDescriptorSetLayout>;

  TLabWriteDescriptorSet = record
    WriteDescriptorSet: TVkWriteDescriptorSet;
    ImageInfos: array of TVkDescriptorImageInfo;
    BufferInfos: array of TVkDescriptorBufferInfo;
    TexelBufferViews: array of TVkBufferView;
  end;

  TLabDescriptorSets = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Pool: TLabDescriptorPoolShared;
    var _Handles: array of TVkDescriptorSet;
    function GetHandleCount: TVkInt32; inline;
    function GetHandle(const Index: TVkInt32): TVkDescriptorSet; inline;
    function GetHandlePtr(const Index: TVkInt32): PVkDescriptorSet; inline;
  public
    property HandleCount: TVkInt32 read GetHandleCount;
    property VkHandle[const Index: TVkInt32]: TVkDescriptorSet read GetHandle; default;
    property VkHandlePtr[const Index: TVkInt32]: PVkDescriptorSet read GetHandlePtr;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ADescriptorPool: TLabDescriptorPoolShared;
      const ALayouts: array of TVkDescriptorSetLayout
    );
    destructor Destroy; override;
    procedure UpdateSets(
      const Writes: array of TLabWriteDescriptorSet;
      const Copies: array of TVkCopyDescriptorSet
    );
  end;
  TLabDescriptorSetsShared = specialize TLabSharedRef<TLabDescriptorSets>;

function LabDescriptorBinding(
  const Binding: TVkUInt32;
  const DescriptorType: TVkDescriptorType;
  const DescriptorCount: TVkUInt32 = 1;
  const StageFlags: TVkShaderStageFlags = TVkFlags(VK_SHADER_STAGE_ALL);
  const PImmutableSamplers: PVkSampler = nil
): TVkDescriptorSetLayoutBinding;

function LabWriteDescriptorSet(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const DescriptorType: TVkDescriptorType;
  const DstArrayElement: TVkUInt32;
  const DescriptorCount: TVkUInt32;
  const ImageInfos: array of TVkDescriptorImageInfo;
  const BufferInfos: array of TVkDescriptorBufferInfo;
  const TexelBufferViews: array of TVkBufferView
): TLabWriteDescriptorSet; inline;

function LabWriteDescriptorSetUniformBuffer(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet; inline;

function LabWriteDescriptorSetUniformBufferDynamic(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet; inline;

function LabWriteDescriptorSetImageSampler(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const ImageInfo: array of TVkDescriptorImageInfo
): TLabWriteDescriptorSet; inline;

function LabDescriptorBufferInfo(
  const Buffer: TVkBuffer;
  const Offset: TVkDeviceSize = 0;
  const Range: TVkDeviceSize = VK_WHOLE_SIZE
): TVkDescriptorBufferInfo; inline;

function LabDescriptorImageInfo(
  const ImageLayout: TVkImageLayout;
  const ImageView: TVkImageView;
  const Sampler: TVkSampler
): TVkDescriptorImageInfo; inline;

implementation

constructor TLabDescriptorSetLayout.Create(
  const ADevice: TLabDeviceShared;
  const ABindings: array of TVkDescriptorSetLayoutBinding;
  const AFlags: TVkDescriptorSetLayoutCreateFlags
);
  var i: Integer;
  var descriptor_set_layout_info: TVkDescriptorSetLayoutCreateInfo;
begin
  LabLog('TLabDescriptorSetLayout.Create');
  _Device := ADevice;
  _Flags := AFlags;
  SetLength(_Bindings, Length(ABindings));
  Move(ABindings[0], _Bindings[0], Length(_Bindings) * SizeOf(TVkDescriptorSetLayoutBinding));
  for i := 0 to High(_Bindings) do
  if _Bindings[i].binding = $ffffffff then _Bindings[i].binding := TVkUInt32(i);
  FillChar(descriptor_set_layout_info, SizeOf(descriptor_set_layout_info), 0);
  descriptor_set_layout_info.sType := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
  descriptor_set_layout_info.pNext := nil;
  descriptor_set_layout_info.flags := _Flags;
  descriptor_set_layout_info.bindingCount := Length(_Bindings);
  descriptor_set_layout_info.pBindings := @_Bindings[0];
  LabAssertVkError(Vulkan.CreateDescriptorSetLayout(_Device.Ptr.VkHandle, @descriptor_set_layout_info, nil, @_Handle));
  _Hash := LabCRC32(0, @_Flags, SizeOf(_Flags));
  _Hash := LabCRC32(_Hash, @_Bindings[0], Length(_Bindings) * SizeOf(TVkDescriptorSetLayoutBinding));
end;

destructor TLabDescriptorSetLayout.Destroy;
begin
  Vulkan.DestroyDescriptorSetLayout(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabDescriptorSetLayout.Destroy');
end;

function TLabDescriptorSets.GetHandleCount: TVkInt32;
begin
  Result := Length(_Handles);
end;

function TLabDescriptorSets.GetHandle(const Index: TVkInt32): TVkDescriptorSet;
begin
  Result := _Handles[Index];
end;

function TLabDescriptorSets.GetHandlePtr(const Index: TVkInt32): PVkDescriptorSet;
begin
  Result := @_Handles[Index];
end;

constructor TLabDescriptorSets.Create(
  const ADevice: TLabDeviceShared;
  const ADescriptorPool: TLabDescriptorPoolShared;
  const ALayouts: array of TVkDescriptorSetLayout
);
  var alloc_info: array[0..0] of TVkDescriptorSetAllocateInfo;
begin
  LabLog('TLabDescriptorSets.Create');
  _Device := ADevice;
  _Pool := ADescriptorPool;
  SetLength(_Handles, Length(ALayouts));
  alloc_info[0].sType := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
  alloc_info[0].pNext := nil;
  alloc_info[0].descriptorPool := _Pool.Ptr.VkHandle;
  alloc_info[0].descriptorSetCount := Length(ALayouts);
  alloc_info[0].pSetLayouts := @ALayouts[0];
  LabAssertVkError(Vulkan.AllocateDescriptorSets(_Device.Ptr.VkHandle, @alloc_info[0], @_Handles[0]));
end;

destructor TLabDescriptorSets.Destroy;
begin
  LabAssertVkError(Vulkan.FreeDescriptorSets(_Device.Ptr.VkHandle, _Pool.Ptr.VkHandle, Length(_Handles), @_Handles[0]));
  inherited Destroy;
  LabLog('TLabDescriptorSets.Destroy');
end;

procedure TLabDescriptorSets.UpdateSets(
  const Writes: array of TLabWriteDescriptorSet;
  const Copies: array of TVkCopyDescriptorSet
);
  var WriteData: array of TVkWriteDescriptorSet;
  var WritePtr: PVkWriteDescriptorSet;
  var CopyPtr: PVkCopyDescriptorSet;
  var i: TVkInt32;
begin
  if Length(Writes) > 0 then
  begin
    SetLength(WriteData, Length(Writes));
    for i := 0 to High(Writes) do
    begin
      WriteData[i] := Writes[i].WriteDescriptorSet;
    end;
    WritePtr := @WriteData[0];
  end
  else
  begin
    WritePtr := nil;
  end;
  if Length(Copies) > 0 then
  begin
    CopyPtr := @Copies[0];
  end
  else
  begin
    CopyPtr := nil;
  end;
  Vulkan.UpdateDescriptorSets(_Device.Ptr.VkHandle, Length(Writes), WritePtr, Length(Copies), CopyPtr);
end;

function LabDescriptorBinding(
  const Binding: TVkUInt32;
  const DescriptorType: TVkDescriptorType;
  const DescriptorCount: TVkUInt32;
  const StageFlags: TVkShaderStageFlags;
  const PImmutableSamplers: PVkSampler
): TVkDescriptorSetLayoutBinding;
begin
  Result.binding := Binding;
  Result.descriptorType := DescriptorType;
  Result.descriptorCount := DescriptorCount;
  Result.stageFlags := StageFlags;
  Result.pImmutableSamplers := PImmutableSamplers;
end;

function LabWriteDescriptorSet(const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32; const DescriptorType: TVkDescriptorType;
  const DstArrayElement: TVkUInt32; const DescriptorCount: TVkUInt32;
  const ImageInfos: array of TVkDescriptorImageInfo;
  const BufferInfos: array of TVkDescriptorBufferInfo;
  const TexelBufferViews: array of TVkBufferView): TLabWriteDescriptorSet;
begin
  Result.WriteDescriptorSet.sType := VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
  Result.WriteDescriptorSet.pNext := nil;
  Result.WriteDescriptorSet.dstSet := DstSet;
  Result.WriteDescriptorSet.dstBinding := DstBinding;
  Result.WriteDescriptorSet.dstArrayElement := DstArrayElement;
  Result.WriteDescriptorSet.descriptorCount := DescriptorCount;
  Result.WriteDescriptorSet.descriptorType := DescriptorType;
  if Length(ImageInfos) > 0 then
  begin
    SetLength(Result.ImageInfos, Length(ImageInfos));
    Move(ImageInfos[0], Result.ImageInfos[0], SizeOf(TVkDescriptorImageInfo));
    Result.WriteDescriptorSet.pImageInfo := @Result.ImageInfos[0];
  end
  else
  begin
    Result.WriteDescriptorSet.pImageInfo := nil;
  end;
  if Length(BufferInfos) > 0 then
  begin
    SetLength(Result.BufferInfos, Length(BufferInfos));
    Move(BufferInfos[0], Result.BufferInfos[0], SizeOf(TVkDescriptorBufferInfo));
    Result.WriteDescriptorSet.pBufferInfo := @Result.BufferInfos[0];
  end
  else
  begin
    Result.WriteDescriptorSet.pBufferInfo := nil;
  end;
  if Length(TexelBufferViews) > 0 then
  begin
    SetLength(Result.TexelBufferViews, Length(TexelBufferViews));
    Move(TexelBufferViews[0], Result.TexelBufferViews[0], SizeOf(TVkBufferView));
    Result.WriteDescriptorSet.pTexelBufferView := @TexelBufferViews[0];
  end
  else
  begin
    Result.WriteDescriptorSet.pTexelBufferView := nil;
  end;
end;

function LabWriteDescriptorSetUniformBuffer(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet;
begin
  Result := LabWriteDescriptorSet(
    DstSet, DstBinding,
    VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
    0, Length(BufferInfo), [], BufferInfo, []
  );
end;

function LabWriteDescriptorSetUniformBufferDynamic(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet;
begin
  Result := LabWriteDescriptorSet(
    DstSet, DstBinding,
    VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
    0, Length(BufferInfo), [], BufferInfo, []
  );
end;

function LabWriteDescriptorSetImageSampler(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const ImageInfo: array of TVkDescriptorImageInfo
): TLabWriteDescriptorSet;
begin
  Result := LabWriteDescriptorSet(
    DstSet, DstBinding,
    VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
    0, Length(ImageInfo), ImageInfo, [], []
  );
end;

function LabDescriptorBufferInfo(
  const Buffer: TVkBuffer;
  const Offset: TVkDeviceSize;
  const Range: TVkDeviceSize
): TVkDescriptorBufferInfo;
begin
  Result.buffer := Buffer;
  Result.offset := Offset;
  Result.range := Range;
end;

function LabDescriptorImageInfo(
  const ImageLayout: TVkImageLayout;
  const ImageView: TVkImageView;
  const Sampler: TVkSampler
): TVkDescriptorImageInfo;
begin
  Result.imageLayout := ImageLayout;
  Result.imageView := ImageView;
  Result.sampler := Sampler;
end;

end.
