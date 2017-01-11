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
    var _Device: TLabDeviceRef;
    var _Handle: TVkFence;
  public
    constructor Create(const ADevice: TLabDeviceRef; const AFlags: TVkFenceCreateFlags = TVkFenceCreateFlags(0));
    destructor Destroy; override;
    function GetStatus:TVkResult;
    function Reset: TVkResult;
    function WaitFor(const TimeOut: TVkUInt64 = TVKUInt64(TVKInt64(-1))): TVkResult; overload;
    property Device: TLabDeviceRef read _Device;
    property VkHandle: TVkFence read _Handle;
  end;

  TLabSemaphore = class (TLabClass)
  private
    var _Device: TLabDeviceRef;
    var _Handle: TVkSemaphore;
  public
    constructor Create(const ADevice: TLabDeviceRef; const AFlags: TVkSemaphoreCreateFlags = TVkSemaphoreCreateFlags(0));
    destructor Destroy; override;
    property Device: TLabDeviceRef read _Device;
    property VkHandle: TVkSemaphore read _Handle;
  end;

implementation

//TLabFence BEGIN
constructor TLabFence.Create(const ADevice: TLabDeviceRef; const AFlags: TVkFenceCreateFlags);
  var FenceCreateInfo: TVkFenceCreateInfo;
begin
  inherited Create;
  _Device := ADevice;
  _Handle := VK_NULL_HANDLE;
  FillChar(FenceCreateInfo, SizeOf(TVkFenceCreateInfo), #0);
  FenceCreateInfo.sType := VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
  FenceCreateInfo.pNext := nil;
  FenceCreateInfo.flags := AFlags;
  LabAssetVkError(Vulkan.CreateFence(_Device.Ptr.VkHandle, @FenceCreateInfo, nil, @_Handle));
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
  LabAssetVkError(Result);
end;

function TLabFence.WaitFor(const TimeOut: TVkUInt64): TVkResult;
begin
  Result := Vulkan.WaitForFences(_Device.Ptr.VkHandle, 1, @_Handle, VK_TRUE, TimeOut);
  LabAssetVkError(Result);
end;
//TLabFence END

//TLabSemaphore BEGIN
constructor TLabSemaphore.Create(const ADevice: TLabDeviceRef; const AFlags: TVkSemaphoreCreateFlags);
  var SemaphoreCreateInfo: TVkSemaphoreCreateInfo;
begin
  inherited Create;
  _Device := ADevice;
  _Handle := VK_NULL_HANDLE;
  FillChar(SemaphoreCreateInfo, SizeOf(TVkSemaphoreCreateInfo), #0);
  SemaphoreCreateInfo.sType := VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
  SemaphoreCreateInfo.pNext := nil;
  SemaphoreCreateInfo.flags := AFlags;
  LabAssetVkError(Vulkan.CreateSemaphore(_Device.Ptr.VkHandle, @SemaphoreCreateInfo, nil, @_Handle));
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
