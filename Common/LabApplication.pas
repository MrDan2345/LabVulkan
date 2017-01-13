unit LabApplication;

interface

uses
  SysUtils,
  LabWindow,
  LabSwapChain,
  LabPhysicalDevice,
  LabDevice,
  LabCommandPool,
  LabCommandBuffer,
  LabThread,
  LabRenderer,
  LabUtils,
  LabSync,
  LabDepthBuffer,
  LabMath,
  Vulkan;

type
  TLabApplication = class (TInterfacedObject)
  private
    var _Renderer: TLabRenderer;
    var _Window: TLabWindow;
    var _Device: TLabDeviceRef;
    var _SwapChain: TLabSwapChainRef;
    var _DepthBuffer: TLabDepthBufferRef;
    var _UpdateThread: TLabThread;
    var _Active: Boolean;
    procedure OnWindowClose(Wnd: TLabWindow);
    procedure Update;
    procedure Stop;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Run;
  end;
  TLabApplicationRef = specialize TLabRefCounter<TLabApplication>;

implementation

procedure TLabApplication.OnWindowClose(Wnd: TLabWindow);
begin
  if Wnd = _Window then Stop;
end;

procedure TLabApplication.Update;
begin
  while _Active do
  begin
    //Logical update thread
  end;
end;

procedure TLabApplication.Stop;
begin
  _Active := False;
end;

constructor TLabApplication.Create;
begin
  LabProfileStart('App');
  LabLog('CPU Count = ' + IntToStr(System.CPUCount));
  LabLog('TLabApplication.Create', 2);
  inherited Create;
  _Active := False;
  _Renderer := TLabRenderer.Create();
  _Window := TLabWindow.Create;
  _Window.OnClose := @OnWindowClose;
  _Device := TLabDevice.Create(
    _Renderer.PhysicalDevices[0],
    [
      LabQueueFamilyRequest(_Renderer.PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT))),
      LabQueueFamilyRequest(_Renderer.PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_COMPUTE_BIT)))
    ],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  _SwapChain := TLabSwapChain.Create(_Window, _Device);
  _DepthBuffer := TLabDepthBuffer.Create(_Device, _SwapChain.Ptr.Width, _SwapChain.Ptr.Height);
  _UpdateThread := TLabThread.Create;
  _UpdateThread.Proc := @Update;
end;

destructor TLabApplication.Destroy;
begin
  _UpdateThread.Free;
  _DepthBuffer := nil;
  _SwapChain := nil;
  _Device := nil;
  _Window.Free;
  _Renderer.Free;
  inherited Destroy;
  LabLog('TLabApplication.Destroy', -2);
  LabProfileStop;
end;

procedure TLabApplication.Run;
begin
  _Active := True;
  _UpdateThread.Start;
  while _Active do
  begin
    //Gather, process window messages and sync other threads
  end;
  _UpdateThread.WaitFor();
end;

end.
