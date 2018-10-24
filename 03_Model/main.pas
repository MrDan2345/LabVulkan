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
  LabDebugDraw,
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
    var DebugDraw: TLabDebugDraw;
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

  TSkinSubsetData = class (TLabClass)
  private
    var _Subset: TLabSceneControllerSkin.TSubset;
  public
    VertexBufferStaging: TLabBuffer;
    VertexBuffer: TLabVertexBuffer;
    constructor Create(const Subset: TLabSceneControllerSkin.TSubset);
    destructor Destroy; override;
  end;

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
  TImageDataList = specialize TLabList<TImageData>;

  TInstanceData = class (TLabClass)
  public
    type TPass = class
      GeomSubset: TLabSceneGeometry.TSubset;
      SkinSubset: TLabSceneControllerSkin.TSubset;
      Material: TLabSceneMaterial;
      Shader: TLabSceneShaderShared;
      PipelineLayout: TLabPipelineLayoutShared;
      Images: TImageDataList;
      Pipeline: TLabPipelineShared;
      constructor Create;
      destructor Destroy; override;
    end;
    type TPassList = specialize TLabList<TPass>;
  private
    var _Attachment: TLabSceneNodeAttachment;
    procedure SetupGeometry(
      const Geom: TLabSceneGeometry;
      const Skin: TLabSceneControllerSkin;
      const MaterialBindings: TLabSceneMaterialBindingList
    );
  public
    Passes: TPassList;
    JointUniformBuffer: TLabUniformBuffer;
    JointUniforms: PLabMatArr;
    Joints: TLabSceneNodeList;
    procedure UpdateSkinTransforms;
    constructor Create(const Attachment: TLabSceneNodeAttachmentGeometry);
    constructor Create(const Attachment: TLabSceneNodeAttachmentController);
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

constructor TSkinSubsetData.Create(const Subset: TLabSceneControllerSkin.TSubset);
  const FormatMap: array[1..4] of array[0..1] of TVkFormat = (
    (VK_FORMAT_R32_UINT, VK_FORMAT_R32_SFLOAT),
    (VK_FORMAT_R32G32_UINT, VK_FORMAT_R32G32_SFLOAT),
    (VK_FORMAT_R32G32B32_UINT, VK_FORMAT_R32G32B32_SFLOAT),
    (VK_FORMAT_R32G32B32A32_UINT, VK_FORMAT_R32G32B32A32_SFLOAT)
  );
  var Attribs: array[0..1] of TLabVertexBufferAttributeFormat;
  var map: Pointer;
begin
  _Subset := Subset;
  Attribs[0] := LabVertexBufferAttributeFormat(FormatMap[Subset.Skin.MaxWeightCount][0], 0);
  Attribs[1] := LabVertexBufferAttributeFormat(FormatMap[Subset.Skin.MaxWeightCount][1], Subset.Skin.MaxWeightCount * SizeOf(TVkUInt32));
  VertexBuffer := TLabVertexBuffer.Create(
    App.Device,
    Subset.Skin.VertexStride * Subset.GeometrySubset.VertexCount, Subset.Skin.VertexStride, Attribs,
    TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexBufferStaging := TLabBuffer.Create(
    App.Device, VertexBuffer.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  if VertexBufferStaging.Map(map) then
  begin
    Move(Subset.WeightData^, map^, VertexBuffer.Size);
    VertexBufferStaging.Unmap;
  end;
  Subset.FreeWeightData;
end;

destructor TSkinSubsetData.Destroy;
begin
  FreeAndNil(VertexBufferStaging);
  FreeAndNil(VertexBuffer);
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

constructor TInstanceData.TPass.Create;
begin
  Images := TImageDataList.Create;
end;

destructor TInstanceData.TPass.Destroy;
begin
  Images.Free;
  inherited Destroy;
end;

procedure TInstanceData.SetupGeometry(
  const Geom: TLabSceneGeometry;
  const Skin: TLabSceneControllerSkin;
  const MaterialBindings: TLabSceneMaterialBindingList
);
  var i, j, pc: Integer;
  var r_s: TLabSceneGeometry.TSubset;
  var Pass: TPass;
  var Image: TImageData;
  var Params: TLabSceneShaderParameters;
  var SkinInfo: TLabSceneShaderSkinInfo;
  var si_ptr: PLabSceneShaderSkinInfo;
begin
  if Assigned(Skin) then
  begin
    si_ptr := @SkinInfo;
    SkinInfo.JointCount := Length(Skin.Joints);
    SkinInfo.MaxJointWeights := Skin.MaxWeightCount;
  end
  else
  begin
    si_ptr := nil;
  end;
  for i := 0 to Geom.Subsets.Count - 1 do
  begin
    r_s := Geom.Subsets[i];
    Pass := TPass.Create;
    pc := 1;
    if Assigned(Skin) then Inc(pc);
    for j := 0 to MaterialBindings.Count - 1 do
    if r_s.Material = MaterialBindings[j].Symbol then
    begin
      Pass.Material := MaterialBindings[j].Material;
      Break;
    end;
    if Assigned(Pass.Material) then
    begin
      for j := 0 to Pass.Material.Effect.Params.Count - 1 do
      if Pass.Material.Effect.Params[j].ParameterType = pt_sampler then
      begin
        Inc(pc);
      end;
    end;
    SetLength(Params, pc);
    pc := 0;
    Params[pc] := LabSceneShaderParameterUniformDynamic(
      App.UniformBuffer.Ptr.VkHandle, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
    );
    Inc(pc);
    if Assigned(Skin) then
    begin
      Params[pc] := LabSceneShaderParameterUniform(
        JointUniformBuffer.VkHandle, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
      );
      Inc(pc);
    end;
    if Assigned(Pass.Material) then
    begin
      for j := 0 to Pass.Material.Effect.Params.Count - 1 do
      if Pass.Material.Effect.Params[j].ParameterType = pt_sampler then
      begin
        Image := TImageData(TLabSceneEffectParameterSampler(Pass.Material.Effect.Params[j]).Image.UserData);
        Pass.Images.Add(Image);
        Params[pc] := LabSceneShaderParameterImage(
          Image.TextureView.Ptr.VkHandle,
          Image.TextureSampler.Ptr.VkHandle,
          TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
        );
      end;
    end;
    Pass.GeomSubset := r_s;
    if Assigned(Skin) then
    begin
      Pass.SkinSubset := Skin.Subsets[i];
    end
    else
    begin
      Pass.SkinSubset := nil;
    end;
    Pass.Shader := TLabSceneShaderFactory.MakeShader(App.Device, r_s.VertexDescriptor, Params, si_ptr);
    Pass.PipelineLayout := TLabPipelineLayout.Create(App.Device, [], [Pass.Shader.Ptr.DescriptorSetLayout]);
    Passes.Add(Pass);
  end;
end;

procedure TInstanceData.UpdateSkinTransforms;
  function CombinedTransform(const n: TLabSceneNode): TLabMat;
    var i: TVkInt32;
  begin
    Result := n.Transform;
    if Assigned(n.Parent) then Result := Result * CombinedTransform(n.Parent);
  end;
  var Skin: TLabSceneControllerSkin;
  var i: TVkInt32;
  var m: TLabMat;
begin
  if not (_Attachment is TLabSceneNodeAttachmentController)
  or not (TLabSceneNodeAttachmentController(_Attachment).Controller is TLabSceneControllerSkin) then Exit;
  Skin := TLabSceneControllerSkin(TLabSceneNodeAttachmentController(_Attachment).Controller);
  for i := 0 to Joints.Count - 1 do
  begin
    m := Joints[i].Transform;//CombinedTransform(Joints[i]);
    m := (Skin.BindShapeMatrix * Skin.Joints[i].BindPose) * m;
    JointUniforms^[i] := m;
  end;
end;

constructor TInstanceData.Create(const Attachment: TLabSceneNodeAttachmentGeometry);
begin
  _Attachment := Attachment;
  Passes := TPassList.Create;
  SetupGeometry(Attachment.Geometry, nil, Attachment.MaterialBindings);
end;

constructor TInstanceData.Create(
  const Attachment: TLabSceneNodeAttachmentController
);
  var Skin: TLabSceneControllerSkin;
  procedure PropagateBinds(const Node: TLabSceneNode; const xf: TLabMat);
    var i: TVkInt32;
    var bp: TLabMat;
  begin
    bp := xf;
    for i := 0 to Joints.Count - 1 do
    if Joints[i] = Node then
    begin
      bp := bp * Skin.Joints[i].BindPose;
      Skin.Joints[i].BindPose := bp;
      Break;
    end;
    for i := 0 to Node.Children.Count - 1 do
    begin
      PropagateBinds(Node.Children[i], bp);
    end;
  end;
  var i: TVkInt32;
begin
  _Attachment := Attachment;
  Passes := TPassList.Create;
  if not (Attachment.Controller is TLabSceneControllerSkin) then Exit;
  Skin := TLabSceneControllerSkin(Attachment.Controller);
  JointUniformBuffer := TLabUniformBuffer.Create(
    App.Device, SizeOf(TLabMat) * Length(Skin.Joints)
  );
  JointUniformBuffer.Map(JointUniforms);
  Joints := TLabSceneNodeList.Create;
  Joints.Allocate(Length(Skin.Joints));
  for i := 0 to Joints.Count - 1 do
  begin
    Joints[i] := Attachment.Skeleton.FindBySID(Skin.Joints[i].JointName);
    if not Assigned(Joints[i]) then
    begin
      Joints[i] := Attachment.Skeleton.FindByID(Skin.Joints[i].JointName);
      if not Assigned(Joints[i]) then
      begin
        Joints[i] := Attachment.Skeleton.FindByName(Skin.Joints[i].JointName);
      end;
    end;
    JointUniforms^[i] := LabMatIdentity;
  end;
  //PropagateBinds(Attachment.Skeleton, LabMatIdentity);
  SetupGeometry(Skin.Geometry, Skin, Attachment.MaterialBindings);
end;

destructor TInstanceData.Destroy;
begin
  FreeAndNil(Joints);
  if Assigned(JointUniformBuffer) then
  begin
    JointUniformBuffer.Unmap;
    FreeAndNil(JointUniformBuffer);
  end;
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
      if Node.Attachments[i] is TLabSceneNodeAttachmentGeometry then
      begin
        Node.Attachments[i].UserData := TInstanceData.Create(TLabSceneNodeAttachmentGeometry(Node.Attachments[i]));
      end
      else if Node.Attachments[i] is TLabSceneNodeAttachmentController then
      begin
        Node.Attachments[i].UserData := TInstanceData.Create(TLabSceneNodeAttachmentController(Node.Attachments[i]));
      end;
    end;
    for i := 0 to Node.Children.Count - 1 do
    begin
      CreateInstances(Node.Children[i]);
    end;
  end;
  var r_g: TLabSceneGeometry;
  var r_s: TLabSceneGeometry.TSubset;
  var r_i: TLabSceneImage;
  var r_c: TLabSceneControllerSkin;
  var i_i, i_g, i_s, i_c: Integer;
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
  for i_c := 0 to Scene.Controllers.Count - 1 do
  if Scene.Controllers[i_c] is TLabSceneControllerSkin then
  begin
    r_c := TLabSceneControllerSkin(Scene.Controllers[i_c]);
    for i_s := 0 to r_c.Subsets.Count - 1 do
    begin
      r_c.Subsets[i_s].UserData := TSkinSubsetData.Create(r_c.Subsets[i_s]);
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
  var GlobalWorld: TLabMat;
  var GlobalView: TLabMat;
  var GlobalProjection: TLabMat;
  var GlobalClip: TLabMat;
  procedure UpdateNode(const Node: TLabSceneNode);
    var i_n, i: Integer;
    var nd: TNodeData;
    var id: TInstanceData;
  begin
    nd := TNodeData(Node.UserData);
    if Assigned(nd) then
    with Transforms.Ptr.Items[nd.UniformOffset]^ do
    begin
      Projection := GlobalProjection;
      View := GlobalView;
      World := Node.Transform * GlobalWorld;
      WVP := World * View * Projection * GlobalClip;
    end;
    //DebugDraw.DrawTransform(Node.Transform);
    for i_n := 0 to Node.Children.Count - 1 do
    begin
      UpdateNode(Node.Children[i_n]);
    end;
    for i := 0 to Node.Attachments.Count - 1 do
    if (Node.Attachments[i] is TLabSceneNodeAttachmentController)
    and Assigned(Node.Attachments[i].UserData)
    and (Node.Attachments[i].UserData is TInstanceData) then
    begin
      TInstanceData(Node.Attachments[i].UserData).UpdateSkinTransforms;
    end;
  end;
  var fov: TVkFloat;
  const rot_loop = 45;
begin
  fov := LabDegToRad * 45;
  GlobalWorld := LabMatRotationX(-LabHalfPi);//LabMatIdentity;// LabMatRotationX(LabHalfPi); LabMatRotationY((LabTimeLoopSec(5) / 5) * Pi * 2);
  if rot_loop > LabEPS then
  begin
    GlobalWorld := GlobalWorld * LabMatRotationY((LabTimeLoopSec(rot_loop) / rot_loop) * Pi * 2);
  end;
  GlobalProjection := LabMatProj(fov, Window.Width / Window.Height, 0.1, 100);
  GlobalView := LabMatView(LabVec3(0, 7, -15), LabVec3(0, 5, 0), LabVec3(0, 1, 0));
  GlobalClip := LabMat(
    1, 0, 0, 0,
    0, -1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  );
  UpdateNode(Scene.Root);
  if Assigned(UniformBufferMap) then
  begin
    Move(Transforms.Ptr.Data^, UniformBufferMap^, Transforms.Ptr.DataSize);
    UniformBuffer.Ptr.FlushMappedMemoryRanges(
      [LabMappedMemoryRange(UniformBuffer.Ptr.Memory, 0, UniformBuffer.Ptr.Size)]
    );
  end;
  with DebugDraw.Transforms^ do
  begin
    World := GlobalWorld;
    Projection := GlobalProjection;
    View := GlobalView;
    WVP := World * View * Projection * GlobalClip;
  end;
end;

procedure TLabApp.TransferBuffers;
  var i_g, i_s, i_i, i_c: Integer;
  var r_g: TLabSceneGeometry;
  var r_c: TLabSceneControllerSkin;
  var r_i: TLabSceneImage;
  var gsd: TGeometrySubsetData;
  var ssd: TSkinSubsetData;
  var image_data: TImageData;
begin
  CmdBuffer.Ptr.RecordBegin;
  for i_g := 0 to Scene.Geometries.Count - 1 do
  begin
    r_g := Scene.Geometries[i_g];
    for i_s := 0 to r_g.Subsets.Count - 1 do
    begin
      gsd := TGeometrySubsetData(r_g.Subsets[i_s].UserData);
      CmdBuffer.Ptr.CopyBuffer(
        gsd.VertexBufferStaging.VkHandle,
        gsd.VertexBuffer.VkHandle,
        LabBufferCopy(gsd.VertexBufferStaging.Size)
      );
      CmdBuffer.Ptr.CopyBuffer(
        gsd.IndexBufferStaging.VkHandle,
        gsd.IndexBuffer.VkHandle,
        LabBufferCopy(gsd.IndexBufferStaging.Size)
      );
    end;
  end;
  for i_c := 0 to Scene.Controllers.Count - 1 do
  if Scene.Controllers[i_c] is TLabSceneControllerSkin then
  begin
    r_c := TLabSceneControllerSkin(Scene.Controllers[i_c]);
    for i_s := 0 to r_c.Subsets.Count - 1 do
    begin
      ssd := TSkinSubsetData(r_c.Subsets[i_s].UserData);
      CmdBuffer.Ptr.CopyBuffer(
        ssd.VertexBufferStaging.VkHandle,
        ssd.VertexBuffer.VkHandle,
        LabBufferCopy(ssd.VertexBufferStaging.Size)
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
      gsd := TGeometrySubsetData(r_g.Subsets[i_s].UserData);
      FreeAndNil(gsd.VertexBufferStaging);
      FreeAndNil(gsd.IndexBufferStaging);
    end;
  end;
  for i_c := 0 to Scene.Controllers.Count - 1 do
  if Scene.Controllers[i_c] is TLabSceneControllerSkin then
  begin
    r_c := TLabSceneControllerSkin(Scene.Controllers[i_c]);
    for i_s := 0 to r_c.Subsets.Count - 1 do
    begin
      ssd := TSkinSubsetData(r_c.Subsets[i_s].UserData);
      FreeAndNil(ssd.VertexBufferStaging);
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
  Scene.Add('../Models/maya/maya_anim.dae');
  //Scene.Add('../Models/box.dae');
  //Scene.Add('../Models/skin.dae');
  ProcessScene;
  PipelineCache := TLabPipelineCache.Create(Device);
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  TransferBuffers;
  DebugDraw := TLabDebugDraw.Create(Device);
  if UniformBuffer.IsValid then UniformBuffer.Ptr.Map(UniformBufferMap);
end;

procedure TLabApp.Finalize;
begin
  if UniformBuffer.IsValid then UniformBuffer.Ptr.Unmap;
  Device.Ptr.WaitIdle;
  DebugDraw.Free;
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
  var Viewport: TVkViewport;
  var Scissor: TVkRect2D;
  var cur_pipeline: TLabGraphicsPipeline;
  procedure RenderNode(const Node: TLabSceneNode);
    var nd: TNodeData;
    var i, i_a, i_p: Integer;
    var r_sg: TLabSceneGeometry.TSubset;
    var r_ss: TLabSceneControllerSkin.TSubset;
    var r_p: TInstanceData.TPass;
    var inst_data: TInstanceData;
    var geom_data: TGeometrySubsetData;
    var skin_data: TSkinSubsetData;
    var vertex_state: TLabPipelineVertexInputState;
    var attrib_desc: TLabVertexInputAttributeDescriptionArr;
  begin
    nd := TNodeData(Node.UserData);
    if Assigned(nd) then
    for i_a := 0 to Node.Attachments.Count - 1 do
    if Assigned(Node.Attachments[i_a].UserData)
    and (Node.Attachments[i_a].UserData is TInstanceData) then
    begin
      inst_data := TInstanceData(Node.Attachments[i_a].UserData);
      for i_p := 0 to inst_data.Passes.Count - 1 do
      begin
        r_p := inst_data.Passes[i_p];
        r_sg := r_p.GeomSubset;
        r_ss := r_p.SkinSubset;
        geom_data := TGeometrySubsetData(r_sg.UserData);
        if Assigned(r_ss) then skin_data := TSkinSubsetData(r_ss.UserData);
        if not r_p.Pipeline.IsValid then
        begin
          if Assigned(r_ss) then
          begin
            SetLength(attrib_desc, geom_data.VertexBuffer.AttributeCount + skin_data.VertexBuffer.AttributeCount);
            for i := 0 to geom_data.VertexBuffer.AttributeCount - 1 do
            begin
              attrib_desc[i] := geom_data.VertexBuffer.MakeAttributeDesc(i, i, 0);
            end;
            for i := 0 to skin_data.VertexBuffer.AttributeCount - 1 do
            begin
              attrib_desc[geom_data.VertexBuffer.AttributeCount + i] := (
                skin_data.VertexBuffer.MakeAttributeDesc(i, geom_data.VertexBuffer.AttributeCount + i, 1)
              );
            end;
            vertex_state := LabPipelineVertexInputState(
              [
                geom_data.VertexBuffer.MakeBindingDesc(0),
                skin_data.VertexBuffer.MakeBindingDesc(1)
              ],
              attrib_desc
            );
          end
          else
          begin
            vertex_state := LabPipelineVertexInputState(
              [geom_data.VertexBuffer.MakeBindingDesc(0)],
              geom_data.VertexBuffer.MakeAttributeDescArr(0, 0)
            );
          end;
          r_p.Pipeline := TLabGraphicsPipeline.FindOrCreate(
            Device, PipelineCache, r_p.PipelineLayout.Ptr,
            [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
            [r_p.Shader.Ptr.VertexShader.Ptr.Shader, r_p.Shader.Ptr.PixelShader.Ptr.Shader],
            RenderPass.Ptr, 0,
            LabPipelineViewportState(),
            LabPipelineInputAssemblyState(),
            vertex_state,
            LabPipelineRasterizationState(
              VK_FALSE, VK_FALSE,
              VK_POLYGON_MODE_FILL,
              TVkFlags(VK_CULL_MODE_BACK_BIT),
              VK_FRONT_FACE_CLOCKWISE
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
          CmdBuffer.Ptr.SetViewport([Viewport]);
          CmdBuffer.Ptr.SetScissor([Scissor]);
        end;
        CmdBuffer.Ptr.BindDescriptorSets(
          VK_PIPELINE_BIND_POINT_GRAPHICS,
          r_p.PipelineLayout.Ptr,
          0, 1, r_p.Shader.Ptr.DescriptorSets.Ptr, [Transforms.Ptr.ItemOffset[nd.UniformOffset]]
        );
        if Assigned(r_ss) then
        begin
          CmdBuffer.Ptr.BindVertexBuffers(
            0,
            [
              geom_data.VertexBuffer.VkHandle,
              skin_data.VertexBuffer.VkHandle
            ], [0, 0]
          );
        end
        else
        begin
          CmdBuffer.Ptr.BindVertexBuffers(0, [geom_data.VertexBuffer.VkHandle], [0]);
        end;
        CmdBuffer.Ptr.BindIndexBuffer(geom_data.IndexBuffer.VkHandle, 0, geom_data.IndexBuffer.IndexType);
        CmdBuffer.Ptr.DrawIndexed(geom_data.IndexBuffer.IndexCount);
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
  var t, anim_loop: TLabFloat;
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
  if Scene.DefaultAnimationClip.MaxTime > LabEPS then
  begin
    anim_loop := 1;
    t := LabTimeLoopSec(Scene.DefaultAnimationClip.MaxTime * anim_loop) / anim_loop;
    Scene.DefaultAnimationClip.Sample(t, False);
  end;
  Viewport := LabViewport(0, 0, Window.Width, Window.Height);
  Scissor := LabRect2D(0, 0, Window.Width, Window.Height);
  UpdateTransforms;
  DebugDraw.Flush;
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
  DebugDraw.Draw(CmdBuffer.Ptr, PipelineCache.Ptr, RenderPass.Ptr, Viewport, SampleCount);
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
