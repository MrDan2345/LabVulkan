unit main;

{$macro on}
{$include LabPlatform.inc}

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
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
  LabFrameBuffer,
  LabDescriptorPool,
  LabPlatform,
  LabSync,
  LabColladaParser,
  LabScene,
  LabImageData,
  Classes,
  sysutils;

type
  TUniformData = packed record
    World: TLabMat;
    View: TLabMat;
    Projection: TLabMat;
    WVP: TLabMat;
  end;
  TUniformArray = specialize TLabAlignedArray<TUniformData>;
  TUniformArrayShared = specialize TLabSharedRef<TUniformArray>;

  TLabApp = class (TLabVulkan)
  public
    var Window: TLabWindow;
    var Device: TLabDeviceShared;
    var Surface: TLabSurfaceShared;
    var SwapChain: TLabSwapChainShared;
    var SampleCount: TVkSampleCountFlagBits;
    var BackBuffers: array of record
      var Depth: TLabDepthBufferShared;
      var Frame: TLabFrameBufferShared;
      var ColorMS: TLabImageShared;
      var ColorMSView: TLabImageViewShared;
    end;
    var CmdPool: TLabCommandPoolShared;
    var CmdBuffer: TLabCommandBufferShared;
    var Semaphore: TLabSemaphoreShared;
    var Fence: TLabFenceShared;
    var UniformBuffer: TLabBufferShared;
    var RenderPass: TLabRenderPassShared;
    var PipelineCache: TLabPipelineCacheShared;
    var Scene: TLabScene;
    var Transforms: TUniformArrayShared;
    var UniformBufferMap: Pointer;
    constructor Create;
    procedure SwapchainCreate;
    procedure SwapchainDestroy;
    procedure ProcessScene;
    procedure UpdateTransforms;
    procedure TransferBuffers;
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
    function GetUniformBufferOffsetAlignment(const BufferSize: TVkDeviceSize): TVkDeviceSize;
  end;

  TNodeData = class (TLabClass)
  private
    var _Node: TLabSceneNode;
  public
    var UniformOffset: TVkInt32;
    constructor Create(const Node: TLabSceneNode);
    destructor Destroy; override;
  end;

  TGeometrySubsetData = class (TLabClass)
  private
    var _Subset: TLabSceneGeometry.TSubset;
  public
    VertexBufferStaging: TLabBuffer;
    VertexBuffer: TLabVertexBuffer;
    IndexBufferStaging: TLabBuffer;
    IndexBuffer: TLabIndexBuffer;
    constructor Create(const Subset: TLabSceneGeometry.TSubset);
    destructor Destroy; override;
  end;
  TGeometrySubsetDataWeak = specialize TLabWeakRef<TGeometrySubsetData>;

  TImageData = class (TLabClass)
  private
    var _Image: TLabSceneImage;
  public
    MipLevels: TVkUInt32;
    Texture: TLabImageShared;
    TextureStaging: TLabBufferShared;
    TextureView: TLabImageViewShared;
    TextureSampler: TLabSamplerShared;
    constructor Create(const Image: TLabSceneImage);
    destructor Destroy; override;
    procedure Stage(const Cmd: TLabCommandBuffer);
  end;

  TInstanceData = class (TLabClass)
  public
    type TPass = class
      Subset: TLabSceneGeometry.TSubset;
      Material: TLabSceneMaterial;
      VertexShader: TLabSceneVertexShaderShared;
      PixelShader: TLabScenePixelShaderShared;
      DescriptorSetLayout: TLabDescriptorSetLayoutShared;
      PipelineLayout: TLabPipelineLayoutShared;
      DescriptorPool: TLabDescriptorPoolShared;
      DescriptorSets: TLabDescriptorSetsShared;
      Image: TImageData;
      Pipeline: TLabPipelineShared;
    end;
    type TPassList = specialize TLabList<TPass>;
  private
    var _Attachment: TLabSceneNodeAttachmentGeometry;
  public
    Passes: TPassList;
    constructor Create(const Attachment: TLabSceneNodeAttachmentGeometry);
    destructor Destroy; override;
  end;

const
  FENCE_TIMEOUT = 100000000;

  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

var
  App: TLabApp;

implementation

constructor TNodeData.Create(const Node: TLabSceneNode);
begin
  _Node := Node;
end;

destructor TNodeData.Destroy;
begin
  inherited Destroy;
end;

constructor TGeometrySubsetData.Create(const Subset: TLabSceneGeometry.TSubset);
  var map: Pointer;
begin
  _Subset := Subset;
  VertexBuffer := TLabVertexBuffer.Create(
    App.Device,
    Subset.VertexStride * Subset.VertexCount, Subset.VertexStride, Subset.VertexAttributes,
    TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexBufferStaging := TLabBuffer.Create(
    App.Device, VertexBuffer.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if VertexBufferStaging.Map(map) then
  begin
    Move(Subset.VertexData^, map^, VertexBuffer.Size);
    VertexBufferStaging.Unmap;
  end;
  Subset.FreeVertexData;
  IndexBuffer := TLabIndexBuffer.Create(
    App.Device,
    Subset.IndexCount, Subset.IndexType,
    TVkFlags(VK_BUFFER_USAGE_INDEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  IndexBufferStaging := TLabBuffer.Create(
    App.Device, IndexBuffer.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if IndexBufferStaging.Map(map) then
  begin
    Move(Subset.IndexData^, map^, IndexBuffer.Size);
    IndexBufferStaging.Unmap;
  end;
  Subset.FreeIndexData;
end;

destructor TGeometrySubsetData.Destroy;
begin
  FreeAndNil(VertexBufferStaging);
  FreeAndNil(VertexBuffer);
  FreeAndNil(IndexBufferStaging);
  FreeAndNil(IndexBuffer);
  inherited Destroy;
end;

constructor TImageData.Create(const Image: TLabSceneImage);
  var x, y: Integer;
  var c: PLabColor;
  var map: Pointer;
  var min_mip: TVkUInt32;
begin
  _Image := Image;
  MipLevels := (LabIntLog2(LabMakePOT(LabMax(_Image.Image.Width, _Image.Image.Height))) + 1);
  min_mip := LabIntLog2(64) + 1;
  if MipLevels > min_mip then MipLevels := MipLevels - min_mip;
  Texture := TLabImage.Create(
    App.Device,
    VK_FORMAT_R8G8B8A8_UNORM,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    [], _Image.Image.Width, _Image.Image.Height, 1, MipLevels, 1, VK_SAMPLE_COUNT_1_BIT,
    VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  TextureStaging := TLabBuffer.Create(
    App.Device, _Image.Image.Width * _Image.Image.Height * 4,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (TextureStaging.Ptr.Map(map)) then
  begin
    if _Image.Image.Format = idf_r8g8b8a8 then
    begin
      Move(_Image.Image.Data^, map^, _Image.Image.DataSize);
    end
    else
    begin
      c := PLabColor(map);
      for y := 0 to _Image.Image.Height - 1 do
      for x := 0 to _Image.Image.Width - 1 do
      begin
        c^ := _Image.Image.Pixels[x, y];
        Inc(c);
      end;
    end;
    TextureStaging.Ptr.Unmap;
  end;
  TextureView := TLabImageView.Create(
    App.Device, Texture.Ptr.VkHandle, Texture.Ptr.Format,
    TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
    0, MipLevels
  );
  TextureSampler := TLabSampler.Create(
    App.Device, VK_FILTER_LINEAR, VK_FILTER_LINEAR,
    VK_SAMPLER_ADDRESS_MODE_REPEAT, VK_SAMPLER_ADDRESS_MODE_REPEAT, VK_SAMPLER_ADDRESS_MODE_REPEAT,
    VK_TRUE, 16, VK_SAMPLER_MIPMAP_MODE_LINEAR,
    0, 0, MipLevels - 1
  );
end;

destructor TImageData.Destroy;
begin
  inherited Destroy;
end;

procedure TImageData.Stage(const Cmd: TLabCommandBuffer);
  var i, mip_src_width, mip_src_height, mip_dst_width, mip_dst_height: TVkUInt32;
begin
  Cmd.PipelineBarrier(
    TVkFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
    TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
    0, [], [],
    [
      LabImageMemoryBarrier(
        Texture.Ptr.VkHandle,
        VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        0, TVkFlags(VK_ACCESS_TRANSFER_WRITE_BIT),
        VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0, MipLevels
      )
    ]
  );
  Cmd.CopyBufferToImage(
    TextureStaging.Ptr.VkHandle,
    Texture.Ptr.VkHandle,
    VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    [
      LabBufferImageCopy(
        LabOffset3D(0, 0, 0),
        LabExtent3D(Texture.Ptr.Width, Texture.Ptr.Height, Texture.Ptr.Depth),
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0
      )
    ]
  );
  mip_src_width := Texture.Ptr.Width;
  mip_src_height := Texture.Ptr.Height;
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
          Texture.Ptr.VkHandle,
          VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
          TVkFlags(VK_ACCESS_TRANSFER_WRITE_BIT), TVkFlags(VK_ACCESS_TRANSFER_READ_BIT),
          VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), i
        )
      ]
    );
    Cmd.BlitImage(
      Texture.Ptr.VkHandle,
      VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
      Texture.Ptr.VkHandle,
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
          Texture.Ptr.VkHandle,
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
        Texture.Ptr.VkHandle,
        VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        TVkFlags(VK_ACCESS_TRANSFER_READ_BIT), TVkFlags(VK_ACCESS_SHADER_READ_BIT),
        VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), MipLevels - 1
      )
    ]
  );
end;

constructor TInstanceData.Create(const Attachment: TLabSceneNodeAttachmentGeometry);
  var i, j: Integer;
  var r_s: TLabSceneGeometry.TSubset;
  var Pass: TPass;
begin
  _Attachment := Attachment;
  Passes := TPassList.Create;
  for i := 0 to Attachment.Geometry.Subsets.Count - 1 do
  begin
    r_s := Attachment.Geometry.Subsets[i];
    Pass := TPass.Create;
    for j := 0 to Attachment.MaterialBindings.Count - 1 do
    if r_s.Material = Attachment.MaterialBindings[j].Symbol then
    begin
      Pass.Material := Attachment.MaterialBindings[j].Material;
      Break;
    end;
    if Assigned(Pass.Material) then
    begin
      for j := 0 to Pass.Material.Effect.Params.Count - 1 do
      if Pass.Material.Effect.Params[j].ParameterType = pt_sampler then
      begin
        Pass.Image := TImageData(TLabSceneEffectParameterSampler(Pass.Material.Effect.Params[j]).Image.UserData);
        Break;
      end;
    end;
    Pass.Subset := r_s;
    Pass.VertexShader := TLabSceneShaderFactory.MakeVertexShader(r_s.Geometry.Scene, r_s.VertexDescriptor, Pass.Material);
    Pass.PixelShader := TLabSceneShaderFactory.MakePixelShader(r_s.Geometry.Scene, r_s.VertexDescriptor, Pass.Material);
    if Assigned(Pass.Image) then
    begin
      Pass.DescriptorSetLayout := TLabDescriptorSetLayout.Create(
        App.Device,
        [
          LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
          LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
        ]
      );
      Pass.PipelineLayout := TLabPipelineLayout.Create(App.Device, [], [Pass.DescriptorSetLayout]);
      Pass.DescriptorPool := TLabDescriptorPool.Create(
        App.Device,
        [
          LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, 1),
          LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1)
        ],
        1
      );
      Pass.DescriptorSets := TLabDescriptorSets.Create(
        App.Device, Pass.DescriptorPool,
        [Pass.DescriptorSetLayout.Ptr.VkHandle]
      );
      Pass.DescriptorSets.Ptr.UpdateSets(
        [
          LabWriteDescriptorSetUniformBufferDynamic(
            Pass.DescriptorSets.Ptr.VkHandle[0], 0,
            [LabDescriptorBufferInfo(App.UniformBuffer.Ptr.VkHandle)]
          ),
          LabWriteDescriptorSetImageSampler(
            Pass.DescriptorSets.Ptr.VkHandle[0], 1,
            [
              LabDescriptorImageInfo(
                VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                Pass.Image.TextureView.Ptr.VkHandle,
                Pass.Image.TextureSampler.Ptr.VkHandle
              )
            ]
          )
        ],
        []
      );
    end
    else
    begin
      Pass.DescriptorSetLayout := TLabDescriptorSetLayout.Create(
        App.Device,
        [
          LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT))
        ]
      );
      Pass.PipelineLayout := TLabPipelineLayout.Create(App.Device, [], [Pass.DescriptorSetLayout]);
      Pass.DescriptorPool := TLabDescriptorPool.Create(
        App.Device,
        [
          LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, 1)
        ],
        1
      );
      Pass.DescriptorSets := TLabDescriptorSets.Create(
        App.Device, Pass.DescriptorPool,
        [Pass.DescriptorSetLayout.Ptr.VkHandle]
      );
      Pass.DescriptorSets.Ptr.UpdateSets(
        [
          LabWriteDescriptorSetUniformBufferDynamic(
            Pass.DescriptorSets.Ptr.VkHandle[0], 0,
            [LabDescriptorBufferInfo(App.UniformBuffer.Ptr.VkHandle)]
          )
        ],
        []
      );
    end;
    Passes.Add(Pass);
  end;
end;

destructor TInstanceData.Destroy;
begin
  while Passes.Count > 0 do Passes.Pop.Free;
  Passes.Free;
  inherited Destroy;
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
  if Length(BackBuffers) <> SwapChain.Ptr.ImageCount then
  begin
    SetLength(BackBuffers, SwapChain.Ptr.ImageCount);
  end;
  CmdPool := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexGraphics);
  CmdBuffer := TLabCommandBuffer.Create(CmdPool);
  CmdBuffer.Ptr.RecordBegin();
  for i := 0 to SwapChain.Ptr.ImageCount - 1 do
  begin
    BackBuffers[i].Depth := TLabDepthBuffer.Create(
      Device, SwapChain.Ptr.Width, SwapChain.Ptr.Height, VK_FORMAT_D32_SFLOAT, //VK_FORMAT_D24_UNORM_S8_UINT,
      TVkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT) or TVkFlags(VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT),
      SampleCount
    );
    BackBuffers[i].ColorMS := TLabImage.Create(
      Device, SwapChain.Ptr.Format,
      TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkFlags(VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT),
      [], SwapChain.Ptr.Width, SwapChain.Ptr.Height, 1, 1, 1, SampleCount, VK_IMAGE_TILING_OPTIMAL,
      VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE, TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
    );
    BackBuffers[i].ColorMSView := TLabImageView.Create(
      Device, BackBuffers[i].ColorMS.Ptr.VkHandle,
      BackBuffers[i].ColorMS.Ptr.Format
    );
    CmdBuffer.Ptr.PipelineBarrier(
      TVkFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
      TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
      0, [], [],
      [
        LabImageMemoryBarrier(
          BackBuffers[i].ColorMS.Ptr.VkHandle,
          VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
          0, TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
        )
      ]
    );
  end;
  CmdBuffer.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [CmdBuffer.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
  RenderPass := TLabRenderPass.Create(
    Device,
    [
      LabAttachmentDescription(
        SwapChain.Ptr.Format,
        VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        SampleCount,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE,
        VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
      ),
      LabAttachmentDescription(
        SwapChain.Ptr.Format,
        VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE
      ),
      LabAttachmentDescription(
        BackBuffers[0].Depth.Ptr.Format,
        VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        SampleCount,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      )
    ],
    [
      LabSubpassDescriptionData(
        [],
        [LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)],
        [LabAttachmentReference(1, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)],
        LabAttachmentReference(2, VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL),
        []
      )
    ],
    [
      //LabSubpassDependency(
      //  VK_SUBPASS_EXTERNAL, 0,
      //  TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT), TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
      //  TVkFlags(VK_ACCESS_MEMORY_READ_BIT), TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
      //),
      //LabSubpassDependency(
      //  0, VK_SUBPASS_EXTERNAL,
      //  TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT), TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
      //  TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT), TVkFlags(VK_ACCESS_MEMORY_READ_BIT)
      //)
    ]
  );
  for i := 0 to SwapChain.Ptr.ImageCount - 1 do
  begin
    BackBuffers[i].Frame := TLabFrameBuffer.Create(
      Device, RenderPass.Ptr,
      SwapChain.Ptr.Width, SwapChain.Ptr.Height,
      [
        BackBuffers[i].ColorMSView.Ptr.VkHandle,
        SwapChain.Ptr.Images[i]^.View.VkHandle,
        BackBuffers[i].Depth.Ptr.View.VkHandle
      ]
    );
  end;
end;

procedure TLabApp.SwapchainDestroy;
begin
  CmdBuffer := nil;
  CmdPool := nil;
  BackBuffers := nil;
  RenderPass := nil;
  SwapChain := nil;
end;

procedure TLabApp.ProcessScene;
  var inst_count: Integer;
  procedure ProcessNode(const Node: TLabSceneNode);
    var i: Integer;
    var nd: TNodeData;
  begin
    if Node.Attachments.Count > 0 then
    begin
      nd := TNodeData.Create(Node);
      nd.UniformOffset := inst_count;
      Node.UserData := nd;
      Inc(inst_count);
    end;
    for i := 0 to Node.Children.Count - 1 do
    begin
      ProcessNode(Node.Children[i]);
    end;
  end;
  procedure CreateInstances(const Node: TLabSceneNode);
    var i: Integer;
  begin
    for i := 0 to Node.Attachments.Count - 1 do
    begin
      Node.Attachments[i].UserData := TInstanceData.Create(Node.Attachments[i]);
    end;
    for i := 0 to Node.Children.Count - 1 do
    begin
      CreateInstances(Node.Children[i]);
    end;
  end;
  var r_g: TLabSceneGeometry;
  var r_s: TLabSceneGeometry.TSubset;
  var r_i: TLabSceneImage;
  var i_i, i_g, i_s: Integer;
begin
  for i_g := 0 to Scene.Geometries.Count - 1 do
  begin
    r_g := Scene.Geometries[i_g];
    for i_s := 0 to r_g.Subsets.Count - 1 do
    begin
      r_s := r_g.Subsets[i_s];
      r_s.UserData := TGeometrySubsetData.Create(r_s);
    end;
  end;
  for i_i := 0 to Scene.Images.Count - 1 do
  begin
    r_i := Scene.Images[i_i];
    r_i.UserData := TImageData.Create(r_i);
  end;
  inst_count := 0;
  ProcessNode(Scene.Root);
  if inst_count = 0 then Exit;
  Transforms := TUniformArray.Create(GetUniformBufferOffsetAlignment(SizeOf(TUniformData)));
  Transforms.Ptr.Count := inst_count;
  UniformBuffer := TLabBuffer.Create(
    Device, Transforms.Ptr.DataSize,
    TVkFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT),
    [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  CreateInstances(Scene.Root);
end;

procedure TLabApp.UpdateTransforms;
  procedure UpdateNode(const Node: TLabSceneNode);
    var i_n: Integer;
    var nd: TNodeData;
    var Clip: TLabMat;
    var fov: TVkFloat;
  begin
    fov := LabDegToRad * 45;
    nd := TNodeData(Node.UserData);
    if Assigned(nd) then
    with Transforms.Ptr.Items[nd.UniformOffset]^ do
    begin
      Projection := LabMatProj(fov, Window.Width / Window.Height, 0.1, 20);
      //View := LabMatView(LabVec3(0, 3, -14), LabVec3(0, 0.7, 0), LabVec3(0, 1, 0));
      View := LabMatView(LabVec3(0, 5, -15), LabVec3(0, 1, 0), LabVec3(0, 1, 0));
      World := Node.Transform;// * LabMatRotationY((LabTimeLoopSec(5) / 5) * Pi * 2);
      Clip := LabMat(
        1, 0, 0, 0,
        0, -1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
      );
      WVP := World * View * Projection * Clip;
    end;
    for i_n := 0 to Node.Children.Count - 1 do
    begin
      UpdateNode(Node.Children[i_n]);
    end;
  end;
begin
  UpdateNode(Scene.Root);
  if Assigned(UniformBufferMap) then
  begin
    Move(Transforms.Ptr.Data^, UniformBufferMap^, Transforms.Ptr.DataSize);
    UniformBuffer.Ptr.FlushMappedMemoryRanges(
      [LabMappedMemoryRange(UniformBuffer.Ptr.Memory, 0, UniformBuffer.Ptr.Size)]
    );
  end;
end;

procedure TLabApp.TransferBuffers;
  var i_g, i_s, i_i: Integer;
  var r_g: TLabSceneGeometry;
  var r_s: TLabSceneGeometry.TSubset;
  var r_i: TLabSceneImage;
  var subset_data: TGeometrySubsetData;
  var image_data: TImageData;
begin
  CmdBuffer.Ptr.RecordBegin;
  for i_g := 0 to Scene.Geometries.Count - 1 do
  begin
    r_g := Scene.Geometries[i_g];
    for i_s := 0 to r_g.Subsets.Count - 1 do
    begin
      r_s := r_g.Subsets[i_s];
      subset_data := TGeometrySubsetData(r_s.UserData);
      CmdBuffer.Ptr.CopyBuffer(
        subset_data.VertexBufferStaging.VkHandle,
        subset_data.VertexBuffer.VkHandle,
        LabBufferCopy(subset_data.VertexBufferStaging.Size)
      );
      CmdBuffer.Ptr.CopyBuffer(
        subset_data.IndexBufferStaging.VkHandle,
        subset_data.IndexBuffer.VkHandle,
        LabBufferCopy(subset_data.IndexBufferStaging.Size)
      );
    end;
  end;
  for i_i := 0 to Scene.Images.Count - 1 do
  begin
    r_i := Scene.Images[i_i];
    image_data := TImageData(r_i.UserData);
    image_data.Stage(CmdBuffer.Ptr);
  end;
  CmdBuffer.Ptr.RecordEnd;
  QueueSubmit(SwapChain.Ptr.QueueFamilyGraphics, [CmdBuffer.Ptr.VkHandle], [], [], VK_NULL_HANDLE);
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
  for i_g := 0 to Scene.Geometries.Count - 1 do
  begin
    r_g := Scene.Geometries[i_g];
    for i_s := 0 to r_g.Subsets.Count - 1 do
    begin
      r_s := r_g.Subsets[i_s];
      subset_data := TGeometrySubsetData(r_s.UserData);
      FreeAndNil(subset_data.VertexBufferStaging);
      FreeAndNil(subset_data.IndexBufferStaging);
    end;
  end;
  for i_i := 0 to Scene.Images.Count - 1 do
  begin
    r_i := Scene.Images[i_i];
    image_data := TImageData(r_i.UserData);
    image_data.TextureStaging := nil;
  end;
end;

procedure TLabApp.Initialize;
  var fov: TVkFloat;
  var ColladaParser: TLabColladaParser;
begin
  Window := TLabWindow.Create(500, 500);
  Window.Caption := 'Vulkan Model';
  Device := TLabDevice.Create(
    PhysicalDevices[0],
    [LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT)))],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  Surface := TLabSurface.Create(Window);
  SampleCount := Device.Ptr.PhysicalDevice.Ptr.GetSupportedSampleCount(
    [
      VK_SAMPLE_COUNT_8_BIT,
      VK_SAMPLE_COUNT_4_BIT,
      VK_SAMPLE_COUNT_2_BIT
    ]
  );
  SwapChainCreate;
  CmdPool := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexGraphics);
  CmdBuffer := TLabCommandBuffer.Create(CmdPool);
  Scene := TLabScene.Create(Device);
  Scene.Add('../Models/maya/maya.dae');
  Scene.Add('../Models/box.dae');
  ProcessScene;
  PipelineCache := TLabPipelineCache.Create(Device);
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  TransferBuffers;
  if UniformBuffer.IsValid then UniformBuffer.Ptr.Map(UniformBufferMap);
end;

procedure TLabApp.Finalize;
begin
  if UniformBuffer.IsValid then UniformBuffer.Ptr.Unmap;
  Device.Ptr.WaitIdle;
  SwapchainDestroy;
  Scene.Free;
  Fence := nil;
  Semaphore := nil;
  PipelineCache := nil;
  UniformBuffer := nil;
  Surface := nil;
  Device := nil;
  Window.Free;
  Free;
end;

procedure TLabApp.Loop;
  var cur_pipeline: TLabGraphicsPipeline;
  procedure RenderNode(const Node: TLabSceneNode);
    var nd: TNodeData;
    var i, i_a, i_s, i_p: Integer;
    var r_a: TLabSceneNodeAttachmentGeometry;
    var r_s: TLabSceneGeometry.TSubset;
    var r_p: TInstanceData.TPass;
    var inst_data: TInstanceData;
    var subset_data: TGeometrySubsetData;
  begin
    nd := TNodeData(Node.UserData);
    if Assigned(nd) then
    for i_a := 0 to Node.Attachments.Count - 1 do
    begin
      r_a := Node.Attachments[i_a];
      inst_data := TInstanceData(r_a.UserData);
      for i_p := 0 to inst_data.Passes.Count - 1 do
      begin
        r_p := inst_data.Passes[i_p];
        r_s := r_p.Subset;
        subset_data := TGeometrySubsetData(r_s.UserData);
        if not r_p.Pipeline.IsValid then
        begin
          r_p.Pipeline := TLabGraphicsPipeline.FindOrCreate(
            Device, PipelineCache, r_p.PipelineLayout.Ptr,
            [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
            [r_p.VertexShader.Ptr.Shader, r_p.PixelShader.Ptr.Shader],
            RenderPass.Ptr, 0,
            LabPipelineViewportState(),
            LabPipelineInputAssemblyState(),
            LabPipelineVertexInputState(
              [subset_data.VertexBuffer.MakeBindingDesc(0)],
              subset_data.VertexBuffer.MakeAttributeDescArr(0, 0)
            ),
            LabPipelineRasterizationState(
              VK_FALSE, VK_FALSE,
              VK_POLYGON_MODE_FILL,
              TVkFlags(VK_CULL_MODE_BACK_BIT),
              VK_FRONT_FACE_COUNTER_CLOCKWISE
            ),
            LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
            LabPipelineMultisampleState(SampleCount),
            LabPipelineColorBlendState(1, @LabDefaultColorBlendAttachment, [])
          );
        end;
        if not Assigned(cur_pipeline)
        or (cur_pipeline.Hash <> TLabGraphicsPipeline(r_p.Pipeline.Ptr).Hash) then
        begin
          cur_pipeline := TLabGraphicsPipeline(r_p.Pipeline.Ptr);
          CmdBuffer.Ptr.BindPipeline(cur_pipeline);
          CmdBuffer.Ptr.SetViewport([LabViewport(0, 0, Window.Width, Window.Height)]);
          CmdBuffer.Ptr.SetScissor([LabRect2D(0, 0, Window.Width, Window.Height)]);
        end;
        CmdBuffer.Ptr.BindDescriptorSets(
          VK_PIPELINE_BIND_POINT_GRAPHICS,
          r_p.PipelineLayout.Ptr,
          0, 1, r_p.DescriptorSets.Ptr, [Transforms.Ptr.ItemOffset[nd.UniformOffset]]
        );
        CmdBuffer.Ptr.BindVertexBuffers(0, [subset_data.VertexBuffer.VkHandle], [0]);
        CmdBuffer.Ptr.BindIndexBuffer(subset_data.IndexBuffer.VkHandle, 0, subset_data.IndexBuffer.IndexType);
        CmdBuffer.Ptr.DrawIndexed(subset_data.IndexBuffer.IndexCount);
      end;
    end;
    for i := 0 to Node.Children.Count - 1 do
    begin
      RenderNode(Node.Children[i]);
    end;
  end;
  var cur_buffer: TVkUInt32;
  var r: TVkResult;
  var n: TLabSceneNode;
  var e: TLabVec3;
  var m: TLabMat;
  var t: TLabFloat;
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
  t := LabTimeLoopSec(Scene.DefaultAnimationClip.MaxTime * 8) / 8;
  Scene.DefaultAnimationClip.Sample(t, True);
  UpdateTransforms;
  CmdBuffer.Ptr.RecordBegin();
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
  CmdBuffer.Ptr.BeginRenderPass(
    RenderPass.Ptr, BackBuffers[cur_buffer].Frame.Ptr,
    [
      LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(0.4, 0.7, 1.0, 1.0),
      LabClearValue(1.0, 0), LabClearValue(1.0, 0)
    ]
  );
  cur_pipeline := nil;
  RenderNode(Scene.Root);
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

function TLabApp.GetUniformBufferOffsetAlignment(const BufferSize: TVkDeviceSize): TVkDeviceSize;
  var align: TVkDeviceSize;
begin
  align := Device.Ptr.PhysicalDevice.Ptr.Properties^.limits.minUniformBufferOffsetAlignment;
  Result := BufferSize;
  if align > 0 then
  begin
    Result := (Result + align - 1) and (not(align - 1));
  end;
end;

end.
