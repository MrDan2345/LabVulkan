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
  LabScene,
  LabFrameBuffer,
  LabPlatform,
  LabSync,
  LabUtils,
  LabImageData,
  Classes,
  SysUtils;

type
  TTexture = class (TLabClass)
    var Image: TLabImageShared;
    var Staging: TLabBufferShared;
    var View: TLabImageViewShared;
    var Sampler: TLabSamplerShared;
    var MipLevels: TVkUInt32;
    constructor Create(const FileName: String);
    procedure Stage(const Cmd: TLabCommandBuffer);
  end;
  TTextureShared = specialize TLabSharedRef<TTexture>;

  TLightData = object
    type TLightVertex = packed record
      x, y, z: TVkFloat;
    end;
    const light_vertices: array[0..5] of TLightVertex = (
      (x:0; y:1; z:0), (x:1; y:0; z:0), (x:0; y:0; z:1), (x:-1; y:0; z:0), (x:0; y:0; z:-1), (x:0; y:-1; z:0)
    );
    const light_indices: array[0..23] of TVkUInt16 = (
      0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1,
      1, 4, 5, 4, 3, 5, 3, 2, 5, 2, 1, 5
    );
    var VertexBuffer: TLabVertexBufferShared;
    var VertexStaging: TLabBufferShared;
    var IndexBuffer: TLabIndexBufferShared;
    var IndexStaging: TLabIndexBufferShared;
    var VertexShader: TLabVertexShaderShared;
    var TessControlShader: TLabTessControlShaderShared;
    var TessEvalShader: TLabTessEvaluationShaderShared;
    var PixelShader: TLabPixelShaderShared;
    procedure Setup;
  end;

  TRenderTarget = object
    var Image: TLabImageShared;
    var View: TLabImageViewShared;
    procedure SetupImage(
      const Format: TVkFormat;
      const Usage: TVkImageUsageFlags
    );
  end;

  TFullscreenQuad = class
    type TScreenVertex = packed record
      x, y, z, w: TVkFloat;
      u, v: TVkFloat;
    end;
    type TUniforms = packed record
      ScreenSize: TLabVec4;
      RTSize: TLabVec4;
      VP_i: TLabMat;
    end;
    type PUniforms = ^TUniforms;
    var QuadData: array[0..3] of TScreenVertex;
    var UniformBuffer: TLabUniformBufferShared;
    var VertexBuffer: TLabVertexBufferShared;
    var VertexBufferStaging: TLabBufferShared;
    var IndexBuffer: TLabIndexBufferShared;
    var IndexBufferStaging: TLabBufferShared;
    var VertexShader: TLabVertexShaderShared;
    var PixelShader: TLabPixelShaderShared;
    var Sampler: TLabSamplerShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var Uniforms: PUniforms;
    constructor Create;
    destructor Destroy; override;
    procedure Stage(const Cmd: TLabCommandBuffer);
    procedure Draw(const Cmd: TLabCommandBuffer);
    procedure BindOffscreenTargets;
    procedure Resize(const Cmd: TLabCommandBuffer);
    procedure UpdateUniforms;
    class function ScreenVertex(const x, y, z, w, u, v: TVkFloat): TScreenVertex; inline;
  end;

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
    var OffscreenTargets: array of record
      Depth: TRenderTarget;
      Color: TRenderTarget;
      Normals: TRenderTarget;
      ZBuffer: TLabDepthBufferShared;
      FrameBuffer: TLabFrameBufferShared;
    end;
    var DepthBuffers: array of TLabDepthBufferShared;
    var FrameBuffers: array of TLabFrameBufferShared;
    var UniformBuffer: TLabUniformBufferShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var RenderPass: TLabRenderPassShared;
    var RenderPassOffscreen: TLabRenderPassShared;
    var VertexShader: TLabShaderShared;
    var PixelShader: TLabShaderShared;
    var VertexBuffer: TLabVertexBufferShared;
    var VertexBufferStaging: TLabBufferShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var DescriptorSetsFactory: TLabDescriptorSetsFactoryShared;
    var PipelineCache: TLabPipelineCacheShared;
    var TextureColor: TTextureShared;
    var TextureNormal: TTextureShared;
    var Transforms: record
      World: TLabMat;
      View: TLabMat;
      Projection: TLabMat;
      WVP: TLabMat;
    end;
    var ScreenQuad: TFullscreenQuad;
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
  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

var
  App: TLabApp;

implementation

constructor TTexture.Create(const FileName: String);
  var img: TLabImageDataPNG;
  var map: PVkVoid;
  var c: PLabColor;
  var x, y: TVkInt32;
begin
  img := TLabImageDataPNG.Create;
  img.Load('../Images/' + FileName);
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
    App.Device, Image.Ptr.DataSize,
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
    VK_TRUE, 16, VK_SAMPLER_MIPMAP_MODE_LINEAR, 0, 0, MipLevels - 1
  );
end;

procedure TTexture.Stage(const Cmd: TLabCommandBuffer);
  var mip_src_width, mip_src_height, mip_dst_width, mip_dst_height, i: TVkUInt32;
begin
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
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i)
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
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i), 0, 1,
          LabOffset3D(0, 0, 0), LabOffset3D(mip_dst_width, mip_dst_height, 1),
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i + 1), 0, 1
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
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i)
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

procedure TLightData.Setup;
begin
  VertexBuffer := TLabVertexBuffer.Create(
    App.Device,
    SizeOf(light_vertices), SizeOf(TLightVertex),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32_SFLOAT, 0)
    ],
    TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexStaging := TLabBuffer.Create(
    App.Device,
    VertexBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
    [],
    VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  IndexBuffer := TLabIndexBuffer.Create(
    App.Device, Length(light_indices), VK_INDEX_TYPE_UINT16,
    TVkFlags(VK_BUFFER_USAGE_INDEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  IndexStaging := TLabBuffer.Create(
    App.Device, IndexBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
    [],
    VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
end;

constructor TFullscreenQuad.Create;
  var Map: PVkVoid;
  var rt_w, rt_h, i: TVkUInt32;
  var u, v: TLabFloat;
begin
  rt_w := LabMakePOT(LabMax(App.SwapChain.Ptr.Width, 1));
  rt_h := LabMakePOT(LabMax(App.SwapChain.Ptr.Height, 1));
  u := App.SwapChain.Ptr.Width / rt_w;
  v := App.SwapChain.Ptr.Height / rt_h;
  QuadData[0] := ScreenVertex(-1, -1, 0.5, 1, 0, 0);
  QuadData[1] := ScreenVertex(1, -1, 0.5, 1, u, 0);
  QuadData[2] := ScreenVertex(-1, 1, 0.5, 1, 0, v);
  QuadData[3] := ScreenVertex(1, 1, 0.5, 1, u, v);
  VertexBuffer := TLabVertexBuffer.Create(
    App.Device,
    SizeOf(QuadData), SizeOf(TScreenVertex),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, LabPtrToOrd(@TScreenVertex( nil^ ).x)),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32_SFLOAT, LabPtrToOrd(@TScreenVertex( nil^ ).u))
    ],
    TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexBufferStaging := TLabBuffer.Create(
    App.Device,
    VertexBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
    [],
    VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  Map := nil;
  if VertexBufferStaging.Ptr.Map(Map) then
  begin
    Move(QuadData, Map^, VertexBuffer.Ptr.Size);
    VertexBufferStaging.Ptr.Unmap;
    VertexBufferStaging.Ptr.FlushAll;
  end;
  IndexBuffer := TLabIndexBuffer.Create(
    App.Device, Length(fullscreen_quad_ib),
    VK_INDEX_TYPE_UINT16,
    TVkFlags(VK_BUFFER_USAGE_INDEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  IndexBufferStaging := TLabBuffer.Create(
    App.Device, IndexBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
    [],
    VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  if IndexBufferStaging.Ptr.Map(Map) then
  begin
    Move(fullscreen_quad_ib, Map^, IndexBuffer.Ptr.Size);
    IndexBufferStaging.Ptr.Unmap;
    IndexBufferStaging.Ptr.FlushAll;
  end;
  Sampler := TLabSampler.Create(
    App.Device, VK_FILTER_NEAREST, VK_FILTER_NEAREST,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
  );
  UniformBuffer := TLabUniformBuffer.Create(App.Device, SizeOf(Uniforms));
  UniformBuffer.Ptr.Map(Uniforms);
  UpdateUniforms;
  VertexShader := TLabVertexShader.Create(
    App.Device, 'fullscreen_vs.spv'
  );
  PixelShader := TLabPixelShader.Create(
    App.Device, 'fullscreen_ps.spv'
  );
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings([
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT) or TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(3, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
    ], App.SwapChain.Ptr.ImageCount)
  ]);
  for i := 0 to App.SwapChain.Ptr.ImageCount - 1 do
  begin
    DescriptorSets.Ptr.UpdateSets(
      [
        LabWriteDescriptorSetUniformBuffer(
          DescriptorSets.Ptr.VkHandle[i], 0,
          [LabDescriptorBufferInfo(UniformBuffer.Ptr.VkHandle)]
        )
      ], []
    );
  end;
  PipelineLayout := TLabPipelineLayout.Create(App.Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]);
  Pipeline := TLabGraphicsPipeline.Create(
    App.Device, App.PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [VertexShader.Ptr, PixelShader.Ptr],
    App.RenderPass.Ptr, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState(
      [VertexBuffer.Ptr.MakeBindingDesc(0)],
      VertexBuffer.Ptr.MakeAttributeDescArr(0, 0)
    ),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment], []),
    LabPipelineTesselationState(0)
  );
  BindOffscreenTargets;
end;

destructor TFullscreenQuad.Destroy;
begin
  UniformBuffer.Ptr.Unmap;
  inherited Destroy;
end;

procedure TFullscreenQuad.Stage(const Cmd: TLabCommandBuffer);
begin
  Cmd.CopyBuffer(
    VertexBufferStaging.Ptr.VkHandle,
    VertexBuffer.Ptr.VkHandle,
    [LabBufferCopy(VertexBuffer.Ptr.Size)]
  );
  Cmd.CopyBuffer(
    IndexBufferStaging.Ptr.VkHandle,
    IndexBuffer.Ptr.VkHandle,
    [LabBufferCopy(IndexBuffer.Ptr.Size)]
  );
end;

procedure TFullscreenQuad.Draw(const Cmd: TLabCommandBuffer);
begin
  Cmd.BindPipeline(Pipeline.Ptr);
  Cmd.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[App.SwapChain.Ptr.CurImage]], []
  );
  Cmd.BindVertexBuffers(0, [VertexBuffer.Ptr.VkHandle], [0]);
  Cmd.BindIndexBuffer(IndexBuffer.Ptr.VkHandle);
  Cmd.DrawIndexed(IndexBuffer.Ptr.IndexCount);
end;

procedure TFullscreenQuad.BindOffscreenTargets;
  var i: TVkInt32;
  var Writes: array of TLabWriteDescriptorSet;
begin
  SetLength(Writes, App.SwapChain.Ptr.ImageCount * 3);
  for i := 0 to App.SwapChain.Ptr.ImageCount - 1 do
  begin
    Writes[i * 3 + 0] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      1,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.OffscreenTargets[i].Depth.View.Ptr.VkHandle,
          Sampler.Ptr.VkHandle
        )
      ]
    );
    Writes[i * 3 + 1] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      2,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.OffscreenTargets[i].Color.View.Ptr.VkHandle,
          //App.Texture.View.Ptr.VkHandle,
          Sampler.Ptr.VkHandle
        )
      ]
    );
    Writes[i * 3 + 2] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      3,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.OffscreenTargets[i].Normals.View.Ptr.VkHandle,
          Sampler.Ptr.VkHandle
        )
      ]
    );
  end;
  DescriptorSets.Ptr.UpdateSets(Writes, []);
end;

procedure TFullscreenQuad.Resize(const Cmd: TLabCommandBuffer);
  var rt_w, rt_h: TVkUInt32;
  var u, v: TVkFloat;
  var map: PVkVoid;
begin
  rt_w := LabMakePOT(LabMax(App.SwapChain.Ptr.Width, 1));
  rt_h := LabMakePOT(LabMax(App.SwapChain.Ptr.Height, 1));
  u := App.SwapChain.Ptr.Width / rt_w;
  v := App.SwapChain.Ptr.Height / rt_h;
  Uniforms^.ScreenSize.x := App.SwapChain.Ptr.Width;
  Uniforms^.ScreenSize.y := App.SwapChain.Ptr.Height;
  Uniforms^.ScreenSize.z := 1 / App.SwapChain.Ptr.Width;
  Uniforms^.ScreenSize.w := 1 / App.SwapChain.Ptr.Height;
  QuadData[1].u := u;
  QuadData[2].v := v;
  QuadData[3].u := u;
  QuadData[3].v := v;
  map := nil;
  if VertexBufferStaging.Ptr.Map(map) then
  begin
    Move(QuadData, map^, VertexBuffer.Ptr.Size);
    VertexBufferStaging.Ptr.Unmap;
    VertexBufferStaging.Ptr.FlushAll;
  end;
  Cmd.RecordBegin;
  Cmd.CopyBuffer(
    VertexBufferStaging.Ptr.VkHandle,
    VertexBuffer.Ptr.VkHandle,
    [LabBufferCopy(VertexBuffer.Ptr.Size)]
  );
  Cmd.RecordEnd;
  App.QueueSubmit(
    App.SwapChain.Ptr.QueueFamilyGraphics,
    [Cmd.VkHandle],
    [],
    [],
    VK_NULL_HANDLE
  );
  App.QueueWaitIdle(App.SwapChain.Ptr.QueueFamilyGraphics);
end;

procedure TFullscreenQuad.UpdateUniforms;
  var rt_w, rt_h: TVkUInt32;
begin
  rt_w := LabMakePOT(LabMax(App.SwapChain.Ptr.Width, 1));
  rt_h := LabMakePOT(LabMax(App.SwapChain.Ptr.Height, 1));
  Uniforms^.ScreenSize.x := App.SwapChain.Ptr.Width;
  Uniforms^.ScreenSize.y := App.SwapChain.Ptr.Height;
  Uniforms^.ScreenSize.z := 1 / App.SwapChain.Ptr.Width;
  Uniforms^.ScreenSize.w := 1 / App.SwapChain.Ptr.Height;
  Uniforms^.RTSize.x := rt_w;
  Uniforms^.RTSize.y := rt_h;
  Uniforms^.RTSize.z := 1 / rt_w;
  Uniforms^.RTSize.w := 1 / rt_h;
end;

class function TFullscreenQuad.ScreenVertex(const x, y, z, w, u, v: TVkFloat): TScreenVertex;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
  Result.w := w;
  Result.u := u;
  Result.v := v;
end;

procedure TRenderTarget.SetupImage(
  const Format: TVkFormat;
  const Usage: TVkImageUsageFlags
);
  var rt_w, rt_h: TVkUInt32;
begin
  rt_w := LabMakePOT(LabMax(App.SwapChain.Ptr.Width, 1));
  rt_h := LabMakePOT(LabMax(App.SwapChain.Ptr.Height, 1));
  Image := TLabImage.Create(
    App.Device, Format, Usage or TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT), [],
    rt_w, rt_h, 1, 1, 1, VK_SAMPLE_COUNT_1_BIT, VK_IMAGE_TILING_OPTIMAL,
    VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE, TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  View := TLabImageView.Create(
    App.Device, Image.Ptr.VkHandle,
    Image.Ptr.Format
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
  var rt_w, rt_h: TVkInt32;
begin
  SwapChain := TLabSwapChain.Create(Device, Surface);
  SetLength(DepthBuffers, SwapChain.Ptr.ImageCount);
  for i := 0 to SwapChain.Ptr.ImageCount - 1 do
  begin
    DepthBuffers[i] := TLabDepthBuffer.Create(Device, Window.Width, Window.Height);
  end;
  rt_w := LabMakePOT(LabMax(App.SwapChain.Ptr.Width, 1));
  rt_h := LabMakePOT(LabMax(App.SwapChain.Ptr.Height, 1));
  SetLength(OffscreenTargets, SwapChain.Ptr.ImageCount);
  for i := 0 to SwapChain.Ptr.ImageCount - 1 do
  begin
    OffscreenTargets[i].Depth.SetupImage(VK_FORMAT_R32_SFLOAT, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT));
    OffscreenTargets[i].Color.SetupImage(VK_FORMAT_R8G8B8A8_UNORM, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT));
    OffscreenTargets[i].Normals.SetupImage(VK_FORMAT_R8G8B8A8_SNORM, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT));
    OffscreenTargets[i].ZBuffer := TLabDepthBuffer.Create(
      App.Device, rt_w, rt_h, VK_FORMAT_UNDEFINED,
      TVkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT)
    );
  end;
  RenderPassOffscreen := TLabRenderPass.Create(
    Device,
    [
      LabAttachmentDescription(
        OffscreenTargets[0].Depth.Image.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      ),
      LabAttachmentDescription(
        OffscreenTargets[0].Color.Image.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      ),
      LabAttachmentDescription(
        OffscreenTargets[0].Normals.Image.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      ),
      LabAttachmentDescription(
        OffscreenTargets[0].ZBuffer.Ptr.Format,
        VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      )
    ],
    [
      LabSubpassDescriptionData(
        [],
        [
          LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(1, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(2, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
        ],
        [],
        LabAttachmentReference(3, VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL),
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
    ],
    [
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
      [
        SwapChain.Ptr.Images[i]^.View.VkHandle,
        DepthBuffers[i].Ptr.View.VkHandle
      ]
    );
    OffscreenTargets[i].FrameBuffer := TLabFrameBuffer.Create(
      Device, RenderPassOffscreen.Ptr,
      SwapChain.Ptr.Width, SwapChain.Ptr.Height,
      [
        OffscreenTargets[i].Depth.View.Ptr.VkHandle,
        OffscreenTargets[i].Color.View.Ptr.VkHandle,
        OffscreenTargets[i].Normals.View.Ptr.VkHandle,
        OffscreenTargets[i].ZBuffer.Ptr.View.VkHandle
      ]
    );
  end;
end;

procedure TLabApp.SwapchainDestroy;
begin
  RenderPass := nil;
  RenderPassOffscreen := nil;
  OffscreenTargets := nil;
  FrameBuffers := nil;
  DepthBuffers := nil;
  SwapChain := nil;
end;

procedure TLabApp.UpdateTransforms;
  var fov: TVkFloat;
  var Clip: TLabMat;
begin
  fov := LabDegToRad * 20;
  with Transforms do
  begin
    Projection := LabMatProj(fov, Window.Width / Window.Height, 0.1, 100);
    View := LabMatView(LabVec3(-5, 8, -10), LabVec3, LabVec3(0, 1, 0));
    World := LabMatRotationY((LabTimeLoopSec(5) / 5) * Pi * 2);
    Clip := LabMat(
      1, 0, 0, 0,
      0, -1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    );
    WVP := World * View * Projection * Clip;
  end;
  ScreenQuad.Uniforms^.VP_i := (Transforms.View * Transforms.Projection * Clip).Inverse;
end;

procedure TLabApp.TransferBuffers;
  var i: Integer;
  var mip_src_width, mip_src_height, mip_dst_width, mip_dst_height: TVkUInt32;
begin
  Cmd.Ptr.RecordBegin;
  Cmd.Ptr.CopyBuffer(
    VertexBufferStaging.Ptr.VkHandle,
    VertexBuffer.Ptr.VkHandle,
    [LabBufferCopy(VertexBuffer.Ptr.Size)]
  );
  TextureColor.Ptr.Stage(Cmd.Ptr);
  TextureNormal.Ptr.Stage(Cmd.Ptr);
  ScreenQuad.Stage(Cmd.Ptr);
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
  TextureColor.Ptr.Staging := nil;
end;

procedure TLabApp.Initialize;
  var map: PVkVoid;
  var img: TLabImageData;
begin
  Window := TLabWindow.Create(500, 500);
  Window.Caption := 'Vulkan Deferred';
  Device := TLabDevice.Create(
    PhysicalDevices[0],
    [
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT)))
    ],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  Surface := TLabSurface.Create(Window);
  DescriptorSetsFactory := TLabDescriptorSetsFactory.Create(Device);
  SwapChainCreate;
  CmdPool := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexGraphics);
  Cmd := TLabCommandBuffer.Create(CmdPool);
  UniformBuffer := TLabUniformBuffer.Create(Device, SizeOf(Transforms));
  //VertexShader := TLabVertexShader.Create(Device, @Bin_vs, SizeOf(Bin_vs));
  //PixelShader := TLabPixelShader.Create(Device, @Bin_ps, SizeOf(Bin_ps));
  VertexShader := TLabVertexShader.Create(Device, 'vs.spv');
  PixelShader := TLabPixelShader.Create(Device, 'ps.spv');
  VertexBuffer := TLabVertexBuffer.Create(
    Device,
    sizeof(g_vb_solid_face_colors_Data),
    sizeof(g_vb_solid_face_colors_Data[0]),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, LabPtrToOrd(@TVertex( nil^ ).x) ),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32_SFLOAT, LabPtrToOrd(@TVertex( nil^ ).nx) ),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32_SFLOAT, LabPtrToOrd(@TVertex( nil^ ).tx) ),
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
  TextureColor := TTexture.Create('crate_c.png');
  TextureNormal := TTexture.Create('crate_n.png');
  DescriptorSets := DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings([
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
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
            TextureColor.Ptr.View.Ptr.VkHandle,
            TextureColor.Ptr.Sampler.Ptr.VkHandle
          )
        ]
      ),
      LabWriteDescriptorSetImageSampler(
        DescriptorSets.Ptr.VkHandle[0],
        2,
        [
          LabDescriptorImageInfo(
            VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            TextureNormal.Ptr.View.Ptr.VkHandle,
            TextureNormal.Ptr.Sampler.Ptr.VkHandle
          )
        ]
      )
    ],
    []
  );
  PipelineCache := TLabPipelineCache.Create(Device);
  PipelineLayout := TLabPipelineLayout.Create(Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]);
  Pipeline := TLabGraphicsPipeline.Create(
    Device, PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [VertexShader.Ptr, PixelShader.Ptr],
    RenderPassOffscreen.Ptr, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState(
      [VertexBuffer.Ptr.MakeBindingDesc(0)],
      VertexBuffer.Ptr.MakeAttributeDescArr(0, 0)
    ),
    LabPipelineRasterizationState(
      VK_FALSE, VK_FALSE, VK_POLYGON_MODE_FILL, TVkFlags(VK_CULL_MODE_BACK_BIT), VK_FRONT_FACE_COUNTER_CLOCKWISE
    ),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment], []),
    LabPipelineTesselationState(0)
  );
  ScreenQuad := TFullscreenQuad.Create;
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  TransferBuffers;
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  SwapchainDestroy;
  ScreenQuad.Free;
  TextureNormal := nil;
  TextureColor := nil;
  Fence := nil;
  Semaphore := nil;
  Pipeline := nil;
  PipelineCache := nil;
  DescriptorSets := nil;
  VertexBuffer := nil;
  PixelShader := nil;
  VertexShader := nil;
  PipelineLayout := nil;
  UniformBuffer := nil;
  Cmd := nil;
  CmdPool := nil;
  DescriptorSetsFactory := nil;
  Surface := nil;
  Device := nil;
  Window.Free;
  Free;
end;

procedure TLabApp.Loop;
  procedure ResetSwapChain;
  begin
    Device.Ptr.WaitIdle;
    SwapchainDestroy;
    SwapchainCreate;
    ScreenQuad.BindOffscreenTargets;
    ScreenQuad.Resize(Cmd.Ptr);
  end;
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
    ResetSwapChain;
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
    ResetSwapChain;
    Exit;
  end
  else
  begin
    LabAssertVkError(r);
  end;
  cur_buffer := SwapChain.Ptr.CurImage;
  Cmd.Ptr.RecordBegin();
  Cmd.Ptr.SetViewport([LabViewport(0, 0, Window.Width, Window.Height)]);
  Cmd.Ptr.SetScissor([LabRect2D(0, 0, Window.Width, Window.Height)]);
  Cmd.Ptr.BeginRenderPass(
    RenderPassOffscreen.Ptr, OffscreenTargets[cur_buffer].FrameBuffer.Ptr,
    [LabClearValue(1, 0), LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(0, 0, 0, 1.0), LabClearValue(1.0, 0)]
  );
  Cmd.Ptr.BindPipeline(Pipeline.Ptr);
  Cmd.Ptr.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[0]], []
  );
  Cmd.Ptr.BindVertexBuffers(0, [VertexBuffer.Ptr.VkHandle], [0]);
  Cmd.Ptr.Draw(12 * 3);
  Cmd.Ptr.EndRenderPass;
  Cmd.Ptr.BeginRenderPass(
    RenderPass.Ptr, FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(1.0, 0)]
  );
  ScreenQuad.Draw(Cmd.Ptr);
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

end.
