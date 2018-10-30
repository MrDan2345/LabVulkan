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
  LabPlatform,
  LabSync,
  LabUtils,
  LabImageData,
  Classes,
  SysUtils;

type
  TVertex0 = packed record
    Position: TLabVec3;
  end;
  TVertex1 = packed record
    Normal: TLabVec3;
    Color: TLabVec4;
    TexCoord0: TLabVec2;
  end;
  TVertex2 = packed record
    BoneIndex: array[0..1] of TVkUInt32;
    BoneWeight: array[0..1] of TVkFloat;
  end;
  TSkinUniform = packed record
    Bones: array[0..1] of TLabMat;
  end;
  PSkinUniform = ^TSkinUniform;

  TLabApp = class (TLabVulkan)
  public
    var Window: TLabWindow;
    var Device: TLabDeviceShared;
    var Surface: TLabSurfaceShared;
    var SwapChain: TLabSwapChainShared;
    var CmdPool: TLabCommandPoolShared;
    var Cmd: TLabCommandBufferShared;
    var Semaphore: TLabSemaphoreShared;
    var Fence: TLabFenceShared;
    var DepthBuffers: array of TLabDepthBufferShared;
    var FrameBuffers: array of TLabFrameBufferShared;
    var UniformBuffer: TLabUniformBufferShared;
    var UniformBufferSkin: TLabUniformBufferShared;
    var DescriptorSetLayout: TLabDescriptorSetLayoutShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var RenderPass: TLabRenderPassShared;
    var VertexShader: TLabShaderShared;
    var PixelShader: TLabShaderShared;
    var VertexBuffer: array [0..2] of TLabVertexBufferShared;
    var VertexBufferStaging: array [0..2] of TLabBufferShared;
    var IndexBuffer: TLabIndexBufferShared;
    var IndexBufferStaging: TLabBufferShared;
    var DescriptorPool: TLabDescriptorPoolShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineCache: TLabPipelineCacheShared;
    var Texture: record
      var Image: TLabImageShared;
      var Staging: TLabBufferShared;
      var View: TLabImageViewShared;
      var Sampler: TLabSamplerShared;
      var MipLevels: TVkUInt32;
    end;
    var Transforms: record
      World: TLabMat;
      View: TLabMat;
      Projection: TLabMat;
      WVP: TLabMat;
    end;
    var VertexStream0: array of TVertex0;
    var VertexStream1: array of TVertex1;
    var VertexStream2: array of TVertex2;
    var Indices: array of TVkUInt16;
    var SkinUniform: PSkinUniform;
    constructor Create;
    procedure SwapchainCreate;
    procedure SwapchainDestroy;
    procedure UpdateTransforms;
    procedure TransferBuffers;
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
    procedure GenerateVertices;
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
  SkinUniform^.Bones[0] := LabMatIdentity;
  SkinUniform^.Bones[1] := (
    LabMatTranslation(0, -2, 0) *
    LabMatRotationY(1.8 * sin(4 * LabTimeLoopSec(2 * LabTwoPi))) *
    LabMatRotationX(1.5 * sin(LabTimeLoopSec(LabTwoPi))) *
    LabMatTranslation(0, 2, 0)
  );
  fov := LabDegToRad * 20;
  with Transforms do
  begin
    Projection := LabMatProj(fov, Window.Width / Window.Height, 0.1, 100);
    View := LabMatView(LabVec3(0, 2, -20), LabVec3(0, 2, 0), LabVec3(0, 1, 0));
    World := LabMatRotationY((LabTimeLoopSec(5) / 5) * Pi * 2);
    // Vulkan clip space has inverted Y and half Z.
    Clip := LabMat(
      1, 0, 0, 0,
      0, -1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    );
    WVP := World * View * Projection * Clip;
  end;
end;

procedure TLabApp.TransferBuffers;
  var i: Integer;
  var mip_src_width, mip_src_height, mip_dst_width, mip_dst_height: TVkUInt32;
begin
  Cmd.Ptr.RecordBegin;
  for i := 0 to High(VertexBuffer) do
  begin
    Cmd.Ptr.CopyBuffer(
      VertexBufferStaging[i].Ptr.VkHandle,
      VertexBuffer[i].Ptr.VkHandle,
      [LabBufferCopy(VertexBuffer[i].Ptr.Size)]
    );
  end;
  Cmd.Ptr.CopyBuffer(
    IndexBufferStaging.Ptr.VkHandle,
    IndexBuffer.Ptr.VkHandle,
    [LabBufferCopy(IndexBuffer.Ptr.Size)]
  );
  Cmd.Ptr.PipelineBarrier(
    TVkFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
    TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
    0, [], [],
    [
      LabImageMemoryBarrier(
        Texture.Image.Ptr.VkHandle,
        VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        0, TVkFlags(VK_ACCESS_TRANSFER_WRITE_BIT),
        VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0, Texture.MipLevels
      )
    ]
  );
  Cmd.Ptr.CopyBufferToImage(
    Texture.Staging.Ptr.VkHandle,
    Texture.Image.Ptr.VkHandle,
    VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    [
      LabBufferImageCopy(
        LabOffset3D(0, 0, 0),
        LabExtent3D(Texture.Image.Ptr.Width, Texture.Image.Ptr.Height, Texture.Image.Ptr.Depth),
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0
      )
    ]
  );
  mip_src_width := Texture.Image.Ptr.Width;
  mip_src_height := Texture.Image.Ptr.Height;
  for i := 0 to Texture.MipLevels - 2 do
  begin
    mip_dst_width := mip_src_width shr 1; if mip_dst_width <= 0 then mip_dst_width := 1;
    mip_dst_height := mip_src_height shr 1; if mip_dst_height <= 0 then mip_dst_height := 1;
    Cmd.Ptr.PipelineBarrier(
      TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
      TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
      0, [], [],
      [
        LabImageMemoryBarrier(
          Texture.Image.Ptr.VkHandle,
          VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
          TVkFlags(VK_ACCESS_TRANSFER_WRITE_BIT), TVkFlags(VK_ACCESS_TRANSFER_READ_BIT),
          VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i)
        )
      ]
    );
    Cmd.Ptr.BlitImage(
      Texture.Image.Ptr.VkHandle,
      VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
      Texture.Image.Ptr.VkHandle,
      VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
      [
        LabImageBlit(
          LabOffset3D(0, 0, 0), LabOffset3D(mip_src_width, mip_src_height, 1),
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i), 0, 1,
          LabOffset3D(0, 0, 0), LabOffset3D(mip_dst_width, mip_dst_height, 1),
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i + 1), 0, 1
        )
      ]
    );
    Cmd.Ptr.PipelineBarrier(
      TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
      TVkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
      0, [], [],
      [
        LabImageMemoryBarrier(
          Texture.Image.Ptr.VkHandle,
          VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          TVkFlags(VK_ACCESS_TRANSFER_READ_BIT), TVkFlags(VK_ACCESS_SHADER_READ_BIT),
          VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i)
        )
      ]
    );
    mip_src_width := mip_dst_width;
    mip_src_height := mip_dst_height;
  end;
  Cmd.Ptr.PipelineBarrier(
    TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
    TVkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
    0, [], [],
    [
      LabImageMemoryBarrier(
        Texture.Image.Ptr.VkHandle,
        VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        TVkFlags(VK_ACCESS_TRANSFER_READ_BIT), TVkFlags(VK_ACCESS_SHADER_READ_BIT),
        VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), Texture.MipLevels - 1
      )
    ]
  );
  //Cmd.Ptr.PipelineBarrier(
  //  TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
  //  TVkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
  //  0, [], [],
  //  [
  //    LabImageMemoryBarrier(
  //      Texture.Image.Ptr.VkHandle,
  //      VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
  //      TVkFlags(VK_ACCESS_TRANSFER_WRITE_BIT), TVkFlags(VK_ACCESS_SHADER_READ_BIT),
  //      VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
  //      TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0, Texture.MipLevels
  //    )
  //  ]
  //);
  Cmd.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [Cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
  for i := 0 to High(VertexBuffer) do
  begin
    VertexBufferStaging[i] := nil;
  end;
  IndexBufferStaging := nil;
  Texture.Staging := nil;
end;

procedure TLabApp.Initialize;
  var map: PVkVoid;
  var img: TLabImageData;
begin
  Window := TLabWindow.Create(500, 500);
  Window.Caption := 'Vulkan Skin';
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
  UniformBuffer := TLabUniformBuffer.Create(Device, SizeOf(Transforms));
  UniformBufferSkin := TLabUniformBuffer.Create(Device, SizeOf(TSkinUniform));
  UniformBufferSkin.Ptr.Map(PVkVoid(SkinUniform));
  VertexShader := TLabVertexShader.Create(Device, 'vs.spv');
  PixelShader := TLabPixelShader.Create(Device, 'ps.spv');
  GenerateVertices;
  VertexBuffer[0] := TLabVertexBuffer.Create(
    Device,
    sizeof(TVertex0) * Length(VertexStream0),
    sizeof(TVertex0),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32_SFLOAT, LabPtrToOrd(@TVertex0( nil^ ).Position))
    ],
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexBufferStaging[0] := TLabBuffer.Create(
    Device, VertexBuffer[0].Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (VertexBufferStaging[0].Ptr.Map(map)) then
  begin
    Move(VertexStream0[0], map^, sizeof(TVertex0) * Length(VertexStream0));
    VertexBufferStaging[0].Ptr.Unmap;
  end;
  VertexBuffer[1] := TLabVertexBuffer.Create(
    Device,
    sizeof(TVertex1) * Length(VertexStream1),
    sizeof(TVertex1),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32_SFLOAT, LabPtrToOrd(@TVertex1( nil^ ).Normal)),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, LabPtrToOrd(@TVertex1( nil^ ).Color)),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32_SFLOAT, LabPtrToOrd(@TVertex1( nil^ ).TexCoord0))
    ],
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexBufferStaging[1] := TLabBuffer.Create(
    Device, VertexBuffer[1].Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (VertexBufferStaging[1].Ptr.Map(map)) then
  begin
    Move(VertexStream1[0], map^, sizeof(TVertex1) * Length(VertexStream1));
    VertexBufferStaging[1].Ptr.Unmap;
  end;
  VertexBuffer[2] := TLabVertexBuffer.Create(
    Device,
    sizeof(TVertex2) * Length(VertexStream2),
    sizeof(TVertex2),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32_UINT, LabPtrToOrd(@TVertex2( nil^ ).BoneIndex)),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32_SFLOAT, LabPtrToOrd(@TVertex2( nil^ ).BoneWeight))
    ],
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexBufferStaging[2] := TLabBuffer.Create(
    Device, VertexBuffer[2].Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (VertexBufferStaging[2].Ptr.Map(map)) then
  begin
    Move(VertexStream2[0], map^, sizeof(TVertex2) * Length(VertexStream2));
    VertexBufferStaging[2].Ptr.Unmap;
  end;
  IndexBuffer := TLabIndexBuffer.Create(
    Device,
    Length(Indices),
    VK_INDEX_TYPE_UINT16,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkFlags(VK_BUFFER_USAGE_INDEX_BUFFER_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  IndexBufferStaging := TLabBuffer.Create(
    Device, IndexBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if IndexBufferStaging.Ptr.Map(map) then
  begin
    Move(Indices[0], map^, Length(Indices) * SizeOf(Indices[0]));
    IndexBufferStaging.Ptr.Unmap;
  end;
  img := TLabImageDataPNG.Create;
  img.Load('../Images/box.png');
  Texture.MipLevels := LabIntLog2(LabMakePOT(LabMax(img.Width, img.Height))) + 1;
  Texture.Image := TLabImage.Create(
    Device,
    VK_FORMAT_R8G8B8A8_UNORM,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    [], img.Width, img.Height, 1, Texture.MipLevels, 1, VK_SAMPLE_COUNT_1_BIT,
    VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  Texture.Staging := TLabBuffer.Create(
    Device, img.DataSize,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (Texture.Staging.Ptr.Map(map)) then
  begin
    Move(img.Data^, map^, img.DataSize);
    Texture.Staging.Ptr.Unmap;
  end;
  img.Free;
  Texture.View := TLabImageView.Create(
    Device, Texture.Image.Ptr.VkHandle, Texture.Image.Ptr.Format,
    TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
    0, Texture.MipLevels
  );
  Texture.Sampler := TLabSampler.Create(
    Device, VK_FILTER_LINEAR, VK_FILTER_LINEAR,
    VK_SAMPLER_ADDRESS_MODE_REPEAT, VK_SAMPLER_ADDRESS_MODE_REPEAT, VK_SAMPLER_ADDRESS_MODE_REPEAT,
    VK_TRUE, 16, VK_SAMPLER_MIPMAP_MODE_LINEAR, 0, 0, Texture.MipLevels - 1
  );
  DescriptorSetLayout := TLabDescriptorSetLayout.Create(
    Device,
    [
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
      LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
    ]
  );
  DescriptorPool := TLabDescriptorPool.Create(
    Device,
    [
      LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1),
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
        DescriptorSets.Ptr.VkHandle[0],
        0,
        [LabDescriptorBufferInfo(UniformBuffer.Ptr.VkHandle)]
      ),
      LabWriteDescriptorSetUniformBuffer(
        DescriptorSets.Ptr.VkHandle[0],
        1,
        [LabDescriptorBufferInfo(UniformBufferSkin.Ptr.VkHandle)]
      ),
      LabWriteDescriptorSetImageSampler(
        DescriptorSets.Ptr.VkHandle[0],
        2,
        [
          LabDescriptorImageInfo(
            VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            Texture.View.Ptr.VkHandle,
            Texture.Sampler.Ptr.VkHandle
          )
        ]
      )
    ],
    []
  );
  PipelineCache := TLabPipelineCache.Create(Device);
  PipelineLayout := TLabPipelineLayout.Create(Device, [], [DescriptorSetLayout]);
  Pipeline := TLabGraphicsPipeline.Create(
    Device, PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [VertexShader.Ptr, PixelShader.Ptr],
    RenderPass.Ptr, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(
      VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
    ),
    LabPipelineVertexInputState(
      [
        VertexBuffer[0].Ptr.MakeBindingDesc(0),
        VertexBuffer[1].Ptr.MakeBindingDesc(1),
        VertexBuffer[2].Ptr.MakeBindingDesc(2)
      ],
      [
        VertexBuffer[0].Ptr.MakeAttributeDesc(0, 0, 0),
        VertexBuffer[1].Ptr.MakeAttributeDesc(0, 1, 1),
        VertexBuffer[1].Ptr.MakeAttributeDesc(1, 2, 1),
        VertexBuffer[1].Ptr.MakeAttributeDesc(2, 3, 1),
        VertexBuffer[2].Ptr.MakeAttributeDesc(0, 4, 2),
        VertexBuffer[2].Ptr.MakeAttributeDesc(1, 5, 2)
      ]
    ),
    LabPipelineRasterizationState(
      VK_FALSE, VK_FALSE, VK_POLYGON_MODE_FILL
    ),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment], [])
  );
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  TransferBuffers;
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  SwapchainDestroy;
  UniformBufferSkin.Ptr.Unmap;
  UniformBufferSkin := nil;
  Texture.Sampler := nil;
  Texture.View := nil;
  Texture.Image := nil;
  Fence := nil;
  Semaphore := nil;
  Pipeline := nil;
  PipelineCache := nil;
  DescriptorSets := nil;
  DescriptorPool := nil;
  IndexBuffer := nil;
  VertexBuffer[0] := nil;
  VertexBuffer[1] := nil;
  VertexBuffer[2] := nil;
  PixelShader := nil;
  VertexShader := nil;
  PipelineLayout := nil;
  DescriptorSetLayout := nil;
  UniformBuffer := nil;
  Cmd := nil;
  CmdPool := nil;
  Surface := nil;
  Device := nil;
  Window.Free;
  Free;
end;

procedure TLabApp.Loop;
  var UniformData: PVkUInt8;
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
  UpdateTransforms;
  UniformData := nil;
  if (UniformBuffer.Ptr.Map(UniformData)) then
  begin
    Move(Transforms, UniformData^, SizeOf(Transforms));
    UniformBuffer.Ptr.Unmap;
  end;
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
    0, 1, DescriptorSets.Ptr, []
  );
  Cmd.Ptr.BindVertexBuffers(
    0,
    [
      VertexBuffer[0].Ptr.VkHandle,
      VertexBuffer[1].Ptr.VkHandle,
      VertexBuffer[2].Ptr.VkHandle
    ], [0, 0, 0]
  );
  Cmd.Ptr.BindIndexBuffer(IndexBuffer.Ptr.VkHandle);
  Cmd.Ptr.SetViewport([LabViewport(0, 0, Window.Width, Window.Height)]);
  Cmd.Ptr.SetScissor([LabRect2D(0, 0, Window.Width, Window.Height)]);
  Cmd.Ptr.DrawIndexed(Length(Indices));
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

procedure TLabApp.GenerateVertices;
  const segment_count = 24;
  const section_count = 16;
  const cap_section_count = 8;
  const radius = 1;
  const size = 4;
  var i, j, v, n: TVkInt32;
  var a, va, t, h: TVkFloat;
begin
  v := segment_count * (cap_section_count + 1) * 2 + (section_count - 1) * segment_count;
  SetLength(VertexStream0, v);
  SetLength(VertexStream1, v);
  SetLength(VertexStream2, v);
  for j := 0 to segment_count - 1 do
  begin
    VertexStream0[j].Position.x := 0;
    VertexStream0[j].Position.y := -radius;
    VertexStream0[j].Position.z := 0;
    VertexStream1[j].Normal := LabVec3(0, -1, 0);
    VertexStream1[j].Color := LabVec4(0, 0, 0, 1);
    t := (j * 2) / segment_count;
    if t > 1 then t := 2 - t;
    VertexStream1[j].TexCoord0 := LabVec2(t, 0);
    VertexStream2[j].BoneIndex[0] := 0;
    VertexStream2[j].BoneIndex[1] := 1;
    VertexStream2[j].BoneWeight[0] := 1;
    VertexStream2[j].BoneWeight[1] := 0;
  end;
  for i := 1 to cap_section_count - 1 do
  for j := 0 to segment_count - 1 do
  begin
    v := i * segment_count + j;
    a := (j / segment_count) * LabTwoPi;
    va := (i / cap_section_count) * LabHalfPi - LabHalfPi;
    h := i / (cap_section_count * 2 + section_count);
    VertexStream0[v].Position.x := cos(a) * radius * cos(va);
    VertexStream0[v].Position.z := sin(a) * radius * cos(va);
    VertexStream0[v].Position.y := radius * ((i / cap_section_count) - 1);
    VertexStream1[v].Normal := VertexStream0[v].Position.Norm;
    VertexStream1[v].Color := LabVec4(h, 0, 0, 1);
    t := (j * 2) / segment_count;
    if t > 1 then t := 2 - t;
    VertexStream1[v].TexCoord0 := LabVec2(t, h);
    VertexStream2[v].BoneIndex[0] := 0;
    VertexStream2[v].BoneIndex[1] := 1;
    VertexStream2[v].BoneWeight[0] := 1;
    VertexStream2[v].BoneWeight[1] := 0;
  end;
  for i := 0 to section_count - 1 do
  for j := 0 to segment_count - 1 do
  begin
    v := cap_section_count * segment_count + i * segment_count + j;
    a := (j / segment_count) * LabTwoPi;
    h := (i + cap_section_count) / (cap_section_count * 2 + section_count);
    VertexStream0[v].Position.x := cos(a) * radius;
    VertexStream0[v].Position.z := sin(a) * radius;
    VertexStream0[v].Position.y := (i / section_count) * size;
    VertexStream1[v].Normal := VertexStream0[v].Position;
    VertexStream1[v].Normal.y := 0;
    VertexStream1[v].Normal := VertexStream1[v].Normal.Norm;
    VertexStream1[v].Color := LabVec4(h, 0, 0, 1);
    t := (j * 2) / segment_count;
    if t > 1 then t := 2 - t;
    VertexStream1[v].TexCoord0 := LabVec2(t, h);
    VertexStream2[v].BoneIndex[0] := 0;
    VertexStream2[v].BoneIndex[1] := 1;
    VertexStream2[v].BoneWeight[0] := 1 - (i / section_count);
    VertexStream2[v].BoneWeight[1] := (i / section_count);
  end;
  for i := 0 to cap_section_count - 1 do
  for j := 0 to segment_count - 1 do
  begin
    v := cap_section_count * segment_count + section_count * segment_count + i * segment_count + j;
    a := (j / segment_count) * LabTwoPi;
    va := (i / cap_section_count) * LabHalfPi + LabHalfPi;
    h := (i + cap_section_count + section_count) / (cap_section_count * 2 + section_count);
    VertexStream0[v].Position.x := cos(a) * radius * sin(va);
    VertexStream0[v].Position.z := sin(a) * radius * sin(va);
    VertexStream0[v].Position.y := size + radius * (i / cap_section_count);
    VertexStream1[v].Normal := (VertexStream0[v].Position - LabVec3(0, size, 0)).Norm;
    VertexStream1[v].Color := LabVec4(h, 0, 0, 1);
    t := (j * 2) / segment_count;
    if t > 1 then t := 2 - t;
    VertexStream1[v].TexCoord0 := LabVec2(t, h);
    VertexStream2[v].BoneIndex[0] := 0;
    VertexStream2[v].BoneIndex[1] := 1;
    VertexStream2[v].BoneWeight[0] := 0;
    VertexStream2[v].BoneWeight[1] := 1;
  end;
  for j := 0 to segment_count - 1 do
  begin
    v := 2 * (cap_section_count * segment_count) + section_count * segment_count + j;
    VertexStream0[v].Position.x := 0;
    VertexStream0[v].Position.y := size + radius;
    VertexStream0[v].Position.z := 0;
    VertexStream1[v].Normal := LabVec3(0, 1, 0);
    VertexStream1[v].Color := LabVec4(1, 0, 0, 1);
    t := (j * 2) / segment_count;
    if t > 1 then t := 2 - t;
    VertexStream1[v].TexCoord0 := LabVec2(t, 1);
    VertexStream2[v].BoneIndex[0] := 0;
    VertexStream2[v].BoneIndex[1] := 1;
    VertexStream2[v].BoneWeight[0] := 0;
    VertexStream2[v].BoneWeight[1] := 1;
  end;
  v := (segment_count * 3 * 2 + (segment_count * (cap_section_count - 1) * 6 * 2)) + segment_count * section_count * 6;
  SetLength(Indices, v);
  n := 0;
  for i := 0 to segment_count - 1 do
  begin
    Indices[n] := i; Inc(n);
    Indices[n] := segment_count + i; Inc(n);
    Indices[n] := segment_count + ((i + 1) mod segment_count); Inc(n);
  end;
  for i := 0 to cap_section_count * 2 + section_count - 3 do
  for j := 0 to segment_count - 1 do
  begin
    v := (i + 1) * segment_count;
    Indices[n] := v + j; Inc(n);
    Indices[n] := v + segment_count + j; Inc(n);
    Indices[n] := v + segment_count + ((j + 1) mod segment_count); Inc(n);
    Indices[n] := v + j; Inc(n);
    Indices[n] := v + segment_count + ((j + 1) mod segment_count); Inc(n);
    Indices[n] := v + ((j + 1) mod segment_count); Inc(n);
  end;
  v := cap_section_count * segment_count + section_count * segment_count + (cap_section_count - 1) * segment_count;
  for i := 0 to segment_count - 1 do
  begin
    Indices[n] := v + i; Inc(n);
    Indices[n] := v + segment_count + i; Inc(n);
    Indices[n] := v + ((i + 1) mod segment_count); Inc(n);
  end;
  for i := 0 to High(VertexStream1) do
  begin
    VertexStream1[i].Color.y := VertexStream1[i].Color.x;
    VertexStream1[i].Color.z := VertexStream1[i].Color.x;
  end;
end;

end.
