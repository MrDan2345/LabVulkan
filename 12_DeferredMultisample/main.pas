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
  TTransforms = record
    World: TLabMat;
    View: TLabMat;
    Projection: TLabMat;
    Clip: TLabMat;
    WVP: TLabMat;
  end;
  PTransforms = ^TTransforms;

  TTexture = class (TLabClass)
    var Image: TLabImageShared;
    var Staging: TLabBufferShared;
    var View: TLabImageViewShared;
    var Sampler: TLabSamplerShared;
    var MipLevels: TVkUInt32;
    constructor Create(const FileName: String);
    destructor Destroy; override;
    procedure Stage(const Args: array of const);
  end;
  TTextureShared = specialize TLabSharedRef<TTexture>;

  TLightData = class (TLabClass)
    type TVertexData = packed record
      VP: TLabMat;
    end;
    type TUniformVertex = specialize TLabUniformBuffer<TVertexData>;
    type TUniformVertexShared = specialize TLabSharedRef<TUniformVertex>;
    type TPixelData = packed record
      VP_i: TLabMat;
      rt_ratio: TLabVec4;
      camera_pos: TLabVec4;
    end;
    type TUniformPixel = specialize TLabUniformBuffer<TPixelData>;
    type TUniformPixelShard = specialize TLabSharedRef<TUniformPixel>;
    type TLightVertex = packed record
      x, y, z, w: TVkFloat;
    end;
    type TLightInstance = packed record
      pos: TLabVec4;
      color: TLabVec4;
      vel: TLabVec4;
    end;
    type TLightInstanceArr = array[Word] of TLightInstance;
    type PLightInstanceArr = ^TLightInstanceArr;
    const light_vertices: array[0..5] of TLightVertex = (
      (x:0; y:1; z:0; w:1), (x:1; y:0; z:0; w:1), (x:0; y:0; z:1; w:1), (x:-1; y:0; z:0; w:1), (x:0; y:0; z:-1; w:1), (x:0; y:-1; z:0; w:1)
    );
    const light_indices: array[0..23] of TVkUInt16 = (
      0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1,
      1, 4, 5, 4, 3, 5, 3, 2, 5, 2, 1, 5
    );
    type TComputeTask = class
      type TComputeData = packed record
        bounds_min: TLabVec4;
        bounds_max: TLabVec4;
        box_x: TLabVec4;
        box_y: TLabVec4;
        box_z: TLabVec4;
      end;
      type TUniformCompute = specialize TLabUniformBuffer<TComputeData>;
      type TUniformComputeShared = specialize TLabSharedRef<TUniformCompute>;
      var ComputeShader: TLabComputeShaderShared;
      var UniformBuffer: TUniformComputeShared;
      var DescriptorSets: TLabDescriptorSetsShared;
      var PipelineLayout: TLabPipelineLayoutShared;
      var Pipeline: TLabPipelineShared;
      var Cmd: TLabCommandBufferShared;
      var Fence: TLabFenceShared;
      constructor Create(const StorageBuffer: TLabBuffer; const InstanceCount: TVkUInt32);
      destructor Destroy; override;
      procedure Run;
    end;
    var InstanceCount: TVkUInt32;
    var VertexBuffer: TLabVertexBufferShared;
    var VertexStaging: TLabBufferShared;
    var IndexBuffer: TLabIndexBufferShared;
    var IndexStaging: TLabIndexBufferShared;
    var InstanceBuffer: TLabVertexBufferShared;
    var InstanceStaging: TLabBufferShared;
    var VertexShader: TLabVertexShaderShared;
    var TessControlShader: TLabTessControlShaderShared;
    var TessEvalShader: TLabTessEvaluationShaderShared;
    var PixelShader: TLabPixelShaderShared;
    var Sampler: TLabSamplerShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var UniformBufferVertex: TUniformVertexShared;
    var UniformBufferPixel: TUniformPixelShard;
    var ComputeTask: TComputeTask;
    constructor Create;
    destructor Destroy; override;
    procedure Stage(const Args: array of const);
    procedure UpdateTransforms(const Args: array of const);
    procedure BindOffscreenTargets(const Args: array of const);
    procedure Draw(const Cmd: TLabCommandBuffer; const ImageIndex: TVkUInt32);
  end;
  TLightDataShared = specialize TLabSharedRef<TLightData>;

  TRenderTarget = object
    var Image: TLabImageShared;
    var View: TLabImageViewShared;
    procedure SetupImage(
      const Format: TVkFormat;
      const Usage: TVkImageUsageFlags
    );
  end;

  TFullscreenQuad = class (TLabClass)
  public
    type TScreenVertex = packed record
      x, y, z, w: TVkFloat;
      u, v: TVkFloat;
    end;
    type TQuadData = packed record
      ScreenSize: TLabVec4;
      RTSize: TLabVec4;
      VP_i: TLabMat;
    end;
    type TUniformQuad = specialize TLabUniformBuffer<TQuadData>;
    type TUniformQuadShared = specialize TLabSharedRef<TUniformQuad>;
    var QuadVertices: array[0..3] of TScreenVertex;
    var UniformBuffer: TUniformQuadShared;
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
    constructor Create;
    destructor Destroy; override;
    procedure Stage(const Args: array of const);
    procedure UpdateTransforms(const Args: array of const);
    procedure BindOffscreenTargets(const Args: array of const);
    procedure Draw(const Cmd: TLabCommandBuffer; const ImageIndex: TVkUInt32);
    procedure Resize(const Cmd: TLabCommandBuffer);
    procedure UpdateUniforms;
    class function ScreenVertex(const x, y, z, w, u, v: TVkFloat): TScreenVertex; inline;
  end;
  TFullscreenQuadShared = specialize TLabSharedRef<TFullscreenQuad>;

  TCube = class (TLabClass)
  public
    type TCubeData = record
      W: TLabMat;
      WVP: TLabMat;
    end;
    type TUniformCube = specialize TLabUniformBuffer<TCubeData>;
    type TUniformCubeShared = specialize TLabSharedRef<TUniformCube>;
    var UniformBuffer: TUniformCubeShared;
    var VertexBuffer: TLabVertexBufferShared;
    var VertexStaging: TLabBufferShared;
    var TextureColor: TTextureShared;
    var TextureNormal: TTextureShared;
    var VertexShader: TLabVertexShaderShared;
    var PixelShader: TLabPixelShaderShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    constructor Create;
    destructor Destroy; override;
    procedure Stage(const Args: array of const);
    procedure UpdateTransforms(const Args: array of const);
    procedure Draw(const Cmd: TLabCommandBuffer);
  end;
  TCubeShared = specialize TLabSharedRef<TCube>;

  TLabApp = class (TLabVulkan)
  public
    var Window: TLabWindowShared;
    var Device: TLabDeviceShared;
    var Surface: TLabSurfaceShared;
    var SwapChain: TLabSwapChainShared;
    var CmdPool: TLabCommandPoolShared;
    var CmdPoolCompute: TLabCommandPoolShared;
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
    var WidthRT: TVkUInt32;
    var HeightRT: TVkUInt32;
    var DepthBuffers: array of TLabDepthBufferShared;
    var FrameBuffers: array of TLabFrameBufferShared;
    var RenderPass: TLabRenderPassShared;
    var RenderPassOffscreen: TLabRenderPassShared;
    var DescriptorSetsFactory: TLabDescriptorSetsFactoryShared;
    var PipelineCache: TLabPipelineCacheShared;
    var Cube: TCubeShared;
    var ScreenQuad: TFullscreenQuadShared;
    var LightData: TLightDataShared;
    var OnStage: TLabDelegate;
    var OnUpdateTransforms: TLabDelegate;
    var OnBindOffscreenTargets: TLabDelegate;
    var SampleCount: TVkSampleCountFlagBits;
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
  App.OnStage.Add(@Stage);
end;

destructor TTexture.Destroy;
begin
  App.OnStage.Remove(@Stage);
  inherited Destroy;
end;

procedure TTexture.Stage(const Args: array of const);
  var Cmd: TLabCommandBuffer;
  var mip_src_width, mip_src_height, mip_dst_width, mip_dst_height, i: TVkUInt32;
begin
  Cmd := TLabCommandBuffer(Args[0].VObject);
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

constructor TLightData.TComputeTask.Create(const StorageBuffer: TLabBuffer; const InstanceCount: TVkUInt32);
  var dg: TVkUInt32;
  const bounds = 1.8;
begin
  inherited Create;
  ComputeShader := TLabComputeShader.Create(App.Device, 'cs.spv');
  UniformBuffer := TUniformCompute.Create(App.Device);
  FillChar(UniformBuffer.Ptr.Buffer^, SizeOf(TComputeData), 0);
  with UniformBuffer.Ptr.Buffer^ do
  begin
    bounds_min := LabVec4(-bounds, -bounds, -bounds, 0);
    bounds_max := LabVec4(bounds, bounds, bounds, 0);
  end;
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings([
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_COMPUTE_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_COMPUTE_BIT))
    ])
  ]);
  PipelineLayout := TLabPipelineLayout.Create(
    App.Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]
  );
  DescriptorSets.Ptr.UpdateSets(
    [
      LabWriteDescriptorSetStorageBuffer(
        DescriptorSets.Ptr.VkHandle[0], 0, LabDescriptorBufferInfo(StorageBuffer.VkHandle)
      ),
      LabWriteDescriptorSetUniformBuffer(
        DescriptorSets.Ptr.VkHandle[0], 1, LabDescriptorBufferInfo(UniformBuffer.Ptr.VkHandle)
      )
    ],
    []
  );
  Pipeline := TLabComputePipeline.Create(
    App.Device, App.PipelineCache, PipelineLayout.Ptr, ComputeShader,
    [
      LabSpecializationMapEntry(0, 0, SizeOf(InstanceCount))
    ],
    @InstanceCount, SizeOf(InstanceCount)
  );
  Fence := TLabFence.Create(App.Device);
  Cmd := TLabCommandBuffer.Create(App.CmdPoolCompute);
  Cmd.Ptr.RecordBegin;
  Cmd.Ptr.BindPipeline(Pipeline.Ptr);
  Cmd.Ptr.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_COMPUTE,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[0]],
    []
  );
  dg := Trunc((InstanceCount - 1) / 256) + 1;
  Cmd.Ptr.DispatchCompute(dg, 1, 1);
  Cmd.Ptr.RecordEnd;
end;

destructor TLightData.TComputeTask.Destroy;
begin
  inherited Destroy;
end;

procedure TLightData.TComputeTask.Run;
begin
  App.QueueSubmit(
    App.SwapChain.Ptr.QueueFamilyCompute,
    [Cmd.Ptr.VkHandle],
    [],
    [],
    Fence.Ptr.VkHandle
  );
  Fence.Ptr.WaitFor;
  Fence.Ptr.Reset;
end;

constructor TLightData.Create;
  var i: TVkInt32;
  var map: PVkVoid;
begin
  InstanceCount := 256;
  VertexBuffer := TLabVertexBuffer.Create(
    App.Device,
    SizeOf(light_vertices), SizeOf(TLightVertex),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, 0)
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
  {$Push}{$Hints off}
  if VertexStaging.Ptr.Map(map) then
  begin
    Move(light_vertices, map^, SizeOf(light_vertices));
    VertexStaging.Ptr.FlushAll;
    VertexStaging.Ptr.Unmap;
  end;
  {$Pop}
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
  if IndexStaging.Ptr.Map(map) then
  begin
    Move(light_indices, map^, SizeOf(light_indices));
    IndexStaging.Ptr.FlushAll;
    IndexStaging.Ptr.Unmap;
  end;
  InstanceBuffer := TLabVertexBuffer.Create(
    App.Device, SizeOf(TLightInstance) * InstanceCount, SizeOf(TLightInstance),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, LabPtrToOrd(@TLightInstance( nil^ ).pos)),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, LabPtrToOrd(@TLightInstance( nil^ ).color))
    ],
    TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkFlags(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  InstanceStaging := TLabBuffer.Create(
    App.Device, InstanceBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
    [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  Randomize;
  if InstanceStaging.Ptr.Map(map) then
  begin
    for i := 0 to InstanceCount - 1 do
    begin
      PLightInstanceArr(map)^[i].pos := LabVec4(
        (Random * 2 - 1) * 6,
        (Random * 2 - 1) * 6,
        (Random * 2 - 1) * 6,
        1.0 * (Random * 1.5 + 0.2)
      );
      PLightInstanceArr(map)^[i].color := LabVec4(
        Random * 0.8 + 0.2, Random * 0.8 + 0.2, Random * 0.8 + 0.2, 1
      );
      PLightInstanceArr(map)^[i].vel := LabVec4(LabRandomSpherePoint, 0);
    end;
    InstanceStaging.Ptr.FlushAll;
    InstanceStaging.Ptr.Unmap;
  end;
  VertexShader := TLabVertexShader.Create(App.Device, 'light_vs.spv');
  TessControlShader := TLabTessCtrlShader.Create(App.Device, 'light_tcs.spv');
  TessEvalShader := TLabTessEvalShader.Create(App.Device, 'light_tes.spv');
  PixelShader := TLabPixelShader.Create(App.Device, 'light_ps.spv');
  Sampler := TLabSampler.Create(
    App.Device, VK_FILTER_NEAREST, VK_FILTER_NEAREST,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_FALSE, 1, VK_SAMPLER_MIPMAP_MODE_NEAREST
  );
  UniformBufferVertex := TUniformVertex.Create(App.Device);
  UniformBufferPixel := TUniformPixel.Create(App.Device);
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings([
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(3, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(4, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
    ], App.SwapChain.Ptr.ImageCount)
  ]);
  for i := 0 to App.SwapChain.Ptr.ImageCount - 1 do
  begin
    DescriptorSets.Ptr.UpdateSets(
      [
        LabWriteDescriptorSetUniformBuffer(
          DescriptorSets.Ptr.VkHandle[i],
          0, [LabDescriptorBufferInfo(UniformBufferVertex.Ptr.VkHandle)]
        ),
        LabWriteDescriptorSetUniformBuffer(
          DescriptorSets.Ptr.VkHandle[i],
          1, [LabDescriptorBufferInfo(UniformBufferPixel.Ptr.VkHandle)]
        )
      ], []
    );
  end;
  PipelineLayout := TLabPipelineLayout.Create(
    App.Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]
  );
  Pipeline := TLabGraphicsPipeline.Create(
    App.Device, App.PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [
      LabShaderStage(VertexShader.Ptr),
      LabShaderStage(TessControlShader.Ptr),
      LabShaderStage(TessEvalShader.Ptr),
      LabShaderStage(PixelShader.Ptr, @App.SampleCount, SizeOf(App.SampleCount), LabSpecializationMapEntry(0, 0, SizeOf(App.SampleCount)))
    ],
    App.RenderPass.Ptr, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(
      VK_PRIMITIVE_TOPOLOGY_PATCH_LIST
    ),
    LabPipelineVertexInputState(
      [VertexBuffer.Ptr.MakeBindingDesc(0), InstanceBuffer.Ptr.MakeBindingDesc(1, VK_VERTEX_INPUT_RATE_INSTANCE)],
      [
        VertexBuffer.Ptr.MakeAttributeDesc(0, 0, 0),
        InstanceBuffer.Ptr.MakeAttributeDesc(0, 1, 1),
        InstanceBuffer.Ptr.MakeAttributeDesc(1, 2, 1)
      ]
    ),
    LabPipelineRasterizationState(
      //VK_FALSE, VK_FALSE,
      //VK_POLYGON_MODE_LINE
    ),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_TRUE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState(
      [
        LabPipelineColorBlendAttachmentState(
          VK_TRUE,
          VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE,
          VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE
        )
      ], []
    ),
    LabPipelineTesselationState(3)
  );
  ComputeTask := TComputeTask.Create(InstanceBuffer.Ptr, InstanceCount);
  App.OnStage.Add(@Stage);
  App.OnUpdateTransforms.Add(@UpdateTransforms);
  App.OnBindOffscreenTargets.Add(@BindOffscreenTargets);
end;

destructor TLightData.Destroy;
begin
  ComputeTask.Free;
  App.OnBindOffscreenTargets.Remove(@BindOffscreenTargets);
  App.OnUpdateTransforms.Remove(@UpdateTransforms);
  App.OnStage.Remove(@Stage);
  inherited Destroy;
end;

procedure TLightData.Stage(const Args: array of const);
  var Cmd: TLabCommandBuffer;
begin
  Cmd := TLabCommandBuffer(Args[0].VObject);
  Cmd.CopyBuffer(VertexStaging.Ptr.VkHandle, VertexBuffer.Ptr.VkHandle, [LabBufferCopy(VertexBuffer.Ptr.Size)]);
  Cmd.CopyBuffer(InstanceStaging.Ptr.VkHandle, InstanceBuffer.Ptr.VkHandle, [LabBufferCopy(InstanceBuffer.Ptr.Size)]);
  Cmd.CopyBuffer(IndexStaging.Ptr.VkHandle, IndexBuffer.Ptr.VkHandle, [LabBufferCopy(IndexBuffer.Ptr.Size)]);
end;

procedure TLightData.UpdateTransforms(const Args: array of const);
  var xf: PTransforms;
  var VP: TLabMat;
  var v_pos: TLabVec3;
begin
  xf := PTransforms(Args[0].VPointer);
  ComputeTask.UniformBuffer.Ptr.Buffer^.box_x := LabVec4(TLabVec3(xf^.World.AxisX).Norm, 0);
  ComputeTask.UniformBuffer.Ptr.Buffer^.box_y := LabVec4(TLabVec3(xf^.World.AxisY).Norm, 0);
  ComputeTask.UniformBuffer.Ptr.Buffer^.box_z := LabVec4(TLabVec3(xf^.World.AxisZ).Norm, 0);
  v_pos := LabVec3(-xf^.View.e30, -xf^.View.e31, -xf^.View.e32);
  v_pos := v_pos.Transform3x3(xf^.View.Transpose);
  VP := xf^.View * xf^.Projection * xf^.Clip;
  UniformBufferVertex.Ptr.Buffer^.VP := VP;
  UniformBufferPixel.Ptr.Buffer^.VP_i := VP.Inverse;
  UniformBufferPixel.Ptr.Buffer^.camera_pos := LabVec4(v_pos, 0);
  ComputeTask.Run;
end;

{$Push}{$Hints off}
procedure TLightData.BindOffscreenTargets(const Args: array of const);
  var i: TVkInt32;
  var Writes: array of TLabWriteDescriptorSet;
begin
  SetLength(Writes, App.SwapChain.Ptr.ImageCount * 3);
  for i := 0 to App.SwapChain.Ptr.ImageCount - 1 do
  begin
    Writes[i * 3 + 0] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      2,
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
      3,
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
      4,
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
  UniformBufferPixel.Ptr.Buffer^.rt_ratio := LabVec4(
    1 / App.SwapChain.Ptr.Width,
    1 / App.SwapChain.Ptr.Height,
    App.SwapChain.Ptr.Width / App.WidthRT,
    App.SwapChain.Ptr.Height / App.HeightRT
  );
end;
{$Pop}

procedure TLightData.Draw(const Cmd: TLabCommandBuffer; const ImageIndex: TVkUInt32);
begin
  Cmd.BindPipeline(Pipeline.Ptr);
  Cmd.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[ImageIndex]], []
  );
  Cmd.BindVertexBuffers(0, [VertexBuffer.Ptr.VkHandle, InstanceBuffer.Ptr.VkHandle], [0, 0]);
  Cmd.BindIndexBuffer(IndexBuffer.Ptr.VkHandle);
  Cmd.DrawIndexed(IndexBuffer.Ptr.IndexCount, InstanceCount);
end;

constructor TFullscreenQuad.Create;
  var Map: PVkVoid;
  var i: TVkUInt32;
  var u, v: TLabFloat;
begin
  u := App.SwapChain.Ptr.Width / App.WidthRT;
  v := App.SwapChain.Ptr.Height / App.HeightRT;
  QuadVertices[0] := ScreenVertex(-1, -1, 0.5, 1, 0, 0);
  QuadVertices[1] := ScreenVertex(1, -1, 0.5, 1, u, 0);
  QuadVertices[2] := ScreenVertex(-1, 1, 0.5, 1, 0, v);
  QuadVertices[3] := ScreenVertex(1, 1, 0.5, 1, u, v);
  VertexBuffer := TLabVertexBuffer.Create(
    App.Device,
    SizeOf(QuadVertices), SizeOf(TScreenVertex),
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
    Move(QuadVertices, Map^, VertexBuffer.Ptr.Size);
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
  UniformBuffer := TUniformQuad.Create(App.Device);
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
    [LabShaderStage(VertexShader.Ptr), LabShaderStage(PixelShader.Ptr)],
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
  App.OnStage.Add(@Stage);
  App.OnUpdateTransforms.Add(@UpdateTransforms);
  App.OnBindOffscreenTargets.Add(@BindOffscreenTargets);
end;

destructor TFullscreenQuad.Destroy;
begin
  App.OnBindOffscreenTargets.Remove(@BindOffscreenTargets);
  App.OnUpdateTransforms.Remove(@UpdateTransforms);
  App.OnStage.Remove(@Stage);
  UniformBuffer.Ptr.Unmap;
  inherited Destroy;
end;

procedure TFullscreenQuad.Stage(const Args: array of const);
  var Cmd: TLabCommandBuffer;
begin
  Cmd := TLabCommandBuffer(Args[0].VObject);
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

procedure TFullscreenQuad.UpdateTransforms(const Args: array of const);
  var xf: PTransforms;
begin
  xf := PTransforms(Args[0].VPointer);
  UniformBuffer.Ptr.Buffer^.VP_i := (xf^.View * xf^.Projection * xf^.Clip).Inverse;
end;

{$Push}{$Hints off}
procedure TFullscreenQuad.BindOffscreenTargets(const Args: array of const);
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
{$Pop}

procedure TFullscreenQuad.Draw(const Cmd: TLabCommandBuffer; const ImageIndex: TVkUInt32);
begin
  Cmd.BindPipeline(Pipeline.Ptr);
  Cmd.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[ImageIndex]], []
  );
  Cmd.BindVertexBuffers(0, [VertexBuffer.Ptr.VkHandle], [0]);
  Cmd.BindIndexBuffer(IndexBuffer.Ptr.VkHandle);
  Cmd.DrawIndexed(IndexBuffer.Ptr.IndexCount);
end;

procedure TFullscreenQuad.Resize(const Cmd: TLabCommandBuffer);
  var u, v: TVkFloat;
  var map: PVkVoid;
begin
  u := App.SwapChain.Ptr.Width / App.WidthRT;
  v := App.SwapChain.Ptr.Height / App.HeightRT;
  with UniformBuffer.Ptr.Buffer^ do
  begin
    ScreenSize.x := App.SwapChain.Ptr.Width;
    ScreenSize.y := App.SwapChain.Ptr.Height;
    ScreenSize.z := 1 / App.SwapChain.Ptr.Width;
    ScreenSize.w := 1 / App.SwapChain.Ptr.Height;
  end;
  QuadVertices[1].u := u;
  QuadVertices[2].v := v;
  QuadVertices[3].u := u;
  QuadVertices[3].v := v;
  map := nil;
  if VertexBufferStaging.Ptr.Map(map) then
  begin
    Move(QuadVertices, map^, VertexBuffer.Ptr.Size);
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
begin
  with UniformBuffer.Ptr.Buffer^ do
  begin
    ScreenSize.x := App.SwapChain.Ptr.Width;
    ScreenSize.y := App.SwapChain.Ptr.Height;
    ScreenSize.z := 1 / App.SwapChain.Ptr.Width;
    ScreenSize.w := 1 / App.SwapChain.Ptr.Height;
    RTSize.x := App.WidthRT;
    RTSize.y := App.HeightRT;
    RTSize.z := 1 / App.WidthRT;
    RTSize.w := 1 / App.HeightRT;
  end;
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

constructor TCube.Create;
  var map: PVkVoid;
begin
  VertexBuffer := TLabVertexBuffer.Create(
    App.Device,
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
  VertexStaging := TLabBuffer.Create(
    App.Device, VertexBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (VertexStaging.Ptr.Map(map)) then
  begin
    Move(g_vb_solid_face_colors_Data, map^, sizeof(g_vb_solid_face_colors_Data));
    VertexStaging.Ptr.Unmap;
  end;
  UniformBuffer := TUniformCube.Create(App.Device);
  TextureColor := TTexture.Create('crate_c.png');
  TextureNormal := TTexture.Create('crate_n.png');
  VertexShader := TLabVertexShader.Create(App.Device, 'vs.spv');
  PixelShader := TLabPixelShader.Create(App.Device, 'ps.spv');
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings([
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
    ])
  ]);
  PipelineLayout := TLabPipelineLayout.Create(App.Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]);
  Pipeline := TLabGraphicsPipeline.Create(
    App.Device, App.PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [
      LabShaderStage(VertexShader.Ptr),
      LabShaderStage(PixelShader.Ptr)
    ],
    App.RenderPassOffscreen.Ptr, 0,
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
    LabPipelineMultisampleState(App.SampleCount),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment], []),
    LabPipelineTesselationState(0)
  );
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
  App.OnStage.Add(@Stage);
  App.OnUpdateTransforms.Add(@UpdateTransforms);
end;

destructor TCube.Destroy;
begin
  App.OnUpdateTransforms.Remove(@UpdateTransforms);
  App.OnStage.Remove(@Stage);
  Pipeline := nil;
  PipelineLayout := nil;
  inherited Destroy;
end;

procedure TCube.Stage(const Args: array of const);
  var Cmd: TLabCommandBuffer;
begin
  Cmd := TLabCommandBuffer(Args[0].VObject);
  Cmd.CopyBuffer(VertexStaging.Ptr.VkHandle, VertexBuffer.Ptr.VkHandle, [LabBufferCopy(VertexBuffer.Ptr.Size)]);
end;

procedure TCube.UpdateTransforms(const Args: array of const);
  var xf: PTransforms;
begin
  xf := PTransforms(Args[0].VPointer);
  with UniformBuffer.Ptr.Buffer^ do
  begin
    W := xf^.World;
    WVP := xf^.WVP;
  end;
end;

procedure TCube.Draw(const Cmd: TLabCommandBuffer);
begin
  Cmd.BindPipeline(Pipeline.Ptr);
  Cmd.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[0]], []
  );
  Cmd.BindVertexBuffers(0, [VertexBuffer.Ptr.VkHandle], [0]);
  Cmd.Draw(24 * 3);
end;

procedure TRenderTarget.SetupImage(
  const Format: TVkFormat;
  const Usage: TVkImageUsageFlags
);
begin
  Image := TLabImage.Create(
    App.Device, Format, Usage or TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT), [],
    App.WidthRT, App.HeightRT, 1, 1, 1, App.SampleCount, VK_IMAGE_TILING_OPTIMAL,
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
  //EnableLayerIfAvailable('VK_LAYER_RENDERDOC_Capture');
  EnableExtensionIfAvailable('VK_EXT_debug_utils');
  EnableExtensionIfAvailable('VK_EXT_debug_report');
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
  WidthRT := LabMakePOT(LabMax(App.SwapChain.Ptr.Width, 1));
  HeightRT := LabMakePOT(LabMax(App.SwapChain.Ptr.Height, 1));
  SetLength(OffscreenTargets, SwapChain.Ptr.ImageCount);
  for i := 0 to SwapChain.Ptr.ImageCount - 1 do
  begin
    OffscreenTargets[i].Depth.SetupImage(VK_FORMAT_R32_SFLOAT, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT));
    OffscreenTargets[i].Color.SetupImage(VK_FORMAT_R8G8B8A8_UNORM, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT));
    OffscreenTargets[i].Normals.SetupImage(VK_FORMAT_R8G8B8A8_SNORM, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT));
    OffscreenTargets[i].ZBuffer := TLabDepthBuffer.Create(
      App.Device, App.WidthRT, App.HeightRT, VK_FORMAT_UNDEFINED,
      TVkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT), SampleCount
    );
  end;
  RenderPassOffscreen := TLabRenderPass.Create(
    Device,
    [
      LabAttachmentDescription(
        OffscreenTargets[0].Depth.Image.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        SampleCount,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      ),
      LabAttachmentDescription(
        OffscreenTargets[0].Color.Image.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        SampleCount,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      ),
      LabAttachmentDescription(
        OffscreenTargets[0].Normals.Image.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        SampleCount,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      ),
      LabAttachmentDescription(
        OffscreenTargets[0].ZBuffer.Ptr.Format,
        VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        SampleCount,
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
  var Transforms: TTransforms;
begin
  fov := LabDegToRad * 20;
  with Transforms do
  begin
    Projection := LabMatProj(fov, Window.Ptr.Width / Window.Ptr.Height, 1, 1000);
    View := LabMatView(LabVec3(-5, 8, -10), LabVec3, LabVec3(0, 1, 0));
    World := LabMatRotationY((LabTimeLoopSec(15) / 15) * Pi * 2);
    Clip := LabMat(
      1, 0, 0, 0,
      0, -1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    );
    WVP := World * View * Projection * Clip;
  end;
  OnUpdateTransforms.Call([@Transforms]);
end;

procedure TLabApp.TransferBuffers;
begin
  Cmd.Ptr.RecordBegin;
  OnStage.Call([Cmd.Ptr]);
  OnStage.Clear;
  Cmd.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [Cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
end;

procedure TLabApp.Initialize;
begin
  Window := TLabWindow.Create(500, 500);
  Window.Ptr.Caption := 'Vulkan Deferred MS';
  Device := TLabDevice.Create(
    PhysicalDevices[0],
    [
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT))),
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_COMPUTE_BIT)))
    ],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  SampleCount := Device.Ptr.PhysicalDevice.Ptr.GetSupportedSampleCount(
    [
      //VK_SAMPLE_COUNT_8_BIT,
      VK_SAMPLE_COUNT_4_BIT,
      VK_SAMPLE_COUNT_2_BIT
    ]
  );
  //SampleCount := VK_SAMPLE_COUNT_1_BIT;
  Surface := TLabSurface.Create(Window);
  DescriptorSetsFactory := TLabDescriptorSetsFactory.Create(Device);
  SwapChainCreate;
  CmdPool := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexGraphics);
  CmdPoolCompute := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexCompute);
  Cmd := TLabCommandBuffer.Create(CmdPool);
  PipelineCache := TLabPipelineCache.Create(Device);
  Cube := TCube.Create;
  ScreenQuad := TFullscreenQuad.Create;
  LightData := TLightData.Create;
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  TransferBuffers;
  OnBindOffscreenTargets.Call([]);
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  SwapchainDestroy;
  LightData := nil;
  ScreenQuad := nil;
  Cube := nil;
  Fence := nil;
  Semaphore := nil;
  PipelineCache := nil;
  Cmd := nil;
  CmdPool := nil;
  CmdPoolCompute := nil;
  DescriptorSetsFactory := nil;
  Surface := nil;
  Device := nil;
  Window := nil;
  Free;
end;

procedure TLabApp.Loop;
  procedure ResetSwapChain;
  begin
    Device.Ptr.WaitIdle;
    SwapchainDestroy;
    SwapchainCreate;
    OnBindOffscreenTargets.Call([]);
    ScreenQuad.Ptr.Resize(Cmd.Ptr);
  end;
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
    ResetSwapChain;
  end;
  UpdateTransforms;
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
  if OnStage.CallbackCount > 0 then
  begin
    TransferBuffers;
  end;
  cur_buffer := SwapChain.Ptr.CurImage;
  Cmd.Ptr.RecordBegin();
  Cmd.Ptr.SetViewport([LabViewport(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  Cmd.Ptr.SetScissor([LabRect2D(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  Cmd.Ptr.BeginRenderPass(
    RenderPassOffscreen.Ptr, OffscreenTargets[cur_buffer].FrameBuffer.Ptr,
    [LabClearValue(1, 0), LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(0, 0, 0, 1.0), LabClearValue(1.0, 0)]
  );
  Cube.Ptr.Draw(Cmd.Ptr);
  Cmd.Ptr.EndRenderPass;
  Cmd.Ptr.BeginRenderPass(
    RenderPass.Ptr, FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.0, 0.0, 0.0, 1.0), LabClearValue(1.0, 0)]
  );
  LightData.Ptr.Draw(Cmd.Ptr, cur_buffer);
  //ScreenQuad.Ptr.Draw(Cmd.Ptr, cur_buffer);
  Cmd.Ptr.EndRenderPass;
  Cmd.Ptr.RecordEnd;
  LabAssertVkError(
    QueueSubmit(
      SwapChain.Ptr.QueueFamilyGraphics,
      [Cmd.Ptr.VkHandle],
      [Semaphore.Ptr.VkHandle],
      [],
      Fence.Ptr.VkHandle,
      TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
    )
  );
  Fence.Ptr.WaitFor;
  Fence.Ptr.Reset;
  LabAssertVkError(
    QueuePresent(
      SwapChain.Ptr.QueueFamilyPresent,
      [SwapChain.Ptr.VkHandle],
      [cur_buffer],
      []
    )
  );
end;

end.
