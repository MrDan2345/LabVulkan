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

  TLabExtension = record
    Name: AnsiString;
    SpecVersion: TVkUInt32;
  end;

  TLabLayer = record
    Name: AnsiString;
    SpecVersion: TVkUInt32;
    ImplementationVersion: TVkUInt32;
    Description: AnsiString;
    Extensions: array of TLabExtension;
  end;
  PLabLayer = ^TLabLayer;

  TLabRenderer = class (TInterfacedObject)
  private
    class var _VulkanEnabled: Boolean;
    class var _Layers: array of TLabLayer;
    class var _ExtensionsEnabled: TLabListString;
    class var _LayersEnabled: TLabListString;
    var _Instance: TVkInstance;
    var _Vulkan: TVulkan;
    var _PhysicalDevices: TLabPhysicalDeviceList;
    class function GetLayer(const Index: Integer): PLabLayer; inline;
    class function GetLayerCount: Integer; inline;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    class property Layers[const Index: Integer]: PLabLayer read GetLayer;
    class property LayerCount: Integer read GetLayerCount;
    class function FindLayer(const Name: AnsiString): PLabLayer;
    class procedure ResetExtensions;
    class procedure EnableExtension(const Name: AnsiString);
    class procedure DisableExtension(const Name: AnsiString);
    class procedure ResetLayers;
    class procedure EnableLayer(const Name: AnsiString);
    class procedure DisableLayer(const Name: AnsiString);
    constructor Create(const AppName: AnsiString = 'Lab Vulkan'; const EngineName: AnsiString = 'Lab Vulkan');
    destructor Destroy; override;
    property VkHandle: TVkInstance read _Instance;
    property Vulkan: TVulkan read _Vulkan;
    property PhysicalDevices: TLabPhysicalDeviceList read _PhysicalDevices;
  end;

implementation

class function TLabRenderer.GetLayer(const Index: Integer): PLabLayer;
begin
  Result := @_Layers[Index];
end;

class function TLabRenderer.GetLayerCount: Integer;
begin
  Result := Length(_Layers);
end;

class constructor TLabRenderer.CreateClass;
  var i, j: Integer;
  var LayerCount, ExtensionCount: TVkUInt32;
  var LayerProperties: array of TVkLayerProperties;
  var ExtensionProperties: array of TVkExtensionProperties;
begin
  _VulkanEnabled := LoadVulkanLibrary and LoadVulkanGlobalCommands;
  if _VulkanEnabled then
  begin
    ResetExtensions;
{$if defined(Windows)}
    EnableExtension(VK_KHR_WIN32_SURFACE_EXTENSION_NAME);
{$elseif defined(Android)}
    EnableExtension(VK_KHR_ANDROID_SURFACE_EXTENSION_NAME);
{$elseif defined(Linux)}
    EnableExtension(VK_KHR_XCB_SURFACE_EXTENSION_NAME);
{$endif}
    _ExtensionsEnabled := TLabListString.Create(4, 4);
    _LayersEnabled := TLabListString.Create(4, 4);
    LayerCount := 0;
    vk.EnumerateInstanceLayerProperties(@LayerCount, nil));
    if LayerCount > 0 then
    begin
      SetLength(_Layers, LayerCount);
      SetLength(LayerProperties, LayerCount);
      vk.EnumerateInstanceLayerProperties(@LayerCount, @LayerProperties[0]));
      for i := 0 to LayerCount - 1 do
      begin
        _Layers[i].Name := LayerProperties[i].layerName;
        _Layers[i].SpecVersion := LayerProperties[i].specVersion;
        _Layers[i].ImplementationVersion := LayerProperties[i].implementationVersion;
        _Layers[i].Description := LayerProperties[i].description;
        ExtensionCount := 0;
        vk.EnumerateInstanceExtensionProperties(PVkChar(_Layers[i].Name), @ExtensionCount, nil);
        SetLength(_Layers[i].Extensions, ExtensionCount);
        if Length(ExtensionProperties) < ExtensionCount then
        begin
          SetLength(ExtensionProperties, ExtensionCount);
        end;
        vk.EnumerateInstanceExtensionProperties(PVkChar(_Layers[i].Name), @ExtensionCount, @ExtensionProperties[0]);
        for j := 0 to ExtensionCount - 1 do
        begin
          _Layers[i].Extensions[j].Name := ExtensionProperties[j].extensionName;
          _Layers[i].Extensions[j].SpecVersion := ExtensionProperties[j].specVersion;
        end;
      end;
    end;
  end;
end;

class destructor TLabRenderer.DestroyClass;
begin
  if Assigned(_Renderer) then _Renderer := nil;
end;

class function TLabRenderer.FindLayer(const Name: AnsiString): PLabLayer;
  var i: Integer;
begin
  for i := 0 to High(_Layers) do
  if _Layers[i].Name = Name then
  begin
    Result := @_Layers[i];
  end;
  Result := nil;
end;

class procedure TLabRenderer.ResetExtensions;
begin
  _ExtensionsEnabled.Clear;
  _ExtensionsEnabled.Add(VK_KHR_SURFACE_EXTENSION_NAME);
end;

class procedure TLabRenderer.EnableExtension(const Name: AnsiString);
begin
  if _ExtensionsEnabled.Find(Name) = -1 then
  begin
    _ExtensionsEnabled.Add(Name);
  end;
end;

class procedure TLabRenderer.DisableExtension(const Name: AnsiString);
begin
  _ExtensionsEnabled.Remove(Name);
end;

class procedure TLabRenderer.ResetLayers;
begin
  _LayersEnabled.Clear;
end;

class procedure TLabRenderer.EnableLayer(const Name: AnsiString);
begin
  if _LayersEnabled.Find(Name) = -1 then
  begin
    _LayersEnabled.Add(Name);
  end;
end;

class procedure TLabRenderer.DisableLayer(const Name: AnsiString);
begin
  _LayersEnabled.Remove(Name);
end;

constructor TLabRenderer.Create(const AppName: AnsiString; const EngineName: AnsiString);
  var AppInfo: TVkApplicationInfo;
  var InstanceCreateInfo: TVkInstanceCreateInfo;
  var InstanceCommands: TVulkanCommands;
  var PhysicalDeviceCount: TVkUInt32;
  var PhysicalDevices: array of TVkPhysicslDevice;
  var PhysicalDeviceFeatures: TVkPhysicalDeviceFeatures;
  var DepthFormat: TVkFormat;
  var i: Integer;
  var Extensions: array of PVkChar;
  var Layers: array of PVkChar;
begin
  if not _VulkanEnabled then Halt;
  _PhysicalDevices := TLabPhysicalDeviceList.Create(0, 4);
  LabZeroMem(@AppInfo, SizeOf(TVkApplicationInfo));
  AppInfo.sType := VK_STRUCTURE_TYPE_APPLICATION_INFO;
  AppInfo.pApplicationName := AppName;
  AppInfo.pEngineName := EngineName;
  AppInfo.apiVersion := VK_API_VERSION_1_0;
  SetLength(Extensions, _ExtensionsEnabled.Count);
  for i := 0 to _ExtensionsEnabled.Count - 1 do
  begin
    Extensions[i] := PVkChar(_ExtensionsEnabled[i]);
  end;
  SetLength(Layers, _LayersEnabled.Count);
  for i := 0 to _LayersEnabled.Count - 1 do
  begin
    Layers[i] := PVkChar(_LayersEnabled[i]);
  end;
  LabZeroMem(@InstanceCreateInfo, SizeOf(TVkInstanceCreateInfo));
  InstanceCreateInfo.sType := VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  InstanceCreateInfo.enabledExtensionCount := Length(Extensions);
  InstanceCreateInfo.ppEnabledExtensionNames := PPVkChar(@Extensions[0]);
  InstanceCreateInfo.enabledLayerCount := Length(Layers);
  InstanceCreateInfo.ppEnabledLayerNames := PPVkChar(@Layers[0]);
  InstanceCreateInfo.pApplicationInfo := @AppInfo;
  LabAssetVkError(vk.CreateInstance(@InstanceCreateInfo, nil, @_Instance));
  LabZeroMem(@InstanceCommands, SizeOf(TVulkanCommands));
  if LoadVulkanInstanceCommands(vk.Commands.GetInstanceProcAddr, _Instance, InstanceCommands) then
  begin
    _Vulkan := TVulkan.Create(InstanceCommands);
  end
  else
  begin
    _Vulkan := nil;
  end;

  PhysicalDeviceCount := 0;
  LabAssetVkError(_Vulkan.EnumeratePhysicalDevices(_Instance, @PhysicalDeviceCount, nil));
  _PhysicalDevices.Allocate(PhysicalDeviceCount);
  SetLength(PhysicalDevices, PhysicalDeviceCount);
  LabAssetVkError(_Vulkan.EnumeratePhysicalDevices(_Instance, @PhysicalDeviceCount, @PhysicalDevices));
  for i := 0 to PhysicalDeviceCount - 1 do
  begin
    _PhysicalDevices[i] := TLabPhysicalDevice.Create(PhysicalDevices[i]);
  end;
end;

destructor TLabRenderer.Destroy;
begin
  _LabLayerList := nil;
  if _Renderer = Self then _Renderer := nil;
  if Assigned(_Instance) then
  begin
    vk.DestroyInstance(instance, nullptr);
  end;
  _Device := nil;
  _PhysicalDevice := nil;
  if Assigned(_Vulkan) then
  begin
    _Vulkan.Free;
    _Vulkan := nil;
  end;
  inherited Destroy;
end;

end.
