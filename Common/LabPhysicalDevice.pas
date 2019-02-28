unit LabPhysicalDevice;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabMath;

type
  TLabPhysicalDevice = class (TLabClass)
  private
    var _PhysicalDevice: TVkPhysicalDevice;
    var _Properties: TVkPhysicalDeviceProperties;
    var _Features: TVkPhysicalDeviceFeatures;
    var _MemoryProperties: TVkPhysicalDeviceMemoryProperties;
    var _QueueFamilyProperties: array of TVkQueueFamilyProperties;
    function GetProperties: PVkPhysicalDeviceProperties; inline;
    function GetFeatures: PVkPhysicalDeviceFeatures; inline;
    function GetMemoryProperties: PVkPhysicalDeviceMemoryProperties; inline;
    function GetQueueFamilyProperties(const Index: Integer): PVkQueueFamilyProperties; inline;
    function GetQueueFamilyCount: Integer; inline;
  public
    constructor Create(const AVkPhysicalDevice: TVkPhysicalDevice);
    destructor Destroy; override;
    property VkHandle: TVkPhysicalDevice read _PhysicalDevice;
    property Properties: PVkPhysicalDeviceProperties read GetProperties;
    property Features: PVkPhysicalDeviceFeatures read GetFeatures;
    property MemoryPropertices: PVkPhysicalDeviceMemoryProperties read GetMemoryProperties;
    property QueueFamilyProperties[const Index: Integer]: PVkQueueFamilyProperties read GetQueueFamilyProperties;
    property QueueFamilyCount: Integer read GetQueueFamilyCount;
    function GetQueueFamiliyIndex(const QueueFlags: TVkQueueFlags): TVkUInt32;
    function GetSupportedDepthFormat: TVkFormat;
    function GetSupportedSampleCount(const PreferredCount: array of TVkSampleCountFlagBits): TVkSampleCountFlagBits;
    function ImageFormatProperties(
      const Format: TVkFormat;
      const ImageType: TVkImageType = VK_IMAGE_TYPE_2D;
      const Tiling: TVkImageTiling = VK_IMAGE_TILING_OPTIMAL;
      const Usage: TVkImageUsageFlags = TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT);
      const Flags: TVkImageCreateFlags = 0
    ): TVkImageFormatProperties;
  end;
  TLabPhysicalDeviceShared = specialize TLabSharedRef<TLabPhysicalDevice>;
  TLabPhysicalDeviceList = specialize TLabRefList<TLabPhysicalDeviceShared>;
  TLabPhysicalDeviceListShared = specialize TLabSharedRef<TLabPhysicalDeviceList>;

implementation

//TLabPhysicalDevice BEGIN
function TLabPhysicalDevice.GetProperties: PVkPhysicalDeviceProperties;
begin
  Result := @_Properties;
end;

function TLabPhysicalDevice.GetFeatures: PVkPhysicalDeviceFeatures;
begin
  Result := @_Features;
end;

function TLabPhysicalDevice.GetMemoryProperties: PVkPhysicalDeviceMemoryProperties;
begin
  Result := @_MemoryProperties;
end;

function TLabPhysicalDevice.GetQueueFamilyProperties(const Index: Integer): PVkQueueFamilyProperties;
begin
  Result := @_QueueFamilyProperties[Index];
end;

function TLabPhysicalDevice.GetQueueFamilyCount: Integer;
begin
  Result := Length(_QueueFamilyProperties);
end;

constructor TLabPhysicalDevice.Create(const AVkPhysicalDevice: TVkPhysicalDevice);
  var qfc: Integer;
begin
  _PhysicalDevice := AVkPhysicalDevice;
  Vulkan.GetPhysicalDeviceProperties(_PhysicalDevice, @_Properties);
  Vulkan.GetPhysicalDeviceFeatures(_PhysicalDevice, @_Features);
  Vulkan.GetPhysicalDeviceMemoryProperties(_PhysicalDevice, @_MemoryProperties);
  Vulkan.GetPhysicalDeviceQueueFamilyProperties(_PhysicalDevice, @qfc, nil);
  SetLength(_QueueFamilyProperties, qfc);
  Vulkan.GetPhysicalDeviceQueueFamilyProperties(_PhysicalDevice, @qfc, @_QueueFamilyProperties[0]);
end;

destructor TLabPhysicalDevice.Destroy;
begin
  inherited Destroy;
end;

function TLabPhysicalDevice.GetQueueFamiliyIndex(const QueueFlags: TVkQueueFlags): TVkUInt32;
  var i: Integer;
begin
  if (QueueFlags and TVkQueueFlags(VK_QUEUE_COMPUTE_BIT)) > 0 then
  begin
    for i := 0 to High(_QueueFamilyProperties) do
    begin
      if ((_QueueFamilyProperties[i].queueFlags and QueueFlags) > 0)
      and ((_QueueFamilyProperties[i].queueFlags and TVkQueueFlags(VK_QUEUE_GRAPHICS_BIT)) = 0) then
      begin
	Result := i;
	Exit;
      end;
    end;
  end;
  if (QueueFlags and TVkQueueFlags(VK_QUEUE_TRANSFER_BIT))  > 0 then
  begin
    for i := 0 to High(_QueueFamilyProperties) do
    begin
      if ((_QueueFamilyProperties[i].queueFlags and queueFlags) > 0)
      and ((_QueueFamilyProperties[i].queueFlags and TVkQueueFlags(VK_QUEUE_GRAPHICS_BIT)) = 0)
      and ((_QueueFamilyProperties[i].queueFlags and TVkQueueFlags(VK_QUEUE_COMPUTE_BIT)) = 0) then
      begin
	Result := i;
	Exit;
      end;
    end;
  end;
  for i := 0 to High(_QueueFamilyProperties) do
  begin
    if (_QueueFamilyProperties[i].queueFlags and TVkQueueFlags(QueueFlags)) > 0 then
    begin
      Result := i;
      Exit;
    end;
  end;
  Result := TVkUInt32(-1);
end;

function TLabPhysicalDevice.GetSupportedDepthFormat: TVkFormat;
  const depth_formats: array[0..4] of TVkFormat = (
    VK_FORMAT_D32_SFLOAT_S8_UINT,
    VK_FORMAT_D32_SFLOAT,
    VK_FORMAT_D24_UNORM_S8_UINT,
    VK_FORMAT_D16_UNORM_S8_UINT,
    VK_FORMAT_D16_UNORM
  );
  var format: TVkFormat;
  var format_props: TVkFormatProperties;
begin
  for format in depth_formats do
  begin
    Vulkan.GetPhysicalDeviceFormatProperties(_PhysicalDevice, format, @format_props);
    if (format_props.optimalTilingFeatures and TVkFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT)) > 0 then
    begin
      Result := format;
      Exit;
    end;
  end;
  Result := VK_FORMAT_UNDEFINED;
end;

function TLabPhysicalDevice.GetSupportedSampleCount(const PreferredCount: array of TVkSampleCountFlagBits): TVkSampleCountFlagBits;
  var counts: TVkSampleCountFlags;
  var i: TVkInt32;
begin
  counts := LabMin(_Properties.limits.framebufferColorSampleCounts, _Properties.limits.framebufferDepthSampleCounts);
  for i := 0 to High(PreferredCount) do
  begin
    if (TVkFlags(counts) and TVkFlags(PreferredCount[i])) > 0 then Exit(PreferredCount[i]);
  end;
  Result := VK_SAMPLE_COUNT_1_BIT;
end;

function TLabPhysicalDevice.ImageFormatProperties(
  const Format: TVkFormat;
  const ImageType: TVkImageType;
  const Tiling: TVkImageTiling;
  const Usage: TVkImageUsageFlags;
  const Flags: TVkImageCreateFlags
): TVkImageFormatProperties;
begin
  Vulkan.GetPhysicalDeviceImageFormatProperties(_PhysicalDevice, Format, ImageType, Tiling, Usage, Flags, @Result);
end;

//TLabPhysicalDevice END

end.
