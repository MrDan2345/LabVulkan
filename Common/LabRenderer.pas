unit LabRenderer;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabPhysicalDevice,
  LabDevice,
  LabSwapChain,
  SysUtils;

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

  TLabRenderer = class (TLabClass)
  private
    class var _VulkanEnabled: Boolean;
    class var _Layers: array of TLabLayer;
    class var _ExtensionsEnabled: TLabListStringShared;
    class var _LayersEnabled: TLabListStringShared;
    var _Vulkan: TVulkan;
    var _PhysicalDevices: TLabPhysicalDeviceList;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    class function GetLayer(const Index: Integer): PLabLayer; inline;
    class function GetLayerCount: Integer; inline;
    class function FindLayer(const Name: AnsiString): PLabLayer;
    class procedure ResetExtensions;
    class procedure EnableExtension(const Name: AnsiString);
    class procedure DisableExtension(const Name: AnsiString);
    class procedure ResetLayers;
    class procedure EnableLayer(const Name: AnsiString);
    class procedure DisableLayer(const Name: AnsiString);
    constructor Create(const AppName: AnsiString = 'Lab Vulkan'; const EngineName: AnsiString = 'Lab Vulkan');
    destructor Destroy; override;
    property PhysicalDevices: TLabPhysicalDeviceList read _PhysicalDevices;
  end;
  TLabRendererShared = specialize TLabSharedRef<TLabRenderer>;

const VK_DYNAMIC_STATE_RANGE_SIZE: TVkInt32 = (TVkInt32(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkInt32(VK_DYNAMIC_STATE_VIEWPORT) + 1);

implementation

//TLabRenderer BEGIN
class constructor TLabRenderer.CreateClass;
  var i, j: Integer;
  var LayerCount, ExtensionCount: TVkUInt32;
  var LayerProperties: array of TVkLayerProperties;
  var ExtensionProperties: array of TVkExtensionProperties;
begin
  LabLog('TLabRenderer.CreateClass');
  _VulkanEnabled := LoadVulkanLibrary and LoadVulkanGlobalCommands;
  if _VulkanEnabled then
  begin
    _ExtensionsEnabled := TLabListString.Create(4, 4);
    _LayersEnabled := TLabListString.Create(4, 4);
    ResetExtensions;
    EnableExtension(VK_KHR_SURFACE_EXTENSION_NAME);
    EnableExtension(TLabSwapChain.GetSurfacePlatformExtension);
    LayerCount := 0;
    LabAssertVkError(Vulkan.EnumerateInstanceLayerProperties(@LayerCount, nil));
    if LayerCount > 0 then
    begin
      SetLength(_Layers, LayerCount);
      SetLength(LayerProperties, LayerCount);
      LabAssertVkError(Vulkan.EnumerateInstanceLayerProperties(@LayerCount, @LayerProperties[0]));
      for i := 0 to LayerCount - 1 do
      begin
        _Layers[i].Name := LayerProperties[i].layerName;
        _Layers[i].SpecVersion := LayerProperties[i].specVersion;
        _Layers[i].ImplementationVersion := LayerProperties[i].implementationVersion;
        _Layers[i].Description := LayerProperties[i].description;
        ExtensionCount := 0;
        LabAssertVkError(Vulkan.EnumerateInstanceExtensionProperties(PVkChar(_Layers[i].Name), @ExtensionCount, nil));
        SetLength(_Layers[i].Extensions, ExtensionCount);
        if Length(ExtensionProperties) < ExtensionCount then
        begin
          SetLength(ExtensionProperties, ExtensionCount);
        end;
        LabAssertVkError(Vulkan.EnumerateInstanceExtensionProperties(PVkChar(_Layers[i].Name), @ExtensionCount, @ExtensionProperties[0]));
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
  LabLog('TLabRenderer.DestroyClass');
end;

class function TLabRenderer.GetLayer(const Index: Integer): PLabLayer;
begin
  Result := @_Layers[Index];
end;

class function TLabRenderer.GetLayerCount: Integer;
begin
  Result := Length(_Layers);
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
  _ExtensionsEnabled.Ptr.Clear;
end;

class procedure TLabRenderer.EnableExtension(const Name: AnsiString);
begin
  if _ExtensionsEnabled.Ptr.Find(Name) = -1 then
  begin
    _ExtensionsEnabled.Ptr.Add(Name);
  end;
end;

class procedure TLabRenderer.DisableExtension(const Name: AnsiString);
begin
  _ExtensionsEnabled.Ptr.Remove(Name);
end;

class procedure TLabRenderer.ResetLayers;
begin
  _LayersEnabled.Ptr.Clear;
end;

class procedure TLabRenderer.EnableLayer(const Name: AnsiString);
begin
  if _LayersEnabled.Ptr.Find(Name) = -1 then
  begin
    _LayersEnabled.Ptr.Add(Name);
  end;
end;

class procedure TLabRenderer.DisableLayer(const Name: AnsiString);
begin
  _LayersEnabled.Ptr.Remove(Name);
end;

constructor TLabRenderer.Create(const AppName: AnsiString; const EngineName: AnsiString);
  var AppInfo: TVkApplicationInfo;
  var InstanceCreateInfo: TVkInstanceCreateInfo;
  var InstanceCommands: TVulkanCommands;
  var PhysicalDeviceCount: TVkUInt32;
  var PhysicalDeviceArr: array of TVkPhysicalDevice;
  var i, j: Integer;
  var Extensions: array of PVkChar;
  var Layers: array of PVkChar;
begin
  LabLog('TLabRenderer.Create');
  LabProfileStart('TLabRenderer.Create');
  if not _VulkanEnabled then Halt;
  _PhysicalDevices := TLabPhysicalDeviceList.Create(0, 4);
  LabZeroMem(@AppInfo, SizeOf(TVkApplicationInfo));
  AppInfo.sType := VK_STRUCTURE_TYPE_APPLICATION_INFO;
  AppInfo.pApplicationName := PVkChar(AppName);
  AppInfo.pEngineName := PVkChar(EngineName);
  AppInfo.apiVersion := VK_API_VERSION_1_0;
  SetLength(Extensions, _ExtensionsEnabled.Ptr.Count);
  for i := 0 to _ExtensionsEnabled.Ptr.Count - 1 do
  begin
    Extensions[i] := PVkChar(_ExtensionsEnabled.Ptr[i]);
  end;
  SetLength(Layers, _LayersEnabled.Ptr.Count);
  for i := 0 to _LayersEnabled.Ptr.Count - 1 do
  begin
    Layers[i] := PVkChar(_LayersEnabled.Ptr[i]);
  end;
  LabZeroMem(@InstanceCreateInfo, SizeOf(TVkInstanceCreateInfo));
  InstanceCreateInfo.sType := VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  InstanceCreateInfo.enabledExtensionCount := Length(Extensions);
  InstanceCreateInfo.ppEnabledExtensionNames := PPVkChar(@Extensions[0]);
  InstanceCreateInfo.enabledLayerCount := Length(Layers);
  InstanceCreateInfo.ppEnabledLayerNames := PPVkChar(@Layers[0]);
  InstanceCreateInfo.pApplicationInfo := @AppInfo;
  LabAssertVkError(Vulkan.CreateInstance(@InstanceCreateInfo, nil, @_VulkanInstance));
  LabZeroMem(@InstanceCommands, SizeOf(TVulkanCommands));
  if LoadVulkanInstanceCommands(Vulkan.Commands.GetInstanceProcAddr, _VulkanInstance, InstanceCommands) then
  begin
    _Vulkan := TVulkan.Create(InstanceCommands);
    _VulkanPtr := @_Vulkan;
  end
  else
  begin
    _Vulkan := nil;
    Halt;
  end;
  LabProfileStop;
  LabProfileStart('EnumeratePhysicalDevices');
  PhysicalDeviceCount := 0;
  LabAssertVkError(Vulkan.EnumeratePhysicalDevices(VulkanInstance, @PhysicalDeviceCount, nil));
  _PhysicalDevices.Allocate(PhysicalDeviceCount);
  SetLength(PhysicalDeviceArr, PhysicalDeviceCount);
  LabAssertVkError(Vulkan.EnumeratePhysicalDevices(VulkanInstance, @PhysicalDeviceCount, @PhysicalDeviceArr[0]));
  for i := 0 to PhysicalDeviceCount - 1 do
  begin
    _PhysicalDevices[i] := TLabPhysicalDevice.Create(PhysicalDeviceArr[i]);
  end;
  if _ExtensionsEnabled.Ptr.Count > 0 then
  begin
    LabLog('Vulkan extension count = ' + IntToStr(_ExtensionsEnabled.Ptr.Count));
    for i := 0 to _ExtensionsEnabled.Ptr.Count - 1 do
    begin
      LabLog('Extension[' + IntToStr(i) + '] = ' + _ExtensionsEnabled.Ptr[i]);
    end;
  end;
  LabLog('Physical device count = ' + IntToStr(_PhysicalDevices.Count));
  LabLog('Layer count = ' + IntToStr(Length(_Layers)));
  for i := 0 to High(_Layers) do
  begin
    LabLog('Layer[' + IntToStr(i) + '] = ' + _Layers[i].Name + ' (' + _Layers[i].Description + ')');
    LabLog('Layer[' + IntToStr(i) + '] extension count = ' + IntToStr(Length(_Layers[i].Extensions)));
    for j := 0 to High(_Layers[i].Extensions) do
    begin
      LabLog(_Layers[i].Extensions[j].Name);
    end;
  end;
  LabProfileStop;
end;

destructor TLabRenderer.Destroy;
begin
  _PhysicalDevices.Clear;
  _PhysicalDevices.Free;
  if Assigned(_Vulkan) then
  begin
    if _VulkanPtr = @_Vulkan then
    begin
      _VulkanPtr := @vk;
    end;
    _Vulkan.Free;
    _Vulkan := nil;
  end;
  if LabVkValidHandle(_VulkanInstance) then
  begin
    Vulkan.DestroyInstance(_VulkanInstance, nil);
    _VulkanInstance := 0;
  end;
  inherited Destroy;
  LabLog('TLabRenderer.Destroy');
end;
//TLabRenderer END

end.
