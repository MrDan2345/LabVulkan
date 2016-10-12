unit LabPhysicalDevice;

interface

uses
  Vulkan,
  LabUtils;

type
  TLabRenderer = class;
  TLabPhysicalDevice = class (TInterfacedObject)
  private
    var _Renderer: TLabRenderer;
    var _PhysicalDevice: TVkPhysicalDevice;
    var _Properties: TVkPhysicalDeviceProperties;
    var _Features: TVkPhysicalDeviceFeatures;
    var _MemoryProperties: TVkPhysicalDeviceMemoryProperties;
    var _QueueFamilyProperties: array of TVkQueueFamilyProperties;
  public
    constructor Create(const ARenderer: TLabRenderer; const APhysicalDevice: TVkPhysicalDevice);
    destructor Destroy; override;
    property VkHandle: TVkPhysicalDevice read _PhysicalDevice;
    function GetQueueFamiliyIndex(const QueueFlags: TVkQueueFlagBits): TVkUInt32;
    function GetSupportedDepthFormat: TVkFormat;
  end;
  TLabPhysicalDeviceList = specialize TLabListRef<TLabPhysicalDevice>;

implementation

constructor TLabPhysicalDevice.Create(const ARenderer: TLabRenderer; const APhysicalDevice: TVkPhysicalDevice);
begin
  _Renderer := ARenderer;
  _PhysicalDevice := APhysicalDevice;
  vk.GetPhysicalDeviceProperties(_PhysicalDevice, @_Properties);
  vk.GetPhysicalDeviceFeatures(_PhysicalDevice, @_Features);
  vk.GetPhysicalDeviceMemoryProperties(_PhysicalDevice, @_MemoryProperties);
  vk.GetPhysicalDeviceQueueFamilyProperties(_PhysicalDevice, @queue_family_count, nil);
  Assert(queue_family_count > 0);
  SetLength(_QueueFamilyProperties, queue_family_count);
  vk.GetPhysicalDeviceQueueFamilyProperties(_PhysicalDevice, @queue_family_count, @_QueueFamilyProperties[0]);
end;

destructor TLabPhysicalDevice.Destroy;
begin
  inherited Destroy;
end;

function TLabPhysicalDevice.GetQueueFamiliyIndex(const QueueFlags: TVkQueueFlagBits): TVkUInt32;
  var i: Integer;
begin
  if (QueueFlags and VK_QUEUE_COMPUTE_BIT) > 0 then
  begin
    for i := 0 to High(_QueueFamilyPropertTLabPhysicalDeviceies) do
    begin
      if ((_QueueFamilyProperties[i].queueFlags and QueueFlags) > 0)
      and ((_QueueFamilyProperties[i].queueFlags and VK_QUEUE_GRAPHICS_BIT) == 0) then
      begin
	Result := i;
	Exit;
      end;
    end;
  end;
  if (QueueFlags and VK_QUEUE_TRANSFER_BIT)  > 0 then
  begin
    for i := 0 to High(_QueueFamilyProperties) do
    begin
      if ((_QueueFamilyProperties[i].queueFlags and queueFlags) > 0)
      and ((_QueueFamilyProperties[i].queueFlags and VK_QUEUE_GRAPHICS_BIT) = 0)
      and ((_QueueFamilyProperties[i].queueFlags and VK_QUEUE_COMPUTE_BIT) = 0) then
      begin
	Result := i;
	Exit;
      end;
    end;
  end;
  for i := 0 to High(_QueueFamilyProperties) do
  begin
    if (_QueueFamilyProperties[i].queueFlags and QueueFlags) then
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
    if (format_props.optimalTilingFeatures and VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT) > 0 then
    begin
      Result := format;
      Exit;
    end;
  end;
  Result := VK_FORMAT_UNDEFINED;
end;

end.
