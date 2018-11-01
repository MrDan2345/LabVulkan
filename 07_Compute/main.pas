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
  LabDescriptorPool,
  LabSync,
  LabUtils,
  LabImageData,
  Classes,
  SysUtils;

type
  TTexture = class (TLabClass)
  public
    var Image: TLabImageShared;
    var Staging: TLabBufferShared;
    var View: TLabImageViewShared;
    var Sampler: TLabSamplerShared;
    var MipLevels: TVkUInt32;
    constructor Create(const FileName: AnsiString);
    procedure Stage(const Cmd: TLabCommandBuffer);
  end;
  TTextureShared = specialize TLabSharedRef<TTexture>;

  TComputeUniform = packed record
    w, h: TVkFloat;
  end;
  PComputeUniform = ^TComputeUniform;

  TVertex = packed record
    pos: TLabVec2;
    vel: TLabVec2;
    scale: TLabVec4;
  end;
  TVertexArr = array[Word] of TVertex;
  PVertexArr = ^TVertexArr;

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
    var DepthBuffers: array of TLabDepthBufferShared;
    var FrameBuffers: array of TLabFrameBufferShared;
    var UniformBuffer: TLabUniformBufferShared;
    var DescriptorSetLayout: TLabDescriptorSetLayoutShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var RenderPass: TLabRenderPassShared;
    var VertexShader: TLabShaderShared;
    var PixelShader: TLabShaderShared;
    var VertexBuffer: TLabVertexBufferShared;
    var VertexBufferStaging: TLabBufferShared;
    var DescriptorPool: TLabDescriptorPoolShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineCache: TLabPipelineCacheShared;
    var ComputePipeline: TLabPipelineShared;
    var ComputePipelineLayout: TLabPipelineLayoutShared;
    var ComputeDescriptorPool: TLabDescriptorPoolShared;
    var ComputeDescriptorSetLayout: TLabDescriptorSetLayoutShared;
    var ComputeDescriptorSets: TLabDescriptorSetsShared;
    var ComputeShader: TLabComputeShaderShared;
    var ComputeUniformBuffer: TLabUniformBufferShared;
    var ParticleCount: TVkUInt32;
    var ComputeGroups: TVkUInt32;
    var UniformData: PLabMat;
    var ComputeUniformData: PComputeUniform;
    var Texture: TTextureShared;
    constructor Create;
    procedure SwapchainCreate;
    procedure SwapchainDestroy;
    procedure UpdateTransforms;
    procedure RunComputeShader;
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

constructor TTexture.Create(const FileName: AnsiString);
  var img: TLabImageData;
  var map: PVkVoid;
  var c: PLabColor;
  var x, y: TVkInt32;
begin
  img := TLabImageDataPNG.Create;
  img.Load(FileName);
  MipLevels := LabIntLog2(LabMakePOT(LabMax(img.Width, img.Height))) + 1;
  Image := TLabImage.Create(
    App.Device,
    VK_FORMAT_R8G8B8A8_UNORM,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    [], img.Width, img.Height, 1, MipLevels, 1, VK_SAMPLE_COUNT_1_BIT,
    VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  Staging := TLabBuffer.Create(
    App.Device, img.DataSize,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (Staging.Ptr.Map(map)) then
  begin
    if img.Format = idf_r8g8b8a8 then
    begin
      Move(img.Data^, map^, img.DataSize);
    end
    else
    begin
      c := PLabColor(map);
      for y := 0 to img.Height - 1 do
      for x := 0 to img.Width - 1 do
      begin
        c^ := img.Pixels[x, y];
        Inc(c);
      end;
    end;
    Staging.Ptr.Unmap;
  end;
  img.Free;
  View := TLabImageView.Create(
    App.Device, Image.Ptr.VkHandle, Image.Ptr.Format,
    TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
    0, MipLevels
  );
  Sampler := TLabSampler.Create(
    App.Device, VK_FILTER_LINEAR, VK_FILTER_LINEAR,
    VK_SAMPLER_ADDRESS_MODE_REPEAT, VK_SAMPLER_ADDRESS_MODE_REPEAT, VK_SAMPLER_ADDRESS_MODE_REPEAT,
    VK_TRUE, 16, VK_SAMPLER_MIPMAP_MODE_LINEAR,
    0, 0, MipLevels - 1
  );
end;

procedure TTexture.Stage(const Cmd: TLabCommandBuffer);
  var i, mip_src_width, mip_src_height, mip_dst_width, mip_dst_height: TVkUInt32;
begin
  if not Staging.IsValid then Exit;
  Cmd.PipelineBarrier(
    TVkFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
    TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
    0, [], [],
    [
      LabImageMemoryBarrier(
        Image.Ptr.VkHandle,
        VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        0, TVkFlags(VK_ACCESS_TRANSFER_WRITE_BIT),
        VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0, MipLevels
      )
    ]
  );
  Cmd.CopyBufferToImage(
    Staging.Ptr.VkHandle,
    Image.Ptr.VkHandle,
    VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    [
      LabBufferImageCopy(
        LabOffset3D(0, 0, 0),
        LabExtent3D(Image.Ptr.Width, Image.Ptr.Height, Image.Ptr.Depth),
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0
      )
    ]
  );
  mip_src_width := Image.Ptr.Width;
  mip_src_height := Image.Ptr.Height;
  if MipLevels > 1 then
  for i := 0 to MipLevels - 2 do
  begin
    mip_dst_width := mip_src_width shr 1; if mip_dst_width <= 0 then mip_dst_width := 1;
    mip_dst_height := mip_src_height shr 1; if mip_dst_height <= 0 then mip_dst_height := 1;
    Cmd.PipelineBarrier(
      TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
      TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
      0, [], [],
      [
        LabImageMemoryBarrier(
          Image.Ptr.VkHandle,
          VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
          TVkFlags(VK_ACCESS_TRANSFER_WRITE_BIT), TVkFlags(VK_ACCESS_TRANSFER_READ_BIT),
          VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), i
        )
      ]
    );
    Cmd.BlitImage(
      Image.Ptr.VkHandle,
      VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
      Image.Ptr.VkHandle,
      VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
      [
        LabImageBlit(
          LabOffset3D(0, 0, 0), LabOffset3D(mip_src_width, mip_src_height, 1),
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), i, 0, 1,
          LabOffset3D(0, 0, 0), LabOffset3D(mip_dst_width, mip_dst_height, 1),
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), i + 1, 0, 1
        )
      ]
    );
    Cmd.PipelineBarrier(
      TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
      TVkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
      0, [], [],
      [
        LabImageMemoryBarrier(
          Image.Ptr.VkHandle,
          VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          TVkFlags(VK_ACCESS_TRANSFER_READ_BIT), TVkFlags(VK_ACCESS_SHADER_READ_BIT),
          VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), i
        )
      ]
    );
    mip_src_width := mip_dst_width;
    mip_src_height := mip_dst_height;
  end;
  Cmd.PipelineBarrier(
    TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
    TVkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
    0, [], [],
    [
      LabImageMemoryBarrier(
        Image.Ptr.VkHandle,
        VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        TVkFlags(VK_ACCESS_TRANSFER_READ_BIT), TVkFlags(VK_ACCESS_SHADER_READ_BIT),
        VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), MipLevels - 1
      )
    ]
  );
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
    DepthBuffers[i] := TLabDepthBuffer.Create(Device, Window.Width, Window.Height);
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
  var i: Integer;
begin
  FrameBuffers := nil;
  DepthBuffers := nil;
  RenderPass := nil;
  SwapChain := nil;
end;

procedure TLabApp.UpdateTransforms;
begin
  if (Window.Width = 0) or (Window.Height = 0) then Exit;
  UniformData^ := LabMatScaling(2 / Window.Width, 2 / Window.Height, 1) * LabMatTranslation(-1, -1, 0);
end;

procedure TLabApp.RunComputeShader;
begin
  CmdBuffer.Ptr.RecordBegin;
  CmdBuffer.Ptr.BindPipeline(ComputePipeline.Ptr);
  CmdBuffer.Ptr.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_COMPUTE,
    ComputePipelineLayout.Ptr,
    0, 1, ComputeDescriptorSets.Ptr,
    []
  );
  CmdBuffer.Ptr.DispatchCompute(ComputeGroups, 1, 1);
  CmdBuffer.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyCompute,
    [CmdBuffer.Ptr.VkHandle],
    [],
    [],
    Fence.Ptr.VkHandle
  );
  Fence.Ptr.WaitFor;
  Fence.Ptr.Reset;
  {
  CmdBuffer.Ptr.RecordBegin;
  CmdBuffer.Ptr.CopyBuffer(
    ComputeBufferStaging.Ptr.VkHandle,
    ComputeBuffer.Ptr.VkHandle,
    LabBufferCopy(ComputeBuffer.Ptr.Size)
  );
  CmdBuffer.Ptr.PipelineBarrier(
    TVkFlags(VK_PIPELINE_STAGE_HOST_BIT),
    TVkFlags(VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT),
    0,
    [],
    [
      LabBufferMemoryBarrier(
        ComputeBuffer.Ptr.VkHandle,
        TVkFlags(VK_ACCESS_HOST_WRITE_BIT),
        TVkFlags(VK_ACCESS_SHADER_READ_BIT)
      )
    ],
    []
  );
  CmdBuffer.Ptr.BindPipeline(ComputePipeline.Ptr);
  CmdBuffer.Ptr.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_COMPUTE,
    ComputePipelineLayout.Ptr,
    0, 1, ComputeDescriptorSets.Ptr,
    []
  );
  CmdBuffer.Ptr.DispatchCompute(ComputeGroups, 1, 1);
  CmdBuffer.Ptr.PipelineBarrier(
    TVkFlags(VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT),
    TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
    0,
    [],
    [
      LabBufferMemoryBarrier(
        ComputeBuffer.Ptr.VkHandle,
        TVkFlags(VK_ACCESS_SHADER_WRITE_BIT),
        TVkFlags(VK_ACCESS_TRANSFER_READ_BIT)
      )
    ],
    []
  );
  CmdBuffer.Ptr.CopyBuffer(
    ComputeBuffer.Ptr.VkHandle,
    ComputeBufferStaging.Ptr.VkHandle,
    LabBufferCopy(ComputeBuffer.Ptr.Size)
  );
  CmdBuffer.Ptr.PipelineBarrier(
    TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
    TVkFlags(VK_PIPELINE_STAGE_HOST_BIT),
    0,
    [],
    [
      LabBufferMemoryBarrier(
        ComputeBufferStaging.Ptr.VkHandle,
        TVkFlags(VK_ACCESS_TRANSFER_WRITE_BIT),
        TVkFlags(VK_ACCESS_HOST_READ_BIT)
      )
    ],
    []
  );
  CmdBuffer.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyCompute,
    [CmdBuffer.Ptr.VkHandle],
    [],
    [],
    Fence.Ptr.VkHandle
  );
  Fence.Ptr.WaitFor;
  Fence.Ptr.Reset;
  }
end;

procedure TLabApp.TransferBuffers;
begin
  CmdBuffer.Ptr.RecordBegin;
  CmdBuffer.Ptr.CopyBuffer(VertexBufferStaging.Ptr.VkHandle, VertexBuffer.Ptr.VkHandle, [LabBufferCopy(VertexBuffer.Ptr.Size)]);
  Texture.Ptr.Stage(CmdBuffer.Ptr);
  CmdBuffer.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [CmdBuffer.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
  Texture.Ptr.Staging := nil;
  VertexBufferStaging := nil;
end;

procedure TLabApp.Initialize;
  var map: PVkVoid;
  var i: TVkInt32;
  var s: AnsiString;
  var v: TLabVec2;
begin
  ComputeGroups := 1024;
  ParticleCount := 256 * ComputeGroups;
  Window := TLabWindow.Create(500, 500);
  Window.Caption := 'Vulkan Compute';
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
  UniformBuffer := TLabUniformBuffer.Create(Device, SizeOf(TLabMat));
  UniformBuffer.Ptr.Map(UniformData);
  DescriptorSetLayout := TLabDescriptorSetLayout.Create(
    Device,
    [
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
    ]
  );
  PipelineLayout := TLabPipelineLayout.Create(Device, [], [DescriptorSetLayout]);
  VertexShader := TLabVertexShader.Create(Device, 'vs.spv');
  PixelShader := TLabPixelShader.Create(Device, 'ps.spv');
  ComputeShader := TLabComputeShader.Create(Device, 'cs.spv');
  VertexBuffer := TLabVertexBuffer.Create(
    Device,
    sizeof(TVertex) * ParticleCount,
    sizeof(TVertex),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32_SFLOAT, LabPtrToOrd(@TVertex( nil^ ).pos)),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32_SFLOAT, LabPtrToOrd(@TVertex( nil^ ).scale))
    ],
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT),
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
    for i := 0 to ParticleCount - 1 do
    begin
      PVertexArr(map)^[i].pos := LabVec2(Random(Window.Width), Random(Window.Height));
      PVertexArr(map)^[i].vel := LabRandomCirclePoint;
      PVertexArr(map)^[i].scale := LabVec4(16 + Random * 64, 0, 0, 0);
    end;
    VertexBufferStaging.Ptr.Unmap;
  end;
  Texture := TTexture.Create('../Images/flare.png');
  DescriptorPool := TLabDescriptorPool.Create(
    Device,
    [
      LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1),
      LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1)
    ],
    1
  );
  DescriptorSets := TLabDescriptorSets.Create(
    Device, DescriptorPool,
    [DescriptorSetLayout.Ptr.VkHandle]
  );
  DescriptorSets.Ptr.UpdateSets(
    [
      LabWriteDescriptorSetUniformBuffer(
        DescriptorSets.Ptr.VkHandle[0], 0,
        [LabDescriptorBufferInfo(UniformBuffer.Ptr.VkHandle)]
      ),
      LabWriteDescriptorSetImageSampler(
        DescriptorSets.Ptr.VkHandle[0], 1,
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
  PipelineCache := TLabPipelineCache.Create(Device);
  Pipeline := TLabGraphicsPipeline.Create(
    Device, PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [VertexShader.Ptr, PixelShader.Ptr],
    RenderPass.Ptr, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(
      VK_PRIMITIVE_TOPOLOGY_POINT_LIST
    ),
    LabPipelineVertexInputState(
      [VertexBuffer.Ptr.MakeBindingDesc(0)],
      [
        VertexBuffer.Ptr.MakeAttributeDesc(0, 0, 0),
        VertexBuffer.Ptr.MakeAttributeDesc(1, 1, 0)
      ]
    ),
    LabPipelineRasterizationState(
      VK_FALSE, VK_FALSE, VK_POLYGON_MODE_FILL,
      TVkFlags(VK_CULL_MODE_BACK_BIT), VK_FRONT_FACE_COUNTER_CLOCKWISE
    ),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState(
      [
        LabPipelineColorBlendAttachmentState(
          VK_TRUE,
          VK_BLEND_FACTOR_SRC_ALPHA, VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
          VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE
        )
      ], []
    ),
    LabPipelineTesselationState(0)
  );
  ComputeUniformBuffer := TLabUniformBuffer.Create(Device, SizeOf(TComputeUniform));
  ComputeUniformBuffer.Ptr.Map(ComputeUniformData);
  ComputeDescriptorSetLayout := TLabDescriptorSetLayout.Create(
    Device,
    [
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_COMPUTE_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_COMPUTE_BIT))
    ]
  );
  ComputePipelineLayout := TLabPipelineLayout.Create(
    Device, [], [ComputeDescriptorSetLayout]
  );
  ComputeDescriptorPool := TLabDescriptorPool.Create(
    Device,
    [
      LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1),
      LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1)
    ],
    1
  );
  ComputeDescriptorSets := TLabDescriptorSets.Create(
    Device, ComputeDescriptorPool, [ComputeDescriptorSetLayout.Ptr.VkHandle]
  );
  ComputeDescriptorSets.Ptr.UpdateSets(
    [
      LabWriteDescriptorSetStorageBuffer(
        ComputeDescriptorSets.Ptr.VkHandle[0], 0, LabDescriptorBufferInfo(VertexBuffer.Ptr.VkHandle)
      ),
      LabWriteDescriptorSetUniformBuffer(
        ComputeDescriptorSets.Ptr.VkHandle[0], 1, LabDescriptorBufferInfo(ComputeUniformBuffer.Ptr.VkHandle)
      )
    ],
    []
  );
  ComputePipeline := TLabComputePipeline.Create(
    Device, PipelineCache, ComputePipelineLayout.Ptr, ComputeShader,
    [
      LabSpecializationMapEntry(0, 0, SizeOf(ParticleCount))
    ],
    @ParticleCount, SizeOf(ParticleCount)
  );
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  TransferBuffers;
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  SwapchainDestroy;
  UniformBuffer.Ptr.Unmap;
  ComputeUniformBuffer.Ptr.Unmap;
  Fence := nil;
  ComputePipeline := nil;
  ComputePipelineLayout := nil;
  ComputeDescriptorSets := nil;
  ComputeDescriptorPool := nil;
  ComputeDescriptorSetLayout := nil;
  ComputeShader := nil;
  ComputeUniformBuffer := nil;
  Semaphore := nil;
  Pipeline := nil;
  PipelineCache := nil;
  DescriptorSets := nil;
  DescriptorPool := nil;
  Texture := nil;
  VertexBuffer := nil;
  PixelShader := nil;
  VertexShader := nil;
  PipelineLayout := nil;
  DescriptorSetLayout := nil;
  UniformBuffer := nil;
  CmdBuffer := nil;
  CmdPool := nil;
  Surface := nil;
  Device := nil;
  Window.Free;
  Free;
end;

procedure TLabApp.Loop;
  var cur_buffer: TVkUInt32;
  var r: TVkResult;
begin
  TLabVulkan.IsActive := Window.IsActive;
  if not TLabVulkan.IsActive
  or (Window.Mode = wm_minimized)
  or (Window.Width * Window.Height = 0) then Exit;
  if (SwapChain.Ptr.Width <> Window.Width)
  or (SwapChain.Ptr.Height <> Window.Height) then
  begin
    Device.Ptr.WaitIdle;
    SwapchainDestroy;
    SwapchainCreate;
  end;
  ComputeUniformData^.w := Window.Width;
  ComputeUniformData^.h := Window.Height;
  RunComputeShader;
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
    0, 1, DescriptorSets.Ptr, []
  );
  CmdBuffer.Ptr.BindVertexBuffers(0, [VertexBuffer.Ptr.VkHandle], [0]);
  CmdBuffer.Ptr.SetViewport([LabViewport(0, 0, Window.Width, Window.Height)]);
  CmdBuffer.Ptr.SetScissor([LabRect2D(0, 0, Window.Width, Window.Height)]);
  CmdBuffer.Ptr.Draw(ParticleCount);
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
