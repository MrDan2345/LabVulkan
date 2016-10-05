unit LabRenderer;

interface

uses
  {$include LabPlatform.inc},
  Vulkan,
  LabUtils,
  LabPhysicalDevice,
  LabDevice,
  LabSwapChain;

type

  TLabRenderer = class (TInterfacedObject)
  private
    class var _VulkanEnabled: Boolean;
    class var _Extensions: array of String;
    var _Instance: TVkInstance;
    var _PhyisicalDevice: TLabPhysicalDevice;
    var _Device: TLabDevice;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    class procedure ResetExtensions;
    class procedure AddExtension(const Name: String);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

class constructor TLabRenderer.CreateClass;
begin
  _VulkanEnabled := LoadVulkanLibrary;
  if _VulkanEnabled then
  begin
    ResetExtensions;
{$if defined(Windows)}
    AddExtension(VK_KHR_WIN32_SURFACE_EXTENSION_NAME);
{$elseif defined(Android)}
    AddExtension(VK_KHR_ANDROID_SURFACE_EXTENSION_NAME);
{$elseif defined(Linux)}
    AddExtension(VK_KHR_XCB_SURFACE_EXTENSION_NAME);
{$endif}
  end;
end;

class destructor TLabRenderer.DestroyClass;
begin

end;

class procedure TLabRenderer.ResetExtensions;
begin
  SetLength(_Extensions, 1);
  _Extensions[0] := VK_KHR_SURFACE_EXTENSION_NAME;
end;

class procedure TLabRenderer.AddExtension(const Name: String);
begin
  SetLength(_Extensions, Length(_Extensions) + 1);
  _Extensions[High(_Extensions)] := Name;
end;

constructor TLabRenderer.Create;
  var AppInfo: TVkApplicationInfo;
  var InstanceCreateInfo: TVkInstanceCreateInfo;
  var gpu_count: TVkUInt32;
  var gpus: array of TVkPhysicslDevice;
  var physical_device_features: TVkPhysicalDeviceFeatures;
  var depth_format: TVkFormat;
begin
  LabZeroMem(@AppInfo, SizeOf(TVkApplicationInfo));
  AppInfo.sType := VK_STRUCTURE_TYPE_APPLICATION_INFO;
  AppInfo.pApplicationName := 'Lab Vulkan';
  AppInfo.pEngineName := 'Lab Vulkan';
  AppInfo.apiVersion := VK_API_VERSION_1_0;

  LabZeroMem(@InstanceCreateInfo, SizeOf(TVkInstanceCreateInfo));
  InstanceCreateInfo.sType := VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  InstanceCreateInfo.enabledExtensionCount := Length(_Extensions);
  InstanceCreateInfo.ppEnabledExtensionNames := PPVkChar(Pointer(@_Extensions[0]));
  LabAssetVkError(vk.CreateInstance(@InstanceCreateInfo, nil, @_Instance));
  gpu_count := 0;
  LabAssetVkError(vk.EnumeratePhysicalDevices(_Instance, @gpu_count, nil));
  Assert(gpu_count > 0);
  SetLength(gpus, gpu_count);
  LabAssetVkError(vk.EnumeratePhysicalDevices(_Instance, @gpu_count, @gpus));
  _PhysicalDevice := TLabPhysicalDevice.Create(gpus[0]);
  LabZeroMem(@physical_device_features, SizeOf(TVkPhysicalDeviceFeatures));
  _Device := TLabDevice.Create(_PhysicalDevice, physical_device_features);
  depth_format := _PhyisicalDevice.GetSupportedDepthFormat;
end;

destructor TLabRenderer.Destroy;
begin
  if Assigned(_Instance) then
  begin
    vk.DestroyInstance(instance, nullptr);
  end;
  _Device := nil;
  _PhysicalDevice := nil;
  inherited Destroy;
end;

end.
