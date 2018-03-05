unit LabCommandBuffer;

interface

uses
  Vulkan,
  LabSync,
  LabTypes,
  LabUtils,
  LabCommandPool;

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
  end;
  TLabCommandBufferShared = specialize TLabSharedRef<TLabCommandBuffer>;

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

//TLabCommandBuffer END

end.
