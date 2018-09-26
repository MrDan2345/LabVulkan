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
    var _Hash: TVkUInt32;
  public
    property VkHandle: TVkRenderPass read _Handle;
    property Hash: TVkUInt32 read _Hash;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const AAttachments: array of TVkAttachmentDescription;
      const ASubpasses: array of TLabSubpassDescriptionData;
      const ADependencies: array of TVkSubpassDependency
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
function LabSubpassDependency(
  const SrcSubpass: TVkUInt32 = VK_SUBPASS_EXTERNAL;
  const DstSubpass: TVkUInt32 = VK_SUBPASS_EXTERNAL;
  const SrcStageMask: TVkPipelineStageFlags = TVkFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT);
  const DstStageMask: TVkPipelineStageFlags = TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT);
  const SrcAccessMask: TVkAccessFlags = 0;
  const DstAccessMask: TVkAccessFlags = 0;
  const DependencyFlags: TVkDependencyFlags = TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
): TVkSubpassDependency;

implementation

constructor TLabRenderPass.Create(
  const ADevice: TLabDeviceShared;
  const AAttachments: array of TVkAttachmentDescription;
  const ASubpasses: array of TLabSubpassDescriptionData;
  const ADependencies: array of TVkSubpassDependency
);
  var subpass_descriptions: array of TVkSubpassDescription;
  var rp_info: TVkRenderPassCreateInfo;
  var i, j: TVkInt32;
begin
  LabLog('TLabRenderPass.Create');
  inherited Create;
  _Device := ADevice;
  SetLength(subpass_descriptions, Length(ASubpasses));
  for i := 0 to High(ASubpasses) do
  begin
    subpass_descriptions[i] := LabSubpassDescription(ASubpasses[i]);
  end;
  FillChar(rp_info, SizeOf(rp_info), 0);
  rp_info.sType := VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
  rp_info.pNext := nil;
  rp_info.attachmentCount := Length(AAttachments);
  if Length(AAttachments) > 0 then
  begin
    rp_info.pAttachments := @AAttachments[0];
  end;
  rp_info.subpassCount := Length(subpass_descriptions);
  if Length(subpass_descriptions) > 0 then
  begin
    rp_info.pSubpasses := @subpass_descriptions[0];
  end;
  rp_info.dependencyCount := Length(ADependencies);
  if Length(ADependencies) > 0 then
  begin
    rp_info.pDependencies := @ADependencies[0];
  end;
  LabAssertVkError(Vulkan.CreateRenderPass(_Device.Ptr.VkHandle, @rp_info, nil, @_Handle));
  if Length(AAttachments) > 0 then
  begin
    _Hash := LabCRC32(0, @AAttachments[0], Length(AAttachments) * SizeOf(TVkAttachmentDescription));
  end
  else
  begin
    _Hash := 0;
  end;
  for i := 0 to High(ASubpasses) do
  begin
    _Hash := LabCRC32(_Hash, @ASubpasses[i].Flags, SizeOf(ASubpasses[i].Flags));
    _Hash := LabCRC32(_Hash, @ASubpasses[i].PipelineBindPoint, SizeOf(ASubpasses[i].PipelineBindPoint));
    _Hash := LabCRC32(_Hash, @ASubpasses[i].DepthStencilAttachment, SizeOf(ASubpasses[i].DepthStencilAttachment));
    if Length(ASubpasses[i].ColorAttachments) > 0 then
    begin
      _Hash := LabCRC32(
        _Hash, @ASubpasses[i].ColorAttachments[0],
        Length(ASubpasses[i].ColorAttachments) * SizeOf(TVkAttachmentReference)
      );
    end;
    if Length(ASubpasses[i].InputAttachments) > 0 then
    begin
      _Hash := LabCRC32(
        _Hash, @ASubpasses[i].InputAttachments[0],
        Length(ASubpasses[i].InputAttachments) * SizeOf(TVkAttachmentReference)
      );
    end;
    if Length(ASubpasses[i].PreserveAttachments) > 0 then
    begin
      _Hash := LabCRC32(
        _Hash, @ASubpasses[i].PreserveAttachments[0],
        Length(ASubpasses[i].PreserveAttachments) * SizeOf(TVkUInt32)
      );
    end;
    if Length(ASubpasses[i].ResolveAttachments) > 0 then
    begin
      _Hash := LabCRC32(
        _Hash, @ASubpasses[i].ResolveAttachments[0],
        Length(ASubpasses[i].ResolveAttachments) * SizeOf(TVkAttachmentReference)
      );
    end;
  end;
  if Length(ADependencies) > 0 then
  begin
    _Hash := LabCRC32(_Hash, @ADependencies[0], Length(ADependencies) * SizeOf(TVkSubpassDependency));
  end;
end;

destructor TLabRenderPass.Destroy;
begin
  Vulkan.DestroyRenderPass(_Device.Ptr.VkHandle, _Handle, nil);
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
  if Length(InputAttachments) > 0 then
  begin
    Move(InputAttachments[0], Result.InputAttachments[0], SizeOf(TVkAttachmentReference) * Length(InputAttachments));
  end;
  SetLength(Result.ColorAttachments, Length(ColorAttachments));
  if Length(ColorAttachments) > 0 then
  begin
    Move(ColorAttachments[0], Result.ColorAttachments[0], SizeOf(TVkAttachmentReference) * Length(ColorAttachments));
  end;
  SetLength(Result.ResolveAttachments, Length(ResolveAttachments));
  if Length(ResolveAttachments) > 0 then
  begin
    Move(ResolveAttachments[0], Result.ResolveAttachments[0], SizeOf(TVkAttachmentReference) * Length(ResolveAttachments));
  end;
  SetLength(Result.PreserveAttachments, Length(PreserveAttachments));
  if Length(PreserveAttachments) > 0 then
  begin
    Move(PreserveAttachments[0], Result.PreserveAttachments[0], SizeOf(TVkUInt32) * Length(PreserveAttachments));
  end;
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
    Result.pPreserveAttachments := @Data.PreserveAttachments[0];
  end
  else
  begin
    Result.pPreserveAttachments := nil;
  end;
end;

function LabAttachmentReference(const Attachment: TVkUInt32; const Layout: TVkImageLayout): TVkAttachmentReference;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.attachment := Attachment;
  Result.layout := Layout;
end;

function LabSubpassDependency(
  const SrcSubpass: TVkUInt32;
  const DstSubpass: TVkUInt32;
  const SrcStageMask: TVkPipelineStageFlags;
  const DstStageMask: TVkPipelineStageFlags;
  const SrcAccessMask: TVkAccessFlags;
  const DstAccessMask: TVkAccessFlags;
  const DependencyFlags: TVkDependencyFlags
): TVkSubpassDependency;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.srcSubpass := SrcSubpass;
  Result.dstSubpass := DstSubpass;
  Result.srcStageMask := SrcStageMask;
  Result.dstStageMask := DstStageMask;
  Result.srcAccessMask := SrcAccessMask;
  Result.dstAccessMask := DstAccessMask;
  Result.dependencyFlags := DependencyFlags;
end;

end.
