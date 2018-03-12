unit LabFrameBuffer;

interface

uses
  Vulkan,
  LabDevice,
  LabSwapChain,
  LabRenderPass,
  LabImage,
  LabTypes,
  LabUtils;

type
  TLabFrameBuffer = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkFramebuffer;
    var _Width: TVkInt32;
    var _Height: TVkInt32;
  public
    property VkHandle: TVkFramebuffer read _Handle;
    property Width: TVkInt32 read _Width;
    property Height: TVkInt32 read _Height;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ARenderPass: TLabRenderPass;
      const AWidth: TVkInt32;
      const AHeight: TVkInt32;
      const Attachments: array of TVkImageView
    );
    destructor Destroy; override;
  end;
  TLabFrameBufferShared = specialize TLabSharedRef<TLabFrameBuffer>;

  TLabFrameBuffers = array of TLabFrameBufferShared;
  TLabFrameBufferAttachments = array of TVkImage;

function LabFrameBuffers(
  const Device: TLabDeviceShared;
  const RenderPass: TLabRenderPass;
  const SwapChain: TLabSwapChain;
  const DepthBuffer: TLabDepthBuffer
): TLabFrameBuffers;

implementation

constructor TLabFrameBuffer.Create(const ADevice: TLabDeviceShared;
  const ARenderPass: TLabRenderPass; const AWidth: TVkInt32;
  const AHeight: TVkInt32; const Attachments: array of TVkImageView);
  var frame_buffer_info: TVkFramebufferCreateInfo;
begin
  LabLog('TLabFrameBuffer.Create');
  _Device := ADevice;
  _Width := AWidth;
  _Height := AHeight;
  LabZeroMem(@frame_buffer_info, SizeOf(frame_buffer_info));
  frame_buffer_info.sType := VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
  frame_buffer_info.renderPass := ARenderPass.VkHandle;
  frame_buffer_info.attachmentCount := Length(Attachments);
  frame_buffer_info.pAttachments := @Attachments[0];
  frame_buffer_info.width := _Width;
  frame_buffer_info.height := _Height;
  frame_buffer_info.layers := 1;
  LabAssertVkError(vk.CreateFramebuffer(_Device.Ptr.VkHandle, @frame_buffer_info, nil, @_Handle));
end;

destructor TLabFrameBuffer.Destroy;
begin
  vk.DestroyFramebuffer(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabFrameBuffer.Destroy');
end;

function LabFrameBuffers(
  const Device: TLabDeviceShared;
  const RenderPass: TLabRenderPass;
  const SwapChain: TLabSwapChain;
  const DepthBuffer: TLabDepthBuffer
): TLabFrameBuffers;
  var Attachments: array[0..1] of TVkImage;
  var i: TVkInt32;
begin
  SetLength(Result, SwapChain.ImageCount);
  Attachments[1] := DepthBuffer.View.VkHandle;
  for i := 0 to SwapChain.ImageCount - 1 do
  begin
    Attachments[0] := SwapChain.Images[i]^.View.VkHandle;
    Result[i] := TLabFrameBuffer.Create(Device, RenderPass, SwapChain.Width, SwapChain.Height, Attachments);
  end;
end;

end.
