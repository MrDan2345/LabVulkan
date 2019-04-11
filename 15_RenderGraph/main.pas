unit main;

{$macro on}
{$include LabPlatform.inc}

interface

uses
  Vulkan,
  LabTypes,
  LabMath,
  LabWindow,
  LabSwapChain,
  LabVulkan,
  LabDevice,
  LabCommandPool,
  LabCommandBuffer,
  LabBuffer,
  LabImage,
  LabSurface,
  LabDescriptorSet,
  LabPipeline,
  LabRenderPass,
  LabShader,
  LabFrameBuffer,
  LabPlatform,
  LabSync,
  LabUtils,
  LabScene,
  LabColladaParser,
  LabRenderGraph,
  Classes,
  SysUtils;

type
  TLabApp = class (TLabVulkan)
  public
    var Window: TLabWindowShared;
    var Device: TLabDeviceShared;
    var Surface: TLabSurfaceShared;
    var SwapChain: TLabSwapChainShared;
    var CmdPool: TLabCommandPoolShared;
    var CmdBuffer: TLabCommandBufferShared;
    var Semaphore: TLabSemaphoreShared;
    var Fence: TLabFenceShared;
    var DepthBuffers: array of TLabDepthBufferShared;
    var FrameBuffers: array of TLabFrameBufferShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var RenderPass: TLabRenderPassShared;
    var Shaders: TLabShaderGroupShared;
    var DescriptorSetsFactory: TLabDescriptorSetsFactoryShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineCache: TLabPipelineCacheShared;
    var UniformGlobal: TLabManagedUniformBufferShared;
    var UniformView: TLabManagedUniformBufferShared;
    var UniformInst: TLabManagedUniformBufferShared;
    var UniformData: TLabManagedUniformBufferShared;
    var CombinedShader: TLabCombinedShaderShared;
    constructor Create;
    procedure SwapchainCreate;
    procedure SwapchainDestroy;
    procedure UpdateTransforms;
    procedure TransferBuffers;
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
  end;

const
  FENCE_TIMEOUT = 100000000;

  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

var
  App: TLabApp;

implementation

constructor TLabApp.Create;
begin
  //ReportFormats := True;
  //EnableLayerIfAvailable('VK_LAYER_LUNARG_api_dump');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_core_validation');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_parameter_validation');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_standard_validation');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_object_tracker');
  OnInitialize := @Initialize;
  OnFinalize := @Finalize;
  OnLoop := @Loop;
  inherited Create;
end;

procedure TLabApp.SwapchainCreate;
  var i: Integer;
begin
  SwapChain := TLabSwapChain.Create(Device, Surface);
  SetLength(DepthBuffers, SwapChain.Ptr.ImageCount);
  for i := 0 to SwapChain.Ptr.ImageCount - 1 do
  begin
    DepthBuffers[i] := TLabDepthBuffer.Create(Device, Window.Ptr.Width, Window.Ptr.Height);
  end;
  RenderPass := TLabRenderPass.Create(
    Device,
    [
      LabAttachmentDescription(
        SwapChain.Ptr.Format,
        VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE,
        VK_IMAGE_LAYOUT_UNDEFINED,
        0
      ),
      LabAttachmentDescription(
        DepthBuffers[0].Ptr.Format,
        VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_LOAD,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_IMAGE_LAYOUT_UNDEFINED,
        0
      )
    ], [
      LabSubpassDescriptionData(
        [],
        [LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)],
        [],
        LabAttachmentReference(1, VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL),
        []
      )
    ],
    []
  );
  SetLength(FrameBuffers, SwapChain.Ptr.ImageCount);
  for i := 0 to SwapChain.Ptr.ImageCount - 1 do
  begin
    FrameBuffers[i] := TLabFrameBuffer.Create(
      Device, RenderPass.Ptr,
      SwapChain.Ptr.Width, SwapChain.Ptr.Height,
      [SwapChain.Ptr.Images[i]^.View.VkHandle, DepthBuffers[i].Ptr.View.VkHandle]
    );
  end;
end;

procedure TLabApp.SwapchainDestroy;
begin
  FrameBuffers := nil;
  DepthBuffers := nil;
  RenderPass := nil;
  SwapChain := nil;
end;

procedure TLabApp.UpdateTransforms;
  var fov: TVkFloat;
  var W, V, P, C: TLabMat;
begin
  fov := LabDegToRad * 45;
  P := LabMatProj(fov, Window.Ptr.Width / Window.Ptr.Height, 0.1, 100);
  V := LabMatView(LabVec3(-5, 3, -10), LabVec3, LabVec3(0, 1, 0));
  W := LabMatRotationY((LabTimeLoopSec(5) / 5) * Pi * 2);
  C := LabMat(
    1, 0, 0, 0,
    0, -1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  );
  UniformView.Ptr.MemberAsMat('v')^ := V;
  UniformView.Ptr.MemberAsMat('p')^ := P;
  UniformView.Ptr.MemberAsMat('vp')^ := V * P * C;
  UniformView.Ptr.MemberAsMat('vp_i')^ := (V * P * C).Inverse;
  UniformInst.Ptr.MemberAsMat('w')^ := W;
  UniformGlobal.Ptr.MemberAsVec4('time')^ := LabVec4(LabTimeSec, LabTimeSec * 0.1, LabTimeSec * 10, sin(LabTimeSec * LabPi));
  UniformData.Ptr.MemberAsMat('mvp')^ := W * V * P * C;
end;

procedure TLabApp.TransferBuffers;
begin

end;

procedure TLabApp.Initialize;
  var map: PVkVoid;
  var ShaderBuildInfo: TLabShaderBuildInfo;
begin
  Window := TLabWindow.Create(500, 500);
  Window.Ptr.Caption := 'Vulkan Initialization';
  Device := TLabDevice.Create(
    PhysicalDevices[0],
    [
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT))),
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_COMPUTE_BIT)))
    ],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  Surface := TLabSurface.Create(Window);
  SwapChainCreate;
  CmdPool := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexGraphics);
  CmdBuffer := TLabCommandBuffer.Create(CmdPool);
  DescriptorSetsFactory := TLabDescriptorSetsFactory.Create(Device);
  DescriptorSets := DescriptorSetsFactory.Ptr.Request([
      LabDescriptorSetBindings([
          LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
          LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
          LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
          LabDescriptorBinding(3, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT))
      ])
  ]);
  PipelineLayout := TLabPipelineLayout.Create(
    Device, [], [
      DescriptorSets.Ptr.Layout[0].Ptr
    ]
  );
  //VertexShader := TLabVertexShader.Create(Device, 'triangle_vs.spv');
  //PixelShader := TLabPixelShader.Create(Device, 'triangle_ps.spv');
  CombinedShader := TLabCombinedShader.CreateFromFile(App.Device, 'triangle_shader.txt');
  ShaderBuildInfo.JointCount := 0;
  ShaderBuildInfo.MaxJointWeights := 0;
  Shaders := CombinedShader.Ptr.Build(ShaderBuildInfo);
  UniformGlobal := CombinedShader.Ptr.FindUniform('global').CreateBuffer();
  UniformView := CombinedShader.Ptr.FindUniform('view').CreateBuffer();
  UniformInst := CombinedShader.Ptr.FindUniform('instance').CreateBuffer();
  UniformData := CombinedShader.Ptr.FindUniform('data').CreateBuffer(1);
  //Uniforms := TUniforms.Create;
  DescriptorSets.Ptr.UpdateSets(
    [
      LabWriteDescriptorSetUniformBuffer(
        DescriptorSets.Ptr.VkHandle[0], 0,
        [
          LabDescriptorBufferInfo(UniformGlobal.Ptr.VkHandle),
          LabDescriptorBufferInfo(UniformView.Ptr.VkHandle),
          LabDescriptorBufferInfo(UniformInst.Ptr.VkHandle),
          LabDescriptorBufferInfo(UniformData.Ptr.VkHandle)
        ]
      )
    ],
    []
  );
  PipelineCache := TLabPipelineCache.Create(Device);
  Pipeline := TLabGraphicsPipeline.Create(
    Device, PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [LabShaderStage(Shaders.Ptr.Vertex.Ptr), LabShaderStage(Shaders.Ptr.Pixel.Ptr)],
    RenderPass.Ptr, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(
      VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
    ),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(
      VK_FALSE, VK_FALSE, VK_POLYGON_MODE_FILL,
      TVkFlags(VK_CULL_MODE_NONE), VK_FRONT_FACE_COUNTER_CLOCKWISE
    ),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment], []),
    LabPipelineTesselationState(0)
  );
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  TransferBuffers;
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  SwapchainDestroy;
  Shaders := nil;
  CombinedShader := nil;
  UniformGlobal := nil;
  UniformView := nil;
  UniformInst := nil;
  UniformData := nil;
  //Uniforms := nil;
  Fence := nil;
  Semaphore := nil;
  Pipeline := nil;
  PipelineCache := nil;
  PipelineLayout := nil;
  DescriptorSets := nil;
  DescriptorSetsFactory := nil;
  CmdBuffer := nil;
  CmdPool := nil;
  Surface := nil;
  Device := nil;
  Window := nil;
  Free;
end;

procedure TLabApp.Loop;
  var cur_buffer: TVkUInt32;
  var r: TVkResult;
begin
  TLabVulkan.IsActive := Window.Ptr.IsActive;
  if not TLabVulkan.IsActive
  or (Window.Ptr.Mode = wm_minimized)
  or (Window.Ptr.Width * Window.Ptr.Height = 0) then Exit;
  if (SwapChain.Ptr.Width <> Window.Ptr.Width)
  or (SwapChain.Ptr.Height <> Window.Ptr.Height) then
  begin
    Device.Ptr.WaitIdle;
    SwapchainDestroy;
    SwapchainCreate;
  end;
  UpdateTransforms;
  r := SwapChain.Ptr.AcquireNextImage(Semaphore);
  if r = VK_ERROR_OUT_OF_DATE_KHR then
  begin
    LabLogVkError(r);
    Device.Ptr.WaitIdle;
    SwapchainDestroy;
    SwapchainCreate;
    Exit;
  end
  else
  begin
    LabAssertVkError(r);
  end;
  cur_buffer := SwapChain.Ptr.CurImage;
  CmdBuffer.Ptr.RecordBegin();
  CmdBuffer.Ptr.BeginRenderPass(
    RenderPass.Ptr, FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(1.0, 0)]
  );
  CmdBuffer.Ptr.BindPipeline(Pipeline.Ptr);
  CmdBuffer.Ptr.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[0]], []
  );
  CmdBuffer.Ptr.SetViewport([LabViewport(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  CmdBuffer.Ptr.SetScissor([LabRect2D(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  CmdBuffer.Ptr.Draw(3);
  CmdBuffer.Ptr.EndRenderPass;
  CmdBuffer.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [CmdBuffer.Ptr.VkHandle],
    [Semaphore.Ptr.VkHandle],
    [],
    Fence.Ptr.VkHandle,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  Fence.Ptr.WaitFor;
  Fence.Ptr.Reset;
  CmdPool.Ptr.Reset();
  QueuePresent(SwapChain.Ptr.QueueFamilyPresent, [SwapChain.Ptr.VkHandle], [cur_buffer], []);
end;

end.
