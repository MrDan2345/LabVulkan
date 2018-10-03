unit LabImage;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice;

type
  TLabImage = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Format: TVkFormat;
    var _ImageType: TVkImageType;
    var _Width: TVkInt32;
    var _Height: TVkInt32;
    var _Depth: TVkInt32;
    var _MipLevels: TVkInt32;
    var _Layers: TVkInt32;
    var _Samples: TVkSampleCountFlagBits;
    var _QueueFamilyIndices: array of TVkUInt32;
    var _SharingMode: TVkSharingMode;
    var _Usage: TVkImageUsageFlags;
    var _Flags: TVkImageCreateFlags;
    var _Handle: TVkImage;
    var _Memory: TVkDeviceMemory;
    var _DataSize: TVkDeviceSize;
  public
    property Device: TLabDeviceShared read _Device;
    property Format: TVkFormat read _Format;
    property Width: TVkInt32 read _Width;
    property Height: TVkInt32 read _Height;
    property Depth: TVkInt32 read _Depth;
    property VkHandle: TVkImage read _Handle;
    property ImageType: TVkImageType read _ImageType;
    property DataSize: TVkDeviceSize read _DataSize;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const AFormat: TVkFormat;
      const AUsage: TVkImageUsageFlags;
      const AQueueFamilyIndices: array of TVkUInt32;
      const AWidth: TVkInt32;
      const AHeight: TVkInt32;
      const ADepth: TVkInt32 = 1;
      const AMipLevels: TVkInt32 = 1;
      const ALayers: TVkInt32 = 1;
      const ASamples: TVkSampleCountFlagBits = VK_SAMPLE_COUNT_1_BIT;
      const ATiling: TVkImageTiling = VK_IMAGE_TILING_OPTIMAL;
      const AImageType: TVkImageType = VK_IMAGE_TYPE_2D;
      const ASharingMode: TVkSharingMode = VK_SHARING_MODE_EXCLUSIVE;
      const AMemoryFlags: TVkFlags = TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
      const AInitialLayout: TVkImageLayout = VK_IMAGE_LAYOUT_UNDEFINED;
      const AFlags: TVkImageCreateFlags = 0
    );
    destructor Destroy; override;
  end;
  TLabImageShared = specialize TLabSharedRef<TLabImage>;

  TLabImageView = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkImageView;
  public
    property VkHandle: TVkImageView read _Handle;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const AImage: TVkImage;
      const AFormat: TVkFormat;
      const AAspectMask: TVkImageAspectFlags = TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT);
      const AViewType: TVkImageViewType = VK_IMAGE_VIEW_TYPE_2D;
      const ABaseMipLevel: TVkInt32 = 0;
      const AMipLevelCount: TVkInt32 = 1;
      const ABaseLayer: TVkInt32 = 0;
      const ALayerCount: TVkInt32 = 1;
      const AFlags: TVkImageViewCreateFlags = 0
    );
    destructor Destroy; override;
  end;
  TLabImageViewShared = specialize TLabSharedRef<TLabImageView>;

  TLabDepthBuffer = class (TLabImage)
  private
    var _View: TLabImageView;
  public
    property View: TLabImageView read _View;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const AWidth: TVkInt32;
      const AHeight: TVkInt32;
      const AFormat: TVkFormat = VK_FORMAT_UNDEFINED;
      const AUsage: TVkImageUsageFlags = TVkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT);
      const ASamples: TVkSampleCountFlagBits = VK_SAMPLE_COUNT_1_BIT
    );
    destructor Destroy; override;
  end;
  TLabDepthBufferShared = specialize TLabSharedRef<TLabDepthBuffer>;

  TLabSampler = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkSampler;
  public
    property Device: TLabDeviceShared read _Device;
    property VkHandle: TVkSampler read _Handle;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const AMinFilter: TVkFilter = VK_FILTER_LINEAR;
      const AMagFilter: TVkFilter = VK_FILTER_LINEAR;
      const AAddressModeU: TVkSamplerAddressMode = VK_SAMPLER_ADDRESS_MODE_REPEAT;
      const AAddressModeV: TVkSamplerAddressMode = VK_SAMPLER_ADDRESS_MODE_REPEAT;
      const AAddressModeW: TVkSamplerAddressMode = VK_SAMPLER_ADDRESS_MODE_REPEAT;
      const AAnisotropyEnable: TVkBool32 = VK_FALSE;
      const AMaxAnisotropy: TVkFloat = 1;
      const AMipMapMode: TVkSamplerMipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
      const AMipLodBias: TVkFloat = 0;
      const AMinLod: TVkFloat = 0;
      const AMaxLod: TVkFloat = 0;
      const ABorderColor: TVkBorderColor = VK_BORDER_COLOR_INT_OPAQUE_BLACK;
      const ACompareEnable: TVkBool32 = VK_FALSE;
      const ACompareOp: TVkCompareOp = VK_COMPARE_OP_ALWAYS;
      const AUnnormalizedCoords: TVkBool32 = VK_FALSE;
      const AFlags: TVkSamplerCreateFlags = 0
    );
    destructor Destroy; override;
  end;
  TLabSamplerShared = specialize TLabSharedRef<TLabSampler>;

implementation

constructor TLabImage.Create(const ADevice: TLabDeviceShared;
  const AFormat: TVkFormat; const AUsage: TVkImageUsageFlags;
  const AQueueFamilyIndices: array of TVkUInt32; const AWidth: TVkInt32;
  const AHeight: TVkInt32; const ADepth: TVkInt32; const AMipLevels: TVkInt32;
  const ALayers: TVkInt32; const ASamples: TVkSampleCountFlagBits;
  const ATiling: TVkImageTiling; const AImageType: TVkImageType;
  const ASharingMode: TVkSharingMode;
  const AMemoryFlags: TVkFlags;
  const AInitialLayout: TVkImageLayout;
  const AFlags: TVkImageCreateFlags
);
  var pass: Boolean;
  var image_info: TVkImageCreateInfo;
  var mem_alloc: TVkMemoryAllocateInfo;
  var mem_reqs: TVkMemoryRequirements;
begin
  LabLog('TLabImage.Create');
  inherited Create;
  _Device := ADevice;
  _Format := AFormat;
  _ImageType := AImageType;
  _Width := AWidth;
  _Height := AHeight;
  _Depth := ADepth;
  _MipLevels := AMipLevels;
  _Layers := ALayers;
  _Samples := ASamples;
  _SharingMode := ASharingMode;
  _Usage := AUsage;
  _Flags := AFlags;
  SetLength(_QueueFamilyIndices, Length(AQueueFamilyIndices));
  if (Length(_QueueFamilyIndices) > 0) then
  begin
    Move(AQueueFamilyIndices[0], _QueueFamilyIndices[0], SizeOf(TVkUint32) * Length(_QueueFamilyIndices));
  end;
  FillChar(image_info, sizeof(image_info), 0);
  image_info.sType := VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
  image_info.pNext := nil;
  image_info.imageType := _ImageType;
  image_info.format := _Format;
  image_info.extent.width := _Width;
  image_info.extent.height := _Height;
  image_info.extent.depth := _Depth;
  image_info.mipLevels := _MipLevels;
  image_info.arrayLayers := _Layers;
  image_info.samples := _Samples;
  image_info.initialLayout := AInitialLayout;
  image_info.queueFamilyIndexCount := Length(_QueueFamilyIndices);
  if Length(_QueueFamilyIndices) > 0 then
  begin
    image_info.pQueueFamilyIndices := @_QueueFamilyIndices[0];
  end
  else
  begin
    image_info.pQueueFamilyIndices := nil;
  end;
  image_info.sharingMode := _SharingMode;
  image_info.usage := _Usage;
  image_info.flags := _Flags;

  FillChar(mem_alloc, sizeof(mem_alloc), 0);
  mem_alloc.sType := VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  mem_alloc.pNext := nil;
  mem_alloc.allocationSize := 0;
  mem_alloc.memoryTypeIndex := 0;

  LabAssertVkError(Vulkan.CreateImage(_Device.Ptr.VkHandle, @image_info, nil, @_Handle));
  Vulkan.GetImageMemoryRequirements(_Device.Ptr.VkHandle, _Handle, @mem_reqs);
  mem_alloc.allocationSize := mem_reqs.size;
  _DataSize := mem_reqs.size;
  pass := _Device.Ptr.MemoryTypeFromProperties(
    mem_reqs.memoryTypeBits,
    AMemoryFlags,
    mem_alloc.memoryTypeIndex
  );
  assert(pass);
  LabAssertVkError(Vulkan.AllocateMemory(_Device.Ptr.VkHandle, @mem_alloc, nil, @_Memory));
  LabAssertVkError(Vulkan.BindImageMemory(_Device.Ptr.VkHandle, _Handle, _Memory, 0));
end;

destructor TLabImage.Destroy;
begin
  Vulkan.DestroyImage(_Device.Ptr.VkHandle, _Handle, nil);
  Vulkan.FreeMemory(_Device.Ptr.VkHandle, _Memory, nil);
  inherited Destroy;
  LabLog('TLabImage.Destroy');
end;

constructor TLabImageView.Create(
  const ADevice: TLabDeviceShared;
  const AImage: TVkImage;
  const AFormat: TVkFormat;
  const AAspectMask: TVkImageAspectFlags;
  const AViewType: TVkImageViewType;
  const ABaseMipLevel: TVkInt32;
  const AMipLevelCount: TVkInt32;
  const ABaseLayer: TVkInt32;
  const ALayerCount: TVkInt32;
  const AFlags: TVkImageViewCreateFlags);
  var view_info: TVkImageViewCreateInfo;
begin
  LabLog('TLabImageView.Create');
  inherited Create;
  _Device := ADevice;
  FillChar(view_info, sizeof(view_info), 0);
  view_info.sType := VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
  view_info.pNext := nil;
  view_info.image := AImage;
  view_info.format := AFormat;
  view_info.components.r := VK_COMPONENT_SWIZZLE_R;
  view_info.components.g := VK_COMPONENT_SWIZZLE_G;
  view_info.components.b := VK_COMPONENT_SWIZZLE_B;
  view_info.components.a := VK_COMPONENT_SWIZZLE_A;
  view_info.subresourceRange.aspectMask := AAspectMask;
  view_info.subresourceRange.baseMipLevel := ABaseMipLevel;
  view_info.subresourceRange.levelCount := AMipLevelCount;
  view_info.subresourceRange.baseArrayLayer := ABaseLayer;
  view_info.subresourceRange.layerCount := ALayerCount;
  view_info.viewType := AViewType;
  view_info.flags := AFlags;
  LabAssertVkError(Vulkan.CreateImageView(_Device.Ptr.VkHandle, @view_info, nil, @_Handle));
end;

destructor TLabImageView.Destroy;
begin
  Vulkan.DestroyImageView(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabImageView.Destroy');
end;

constructor TLabDepthBuffer.Create(
  const ADevice: TLabDeviceShared;
  const AWidth: TVkInt32;
  const AHeight: TVkInt32;
  const AFormat: TVkFormat;
  const AUsage: TVkImageUsageFlags;
  const ASamples: TVkSampleCountFlagBits
);
  var depth_format: TVkFormat;
  var tiling: TVkImageTiling;
  var aspect_mask: TVkImageAspectFlags;
  var props: TVkFormatProperties;
begin
  LabLog('TLabDepthBuffer.Create');
  depth_format := AFormat;
{$if defined(__ANDROID__)}
  // Depth format needs to be VK_FORMAT_D24_UNORM_S8_UINT on Android.
  depth_format := VK_FORMAT_D24_UNORM_S8_UINT;
{$elseif defined(VK_USE_PLATFORM_IOS_MVK)}
  if (depth_format = VK_FORMAT_UNDEFINED) depth_format := VK_FORMAT_D32_SFLOAT;
{$else}
  if (depth_format = VK_FORMAT_UNDEFINED) then depth_format := VK_FORMAT_D16_UNORM;
{$endif}
  Vulkan.GetPhysicalDeviceFormatProperties(ADevice.Ptr.PhysicalDevice.Ptr.VkHandle, depth_format, @props);
  if (props.linearTilingFeatures and TVkFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT)) > 0 then
  begin
    tiling := VK_IMAGE_TILING_LINEAR;
  end
  else
  begin
    tiling := VK_IMAGE_TILING_OPTIMAL;
  end;
  inherited Create(
    ADevice,
    depth_format,
    TVkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT),
    [],
    AWidth, AHeight, 1, 1, 1, ASamples,
    tiling, VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  aspect_mask := TVkFlags(VK_IMAGE_ASPECT_DEPTH_BIT);
  if (depth_format = VK_FORMAT_D16_UNORM_S8_UINT)
  or (depth_format = VK_FORMAT_D24_UNORM_S8_UINT)
  or (depth_format = VK_FORMAT_D32_SFLOAT_S8_UINT) then
  begin
    aspect_mask := aspect_mask or TVkFlags(VK_IMAGE_ASPECT_STENCIL_BIT);
  end;
  _View := TLabImageView.Create(
    ADevice, VkHandle, Format, aspect_mask, VK_IMAGE_VIEW_TYPE_2D,
    0, 1, 0, 1, 0
  );
end;

destructor TLabDepthBuffer.Destroy;
begin
  _View.Free;
  inherited Destroy;
  LabLog('TLabDepthBuffer.Destroy');
end;

constructor TLabSampler.Create(
  const ADevice: TLabDeviceShared;
  const AMinFilter: TVkFilter;
  const AMagFilter: TVkFilter;
  const AAddressModeU: TVkSamplerAddressMode;
  const AAddressModeV: TVkSamplerAddressMode;
  const AAddressModeW: TVkSamplerAddressMode;
  const AAnisotropyEnable: TVkBool32;
  const AMaxAnisotropy: TVkFloat;
  const AMipMapMode: TVkSamplerMipmapMode;
  const AMipLodBias: TVkFloat;
  const AMinLod: TVkFloat;
  const AMaxLod: TVkFloat;
  const ABorderColor: TVkBorderColor;
  const ACompareEnable: TVkBool32;
  const ACompareOp: TVkCompareOp;
  const AUnnormalizedCoords: TVkBool32;
  const AFlags: TVkSamplerCreateFlags
);
  var samp_info: TVkSamplerCreateInfo;
begin
  _Device := ADevice;
  FillChar(samp_info, SizeOf(samp_info), 0);
  samp_info.sType := VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
  samp_info.minFilter := AMinFilter;
  samp_info.magFilter := AMagFilter;
  samp_info.addressModeU := AAddressModeU;
  samp_info.addressModeV := AAddressModeV;
  samp_info.addressModeW := AAddressModeW;
  samp_info.anisotropyEnable := AAnisotropyEnable;
  samp_info.maxAnisotropy := AMaxAnisotropy;
  samp_info.mipmapMode := AMipMapMode;
  samp_info.mipLodBias := AMipLodBias;
  samp_info.minLod := AMinLod;
  samp_info.maxLod := AMaxLod;
  samp_info.borderColor := ABorderColor;
  samp_info.compareEnable := ACompareEnable;
  samp_info.compareOp := ACompareOp;
  samp_info.unnormalizedCoordinates := AUnnormalizedCoords;
  samp_info.flags := AFlags;
  LabAssertVkError(Vulkan.CreateSampler(_Device.Ptr.VkHandle, @samp_info, nil, @_Handle));
end;

destructor TLabSampler.Destroy;
begin
  if LabVkValidHandle(_Handle) then
  begin
    Vulkan.DestroySampler(_Device.Ptr.VkHandle, _Handle, nil);
    _Handle := VK_NULL_HANDLE;
  end;
  inherited Destroy;
end;

end.
