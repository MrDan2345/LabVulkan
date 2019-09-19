unit LabVulkan;

interface

uses
  SysUtils,
  Windows,
  Vulkan,
  LabTypes,
  LabUtils,
  LabPhysicalDevice,
  LabSurface;

type
  TLabExtension = record
    Name: AnsiString;
    SpecVersion: TVkUInt32;
  end;
  TLabExtensionArr = array of TLabExtension;

  TLabLayer = record
    Name: AnsiString;
    SpecVersion: TVkUInt32;
    ImplementationVersion: TVkUInt32;
    Description: AnsiString;
    Extensions: array of TLabExtension;
  end;
  PLabLayer = ^TLabLayer;

  TLabVulkan = class (TLabClass)
  private
    class var _IsEnabled: Boolean;
    class var _IsActive: Boolean;
    class var _OnInitialize: TLabProcObj;
    class var _OnFinalize: TLabProcObj;
    class var _OnLoop: TLabProcObj;
    class var _Layers: array of TLabLayer;
    class var _Extensions: TLabExtensionArr;
    class var _ExtensionsEnabled: TLabListStringShared;
    class var _LayersEnabled: TLabListStringShared;
    class var _ReportFormats: Boolean;
    var _PhysicalDevices: TLabPhysicalDeviceList;
    var _Vulkan: TVulkan;
  public
    class property ReportFormats: Boolean read _ReportFormats write _ReportFormats;
    class property IsEnabled: Boolean read _IsEnabled;
    class property IsActive: Boolean read _IsActive write _IsActive;
    class property OnInitialize: TLabProcObj read _OnInitialize write _OnInitialize;
    class property OnFinalize: TLabProcObj read _OnFinalize write _OnFinalize;
    class property OnLoop: TLabProcObj read _OnLoop write _OnLoop;
    class property Extensions: TLabExtensionArr read _Extensions;
    class function GetLayer(const Index: Integer): PLabLayer; inline;
    class function GetLayerCount: Integer; inline;
    class function FindLayer(const Name: AnsiString): PLabLayer;
    class procedure ResetExtensions;
    class procedure EnableExtension(const Name: AnsiString);
    class procedure EnableExtensionIfAvailable(const Name: AnsiString);
    class procedure DisableExtension(const Name: AnsiString);
    class procedure ResetLayers;
    class procedure EnableLayer(const Name: AnsiString);
    class procedure EnableLayerIfAvailable(const Name: AnsiString);
    class procedure DisableLayer(const Name: AnsiString);
    class constructor CreateClass;
    class destructor DestroyClass;
    class procedure Run;
    class function QueueSubmit(
      const Queue: TVkQueue;
      const CommandBuffers: array of TVkCommandBuffer;
      const WaitSemaphores: array of TVkSemaphore;
      const SignalSemaphores: array of TVkSemaphore;
      const Fence: TVkFence;
      const WaitDstStageMask: TVkPipelineStageFlags = 0
    ): TVkResult;
    class function QueuePresent(
      const Queue: TVkQueue;
      const SwapChains: array of TVkSwapchainKHR;
      const ImageIndices: array of TVkUInt32;
      const WaitSemaphores: array of TVkSemaphore
    ): TVkResult;
    class procedure QueueWaitIdle(const Queue: TVkQueue);
    property PhysicalDevices: TLabPhysicalDeviceList read _PhysicalDevices;
    constructor Create;
    destructor Destroy; override;
  end;
  TLabVulkanShared = specialize TLabSharedRef<TLabVulkan>;

implementation

class function TLabVulkan.GetLayer(const Index: Integer): PLabLayer;
begin
  Result := @_Layers[Index];
end;

class function TLabVulkan.GetLayerCount: Integer;
begin
  Result := Length(_Layers);
end;

class function TLabVulkan.FindLayer(const Name: AnsiString): PLabLayer;
  var i: Integer;
begin
  for i := 0 to High(_Layers) do
  if _Layers[i].Name = Name then
  begin
    Exit(@_Layers[i]);
  end;
  Result := nil;
end;

class procedure TLabVulkan.ResetExtensions;
begin
  _ExtensionsEnabled.Ptr.Clear;
end;

class procedure TLabVulkan.EnableExtension(const Name: AnsiString);
begin
  if _ExtensionsEnabled.Ptr.Find(Name) = -1 then
  begin
    _ExtensionsEnabled.Ptr.Add(Name);
  end;
end;

class procedure TLabVulkan.EnableExtensionIfAvailable(const Name: AnsiString);
  var i, j: TVkInt32;
begin
  for i := 0 to High(_Layers) do
  for j := 0 to High(_Layers[i].Extensions) do
  if _Layers[i].Extensions[j].Name = Name then
  begin
    EnableExtension(Name);
    Exit;
  end;
end;

class procedure TLabVulkan.DisableExtension(const Name: AnsiString);
begin
  _ExtensionsEnabled.Ptr.Remove(Name);
end;

class procedure TLabVulkan.ResetLayers;
begin
  _LayersEnabled.Ptr.Clear;
end;

class procedure TLabVulkan.EnableLayer(const Name: AnsiString);
begin
  if _LayersEnabled.Ptr.Find(Name) = -1 then
  begin
    _LayersEnabled.Ptr.Add(Name);
  end;
end;

class procedure TLabVulkan.EnableLayerIfAvailable(const Name: AnsiString);
begin
  if Assigned(FindLayer(Name)) then EnableLayer(Name);
end;

class procedure TLabVulkan.DisableLayer(const Name: AnsiString);
begin
  _LayersEnabled.Ptr.Remove(Name);
end;

class constructor TLabVulkan.CreateClass;
  var i, j: Integer;
  var layer_count, extension_count: TVkUInt32;
  var layer_properties: array of TVkLayerProperties;
  var extension_properties: array of TVkExtensionProperties;
begin
  LabLog('TLabVulkan.CreateClass');
  _ReportFormats := False;
  _IsActive := False;
  _IsEnabled := LoadVulkanLibrary and LoadVulkanGlobalCommands;
  if _IsEnabled then
  begin
    _ExtensionsEnabled := TLabListString.Create(4, 4);
    _LayersEnabled := TLabListString.Create(4, 4);
    ResetExtensions;
    EnableExtension(VK_KHR_SURFACE_EXTENSION_NAME);
    EnableExtension(TLabSurface.GetSurfacePlatformExtension);
    extension_count := 0;
    Vulkan.EnumerateInstanceExtensionProperties(nil, @extension_count, nil);
    SetLength(extension_properties, extension_count);
    SetLength(_Extensions, extension_count);
    Vulkan.EnumerateInstanceExtensionProperties(nil, @extension_count, @extension_properties[0]);
    LabLog('Suppoerted Extensions[' + extension_count.ToString + ']:');
    LabLogOffset(2);
    for i := 0 to extension_count - 1 do
    begin
      _Extensions[i].Name := extension_properties[i].extensionName;
      _Extensions[i].SpecVersion := extension_properties[i].specVersion;
      LabLog(_Extensions[i].Name + ' ver' + _Extensions[i].SpecVersion.ToString);
    end;
    LabLogOffset(-2);
    layer_count := 0;
    LabAssertVkError(Vulkan.EnumerateInstanceLayerProperties(@layer_count, nil));
    if layer_count > 0 then
    begin
      SetLength(_Layers, layer_count);
      SetLength(layer_properties, layer_count);
      LabAssertVkError(Vulkan.EnumerateInstanceLayerProperties(@layer_count, @layer_properties[0]));
      for i := 0 to layer_count - 1 do
      begin
        _Layers[i].Name := layer_properties[i].layerName;
        _Layers[i].SpecVersion := layer_properties[i].specVersion;
        _Layers[i].ImplementationVersion := layer_properties[i].implementationVersion;
        _Layers[i].Description := layer_properties[i].description;
        extension_count := 0;
        LabAssertVkError(Vulkan.EnumerateInstanceExtensionProperties(PVkChar(_Layers[i].Name), @extension_count, nil));
        SetLength(_Layers[i].Extensions, extension_count);
        if (extension_count > 0) then
        begin
          if Length(extension_properties) < extension_count then
          begin
            SetLength(extension_properties, extension_count);
          end;
          LabAssertVkError(Vulkan.EnumerateInstanceExtensionProperties(PVkChar(_Layers[i].Name), @extension_count, @extension_properties[0]));
          for j := 0 to extension_count - 1 do
          begin
            _Layers[i].Extensions[j].Name := extension_properties[j].extensionName;
            _Layers[i].Extensions[j].SpecVersion := extension_properties[j].specVersion;
          end;
        end;
      end;
    end;
  end;
end;

class destructor TLabVulkan.DestroyClass;
begin
  LabLog('TLabVulkan.DestroyClass');
end;

class procedure TLabVulkan.Run;
  var msg: TMsg;
begin
  _IsActive := True;
  if Assigned(_OnInitialize) then _OnInitialize();
  {$Push}{$Hints off}
  FillChar(msg, SizeOf(msg), 0);
  {$Pop}
  while _IsActive do
  begin
    if PeekMessage(msg, 0, 0, 0, PM_REMOVE) then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end
    else
    if Assigned(_OnLoop) then _OnLoop();
  end;
  if Assigned(_OnFinalize) then _OnFinalize();
  ExitCode := 0;
end;

class function TLabVulkan.QueueSubmit(
  const Queue: TVkQueue;
  const CommandBuffers: array of TVkCommandBuffer;
  const WaitSemaphores: array of TVkSemaphore;
  const SignalSemaphores: array of TVkSemaphore;
  const Fence: TVkFence;
  const WaitDstStageMask: TVkPipelineStageFlags
): TVkResult;
  var submit_info: TVkSubmitInfo;
begin
  {$Push}{$Hints off}
  FillChar(submit_info, SizeOf(submit_info), 0);
  {$Pop}
  submit_info.sType := VK_STRUCTURE_TYPE_SUBMIT_INFO;
  submit_info.pNext := nil;
  submit_info.waitSemaphoreCount := Length(WaitSemaphores);
  submit_info.pWaitSemaphores := @WaitSemaphores[0];
  submit_info.pWaitDstStageMask := @WaitDstStageMask;
  submit_info.commandBufferCount := Length(CommandBuffers);
  submit_info.pCommandBuffers := @CommandBuffers;
  submit_info.signalSemaphoreCount := Length(SignalSemaphores);
  submit_info.pSignalSemaphores := @SignalSemaphores[0];
  Result := Vulkan.QueueSubmit(Queue, 1, @submit_info, Fence);
end;

class function TLabVulkan.QueuePresent(
  const Queue: TVkQueue;
  const SwapChains: array of TVkSwapchainKHR;
  const ImageIndices: array of TVkUInt32;
  const WaitSemaphores: array of TVkSemaphore
): TVkResult;
  var present_info: TVkPresentInfoKHR;
begin
  present_info.sType := VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
  present_info.pNext := nil;
  present_info.swapchainCount := Length(SwapChains);
  present_info.pSwapchains := @SwapChains[0];
  present_info.pImageIndices := @ImageIndices[0];
  present_info.waitSemaphoreCount := Length(WaitSemaphores);
  present_info.pWaitSemaphores := @WaitSemaphores[0];
  present_info.pResults := nil;
  Result := Vulkan.QueuePresentKHR(Queue, @present_info);
end;

class procedure TLabVulkan.QueueWaitIdle(const Queue: TVkQueue);
begin
  Vulkan.QueueWaitIdle(Queue);
end;

constructor TLabVulkan.Create;
  function GetDeviceTypeName(const DeviceType: TVkPhysicalDeviceType): String;
  begin
    case DeviceType of
      VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU: Exit('Integrated GPU');
      VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU: Exit('Discrete GPU');
      VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU: Exit('Virtual GPU');
      VK_PHYSICAL_DEVICE_TYPE_CPU: Exit('CPU');
    end;
    Exit('OTHER');
  end;
  var app_info: TVkApplicationInfo;
  var inst_info: TVkInstanceCreateInfo;
  var inst_commands: TVulkanCommands;
  var ext_arr: array of PVkChar;
  var layers: array of PVkChar;
  var r: TVkResult;
  var i, j, physical_device_count: Integer;
  var physical_device_arr: array of TVkPhysicalDevice;
  var fmt: TVkFormat;
  var fmt_props: TVkFormatProperties;
  var ff: TVkFormatFeatureFlagBits;
  var fmt_str, str: String;
begin
  LabLog('TLabVulkan.Create');
  LabLogOffset(2);
  _PhysicalDevices := TLabPhysicalDeviceList.Create(0, 4);
  {$Push}{$Hints off}
  FillChar(app_info, SizeOf(app_info), 0);
  {$Pop}
  app_info.sType := VK_STRUCTURE_TYPE_APPLICATION_INFO;
  app_info.pNext := nil;
  app_info.pApplicationName := PVkChar('LabVulkan');
  app_info.applicationVersion := 1;
  app_info.pEngineName := PVkChar('LabVulkan');
  app_info.engineVersion := 1;
  app_info.apiVersion := VK_API_VERSION_1_0;
  SetLength(ext_arr, _ExtensionsEnabled.Ptr.Count);
  for i := 0 to _ExtensionsEnabled.Ptr.Count - 1 do
  begin
    ext_arr[i] := PVkChar(_ExtensionsEnabled.Ptr[i]);
  end;
  SetLength(layers, _LayersEnabled.Ptr.Count);
  for i := 0 to _LayersEnabled.Ptr.Count - 1 do
  begin
    layers[i] := PVkChar(_LayersEnabled.Ptr[i]);
  end;
  {$Push}{$Hints off}
  FillChar(inst_info, SizeOf(inst_info), 0);
  {$Pop}
  inst_info.sType := VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  inst_info.pNext := nil;
  inst_info.flags := 0;
  inst_info.pApplicationInfo := @app_info;
  inst_info.enabledLayerCount := Length(layers);
  if Length(layers) > 0 then
  begin
    inst_info.ppEnabledLayerNames := PPVkChar(@layers[0]);
  end
  else
  begin
    inst_info.ppEnabledLayerNames := nil;
  end;
  inst_info.enabledExtensionCount := Length(ext_arr);
  if Length(ext_arr) > 0 then
  begin
    inst_info.ppEnabledExtensionNames := PPVkChar(@ext_arr[0]);
  end
  else
  begin
    inst_info.ppEnabledExtensionNames := nil;
  end;
  r := Vulkan.CreateInstance(@inst_info, nil, @_VulkanInstance);
  LabAssertVkError(r);
  LoadVulkanInstanceCommands(Vulkan.Commands.GetInstanceProcAddr, _VulkanInstance, inst_commands);
  _Vulkan := TVulkan.Create(inst_commands);
  _VulkanPtr := @_Vulkan;
  physical_device_count := 0;
  r := Vulkan.EnumeratePhysicalDevices(_VulkanInstance, @physical_device_count, nil);
  LabAssertVkError(r);
  _PhysicalDevices.Allocate(physical_device_count);
  SetLength(physical_device_arr, physical_device_count);
  LabAssertVkError(Vulkan.EnumeratePhysicalDevices(_VulkanInstance, @physical_device_count, @physical_device_arr[0]));
  LabLog('Physical device count = ' + IntToStr(_PhysicalDevices.Count));
  for i := 0 to physical_device_count - 1 do
  begin
    _PhysicalDevices[i] := TLabPhysicalDevice.Create(physical_device_arr[i]);
    LabLog('Physical device[' + IntToStr(i) + ']:', 2);
    LabLog('API Version = ' + IntToStr(_PhysicalDevices[i].Ptr.Properties^.apiVersion));
    LabLog('Device ID = ' + IntToStr(_PhysicalDevices[i].Ptr.Properties^.deviceID));
    LabLog('Device Name = ' + _PhysicalDevices[i].Ptr.Properties^.deviceName);
    LabLog('Device Type = ' + GetDeviceTypeName(_PhysicalDevices[i].Ptr.Properties^.deviceType));
    LabLog('Driver Version = ' + IntToStr(_PhysicalDevices[i].Ptr.Properties^.driverVersion));
    LabLog('Queue family count = ' + IntToStr(_PhysicalDevices[i].Ptr.QueueFamilyCount));
    for j := 0 to _PhysicalDevices[i].Ptr.QueueFamilyCount - 1 do
    begin
      LabLog('Queue family[' + IntToStr(j) + ']:', 2);
      if _PhysicalDevices[i].Ptr.QueueFamilyProperties[j]^.queueFlags and TVkFlags(VK_QUEUE_GRAPHICS_BIT) > 0 then
      begin
        LabLog('GRAPHICS');
      end;
      if _PhysicalDevices[i].Ptr.QueueFamilyProperties[j]^.queueFlags and TVkFlags(VK_QUEUE_COMPUTE_BIT) > 0 then
      begin
        LabLog('COMPUTE');
      end;
      if _PhysicalDevices[i].Ptr.QueueFamilyProperties[j]^.queueFlags and TVkFlags(VK_QUEUE_TRANSFER_BIT) > 0 then
      begin
        LabLog('TRANSFER');
      end;
      if _PhysicalDevices[i].Ptr.QueueFamilyProperties[j]^.queueFlags and TVkFlags(VK_QUEUE_SPARSE_BINDING_BIT) > 0 then
      begin
        LabLog('SPARSE BINDING');
      end;
      if _PhysicalDevices[i].Ptr.QueueFamilyProperties[j]^.queueFlags and TVkFlags(VK_QUEUE_PROTECTED_BIT) > 0 then
      begin
        LabLog('PROTECTED');
      end;
      LabLogOffset(-2);
    end;
    if _ReportFormats then
    begin
      LabLog('Supported formats:', 2);
      for fmt in [Low(TVkFormat)..VK_FORMAT_ASTC_12x12_SRGB_BLOCK] do
      begin
        Vulkan.GetPhysicalDeviceFormatProperties(_PhysicalDevices[i].Ptr.VkHandle, fmt, @fmt_props);
        if (fmt_props.optimalTilingFeatures > 0)
        or (fmt_props.linearTilingFeatures > 0)
        or (fmt_props.optimalTilingFeatures > 0) then
        begin
          WriteStr(str, fmt);
          LabLog(str, 2);
          if fmt_props.optimalTilingFeatures > 0 then
          begin
            LabLog('optimal:', 2);
            for ff in LabFormatFeatures do
            if (TVkFlags(ff) and fmt_props.optimalTilingFeatures) > 0 then
            begin
              WriteStr(str, ff);
              LabLog(str);
            end;
            LabLogOffset(-2)
          end;
          if fmt_props.linearTilingFeatures > 0 then
          begin
            LabLog('linear:', 2);
            for ff in LabFormatFeatures do
            if (TVkFlags(ff) and fmt_props.linearTilingFeatures) > 0 then
            begin
              WriteStr(str, ff);
              LabLog(str);
            end;
            LabLogOffset(-2)
          end;
          if fmt_props.bufferFeatures > 0 then
          begin
            LabLog('buffer:', 2);
            for ff in LabFormatFeatures do
            if (TVkFlags(ff) and fmt_props.bufferFeatures) > 0 then
            begin
              WriteStr(str, ff);
              LabLog(str);
            end;
            LabLogOffset(-2)
          end;
          LabLogOffset(-2);
        end;
      end;
      LabLogOffset(-2);
    end;
    LabLogOffset(-2);
  end;
  if _ExtensionsEnabled.Ptr.Count > 0 then
  begin
    LabLog('Vulkan extension count = ' + IntToStr(_ExtensionsEnabled.Ptr.Count), 2);
    for i := 0 to _ExtensionsEnabled.Ptr.Count - 1 do
    begin
      LabLog('Extension[' + IntToStr(i) + '] = ' + _ExtensionsEnabled.Ptr[i]);
    end;
    LabLogOffset(-2);
  end;
  LabLog('Layer count = ' + IntToStr(Length(_Layers)));
  LabLogOffset(2);
  for i := 0 to High(_Layers) do
  begin
    LabLog('Layer[' + IntToStr(i) + '] = ' + _Layers[i].Name + ' (' + _Layers[i].Description + ')');
    LabLog('Layer[' + IntToStr(i) + '] extension count = ' + IntToStr(Length(_Layers[i].Extensions)));
    LabLogOffset(2);
    for j := 0 to High(_Layers[i].Extensions) do
    begin
      LabLog(_Layers[i].Extensions[j].Name);
    end;
    LabLogOffset(-2);
  end;
  LabLogOffset(-2);
  LabLogOffset(-2);
end;

destructor TLabVulkan.Destroy;
begin
  if Assigned(_Vulkan) then
  begin
    _Vulkan.Free;
    _VulkanPtr := @vk;
    _Vulkan := nil;
  end;
  _PhysicalDevices.Free;
  if LabVkValidHandle(_VulkanInstance) then
  begin
    Vulkan.DestroyInstance(_VulkanInstance, nil);
    _VulkanInstance := 0;
  end;
  inherited Destroy;
  LabLog('TLabVulkan.Destroy');
end;

end.
