unit LabSurface;

interface

{$include LabPlatform.inc}

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabWindow;

type
  TLabSurface = class (TLabClass)
  private
    var _Window: TLabWindow;
    var _Handle: TVkSurfaceKHR;
    function GetWidth: Integer; inline;
    function GetHeight: Integer; inline;
  public
    class function GetSurfacePlatformExtension: AnsiString;
    property VkHandle: TVkSurfaceKHR read _Handle;
    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
    constructor Create(const AWindow: TLabWindow);
    destructor Destroy; override;
  end;
  TLabSurfaceShared = specialize TLabSharedRef<TLabSurface>;

implementation

function TLabSurface.GetWidth: Integer;
begin
  Result := _Window.Width;
end;

function TLabSurface.GetHeight: Integer;
begin
  Result := _Window.Height;
end;

class function TLabSurface.GetSurfacePlatformExtension: AnsiString;
begin
{$if defined(Windows)}
  Result := VK_KHR_WIN32_SURFACE_EXTENSION_NAME;
{$elseif defined(Android)}
  Result := VK_KHR_ANDROID_SURFACE_EXTENSION_NAME;
{$elseif defined(Linux)}
  Result := VK_KHR_XCB_SURFACE_EXTENSION_NAME;
{$else}
  LabLog('Error: Surface platform extension not specified');
{$endif}
end;

constructor TLabSurface.Create(const AWindow: TLabWindow);
  var r: TVkResult;
{$if defined(Platform_Windows)}
  var create_info: TVkWin32SurfaceCreateInfoKHR;
{$endif}
  var supports_present: array of TVkBool32;
  var surf_formats: array of TVkSurfaceFormatKHR;
  var i, format_count: TVkUInt32;
begin
  _Window := AWindow;
// Construct the surface description:
{$if defined(Platform_Windows)}
{$Push}{$Hints off}
  FillChar(create_info, SizeOf(create_info), 0);
{$Pop}
  create_info.sType := VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
  create_info.pNext := nil;
  create_info.hinstance_ := _Window.WndClass.hInstance;
  create_info.hwnd_ := _Window.Handle;
  r := Vulkan.CreateWin32SurfaceKHR(VulkanInstance, @create_info, nil, @_Handle);
  LabAssertVkError(r);
{$elseif defined(__ANDROID__)}
  GET_INSTANCE_PROC_ADDR(info.inst, CreateAndroidSurfaceKHR);
  VkAndroidSurfaceCreateInfoKHR createInfo;
  createInfo.sType = VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR;
  createInfo.pNext = nullptr;
  createInfo.flags = 0;
  createInfo.window = AndroidGetApplicationWindow();
  res = info.fpCreateAndroidSurfaceKHR(info.inst, &createInfo, nullptr, &info.surface);
{$elseif defined(VK_USE_PLATFORM_IOS_MVK)}
  VkIOSSurfaceCreateInfoMVK createInfo = {};
  createInfo.sType = VK_STRUCTURE_TYPE_IOS_SURFACE_CREATE_INFO_MVK;
  createInfo.pNext = NULL;
  createInfo.flags = 0;
  createInfo.pView = info.window;
  res = Vulkan.CreateIOSSurfaceMVK(info.inst, &createInfo, NULL, &info.surface);
{$elseif defined(VK_USE_PLATFORM_MACOS_MVK)}
  VkMacOSSurfaceCreateInfoMVK createInfo = {};
  createInfo.sType = VK_STRUCTURE_TYPE_MACOS_SURFACE_CREATE_INFO_MVK;
  createInfo.pNext = NULL;
  createInfo.flags = 0;
  createInfo.pView = info.window;
  res = Vulkan.CreateMacOSSurfaceMVK(info.inst, &createInfo, NULL, &info.surface);
{$elseif defined(VK_USE_PLATFORM_WAYLAND_KHR)}
  VkWaylandSurfaceCreateInfoKHR createInfo = {};
  createInfo.sType = VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR;
  createInfo.pNext = NULL;
  createInfo.display = info.display;
  createInfo.surface = info.window;
  res = Vulkan.CreateWaylandSurfaceKHR(info.inst, &createInfo, NULL, &info.surface);
{$else}
  VkXcbSurfaceCreateInfoKHR createInfo = {};
  createInfo.sType = VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR;
  createInfo.pNext = NULL;
  createInfo.connection = info.connection;
  createInfo.window = info.window;
  res = Vulkan.CreateXcbSurfaceKHR(info.inst, &createInfo, NULL, &info.surface);
{$endif}  // __ANDROID__  && _WIN32
end;

destructor TLabSurface.Destroy;
begin
  if LabVkValidHandle(_Handle) then
  begin
    Vulkan.DestroySurfaceKHR(VulkanInstance, _Handle, nil);
  end;
  inherited Destroy;
end;

end.
