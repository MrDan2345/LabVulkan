unit LabDevice;

interface

uses
  LabTypes,
  LabUtils,
  LabPhysicalDevice,
  Vulkan,
  SysUtils;

type
  {$Push}
  {$PackRecords 2}
  TLabQueueFamilyRequest = record
    FamilyIndex: Byte;
    QueueCount: Byte;
    Priority: Single;
  end;
  {$Pop}

  TLabDevice = class (TLabClass)
  private
    var _PhysicalDevice: TLabPhysicalDeviceShared;
    var _Handle: TVkDevice;
    var _EnableDebugMarkers: Boolean;
  public
    property PhysicalDevice: TLabPhysicalDeviceShared read _PhysicalDevice;
    constructor Create(
      const APhysicalDevice: TLabPhysicalDeviceShared;
      const ARequestedQueues: array of TLabQueueFamilyRequest;
      const ADeviceExtensions: array of AnsiString
    );
    destructor Destroy; override;
    property VkHandle: TVkDevice read _Handle;
    function MemoryTypeFromProperties(const TypeBits: TVkUInt32; const RequirementsMask: TVkFlags; var TypeIndex: TVkUInt32): Boolean;
    function GetQueue(const QueueFamilyIndex, QueueIndex: TVkUInt32): TVkQueue; inline;
    procedure WaitIdle; inline;
  end;
  TLabDeviceShared = specialize TLabSharedRef<TLabDevice>;

function LabQueueFamilyRequest(const FamilyIndex: Byte; const QueueCount: Byte = 1; const Priority: Single = 0): TLabQueueFamilyRequest; inline;

implementation

//TLabDevice BEGIN
constructor TLabDevice.Create(
  const APhysicalDevice: TLabPhysicalDeviceShared;
  const ARequestedQueues: array of TLabQueueFamilyRequest;
  const ADeviceExtensions: array of AnsiString
);
  var queue_create_infos: array of TVkDeviceQueueCreateInfo;
  var device_create_info: TVkDeviceCreateInfo;
  var device_extensions: array of AnsiString;
  var add_swapchain_extension, add_quieue_request: Boolean;
  var i, j, request_queue_count: Integer;
  var mp: TVkMemoryPropertyFlagBits;
  var str: String;
begin
  LabLog('TLabDevice.Create');
  LabLogOffset(2);
  inherited Create;
  _PhysicalDevice := APhysicalDevice;
  LabLog('Queue family count = ' + IntToStr(_PhysicalDevice.Ptr.QueueFamilyCount));
  for i := 0 to _PhysicalDevice.Ptr.QueueFamilyCount - 1 do
  begin
    LabLog('Queue family[' + IntToStr(i) + ']:', 2);
    with _PhysicalDevice.Ptr.QueueFamilyProperties[i]^ do
    begin
      if (queueFlags and TVkFlags(VK_QUEUE_GRAPHICS_BIT)) > 0 then LabLog('Graphics support');
      if (queueFlags and TVkFlags(VK_QUEUE_COMPUTE_BIT)) > 0 then LabLog('Compute support');
      if (queueFlags and TVkFlags(VK_QUEUE_TRANSFER_BIT)) > 0 then LabLog('Transfer support');
      if (queueFlags and TVkFlags(VK_QUEUE_SPARSE_BINDING_BIT)) > 0 then LabLog('Sparse binding support');
      LabLog('Queue count = ' + IntToStr(queueCount));
    end;
    LabLogOffset(-2);
  end;
  SetLength(queue_create_infos, Length(ARequestedQueues));
  request_queue_count := 0;
  for i := 0 to High(ARequestedQueues) do
  begin
    add_quieue_request := True;
    for j := i - 1 downto 0 do
    if ARequestedQueues[j].FamilyIndex = ARequestedQueues[i].FamilyIndex then
    begin
      add_quieue_request := False;
      Break;
    end;
    if not add_quieue_request then Continue;
    LabZeroMem(@queue_create_infos[request_queue_count], SizeOf(TVkDeviceQueueCreateInfo));
    queue_create_infos[request_queue_count].sType := VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queue_create_infos[request_queue_count].queueFamilyIndex := ARequestedQueues[i].FamilyIndex;
    queue_create_infos[request_queue_count].queueCount := ARequestedQueues[i].QueueCount;
    queue_create_infos[request_queue_count].pQueuePriorities := @ARequestedQueues[i].Priority;
    Inc(request_queue_count);
  end;
  add_swapchain_extension := True;
  SetLength(device_extensions, Length(ADeviceExtensions));
  for i := 0 to High(ADeviceExtensions) do
  begin
    device_extensions[i] := ADeviceExtensions[i];
    if add_swapchain_extension
    and (ADeviceExtensions[i] = VK_KHR_SWAPCHAIN_EXTENSION_NAME) then
    begin
      add_swapchain_extension := False;
    end;
  end;
  if add_swapchain_extension then
  begin
    i := Length(device_extensions);
    SetLength(device_extensions, i + 1);
    device_extensions[i] := VK_KHR_SWAPCHAIN_EXTENSION_NAME;
  end;
  LabZeroMem(@device_create_info, SizeOf(TVkDeviceCreateInfo));
  device_create_info.sType := VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
  device_create_info.queueCreateInfoCount := request_queue_count;
  device_create_info.pQueueCreateInfos := @queue_create_infos[0];
  device_create_info.pEnabledFeatures := _PhysicalDevice.Ptr.Features;
  if LabCheckDeviceExtensionPresent(_PhysicalDevice.Ptr.VkHandle, VK_EXT_DEBUG_MARKER_EXTENSION_NAME) then
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
  LabAssertVkError(Vulkan.CreateDevice(_PhysicalDevice.Ptr.VkHandle, @device_create_info, nil, @_Handle));
  if Length(device_extensions) > 0 then
  begin
    LabLog('Device extension count = ' + IntToStr(Length(device_extensions)));
    for i := 0 to High(device_extensions) do
    begin
      LabLog('Extension[' + IntToStr(i) + '] ' + device_extensions[i]);
    end;
  end;
  LabLog('Memory heap count = ' + IntToStr(_PhysicalDevice.Ptr.MemoryPropertices^.memoryHeapCount));
  for i := 0 to _PhysicalDevice.Ptr.MemoryPropertices^.memoryHeapCount - 1 do
  begin
    LabLogOffset(2);
    LabLog('Heap[' + i.ToString + ']: ', 2);
    LabLog('Size = ' + (_PhysicalDevice.Ptr.MemoryPropertices^.memoryHeaps[i].size div (1024 * 1024)).ToString + ' MB');
    if _PhysicalDevice.Ptr.MemoryPropertices^.memoryHeaps[i].flags and TVkFlags(VK_MEMORY_HEAP_DEVICE_LOCAL_BIT) > 0 then
    begin
      LabLog('VK_MEMORY_HEAP_DEVICE_LOCAL_BIT');
    end;
    if _PhysicalDevice.Ptr.MemoryPropertices^.memoryHeaps[i].flags and TVkFlags(VK_MEMORY_HEAP_MULTI_INSTANCE_BIT) > 0 then
    begin
      LabLog('VK_MEMORY_HEAP_MULTI_INSTANCE_BIT');
    end;
    LabLogOffset(-4);
  end;
  LabLog('Memory type count = ' + IntToStr(_PhysicalDevice.Ptr.MemoryPropertices^.memoryTypeCount));
  for i := 0 to _PhysicalDevice.Ptr.MemoryPropertices^.memoryTypeCount - 1 do
  begin
    LabLogOffset(2);
    LabLog('Type[' + i.ToString + ']:', 2);
    LabLog('Heap index = ' + _PhysicalDevice.Ptr.MemoryPropertices^.memoryTypes[i].heapIndex.ToString);
    mp := TVkMemoryPropertyFlagBits(1);
    while mp <= High(TVkMemoryPropertyFlagBits) do
    begin
      if _PhysicalDevice.Ptr.MemoryPropertices^.memoryTypes[i].propertyFlags and TVkFlags(mp) > 0 then
      begin
        WriteStr(str, mp);
        LabLog(str);
      end;
      mp := TVkMemoryPropertyFlagBits(Ord(mp) shl 1);
    end;
    LabLogOffset(-4);
  end;
  LabLogOffset(-2);
end;

destructor TLabDevice.Destroy;
begin
  if LabVkValidHandle(_Handle) then
  begin
    Vulkan.DeviceWaitIdle(_Handle);
    Vulkan.DestroyDevice(_Handle, nil);
  end;
  inherited Destroy;
  LabLog('TLabDevice.Destroy');
end;

function TLabDevice.MemoryTypeFromProperties(
  const TypeBits: TVkUInt32;
  const RequirementsMask: TVkFlags;
  var TypeIndex: TVkUInt32
): Boolean;
  var i: TVkInt32;
  var tb: TVkUInt32;
begin
  tb := TypeBits;
  for i := 0 to _PhysicalDevice.Ptr.MemoryPropertices^.memoryTypeCount - 1 do
  begin
    if (tb and 1) = 1 then
    begin
      if (_PhysicalDevice.Ptr.MemoryPropertices^.memoryTypes[i].propertyFlags and RequirementsMask) = RequirementsMask then
      begin
        TypeIndex := i;
        Exit(True);
      end;
    end;
    tb := tb shr 1;
  end;
  Result := False;
end;

function TLabDevice.GetQueue(const QueueFamilyIndex, QueueIndex: TVkUInt32): TVkQueue;
begin
  Vulkan.GetDeviceQueue(_Handle, QueueFamilyIndex, QueueIndex, @Result);
end;

procedure TLabDevice.WaitIdle;
begin
  Vulkan.DeviceWaitIdle(_Handle);
end;

//TLabDevice END

function LabQueueFamilyRequest(const FamilyIndex: Byte; const QueueCount: Byte; const Priority: Single = 0): TLabQueueFamilyRequest;
begin
  {$Push}
  {$Warnings off}
  Result.FamilyIndex := FamilyIndex;
  Result.QueueCount := QueueCount;
  Result.Priority := Priority;
  {$Pop}
end;

end.
