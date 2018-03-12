unit LabRenderPass;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice;

type
  TLabSubpassDescriptionData = record
    Flags: TVkSubpassDescriptionFlags;
    PipelineBindPoint: TVkPipelineBindPoint;
    InputAttachments: array of TVkAttachmentReference;
    ColorAttachments: array of TVkAttachmentReference;
    ResolveAttachments: array of TVkAttachmentReference;
    DepthStencilAttachment: TVkAttachmentReference;
    PreserveAttachments: array of TVkUInt32;
  end;

  TLabRenderPass = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkRenderPass;
  public
    property VkHandle: TVkRenderPass read _Handle;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const AAttachments: array of TVkAttachmentDescription;
      const ASubpasses: array of TLabSubpassDescriptionData
    );
    destructor Destroy; override;
  end;
  TLabRenderPassShared = specialize TLabSharedRef<TLabRenderPass>;

function LabAttachmentDescription(
  const Format: TVkFormat;
  const FinalLayout: TVkImageLayout;
  const Samples: TVkSampleCountFlagBits = VK_SAMPLE_COUNT_1_BIT;
  const LoadOp: TVkAttachmentLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
  const StoreOp: TVkAttachmentStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
  const StencilLoadOp: TVkAttachmentLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
  const StencilStoreOp: TVkAttachmentStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
  const InitialLayout: TVkImageLayout = VK_IMAGE_LAYOUT_UNDEFINED;
  const Flags: TVkAttachmentDescriptionFlags = 0
): TVkAttachmentDescription;

function LabSubpassDescriptionData(
  const InputAttachments: array of TVkAttachmentReference;
  const ColorAttachments: array of TVkAttachmentReference;
  const ResolveAttachments: array of TVkAttachmentReference;
  const DepthStencilAttachment: TVkAttachmentReference;
  const PreserveAttachments: array of TVkUInt32;
  const PipelineBindPoint: TVkPipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
  const Flags: TVkSubpassDescriptionFlags = 0
): TLabSubpassDescriptionData;

function LabSubpassDescription(const Data: TLabSubpassDescriptionData): TVkSubpassDescription;
function LabAttachmentReference(const Attachment:TVkUInt32; const Layout:TVkImageLayout): TVkAttachmentReference;

implementation

constructor TLabRenderPass.Create(
  const ADevice: TLabDeviceShared;
  const AAttachments: array of TVkAttachmentDescription;
  const ASubpasses: array of TLabSubpassDescriptionData
);
  var subpass_descriptions: array of TVkSubpassDescription;
  var rp_info: TVkRenderPassCreateInfo;
  var i: TVkInt32;
begin
  LabLog('TLabRenderPass.Create');
  inherited Create;
  _Device := ADevice;
  SetLength(subpass_descriptions, Length(ASubpasses));
  for i := 0 to High(ASubpasses) do subpass_descriptions[i] := LabSubpassDescription(ASubpasses[i]);
  FillChar(rp_info, SizeOf(rp_info), 0);
  rp_info.sType := VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
  rp_info.pNext := nil;
  rp_info.attachmentCount := Length(AAttachments);
  rp_info.pAttachments := @AAttachments[0];
  rp_info.subpassCount := Length(subpass_descriptions);
  rp_info.pSubpasses := @subpass_descriptions[0];
  rp_info.dependencyCount := 0;
  rp_info.pDependencies := nil;
  LabAssertVkError(vk.CreateRenderPass(_Device.Ptr.VkHandle, @rp_info, nil, @_Handle));
end;

destructor TLabRenderPass.Destroy;
begin
  vk.DestroyRenderPass(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabRenderPass.Destroy');
end;

function LabAttachmentDescription(
  const Format: TVkFormat;
  const FinalLayout: TVkImageLayout;
  const Samples: TVkSampleCountFlagBits;
  const LoadOp: TVkAttachmentLoadOp;
  const StoreOp: TVkAttachmentStoreOp;
  const StencilLoadOp: TVkAttachmentLoadOp;
  const StencilStoreOp: TVkAttachmentStoreOp;
  const InitialLayout: TVkImageLayout;
  const Flags: TVkAttachmentDescriptionFlags
): TVkAttachmentDescription;
begin
  Result.flags := Flags;
  Result.format := Format;
  Result.samples := Samples;
  Result.loadOp := LoadOp;
  Result.storeOp := StoreOp;
  Result.stencilLoadOp := StencilLoadOp;
  Result.stencilStoreOp := StencilStoreOp;
  Result.initialLayout := InitialLayout;
  Result.finalLayout := FinalLayout;
end;

function LabSubpassDescriptionData(
  const InputAttachments: array of TVkAttachmentReference;
  const ColorAttachments: array of TVkAttachmentReference;
  const ResolveAttachments: array of TVkAttachmentReference;
  const DepthStencilAttachment: TVkAttachmentReference;
  const PreserveAttachments: array of TVkUInt32;
  const PipelineBindPoint: TVkPipelineBindPoint;
  const Flags: TVkSubpassDescriptionFlags
): TLabSubpassDescriptionData;
begin
  Result.Flags := Flags;
  Result.PipelineBindPoint := PipelineBindPoint;
  SetLength(Result.InputAttachments, Length(InputAttachments));
  Move(InputAttachments[0], Result.InputAttachments[0], SizeOf(TVkAttachmentReference) * Length(InputAttachments));
  SetLength(Result.ColorAttachments, Length(ColorAttachments));
  Move(ColorAttachments[0], Result.ColorAttachments[0], SizeOf(TVkAttachmentReference) * Length(ColorAttachments));
  SetLength(Result.ResolveAttachments, Length(ResolveAttachments));
  Move(ResolveAttachments[0], Result.ResolveAttachments[0], SizeOf(TVkAttachmentReference) * Length(ResolveAttachments));
  SetLength(Result.PreserveAttachments, Length(PreserveAttachments));
  Move(PreserveAttachments[0], Result.PreserveAttachments[0], SizeOf(TVkUInt32) * Length(PreserveAttachments));
  Result.DepthStencilAttachment := DepthStencilAttachment;
end;

function LabSubpassDescription(const Data: TLabSubpassDescriptionData): TVkSubpassDescription;
begin
  Result.flags := Data.Flags;
  Result.pipelineBindPoint := Data.PipelineBindPoint;
  Result.inputAttachmentCount := Length(Data.InputAttachments);
  if Length(Data.InputAttachments) > 0 then
  begin
    Result.pInputAttachments := @Data.InputAttachments[0];
  end
  else
  begin
    Result.pInputAttachments := nil;
  end;
  Result.colorAttachmentCount := Length(Data.ColorAttachments);
  if Length(Data.ColorAttachments) > 0 then
  begin
    Result.pColorAttachments := @Data.ColorAttachments[0];
  end
  else
  begin
    Result.pColorAttachments := nil;
  end;
  if Length(Data.ResolveAttachments) > 0 then
  begin
    Result.pResolveAttachments := @Data.ResolveAttachments[0];
  end
  else
  begin
    Result.pResolveAttachments := nil;
  end;
  Result.pDepthStencilAttachment := @Data.DepthStencilAttachment;
  Result.preserveAttachmentCount := Length(Data.PreserveAttachments);
  if Length(Data.PreserveAttachments) > 0 then
  begin
    Result.pResolveAttachments := @Data.PreserveAttachments[0];
  end
  else
  begin
    Result.pResolveAttachments := nil;
  end;
end;

function LabAttachmentReference(const Attachment: TVkUInt32; const Layout: TVkImageLayout): TVkAttachmentReference;
begin
  Result.attachment := Attachment;
  Result.layout := Layout;
end;

end.
