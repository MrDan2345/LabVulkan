unit main;

{$macro on}
{$include LabPlatform.inc}

interface

uses
  cube_data,
  Vulkan,
  LabTypes,
  LabMath,
  LabWindow,
  LabSwapChain,
  LabVulkan,
  LabDevice,
  LabCommandPool,
  LabCommandBuffer,
  LabBuffer,
  LabImage,
  LabSurface,
  LabDescriptorSet,
  LabPipeline,
  LabRenderPass,
  LabShader,
  LabFrameBuffer,
  LabDescriptorPool,
  LabPlatform,
  LabSync,
  LabUtils,
  Classes,
  SysUtils;

type
  TUniformData = packed record
    World: TLabMat;
    View: TLabMat;
    Projection: TLabMat;
    WVP: TLabMat;
  end;
  TUniformArray = specialize TLabAlignedArray<TUniformData>;
  TUniformArrayShared = specialize TLabSharedRef<TUniformArray>;

  TLabApp = class (TLabVulkan)
  public
    var Window: TLabWindow;
    var Device: TLabDeviceShared;
    var Surface: TLabSurfaceShared;
    var SwapChain: TLabSwapChainShared;
    var CmdPool: TLabCommandPoolShared;
    var CmdBuffer: TLabCommandBufferShared;
    var Semaphore: TLabSemaphoreShared;
    var Fence: TLabFenceShared;
    var DepthBuffers: array of TLabDepthBufferShared;
    var FrameBuffers: array of TLabFrameBufferShared;
    var UniformBuffer: TLabBufferShared;
    var DescriptorSetLayout: TLabDescriptorSetLayoutShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var RenderPass: TLabRenderPassShared;
    var VertexShader: TLabShaderShared;
    var PixelShader: TLabShaderShared;
    var VertexBuffer: TLabVertexBufferShared;
    var VertexBufferStaging: TLabBufferShared;
    var DescriptorPool: TLabDescriptorPoolShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineCache: TLabPipelineCacheShared;
    var Transforms: TUniformArrayShared;
    constructor Create;
    procedure SwapchainCreate;
    procedure SwapchainDestroy;
    procedure UpdateTransforms;
    procedure TransferBuffers;
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
    function GetUniformBufferOffsetAlignment(const BufferSize: TVkDeviceSize): TVkDeviceSize;
  end;

const
  NUM_SAMPLES = VK_SAMPLE_COUNT_1_BIT;
  NUM_DESCRIPTOR_SETS = 1;
  NUM_VIEWPORTS = 1;
  NUM_SCISSORS = NUM_VIEWPORTS;
  //Amount of time, in nanoseconds, to wait for a command buffer to complete
  FENCE_TIMEOUT = 100000000;

  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

var
  App: TLabApp;

implementation

constructor TLabApp.Create;
begin
  //EnableLayerIfAvailable('VK_LAYER_LUNARG_api_dump');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_core_validation');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_parameter_validation');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_standard_validation');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_object_tracker');
  OnInitialize := @Initialize;
  OnFinalize := @Finalize;
  OnLoop := @Loop;
  inherited Create;
end;

procedure TLabApp.SwapchainCreate;
  var i: Integer;
begin
  SwapChain := TLabSwapChain.Create(Device, Surface);
  SetLength(DepthBuffers, SwapChain.Ptr.ImageCount);
  for i := 0 to SwapChain.Ptr.ImageCount - 1 do
  begin
    DepthBuffers[i] := TLabDepthBuffer.Create(Device, Window.Width, Window.Height);
  end;
  RenderPass := TLabRenderPass.Create(
    Device,
    [
      LabAttachmentDescription(
        SwapChain.Ptr.Format,
        VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE,
        VK_IMAGE_LAYOUT_UNDEFINED,
        0
      ),
      LabAttachmentDescription(
        DepthBuffers[0].Ptr.Format,
        VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_LOAD,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_IMAGE_LAYOUT_UNDEFINED,
        0
      )
    ], [
      LabSubpassDescriptionData(
        [],
        [LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)],
        [],
        LabAttachmentReference(1, VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL),
        []
      )
    ],
    []
  );
  SetLength(FrameBuffers, SwapChain.Ptr.ImageCount);
  for i := 0 to SwapChain.Ptr.ImageCount - 1 do
  begin
    FrameBuffers[i] := TLabFrameBuffer.Create(
      Device, RenderPass.Ptr,
      SwapChain.Ptr.Width, SwapChain.Ptr.Height,
      [SwapChain.Ptr.Images[i]^.View.VkHandle, DepthBuffers[i].Ptr.View.VkHandle]
    );
  end;
end;

procedure TLabApp.SwapchainDestroy;
  var i: Integer;
begin
  FrameBuffers := nil;
  DepthBuffers := nil;
  RenderPass := nil;
  SwapChain := nil;
end;

procedure TLabApp.UpdateTransforms;
  var i: Integer;
  var fov: TVkFloat;
  var Clip: TLabMat;
begin
  fov := LabDegToRad * 45;
  for i := 0 to Transforms.Ptr.Count - 1 do
  with Transforms.Ptr.Items[i]^ do
  begin
    Projection := LabMatProj(fov, Window.Width / Window.Height, 0.1, 100);
    View := LabMatView(LabVec3(-8, 5, -4), LabVec3(5, 0, 0), LabVec3(0, 1, 0));
    World := LabMatRotationY((LabTimeLoopSec(5) / 5) * Pi * 2) * LabMatTranslation(i * 5, 0, 0);
    Clip := LabMat(
      1, 0, 0, 0,
      0, -1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    );
    WVP := World * View * Projection * Clip;
  end;
end;

procedure TLabApp.TransferBuffers;
begin
  CmdBuffer.Ptr.RecordBegin;
  CmdBuffer.Ptr.CopyBuffer(
    VertexBufferStaging.Ptr.VkHandle,
    VertexBuffer.Ptr.VkHandle,
    [LabBufferCopy(VertexBuffer.Ptr.Size)]
  );
  CmdBuffer.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [CmdBuffer.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE
  );
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
  VertexBufferStaging := nil;
end;

procedure TLabApp.Initialize;
  var map: PVkVoid;
begin
  Window := TLabWindow.Create(500, 500);
  Window.Caption := 'Vulkan Uniforms';
  Device := TLabDevice.Create(
    PhysicalDevices[0],
    [
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT)))
    ],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  Surface := TLabSurface.Create(Window);
  SwapChainCreate;
  CmdPool := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexGraphics);
  CmdBuffer := TLabCommandBuffer.Create(CmdPool);
  Transforms := TUniformArray.Create(GetUniformBufferOffsetAlignment(SizeOf(TUniformData)));
  Transforms.Ptr.Count := 20;
  UniformBuffer := TLabBuffer.Create(
    Device, Transforms.Ptr.DataSize,
    TVkFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT),
    [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  VertexShader := TLabVertexShader.Create(Device, 'vs.spv');
  PixelShader := TLabPixelShader.Create(Device, 'ps.spv');
  VertexBuffer := TLabVertexBuffer.Create(
    Device,
    sizeof(g_vb_solid_face_colors_Data),
    sizeof(g_vb_solid_face_colors_Data[0]),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, 0),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, 16)
    ],
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexBufferStaging := TLabBuffer.Create(
    Device, VertexBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (VertexBufferStaging.Ptr.Map(map)) then
  begin
    Move(g_vb_solid_face_colors_Data, map^, sizeof(g_vb_solid_face_colors_Data));
    VertexBufferStaging.Ptr.Unmap;
  end;
  DescriptorSetLayout := TLabDescriptorSetLayout.Create(
    Device, [LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT))]
  );
  DescriptorPool := TLabDescriptorPool.Create(
    Device,
    [LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, 1)],
    1
  );
  DescriptorSets := TLabDescriptorSets.Create(
    Device, DescriptorPool,
    [DescriptorSetLayout.Ptr.VkHandle]
  );
  DescriptorSets.Ptr.UpdateSets(
    [
      LabWriteDescriptorSet(
        DescriptorSets.Ptr.VkHandle[0],
        0,
        VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
        0,
        1,
        nil,
        UniformBuffer.Ptr.BufferInfo
      )
    ],
    []
  );
  PipelineCache := TLabPipelineCache.Create(Device);
  PipelineLayout := TLabPipelineLayout.Create(Device, [], [DescriptorSetLayout]);
  Pipeline := TLabGraphicsPipeline.Create(
    Device, PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [VertexShader.Ptr, PixelShader.Ptr],
    RenderPass.Ptr, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState(
      [VertexBuffer.Ptr.MakeBindingDesc(0)],
      [
        VertexBuffer.Ptr.MakeAttributeDesc(0, 0, 0),
        VertexBuffer.Ptr.MakeAttributeDesc(1, 1, 0)
      ]
    ),
    LabPipelineRasterizationState(
      VK_FALSE, VK_FALSE, VK_POLYGON_MODE_FILL,
      TVkFlags(VK_CULL_MODE_BACK_BIT), VK_FRONT_FACE_COUNTER_CLOCKWISE
    ),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState(1, @LabDefaultColorBlendAttachment, [])
  );
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  TransferBuffers;
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  SwapchainDestroy;
  Fence := nil;
  Semaphore := nil;
  Pipeline := nil;
  PipelineCache := nil;
  DescriptorSets := nil;
  DescriptorPool := nil;
  VertexBuffer := nil;
  PixelShader := nil;
  VertexShader := nil;
  PipelineLayout := nil;
  DescriptorSetLayout := nil;
  UniformBuffer := nil;
  CmdBuffer := nil;
  CmdPool := nil;
  Surface := nil;
  Device := nil;
  Window.Free;
  Free;
end;

procedure TLabApp.Loop;
  var UniformData: PVkUInt8;
  var cur_buffer: TVkUInt32;
  var r: TVkResult;
  var i: Integer;
begin
  TLabVulkan.IsActive := Window.IsActive;
  if not TLabVulkan.IsActive then Exit;
  if (SwapChain.Ptr.Width <> Window.Width)
  or (SwapChain.Ptr.Height <> Window.Height) then
  begin
    Device.Ptr.WaitIdle;
    SwapchainDestroy;
    SwapchainCreate;
  end;
  UpdateTransforms;
  UniformData := nil;
  if (UniformBuffer.Ptr.Map(UniformData)) then
  begin
    Move(Transforms.Ptr.Data^, UniformData^, Transforms.Ptr.DataSize);
    UniformBuffer.Ptr.FlushMappedMemoryRanges(
      [
        LabMappedMemoryRange(UniformBuffer.Ptr.Memory, 0, UniformBuffer.Ptr.Size)
      ]
    );
    UniformBuffer.Ptr.Unmap;
  end;
  r := SwapChain.Ptr.AcquireNextImage(Semaphore, cur_buffer);
  if r = VK_ERROR_OUT_OF_DATE_KHR then
  begin
    LabLogVkError(r);
    Device.Ptr.WaitIdle;
    SwapchainDestroy;
    SwapchainCreate;
    Exit;
  end
  else
  begin
    LabAssertVkError(r);
  end;
  CmdBuffer.Ptr.RecordBegin();
  CmdBuffer.Ptr.BeginRenderPass(
    RenderPass.Ptr, FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(1.0, 0)]
  );
  CmdBuffer.Ptr.BindPipeline(Pipeline.Ptr);
  CmdBuffer.Ptr.BindVertexBuffers(0, [VertexBuffer.Ptr.VkHandle], [0]);
  CmdBuffer.Ptr.SetViewport([LabViewport(0, 0, Window.Width, Window.Height)]);
  CmdBuffer.Ptr.SetScissor([LabRect2D(0, 0, Window.Width, Window.Height)]);
  for i := 0 to Transforms.Ptr.Count - 1 do
  begin
    CmdBuffer.Ptr.BindDescriptorSets(
      VK_PIPELINE_BIND_POINT_GRAPHICS,
      PipelineLayout.Ptr,
      0, 1, DescriptorSets.Ptr, [Transforms.Ptr.ItemOffset[i]]
    );
    CmdBuffer.Ptr.Draw(12 * 3);
  end;
  CmdBuffer.Ptr.EndRenderPass;
  CmdBuffer.Ptr.RecordEnd;
  QueueSubmit(
    SwapChain.Ptr.QueueFamilyGraphics,
    [CmdBuffer.Ptr.VkHandle],
    [Semaphore.Ptr.VkHandle],
    [],
    Fence.Ptr.VkHandle,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  Fence.Ptr.WaitFor;
  Fence.Ptr.Reset;
  QueuePresent(SwapChain.Ptr.QueueFamilyPresent, [SwapChain.Ptr.VkHandle], [cur_buffer], []);
end;

function TLabApp.GetUniformBufferOffsetAlignment(const BufferSize: TVkDeviceSize): TVkDeviceSize;
  var align: TVkDeviceSize;
begin
  align := Device.Ptr.PhysicalDevice.Ptr.Properties^.limits.minUniformBufferOffsetAlignment;
  Result := BufferSize;
  if align > 0 then
  begin
    Result := (Result + align - 1) and (not(align - 1));
  end;
end;

end.
