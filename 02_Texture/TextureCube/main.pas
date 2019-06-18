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
  Math,
  SysUtils;

type
  TMyTextureCube = class (TLabTextureCube)
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

  TLabApp = class (TLabVulkan)
  public
    type TTransofrms = packed record
      World: TLabMat;
      View: TLabMat;
      Projection: TLabMat;
      WVP: TLabMat;
    end;
    type TUniformTransforms = specialize TLabUniformBuffer<TTransofrms>;
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
    var Texture: TLabTextureCubeShared;
    var TextureGen: TLabTextureCubeShared;
    var TextureIrradiance: TLabTextureCubeShared;
    var TexturePrefiltered: TLabTextureCubeShared;
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
    procedure GenerateCubeMap;
    procedure GenerateIrradianceMap;
    procedure GeneratePrefilteredMap;
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

procedure TMyTextureCube.AfterConstruction;
begin
  inherited AfterConstruction;
  App.OnStage.Add(@Stage);
  App.OnStageComplete.Add(@StageComplete);
end;

procedure TMyTextureCube.BeforeDestruction;
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
  fov := LabDegToRad * 45;
  with UniformBuffer.Ptr.Buffer^ do
  begin
    Projection := LabMatProj(fov, Window.Ptr.Width / Window.Ptr.Height, 0.1, 100);
    View := LabMatView(LabVec3(0, 0, 0), LabVec3(0, Sin((LabTimeLoopSec(8) / 8) * Pi * 2) * 0.6, 1), LabVec3(0, -1, 0));
    World := LabMatRotationY((LabTimeLoopSec(25) / 25) * Pi * 2);
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
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, LabPtrToOrd(@TVertex( nil^ ).r)),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32_SFLOAT, LabPtrToOrd(@TVertex( nil^ ).u))
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
  PipelineCache := TLabPipelineCache.Create(Device);
  Texture := TMyTextureCube.Create(App.Device, '../../Images/park_cube_map');
  //GenerateCubeMap;
  //GeneratePrefilteredMap;
  //GenerateIrradianceMap;
  //Texture := TexturePrefiltered;
  DescriptorSets := DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings([
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
    ])
  ]);
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
    LabPipelineRasterizationState(
      VK_FALSE, VK_FALSE, VK_POLYGON_MODE_FILL, TVkFlags(VK_CULL_MODE_BACK_BIT), VK_FRONT_FACE_COUNTER_CLOCKWISE
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
  TextureGen := nil;
  TextureIrradiance := nil;
  TexturePrefiltered := nil;
  Texture := nil;
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

procedure TLabApp.GenerateCubeMap;
  const tex_size = 2048;
  var tex2d: TLabTexture2D;
  var tmp_cmd: TLabCommandBufferShared;
  var render_pass: TLabRenderPassShared;
  var attachments: array[0..5] of TVkAttachmentDescription;
  var i: Integer;
  var frame_buffer: TLabFrameBufferShared;
  var vs: TLabVertexShaderShared;
  var ps: TLabPixelShaderShared;
  var pipeline_layout: TLabPipelineLayoutShared;
  var pipeline_tmp: TLabPipelineShared;
  var desc_sets: TLabDescriptorSetsShared;
  var viewport: TVkViewport;
  var scissor: TVkRect2D;
  var view_arr: array[0..5] of TLabImageViewShared;
begin
  TextureGen := TLabTextureCube.Create(
    App.Device,
    tex_size, VK_FORMAT_R32G32B32A32_SFLOAT,
    VK_IMAGE_LAYOUT_UNDEFINED,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    True
  );
  for i := 0 to 5 do
  begin
    view_arr[i] := TLabImageView.Create(
      Device, TextureGen.Ptr.Image.Ptr.VkHandle, TextureGen.Ptr.Image.Ptr.Format,
      TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
      0, 1, i, 1
    );
  end;
  tex2d := TLabTexture2D.Create(App.Device, '../../Images/Arches_E_PineTree_3k.hdr', False);
  for i := 0 to High(attachments) do
  begin
    attachments[i] := LabAttachmentDescription(
      TextureGen.Ptr.Format,
      VK_IMAGE_LAYOUT_UNDEFINED,
      {VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL} VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
      VK_SAMPLE_COUNT_1_BIT,
      VK_ATTACHMENT_LOAD_OP_DONT_CARE,
      VK_ATTACHMENT_STORE_OP_STORE,
      VK_ATTACHMENT_LOAD_OP_DONT_CARE,
      VK_ATTACHMENT_STORE_OP_DONT_CARE
    );
  end;
  render_pass := TLabRenderPass.Create(
    Device,
    attachments,
    [
      LabSubpassDescriptionData(
        [],
        [
          LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(1, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(2, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(3, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(4, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(5, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
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
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
      ),
      LabSubpassDependency(
        0,
        VK_SUBPASS_EXTERNAL,
        TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
        TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_ACCESS_MEMORY_READ_BIT),
        TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
      )
    ]
  );
  frame_buffer := TLabFrameBuffer.Create(
    Device, render_pass, tex_size, tex_size,
    [
      view_arr[0].Ptr.VkHandle,
      view_arr[1].Ptr.VkHandle,
      view_arr[2].Ptr.VkHandle,
      view_arr[3].Ptr.VkHandle,
      view_arr[4].Ptr.VkHandle,
      view_arr[5].Ptr.VkHandle
    ]
  );
  desc_sets := App.DescriptorSetsFactory.Ptr.Request(
    [
      LabDescriptorSetBindings(
        [
          LabDescriptorBinding(
            0, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
          )
        ]
      )
    ]
  );
  pipeline_layout := TLabPipelineLayout.Create(
    Device, [],
    [
      desc_sets.Ptr.Layout[0].Ptr
    ]
  );
  desc_sets.Ptr.UpdateSets(
    LabWriteDescriptorSetImageSampler(
      desc_sets.Ptr.VkHandle[0], 0,
      LabDescriptorImageInfo(
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        tex2d.View.Ptr.VkHandle,
        tex2d.Sampler.Ptr.VkHandle
      )
    ),
    []
  );
  vs := TLabVertexShader.Create(Device, 'gen_cube_map_vs.spv');
  ps := TLabPixelShader.Create(Device, 'gen_cube_map_ps.spv');
  viewport := LabViewport(0, 0, tex_size, tex_size);
  scissor := LabRect2D(0, 0, tex_size, tex_size);
  pipeline_tmp := TLabGraphicsPipeline.FindOrCreate(
    Device, App.PipelineCache, pipeline_layout.Ptr, [],
    [LabShaderStage(vs.Ptr), LabShaderStage(ps.Ptr)],
    render_pass, 0,
    LabPipelineViewportState(1, @viewport, 1, @scissor),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment,
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment
    ], []),
    LabPipelineTesselationState(0)
  );
  tmp_cmd := TLabCommandBuffer.Create(App.CmdPool);
  tmp_cmd.Ptr.RecordBegin();
  tex2d.Stage([tmp_cmd.Ptr]);
  tmp_cmd.Ptr.BeginRenderPass(
    render_pass.Ptr, frame_buffer.Ptr,
    [
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0)
    ]
  );
  tmp_cmd.Ptr.BindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline_layout.Ptr, 0, [desc_sets.Ptr.VkHandle[0]], []);
  tmp_cmd.Ptr.BindPipeline(pipeline_tmp.Ptr);
  tmp_cmd.Ptr.Draw(3);
  tmp_cmd.Ptr.EndRenderPass;
  tmp_cmd.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [tmp_cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
  tex2d.Free;
  tmp_cmd.Ptr.RecordBegin();
  App.TextureGen.Ptr.GenMipMaps(tmp_cmd.Ptr);
  tmp_cmd.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [tmp_cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    0
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
end;

procedure TLabApp.GenerateIrradianceMap;
  const tex_size = 256;
  var tmp_cmd: TLabCommandBufferShared;
  var render_pass: TLabRenderPassShared;
  var attachments: array[0..5] of TVkAttachmentDescription;
  var i: Integer;
  var frame_buffer: TLabFrameBufferShared;
  var vs: TLabVertexShaderShared;
  var ps: TLabPixelShaderShared;
  var pipeline_layout: TLabPipelineLayoutShared;
  var pipeline_tmp: TLabPipelineShared;
  var desc_sets: TLabDescriptorSetsShared;
  var viewport: TVkViewport;
  var scissor: TVkRect2D;
  var view_arr: array[0..5] of TLabImageViewShared;
begin
  TextureIrradiance := TLabTextureCube.Create(
    App.Device,
    tex_size, VK_FORMAT_R32G32B32A32_SFLOAT,
    VK_IMAGE_LAYOUT_UNDEFINED,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    True
  );
  for i := 0 to 5 do
  begin
    view_arr[i] := TLabImageView.Create(
      Device, TextureIrradiance.Ptr.Image.Ptr.VkHandle, TextureIrradiance.Ptr.Image.Ptr.Format,
      TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
      0, 1, i, 1
    );
  end;
  for i := 0 to High(attachments) do
  begin
    attachments[i] := LabAttachmentDescription(
      TextureIrradiance.Ptr.Format,
      VK_IMAGE_LAYOUT_UNDEFINED,
      {VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL} VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
      VK_SAMPLE_COUNT_1_BIT,
      VK_ATTACHMENT_LOAD_OP_DONT_CARE,
      VK_ATTACHMENT_STORE_OP_STORE,
      VK_ATTACHMENT_LOAD_OP_DONT_CARE,
      VK_ATTACHMENT_STORE_OP_DONT_CARE
    );
  end;
  render_pass := TLabRenderPass.Create(
    Device,
    attachments,
    [
      LabSubpassDescriptionData(
        [],
        [
          LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(1, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(2, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(3, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(4, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(5, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
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
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
      ),
      LabSubpassDependency(
        0,
        VK_SUBPASS_EXTERNAL,
        TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
        TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_ACCESS_MEMORY_READ_BIT),
        TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
      )
    ]
  );
  frame_buffer := TLabFrameBuffer.Create(
    Device, render_pass, tex_size, tex_size,
    [
      view_arr[0].Ptr.VkHandle,
      view_arr[1].Ptr.VkHandle,
      view_arr[2].Ptr.VkHandle,
      view_arr[3].Ptr.VkHandle,
      view_arr[4].Ptr.VkHandle,
      view_arr[5].Ptr.VkHandle
      //App.TextureGen.Ptr.View.Ptr.VkHandle
    ]
  );
  desc_sets := App.DescriptorSetsFactory.Ptr.Request(
    [
      LabDescriptorSetBindings(
        [
          LabDescriptorBinding(
            0, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
          )
        ]
      )
    ]
  );
  pipeline_layout := TLabPipelineLayout.Create(
    Device, [],
    [
      desc_sets.Ptr.Layout[0].Ptr
    ]
  );
  desc_sets.Ptr.UpdateSets(
    LabWriteDescriptorSetImageSampler(
      desc_sets.Ptr.VkHandle[0], 0,
      LabDescriptorImageInfo(
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        TextureGen.Ptr.View.Ptr.VkHandle,
        TextureGen.Ptr.Sampler.Ptr.VkHandle
      )
    ),
    []
  );
  vs := TLabVertexShader.Create(Device, 'gen_cube_map_vs.spv');
  ps := TLabPixelShader.Create(Device, 'gen_irradiance_map_ps.spv');
  viewport := LabViewport(0, 0, tex_size, tex_size);
  scissor := LabRect2D(0, 0, tex_size, tex_size);
  pipeline_tmp := TLabGraphicsPipeline.FindOrCreate(
    Device, App.PipelineCache, pipeline_layout.Ptr, [],
    [LabShaderStage(vs.Ptr), LabShaderStage(ps.Ptr)],
    render_pass, 0,
    LabPipelineViewportState(1, @viewport, 1, @scissor),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment,
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment
    ], []),
    LabPipelineTesselationState(0)
  );
  tmp_cmd := TLabCommandBuffer.Create(App.CmdPool);
  tmp_cmd.Ptr.RecordBegin();
  tmp_cmd.Ptr.BeginRenderPass(
    render_pass.Ptr, frame_buffer.Ptr,
    [
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0)
    ]
  );
  tmp_cmd.Ptr.BindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline_layout.Ptr, 0, [desc_sets.Ptr.VkHandle[0]], []);
  tmp_cmd.Ptr.BindPipeline(pipeline_tmp.Ptr);
  tmp_cmd.Ptr.Draw(3);
  tmp_cmd.Ptr.EndRenderPass;
  tmp_cmd.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [tmp_cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
  tmp_cmd.Ptr.RecordBegin();
  TextureIrradiance.Ptr.GenMipMaps(tmp_cmd.Ptr);
  tmp_cmd.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [tmp_cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    0
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
end;

procedure TLabApp.GeneratePrefilteredMap;
  const tex_size = 1024;
  var tmp_cmd: TLabCommandBufferShared;
  var render_pass: TLabRenderPassShared;
  var attachments: array[0..5] of TVkAttachmentDescription;
  var i, m, ts: Integer;
  var frame_buffers: array of TLabFrameBufferShared;
  var vs: TLabVertexShaderShared;
  var ps: TLabPixelShaderShared;
  var pipeline_layout: TLabPipelineLayoutShared;
  var pipeline_tmp: TLabPipelineShared;
  var desc_sets: TLabDescriptorSetsShared;
  var view_arr: array of array[0..5] of TLabImageViewShared;
  var push_consts: record
    roughness: TVkFloat;
    sample_count: TVkUInt32;
  end;
begin
  TexturePrefiltered := TLabTextureCube.Create(
    App.Device,
    tex_size, VK_FORMAT_R32G32B32A32_SFLOAT,
    VK_IMAGE_LAYOUT_UNDEFINED,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT),
    True
  );
  SetLength(view_arr, TexturePrefiltered.Ptr.MipLevels);
  for m := 0 to TexturePrefiltered.Ptr.MipLevels - 1 do
  for i := 0 to 5 do
  begin
    view_arr[m][i] := TLabImageView.Create(
      Device, TexturePrefiltered.Ptr.Image.Ptr.VkHandle, TexturePrefiltered.Ptr.Image.Ptr.Format,
      TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
      m, 1, i, 1
    );
  end;
  for i := 0 to High(attachments) do
  begin
    attachments[i] := LabAttachmentDescription(
      TexturePrefiltered.Ptr.Format,
      VK_IMAGE_LAYOUT_UNDEFINED,
      VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
      VK_SAMPLE_COUNT_1_BIT,
      VK_ATTACHMENT_LOAD_OP_DONT_CARE,
      VK_ATTACHMENT_STORE_OP_STORE,
      VK_ATTACHMENT_LOAD_OP_DONT_CARE,
      VK_ATTACHMENT_STORE_OP_DONT_CARE
    );
  end;
  render_pass := TLabRenderPass.Create(
    Device,
    attachments,
    [
      LabSubpassDescriptionData(
        [],
        [
          LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(1, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(2, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(3, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(4, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(5, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
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
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
      ),
      LabSubpassDependency(
        0,
        VK_SUBPASS_EXTERNAL,
        TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
        TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_ACCESS_MEMORY_READ_BIT),
        TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
      )
    ]
  );
  SetLength(frame_buffers, TexturePrefiltered.Ptr.MipLevels);
  for m := 0 to TexturePrefiltered.Ptr.MipLevels - 1 do
  begin
    ts := Round(tex_size * Math.intpower(0.5, m));
    frame_buffers[m] := TLabFrameBuffer.Create(
      Device, render_pass, ts, ts,
      [
        view_arr[m][0].Ptr.VkHandle,
        view_arr[m][1].Ptr.VkHandle,
        view_arr[m][2].Ptr.VkHandle,
        view_arr[m][3].Ptr.VkHandle,
        view_arr[m][4].Ptr.VkHandle,
        view_arr[m][5].Ptr.VkHandle
      ]
    );
  end;
  desc_sets := App.DescriptorSetsFactory.Ptr.Request(
    [
      LabDescriptorSetBindings(
        [
          LabDescriptorBinding(
            0, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
          )
        ]
      )
    ]
  );
  pipeline_layout := TLabPipelineLayout.Create(
    Device, [
      LabPushConstantRange(
        TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
        0, SizeOf(push_consts)
      )
    ],
    [
      desc_sets.Ptr.Layout[0].Ptr
    ]
  );
  desc_sets.Ptr.UpdateSets(
    LabWriteDescriptorSetImageSampler(
      desc_sets.Ptr.VkHandle[0], 0,
      LabDescriptorImageInfo(
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        TextureGen.Ptr.View.Ptr.VkHandle,
        TextureGen.Ptr.Sampler.Ptr.VkHandle
      )
    ),
    []
  );
  vs := TLabVertexShader.Create(Device, 'gen_cube_map_vs.spv');
  ps := TLabPixelShader.Create(Device, 'gen_prefiltered_map_ps.spv');
  pipeline_tmp := TLabGraphicsPipeline.FindOrCreate(
    Device, App.PipelineCache, pipeline_layout.Ptr, [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [LabShaderStage(vs.Ptr), LabShaderStage(ps.Ptr)],
    render_pass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment,
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment
    ], []),
    LabPipelineTesselationState(0)
  );
  tmp_cmd := TLabCommandBuffer.Create(App.CmdPool);
  tmp_cmd.Ptr.RecordBegin();
  for m := 0 to TexturePrefiltered.Ptr.MipLevels - 1 do
  begin
    ts := Round(tex_size * Math.intpower(0.5, m));
    tmp_cmd.Ptr.SetScissor([LabRect2D(0, 0, ts, ts)]);
    tmp_cmd.Ptr.SetViewport([LabViewport(0, 0, ts, ts)]);
    tmp_cmd.Ptr.BeginRenderPass(
      render_pass.Ptr, frame_buffers[m].Ptr,
      [
        LabClearValue(0.0, 0.0, 0.0, 1.0),
        LabClearValue(0.0, 0.0, 0.0, 1.0),
        LabClearValue(0.0, 0.0, 0.0, 1.0),
        LabClearValue(0.0, 0.0, 0.0, 1.0),
        LabClearValue(0.0, 0.0, 0.0, 1.0),
        LabClearValue(0.0, 0.0, 0.0, 1.0)
      ]
    );
    tmp_cmd.Ptr.BindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline_layout.Ptr, 0, [desc_sets.Ptr.VkHandle[0]], []);
    tmp_cmd.Ptr.BindPipeline(pipeline_tmp.Ptr);
    push_consts.roughness := m / (TexturePrefiltered.Ptr.MipLevels - 1);
    push_consts.sample_count := 32;
    tmp_cmd.Ptr.PushConstants(pipeline_layout.Ptr, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT), 0, SizeOf(push_consts), @push_consts);
    tmp_cmd.Ptr.Draw(3);
    tmp_cmd.Ptr.EndRenderPass;
  end;
  tmp_cmd.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [tmp_cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
end;

end.
