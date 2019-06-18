unit main;

{$macro on}
{$include LabPlatform.inc}

interface

uses
  cube_data,
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
  LabImageData,
  LabTextures,
  Classes,
  SysUtils;

type
  TMyTexture2D = class (TLabTexture2D)
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

  TLabApp = class (TLabVulkan)
  public
    type TTransforms = packed record
      World: TLabMat;
      View: TLabMat;
      Projection: TLabMat;
      WVP: TLabMat;
    end;
    type TUniformTransforms = specialize TLabUniformBuffer<TTransforms>;
    type TUniformTransformsShared = specialize TLabSharedRef<TUniformTransforms>;
    var Window: TLabWindowShared;
    var Device: TLabDeviceShared;
    var Surface: TLabSurfaceShared;
    var SwapChain: TLabSwapChainShared;
    var CmdPool: TLabCommandPoolShared;
    var Cmd: TLabCommandBufferShared;
    var Semaphore: TLabSemaphoreShared;
    var Fence: TLabFenceShared;
    var DepthBuffers: array of TLabDepthBufferShared;
    var FrameBuffers: array of TLabFrameBufferShared;
    var UniformBuffer: TUniformTransformsShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var RenderPass: TLabRenderPassShared;
    var VertexShader: TLabShaderShared;
    var PixelShader: TLabShaderShared;
    var VertexBuffer: TLabVertexBufferShared;
    var VertexBufferStaging: TLabBufferShared;
    var DescriptorSetsFactory: TLabDescriptorSetsFactoryShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineCache: TLabPipelineCacheShared;
    var Texture: TLabTexture2DShared;
    var TextureBRDFLUT: TLabTexture2DShared;
    var OnStage: TLabDelegate;
    var OnStageComplete: TLabDelegate;
    constructor Create;
    procedure SwapchainCreate;
    procedure SwapchainDestroy;
    procedure UpdateTransforms;
    procedure TransferBuffers;
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
    procedure GenerateBRDFLUT;
  end;

const
  //Amount of time, in nanoseconds, to wait for a command buffer to complete
  FENCE_TIMEOUT = 100000000;

  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

var
  App: TLabApp;

implementation

procedure TMyTexture2D.AfterConstruction;
begin
  inherited AfterConstruction;
  App.OnStage.Add(@Stage);
  App.OnStageComplete.Add(@StageComplete);
end;

procedure TMyTexture2D.BeforeDestruction;
begin
  App.OnStageComplete.Remove(@StageComplete);
  App.OnStage.Remove(@Stage);
  inherited BeforeDestruction;
end;

constructor TLabApp.Create;
begin
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
        VK_IMAGE_LAYOUT_UNDEFINED,
        VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE,
        0
      ),
      LabAttachmentDescription(
        DepthBuffers[0].Ptr.Format,
        VK_IMAGE_LAYOUT_UNDEFINED,
        VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_LOAD,
        VK_ATTACHMENT_STORE_OP_STORE,
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
  var Clip: TLabMat;
begin
  fov := LabDegToRad * 20;
  with UniformBuffer.Ptr.Buffer^ do
  begin
    Projection := LabMatProj(fov, Window.Ptr.Width / Window.Ptr.Height, 0.1, 100);
    View := LabMatView(LabVec3(-5, 3, -10), LabVec3, LabVec3(0, -1, 0));
    World := LabMatRotationY((LabTimeLoopSec(5) / 5) * Pi * 2);
    // Vulkan clip space has inverted Y and half Z.
    Clip := LabMat(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 0.5, 0,
      0, 0, 0.5, 1
    );
    WVP := World * View * Projection * Clip;
  end;
end;

procedure TLabApp.TransferBuffers;
begin
  Cmd.Ptr.RecordBegin;
  Cmd.Ptr.CopyBuffer(
    VertexBufferStaging.Ptr.VkHandle,
    VertexBuffer.Ptr.VkHandle,
    [LabBufferCopy(VertexBuffer.Ptr.Size)]
  );
  OnStage.Call([Cmd.Ptr]);
  Cmd.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [Cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
  VertexBufferStaging := nil;
  OnStageComplete.Call([]);
end;

procedure TLabApp.Initialize;
  var map: PVkVoid;
begin
  Window := TLabWindow.Create(500, 500);
  Window.Ptr.Caption := 'Vulkan Texture';
  Device := TLabDevice.Create(
    PhysicalDevices[0],
    [
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT)))
    ],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  Surface := TLabSurface.Create(Window);
  SwapChainCreate;
  CmdPool := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexGraphics);
  Cmd := TLabCommandBuffer.Create(CmdPool);
  UniformBuffer := TUniformTransforms.Create(Device);
  VertexShader := TLabVertexShader.Create(Device, 'vs.spv');
  PixelShader := TLabPixelShader.Create(Device, 'ps.spv');
  VertexBuffer := TLabVertexBuffer.Create(
    Device,
    sizeof(g_vb_solid_face_colors_Data),
    sizeof(g_vb_solid_face_colors_Data[0]),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, LabPtrToOrd(@TVertex( nil^ ).posX) ),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, LabPtrToOrd(@TVertex( nil^ ).r) ),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32_SFLOAT, LabPtrToOrd(@TVertex( nil^ ).u) )
    ],
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexBufferStaging := TLabBuffer.Create(
    Device, VertexBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (VertexBufferStaging.Ptr.Map(map)) then
  begin
    Move(g_vb_solid_face_colors_Data, map^, sizeof(g_vb_solid_face_colors_Data));
    VertexBufferStaging.Ptr.Unmap;
  end;
  DescriptorSetsFactory := TLabDescriptorSetsFactory.Create(Device);
  DescriptorSets := DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings([
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
    ])
  ]);
  PipelineCache := TLabPipelineCache.Create(Device);
  Texture := TMyTexture2D.Create(Device, '../../Images/box.png');
  //Texture := TTexture.Create('../../Images/Arches_E_PineTree_3k.hdr');
  //GenerateBRDFLUT;
  //Texture := TextureBRDFLUT;
  DescriptorSets.Ptr.UpdateSets(
    [
      LabWriteDescriptorSetUniformBuffer(
        DescriptorSets.Ptr.VkHandle[0],
        0,
        [LabDescriptorBufferInfo(UniformBuffer.Ptr.VkHandle)]
      ),
      LabWriteDescriptorSetImageSampler(
        DescriptorSets.Ptr.VkHandle[0],
        1,
        [
          LabDescriptorImageInfo(
            VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            Texture.Ptr.View.Ptr.VkHandle,
            Texture.Ptr.Sampler.Ptr.VkHandle
          )
        ]
      )
    ],
    []
  );
  PipelineLayout := TLabPipelineLayout.Create(Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]);
  Pipeline := TLabGraphicsPipeline.Create(
    Device, PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [LabShaderStage(VertexShader.Ptr), LabShaderStage(PixelShader.Ptr)],
    RenderPass.Ptr, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState(
      [VertexBuffer.Ptr.MakeBindingDesc(0)],
      [
        VertexBuffer.Ptr.MakeAttributeDesc(0, 0, 0),
        VertexBuffer.Ptr.MakeAttributeDesc(1, 1, 0),
        VertexBuffer.Ptr.MakeAttributeDesc(2, 2, 0)
      ]
    ),
    LabPipelineRasterizationState(),
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
  Texture := nil;
  TextureBRDFLUT := nil;
  Fence := nil;
  Semaphore := nil;
  Pipeline := nil;
  PipelineCache := nil;
  DescriptorSets := nil;
  DescriptorSetsFactory := nil;
  VertexBuffer := nil;
  PixelShader := nil;
  VertexShader := nil;
  PipelineLayout := nil;
  UniformBuffer := nil;
  Cmd := nil;
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
  Cmd.Ptr.RecordBegin();
  Cmd.Ptr.BeginRenderPass(
    RenderPass.Ptr, FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(1.0, 0)]
  );
  Cmd.Ptr.BindPipeline(Pipeline.Ptr);
  Cmd.Ptr.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[0]], []
  );
  Cmd.Ptr.BindVertexBuffers(0, [VertexBuffer.Ptr.VkHandle], [0]);
  Cmd.Ptr.SetViewport([LabViewport(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  Cmd.Ptr.SetScissor([LabRect2D(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  Cmd.Ptr.Draw(12 * 3);
  Cmd.Ptr.EndRenderPass;
  Cmd.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [Cmd.Ptr.VkHandle],
    [Semaphore.Ptr.VkHandle],
    [],
    Fence.Ptr.VkHandle,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  Fence.Ptr.WaitFor;
  Fence.Ptr.Reset;
  QueuePresent(SwapChain.Ptr.QueueFamilyPresent, [SwapChain.Ptr.VkHandle], [cur_buffer], []);
end;

procedure TLabApp.GenerateBRDFLUT;
  const tex_size = 512;
  var cmd_tmp: TLabCommandBufferShared;
  var pipeline_layout: TLabPipelineLayoutShared;
  var pipeline_tmp: TLabPipelineShared;
  var vs: TLabVertexShaderShared;
  var ps: TLabPixelShaderShared;
  var render_pass: TLabRenderPassShared;
  var frame_buffer: TLabFrameBufferShared;
begin
  TextureBRDFLUT := TLabTexture2D.Create(
    Device,
    VK_FORMAT_R16G16_SFLOAT, tex_size, tex_size,
    TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
    False
  );
  vs := TLabVertexShader.Create(App.Device, 'brdflut_vs.spv');
  ps := TLabPixelShader.Create(App.Device, 'brdflut_ps.spv');
  render_pass := TLabRenderPass.Create(
    App.Device,
    [
      LabAttachmentDescription(
        TextureBRDFLUT.Ptr.Format,
        VK_IMAGE_LAYOUT_UNDEFINED,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_STORE
      )
    ],
    [
      LabSubpassDescriptionData(
        [],
        [
          LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
        ],
        [],
        LabAttachmentReferenceInvalid,
        []
      )
    ],
    [
      LabSubpassDependency(
        VK_SUBPASS_EXTERNAL,
        0,
        TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
        TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
        TVkFlags(VK_ACCESS_MEMORY_READ_BIT),
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
      ),
      LabSubpassDependency(
        0,
        VK_SUBPASS_EXTERNAL,
        TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
        TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_ACCESS_MEMORY_READ_BIT)
      )
    ]
  );
  pipeline_layout := TLabPipelineLayout.Create(
    App.Device, [], []
  );
  pipeline_tmp := TLabGraphicsPipeline.Create(
    App.Device, App.PipelineCache, pipeline_layout.Ptr,
    [VK_DYNAMIC_STATE_SCISSOR, VK_DYNAMIC_STATE_VIEWPORT],
    [LabShaderStage(vs.Ptr), LabShaderStage(ps.Ptr)],
    render_pass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment], []),
    LabPipelineTesselationState(0)
  );
  frame_buffer := TLabFrameBuffer.Create(
    App.Device, render_pass,
    TextureBRDFLUT.Ptr.Width, TextureBRDFLUT.Ptr.Height,
    [TextureBRDFLUT.Ptr.View.Ptr.VkHandle]
  );
  cmd_tmp := TLabCommandBuffer.Create(App.CmdPool);
  cmd_tmp.Ptr.RecordBegin();
  cmd_tmp.Ptr.BeginRenderPass(
    render_pass.Ptr, frame_buffer.ptr,
    [LabClearValue(0.0, 0.0, 0.0, 1.0)]
  );
  cmd_tmp.Ptr.BindPipeline(pipeline_tmp.Ptr);
  cmd_tmp.Ptr.SetViewport([LabViewport(0, 0, TextureBRDFLUT.Ptr.Width, TextureBRDFLUT.Ptr.Height)]);
  cmd_tmp.Ptr.SetScissor(LabRect2D(0, 0, TextureBRDFLUT.Ptr.Width, TextureBRDFLUT.Ptr.Height));
  cmd_tmp.Ptr.Draw(3);
  cmd_tmp.Ptr.EndRenderPass;
  cmd_tmp.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [cmd_tmp.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
end;

end.
