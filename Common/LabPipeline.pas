unit LabPipeline;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice,
  LabDescriptorSet;

type
  TLabPipelineLayout = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkPipelineLayout;
    var _DescriptorSetLayouts: array of TVkDescriptorSetLayout;
    function GetDescriptorSetLayouts: PVkDescriptorSetLayout; inline;
    function GetDescriptorSetLayoutCount: TVkInt32; inline;
  public
    property VkHandle: TVkPipelineLayout read _Handle;
    property DescriptorSetLayouts: PVkDescriptorSetLayout read GetDescriptorSetLayouts;
    property DescriptorSetLayoutCount: TVkInt32 read GetDescriptorSetLayoutCount;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const APushConstantRanges: array of TVkPushConstantRange;
      const ADescriptorSetLayouts: array of TLabDescriptorSetLayoutShared
    );
    destructor Destroy; override;
  end;
  TLabPipelineLayoutShared = specialize TLabSharedRef<TLabPipelineLayout>;

function LabPushConstantRange(
  const StageFlags: TVkShaderStageFlags;
  const Offset: TVkUInt32;
  const Size: TVkUInt32
): TVkPushConstantRange;

implementation

function TLabPipelineLayout.GetDescriptorSetLayouts: PVkDescriptorSetLayout;
begin
  Result := @_DescriptorSetLayouts[0];
end;

function TLabPipelineLayout.GetDescriptorSetLayoutCount: TVkInt32;
begin
  Result := Length(_DescriptorSetLayouts);
end;

constructor TLabPipelineLayout.Create(const ADevice: TLabDeviceShared;
  const APushConstantRanges: array of TVkPushConstantRange;
  const ADescriptorSetLayouts: array of TLabDescriptorSetLayoutShared
);
  var pipeline_layout_info: TVkPipelineLayoutCreateInfo;
  var i: TVkInt32;
begin
  LabLog('TLabPipelineLayout.Create');
  inherited Create;
  _Device := ADevice;
  SetLength(_DescriptorSetLayouts, Length(ADescriptorSetLayouts));
  for i := 0 to High(_DescriptorSetLayouts) do
  begin
    _DescriptorSetLayouts[i] := ADescriptorSetLayouts[i].Ptr.VkHandle;
  end;
  FillChar(pipeline_layout_info, SizeOf(pipeline_layout_info), 0);
  pipeline_layout_info.sType := VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
  pipeline_layout_info.pNext := nil;
  pipeline_layout_info.pushConstantRangeCount := Length(APushConstantRanges);
  pipeline_layout_info.pPushConstantRanges := @APushConstantRanges[0];
  pipeline_layout_info.setLayoutCount := Length(_DescriptorSetLayouts);
  pipeline_layout_info.pSetLayouts := @_DescriptorSetLayouts[0];
  LabAssertVkError(vk.CreatePipelineLayout(_Device.Ptr.VkHandle, @pipeline_layout_info, nil, @_Handle));
end;

destructor TLabPipelineLayout.Destroy;
begin
  vk.DestroyPipelineLayout(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabPipelineLayout.Destroy');
end;

function LabPushConstantRange(
  const StageFlags: TVkShaderStageFlags;
  const Offset: TVkUInt32;
  const Size: TVkUInt32
): TVkPushConstantRange;
begin
  Result.stageFlags := StageFlags;
  Result.offset := Offset;
  Result.size := Size;
end;

end.
