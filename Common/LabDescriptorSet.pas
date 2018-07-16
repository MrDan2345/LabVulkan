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
  public
    property VkHandle: TVkDescriptorSetLayout read _Handle;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ABindings: array of TVkDescriptorSetLayoutBinding;
      const AFlags: TVkDescriptorSetLayoutCreateFlags = 0
    );
    destructor Destroy; override;
  end;
  TLabDescriptorSetLayoutShared = specialize TLabSharedRef<TLabDescriptorSetLayout>;

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
      const Writes: array of TVkWriteDescriptorSet;
      const Copies: array of TVkCopyDescriptorSet
    );
  end;
  TLabDescriptorSetsShared = specialize TLabSharedRef<TLabDescriptorSets>;

function LabDescriptorBinding(
  const DescriptorType: TVkDescriptorType;
  const DescriptorCount: TVkUInt32 = 1;
  const StageFlags: TVkShaderStageFlags = TVkFlags(VK_SHADER_STAGE_ALL);
  const PImmutableSamplers: PVkSampler = nil;
  const Binding: TVkUInt32 = $ffffffff
): TVkDescriptorSetLayoutBinding;

function LabWriteDescriptorSet(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const DescriptorType: TVkDescriptorType;
  const DstArrayElement: TVkUInt32 = 0;
  const DescriptorCount: TVkUInt32 = 1;
  const ImageInfo: PVkDescriptorImageInfo = nil;
  const BufferInfo: PVkDescriptorBufferInfo = nil;
  const TexelBufferView: PVkBufferView = nil
): TVkWriteDescriptorSet;

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
  const Writes: array of TVkWriteDescriptorSet;
  const Copies: array of TVkCopyDescriptorSet
);
begin
  Vulkan.UpdateDescriptorSets(_Device.Ptr.VkHandle, Length(Writes), @Writes[0], Length(Copies), @Copies[0]);
end;

function LabDescriptorBinding(
  const DescriptorType: TVkDescriptorType;
  const DescriptorCount: TVkUInt32;
  const StageFlags: TVkShaderStageFlags;
  const PImmutableSamplers: PVkSampler;
  const Binding: TVkUInt32
): TVkDescriptorSetLayoutBinding;
begin
  Result.binding := Binding;
  Result.descriptorType := DescriptorType;
  Result.descriptorCount := DescriptorCount;
  Result.stageFlags := StageFlags;
  Result.pImmutableSamplers := PImmutableSamplers;
end;

function LabWriteDescriptorSet(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const DescriptorType: TVkDescriptorType;
  const DstArrayElement: TVkUInt32;
  const DescriptorCount: TVkUInt32;
  const ImageInfo: PVkDescriptorImageInfo;
  const BufferInfo: PVkDescriptorBufferInfo;
  const TexelBufferView: PVkBufferView
): TVkWriteDescriptorSet;
begin
  Result.sType := VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
  Result.pNext := nil;
  Result.dstSet := DstSet;
  Result.dstBinding := DstBinding;
  Result.dstArrayElement := DstArrayElement;
  Result.descriptorCount := DescriptorCount;
  Result.descriptorType := DescriptorType;
  Result.pImageInfo := ImageInfo;
  Result.pBufferInfo := BufferInfo;
  Result.pTexelBufferView := TexelBufferView;
end;

end.
