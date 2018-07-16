unit Main;

{$macro on}
{$include LabPlatform.inc}

interface

uses
  Vulkan,
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
  LabDescriptorPool,
  LabPlatform,
  LabSync,
  LabColladaParser,
  LabScene,
  Classes;

type
  TLabApp = class (TLabVulkan)
  public
    var Window: TLabWindow;
    var Device: TLabDeviceShared;
    var Surface: TLabSurfaceShared;
    var SwapChain: TLabSwapChainShared;
    var CmdPool: TLabCommandPoolShared;
    var CmdBuffer: TLabCommandBufferShared;
    var Semaphore: TLabSemaphoreShared;
    var Fence: TLabFenceShared;
    var DepthBuffer: TLabDepthBufferShared;
    var UniformBuffer: TLabUniformBufferShared;
    var DescriptorSetLayout: TLabDescriptorSetLayoutShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var RenderPass: TLabRenderPassShared;
    var VertexShader: TLabShaderShared;
    var PixelShader: TLabShaderShared;
    var FrameBuffers: TLabFrameBuffers;
    //var VertexBuffer: TLabVertexBufferShared;
    var DescriptorPool: TLabDescriptorPoolShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineCache: TLabPipelineCacheShared;
    var Scene: TLabScene;
    var Transforms: record
      Projection: TLabMat;
      View: TLabMat;
      Model: TLabMat;
      Clip: TLabMat;
      MVP: TLabMat;
    end;
    constructor Create;
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
  end;

const
  NUM_SAMPLES = VK_SAMPLE_COUNT_1_BIT;
  NUM_DESCRIPTOR_SETS = 1;
  NUM_VIEWPORTS = 1;
  NUM_SCISSORS = NUM_VIEWPORTS;
  //Amount of time, in nanoseconds, to wait for a command buffer to complete
  FENCE_TIMEOUT = 100000000;

  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

var
  App: TLabApp;

implementation

constructor TLabApp.Create;
begin
  EnableLayer('VK_LAYER_LUNARG_core_validation');
  EnableLayer('VK_LAYER_LUNARG_parameter_validation');
  OnInitialize := @Initialize;
  OnFinalize := @Finalize;
  OnLoop := @Loop;
  inherited Create;
end;

procedure TLabApp.Initialize;
  var fov: TVkFloat;
  var map: PVkVoid;
  var ColladaParser: TLabColladaParser;
begin
  ColladaParser := TLabColladaParser.Create('../Models/box.dae');
  ColladaParser.RootNode.Dump;
  ColladaParser.Free;
  Window := TLabWindow.Create(500, 500);
  Window.Caption := 'Vulkan Model';
  Device := TLabDevice.Create(
    PhysicalDevices[0],
    [
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT))),
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_COMPUTE_BIT)))
    ],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  Surface := TLabSurface.Create(Window);
  SwapChain := TLabSwapChain.Create(Device, Surface);
  CmdPool := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexGraphics);
  CmdBuffer := TLabCommandBuffer.Create(CmdPool);
  DepthBuffer := TLabDepthBuffer.Create(Device, Window.Width, Window.Height);
  UniformBuffer := TLabUniformBuffer.Create(Device, SizeOf(TLabMat));
  DescriptorSetLayout := TLabDescriptorSetLayout.Create(
    Device, [LabDescriptorBinding(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT))]
  );
  PipelineLayout := TLabPipelineLayout.Create(Device, [], [DescriptorSetLayout]);
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
        DepthBuffer.Ptr.Format,
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
    ]
  );
  VertexShader := TLabVertexShader.Create(Device, 'vs.spv');
  PixelShader := TLabPixelShader.Create(Device, 'ps.spv');
  FrameBuffers := LabFrameBuffers(Device, RenderPass.Ptr, SwapChain.Ptr, DepthBuffer.Ptr);
  //VertexBuffer := TLabVertexBuffer.Create(
  //  Device, 32, 32,
  //  [
  //    LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, 0),
  //    LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, 16)
  //  ]
  //);
  Scene := TLabScene.Create(Device);
  Scene.Add('../Models/box.dae');
  //map := nil;
  //if (VertexBuffer.Ptr.Map(map)) then
  //begin
  //  Move(g_vb_solid_face_colors_Data, map^, sizeof(g_vb_solid_face_colors_Data));
  //  VertexBuffer.Ptr.Unmap;
  //end;
  DescriptorPool := TLabDescriptorPool.Create(
    Device,
    [LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1)],
    1
  );
  DescriptorSets := TLabDescriptorSets.Create(
    Device, DescriptorPool,
    [DescriptorSetLayout.Ptr.VkHandle]
  );
  DescriptorSets.Ptr.UpdateSets(
    [
      LabWriteDescriptorSet(
        DescriptorSets.Ptr.VkHandle[0],
        0,
        VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        0,
        1,
        nil,
        UniformBuffer.Ptr.BufferInfo
      )
    ],
    []
  );
  PipelineCache := TLabPipelineCache.Create(Device);
  Pipeline := TLabGraphicsPipeline.Create(
    Device, PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    LabShaderStages([VertexShader.Ptr, PixelShader.Ptr]),
    RenderPass.Ptr, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState(
      [VertexBuffer.Ptr.MakeBindingDesc(0)],
      [
        VertexBuffer.Ptr.MakeAttributeDesc(0, 0, 0),
        VertexBuffer.Ptr.MakeAttributeDesc(1, 1, 0)
      ]
    ),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState(1, @LabDefaultColorBlendAttachment, [])
  );
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  fov := LabDegToRad * 45;
  if (Window.Width > Window.Height) then
  begin
    fov *= Window.Height / Window.Width;
  end;
  with Transforms do
  begin
    Projection := LabMatProj(fov, Window.Width / Window.Height, 0.1, 100);
    View := LabMatView(LabVec3(-5, 3, -10), LabVec3, LabVec3(0, -1, 0));
    Model := LabMatIdentity;
    // Vulkan clip space has inverted Y and half Z.
    Clip := LabMat(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 0.5, 0,
      0, 0, 0.5, 1
    );
    MVP := Model * View * Projection * Clip;
  end;
end;

procedure TLabApp.Finalize;
begin
  Fence := nil;
  Semaphore := nil;
  Pipeline := nil;
  PipelineCache := nil;
  DescriptorSets := nil;
  DescriptorPool := nil;
  //VertexBuffer := nil;
  FrameBuffers := nil;
  PixelShader := nil;
  VertexShader := nil;
  RenderPass := nil;
  PipelineLayout := nil;
  DescriptorSetLayout := nil;
  UniformBuffer := nil;
  DepthBuffer := nil;
  CmdBuffer := nil;
  CmdPool := nil;
  SwapChain := nil;
  Surface := nil;
  Device := nil;
  Window.Free;
  Free;
end;

procedure TLabApp.Loop;
  var UniformData: PVkUInt8;
  var cur_buffer: TVkUInt32;
begin
  TLabVulkan.IsActive := Window.IsActive;
  if not TLabVulkan.IsActive then Exit;
  with Transforms do
  begin
    Model := LabMatRotationY(LabTimeSec);
    MVP := Model * View * Projection * Clip;
    UniformData := nil;
    if (UniformBuffer.Ptr.Map(UniformData)) then
    begin
      Move(MVP, UniformData^, SizeOf(MVP));
      UniformBuffer.Ptr.Unmap;
    end;
  end;
  CmdBuffer.Ptr.RecordBegin();
  cur_buffer := SwapChain.Ptr.AcquireNextImage(Semaphore);
  CmdBuffer.Ptr.BeginRenderPass(
    RenderPass.Ptr, FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(1.0, 0)]
  );
  //CmdBuffer.Ptr.BindPipeline(Pipeline.Ptr);
  //CmdBuffer.Ptr.BindDescriptorSets(
  //  VK_PIPELINE_BIND_POINT_GRAPHICS,
  //  PipelineLayout.Ptr,
  //  0, 1, DescriptorSets.Ptr, []
  //);
  //CmdBuffer.Ptr.BindVertexBuffers(0, [VertexBuffer.Ptr.VkHandle], [0]);
  //CmdBuffer.Ptr.SetViewport([LabViewport(0, 0, Window.Width, Window.Height)]);
  //CmdBuffer.Ptr.SetScissor([LabRect2D(0, 0, Window.Width, Window.Height)]);
  //CmdBuffer.Ptr.Draw(12 * 3);
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
  QueuePresent(SwapChain.Ptr.QueueFamilyPresent, [SwapChain.Ptr.VkHandle], [cur_buffer], []);
end;

end.
