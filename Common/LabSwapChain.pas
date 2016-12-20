unit LabSwapChain;

{$include LabPlatform.inc}
interface

uses
  Vulkan,
  LabUtils,
  LabWindow;

type
  TLabSwapChain = class (TInterfacedObject)
  private
    var _Surface: TVkSurfaceKHR;
  public
    constructor Create(const Window: TLabWindow);
    destructor Destroy; override;
  end;

implementation

uses
  LabRenderer;

{$if defined(VK_USE_PLATFORM_WIN32_KHR)}
constructor TLabSwapChain.Create(const Window: TLabWindow);
  var surface_create_info: TVkWin32SurfaceCreateInfoKHR;
begin
  LabLog('TLabSwapChain.Create', 2);
  inherited Create;
  LabZeroMem(@surface_create_info, SizeOf(TVkWin32SurfaceCreateInfoKHR));
  surface_create_info.sType := VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
  surface_create_info.hinstance_ := Window.Instance;
  surface_create_info.hwnd_ := Window.Handle;
  LabAssetVkError(vk.CreateWin32SurfaceKHR(TLabRenderer.VulkanInstance, @surface_create_info, nil, @_Surface));
end;
{$else}
constructor TLabSwapChain.Create(const Window: TLabWindow);
begin
  Halt;
end;
{$endif}

destructor TLabSwapChain.Destroy;
begin
  if _Surface <> VK_NULL_HANDLE then
  begin
    LabAssetVkError(vk.DestroySurfaceKHR(TLabRenderer.VulkanInstance, _Surface, nil));
  end;
  inherited Destroy;
  LabLog('TLabSwapChain.Destroy', -2);
end;

end.
