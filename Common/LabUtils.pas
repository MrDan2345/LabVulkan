unit LabUtils;

interface

uses
  Vulkan;

procedure LabZeroMem(const Ptr: Pointer; const Size: SizeInt);
function LabCheckGlobalExtensionPresent(const ExtensionName: AnsiString): VkBool32;
function LabCheckDeviceExtensionPresent(const PhysicalDevice: TVkPhysicalDevice; const ExtensionName: String): VkBool32;
procedure LabAssetVkError(const State: TVkResult);
function LogVkError(const State: TVkResult): TVkResult;
function LabVkErrorString(const State: TVkResult): String;
function LabVkValidHandle(const Handle: TVkDispatchableHandle): Boolean; inline;

implementation

procedure LabZeroMem(const Ptr: Pointer; const Size: SizeInt);
begin
  if Ptr = nil then Exit;
  {$Warnings off}
  FillChar(Ptr^, Size, 0);
  {$Warnings on}
end;

function LabCheckGlobalExtensionPresent(const ExtensionName: AnsiString): VkBool32;
  var ext_count: TVkUInt32;
  var extensions: array of TVkExtensionProperties;
  var ext: TVkExtensionProperties;
begin
  ext_count := 0;
  vk.EnumerateInstanceExtensionProperties(nil, @ext_count, nil);
  SetLength(extensions, ext_count);
  vk.EnumerateInstanceExtensionProperties(nil, @ext_count, @extensions[0]);
  for ext in extensions do
  if ExtensionName = ext.extensionName then
  begin
    Result := True;
    Exit;
  end;
  Result := False;
end;

function LabCheckDeviceExtensionPresent(const PhysicalDevice: TVkPhysicalDevice; const ExtensionName: String): VkBool32;
  var ext_count: TVkUInt32;
  var extensions: array of TVkExtensionProperties;
  var ext: TVkExtensionProperties;
begin
  ext_count := 0;
  vk.EnumerateDeviceExtensionProperties(PhysicalDevice, nil, @ext_count, nil);
  SetLength(extensions, ext_count);
  vk.EnumerateDeviceExtensionProperties(PhysicalDevice, nil, @ext_count, @extensions[0]);
  for ext in extensions do
  if ExtensionName = ext.extensionName then
  begin
    Result := True;
    Exit;
  end;
  Result := False;
end;

procedure LabAssetVkError(const State: TVkResult);
begin
  Assert(LogVkError(State) = VK_SUCCESS, LabVkErrorString(State));
end;

function LogVkError(const State: TVkResult): TVkResult;
begin
  if State <> VK_SUCCESS then
  begin
    WriteLn('Vulkan Error: ' + LavVkErrorString(State));
  end;
  Result := State;
end;

function LabVkValidHandle(const Handle: TVkDispatchableHandle): Boolean;
begin
  Result := Handle <> 0;
end;

function LabVkErrorString(const State: TVkResult): String;
begin
  case State of
    VK_NOT_READY: Result := 'NOT_READY';
    VK_TIMEOUT: Result := 'TIMEOUT';
    VK_EVENT_SET: Result := 'EVENT_SET';
    VK_EVENT_RESET: Result := 'EVENT_RESET';
    VK_INCOMPLETE: Result := 'INCOMPLETE';
    VK_ERROR_OUT_OF_HOST_MEMORY: Result := 'ERROR_OUT_OF_HOST_MEMORY';
    VK_ERROR_OUT_OF_DEVICE_MEMORY: Result := 'ERROR_OUT_OF_DEVICE_MEMORY';
    VK_ERROR_INITIALIZATION_FAILED: Result := 'ERROR_INITIALIZATION_FAILED';
    VK_ERROR_DEVICE_LOST: Result := 'ERROR_DEVICE_LOST';
    VK_ERROR_MEMORY_MAP_FAILED: Result := 'ERROR_MEMORY_MAP_FAILED';
    VK_ERROR_LAYER_NOT_PRESENT: Result := 'ERROR_LAYER_NOT_PRESENT';
    VK_ERROR_EXTENSION_NOT_PRESENT: Result := 'ERROR_EXTENSION_NOT_PRESENT';
    VK_ERROR_FEATURE_NOT_PRESENT: Result := 'ERROR_FEATURE_NOT_PRESENT';
    VK_ERROR_INCOMPATIBLE_DRIVER: Result := 'ERROR_INCOMPATIBLE_DRIVER';
    VK_ERROR_TOO_MANY_OBJECTS: Result := 'ERROR_TOO_MANY_OBJECTS';
    VK_ERROR_FORMAT_NOT_SUPPORTED: Result := 'ERROR_FORMAT_NOT_SUPPORTED';
    VK_ERROR_SURFACE_LOST_KHR: Result := 'ERROR_SURFACE_LOST_KHR';
    VK_ERROR_NATIVE_WINDOW_IN_USE_KHR: Result := 'ERROR_NATIVE_WINDOW_IN_USE_KHR';
    VK_SUBOPTIMAL_KHR: Result := 'SUBOPTIMAL_KHR';
    VK_ERROR_OUT_OF_DATE_KHR: Result := 'ERROR_OUT_OF_DATE_KHR';
    VK_ERROR_INCOMPATIBLE_DISPLAY_KHR: Result := 'ERROR_INCOMPATIBLE_DISPLAY_KHR';
    VK_ERROR_VALIDATION_FAILED_EXT: Result := 'ERROR_VALIDATION_FAILED_EXT';
    VK_ERROR_INVALID_SHADER_NV: Result := 'ERROR_INVALID_SHADER_NV';
    else Result := 'UNKNOWN_ERROR';
  end;
end;

end.
