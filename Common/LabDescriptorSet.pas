unit LabDescriptorSet;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice;

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

function LabDescriptorBinding(
  const DescriptorType: TVkDescriptorType;
  const DescriptorCount: TVkUInt32 = 1;
  const StageFlags: TVkShaderStageFlags = TVkFlags(VK_SHADER_STAGE_ALL);
  const PImmutableSamplers: PVkSampler = nil;
  const Binding: TVkUInt32 = $ffffffff
): TVkDescriptorSetLayoutBinding;

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
  LabAssertVkError(vk.CreateDescriptorSetLayout(_Device.Ptr.VkHandle, @descriptor_set_layout_info, nil, @_Handle));
end;

destructor TLabDescriptorSetLayout.Destroy;
begin
  vk.DestroyDescriptorSetLayout(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabDescriptorSetLayout.Destroy');
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

end.
