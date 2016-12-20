unit LabPhysicalDevice;

interface

uses
  Vulkan,
  LabUtils;

type
  TLabPhysicalDevice = class (TInterfacedObject)
  private
    var _Vulkan: TVulkan;
    var _PhysicalDevice: TVkPhysicalDevice;
    var _Properties: TVkPhysicalDeviceProperties;
    var _Features: TVkPhysicalDeviceFeatures;
    var _MemoryProperties: TVkPhysicalDeviceMemoryProperties;
    var _QueueFamilyProperties: array of TVkQueueFamilyProperties;
    function GetProperties: PVkPhysicalDeviceProperties; inline;
    function GetFeatures: PVkPhysicalDeviceFeatures; inline;
    function GetMemoryProperties: PVkPhysicalDeviceMemoryProperties; inline;
  public
    constructor Create(const AVulkan: TVulkan; const AVkPhysicalDevice: TVkPhysicalDevice);
    destructor Destroy; override;
    property Vulkan: TVulkan read _Vulkan;
    property VkHandle: TVkPhysicalDevice read _PhysicalDevice;
    property Properties: PVkPhysicalDeviceProperties read GetProperties;
    property Features: PVkPhysicalDeviceFeatures read GetFeatures;
    property MemoryPropertices: PVkPhysicalDeviceMemoryProperties read GetMemoryProperties;
    function GetQueueFamiliyIndex(const QueueFlags: TVkQueueFlags): TVkUInt32;
    function GetSupportedDepthFormat: TVkFormat;
  end;
  TLabPhysicalDeviceRef = specialize TLabRefCounter<TLabPhysicalDevice>;
  TLabPhysicalDeviceList = specialize TLabListRef<TLabPhysicalDeviceRef>;
  TLabPhysicalDeviceListRef = specialize TLabRefCounter<TLabPhysicalDeviceList>;

implementation

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

constructor TLabPhysicalDevice.Create(const AVulkan: TVulkan; const AVkPhysicalDevice: TVkPhysicalDevice);
  var QueueFamilyCount: Integer;
begin
  _Vulkan := AVulkan;
  _PhysicalDevice := AVkPhysicalDevice;
  _Vulkan.GetPhysicalDeviceProperties(_PhysicalDevice, @_Properties);
  _Vulkan.GetPhysicalDeviceFeatures(_PhysicalDevice, @_Features);
  _Vulkan.GetPhysicalDeviceMemoryProperties(_PhysicalDevice, @_MemoryProperties);
  _Vulkan.GetPhysicalDeviceQueueFamilyProperties(_PhysicalDevice, @QueueFamilyCount, nil);
  SetLength(_QueueFamilyProperties, QueueFamilyCount);
  _Vulkan.GetPhysicalDeviceQueueFamilyProperties(_PhysicalDevice, @QueueFamilyCount, @_QueueFamilyProperties[0]);
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
  Result := VK_NULL_HANDLE;
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
    vk.GetPhysicalDeviceFormatProperties(_PhysicalDevice, format, @format_props);
    if (format_props.optimalTilingFeatures and TVkFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT)) > 0 then
    begin
      Result := format;
      Exit;
    end;
  end;
  Result := VK_FORMAT_UNDEFINED;
end;

end.
