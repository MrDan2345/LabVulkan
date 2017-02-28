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
  LabMath;

type
  TLabApplication = class (TLabClass)
  private
    var _Renderer: TLabRenderer;
    var _Window: TLabWindow;
    var _Device: TLabDeviceShared;
    var _SwapChain: TLabSwapChainShared;
    var _DepthBuffer: TLabDepthBufferShared;
    var _UniformBuffer: TLabUniformBufferShared;
    var _VertexShader: TLabShaderShared;
    var _PixelShader: TLabShaderShared;
    var _UpdateThread: TLabThread;
    var _Active: Boolean;
    var _DescSetLayout: TVkDescriptorSetLayout;
    var _DescSet: array [0..0] of TVkDescriptorSet;
    var _Pipeline: TVkPipelineLayout;
    var _DescPool: TVkDescriptorPool;
    var _CurrentBuffer: TLabUInt32;
    var _ImageAcquiredSemaphore: TVkSemaphore;
    var _RenderPass: TVkRenderPass;
    procedure OnWindowClose(Wnd: TLabWindow);
    procedure Update;
    procedure Stop;
    procedure PipelineSetup;
    procedure PipelineWrapup;
    procedure DescriptorSetSetup;
    procedure DescriptorSetWrapup;
    procedure RenderPassSetup;
    procedure RenderPassWrapup;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Run;
  end;
  TLabApplicationShared = specialize TLabSharedRef<TLabApplication>;

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

procedure TLabApplication.PipelineSetup;
  var layout_binding: TVkDescriptorSetLayoutBinding;
  var desc_set_info: TVkDescriptorSetLayoutCreateInfo;
  var pipeline_info: TVkPipelineLayoutCreateInfo;
begin
  LabLog('Pipeline setup BEGIN');
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

  LabAssetVkError(Vulkan.CreateDescriptorSetLayout(_Device.Ptr.VkHandle, @desc_set_info, nil, @_DescSetLayout));

  LabZeroMem(@pipeline_info, SizeOf(TVkPipelineLayoutCreateInfo));
  pipeline_info.sType := VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
  pipeline_info.pushConstantRangeCount := 0;
  pipeline_info.pPushConstantRanges := nil;
  pipeline_info.setLayoutCount := 1;
  pipeline_info.pSetLayouts := @_DescSetLayout;
  LabAssetVkError(Vulkan.CreatePipelineLayout(_Device.Ptr.VkHandle, @pipeline_info, nil, @_Pipeline));
  LabLog('Pipeline setup END');
end;

procedure TLabApplication.PipelineWrapup;
begin
  LabLog('Pipeline wrapup BEGIN');
  Vulkan.DestroyDescriptorSetLayout(_Device.Ptr.VkHandle, _DescSetLayout, nil);
  Vulkan.DestroyPipelineLayout(_Device.Ptr.VkHandle, _Pipeline, nil);
  LabLog('Pipeline wrapup END');
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
  LabAssetVkError(Vulkan.CreateDescriptorPool(_Device.Ptr.VkHandle, @desc_pool_info, nil, @_DescPool));

  LabZeroMem(@desc_set_alloc_info[0], SizeOf(TVkDescriptorSetAllocateInfo));
  desc_set_alloc_info[0].sType := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
  desc_set_alloc_info[0].descriptorPool := _DescPool;
  desc_set_alloc_info[0].descriptorSetCount := 1;
  desc_set_alloc_info[0].pSetLayouts := @_DescSetLayout;

  LabAssetVkError(Vulkan.AllocateDescriptorSets(_Device.Ptr.VkHandle, @desc_set_alloc_info[0], @_DescSet[0]));

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

procedure TLabApplication.RenderPassSetup;
  var image_acquired_semaphore_info: TVkSemaphoreCreateInfo;
  var attachments: array[0..1] of TVkAttachmentDescription;
  var color_reference: TVkAttachmentReference;
  var depth_reference: TVkAttachmentReference;
  var subpass: TVkSubpassDescription;
  var render_pass_info: TVkRenderPassCreateInfo;
begin
  LabLog('RenderPass setup BEGIN');
  LabZeroMem(@image_acquired_semaphore_info, SizeOf(TVkSemaphoreCreateInfo));
  image_acquired_semaphore_info.sType := VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
  image_acquired_semaphore_info.flags := 0;

  LabAssetVkError(Vulkan.CreateSemaphore(_Device.Ptr.VkHandle, @image_acquired_semaphore_info, nil, @_ImageAcquiredSemaphore));

  // Acquire the swapchain image in order to set its layout
  LabAssetVkError(Vulkan.AcquireNextImageKHR(_Device.Ptr.VkHandle, _SwapChain.Ptr.VkHandle, High(TLabUInt64), _ImageAcquiredSemaphore, VK_NULL_HANDLE, @_CurrentBuffer));

  // The initial layout for the color and depth attachments will be
  // LAYOUT_UNDEFINED because at the start of the renderpass, we don't
  // care about their contents. At the start of the subpass, the color
  // attachment's layout will be transitioned to LAYOUT_COLOR_ATTACHMENT_OPTIMAL
  // and the depth stencil attachment's layout will be transitioned to
  // LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL.  At the end of the renderpass,
  // the color attachment's layout will be transitioned to
  // LAYOUT_PRESENT_SRC_KHR to be ready to present.  This is all done as part
  // of the renderpass, no barriers are necessary.
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

  LabAssetVkError(Vulkan.CreateRenderPass(_Device.Ptr.VkHandle, @render_pass_info, nil, @_RenderPass));
  LabLog('RenderPass setup END');
end;

procedure TLabApplication.RenderPassWrapup;
begin
  LabLog('RenderPass wrapup BEGIN');
  Vulkan.DestroyRenderPass(_Device.Ptr.VkHandle, _RenderPass, nil);
  Vulkan.DestroySemaphore(_Device.Ptr.VkHandle, _ImageAcquiredSemaphore, nil);
  LabLog('RenderPass wrapup END');
end;

constructor TLabApplication.Create;
  var WVP, W, V, P, C: TLabMat;
  var UniformBuffer: PVkVoid;
begin
  LabProfileStart('App');
  LabLog('CPU Count = ' + IntToStr(System.CPUCount));
  LabLog('TLabApplication.Create', 2);
  inherited Create;
  _Active := False;
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
  _UniformBuffer := TLabUniformBuffer.Create(_Device, SizeOf(WVP));
  if _UniformBuffer.Ptr.Map(UniformBuffer) then
  begin
    PLabMat(UniformBuffer)^ := WVP;
    _UniformBuffer.Ptr.Unmap;
  end;
  PipelineSetup;
  DescriptorSetSetup;
  RenderPassSetup;
  _VertexShader := TLabShader.Create(_Device, 'vs.spv');
  _PixelShader := TLabShader.Create(_Device, 'ps.spv');
  _UpdateThread := TLabThread.Create;
  _UpdateThread.Proc := @Update;
end;

destructor TLabApplication.Destroy;
begin
  _UpdateThread.Free;
  _PixelShader := nil;
  _VertexShader := nil;
  RenderPassWrapup;
  DescriptorSetWrapup;
  PipelineWrapup;
  _UniformBuffer := nil;
  _DepthBuffer := nil;
  _SwapChain := nil;
  _Device := nil;
  _Window.Free;
  _Renderer.Free;
  inherited Destroy;
  LabLog('TLabApplication.Destroy', -2);
  LabProfileStop;
end;

procedure TLabApplication.Run;
begin
  _Active := True;
  _UpdateThread.Start;
  while _Active do
  begin
    //Gather, process window messages and sync other threads
  end;
  _UpdateThread.WaitFor();
end;

end.
