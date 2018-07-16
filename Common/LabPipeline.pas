unit LabPipeline;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice,
  LabDescriptorSet,
  LabBuffer,
  LabRenderPass,
  LabShader;

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

  TLabPipelineCache = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkPipelineCache;
  public
    property VkHandle: TVkPipelineCache read _Handle;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const AInitialCache: PVkVoid = nil;
      const AInitialCacheSize: TVkUInt32 = 0;
      const AFlags: TVkPipelineCacheCreateFlags = 0
    );
    destructor Destroy; override;
  end;
  TLabPipelineCacheShared = specialize TLabSharedRef<TLabPipelineCache>;

  TLabPipeline = class (TLabClass)
  protected
    var _Device: TLabDeviceShared;
    var _Cache: TLabPipelineCacheShared;
    var _Handle: TVkPipeline;
    var _BindPoint: TVkPipelineBindPoint;
  public
    property VkHandle: TVkPipeline read _Handle;
    property BindPoint: TVkPipelineBindPoint read _BindPoint;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const APipelineCache: TLabPipelineCacheShared;
      const ABindPoint: TVkPipelineBindPoint
    );
    destructor Destroy; override;
  end;

  TLabGraphicsPipeline = class (TLabPipeline)
  public
    constructor Create(
      const ADevice: TLabDeviceShared;
      const APipelineCache: TLabPipelineCacheShared;
      const APipelineLayout: TLabPipelineLayout;
      const ADynamicStates: array of TVkDynamicState;
      const AShaderStages: TLabShaderStages;
      const ARenderPass: TLabRenderPass;
      const ASubpass: TVkUInt32;
      const AViewportState: TVkPipelineViewportStateCreateInfo;
      const AInputAssemblyState: TVkPipelineInputAssemblyStateCreateInfo;
      const AVertexInputState: TLabPipelineVertexInputState;
      const ARasterizationState: TVkPipelineRasterizationStateCreateInfo;
      const ADepthStencilState: TVkPipelineDepthStencilStateCreateInfo;
      const AMultisampleState: TVkPipelineMultisampleStateCreateInfo;
      const AColorBlendState: TVkPipelineColorBlendStateCreateInfo
    );
    destructor Destroy; override;
  end;
  TLabPipelineShared = specialize TLabSharedRef<TLabPipeline>;

const
  LabDefaultStencilOpState: TVkStencilOpState = (
    failOp: VK_STENCIL_OP_KEEP;
    passOp: VK_STENCIL_OP_KEEP;
    depthFailOp: VK_STENCIL_OP_KEEP;
    compareOp: VK_COMPARE_OP_ALWAYS;
    compareMask: 0;
    writeMask: 0;
    reference: 0;
  );
  LabDefaultColorBlendAttachment: TVkPipelineColorBlendAttachmentState = (
    blendEnable: VK_FALSE;
    srcColorBlendFactor: VK_BLEND_FACTOR_ZERO;
    dstColorBlendFactor: VK_BLEND_FACTOR_ZERO;
    colorBlendOp: VK_BLEND_OP_ADD;
    srcAlphaBlendFactor: VK_BLEND_FACTOR_ZERO;
    dstAlphaBlendFactor: VK_BLEND_FACTOR_ZERO;
    alphaBlendOp: VK_BLEND_OP_ADD;
    colorWriteMask: $f;
  );

function LabPushConstantRange(
  const StageFlags: TVkShaderStageFlags;
  const Offset: TVkUInt32;
  const Size: TVkUInt32
): TVkPushConstantRange;

function LabPipelineViewportState(
  const ViewportCount: TVkUInt32 = 1;
  const Viewports: PVkViewport = nil;
  const ScissorCount: TVkUInt32 = 1;
  const Scissors: PVkRect2D = nil;
  const Flags: TVkPipelineViewportStateCreateFlags = 0
): TVkPipelineViewportStateCreateInfo;

function LabPipelineInputAssemblyState(
  const Topology: TVkPrimitiveTopology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
  const PrimitiveRestartEnable: TVkBool32 = VK_FALSE;
  const Flags: TVkPipelineInputAssemblyStateCreateFlags = 0
): TVkPipelineInputAssemblyStateCreateInfo;

function LabPipelineVertexInputState(
  const VertexBindingDescriptions: array of TVkVertexInputBindingDescription;
  const VertexAttributeDescriptions: array of TVkVertexInputAttributeDescription;
  const Flags: TVkPipelineVertexInputStateCreateFlags = 0
): TLabPipelineVertexInputState;

function LabPipelineRasterizationState(
  const DepthClampEnable: TVkBool32 = VK_FALSE;
  const RasterizerDiscardEnable: TVkBool32 = VK_FALSE;
  const PolygonMode: TVkPolygonMode = VK_POLYGON_MODE_FILL;
  const CullMode: TVkCullModeFlags = TVkFlags(VK_CULL_MODE_BACK_BIT);
  const FrontFace: TVkFrontFace = VK_FRONT_FACE_CLOCKWISE;
  const DepthBiasEnable: TVkBool32 = VK_FALSE;
  const DepthBiasConstantFactor: TVkFloat = 0;
  const DepthBiasClamp: TVkFloat = 0;
  const DepthBiasSlopeFactor: TVkFloat = 0;
  const LineWidth: TVkFloat = 1;
  const Flags: TVkPipelineRasterizationStateCreateFlags = 0
): TVkPipelineRasterizationStateCreateInfo;

function LabPipelineDepthStencilState(
  const Front: TVkStencilOpState;
  const Back: TVkStencilOpState;
  const DepthTestEnable: TVkBool32 = VK_TRUE;
  const DepthWriteEnable: TVkBool32 = VK_TRUE;
  const DepthCompareOp: TVkCompareOp = VK_COMPARE_OP_LESS_OR_EQUAL;
  const DepthBoundsTestEnable: TVkBool32 = VK_FALSE;
  const StencilTestEnable: TVkBool32 = VK_FALSE;
  const MinDepthBounds: TVkFloat = 0;
  const MaxDepthBounds: TVkFloat = 0;
  const Flags: TVkPipelineDepthStencilStateCreateFlags = 0
): TVkPipelineDepthStencilStateCreateInfo;

function LabPipelineMultisampleState(
  const RasterizationSamples: TVkSampleCountFlagBits = VK_SAMPLE_COUNT_1_BIT;
  const SampleShadingEnable: TVkBool32 = VK_FALSE;
  const MinSampleShading: TVkFloat = 0;
  const SampleMask: PVkSampleMask = nil;
  const AlphaToCoverageEnable: TVkBool32 = VK_FALSE;
  const AlphaToOneEnable: TVkBool32 = VK_FALSE;
  const Flags: TVkPipelineMultisampleStateCreateFlags = 0
): TVkPipelineMultisampleStateCreateInfo;

function LabPipelineColorBlendState(
  const AttachmentCount: TVkUInt32;
  const Attachments: PVkPipelineColorBlendAttachmentState;
  const BlendConstants: array of TVkFloat;
  const LogicOpEnable: TVkBool32 = VK_FALSE;
  const LogicOp: TVkLogicOp = VK_LOGIC_OP_NO_OP;
  const Flags:TVkPipelineColorBlendStateCreateFlags = 0
): TVkPipelineColorBlendStateCreateInfo;

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
  LabAssertVkError(Vulkan.CreatePipelineLayout(_Device.Ptr.VkHandle, @pipeline_layout_info, nil, @_Handle));
end;

destructor TLabPipelineLayout.Destroy;
begin
  Vulkan.DestroyPipelineLayout(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabPipelineLayout.Destroy');
end;

constructor TLabPipelineCache.Create(
  const ADevice: TLabDeviceShared;
  const AInitialCache: PVkVoid;
  const AInitialCacheSize: TVkUInt32;
  const AFlags: TVkPipelineCacheCreateFlags
);
  var pipeline_cache_info: TVkPipelineCacheCreateInfo;
begin
  LabLog('TLabPipelineCache.Create');
  _Device := ADevice;
  pipeline_cache_info.sType := VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
  pipeline_cache_info.pNext := nil;
  pipeline_cache_info.initialDataSize := AInitialCacheSize;
  pipeline_cache_info.pInitialData := AInitialCache;
  pipeline_cache_info.flags := AFlags;
  LabAssertVkError(Vulkan.CreatePipelineCache(_Device.Ptr.VkHandle, @pipeline_cache_info, nil, @_Handle));
end;

destructor TLabPipelineCache.Destroy;
begin
  Vulkan.DestroyPipelineCache(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabPipelineCache.Destroy');
end;

constructor TLabPipeline.Create(
  const ADevice: TLabDeviceShared;
  const APipelineCache: TLabPipelineCacheShared;
  const ABindPoint: TVkPipelineBindPoint
);
begin
  LabLog('TLabPipeline.Create');
  _Device := ADevice;
  _Cache := APipelineCache;
  _Handle := VK_NULL_HANDLE;
  _BindPoint := ABindPoint;
end;

destructor TLabPipeline.Destroy;
begin
  if LabVkValidHandle(_Handle) then
  begin
    Vulkan.DestroyPipeline(_Device.Ptr.VkHandle, _Handle, nil);
  end;
  inherited Destroy;
  LabLog('TLabPipeline.Destroy');
end;

constructor TLabGraphicsPipeline.Create(
  const ADevice: TLabDeviceShared;
  const APipelineCache: TLabPipelineCacheShared;
  const APipelineLayout: TLabPipelineLayout;
  const ADynamicStates: array of TVkDynamicState;
  const AShaderStages: TLabShaderStages;
  const ARenderPass: TLabRenderPass;
  const ASubpass: TVkUInt32;
  const AViewportState: TVkPipelineViewportStateCreateInfo;
  const AInputAssemblyState: TVkPipelineInputAssemblyStateCreateInfo;
  const AVertexInputState: TLabPipelineVertexInputState;
  const ARasterizationState: TVkPipelineRasterizationStateCreateInfo;
  const ADepthStencilState: TVkPipelineDepthStencilStateCreateInfo;
  const AMultisampleState: TVkPipelineMultisampleStateCreateInfo;
  const AColorBlendState: TVkPipelineColorBlendStateCreateInfo
);
  var dynamic_state_info: TVkPipelineDynamicStateCreateInfo;
  var pipeline_info: TVkGraphicsPipelineCreateInfo;
  var dynamic_state_enables: array of TVkDynamicState;
begin
  inherited Create(ADevice, APipelineCache, VK_PIPELINE_BIND_POINT_GRAPHICS);
  FillChar(dynamic_state_info, SizeOf(dynamic_state_info), 0);
  dynamic_state_info.sType := VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
  dynamic_state_info.pNext := nil;
  dynamic_state_info.pDynamicStates := @ADynamicStates[0];
  dynamic_state_info.dynamicStateCount := Length(ADynamicStates);
  SetLength(dynamic_state_enables, Length(ADynamicStates));
  Move(ADynamicStates[0], dynamic_state_enables[0], SizeOf(TVkDynamicState) * Length(ADynamicStates));
{$ifndef __ANDROID__}

{$else}
  // Temporary disabling dynamic viewport on Android because some of drivers doesn't
  // support the feature.
  VkViewport viewports;
  viewports.minDepth = 0.0f;
  viewports.maxDepth = 1.0f;
  viewports.x = 0;
  viewports.y = 0;
  viewports.width = info.width;
  viewports.height = info.height;
  VkRect2D scissor;
  scissor.extent.width = info.width;
  scissor.extent.height = info.height;
  scissor.offset.x = 0;
  scissor.offset.y = 0;
  vp.viewportCount = NUM_VIEWPORTS;
  vp.scissorCount = NUM_SCISSORS;
  vp.pScissors = &scissor;
  vp.pViewports = &viewports;
{$endif}
  pipeline_info.sType := VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
  pipeline_info.pNext := nil;
  pipeline_info.layout := APipelineLayout.VkHandle;
  pipeline_info.basePipelineHandle := VK_NULL_HANDLE;
  pipeline_info.basePipelineIndex := 0;
  pipeline_info.flags := 0;
  pipeline_info.pVertexInputState := @AVertexInputState.CreateInfo;
  pipeline_info.pInputAssemblyState := @AInputAssemblyState;
  pipeline_info.pRasterizationState := @ARasterizationState;
  pipeline_info.pColorBlendState := @AColorBlendState;
  pipeline_info.pTessellationState := nil;
  pipeline_info.pMultisampleState := @AMultisampleState;
  pipeline_info.pDynamicState := @dynamic_state_info;
  pipeline_info.pViewportState := @AViewportState;
  pipeline_info.pDepthStencilState := @ADepthStencilState;
  pipeline_info.pStages := @AShaderStages[0];
  pipeline_info.stageCount := Length(AShaderStages);
  pipeline_info.renderPass := ARenderPass.VkHandle;
  pipeline_info.subpass := ASubpass;
  LabAssertVkError(Vulkan.CreateGraphicsPipelines(_Device.Ptr.VkHandle, _Cache.Ptr.VkHandle, 1, @pipeline_info, nil, @_Handle));
end;

destructor TLabGraphicsPipeline.Destroy;
begin
  inherited Destroy;
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

function LabPipelineViewportState(
  const ViewportCount: TVkUInt32;
  const Viewports: PVkViewport;
  const ScissorCount: TVkUInt32;
  const Scissors: PVkRect2D;
  const Flags: TVkPipelineViewportStateCreateFlags
): TVkPipelineViewportStateCreateInfo;
begin
  Result.sType := VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
  Result.pNext := nil;
  Result.flags := Flags;
  Result.viewportCount := ViewportCount;
  Result.pViewports := Viewports;
  Result.scissorCount := ScissorCount;
  Result.pScissors := Scissors;
end;

function LabPipelineInputAssemblyState(
  const Topology: TVkPrimitiveTopology;
  const PrimitiveRestartEnable: TVkBool32;
  const Flags: TVkPipelineInputAssemblyStateCreateFlags
): TVkPipelineInputAssemblyStateCreateInfo;
begin
  Result.sType := VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
  Result.pNext := nil;
  Result.flags := Flags;
  Result.primitiveRestartEnable := PrimitiveRestartEnable;
  Result.topology := Topology;
end;

function LabPipelineVertexInputState(
  const VertexBindingDescriptions: array of TVkVertexInputBindingDescription;
  const VertexAttributeDescriptions: array of TVkVertexInputAttributeDescription;
  const Flags: TVkPipelineVertexInputStateCreateFlags
): TLabPipelineVertexInputState;
begin
  SetLength(Result.Data.InputBindings, Length(VertexBindingDescriptions));
  Move(VertexBindingDescriptions[0], Result.Data.InputBindings[0], SizeOf(TVkVertexInputBindingDescription) * Length(VertexBindingDescriptions));
  SetLength(Result.Data.Attributes, Length(VertexAttributeDescriptions));
  Move(VertexAttributeDescriptions[0], Result.Data.Attributes[0], SizeOf(TVkVertexInputAttributeDescription) * Length(VertexAttributeDescriptions));
  Result.CreateInfo.sType := VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
  Result.CreateInfo.pNext := nil;
  Result.CreateInfo.flags := Flags;
  Result.CreateInfo.vertexBindingDescriptionCount := Length(Result.Data.InputBindings);
  Result.CreateInfo.pVertexBindingDescriptions := @Result.Data.InputBindings[0];
  Result.CreateInfo.vertexAttributeDescriptionCount := Length(Result.Data.Attributes);
  Result.CreateInfo.pVertexAttributeDescriptions := @Result.Data.Attributes[0];
end;

function LabPipelineRasterizationState(
  const DepthClampEnable: TVkBool32;
  const RasterizerDiscardEnable: TVkBool32;
  const PolygonMode: TVkPolygonMode;
  const CullMode: TVkCullModeFlags;
  const FrontFace: TVkFrontFace;
  const DepthBiasEnable: TVkBool32;
  const DepthBiasConstantFactor: TVkFloat;
  const DepthBiasClamp: TVkFloat;
  const DepthBiasSlopeFactor: TVkFloat;
  const LineWidth: TVkFloat;
  const Flags: TVkPipelineRasterizationStateCreateFlags
): TVkPipelineRasterizationStateCreateInfo;
begin
  Result.sType := VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
  Result.pNext := nil;
  Result.flags := Flags;
  Result.depthClampEnable := DepthClampEnable;
  Result.rasterizerDiscardEnable := RasterizerDiscardEnable;
  Result.polygonMode := PolygonMode;
  Result.cullMode := CullMode;
  Result.frontFace := FrontFace;
  Result.depthBiasEnable := DepthBiasEnable;
  Result.depthBiasConstantFactor := DepthBiasConstantFactor;
  Result.depthBiasClamp := DepthBiasClamp;
  Result.depthBiasSlopeFactor := DepthBiasSlopeFactor;
  Result.lineWidth := LineWidth;
end;

function LabPipelineDepthStencilState(
  const Front: TVkStencilOpState;
  const Back: TVkStencilOpState;
  const DepthTestEnable: TVkBool32;
  const DepthWriteEnable: TVkBool32;
  const DepthCompareOp: TVkCompareOp;
  const DepthBoundsTestEnable: TVkBool32;
  const StencilTestEnable: TVkBool32;
  const MinDepthBounds: TVkFloat;
  const MaxDepthBounds: TVkFloat;
  const Flags: TVkPipelineDepthStencilStateCreateFlags
): TVkPipelineDepthStencilStateCreateInfo;
begin
  Result.sType := VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
  Result.pNext := nil;
  Result.flags := Flags;
  Result.depthTestEnable := DepthTestEnable;
  Result.depthWriteEnable := DepthWriteEnable;
  Result.depthCompareOp := DepthCompareOp;
  Result.depthBoundsTestEnable := DepthBoundsTestEnable;
  Result.stencilTestEnable := StencilTestEnable;
  Result.front := Front;
  Result.back := Back;
  Result.minDepthBounds := MinDepthBounds;
  Result.maxDepthBounds := MaxDepthBounds;
end;

function LabPipelineMultisampleState(
  const RasterizationSamples: TVkSampleCountFlagBits;
  const SampleShadingEnable: TVkBool32;
  const MinSampleShading: TVkFloat;
  const SampleMask: PVkSampleMask;
  const AlphaToCoverageEnable: TVkBool32;
  const AlphaToOneEnable: TVkBool32;
  const Flags: TVkPipelineMultisampleStateCreateFlags
): TVkPipelineMultisampleStateCreateInfo;
begin
  Result.sType := VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
  Result.pNext := nil;
  Result.flags := Flags;
  Result.rasterizationSamples := RasterizationSamples;
  Result.sampleShadingEnable := SampleShadingEnable;
  Result.minSampleShading := MinSampleShading;
  Result.pSampleMask := SampleMask;
  Result.alphaToCoverageEnable := AlphaToCoverageEnable;
  Result.alphaToOneEnable := AlphaToOneEnable;
end;

function LabPipelineColorBlendState(
  const AttachmentCount: TVkUInt32;
  const Attachments: PVkPipelineColorBlendAttachmentState;
  const BlendConstants: array of TVkFloat;
  const LogicOpEnable: TVkBool32;
  const LogicOp: TVkLogicOp;
  const Flags: TVkPipelineColorBlendStateCreateFlags
): TVkPipelineColorBlendStateCreateInfo;
  var i: Integer;
begin
  Result.sType := VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
  Result.pNext := nil;
  Result.flags := Flags;
  Result.logicOpEnable := LogicOpEnable;
  Result.logicOp := LogicOp;
  Result.attachmentCount := AttachmentCount;
  Result.pAttachments := Attachments;
  for i := 0 to High(Result.blendConstants) do
  if i < Length(BlendConstants) then Result.blendConstants[i] := BlendConstants[i] else Result.blendConstants[i] := 1;
end;

end.
