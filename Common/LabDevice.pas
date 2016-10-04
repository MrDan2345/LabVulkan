unit LabDevice;

interface

uses
  Vulkan;

type
  TLabDevice = class (TInterfacedObject)
  private
    var _PhysicalDevice: TVkPhysicalDevice;
    var _Properties: TVkPhysicalDeviceProperties;
    var _Features: TVkPhysicalDeviceFeatures;
    var _MemoryProperties: TVkPhysicalDeviceMemoryProperties;
    var _QueueFamilyProperties: array of TVkQueueFamilyProperties;
  public
    constructor Create(const VkPhysicalDevice: TVkPhysicalDevice);
    destructor Destroy; override;
  end;

implementation

constructor TLabDevice.Create(
  const VkPhysicalDevice: TVkPhysicalDevice;
  const Features: TVkPhysicalDeviceFeatures;
);
  var queue_family_count: TVkUInt32;
begin
  _PhysicalDevice := VkPhysicalDevice;
  vk.GetPhysicalDeviceProperties(_PhysicalDevice, @_Properties);
  vk.GetPhysicalDeviceFeatures(_PhysicalDevice, @_Features);
  vk.GetPhysicalDeviceMemoryProperties(_PhysicalDevice, @_MemoryProperties);
  vk.GetPhysicalDeviceQueueFamilyProperties(_PhysicalDevice, @queue_family_count, nil);
  Assert(queue_family_count > 0);
  SetLength(_QueueFamilyProperties, queue_family_count);
  vk.GetPhysicalDeviceQueueFamilyProperties(_PhysicalDevice, @queue_family_count, @_QueueFamilyProperties[0]);
end;

destructor TLabDevice.Destroy;
begin
  inherited Destroy;
end;

end.
