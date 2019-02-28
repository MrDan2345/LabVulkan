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
  private
    var Staging: TLabBufferShared;
  public
    var Image: TLabImageShared;
    var View: TLabImageViewShared;
    var Sampler: TLabSamplerShared;
    var MipLevels: TVkUInt32;
    var Size: TVkUInt32;
    var Format: TVkFormat;
    constructor Create(const CubeImage: TCubeImage);
    constructor Create(
      const CubeSize: TVkUInt32;
      const AFormat: TVkFormat;
      const Layout: TVkImageLayout = VK_IMAGE_LAYOUT_UNDEFINED;
      const Usage: TVkImageUsageFlags = TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT);
      const UseMipMaps: Boolean = True
    );
    destructor Destroy; override;
    procedure Stage(const Cmd: TLabCommandBuffer);
    procedure GenMipMaps(const Cmd: TLabCommandBuffer);
  end;
  TCubeTextureShared = specialize TLabSharedRef<TCubeTexture>;

  TTexture = class (TLabClass)
  private
    var Staging: TLabBufferShared;
  public
    var Image: TLabImageShared;
    var View: TLabImageViewShared;
    var Sampler: TLabSamplerShared;
    var MipLevels: TVkUInt32;
    constructor Create(const ImageData: TLabImageData; const ForceRGBA32: Boolean = True);
    constructor Create(const FileName: String; const ForceRGBA32: Boolean = True);
    destructor Destroy; override;
    procedure Stage(const Cmd: TLabCommandBuffer);
  end;
  TTextureShared = specialize TLabSharedRef<TTexture>;

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
    var Texture: TCubeTextureShared;
    var TextureGen: TCubeTextureShared;
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
    procedure GenerateCubeMap;
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
  Create(CubeImage.Size, VK_FORMAT_R8G8B8A8_UNORM);
  Staging := TLabBuffer.Create(
    App.Device,
    Image.Ptr.DataSize,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
    []
  );
  pc := nil;
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
end;

constructor TCubeTexture.Create(const CubeSize: TVkUInt32;
  const AFormat: TVkFormat; const Layout: TVkImageLayout;
  const Usage: TVkImageUsageFlags; const UseMipMaps: Boolean);
  var fmt_props: TVkImageFormatProperties;
begin
  Format := AFormat;
  Size := CubeSize;
  if UseMipMaps then
  begin
    fmt_props := App.Device.Ptr.PhysicalDevice.Ptr.ImageFormatProperties(
      Format, VK_IMAGE_TYPE_2D, VK_IMAGE_TILING_OPTIMAL,
      TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
      TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
      TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
      TVkFlags(VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT)
    );
    MipLevels := LabIntLog2(LabMakePOT(Size)) + 1;
    if MipLevels > fmt_props.maxMipLevels then MipLevels := fmt_props.maxMipLevels;
  end
  else
  begin
    MipLevels := 1;
  end;
  Image := TLabImage.Create(
    App.Device,
    Format,
    Usage,
    //TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    //TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    //TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    [], Size, Size, 1, MipLevels, 6, VK_SAMPLE_COUNT_1_BIT,
    VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
    Layout, //VK_IMAGE_LAYOUT_UNDEFINED,
    TVkFlags(VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT)
  );
  View := TLabImageView.Create(
    App.Device, Image.Ptr.VkHandle, Image.Ptr.Format,
    TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_CUBE,
    0, MipLevels, 0, 6
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
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0, MipLevels, 0, 6
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
        LabExtent3D(Size, Size, 1),
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0, 0, 6
      )
    ]
  );
  GenMipMaps(Cmd);
end;

procedure TCubeTexture.GenMipMaps(const Cmd: TLabCommandBuffer);
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

constructor TTexture.Create(const ImageData: TLabImageData; const ForceRGBA32: Boolean);
  var fmt_remap: array[0..8] of record
    fmt_img: TLabImageDataFormat;
    fmt_vk: TVkFormat;
  end = (
    (fmt_img: idf_g8; fmt_vk: VK_FORMAT_R8G8B8A8_UNORM),
    (fmt_img: idf_g16; fmt_vk: VK_FORMAT_R16G16B16A16_UNORM),
    (fmt_img: idf_g8a8; fmt_vk: VK_FORMAT_R8G8B8A8_UNORM),
    (fmt_img: idf_g16a16; fmt_vk: VK_FORMAT_R16G16B16A16_UNORM),
    (fmt_img: idf_r8g8b8; fmt_vk: VK_FORMAT_R8G8B8A8_UNORM),
    (fmt_img: idf_r16g16b16; fmt_vk: VK_FORMAT_R16G16B16A16_UNORM),
    (fmt_img: idf_r8g8b8a8; fmt_vk: VK_FORMAT_R8G8B8A8_UNORM),
    (fmt_img: idf_r16g16b16a16; fmt_vk: VK_FORMAT_R16G16B16A16_UNORM),
    (fmt_img: idf_r32g32b32_f; fmt_vk: VK_FORMAT_R32G32B32A32_SFLOAT)
  );
  type TRGBA16 = array[0..3] of TVkUInt16;
  type PRGBA16 = ^TRGBA16;
  type TRGBA32F = array[0..3] of TVkFloat;
  type PRGBA32F = ^TRGBA32F;
  var map: Pointer;
  var pc: PLabColor absolute map;
  var pc16: PRGBA16 absolute map;
  var pc32f: PRGBA32F absolute map;
  var data_ptr: Pointer;
  var dx, dy: TVkFloat;
  var i, x, y: Integer;
  var fmt: TVkFormat;
begin
  fmt := VK_FORMAT_R8G8B8A8_UNORM;
  if not ForceRGBA32 then
  for i := 0 to High(fmt_remap) do
  if fmt_remap[i].fmt_img = ImageData.Format then
  begin
    fmt := fmt_remap[i].fmt_vk;
  end;
  MipLevels := LabIntLog2(LabMakePOT(LabMax(ImageData.Width, ImageData.Height))) + 1;
  Image := TLabImage.Create(
    App.Device,
    fmt,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    [], LabMakePOT(ImageData.Width), LabMakePOT(ImageData.Height), 1, MipLevels, 1, VK_SAMPLE_COUNT_1_BIT,
    VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
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
  Staging := TLabBuffer.Create(
    App.Device, Image.Ptr.DataSize,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (Staging.Ptr.Map(map)) then
  begin
    if ForceRGBA32 then
    begin
      if (ImageData.BPP = 4)
      and (ImageData.Width = Image.Ptr.Width)
      and (ImageData.Height = Image.Ptr.Height) then
      begin
        Move(ImageData.Data^, map^, ImageData.DataSize);
      end
      else
      begin
        dx := ImageData.Width / Image.Ptr.Width;
        dy := ImageData.Height / Image.Ptr.Height;
        for y := 0 to Image.Ptr.Height - 1 do
        for x := 0 to Image.Ptr.Width - 1 do
        begin
          pc^ := ImageData.Pixels[Round(x * dx), Round(y * dy)];
          Inc(pc);
        end;
      end;
    end
    else
    begin
      dx := ImageData.Width / Image.Ptr.Width;
      dy := ImageData.Height / Image.Ptr.Height;
      for y := 0 to Image.Ptr.Height - 1 do
      for x := 0 to Image.Ptr.Width - 1 do
      begin
        data_ptr := ImageData.DataAt(Round(x * dx), Round(y * dy));
        case ImageData.Format of
          idf_g8:
          begin
            pc^.r := PLabUInt8(data_ptr)^;
            pc^.g := PLabUInt8(data_ptr)^;
            pc^.b := PLabUInt8(data_ptr)^;
            pc^.a := $ff;
          end;
          idf_g16:
          begin
            pc16^[0] := PLabUInt16(data_ptr)^;
            pc16^[1] := PLabUInt16(data_ptr)^;
            pc16^[2] := PLabUInt16(data_ptr)^;
            pc16^[3] := $ffff;
          end;
          idf_g8a8:
          begin
            pc^.r := PLabUInt8(data_ptr)^;
            pc^.g := PLabUInt8(data_ptr)^;
            pc^.b := PLabUInt8(data_ptr)^;
            pc^.a := PLabUInt8Arr(data_ptr)^[1];
          end;
          idf_g16a16:
          begin
            pc16^[0] := PLabUInt16(data_ptr)^;
            pc16^[1] := PLabUInt16(data_ptr)^;
            pc16^[2] := PLabUInt16(data_ptr)^;
            pc16^[3] := PLabUInt16Arr(data_ptr)^[1];
          end;
          idf_r8g8b8:
          begin
            pc^.r := PLabUInt8Arr(data_ptr)^[0];
            pc^.g := PLabUInt8Arr(data_ptr)^[1];
            pc^.b := PLabUInt8Arr(data_ptr)^[2];
            pc^.a := $ff;
          end;
          idf_r16g16b16:
          begin
            pc16^[0] := PLabUInt16Arr(data_ptr)^[0];
            pc16^[1] := PLabUInt16Arr(data_ptr)^[1];
            pc16^[2] := PLabUInt16Arr(data_ptr)^[2];
            pc16^[3] := $ffff;
          end;
          idf_r8g8b8a8:
          begin
            pc^.r := PLabUInt8Arr(data_ptr)^[0];
            pc^.g := PLabUInt8Arr(data_ptr)^[1];
            pc^.b := PLabUInt8Arr(data_ptr)^[2];
            pc^.a := PLabUInt8Arr(data_ptr)^[3];
          end;
          idf_r16g16b16a16:
          begin
            pc16^[0] := PLabUInt16Arr(data_ptr)^[0];
            pc16^[1] := PLabUInt16Arr(data_ptr)^[1];
            pc16^[2] := PLabUInt16Arr(data_ptr)^[2];
            pc16^[3] := PLabUInt16Arr(data_ptr)^[3];
          end;
          idf_r32g32b32_f:
          begin
            pc32f^[0] := PLabFloatArr(data_ptr)^[0];
            pc32f^[1] := PLabFloatArr(data_ptr)^[1];
            pc32f^[2] := PLabFloatArr(data_ptr)^[2];
            pc32f^[3] := 1;
          end;
        end;
        case ImageData.Format of
          idf_g8, idf_g8a8, idf_r8g8b8, idf_r8g8b8a8: Inc(pc);
          idf_g16, idf_g16a16, idf_r16g16b16, idf_r16g16b16a16: Inc(pc16);
          idf_r32g32b32_f: Inc(pc32f);
        end;
      end;
    end;
    Staging.Ptr.Unmap;
  end;
end;

constructor TTexture.Create(const FileName: String; const ForceRGBA32: Boolean);
  var img_class: TLabImageDataClass;
  var img: TLabImageData;
begin
  img_class := LabPickImageFormat(FileName);
  if Assigned(img_class) then img := img_class.Create;
  if Assigned(img) then
  begin
    img.Load(FileName);
    Create(img, ForceRGBA32);
    img.Free;
  end;
end;

destructor TTexture.Destroy;
begin
  inherited Destroy;
end;

procedure TTexture.Stage(const Cmd: TLabCommandBuffer);
  var i: Integer;
  var mip_src_width, mip_src_height, mip_dst_width, mip_dst_height: TVkUInt32;
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
  fov := LabDegToRad * 45;
  with Transforms do
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
  DescriptorSetsFactory := TLabDescriptorSetsFactory.Create(Device);
  PipelineCache := TLabPipelineCache.Create(Device);
  GenerateCubeMap;
  Texture := TextureGen;
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

procedure TLabApp.GenerateCubeMap;
  const tex_size = 2048;
  var tex2d: TTexture;
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
  TextureGen := TCubeTexture.Create(
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
  tex2d := TTexture.Create('../../Images/Arches_E_PineTree_3k.hdr', False);
  for i := 0 to High(attachments) do
  begin
    attachments[i] := LabAttachmentDescription(
      TextureGen.Ptr.Format, {VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL} VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_SAMPLE_COUNT_1_BIT,
      VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_STORE, VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_DONT_CARE,
      VK_IMAGE_LAYOUT_UNDEFINED
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
  tex2d.Stage(tmp_cmd.Ptr);
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
  App.TextureGen.Ptr.GenMipMaps(tmp_cmd.Ptr);
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
end;

end.
