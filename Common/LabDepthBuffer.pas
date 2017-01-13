unit LabDepthBuffer;

interface

uses
  Vulkan,
  LabDevice,
  LabTypes,
  LabUtils;

type
  TLabDepthBuffer = class (TLabClass)
  private
    var _Format: TVkFormat;
    var _Device: TLabDeviceRef;
    var _Image: TVkImage;
    var _Memory: TVkDeviceMemory;
    var _View: TVkImageView;
  public
    property Format: TVkFormat read _Format;
    property VkImage: TVkImage read _Image;
    constructor Create(const ADevice: TLabDeviceRef; const AWidth: TVkInt32; const AHeight: TVkInt32);
    destructor Destroy; override;
  end;
  TLabDepthBufferRef = specialize TLabRefCounter<TLabDepthBuffer>;

implementation

constructor TLabDepthBuffer.Create(const ADevice: TLabDeviceRef; const AWidth: TVkInt32; const AHeight: TVkInt32);
  function MemoryTypeFromProperties(const TypeBits: TVkUInt32; const RequirementsMask: TVkFlags; var TypeIndex: TVkUInt32): Boolean;
    var i: TVkInt32;
    var tb: TVkUInt32;
  begin
    tb := TypeBits;
    for i := 0 to ADevice.Ptr.PhysicalDevice.Ptr.MemoryPropertices^.memoryTypeCount - 1 do
    begin
      if (tb and 1) = 1 then
      begin
        if (ADevice.Ptr.PhysicalDevice.Ptr.MemoryPropertices^.memoryTypes[i].propertyFlags and RequirementsMask) = RequirementsMask then
        begin
          TypeIndex := i;
          Exit(True);
        end;
      end;
      tb := tb shr 1;
    end;
    Result := False;
  end;
  var image_info: TVkImageCreateInfo;
  var mem_info: TVkMemoryAllocateInfo;
  var view_info: TVkImageViewCreateInfo;
  var format_props: TVkFormatProperties;
  var mem_reqs: TVkMemoryRequirements;
begin
  LabLog('TLabDepthBuffer.Create', 2);
  _Device := ADevice;
  LabZeroMem(@image_info, SizeOf(TVkImageCreateInfo));
  _Format := VK_FORMAT_D16_UNORM;//_Device.Ptr.PhysicalDevice.Ptr.GetSupportedDepthFormat;
  Vulkan.GetPhysicalDeviceFormatProperties(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Format, @format_props);
  if (format_props.linearTilingFeatures and TVkFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT)) > 0 then
  begin
    image_info.tiling := VK_IMAGE_TILING_LINEAR;
  end
  else if (format_props.optimalTilingFeatures and TVkFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT)) > 0 then
  begin
    image_info.tiling := VK_IMAGE_TILING_OPTIMAL;
  end
  else
  begin
    LabLog('Error: cannot create depth buffer');
    Exit;
  end;
  image_info.sType := VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
  image_info.imageType := VK_IMAGE_TYPE_2D;
  image_info.format := _Format;
  image_info.extent.width := AWidth;
  image_info.extent.height := AHeight;
  image_info.extent.depth := 1;
  image_info.mipLevels := 1;
  image_info.arrayLayers := 1;
  image_info.samples := VK_SAMPLE_COUNT_1_BIT;
  image_info.initialLayout := VK_IMAGE_LAYOUT_UNDEFINED;
  image_info.usage := TVkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT);
  image_info.queueFamilyIndexCount := 0;
  image_info.pQueueFamilyIndices := nil;
  image_info.sharingMode := VK_SHARING_MODE_EXCLUSIVE;
  image_info.flags := 0;

  LabZeroMem(@mem_info, SizeOf(TVkMemoryAllocateInfo));
  mem_info.sType := VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  mem_info.allocationSize := 0;
  mem_info.memoryTypeIndex := 0;
  LabAssetVkError(Vulkan.CreateImage(_Device.Ptr.VkHandle, @image_info, nil, @_Image));
  Vulkan.GetImageMemoryRequirements(_Device.Ptr.VkHandle, _Image, @mem_reqs);

  mem_info.allocationSize := mem_reqs.size;
  if not MemoryTypeFromProperties(mem_reqs.memoryTypeBits, 0, mem_info.memoryTypeIndex) then
  begin
    LabLog('Error: could not find compatible memory type');
    Exit;
  end;
  LabAssetVkError(Vulkan.AllocateMemory(_Device.Ptr.VkHandle, @mem_info, nil, @_Memory));
  LabAssetVkError(Vulkan.BindImageMemory(_Device.Ptr.VkHandle, _Image, _Memory, 0));

  LabZeroMem(@view_info, SizeOf(TVkImageViewCreateInfo));
  view_info.sType := VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
  view_info.image := _Image;
  view_info.format := _Format;
  view_info.components.r := VK_COMPONENT_SWIZZLE_R;
  view_info.components.g := VK_COMPONENT_SWIZZLE_G;
  view_info.components.b := VK_COMPONENT_SWIZZLE_B;
  view_info.components.a := VK_COMPONENT_SWIZZLE_A;
  view_info.subresourceRange.aspectMask := TVkFlags(VK_IMAGE_ASPECT_DEPTH_BIT);
  view_info.subresourceRange.baseMipLevel := 0;
  view_info.subresourceRange.levelCount := 1;
  view_info.subresourceRange.baseArrayLayer := 0;
  view_info.subresourceRange.layerCount := 1;
  view_info.viewType := VK_IMAGE_VIEW_TYPE_2D;
  view_info.flags := 0;
  LabAssetVkError(Vulkan.CreateImageView(_Device.Ptr.VkHandle, @view_info, nil, @_View));
end;

destructor TLabDepthBuffer.Destroy;
begin
  if LabVkValidHandle(_View) then
  begin
    Vulkan.DestroyImageView(_Device.Ptr.VkHandle, _View, nil);
  end;
  if LabVkValidHandle(_Image) then
  begin
    Vulkan.DestroyImage(_Device.Ptr.VkHandle, _Image, nil);
  end;
  if LabVkValidHandle(_Memory) then
  begin
    Vulkan.FreeMemory(_Device.Ptr.VkHandle, _Memory, nil);
  end;
  inherited Destroy;
  LabLog('TLabDepthBuffer.Destroy', -2);
end;

end.
