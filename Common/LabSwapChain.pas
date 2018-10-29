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
  LabImage,
  LabDevice,
  LabSurface;

type
  TLabSwapChain = class (TLabClass)
  public
    type TImageBuffer = record
      Image: TVkImage;
      View: TLabImageView;
    end;
    type PImageBuffer = ^TImageBuffer;
  private
    var _Device: TLabDeviceShared;
    var _Surface: TLabSurfaceShared;
    var _Handle: TVkSwapchainKHR;
    var _Format: TVkFormat;
    var _Extent: TVkExtent2D;
    var _Images: array of TImageBuffer;
    var _QueueFamilyIndexGraphics: TVkUInt32;
    var _QueueFamilyIndexCompute: TVkUInt32;
    var _QueueFamilyIndexPresent: TVkUInt32;
    var _QueueFamilyGraphics: TVkQueue;
    var _QueueFamilyCompute: TVkQueue;
    var _QueueFamilyPresent: TVkQueue;
    var _CurImage: TVkUInt32;
    function GetWidth: TVkUInt32; inline;
    function GetHeight: TVkUInt32; inline;
    function GetImageBuffer(const Index: TVkInt32): PImageBuffer; inline;
    function GetImageCount: TVkInt32; inline;
  public
    property VkHandle: TVkSwapchainKHR read _Handle;
    property Width: TVkUInt32 read GetWidth;
    property Height: TVkUInt32 read GetHeight;
    property Format: TVkFormat read _Format;
    property Images[const Index: TVkInt32]: PImageBuffer read GetImageBuffer;
    property ImageCount: TVkInt32 read GetImageCount;
    property QueueFamilyIndexGraphics: TVkUInt32 read _QueueFamilyIndexGraphics;
    property QueueFamilyIndexCompute: TVkUInt32 read _QueueFamilyIndexCompute;
    property QueueFamilyIndexPresent: TVkUInt32 read _QueueFamilyIndexPresent;
    property QueueFamilyGraphics: TVkQueue read _QueueFamilyGraphics;
    property QueueFamilyCompute: TVkQueue read _QueueFamilyCompute;
    property QueueFamilyPresent: TVkQueue read _QueueFamilyPresent;
    property CurImage: TVkUInt32 read _CurImage;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ASurface: TLabSurfaceShared;
      const AUsageFlags: TVkImageUsageFlags = TVkImageUsageFlags(
        TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
      )
    );
    destructor Destroy; override;
    function AcquireNextImage(const Semaphore: TLabSemaphoreShared): TVkResult;
  end;
  TLabSwapChainShared = specialize TLabSharedRef<TLabSwapChain>;

implementation

//TLabSwapChain BEGIN
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

constructor TLabSwapChain.Create(
  const ADevice: TLabDeviceShared;
  const ASurface: TLabSurfaceShared;
  const AUsageFlags: TVkImageUsageFlags
);
  var queue_family_index_count: TVkInt32;
  var queue_family_indices: array[0..2] of TVkUInt32;
  function AddQueueFamilyIndex(const Index: TVkUInt32): TVkUInt32;
    var i: TVkInt32;
  begin
    for i := 0 to queue_family_index_count - 1 do
    if queue_family_indices[i] = Index then Exit(i);
    queue_family_indices[queue_family_index_count] := Index;
    Result := queue_family_index_count;
    Inc(queue_family_index_count);
  end;
  var r: TVkResult;
  var supports_present: array of TVkBool32;
  var surf_formats: array of TVkSurfaceFormatKHR;
  var format_count: TVkUInt32;
  var surf_caps: TVkSurfaceCapabilitiesKHR;
  var present_mode_count: TVkUInt32;
  var present_modes: array of TVkPresentModeKHR;
  var swapchain_present_mode: TVkPresentModeKHR;
  var desired_number_of_swap_chain_images: TVkUInt32;
  var pre_transform: TVkSurfaceTransformFlagBitsKHR;
  var composite_alpha: TVkCompositeAlphaFlagBitsKHR;
  var composite_alpha_flags: array[0..3] of TVkCompositeAlphaFlagBitsKHR;
  var swapchain_ci: TVkSwapchainCreateInfoKHR;
  var swapchain_images: array of TVkImage;
  var swapchain_image_count: TVkUInt32;
  var buffer: TImageBuffer;
  var color_image_view: TVkImageViewCreateInfo;
  var i: TVkUInt32;
begin
  LabLog('TLabSwapChain.Create');
  _Device := ADevice;
  _Surface := ASurface;
  _CurImage := $ffffffff;

  SetLength(supports_present, _Device.Ptr.PhysicalDevice.Ptr.QueueFamilyCount);
  for i := 0 to _Device.Ptr.PhysicalDevice.Ptr.QueueFamilyCount - 1 do
  begin
    Vulkan.GetPhysicalDeviceSurfaceSupportKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, i, _Surface.Ptr.VkHandle, @supports_present[i]);
  end;

  // Search for a graphics and a present queue in the array of queue
  // families, try to find one that supports both
  _QueueFamilyIndexGraphics := High(TVkUInt32);
  _QueueFamilyIndexCompute := High(TVkUInt32);
  _QueueFamilyIndexPresent := High(TVkUInt32);
  for i := 0 to _Device.Ptr.PhysicalDevice.Ptr.QueueFamilyCount - 1 do
  begin
    if ((_Device.Ptr.PhysicalDevice.Ptr.QueueFamilyProperties[i]^.queueFlags and TVkFlags(VK_QUEUE_GRAPHICS_BIT)) <> 0) then
    begin
      if (_QueueFamilyIndexGraphics = High(TVkUInt32)) then _QueueFamilyIndexGraphics := i;
      if (supports_present[i] = VK_TRUE) then
      begin
        _QueueFamilyIndexGraphics := i;
        _QueueFamilyIndexPresent := i;
        Break;
      end;
    end;
  end;

  for i := 0 to _Device.Ptr.PhysicalDevice.Ptr.QueueFamilyCount - 1 do
  if _Device.Ptr.PhysicalDevice.Ptr.QueueFamilyProperties[i]^.queueFlags and TVkFlags(VK_QUEUE_COMPUTE_BIT) <> 0 then
  begin
    _QueueFamilyIndexCompute := i;
    Break;
  end;

  if (_QueueFamilyIndexPresent = High(TVkUInt32)) then
  begin
    // If didn't find a queue that supports both graphics and present, then
    // find a separate present queue.
    for i := 0 to _Device.Ptr.PhysicalDevice.Ptr.QueueFamilyCount - 1 do
    if (supports_present[i] = VK_TRUE) then
    begin
      _QueueFamilyIndexPresent := i;
      Break;
    end;
  end;

  // Generate error if could not find queues that support graphics
  // and present
  if (_QueueFamilyIndexGraphics = High(TVkUInt32))
  or (_QueueFamilyIndexPresent = High(TVkUInt32)) then
  begin
    WriteLn('Could not find a queues for both graphics and present');
    Halt;
  end;

  // Get the list of VkFormats that are supported:
  r := Vulkan.GetPhysicalDeviceSurfaceFormatsKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Surface.Ptr.VkHandle, @format_count, nil);
  LabAssertVkError(r);
  SetLength(surf_formats, format_count);
  r := Vulkan.GetPhysicalDeviceSurfaceFormatsKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Surface.Ptr.VkHandle, @format_count, @surf_formats[0]);
  LabAssertVkError(r);
  // If the format list includes just one entry of VK_FORMAT_UNDEFINED,
  // the surface has no preferred format.  Otherwise, at least one
  // supported format will be returned.
  if (format_count = 1) and (surf_formats[0].format = VK_FORMAT_UNDEFINED) then
  begin
    _Format := VK_FORMAT_B8G8R8A8_UNORM;
  end
  else
  begin
    assert(format_count >= 1);
    _Format := surf_formats[0].format;
  end;

  r := Vulkan.GetPhysicalDeviceSurfaceCapabilitiesKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Surface.Ptr.VkHandle, @surf_caps);
  LabAssertVkError(r);

  r := Vulkan.GetPhysicalDeviceSurfacePresentModesKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Surface.Ptr.VkHandle, @present_mode_count, nil);
  LabAssertVkError(r);
  SetLength(present_modes, present_mode_count);
  assert(Length(present_modes) > 0);
  r := Vulkan.GetPhysicalDeviceSurfacePresentModesKHR(_Device.Ptr.PhysicalDevice.Ptr.VkHandle, _Surface.Ptr.VkHandle, @present_mode_count, @present_modes[0]);
  LabAssertVkError(r);

  // width and height are either both 0xFFFFFFFF, or both not 0xFFFFFFFF.
  if (surf_caps.currentExtent.width = $FFFFFFFF) then
  begin
    // If the surface size is undefined, the size is set to
    // the size of the images requested.
    _Extent.width := _Surface.Ptr.Width;
    _Extent.height := _Surface.Ptr.Height;
    if (_Extent.width < surf_caps.minImageExtent.width) then
    begin
      _Extent.width := surf_caps.minImageExtent.width;
    end
    else if (_Extent.width > surf_caps.maxImageExtent.width) then
    begin
      _Extent.width := surf_caps.maxImageExtent.width;
    end;

    if (_Extent.height < surf_caps.minImageExtent.height) then
    begin
      _Extent.height := surf_caps.minImageExtent.height;
    end
    else if (_Extent.height > surf_caps.maxImageExtent.height) then
    begin
      _Extent.height := surf_caps.maxImageExtent.height;
    end;
  end
  else
  begin
    // If the surface size is defined, the swap chain size must match
    _Extent := surf_caps.currentExtent;
  end;

  // The FIFO present mode is guaranteed by the spec to be supported
  // Also note that current Android driver only supports FIFO
  swapchain_present_mode := VK_PRESENT_MODE_FIFO_KHR;

  // Determine the number of VkImage's to use in the swap chain.
  // We need to acquire only 1 presentable image at at time.
  // Asking for minImageCount images ensures that we can acquire
  // 1 presentable image as long as we present it before attempting
  // to acquire another.
  desired_number_of_swap_chain_images := surf_caps.minImageCount;

  if surf_caps.supportedTransforms and TVkFlags(VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR) > 0 then
  begin
    pre_transform := VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
  end
  else
  begin
    pre_transform := surf_caps.currentTransform;
  end;

  // Find a supported composite alpha mode - one of these is guaranteed to be set
  composite_alpha := VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
  composite_alpha_flags[0] := VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
  composite_alpha_flags[1] := VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR;
  composite_alpha_flags[2] := VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR;
  composite_alpha_flags[3] := VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR;
  for i := 0 to High(composite_alpha_flags) do
  begin
    if surf_caps.supportedCompositeAlpha and TVkFlags(composite_alpha_flags[i]) > 0 then
    begin
      composite_alpha := composite_alpha_flags[i];
      Break;
    end;
  end;

  queue_family_index_count := 0;
  _QueueFamilyIndexGraphics := AddQueueFamilyIndex(_QueueFamilyIndexGraphics);
  _QueueFamilyIndexCompute := AddQueueFamilyIndex(_QueueFamilyIndexCompute);
  _QueueFamilyIndexPresent := AddQueueFamilyIndex(_QueueFamilyIndexPresent);

  FillChar(swapchain_ci, sizeof(swapchain_ci), 0);
  swapchain_ci.sType := VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
  swapchain_ci.pNext := nil;
  swapchain_ci.surface := _Surface.Ptr.VkHandle;
  swapchain_ci.minImageCount := desired_number_of_swap_chain_images;
  swapchain_ci.imageFormat := _Format;
  swapchain_ci.imageExtent.width := _Extent.width;
  swapchain_ci.imageExtent.height := _Extent.height;
  swapchain_ci.preTransform := pre_transform;
  swapchain_ci.compositeAlpha := composite_alpha;
  swapchain_ci.imageArrayLayers := 1;
  swapchain_ci.presentMode := swapchain_present_mode;
  swapchain_ci.oldSwapchain := VK_NULL_HANDLE;
{$ifndef __ANDROID__}
  swapchain_ci.clipped := VK_TRUE;
{$else}
  swapchain_ci.clipped := VK_FALSE;
{$endif}
  swapchain_ci.imageColorSpace := VK_COLORSPACE_SRGB_NONLINEAR_KHR;
  swapchain_ci.imageUsage := AUsageFlags;
  swapchain_ci.imageSharingMode := VK_SHARING_MODE_EXCLUSIVE;
  swapchain_ci.queueFamilyIndexCount := queue_family_index_count;
  swapchain_ci.pQueueFamilyIndices := @queue_family_indices;
  //uint32_t queueFamilyIndices[2] = {(uint32_t)info.graphics_queue_family_index, (uint32_t)info.present_queue_family_index};
  if (_QueueFamilyIndexGraphics <> _QueueFamilyIndexPresent) then
  begin
    // If the graphics and present queues are from different queue families,
    // we either have to explicitly transfer ownership of images between the
    // queues, or we have to create the swapchain with imageSharingMode
    // as VK_SHARING_MODE_CONCURRENT
    swapchain_ci.imageSharingMode := VK_SHARING_MODE_CONCURRENT;
  end;

  r := Vulkan.CreateSwapchainKHR(_Device.Ptr.VkHandle, @swapchain_ci, nil, @_Handle);
  LabAssertVkError(r);

  r := Vulkan.GetSwapchainImagesKHR(_Device.Ptr.VkHandle, _Handle, @swapchain_image_count, nil);
  LabAssertVkError(r);

  SetLength(swapchain_images, swapchain_image_count);
  assert(Length(swapchain_images) > 0);
  r := Vulkan.GetSwapchainImagesKHR(_Device.Ptr.VkHandle, _Handle, @swapchain_image_count, @swapchain_images[0]);
  LabAssertVkError(r);

  for i := 0 to swapchain_image_count - 1 do
  begin
    buffer.Image := swapchain_images[i];
    buffer.View := TLabImageView.Create(
      _Device, swapchain_images[i], _Format,
      TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT),
      VK_IMAGE_VIEW_TYPE_2D
    );
    SetLength(_Images, Length(_Images) + 1);
    _Images[High(_Images)] := buffer;
  end;

  _QueueFamilyIndexGraphics := queue_family_indices[_QueueFamilyIndexGraphics];
  _QueueFamilyIndexCompute := queue_family_indices[_QueueFamilyIndexCompute];
  _QueueFamilyIndexPresent := queue_family_indices[_QueueFamilyIndexPresent];
  Vulkan.GetDeviceQueue(_Device.Ptr.VkHandle, _QueueFamilyIndexGraphics, 0, @_QueueFamilyGraphics);
  Vulkan.GetDeviceQueue(_Device.Ptr.VkHandle, _QueueFamilyIndexCompute, 0, @_QueueFamilyCompute);
  Vulkan.GetDeviceQueue(_Device.Ptr.VkHandle, _QueueFamilyIndexPresent, 0, @_QueueFamilyPresent);
end;

destructor TLabSwapChain.Destroy;
  var i: TVkInt32;
begin
  for i := 0 to High(_Images) do _Images[i].View.Free;
  if LabVkValidHandle(_Handle) then
  begin
    Vulkan.DestroySwapchainKHR(_Device.Ptr.VkHandle, _Handle, nil);
  end;
  inherited Destroy;
  LabLog('TLabSwapChain.Destroy');
end;

function TLabSwapChain.AcquireNextImage(const Semaphore: TLabSemaphoreShared): TVkResult;
begin
  Result := Vulkan.AcquireNextImageKHR(
    _Device.Ptr.VkHandle,
    _Handle,
    High(TVkUInt64),
    Semaphore.Ptr.VkHandle,
    VK_NULL_HANDLE,
    @_CurImage
  );
end;

end.
