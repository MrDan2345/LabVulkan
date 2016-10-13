unit LabDevice;

interface

uses
  {$include LabPlatform.inc},
  LabUtils,
  LabCommandPool,
  LabPhysicalDevice,
  Vulkan;

type
  TLabDevice = class (TInterfacedObject)
  private
    var _CommandPool: TLabCommandPool;
    var _PhysicalDevice: TLabPhysicalDevice;
    var _LogicalDevice: TVkDevice;
    var _QueueFamilyIndices: record
      Graphics: TVkUInt32;
      Compute: TVkUInt32;
      Transfer: TVkUInt32;
    end;
    var _EnableDebugMarkers: Boolean;
  public
    constructor Create(
      const APhysicalDevice: TLabPhysicalDevice;
      const AFeatures: TVkPhysicalDeviceFeatures;
      const AUseSwapChain: Boolean = true;
      const ARequestedQueueTypes: TVkQueueFlags = (TVkFlags(VK_QUEUE_GRAPHICS_BIT) or TVkFlags(VK_QUEUE_COMPUTE_BIT))
    );
    destructor Destroy; override;
    property VkHandle: TVkDevice read _LogicalDevice;
    function GetGraphicsQueue: TVkQueue; inline;
  end;

implementation

constructor TLabDevice.Create(
  const APhysicalDevice: TLabPhysicalDevice;
  const AFeatures: TVkPhysicalDeviceFeatures;
  const AUseSwapChain: Boolean;
  const ARequestedQueueTypes: TVkQueueFlags
);
  var queue_family_count: TVkUInt32;
  var queue_create_infos: array of TVkDeviceQueueCreateInfo;
  var device_create_info: TVkDeviceCreateInfo;
  var device_extensions: array of AnsiString;
  var i: Integer;
  const default_queue_priority: TVkFloat = 0;
begin
  _PhysicalDevice := APhysicalDevice;
  // Graphics queue
  if (ARequestedQueueTypes and TVkFlags(VK_QUEUE_GRAPHICS_BIT)) > 0 then
  begin
    _QueueFamilyIndices.Graphics := _PhysicalDevice.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT));
    i := Length(queue_create_infos);
    SetLength(queue_create_infos, i + 1);
    LabZeroMem(@queue_create_infos[i], SizeOf(TVkDeviceQueueCreateInfo));
    queue_create_infos[i].sType := VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queue_create_infos[i].queueFamilyIndex := _QueueFamilyIndices.Graphics;
    queue_create_infos[i].queueCount := 1;
    queue_create_infos[i].pQueuePriorities := @default_queue_priority;
  end
  else
  begin
    _QueueFamilyIndices.Graphics := VK_NULL_HANDLE;
  end;
  // Dedicated compute queue
  if (ARequestedQueueTypes and TVkFlags(VK_QUEUE_COMPUTE_BIT)) > 0 then
  begin
    _QueueFamilyIndices.Compute := _PhysicalDevice.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_COMPUTE_BIT));
    if _QueueFamilyIndices.Compute <> _QueueFamilyIndices.Graphics then
    begin
      i := Length(queue_create_infos);
      SetLength(queue_create_infos, i + 1);
      LabZeroMem(@queue_create_infos[i], SizeOf(TVkDeviceQueueCreateInfo));
      queue_create_infos[i].sType := VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
      queue_create_infos[i].queueFamilyIndex := _QueueFamilyIndices.Compute;
      queue_create_infos[i].queueCount := 1;
      queue_create_infos[i].pQueuePriorities := @default_queue_priority;
    end;
  end
  else
  begin
    _QueueFamilyIndices.Compute := _QueueFamilyIndices.Graphics;
  end;
  // Dedicated transfer queue
  if (ARequestedQueueTypes and TVkFlags(VK_QUEUE_TRANSFER_BIT)) > 0 then
  begin
    _QueueFamilyIndices.Transfer := _PhysicalDevice.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_TRANSFER_BIT));
    if (_QueueFamilyIndices.Transfer <> _QueueFamilyIndices.Graphics)
    and (_QueueFamilyIndices.Transfer <> _QueueFamilyIndices.Compute) then
    begin
      i := Length(queue_create_infos);
      SetLength(queue_create_infos, i + 1);
      LabZeroMem(@queue_create_infos[i], SizeOf(TVkDeviceQueueCreateInfo));
      queue_create_infos[i].sType := VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
      queue_create_infos[i].queueFamilyIndex := _QueueFamilyIndices.Transfer;
      queue_create_infos[i].queueCount := 1;
      queue_create_infos[i].pQueuePriorities := @default_queue_priority;
    end;
  end
  else
  begin
    _QueueFamilyIndices.Transfer := _QueueFamilyIndices.Graphics;
  end;
  if AUseSwapChain then
  begin
    i := Length(device_extensions);
    SetLength(device_extensions, i + 1);
    device_extensions[i] := VK_KHR_SWAPCHAIN_EXTENSION_NAME;
  end;
  LabZeroMem(@device_create_info, SizeOf(TVkDeviceCreateInfo));
  device_create_info.sType := VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
  device_create_info.queueCreateInfoCount := Length(queue_create_infos);
  device_create_info.pQueueCreateInfos := @queue_create_infos[0];
  device_create_info.pEnabledFeatures := @AFeatures;
  if LabCheckDeviceExtensionPresent(_PhysicalDevice.VkHandle, VK_EXT_DEBUG_MARKER_EXTENSION_NAME) then
  begin
    i := Length(device_extensions);
    SetLength(device_extensions, i + 1);
    device_extensions[i] := VK_EXT_DEBUG_MARKER_EXTENSION_NAME;
    _EnableDebugMarkers := True;
  end
  else
  begin
    _EnableDebugMarkers := False;
  end;
  if Length(device_extensions) > 0 then
  begin
    device_create_info.enabledExtensionCount := TVkUInt32(Length(device_extensions));
    device_create_info.ppEnabledExtensionNames := PPVkChar(@device_extensions[0]);
  end;
  LabAssetVkError(vk.CreateDevice(_PhysicalDevice.VkHandle, @device_create_info, nil, @_LogicalDevice));
  _CommandPool := TLabCommandPool.Create(_LogicalDevice, _QueueFamilyIndices.Graphics);
end;

destructor TLabDevice.Destroy;
begin
  if Assigned(_CommandPool) then _CommandPool := nil;
  if LabVkValidHandle(_LogicalDevice) then
  begin
    vk.DestroyDevice(_LogicalDevice, nil);
  end;
  inherited Destroy;
end;

function TLabDevice.GetGraphicsQueue: TVkQueue;
begin
  vk.GetDeviceQueue(_LogicalDevice, _QueueFamilyIndices.Graphics, 0, @Result);
end;

end.
