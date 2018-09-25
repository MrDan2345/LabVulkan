unit LabCommandBuffer;

interface

uses
  Vulkan,
  LabSync,
  LabTypes,
  LabUtils,
  LabCommandPool,
  LabRenderPass,
  LabFrameBuffer,
  LabPipeline,
  LabDescriptorSet,
  LabBuffer;

type
  TLabCommandBuffer = class (TLabClass)
  private
    var _CommandPool: TLabCommandPoolShared;
    var _Handle: TVkCommandBuffer;
    var _Recording: Boolean;
  public
    property CommandPool: TLabCommandPoolShared read _CommandPool;
    property VkHandle: TVkCommandBuffer read _Handle;
    property Recording: Boolean read _Recording;
    constructor Create(
      const ACommandPool: TLabCommandPoolShared;
      const ALevel: TVkCommandBufferLevel = VK_COMMAND_BUFFER_LEVEL_PRIMARY
    );
    destructor Destroy; override;
    function RecordBegin(const Flags: TVkCommandBufferUsageFlags = 0): Boolean;
    function RecordEnd: Boolean;
    function QueueSubmit(const Queue: TVkQueue; const WaitSemaphores: array of TVkSemaphore): Boolean;
    procedure BeginRenderPass(
      const RenderPass: TLabRenderPass;
      const FrameBuffer: TLabFrameBuffer;
      const ClearValues: array of TVkClearValue;
      const X: TVkInt32 = -1;
      const Y: TVkInt32 = -1;
      const Width: TVkInt32 = -1;
      const Height: TVkInt32 = -1;
      const Contents: TVkSubpassContents = VK_SUBPASS_CONTENTS_INLINE
    );
    procedure EndRenderPass;
    procedure BindPipeline(const Pipeline: TLabPipeline);
    procedure BindDescriptorSets(
      const PipelineBindPoint: TVkPipelineBindPoint;
      const Layout: TLabPipelineLayout;
      const FirstSet: TVkUInt32;
      const SetCount:TVkUInt32;
      const DescriptorSets: TLabDescriptorSets;
      const DynamicOffsets: array of TVkUInt32
    );
    procedure BindVertexBuffers(
      const FirstBinding: TVkUInt32;
      const Buffers: array of TVkBuffer;
      const Offsets: array of TVkDeviceSize
    );
    procedure SetViewport(const Viewports: array of TVkViewport);
    procedure SetScissor(const Scissors: array of TVkRect2D);
    procedure Draw(
      const VertexCount: TVkUInt32;
      const InstanceCount: TVkUInt32 = 1;
      const FirstVertex: TVkUInt32 = 0;
      const FirstInstance: TVkUInt32 = 0
    );
    procedure CopyBuffer(
      const Src, Dst: TVkBuffer;
      const Regions: array of TVkBufferCopy
    );
    procedure CopyBufferToImage(
      const Src: TVkBuffer;
      const Dst: TVkImage;
      const ImageLayout: TVkImageLayout;
      const Regions: array of TVkBufferImageCopy
    );
    procedure PipelineBarrier(
      const SrcStageMask: TVkPipelineStageFlags;
      const DstStageMask: TVkPipelineStageFlags;
      const DependencyFlags: TVkDependencyFlags;
      const MemoryBarriers: array of TVkMemoryBarrier;
      const BufferMemoryBarriers: array of TVkBufferMemoryBarrier;
      const ImageMemoryBarriers: array of TVkImageMemoryBarrier
    );
  end;
  TLabCommandBufferShared = specialize TLabSharedRef<TLabCommandBuffer>;

function LabClearValue(const r, g, b, a: TVkFloat): TVkClearValue; overload;
function LabClearValue(const r, g, b, a: TVkUInt32): TVkClearValue; overload;
function LabClearValue(const r, g, b, a: TVkInt32): TVkClearValue; overload;
function LabClearValue(const Depth: TVkFloat; const Stencil: TVkUInt32): TVkClearValue; overload;

function LabViewport(
  const X: TVkFloat;
  const Y: TVkFloat;
  const Width: TVkFloat;
  const Height: TVkFloat;
  const MinDepth: TVkFloat = 0;
  const MaxDepth: TVkFloat = 1
): TVkViewport;

function LabImageMemoryBarrier(
  const Image: TVkImage;
  const OldLayout: TVkImageLayout;
  const NewLayout: TVkImageLayout;
  const SrcAccessMask: TVkAccessFlags = 0;
  const DstAccessMask: TVkAccessFlags = 0;
  const SrcQueueFamilyIndex: TVkUInt32 = VK_QUEUE_FAMILY_IGNORED;
  const DstQueueFamilyIndex: TVkUInt32 = VK_QUEUE_FAMILY_IGNORED;
  const ImageAspectMask: TVkImageAspectFlags = TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT);
  const ImageBaseMipLevel: TVkUInt32 = 0;
  const ImageMipLevelCount: TVkUInt32 = 1;
  const ImageBaseArrayLayer: TVkUInt32 = 0;
  const ImageArrayLayerCount: TVkUInt32 = 1
): TVkImageMemoryBarrier;

implementation

//TLabCommandBuffer BEGIN
constructor TLabCommandBuffer.Create(
  const ACommandPool: TLabCommandPoolShared;
  const ALevel: TVkCommandBufferLevel
);
  var command_buffer_info: TVkCommandBufferAllocateInfo;
begin
  LabLog('TLabCommandBuffer.Create');
  _Recording := False;
  _CommandPool := ACommandPool;
  LabZeroMem(@command_buffer_info, SizeOf(TVkCommandBufferAllocateInfo));
  command_buffer_info.sType := VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
  command_buffer_info.commandPool := ACommandPool.Ptr.VkHandle;
  command_buffer_info.level := ALevel;
  command_buffer_info.commandBufferCount := 1;
  LabAssertVkError(Vulkan.AllocateCommandBuffers(_CommandPool.Ptr.Device.Ptr.VkHandle, @command_buffer_info, @_Handle));
end;

destructor TLabCommandBuffer.Destroy;
begin
  if LabVkValidHandle(_Handle) then
  begin
    Vulkan.FreeCommandBuffers(_CommandPool.Ptr.Device.Ptr.VkHandle, _CommandPool.Ptr.VkHandle, 1, @_Handle);
  end;
  inherited Destroy;
  LabLog('TLabCommandBuffer.Destroy');
end;

function TLabCommandBuffer.RecordBegin(const Flags: TVkCommandBufferUsageFlags): Boolean;
  var cbb_info: TVkCommandBufferBeginInfo;
begin
  if _Recording then Exit(False);
  LabZeroMem(@cbb_info, SizeOf(cbb_info));
  cbb_info.sType := VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
  cbb_info.flags := Flags;
  cbb_info.pInheritanceInfo := nil;
  LabAssertVkError(Vulkan.BeginCommandBuffer(_Handle, @cbb_info));
  _Recording := True;
  Result := True;
end;

function TLabCommandBuffer.RecordEnd: Boolean;
begin
  if not _Recording then Exit(False);
  LabAssertVkError(Vulkan.EndCommandBuffer(_Handle));
  _Recording := False;
  Result := True;
end;

function TLabCommandBuffer.QueueSubmit(const Queue: TVkQueue; const WaitSemaphores: array of TVkSemaphore): Boolean;
  var fence: TLabFence;
  var submit_info: TVkSubmitInfo;
  var pipe_stage_flags: TVkPipelineStageFlags;
begin
  fence := TLabFence.Create(_CommandPool.Ptr.Device);
  pipe_stage_flags := TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT);
  LabZeroMem(@submit_info, SizeOf(submit_info));
  submit_info.sType := VK_STRUCTURE_TYPE_SUBMIT_INFO;
  submit_info.waitSemaphoreCount := Length(WaitSemaphores);
  if Length(WaitSemaphores) > 0 then submit_info.pWaitSemaphores := @WaitSemaphores[0] else submit_info.pWaitSemaphores := nil;
  submit_info.pWaitDstStageMask := @pipe_stage_flags;
  submit_info.commandBufferCount := 1;
  submit_info.pCommandBuffers := @_Handle;
  submit_info.signalSemaphoreCount := 0;
  submit_info.pSignalSemaphores := nil;
  LabAssertVkError(Vulkan.QueueSubmit(Queue, 1, @submit_info, fence.VkHandle));
  while fence.WaitFor = VK_TIMEOUT do;
  fence.Free;
  Result := True;
end;

procedure TLabCommandBuffer.BeginRenderPass(
  const RenderPass: TLabRenderPass;
  const FrameBuffer: TLabFrameBuffer;
  const ClearValues: array of TVkClearValue;
  const X: TVkInt32; const Y: TVkInt32;
  const Width: TVkInt32; const Height: TVkInt32;
  const Contents: TVkSubpassContents
);
  var rp_begin_info: TVkRenderPassBeginInfo;
begin
  rp_begin_info.sType := VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
  rp_begin_info.pNext := nil;
  rp_begin_info.renderPass := RenderPass.VkHandle;
  rp_begin_info.framebuffer := FrameBuffer.VkHandle;
  if X > -1 then rp_begin_info.renderArea.offset.x := X
  else rp_begin_info.renderArea.offset.x := 0;
  if Y > -1 then rp_begin_info.renderArea.offset.y := Y
  else rp_begin_info.renderArea.offset.y := 0;
  if Width > -1 then rp_begin_info.renderArea.extent.width := Width
  else rp_begin_info.renderArea.extent.width := FrameBuffer.Width;
  if Height > -1 then rp_begin_info.renderArea.extent.height := Height
  else rp_begin_info.renderArea.extent.height := FrameBuffer.Height;
  rp_begin_info.clearValueCount := Length(ClearValues);
  rp_begin_info.pClearValues := @ClearValues[0];
  Vulkan.CmdBeginRenderPass(_Handle, @rp_begin_info, Contents);
end;

procedure TLabCommandBuffer.EndRenderPass;
begin
  Vulkan.CmdEndRenderPass(_Handle);
end;

procedure TLabCommandBuffer.BindPipeline(const Pipeline: TLabPipeline);
begin
  Vulkan.CmdBindPipeline(_Handle, Pipeline.BindPoint, Pipeline.VkHandle);
end;

procedure TLabCommandBuffer.BindDescriptorSets(
  const PipelineBindPoint: TVkPipelineBindPoint;
  const Layout: TLabPipelineLayout;
  const FirstSet: TVkUInt32;
  const SetCount: TVkUInt32;
  const DescriptorSets: TLabDescriptorSets;
  const DynamicOffsets: array of TVkUInt32
);
  var dynamic_offsets: PVkUInt32;
begin
  if (Length(DynamicOffsets) > 0) then
  begin
    dynamic_offsets := @DynamicOffsets[0];
  end
  else
  begin
    dynamic_offsets := nil;
  end;
  Vulkan.CmdBindDescriptorSets(
    _Handle,
    PipelineBindPoint,
    Layout.VkHandle,
    FirstSet,
    SetCount,
    DescriptorSets.VkHandlePtr[0],
    Length(DynamicOffsets),
    dynamic_offsets
  );
end;

procedure TLabCommandBuffer.BindVertexBuffers(
  const FirstBinding: TVkUInt32;
  const Buffers: array of TVkBuffer;
  const Offsets: array of TVkDeviceSize
);
begin
  Vulkan.CmdBindVertexBuffers(
    _Handle, FirstBinding, Length(Buffers),
    @Buffers[0], @Offsets[0]
  );
end;

procedure TLabCommandBuffer.SetViewport(const Viewports: array of TVkViewport);
begin
  Vulkan.CmdSetViewport(_Handle, 0, Length(Viewports), @Viewports[0]);
end;

procedure TLabCommandBuffer.SetScissor(const Scissors: array of TVkRect2D);
begin
  Vulkan.CmdSetScissor(_Handle, 0, Length(Scissors), @Scissors[0]);
end;

procedure TLabCommandBuffer.Draw(
  const VertexCount: TVkUInt32;
  const InstanceCount: TVkUInt32;
  const FirstVertex: TVkUInt32;
  const FirstInstance: TVkUInt32
);
begin
  Vulkan.CmdDraw(_Handle, VertexCount, InstanceCount, FirstVertex, FirstInstance);
end;

procedure TLabCommandBuffer.CopyBuffer(const Src, Dst: TVkBuffer; const Regions: array of TVkBufferCopy);
begin
  Vulkan.CmdCopyBuffer(_Handle, Src, Dst, Length(Regions), @Regions[0]);
end;

procedure TLabCommandBuffer.CopyBufferToImage(
  const Src: TVkBuffer;
  const Dst: TVkImage;
  const ImageLayout: TVkImageLayout;
  const Regions: array of TVkBufferImageCopy
);
begin
  Vulkan.CmdCopyBufferToImage(_Handle, Src, Dst, ImageLayout, Length(Regions), @Regions[0]);
end;

procedure TLabCommandBuffer.PipelineBarrier(
  const SrcStageMask: TVkPipelineStageFlags;
  const DstStageMask: TVkPipelineStageFlags;
  const DependencyFlags: TVkDependencyFlags;
  const MemoryBarriers: array of TVkMemoryBarrier;
  const BufferMemoryBarriers: array of TVkBufferMemoryBarrier;
  const ImageMemoryBarriers: array of TVkImageMemoryBarrier
);
begin
  Vulkan.CmdPipelineBarrier(
    _Handle,
    SrcStageMask, DstStageMask, DependencyFlags,
    Length(MemoryBarriers), @MemoryBarriers[0],
    Length(BufferMemoryBarriers), @BufferMemoryBarriers[0],
    Length(ImageMemoryBarriers), @ImageMemoryBarriers[0]
  );
end;
//TLabCommandBuffer END

function LabClearValue(const r, g, b, a: TVkFloat): TVkClearValue;
begin
  Result.color.float32[0] := r;
  Result.color.float32[1] := g;
  Result.color.float32[2] := b;
  Result.color.float32[3] := a;
end;

function LabClearValue(const r, g, b, a: TVkUInt32): TVkClearValue;
begin
  Result.color.uint32[0] := r;
  Result.color.uint32[1] := g;
  Result.color.uint32[2] := b;
  Result.color.uint32[3] := a;
end;

function LabClearValue(const r, g, b, a: TVkInt32): TVkClearValue;
begin
  Result.color.int32[0] := r;
  Result.color.int32[1] := g;
  Result.color.int32[2] := b;
  Result.color.int32[3] := a;
end;

function LabClearValue(const Depth: TVkFloat; const Stencil: TVkUInt32): TVkClearValue;
begin
  Result.depthStencil.depth := Depth;
  Result.depthStencil.stencil := Stencil;
end;

function LabViewport(
  const X: TVkFloat; const Y: TVkFloat;
  const Width: TVkFloat; const Height: TVkFloat;
  const MinDepth: TVkFloat; const MaxDepth: TVkFloat
): TVkViewport;
begin
  Result.x := X;
  Result.y := Y;
  Result.width := Width;
  Result.height := Height;
  Result.minDepth := MinDepth;
  Result.maxDepth := MaxDepth;
end;

function LabImageMemoryBarrier(
  const Image: TVkImage;
  const OldLayout: TVkImageLayout;
  const NewLayout: TVkImageLayout;
  const SrcAccessMask: TVkAccessFlags;
  const DstAccessMask: TVkAccessFlags;
  const SrcQueueFamilyIndex: TVkUInt32;
  const DstQueueFamilyIndex: TVkUInt32;
  const ImageAspectMask: TVkImageAspectFlags;
  const ImageBaseMipLevel: TVkUInt32;
  const ImageMipLevelCount: TVkUInt32;
  const ImageBaseArrayLayer: TVkUInt32;
  const ImageArrayLayerCount: TVkUInt32
): TVkImageMemoryBarrier;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.sType := VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
  Result.image := Image;
  Result.srcQueueFamilyIndex := SrcQueueFamilyIndex;
  Result.dstQueueFamilyIndex := DstQueueFamilyIndex;
  Result.srcAccessMask := SrcAccessMask;
  Result.dstAccessMask := DstAccessMask;
  Result.oldLayout := OldLayout;
  Result.newLayout := NewLayout;
  Result.subresourceRange.aspectMask := ImageAspectMask;
  Result.subresourceRange.baseMipLevel := ImageBaseMipLevel;
  Result.subresourceRange.levelCount := ImageMipLevelCount;
  Result.subresourceRange.baseArrayLayer := ImageBaseArrayLayer;
  Result.subresourceRange.layerCount := ImageArrayLayerCount;
end;

end.
