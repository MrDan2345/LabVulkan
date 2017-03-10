unit LabFrameBuffer;

interface

uses
  Vulkan,
  LabDevice,
  LabSwapChain,
  LabTypes,
  LabUtils;

type
  TLabFrameBuffer = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkFramebuffer;
  public
    property VkHandle: TVkFramebuffer read _Handle;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ASwapChain: TLabSwapChainShared;
      const ARenderPass: TVkRenderPass;
      const Attachments: array of TVkImageView
    );
    destructor Destroy; override;
  end;
  TLabFrameBufferShared = specialize TLabSharedRef<TLabFrameBuffer>;

implementation

constructor TLabFrameBuffer.Create(
  const ADevice: TLabDeviceShared;
  const ASwapChain: TLabSwapChainShared;
  const ARenderPass: TVkRenderPass;
  const Attachments: array of TVkImageView
);
  var frame_buffer_info: TVkFramebufferCreateInfo;
begin
  LabLog('TLabFrameBuffer.Create');
  _Device := ADevice;
  LabZeroMem(@frame_buffer_info, SizeOf(frame_buffer_info));
  frame_buffer_info.sType := VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
  frame_buffer_info.renderPass := ARenderPass;
  frame_buffer_info.attachmentCount := Length(Attachments);
  frame_buffer_info.pAttachments := @Attachments[0];
  frame_buffer_info.width := ASwapChain.Ptr.Width;
  frame_buffer_info.height := ASwapChain.Ptr.Height;
  frame_buffer_info.layers := 1;
  LabAssertVkError(Vulkan.CreateFramebuffer(_Device.Ptr.VkHandle, @frame_buffer_info, nil, @_Handle));
end;

destructor TLabFrameBuffer.Destroy;
begin
  Vulkan.DestroyFramebuffer(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabFrameBuffer.Destroy');
end;

end.
