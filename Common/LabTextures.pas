unit LabTextures;

interface

uses
  Vulkan,
  LabTypes,
  LabVulkan,
  LabDevice,
  LabBuffer,
  LabCommandBuffer,
  LabImage,
  LabImageData,
  LabUtils,
  LabMath;

type
  TLabTexture2D = class (TLabClass)
  private
    var Device: TLabDeviceShared;
    var Staging: TLabBufferShared;
  public
    var Image: TLabImageShared;
    var View: TLabImageViewShared;
    var Sampler: TLabSamplerShared;
    var MipLevels: TVkUInt32;
    var Width, Height: TVkUInt32;
    var Format: TVkFormat;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const AFormat: TVkFormat;
      const AWidth: TVkUInt32;
      const AHeight: TVkUInt32;
      const AImageUsage: TVkImageUsageFlags;
      const AMemoryFlags: TVkFlags = TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
      const AUseMipMaps: Boolean = True;
      const ASamplerRepeat: Boolean = True
    );
    constructor Create(const ADevice: TLabDeviceShared; const ImageData: TLabImageData; const ForceRGBA32: Boolean = True);
    constructor Create(const ADevice: TLabDeviceShared; const FileName: String; const ForceRGBA32: Boolean = True);
    destructor Destroy; override;
    procedure Stage(const Params: array of const);
    procedure StageComplete(const Params: array of const);
  end;
  TLabTexture2DShared = specialize TLabSharedRef<TLabTexture2D>;

  TLabCubeImage = class (TLabClass)
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
  TLabCubeImageShared = specialize TLabSharedRef<TLabCubeImage>;

  TLabTextureCube = class (TLabClass)
  private
    var Device: TLabDeviceShared;
    var Staging: TLabBufferShared;
  public
    var Image: TLabImageShared;
    var View: TLabImageViewShared;
    var Sampler: TLabSamplerShared;
    var MipLevels: TVkUInt32;
    var Size: TVkUInt32;
    var Format: TVkFormat;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const CubeImage: TLabCubeImage
    );
    constructor Create(
      const ADevice: TLabDeviceShared;
      const CubeSize: TVkUInt32;
      const AFormat: TVkFormat;
      const Layout: TVkImageLayout = VK_IMAGE_LAYOUT_UNDEFINED;
      const Usage: TVkImageUsageFlags = TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT);
      const UseMipMaps: Boolean = True
    );
    constructor Create(
      const ADevice: TLabDeviceShared;
      const DirName: String
    );
    destructor Destroy; override;
    procedure Stage(const Params: array of const);
    procedure GenMipMaps(const Cmd: TLabCommandBuffer);
    procedure StageComplete(const Params: array of const);
  end;
  TLabTextureCubeShared = specialize TLabSharedRef<TLabTextureCube>;

implementation

constructor TLabTexture2D.Create(
  const ADevice: TLabDeviceShared;
  const AFormat: TVkFormat;
  const AWidth: TVkUInt32;
  const AHeight: TVkUInt32;
  const AImageUsage: TVkImageUsageFlags;
  const AMemoryFlags: TVkFlags;
  const AUseMipMaps: Boolean;
  const ASamplerRepeat: Boolean
);
  var AddressMode: TVkSamplerAddressMode;
begin
  Device := ADevice;
  Format := AFormat;
  Width := AWidth;
  Height := AHeight;
  if AUseMipMaps then
  begin
    MipLevels := LabIntLog2(LabMax(Width, Height)) + 1;
  end
  else
  begin
    MipLevels := 1;
  end;
  if ASamplerRepeat then
  begin
    AddressMode := VK_SAMPLER_ADDRESS_MODE_REPEAT;
  end
  else
  begin
    AddressMode := VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
  end;
  Image := TLabImage.Create(
    Device,
    Format,
    AImageUsage,
    [], Width, Height, 1, MipLevels, 1, VK_SAMPLE_COUNT_1_BIT,
    VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE,
    AMemoryFlags
  );
  View := TLabImageView.Create(
    Device, Image.Ptr.VkHandle, Format,
    TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
    0, MipLevels
  );
  Sampler := TLabSampler.Create(
    Device, VK_FILTER_LINEAR, VK_FILTER_LINEAR,
    AddressMode, AddressMode, AddressMode,
    VK_TRUE, 16, VK_SAMPLER_MIPMAP_MODE_LINEAR, 0, 0, MipLevels - 1
  );
end;

constructor TLabTexture2D.Create(
  const ADevice: TLabDeviceShared;
  const ImageData: TLabImageData;
  const ForceRGBA32: Boolean
);
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
  Create(
    ADevice,
    fmt,
    LabMakePOT(ImageData.Width), LabMakePOT(ImageData.Height),
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
  );
  Staging := TLabBuffer.Create(
    Device, Image.Ptr.DataSize,
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

constructor TLabTexture2D.Create(
  const ADevice: TLabDeviceShared;
  const FileName: String;
  const ForceRGBA32: Boolean
);
  var img_class: TLabImageDataClass;
  var img: TLabImageData;
begin
  img_class := LabPickImageFormat(FileName);
  if Assigned(img_class) then img := img_class.Create;
  if Assigned(img) then
  begin
    img.Load(FileName);
    Create(ADevice, img, ForceRGBA32);
    img.Free;
  end;
end;

destructor TLabTexture2D.Destroy;
begin
  inherited Destroy;
end;

procedure TLabTexture2D.Stage(const Params: array of const);
  var Cmd: TLabCommandBuffer;
  var i: Integer;
  var mip_src_width, mip_src_height, mip_dst_width, mip_dst_height: TVkUInt32;
begin
  if not Staging.IsValid then Exit;
  Cmd := TLabCommandBuffer(Params[0].VPointer);
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

procedure TLabTexture2D.StageComplete(const Params: array of const);
begin
  Staging := nil;
end;

function TLabCubeImage.GetImageData(const Index: TVkInt32): TLabImageData;
begin
  Result := _Data[Index];
end;

function TLabCubeImage.GetXN: TLabImageData;
begin
  Result := _Data[ind_xn];
end;

function TLabCubeImage.GetXP: TLabImageData;
begin
  Result := _Data[ind_xp];
end;

function TLabCubeImage.GetYN: TLabImageData;
begin
  Result := _Data[ind_yn];
end;

function TLabCubeImage.GetYP: TLabImageData;
begin
  Result := _Data[ind_yp];
end;

function TLabCubeImage.GetZN: TLabImageData;
begin
  Result := _Data[ind_zn];
end;

function TLabCubeImage.GetZP: TLabImageData;
begin
  Result := _Data[ind_zp];
end;

function TLabCubeImage.GetSize: TVkUInt32;
begin
  Result := xn.Width;
end;

constructor TLabCubeImage.Create(const DirName: String);
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

destructor TLabCubeImage.Destroy;
  var i: TVkInt32;
begin
  for i := 0 to 5 do _Data[i].Free;
  inherited Destroy;
end;

constructor TLabTextureCube.Create(
  const ADevice: TLabDeviceShared;
  const CubeImage: TLabCubeImage
);
  var i, x, y: TVkInt32;
  var pc: PLabColor;
begin
  Create(
    ADevice, CubeImage.Size,
    VK_FORMAT_R8G8B8A8_UNORM,
    VK_IMAGE_LAYOUT_UNDEFINED,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT)
  );
  Staging := TLabBuffer.Create(
    Device,
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

constructor TLabTextureCube.Create(
  const ADevice: TLabDeviceShared;
  const CubeSize: TVkUInt32;
  const AFormat: TVkFormat;
  const Layout: TVkImageLayout;
  const Usage: TVkImageUsageFlags;
  const UseMipMaps: Boolean
);
  var fmt_props: TVkImageFormatProperties;
begin
  Device := ADevice;
  Format := AFormat;
  Size := CubeSize;
  if UseMipMaps then
  begin
    fmt_props := Device.Ptr.PhysicalDevice.Ptr.ImageFormatProperties(
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
    Device,
    Format,
    Usage,
    [], Size, Size, 1, MipLevels, 6, VK_SAMPLE_COUNT_1_BIT,
    VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
    Layout,
    TVkFlags(VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT)
  );
  View := TLabImageView.Create(
    Device, Image.Ptr.VkHandle, Image.Ptr.Format,
    TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_CUBE,
    0, MipLevels, 0, 6
  );
  Sampler := TLabSampler.Create(
    Device,
    VK_FILTER_LINEAR, VK_FILTER_LINEAR,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_FALSE,
    1,
    VK_SAMPLER_MIPMAP_MODE_LINEAR, 0, 0, MipLevels
  );
end;

constructor TLabTextureCube.Create(
  const ADevice: TLabDeviceShared;
  const DirName: String
);
  var img: TLabCubeImage;
begin
  img := TLabCubeImage.Create(DirName);
  Create(ADevice, img);
  img.Free;
end;

destructor TLabTextureCube.Destroy;
begin
  inherited Destroy;
end;

procedure TLabTextureCube.Stage(const Params: array of const);
  var Cmd: TLabCommandBuffer;
begin
  if not Staging.IsValid then Exit;
  Cmd := TLabCommandBuffer(Params[0].VPointer);
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

procedure TLabTextureCube.GenMipMaps(const Cmd: TLabCommandBuffer);
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

procedure TLabTextureCube.StageComplete(const Params: array of const);
begin
  Staging := nil;
end;

end.
