unit LabApplication;

interface

uses
  Vulkan,
  SysUtils,
  LabTypes,
  LabUtils,
  LabWindow,
  LabSwapChain,
  LabPhysicalDevice,
  LabDevice,
  LabCommandPool,
  LabCommandBuffer,
  LabThread,
  LabRenderer,
  LabSync,
  LabDepthBuffer,
  LabUniformBuffer,
  LabShader,
  LabFrameBuffer,
  LabVertexBuffer,
  LabMath,
  data;

type
  TLabApplication = class (TLabClass)
  private
    var _Renderer: TLabRenderer;
    var _Window: TLabWindow;
    var _Device: TLabDeviceShared;
    var _CommandPool: TLabCommandPoolShared;
    var _CommandBuffer: TLabCommandBufferShared;
    var _SwapChain: TLabSwapChainShared;
    var _DepthBuffer: TLabDepthBufferShared;
    var _UniformBuffer: TLabUniformBufferShared;
    var _VertexBuffer: TLabVertexBufferShared;
    var _VertexShader: TLabShaderShared;
    var _PixelShader: TLabShaderShared;
    var _UpdateThread: TLabThread;
    var _Active: Boolean;
    var _DescSetLayout: TVkDescriptorSetLayout;
    var _DescSet: array [0..0] of TVkDescriptorSet;
    var _PipelineLayout: TVkPipelineLayout;
    var _DescPool: TVkDescriptorPool;
    var _ImageAcquiredSemaphore: TLabSemaphoreShared;
    var _RenderPass: TVkRenderPass;
    var _ClearValues: array [0..1] of TVkClearValue;
    var _FrameBuffers: array[0..1] of TLabFrameBufferShared;
    var _CurrentBuffer: TLabUInt32;
    var _ShaderStages: array[0..1] of TVkPipelineShaderStageCreateInfo;
    var _Pipeline: TVkPipeline;
    procedure OnWindowClose(Wnd: TLabWindow);
    procedure Update;
    procedure Stop;
    procedure PipelineLayoutSetup;
    procedure PipelineLayoutWrapup;
    procedure DescriptorSetSetup;
    procedure DescriptorSetWrapup;
    procedure PipelineSetup;
    procedure PipelineWrapup;
    procedure RenderPassSetup;
    procedure RenderPassWrapup;
    procedure RenderPassBegin;
    procedure RenderPassEnd;
    procedure DrawFrame;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Run;
  end;
  TLabApplicationShared = specialize TLabSharedRef<TLabApplication>;

const NUM_VIEWPORTS = 1;
const NUM_SAMPLES = VK_SAMPLE_COUNT_1_BIT;

implementation

procedure TLabApplication.OnWindowClose(Wnd: TLabWindow);
begin
  if Wnd = _Window then Stop;
end;

procedure TLabApplication.Update;
begin
  while _Active do
  begin
    //Logical update thread
  end;
end;

procedure TLabApplication.Stop;
begin
  _Active := False;
end;

procedure TLabApplication.PipelineLayoutSetup;
  var layout_binding: TVkDescriptorSetLayoutBinding;
  var desc_set_info: TVkDescriptorSetLayoutCreateInfo;
  var pipeline_info: TVkPipelineLayoutCreateInfo;
begin
  LabLog('PipelineLayout setup BEGIN');
  LabZeroMem(@layout_binding, SizeOf(TVkDescriptorSetLayoutBinding));
  layout_binding.binding := 0;
  layout_binding.descriptorType := VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
  layout_binding.descriptorCount := 1;
  layout_binding.stageFlags := TVkFlags(VK_SHADER_STAGE_VERTEX_BIT);
  layout_binding.pImmutableSamplers := nil;

  LabZeroMem(@desc_set_info, SizeOf(TVkDescriptorSetLayoutCreateInfo));
  desc_set_info.sType := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
  desc_set_info.bindingCount := 1;
  desc_set_info.pBindings := @layout_binding;

  LabAssertVkError(Vulkan.CreateDescriptorSetLayout(_Device.Ptr.VkHandle, @desc_set_info, nil, @_DescSetLayout));

  LabZeroMem(@pipeline_info, SizeOf(TVkPipelineLayoutCreateInfo));
  pipeline_info.sType := VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
  pipeline_info.pushConstantRangeCount := 0;
  pipeline_info.pPushConstantRanges := nil;
  pipeline_info.setLayoutCount := 1;
  pipeline_info.pSetLayouts := @_DescSetLayout;
  LabAssertVkError(Vulkan.CreatePipelineLayout(_Device.Ptr.VkHandle, @pipeline_info, nil, @_PipelineLayout));
  LabLog('PipelineLayout setup END');
end;

procedure TLabApplication.PipelineLayoutWrapup;
begin
  LabLog('PipelineLayout wrapup BEGIN');
  Vulkan.DestroyDescriptorSetLayout(_Device.Ptr.VkHandle, _DescSetLayout, nil);
  Vulkan.DestroyPipelineLayout(_Device.Ptr.VkHandle, _PipelineLayout, nil);
  LabLog('PipelineLayout wrapup END');
end;

procedure TLabApplication.DescriptorSetSetup;
  var desc_pool_size: array[0..0] of TVkDescriptorPoolSize;
  var desc_pool_info: TVkDescriptorPoolCreateInfo;
  var desc_set_alloc_info: array[0..0] of TVkDescriptorSetAllocateInfo;
  var write_desc_set: array[0..0] of TVkWriteDescriptorSet;
begin
  LabLog('DescriptorSet setup BEGIN');
  desc_pool_size[0].type_ := VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
  desc_pool_size[0].descriptorCount := 1;

  LabZeroMem(@desc_pool_info, SizeOf(TVkDescriptorPoolCreateInfo));
  desc_pool_info.sType := VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
  desc_pool_info.maxSets := 1;
  desc_pool_info.poolSizeCount := 1;
  desc_pool_info.pPoolSizes := @desc_pool_size[0];
  LabAssertVkError(Vulkan.CreateDescriptorPool(_Device.Ptr.VkHandle, @desc_pool_info, nil, @_DescPool));

  LabZeroMem(@desc_set_alloc_info[0], SizeOf(TVkDescriptorSetAllocateInfo));
  desc_set_alloc_info[0].sType := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
  desc_set_alloc_info[0].descriptorPool := _DescPool;
  desc_set_alloc_info[0].descriptorSetCount := 1;
  desc_set_alloc_info[0].pSetLayouts := @_DescSetLayout;

  LabAssertVkError(Vulkan.AllocateDescriptorSets(_Device.Ptr.VkHandle, @desc_set_alloc_info[0], @_DescSet[0]));

  LabZeroMem(@write_desc_set[0], SizeOf(TVkWriteDescriptorSet));
  write_desc_set[0].sType := VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
  write_desc_set[0].pNext := nil;
  write_desc_set[0].dstSet := _DescSet[0];
  write_desc_set[0].descriptorCount := 1;
  write_desc_set[0].descriptorType := VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
  write_desc_set[0].pBufferInfo := _UniformBuffer.Ptr.BufferInfo;
  write_desc_set[0].dstArrayElement := 0;
  write_desc_set[0].dstBinding := 0;
  Vulkan.UpdateDescriptorSets(_Device.Ptr.VkHandle, 1, @write_desc_set[0], 0, nil);
  LabLog('DescriptorSet setup END');
end;

procedure TLabApplication.DescriptorSetWrapup;
begin
  LabLog('DescriptorSet wrapup BEGIN');
  Vulkan.DestroyDescriptorPool(_Device.Ptr.VkHandle, _DescPool, nil);
  LabLog('DescriptorSet wrapup END');
end;

procedure TLabApplication.PipelineSetup;
  var dynamic_state_enables: array [0..TVkInt16(High(TVkDynamicState))] of TVkDynamicState;
  var dynamic_state_info: TVkPipelineDynamicStateCreateInfo;
  var vertex_input_state_info: TVkPipelineVertexInputStateCreateInfo;
  var input_assembly_state_info: TVkPipelineInputAssemblyStateCreateInfo;
  var rasterization_state_info: TVkPipelineRasterizationStateCreateInfo;
  var color_blend_state_info: TVkPipelineColorBlendStateCreateInfo;
  var color_blend_attachments: array[0..0] of TVkPipelineColorBlendAttachmentState;
  var viewport_state_info: TVkPipelineViewportStateCreateInfo;
  var depth_stencil_state_info: TVkPipelineDepthStencilStateCreateInfo;
  var multisample_state_info: TVkPipelineMultisampleStateCreateInfo;
  var pipeline_info: TVkGraphicsPipelineCreateInfo;
begin
  LabLog('Pipeline setup BEGIN');
  LabZeroMem(@dynamic_state_enables, SizeOf(dynamic_state_enables));
  LabZeroMem(@dynamic_state_info, SizeOf(dynamic_state_info));
  dynamic_state_info.sType := VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
  dynamic_state_info.pDynamicStates := @dynamic_state_enables;
  dynamic_state_info.dynamicStateCount := 0;

  LabZeroMem(@vertex_input_state_info, SizeOf(vertex_input_state_info));
  vertex_input_state_info.sType := VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
  vertex_input_state_info.flags := 0;
  vertex_input_state_info.vertexBindingDescriptionCount := 1;
  vertex_input_state_info.pVertexBindingDescriptions := _VertexBuffer.Ptr.Binding;
  vertex_input_state_info.vertexAttributeDescriptionCount := _VertexBuffer.Ptr.AttributeCount;
  vertex_input_state_info.pVertexAttributeDescriptions := _VertexBuffer.Ptr.Attribute[0];

  LabZeroMem(@input_assembly_state_info, SizeOf(input_assembly_state_info));
  input_assembly_state_info.sType := VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
  input_assembly_state_info.flags := 0;
  input_assembly_state_info.primitiveRestartEnable := VK_FALSE;
  input_assembly_state_info.topology := VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;

  LabZeroMem(@rasterization_state_info, SizeOf(rasterization_state_info));
  rasterization_state_info.sType := VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
  rasterization_state_info.flags := 0;
  rasterization_state_info.polygonMode := VK_POLYGON_MODE_FILL;
  rasterization_state_info.cullMode := TVkFlags(VK_CULL_MODE_NONE);
  rasterization_state_info.frontFace := VK_FRONT_FACE_CLOCKWISE;
  rasterization_state_info.depthClampEnable := VK_FALSE;
  rasterization_state_info.rasterizerDiscardEnable := VK_FALSE;
  rasterization_state_info.depthBiasEnable := VK_FALSE;
  rasterization_state_info.depthBiasConstantFactor := 0;
  rasterization_state_info.depthBiasClamp := 0;
  rasterization_state_info.depthBiasSlopeFactor := 0;
  rasterization_state_info.lineWidth := 1.0;

  LabZeroMem(@color_blend_state_info, SizeOf(color_blend_state_info));
  color_blend_state_info.sType := VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
  color_blend_state_info.flags := 0;
  LabZeroMem(@color_blend_attachments, SizeOf(color_blend_attachments));
  color_blend_attachments[0].colorWriteMask := $f;
  color_blend_attachments[0].blendEnable := VK_FALSE;
  color_blend_attachments[0].alphaBlendOp := VK_BLEND_OP_ADD;
  color_blend_attachments[0].colorBlendOp := VK_BLEND_OP_ADD;
  color_blend_attachments[0].srcColorBlendFactor := VK_BLEND_FACTOR_ZERO;
  color_blend_attachments[0].dstColorBlendFactor := VK_BLEND_FACTOR_ZERO;
  color_blend_attachments[0].srcAlphaBlendFactor := VK_BLEND_FACTOR_ZERO;
  color_blend_attachments[0].dstAlphaBlendFactor := VK_BLEND_FACTOR_ZERO;
  color_blend_state_info.attachmentCount := 1;
  color_blend_state_info.pAttachments := @color_blend_attachments;
  color_blend_state_info.logicOpEnable := VK_FALSE;
  color_blend_state_info.logicOp := VK_LOGIC_OP_NO_OP;
  color_blend_state_info.blendConstants[0] := 1.0;
  color_blend_state_info.blendConstants[1] := 1.0;
  color_blend_state_info.blendConstants[2] := 1.0;
  color_blend_state_info.blendConstants[3] := 1.0;

  LabZeroMem(@viewport_state_info, SizeOf(viewport_state_info));
  viewport_state_info.sType := VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
  viewport_state_info.flags := 0;
  viewport_state_info.viewportCount := NUM_VIEWPORTS;
  dynamic_state_enables[dynamic_state_info.dynamicStateCount] := VK_DYNAMIC_STATE_VIEWPORT;
  Inc(dynamic_state_info.dynamicStateCount);
  viewport_state_info.scissorCount := NUM_VIEWPORTS;
  dynamic_state_enables[dynamic_state_info.dynamicStateCount] := VK_DYNAMIC_STATE_SCISSOR;
  Inc(dynamic_state_info.dynamicStateCount);
  viewport_state_info.pScissors := nil;
  viewport_state_info.pViewports := nil;

  LabZeroMem(@depth_stencil_state_info, SizeOf(depth_stencil_state_info));
  depth_stencil_state_info.sType := VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
  depth_stencil_state_info.flags := 0;
  depth_stencil_state_info.depthTestEnable := VK_TRUE;
  depth_stencil_state_info.depthWriteEnable := VK_TRUE;
  depth_stencil_state_info.depthCompareOp := VK_COMPARE_OP_LESS_OR_EQUAL;
  depth_stencil_state_info.depthBoundsTestEnable := VK_FALSE;
  depth_stencil_state_info.minDepthBounds := 0;
  depth_stencil_state_info.maxDepthBounds := 0;
  depth_stencil_state_info.stencilTestEnable := VK_FALSE;
  depth_stencil_state_info.back.failOp := VK_STENCIL_OP_KEEP;
  depth_stencil_state_info.back.passOp := VK_STENCIL_OP_KEEP;
  depth_stencil_state_info.back.compareOp := VK_COMPARE_OP_ALWAYS;
  depth_stencil_state_info.back.compareMask := 0;
  depth_stencil_state_info.back.reference := 0;
  depth_stencil_state_info.back.depthFailOp := VK_STENCIL_OP_KEEP;
  depth_stencil_state_info.back.writeMask := 0;
  depth_stencil_state_info.front := depth_stencil_state_info.back;

  LabZeroMem(@multisample_state_info, SizeOf(multisample_state_info));
  multisample_state_info.sType := VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
  multisample_state_info.flags := 0;
  multisample_state_info.pSampleMask := nil;
  multisample_state_info.rasterizationSamples := NUM_SAMPLES;
  multisample_state_info.sampleShadingEnable := VK_FALSE;
  multisample_state_info.alphaToCoverageEnable := VK_FALSE;
  multisample_state_info.alphaToOneEnable := VK_FALSE;
  multisample_state_info.minSampleShading := 0.0;

  LabZeroMem(@pipeline_info, SizeOf(pipeline_info));
  pipeline_info.sType := VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
  pipeline_info.layout := _PipelineLayout;
  pipeline_info.basePipelineHandle := VK_NULL_HANDLE;
  pipeline_info.basePipelineIndex := 0;
  pipeline_info.flags := 0;
  pipeline_info.pVertexInputState := @vertex_input_state_info;
  pipeline_info.pInputAssemblyState := @input_assembly_state_info;
  pipeline_info.pRasterizationState := @rasterization_state_info;
  pipeline_info.pColorBlendState := @color_blend_state_info;
  pipeline_info.pTessellationState := nil;
  pipeline_info.pMultisampleState := @multisample_state_info;
  pipeline_info.pDynamicState := @dynamic_state_info;
  pipeline_info.pViewportState := @viewport_state_info;
  pipeline_info.pDepthStencilState := @depth_stencil_state_info;
  pipeline_info.pStages := @_ShaderStages;
  pipeline_info.stageCount := 2;
  pipeline_info.renderPass := _RenderPass;
  pipeline_info.subpass := 0;
  Vulkan.CreateGraphicsPipelines(_Device.Ptr.VkHandle, VK_NULL_HANDLE, 1, @pipeline_info, nil, @_Pipeline);
  LabLog('Pipeline setup END');
end;

procedure TLabApplication.PipelineWrapup;
begin
  LabLog('Pipeline wrapup BEGIN');
  Vulkan.DestroyPipeline(_Device.Ptr.VkHandle, _Pipeline, nil);
  LabLog('Pipeline wrapup END');
end;

procedure TLabApplication.RenderPassSetup;
  var attachments: array[0..1] of TVkAttachmentDescription;
  var color_reference: TVkAttachmentReference;
  var depth_reference: TVkAttachmentReference;
  var subpass: TVkSubpassDescription;
  var render_pass_info: TVkRenderPassCreateInfo;
begin
  LabLog('RenderPass setup BEGIN');

  _ImageAcquiredSemaphore := TLabSemaphore.Create(_Device);

  LabZeroMem(@attachments, SizeOf(attachments));
  attachments[0].format := _SwapChain.Ptr.Format;
  attachments[0].samples := VK_SAMPLE_COUNT_1_BIT;
  attachments[0].loadOp := VK_ATTACHMENT_LOAD_OP_CLEAR;
  attachments[0].storeOp := VK_ATTACHMENT_STORE_OP_STORE;
  attachments[0].stencilLoadOp := VK_ATTACHMENT_LOAD_OP_DONT_CARE;
  attachments[0].stencilStoreOp := VK_ATTACHMENT_STORE_OP_DONT_CARE;
  attachments[0].initialLayout := VK_IMAGE_LAYOUT_UNDEFINED;
  attachments[0].finalLayout := VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
  attachments[0].flags := 0;

  attachments[1].format := _DepthBuffer.Ptr.Format;
  attachments[1].samples := VK_SAMPLE_COUNT_1_BIT;
  attachments[1].loadOp := VK_ATTACHMENT_LOAD_OP_CLEAR;
  attachments[1].storeOp := VK_ATTACHMENT_STORE_OP_DONT_CARE;
  attachments[1].stencilLoadOp := VK_ATTACHMENT_LOAD_OP_DONT_CARE;
  attachments[1].stencilStoreOp := VK_ATTACHMENT_STORE_OP_DONT_CARE;
  attachments[1].initialLayout := VK_IMAGE_LAYOUT_UNDEFINED;
  attachments[1].finalLayout := VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
  attachments[1].flags := 0;

  LabZeroMem(@color_reference, SizeOf(color_reference));
  color_reference.attachment := 0;
  color_reference.layout := VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

  LabZeroMem(@depth_reference, SizeOf(depth_reference));
  depth_reference.attachment := 1;
  depth_reference.layout := VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

  LabZeroMem(@subpass, SizeOf(subpass));
  subpass.pipelineBindPoint := VK_PIPELINE_BIND_POINT_GRAPHICS;
  subpass.flags := 0;
  subpass.inputAttachmentCount := 0;
  subpass.pInputAttachments := nil;
  subpass.colorAttachmentCount := 1;
  subpass.pColorAttachments := @color_reference;
  subpass.pResolveAttachments := nil;
  subpass.pDepthStencilAttachment := @depth_reference;
  subpass.preserveAttachmentCount := 0;
  subpass.pPreserveAttachments := nil;

  LabZeroMem(@render_pass_info, SizeOf(render_pass_info));
  render_pass_info.sType := VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
  render_pass_info.pNext := nil;
  render_pass_info.attachmentCount := 2;
  render_pass_info.pAttachments := @attachments[0];
  render_pass_info.subpassCount := 1;
  render_pass_info.pSubpasses := @subpass;
  render_pass_info.dependencyCount := 0;
  render_pass_info.pDependencies := nil;

  LabAssertVkError(Vulkan.CreateRenderPass(_Device.Ptr.VkHandle, @render_pass_info, nil, @_RenderPass));

  LabLog('RenderPass setup END');
end;

procedure TLabApplication.RenderPassWrapup;
begin
  LabLog('RenderPass wrapup BEGIN');
  Vulkan.DestroyRenderPass(_Device.Ptr.VkHandle, _RenderPass, nil);
  _ImageAcquiredSemaphore := nil;
  LabLog('RenderPass wrapup END');
end;

procedure TLabApplication.RenderPassBegin;
  var rpb_info: TVkRenderPassBeginInfo;
  var viewport: TVkViewport;
  var scissor: TVkRect2D;
  const offsets: array[0..0] of TVkDeviceSize = (0);
begin
  LabLog('RenderPass begin BEGIN');
  _ClearValues[0].color.float32[0] := 0.2;
  _ClearValues[0].color.float32[1] := 0.2;
  _ClearValues[0].color.float32[2] := 0.2;
  _ClearValues[0].color.float32[3] := 1.0;
  _ClearValues[1].depthStencil.depth := 1;
  _ClearValues[1].depthStencil.stencil := 0;
  LabZeroMem(@rpb_info, SizeOf(rpb_info));
  rpb_info.sType := VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
  rpb_info.renderPass := _RenderPass;
  rpb_info.framebuffer := _FrameBuffers[_CurrentBuffer].Ptr.VkHandle;
  rpb_info.renderArea.offset.x := 0;
  rpb_info.renderArea.offset.y := 0;
  rpb_info.renderArea.extent.width := _SwapChain.Ptr.Width;
  rpb_info.renderArea.extent.height := _SwapChain.Ptr.Height;
  rpb_info.clearValueCount := 2;
  rpb_info.pClearValues := @_ClearValues[0];
  Vulkan.CmdBeginRenderPass(_CommandBuffer.Ptr.VkHandle, @rpb_info, VK_SUBPASS_CONTENTS_INLINE);
  Vulkan.CmdBindPipeline(_CommandBuffer.Ptr.VkHandle, VK_PIPELINE_BIND_POINT_GRAPHICS, _Pipeline);
  offsets[0] := 0;
  Vulkan.CmdBindVertexBuffers(_CommandBuffer.Ptr.VkHandle, 0, 1, @_VertexBuffer.Ptr.VkHandle, @offsets);
  LabZeroMem(@viewport, SizeOf(viewport));
  viewport.width := _SwapChain.Ptr.Width;
  viewport.height := _SwapChain.Ptr.Height;
  viewport.minDepth := 0.0;
  viewport.maxDepth := 1.0;
  viewport.x := 0;
  viewport.y := 0;
  Vulkan.CmdSetViewport(_CommandBuffer.Ptr.VkHandle, 0, 1, @viewport);
  LabZeroMem(@scissor, SizeOf(scissor));
  scissor.extent.width := _SwapChain.Ptr.Width;
  scissor.extent.height := _SwapChain.Ptr.Height;
  scissor.offset.x := 0;
  scissor.offset.y := 0;
  Vulkan.CmdSetScissor(_CommandBuffer.Ptr.VkHandle, 0, 1, @scissor);
  LabLog('RenderPass begin END');
end;

procedure TLabApplication.RenderPassEnd;
begin
  LabLog('RenderPass end BEGIN');
  Vulkan.CmdEndRenderPass(_CommandBuffer.Ptr.VkHandle);
  LabLog('RenderPass end END');
end;

procedure TLabApplication.DrawFrame;
  var present_info: TVkPresentInfoKHR;
begin
  LabLog('DrawFrame BEGIN');
  _CurrentBuffer := _SwapChain.Ptr.AcquireNextImage(_ImageAcquiredSemaphore);
  _CommandBuffer.Ptr.RecordBegin;
  RenderPassBegin;
  Vulkan.CmdDraw(_CommandBuffer.Ptr.VkHandle, 12 * 3, 1, 0, 0);
  RenderPassEnd;
  _CommandBuffer.Ptr.RecordEnd;
  _CommandBuffer.Ptr.QueueSubmit(_Device.Ptr.GetQueue(_SwapChain.Ptr.QueueFamilyGraphics, 0));
  LabZeroMem(@present_info, SizeOf(present_info));
  present_info.sType := VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
  present_info.swapchainCount := 1;
  present_info.pSwapchains := @_SwapChain.Ptr.VkHandle;
  present_info.pImageIndices := @_CurrentBuffer;
  present_info.pWaitSemaphores := nil;
  present_info.waitSemaphoreCount := 0;
  present_info.pResults := nil;
  Vulkan.QueuePresentKHR(_Device.Ptr.GetQueue(_SwapChain.Ptr.QueueFamilyPresent, 0), @present_info);
  LabLog('DrawFrame END');
end;

constructor TLabApplication.Create;
  var WVP, W, V, P, C: TLabMat;
  var UniformBuffer, VertexBuffer: PVkVoid;
  var i: TVkInt32;
begin
  LabLog('TLabApplication.Create BEGIN');
  LabProfileStart('App');
  LabLog('CPU Count = ' + IntToStr(System.CPUCount));
  LabLog('TLabApplication.Create', 2);
  inherited Create;
  _Active := False;
  //TLabRenderer.EnableLayer('VK_LAYER_LUNARG_api_dump');
  TLabRenderer.EnableLayer('VK_LAYER_LUNARG_core_validation');
  TLabRenderer.EnableLayer('VK_LAYER_LUNARG_parameter_validation');
  TLabRenderer.EnableLayer('VK_LAYER_LUNARG_image');
  TLabRenderer.EnableLayer('VK_LAYER_LUNARG_monitor');
  TLabRenderer.EnableLayer('VK_LAYER_LUNARG_object_tracker');
  TLabRenderer.EnableLayer('VK_LAYER_LUNARG_swapchain');
  _Renderer := TLabRenderer.Create();
  _Window := TLabWindow.Create;
  _Window.OnClose := @OnWindowClose;
  _Device := TLabDevice.Create(
    _Renderer.PhysicalDevices[0],
    [
      LabQueueFamilyRequest(_Renderer.PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT))),
      LabQueueFamilyRequest(_Renderer.PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_COMPUTE_BIT)))
    ],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  _CommandPool := TLabCommandPool.Create(_Device, _Device.Ptr.PhysicalDevice.Ptr.GetQueueFamiliyIndex(TVkQueueFlags(VK_QUEUE_GRAPHICS_BIT)));
  _CommandBuffer := TLabCommandBuffer.Create(_CommandPool);
  _SwapChain := TLabSwapChain.Create(_Window, _Device);
  _DepthBuffer := TLabDepthBuffer.Create(_Device, _SwapChain.Ptr.Width, _SwapChain.Ptr.Height);
  P := LabMatProj(45 * LabDegToRad, 1, 0.1, 100);
  V := LabMatView(LabVec3(-5, 3, -10), LabVec3(0, 0, 0), LabVec3(0, -1, 0));
  W := LabMatIdentity;
  C := LabMat(
    1.0,  0.0, 0.0, 0.0,
    0.0, -1.0, 0.0, 0.0,
    0.0,  0.0, 0.5, 0.0,
    0.0,  0.0, 0.5, 1.0
  );
  WVP := W * V * P * C;
  WVP := LabMatIdentity;
  _UniformBuffer := TLabUniformBuffer.Create(_Device, SizeOf(WVP));
  if _UniformBuffer.Ptr.Map(UniformBuffer) then
  begin
    PLabMat(UniformBuffer)^ := WVP;
    _UniformBuffer.Ptr.Unmap;
  end;
  PipelineLayoutSetup;
  DescriptorSetSetup;
  RenderPassSetup;
  _VertexShader := TLabShader.Create(_Device, 'vs.spv');
  _PixelShader := TLabShader.Create(_Device, 'ps.spv');
  LabZeroMem(@_ShaderStages, SizeOf(_ShaderStages));
  _ShaderStages[0].sType := VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  _ShaderStages[0].pSpecializationInfo := nil;
  _ShaderStages[0].flags := 0;
  _ShaderStages[0].stage := VK_SHADER_STAGE_VERTEX_BIT;
  _ShaderStages[0].pName := 'main';
  _ShaderStages[0].module := _VertexShader.Ptr.VkHandle;
  _ShaderStages[1].sType := VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  _ShaderStages[1].pSpecializationInfo := nil;
  _ShaderStages[1].flags := 0;
  _ShaderStages[1].stage := VK_SHADER_STAGE_FRAGMENT_BIT;
  _ShaderStages[1].pName := 'main';
  _ShaderStages[1].module := _PixelShader.Ptr.VkHandle;
  LabLog('SwapChain.ImageCount = ' + IntToStr(_SwapChain.Ptr.ImageCount));
  for i := 0 to High(_FrameBuffers) do
  begin
    _FrameBuffers[i] := TLabFrameBuffer.Create(
      _Device, _SwapChain, _RenderPass,
      [_SwapChain.Ptr.Images[i]^.View, _DepthBuffer.Ptr.VkImageView]
    );
  end;
  _VertexBuffer := TLabVertexBuffer.Create(_Device, SizeOf(vb_solid_face_colors_data));
  if _VertexBuffer.Ptr.Map(VertexBuffer) then
  begin
    Move(vb_solid_face_colors_data, VertexBuffer^, _VertexBuffer.Ptr.Size);
    _VertexBuffer.Ptr.Unmap;
  end;
  _VertexBuffer.Ptr.Binding^.binding := 0;
  _VertexBuffer.Ptr.Binding^.stride := SizeOf(vb_solid_face_colors_data[0]);
  _VertexBuffer.Ptr.AttributeCount := 2;
  _VertexBuffer.Ptr.Attribute[0]^.binding := 0;
  _VertexBuffer.Ptr.Attribute[0]^.location := 0;
  _VertexBuffer.Ptr.Attribute[0]^.format := VK_FORMAT_R32G32B32A32_SFLOAT;
  _VertexBuffer.Ptr.Attribute[0]^.offset := 0;
  _VertexBuffer.Ptr.Attribute[1]^.binding := 0;
  _VertexBuffer.Ptr.Attribute[1]^.location := 1;
  _VertexBuffer.Ptr.Attribute[1]^.format := VK_FORMAT_R32G32B32A32_SFLOAT;
  _VertexBuffer.Ptr.Attribute[1]^.offset := 16;
  PipelineSetup;
  _UpdateThread := TLabThread.Create;
  _UpdateThread.Proc := @Update;
  LabLog('TLabApplication.Create END');
end;

destructor TLabApplication.Destroy;
  var i: Integer;
begin
  LabLog('TLabApplication.Destroy BEGIN');
  PipelineWrapup;
  _VertexBuffer := nil;
  for i := 0 to High(_FrameBuffers) do _FrameBuffers[i] := nil;
  _UpdateThread.Free;
  _PixelShader := nil;
  _VertexShader := nil;
  RenderPassWrapup;
  DescriptorSetWrapup;
  PipelineLayoutWrapup;
  _UniformBuffer := nil;
  _DepthBuffer := nil;
  _SwapChain := nil;
  _CommandBuffer := nil;
  _CommandPool := nil;
  _Device := nil;
  _Window.Free;
  _Renderer.Free;
  inherited Destroy;
  LabLog('TLabApplication.Destroy', -2);
  LabProfileStop;
  LabLog('TLabApplication.Destroy END');
end;

procedure TLabApplication.Run;
begin
  _Active := True;
  _UpdateThread.Start;
  while _Active do
  begin
    //Gather, process window messages and sync other threads
    DrawFrame;
    Sleep(3000);
    Stop;
  end;
  _UpdateThread.WaitFor();
end;

end.
