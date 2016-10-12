unit LabSwapChain;

interface

uses
  {$include LabPlatform.inc},
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

{$if defined(Windows)}
constructor TLabSwapChain.Create(const Window: TLabWindow);
  var surface_create_info: TVkWin32SurfaceCreateInfoKHR;
begin
  inherited Create;
  LabZeroMem(@surface_create_info, SizeOf(TVkWin32SurfaceCreateInfoKHR));
  surface_create_info.sType := VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
  surface_create_info.hinstance_ := Window.Instance;
  surface_create_info.hwnd_ := Window.Handle;
  LabAssetVkError(vk.CreateWin32SurfaceKHR(TLabRenderer.VkHandle, @surface_create_info, nil, @_Surface));
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
    vk.DestroySurfaceKHR(TLabRenderer.VkHandle, _Surface, nil);
  end;
  inherited Destroy;
end;

end.
