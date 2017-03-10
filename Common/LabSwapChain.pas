unit LabSwapChain;

{$include LabPlatform.inc}
interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabSync,
  LabWindow,
  LabPhysicalDevice,
  LabDevice;

type
  TLabSwapChain = class (TLabClass)
  public
    type TImageBuffer = record
      Image: TVkImage;
      View: TVkImageView;
    end;
    type PImageBuffer = ^TImageBuffer;
  private
    var _Window: TLabWindow;
    var _Device: TLabDeviceShared;
    var _Surface: TVkSurfaceKHR;
    var _Handle: TVkSwapchainKHR;
    var _Capabilities: TVkSurfaceCapabilitiesKHR;
    var _Formats: array of TVkSurfaceFormatKHR;
    var _Format: TVkFormat;
    var _PresentModes: array of TVkPresentModeKHR;
    var _PresentMode: TVkPresentModeKHR;
    var _Extent: TVkExtent2D;
    var _Images: array of TImageBuffer;
    var _QueueFamilyGraphics: TVkUInt32;
    var _QueueFamilyPresent: TVkUInt32;
    procedure Setup;
    function GetWidth: TVkUInt32; inline;
    function GetHeight: TVkUInt32; inline;
    function GetImageBuffer(const Index: TVkInt32): PImageBuffer; inline;
    function GetImageCount: TVkInt32; inline;
  public
    class function GetSurfacePlatformExtension: AnsiString;
    property VkSurface: TVkSurfaceKHR read _Surface;
    property VkHandle: TVkSwapchainKHR read _Handle;
    property Width: TVkUInt32 read GetWidth;
    property Height: TVkUInt32 read GetHeight;
    property Format: TVkFormat read _Format;
    property Images[const Index: TVkInt32]: PImageBuffer read GetImageBuffer;
    property ImageCount: TVkInt32 read GetImageCount;
    property QueueFamilyGraphics: TVkUInt32 read _QueueFamilyGraphics;
    property QueueFamilyPresent: TVkUInt32 read _QueueFamilyPresent;
    constructor Create(
      const AWindow: TLabWindow;
      const ADevice: TLabDeviceShared
    );
    destructor Destroy; override;
    function AcquireNextImage(const Semaphore: TLabSemaphoreShared): TVkUInt32;
  end;
  TLabSwapChainShared = specialize TLabSharedRef<TLabSwapChain>;

implementation

//TLabSwapChain BEGIN
procedure TLabSwapChain.Setup;
  var queue_family_graphics_present: array[0..1] of TVkUInt32;
  var i, format_count, present_mode_count, image_count: TVkUInt32;
  var present_support: TVkBool32;
  var pre_transform: TVkSurfaceTransformFlagBitsKHR;
  var swap_chain_create_info: TVkSwapchainCreateInfoKHR;
  var image_view_create_info: TVkImageViewCreateInfo;
  var swapchain_images: array of TVkImage;
begin
  queue_family_graphics_present[0] := TVkUInt32(-1);
  queue_family_graphics_present[1] := TVkUInt32(-1);
  for i := 0 to _Device.Ptr.PhysicalDevice.Ptr.QueueFamilyCount - 1 do
  begin
    if _Device.Ptr.PhysicalDevice.Ptr.QueueFamilyProperties[i]^.queueFlags and TVkFlags(VK_QUEUE_GRAPHICS_BIT) > 0 then
    begin
      queue_family_graphics_present[0] := i;
    end;
    Vulkan.GetPhysicalDeviceSurfaceSupportKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, i, _Surface, @present_support);
    if present_support = VK_TRUE then
    begin
      queue_family_graphics_present[1] := i;
      if queue_family_graphics_present[0] = queue_family_graphics_present[1] then Break;
    end;
  end;
  if (queue_family_graphics_present[0] = TVkUInt32(-1))
  or (queue_family_graphics_present[1] = TVkUInt32(-1)) then
  begin
    LabLog('Error: could not setup swap chain.');
    Exit;
  end;
  LabAssertVkError(Vulkan.GetPhysicalDeviceSurfaceCapabilitiesKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Surface, @_Capabilities));
  LabAssertVkError(Vulkan.GetPhysicalDeviceSurfaceFormatsKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Surface, @format_count, nil));
  SetLength(_Formats, format_count);
  LabAssertVkError(Vulkan.GetPhysicalDeviceSurfaceFormatsKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Surface, @format_count, @_Formats[0]));
  if (format_count = 1) and (_Formats[0].format = VK_FORMAT_UNDEFINED) then
  begin
    _Format := VK_FORMAT_B8G8R8A8_UNORM;
  end
  else
  begin
    _Format := _Formats[0].format;
  end;
  LabAssertVkError(Vulkan.GetPhysicalDeviceSurfacePresentModesKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Surface, @present_mode_count, nil));
  SetLength(_PresentModes, present_mode_count);
  LabAssertVkError(Vulkan.GetPhysicalDeviceSurfacePresentModesKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Surface, @present_mode_count, @_PresentModes[0]));
  if present_mode_count > 0 then _PresentMode := _PresentModes[0] else _PresentMode := VK_PRESENT_MODE_FIFO_KHR;
  for i := 0 to High(_PresentModes) do
  if _PresentModes[i] = VK_PRESENT_MODE_FIFO_KHR then
  begin
    _PresentMode := _PresentModes[i];
    Break;
  end;
  if _Capabilities.currentExtent.width = $FFFFFFFF then
  begin
    _Extent.width := _Window.Width;
    _Extent.height := _Window.Height;
    if _Extent.width < _Capabilities.minImageExtent.width then
    begin
      _Extent.width := _Capabilities.minImageExtent.width;
    end
    else if _Extent.width > _Capabilities.maxImageExtent.width then
    begin
      _Extent.width := _Capabilities.maxImageExtent.width;
    end;
    if _Extent.height < _Capabilities.minImageExtent.height then
    begin
      _Extent.height := _Capabilities.minImageExtent.height;
    end
    else if _Extent.height > _Capabilities.maxImageExtent.height then
    begin
      _Extent.height := _Capabilities.maxImageExtent.height;
    end;
  end
  else
  begin
    _Extent := _Capabilities.currentExtent;
  end;
  if (_Capabilities.supportedTransforms and TVkFlags(VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR)) > 0 then
  begin
    pre_transform := VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
  end
  else
  begin
    pre_transform := _Capabilities.currentTransform;
  end;
  LabZeroMem(@swap_chain_create_info, SizeOf(TVkSwapchainCreateInfoKHR));
  swap_chain_create_info.sType := VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
  swap_chain_create_info.surface := _Surface;
  swap_chain_create_info.minImageCount := _Capabilities.minImageCount;
  swap_chain_create_info.imageFormat := _Format;
  swap_chain_create_info.imageExtent.width := _Extent.width;
  swap_chain_create_info.imageExtent.height := _Extent.height;
  swap_chain_create_info.preTransform := pre_transform;
  swap_chain_create_info.compositeAlpha := VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
  swap_chain_create_info.imageArrayLayers := 1;
  swap_chain_create_info.presentMode := _PresentMode;
  swap_chain_create_info.oldSwapchain := VK_NULL_HANDLE;
  swap_chain_create_info.clipped := VK_TRUE;
  swap_chain_create_info.imageColorSpace := VK_COLORSPACE_SRGB_NONLINEAR_KHR;
  swap_chain_create_info.imageUsage := TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT);
  swap_chain_create_info.imageSharingMode := VK_SHARING_MODE_EXCLUSIVE;
  swap_chain_create_info.queueFamilyIndexCount := 0;
  swap_chain_create_info.pQueueFamilyIndices := nil;
  if queue_family_graphics_present[0] <> queue_family_graphics_present[1] then
  begin
    swap_chain_create_info.imageSharingMode := VK_SHARING_MODE_CONCURRENT;
    swap_chain_create_info.queueFamilyIndexCount := 2;
    swap_chain_create_info.pQueueFamilyIndices := @queue_family_graphics_present[0];
  end;
  _QueueFamilyGraphics := queue_family_graphics_present[0];
  _QueueFamilyPresent := queue_family_graphics_present[1];
  LabAssertVkError(Vulkan.CreateSwapchainKHR(_Device.Ptr.VkHandle, @swap_chain_create_info, nil, @_Handle));
  LabAssertVkError(Vulkan.GetSwapchainImagesKHR(_Device.Ptr.VkHandle, _Handle, @image_count, nil));
  SetLength(_Images, image_count);
  SetLength(swapchain_images, image_count);
  LabAssertVkError(Vulkan.GetSwapchainImagesKHR(_Device.Ptr.VkHandle, _Handle, @image_count, @swapchain_images[0]));
  for i := 0 to image_count - 1 do
  begin
    _Images[i].Image := swapchain_images[i];
    LabZeroMem(@image_view_create_info, SizeOf(TVkImageViewCreateInfo));
    image_view_create_info.sType := VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    image_view_create_info.flags := 0;
    image_view_create_info.image := _Images[i].Image;
    image_view_create_info.viewType := VK_IMAGE_VIEW_TYPE_2D;
    image_view_create_info.format := _Format;
    image_view_create_info.components.r := VK_COMPONENT_SWIZZLE_R;
    image_view_create_info.components.g := VK_COMPONENT_SWIZZLE_G;
    image_view_create_info.components.b := VK_COMPONENT_SWIZZLE_B;
    image_view_create_info.components.a := VK_COMPONENT_SWIZZLE_A;
    image_view_create_info.subresourceRange.aspectMask := TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT);
    image_view_create_info.subresourceRange.baseMipLevel := 0;
    image_view_create_info.subresourceRange.levelCount := 1;
    image_view_create_info.subresourceRange.baseArrayLayer := 0;
    image_view_create_info.subresourceRange.layerCount := 1;
    LabAssertVkError(Vulkan.CreateImageView(_Device.Ptr.VkHandle, @image_view_create_info, nil, @_Images[i].View));
  end;
end;

function TLabSwapChain.GetWidth: TVkUInt32;
begin
  Result := _Extent.width;
end;

function TLabSwapChain.GetHeight: TVkUInt32;
begin
  Result := _Extent.height;
end;

function TLabSwapChain.GetImageBuffer(const Index: TVkInt32): PImageBuffer;
begin
  Result := @_Images[Index];
end;

function TLabSwapChain.GetImageCount: TVkInt32;
begin
  Result := Length(_Images);
end;

class function TLabSwapChain.GetSurfacePlatformExtension: AnsiString;
begin
{$if defined(Windows)}
  Result := VK_KHR_WIN32_SURFACE_EXTENSION_NAME;
{$elseif defined(Android)}
  Result := VK_KHR_ANDROID_SURFACE_EXTENSION_NAME;
{$elseif defined(Linux)}
  Result := VK_KHR_XCB_SURFACE_EXTENSION_NAME;
{$else}
  LabLog('Error: Surface platform extension not specified');
{$endif}
end;

{$if defined(VK_USE_PLATFORM_WIN32_KHR)}
constructor TLabSwapChain.Create(
  const AWindow: TLabWindow;
  const ADevice: TLabDeviceShared
);
  var surface_create_info: TVkWin32SurfaceCreateInfoKHR;
begin
  LabLog('TLabSwapChain.Create', 2);
  inherited Create;
  _Window := AWindow;
  _Device := ADevice;
  LabZeroMem(@surface_create_info, SizeOf(TVkWin32SurfaceCreateInfoKHR));
  surface_create_info.sType := VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
  surface_create_info.hinstance_ := _Window.Instance;
  surface_create_info.hwnd_ := _Window.Handle;
  LabAssertVkError(Vulkan.CreateWin32SurfaceKHR(VulkanInstance, @surface_create_info, nil, @_Surface));
  Setup;
end;
{$elseif defined(VK_USE_PLATFORM_ANDROID_KHR)}
constructor TLabSwapChain.Create(
  const AWindow: TLabWindow;
  const ADevice: TLabDeviceRef
);
  var surface_create_info: TVkAndroidSurfaceCreateInfoKHR;
begin
  LabLog('TLabSwapChain.Create', 2);
  inherited Create;
  _Window := AWindow;
  _Device := ADevice;
  LabZeroMem(@surface_create_info, SizeOf(TVkAndroidSurfaceCreateInfoKHR));
  VkAndroidSurfaceCreateInfoKHR createInfo;
  surface_create_info.sType := VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR;
  surface_create_info.flags := 0;
  surface_create_info.window := AndroidGetApplicationWindow();
  LabAssetVkError(Vulkan.CreateAndroidSurfaceKHR(VulkanInstance, @surface_create_info, nil, @_Surface);
  Setup;
end;
{$elseif defined(VK_USE_PLATFORM_XCB_KHR)}
constructor TLabSwapChain.Create(
  const AWindow: TLabWindow;
  const ADevice: TLabDeviceRef
);
  var surface_create_info: TVkXcbSurfaceCreateInfoKHR;
begin
  LabLog('TLabSwapChain.Create', 2);
  inherited Create;
  _Window := AWindow;
  _Device := ADevice;
  LabZeroMem(@surface_create_info, SizeOf(TVkXcbSurfaceCreateInfoKHR));
  surface_create_info.sType := VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR;
  surface_create_info.connection := Window.Connection;
  surface_create_info.window := Window.Handle;
  LabAssetVkError(Vulkan.CreateXcbSurfaceKHR(VulkanInstance, @surface_create_info, nil, @_Surface);
  Setup;
end;
{$else}
constructor TLabSwapChain.Create(const Window: TLabWindow);
begin
  Halt;
end;
{$endif}

destructor TLabSwapChain.Destroy;
  var i: TVkInt32;
begin
  for i := 0 to High(_Images) do
  if LabVkValidHandle(_Images[i].View) then
  begin
    Vulkan.DestroyImageView(_Device.Ptr.VkHandle, _Images[i].View, nil);
  end;
  if LabVkValidHandle(_Handle) then
  begin
    vkDestroySwapchainKHR(_Device.Ptr.VkHandle, _Handle, nil);
  end;
  if LabVkValidHandle(_Surface) then
  begin
    Vulkan.DestroySurfaceKHR(VulkanInstance, _Surface, nil);
  end;
  inherited Destroy;
  LabLog('TLabSwapChain.Destroy', -2);
end;

function TLabSwapChain.AcquireNextImage(const Semaphore: TLabSemaphoreShared): TVkUInt32;
begin
  LabAssertVkError(
    Vulkan.AcquireNextImageKHR(
      _Device.Ptr.VkHandle,
      _Handle,
      High(TVkUInt64),
      Semaphore.Ptr.VkHandle,
      VK_NULL_HANDLE,
      @Result
    )
  );
end;

end.
