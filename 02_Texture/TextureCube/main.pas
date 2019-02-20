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
  Classes,
  SysUtils;

type
  TCubeImage = class (TLabClass)
  private
    var _Data: array [0..5] of TLabImageData;
    const ind_xp = 0;
    const ind_xn = 1;
    const ind_yp = 2;
    const ind_yn = 3;
    const ind_zp = 4;
    const ind_zn = 5;
    function GetImageData(const Index: TVkInt32): TLabImageData; inline;
    function GetXN: TLabImageData; inline;
    function GetXP: TLabImageData; inline;
    function GetYN: TLabImageData; inline;
    function GetYP: TLabImageData; inline;
    function GetZN: TLabImageData; inline;
    function GetZP: TLabImageData; inline;
    function GetSize: TVkUInt32; inline;
  public
    property ImageData[const Index: TVkInt32]: TLabImageData read GetImageData; default;
    property xn: TLabImageData read GetXN;
    property xp: TLabImageData read GetXP;
    property yn: TLabImageData read GetYN;
    property yp: TLabImageData read GetYP;
    property zn: TLabImageData read GetZN;
    property zp: TLabImageData read GetZP;
    property Size: TVkUInt32 read GetSize;
    constructor Create(const DirName: String);
    destructor Destroy; override;
  end;
  TCubeImageShared = specialize TLabSharedRef<TCubeImage>;

  TCubeTexture = class (TLabClass)
  public
    var Image: TLabImageShared;
    var Staging: TLabBufferShared;
    var View: TLabImageViewShared;
    var Sampler: TLabSamplerShared;
    var MipLevels: TVkUInt32;
    var Size: TVkUInt32;
    constructor Create(const CubeImage: TCubeImage);
    destructor Destroy; override;
    procedure Stage(const Cmd: TLabCommandBuffer);
  end;
  TCubeTextureShared = specialize TLabSharedRef<TCubeTexture>;

  TLabApp = class (TLabVulkan)
  public
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
    var UniformBuffer: TLabUniformBufferShared;
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
    //var Texture: record
    //  var Image: TLabImageShared;
    //  var Staging: TLabBufferShared;
    //  var View: TLabImageViewShared;
    //  var Sampler: TLabSamplerShared;
    //  var MipLevels: TVkUInt32;
    //end;
    var Texture: TCubeTextureShared;
    var Transforms: record
      World: TLabMat;
      View: TLabMat;
      Projection: TLabMat;
      WVP: TLabMat;
    end;
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
  //Amount of time, in nanoseconds, to wait for a command buffer to complete
  FENCE_TIMEOUT = 100000000;

  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

var
  App: TLabApp;

implementation

constructor TCubeTexture.Create(const CubeImage: TCubeImage);
  var i, x, y: TVkInt32;
  var pc: PLabColor;
begin
  Size := CubeImage.Size;
  MipLevels := LabIntLog2(LabMakePOT(Size)) + 1;
  Image := TLabImage.Create(
    App.Device,
    VK_FORMAT_R8G8B8A8_UNORM,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    [], Size, Size, 1, MipLevels, 6, VK_SAMPLE_COUNT_1_BIT,
    VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
    VK_IMAGE_LAYOUT_UNDEFINED,
    TVkFlags(VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT)
  );
  Staging := TLabBuffer.Create(
    App.Device,
    Image.Ptr.DataSize,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
    []
  );
  if Staging.Ptr.Map(pc) then
  begin
    for i := 0 to 5 do
    begin
      for y := 0 to Size - 1 do
      for x := 0 to Size - 1 do
      begin
        pc^ := CubeImage[i].Pixels[x, y];
        Inc(pc);
      end;
    end;
    Staging.Ptr.Unmap;
  end;
  View := TLabImageView.Create(
    App.Device, Image.Ptr.VkHandle, Image.Ptr.Format,
    TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_CUBE,
    0, MipLevels
  );
  Sampler := TLabSampler.Create(
    App.Device,
    VK_FILTER_LINEAR, VK_FILTER_LINEAR,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_FALSE,
    1,
    VK_SAMPLER_MIPMAP_MODE_LINEAR, 0, 0, MipLevels
  );
end;

destructor TCubeTexture.Destroy;
begin
  inherited Destroy;
end;

procedure TCubeTexture.Stage(const Cmd: TLabCommandBuffer);
  var BufferCopies: array[0..5] of TVkBufferImageCopy;
  var i: TVkInt32;
  var mip_src_size, mip_dst_size: TVkUInt32;
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
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0, MipLevels, 0, 6
      )
    ]
  );
  for i := 0 to 5 do
  begin
    BufferCopies[i] := LabBufferImageCopy(
      LabOffset3D(0, 0, 0),
      LabExtent3D(Size, Size, 1),
      TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0, TVkUInt32(i),
      1, i * Size * Size * 4
    )
  end;
  Cmd.CopyBufferToImage(
    Staging.Ptr.VkHandle,
    Image.Ptr.VkHandle,
    VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    BufferCopies
  );
  mip_src_size := Size;
  for i := 0 to MipLevels - 2 do
  begin
    mip_dst_size := mip_src_size shr 1;
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
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i), 1, 0, 6
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
          LabOffset3D(0, 0, 0), LabOffset3D(mip_src_size, mip_src_size, 1),
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i), 0, 6,
          LabOffset3D(0, 0, 0), LabOffset3D(mip_dst_size, mip_dst_size, 1),
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i + 1), 0, 6
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
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i), 1, 0, 6
        )
      ]
    );
    mip_src_size := mip_dst_size;
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
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), MipLevels - 1, 1, 0, 6
      )
    ]
  );
end;

function TCubeImage.GetImageData(const Index: TVkInt32): TLabImageData;
begin
  Result := _Data[Index];
end;

function TCubeImage.GetXN: TLabImageData;
begin
  Result := _Data[ind_xn];
end;

function TCubeImage.GetXP: TLabImageData;
begin
  Result := _Data[ind_xp];
end;

function TCubeImage.GetYN: TLabImageData;
begin
  Result := _Data[ind_yn];
end;

function TCubeImage.GetYP: TLabImageData;
begin
  Result := _Data[ind_yp];
end;

function TCubeImage.GetZN: TLabImageData;
begin
  Result := _Data[ind_zn];
end;

function TCubeImage.GetZP: TLabImageData;
begin
  Result := _Data[ind_zp];
end;

function TCubeImage.GetSize: TVkUInt32;
begin
  Result := xn.Width;
end;

constructor TCubeImage.Create(const DirName: String);
  var i: TVkInt32;
begin
  for i := 0 to 5 do _Data[i] := TLabImageDataPNG.Create;
  _Data[ind_xn].Load(DirName + '/xn.png');
  _Data[ind_xp].Load(DirName + '/xp.png');
  _Data[ind_yn].Load(DirName + '/yn.png');
  _Data[ind_yp].Load(DirName + '/yp.png');
  _Data[ind_zn].Load(DirName + '/zn.png');
  _Data[ind_zp].Load(DirName + '/zp.png');
end;

destructor TCubeImage.Destroy;
  var i: TVkInt32;
begin
  for i := 0 to 5 do _Data[i].Free;
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
  var Clip: TLabMat;
begin
  fov := LabDegToRad * 60;
  with Transforms do
  begin
    Projection := LabMatProj(fov, Window.Ptr.Width / Window.Ptr.Height, 0.1, 100);
    View := LabMatView(LabVec3(0, 0, 0), LabVec3(0, 0, 1), LabVec3(0, -1, 0));
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
  Texture.Ptr.Stage(Cmd.Ptr);
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
end;

procedure TLabApp.Initialize;
  var map: PVkVoid;
  var img: TCubeImage;
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
  UniformBuffer := TLabUniformBuffer.Create(Device, SizeOf(Transforms));
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
  img := TCubeImage.Create('../../Images/park_cube_map');
  Texture := TCubeTexture.Create(img);
  img.Free;
  DescriptorSetsFactory := TLabDescriptorSetsFactory.Create(Device);
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
  PipelineCache := TLabPipelineCache.Create(Device);
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
  var UniformData: PVkUInt8;
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

end.
