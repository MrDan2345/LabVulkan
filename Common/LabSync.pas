unit LabSync;

interface

uses
  Vulkan,
  LabDevice,
  LabTypes,
  LabUtils;

type
  TLabFence = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkFence;
    function GetIsSignaled: Boolean; inline;
  public
    property IsSignaled: Boolean read GetIsSignaled;
    constructor Create(const ADevice: TLabDeviceShared; const AFlags: TVkFenceCreateFlags = TVkFenceCreateFlags(0));
    destructor Destroy; override;
    function GetStatus: TVkResult; inline;
    function Reset: TVkResult;
    function WaitFor(const TimeOut: TVkUInt64 = TVKUInt64(TVKInt64(-1))): TVkResult;
    property Device: TLabDeviceShared read _Device;
    property VkHandle: TVkFence read _Handle;
  end;
  TLabFenceShared = specialize TLabSharedRef<TLabFence>;

  TLabSemaphore = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkSemaphore;
    function GetVkHandlePtr: PVkSemaphore; inline;
  public
    constructor Create(const ADevice: TLabDeviceShared; const AFlags: TVkSemaphoreCreateFlags = TVkSemaphoreCreateFlags(0));
    destructor Destroy; override;
    property Device: TLabDeviceShared read _Device;
    property VkHandle: TVkSemaphore read _Handle;
    property VkHandlePtr: PVkSemaphore read GetVkHandlePtr;
  end;
  TLabSemaphoreShared = specialize TLabSharedRef<TLabSemaphore>;

implementation

//TLabFence BEGIN
function TLabFence.GetIsSignaled: Boolean;
begin
  Result := GetStatus = VK_SUCCESS;
end;

constructor TLabFence.Create(const ADevice: TLabDeviceShared; const AFlags: TVkFenceCreateFlags);
  var FenceCreateInfo: TVkFenceCreateInfo;
begin
  inherited Create;
  _Device := ADevice;
  _Handle := VK_NULL_HANDLE;
  {$Push}{$Hints off}
  FillChar(FenceCreateInfo, SizeOf(TVkFenceCreateInfo), #0);
  {$Pop}
  FenceCreateInfo.sType := VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
  FenceCreateInfo.pNext := nil;
  FenceCreateInfo.flags := AFlags;
  LabAssertVkError(Vulkan.CreateFence(_Device.Ptr.VkHandle, @FenceCreateInfo, nil, @_Handle));
end;

destructor TLabFence.Destroy;
begin
  if LabVkValidHandle(_Handle) then
  begin
    Vulkan.DestroyFence(_Device.Ptr.VkHandle, _Handle, nil);
    _Handle := VK_NULL_HANDLE;
  end;
  inherited Destroy;
end;

function TLabFence.GetStatus: TVkResult;
begin
  Result := Vulkan.GetFenceStatus(_Device.Ptr.VkHandle, _Handle);
end;

function TLabFence.Reset: TVkResult;
begin
  Result := Vulkan.ResetFences(_Device.Ptr.VkHandle, 1, @_Handle);
  LabAssertVkError(Result);
end;

function TLabFence.WaitFor(const TimeOut: TVkUInt64): TVkResult;
begin
  Result := Vulkan.WaitForFences(_Device.Ptr.VkHandle, 1, @_Handle, VK_TRUE, TimeOut);
  LabAssertVkError(Result);
end;
//TLabFence END

//TLabSemaphore BEGIN
function TLabSemaphore.GetVkHandlePtr: PVkSemaphore;
begin
  Result := @_Handle;
end;

constructor TLabSemaphore.Create(const ADevice: TLabDeviceShared; const AFlags: TVkSemaphoreCreateFlags);
  var SemaphoreCreateInfo: TVkSemaphoreCreateInfo;
begin
  inherited Create;
  _Device := ADevice;
  _Handle := VK_NULL_HANDLE;
  {$Push}{$Hints off}
  FillChar(SemaphoreCreateInfo, SizeOf(TVkSemaphoreCreateInfo), #0);
  {$Pop}
  SemaphoreCreateInfo.sType := VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
  SemaphoreCreateInfo.pNext := nil;
  SemaphoreCreateInfo.flags := AFlags;
  LabAssertVkError(Vulkan.CreateSemaphore(_Device.Ptr.VkHandle, @SemaphoreCreateInfo, nil, @_Handle));
end;

destructor TLabSemaphore.Destroy;
begin
  if LabVkValidHandle(_Handle) then
  begin
    Vulkan.DestroySemaphore(_Device.Ptr.VkHandle, _Handle, nil);
    _Handle := VK_NULL_HANDLE;
  end;
  inherited Destroy;
end;
//TLabSemaphore END

end.
