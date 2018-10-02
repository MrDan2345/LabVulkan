unit main;

{$macro on}
{$include LabPlatform.inc}

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
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
  LabColladaParser,
  LabScene,
  Classes,
  sysutils;

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
    var DescriptorPool: TLabDescriptorPoolShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineCache: TLabPipelineCacheShared;
    var Scene: TLabScene;
    var Transforms: TUniformArrayShared;
    constructor Create;
    procedure SwapchainCreate;
    procedure SwapchainDestroy;
    procedure ProcessScene;
    procedure UpdateTransforms;
    procedure TransferBuffers;
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
    function GetUniformBufferOffsetAlignment(const BufferSize: TVkDeviceSize): TVkDeviceSize;
  end;

  TGeometryData = class (TLabClass)
  private
    var _Geometry: TLabSceneGeometry;
  public
    var UniformOffset: TVkInt32;
    constructor Create(const Geometry: TLabSceneGeometry);
    destructor Destroy; override;
  end;

  TGeometrySubsetData = class (TLabClass)
  private
    var _Subset: TLabSceneGeometry.TSubset;
  public
    VertexBufferStaging: TLabBuffer;
    VertexBuffer: TLabVertexBuffer;
    IndexBufferStaging: TLabBuffer;
    IndexBuffer: TLabIndexBuffer;
    VertexShader: TLabSceneVertexShaderShared;
    PixelShader: TLabScenePixelShaderShared;
    constructor Create(const Subset: TLabSceneGeometry.TSubset);
    destructor Destroy; override;
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

constructor TGeometryData.Create(const Geometry: TLabSceneGeometry);
begin

end;

destructor TGeometryData.Destroy;
begin
  inherited Destroy;
end;

constructor TGeometrySubsetData.Create(const Subset: TLabSceneGeometry.TSubset);
  var map: Pointer;
begin
  _Subset := Subset;
  VertexBuffer := TLabVertexBuffer.Create(
    App.Device,
    Subset.VertexStride * Subset.VertexCount, Subset.VertexStride, Subset.VertexAttributes,
    TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexBufferStaging := TLabBuffer.Create(
    App.Device, VertexBuffer.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if VertexBufferStaging.Map(map) then
  begin
    Move(Subset.VertexData^, map^, VertexBuffer.Size);
    VertexBufferStaging.Unmap;
  end;
  Subset.FreeVertexData;
  IndexBuffer := TLabIndexBuffer.Create(
    App.Device,
    Subset.IndexCount, Subset.IndexType,
    TVkFlags(VK_BUFFER_USAGE_INDEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  IndexBufferStaging := TLabBuffer.Create(
    App.Device, IndexBuffer.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if IndexBufferStaging.Map(map) then
  begin
    Move(Subset.IndexData^, map^, IndexBuffer.Size);
    IndexBufferStaging.Unmap;
  end;
  Subset.FreeIndexData;
  VertexShader := TLabSceneShaderFactory.MakeVertexShader(Subset.Geometry.Scene, Subset.VertexDescriptor);
  PixelShader := TLabSceneShaderFactory.MakePixelShader(Subset.Geometry.Scene, Subset.VertexDescriptor);
end;

destructor TGeometrySubsetData.Destroy;
begin
  FreeAndNil(VertexBufferStaging);
  FreeAndNil(VertexBuffer);
  FreeAndNil(IndexBufferStaging);
  FreeAndNil(IndexBuffer);
  inherited Destroy;
end;

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
begin
  FrameBuffers := nil;
  DepthBuffers := nil;
  RenderPass := nil;
  SwapChain := nil;
end;

procedure TLabApp.ProcessScene;
  var r_n: TLabSceneNode;
  var r_a: TLabSceneNodeAttachmentGeometry;
  var r_g: TLabSceneGeometry.TSubset;
  var geom_data: TGeometryData;
  var i, i_n, i_a, i_g: Integer;
begin
  for i_n := 0 to Scene.Root.Children.Count - 1 do
  begin
    r_n := Scene.Root.Children[i_n];
    for i_a := 0 to r_n.Attachments.Count - 1 do
    begin
      r_a := r_n.Attachments[i_a];
      for i_g := 0 to r_a.Geometry.Subsets.Count - 1 do
      begin
        r_g := r_a.Geometry.Subsets[i_g];
        r_g.UserData := TGeometrySubsetData.Create(r_g);
      end;
    end;
  end;
  Transforms := TUniformArray.Create(GetUniformBufferOffsetAlignment(SizeOf(TUniformData)));
  Transforms.Ptr.Count := Scene.Geometries.Count;
  UniformBuffer := TLabBuffer.Create(
    Device, Transforms.Ptr.DataSize,
    TVkFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT),
    [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  for i := 0 to Scene.Geometries.Count - 1 do
  begin
    geom_data := TGeometryData.Create(Scene.Geometries[i]);
    geom_data.UniformOffset := i;
    Scene.Geometries[i].UserData := geom_data;
  end;
end;

procedure TLabApp.UpdateTransforms;
  var fov: TVkFloat;
  var Clip: TLabMat;
  var i: Integer;
  var i_n, i_a: Integer;
  var r_n: TLabSceneNode;
  var r_a: TLabSceneNodeAttachmentGeometry;
  var geom_data: TGeometryData;
  var UniformData: Pointer;
begin
  fov := LabDegToRad * 70;
  for i_n := 0 to Scene.Root.Children.Count - 1 do
  begin
    r_n := Scene.Root.Children[i_n];
    for i_a := 0 to r_n.Attachments.Count - 1 do
    begin
      r_a := r_n.Attachments[i_a];
      geom_data := TGeometryData(r_a.Geometry.UserData);
      with Transforms.Ptr.Items[geom_data.UniformOffset]^ do
      begin
        Projection := LabMatProj(fov, Window.Width / Window.Height, 0.1, 100);
        View := LabMatView(LabVec3(0, 3, -8), LabVec3(0, 1, 0), LabVec3(0, 1, 0));
        World := r_n.Transform * LabMatRotationY((LabTimeLoopSec(5) / 5) * Pi * 2);
        Clip := LabMat(
          1, 0, 0, 0,
          0, -1, 0, 0,
          0, 0, 1, 0,
          0, 0, 0, 1
        );
        WVP := World * View * Projection * Clip;
      end;
    end;
  end;
  UniformData := nil;
  if (UniformBuffer.Ptr.Map(UniformData)) then
  begin
    Move(Transforms.Ptr.Data^, UniformData^, Transforms.Ptr.DataSize);
    UniformBuffer.Ptr.FlushMappedMemoryRanges(
      [LabMappedMemoryRange(UniformBuffer.Ptr.Memory, 0, UniformBuffer.Ptr.Size)]
    );
    UniformBuffer.Ptr.Unmap;
  end;
end;

procedure TLabApp.TransferBuffers;
  var i_n, i_a, i_g: Integer;
  var r_n: TLabSceneNode;
  var r_a: TLabSceneNodeAttachmentGeometry;
  var r_g: TLabSceneGeometry.TSubset;
  var subset_data: TGeometrySubsetData;
begin
  CmdBuffer.Ptr.RecordBegin;
  for i_n := 0 to Scene.Root.Children.Count - 1 do
  begin
    r_n := Scene.Root.Children[i_n];
    for i_a := 0 to r_n.Attachments.Count - 1 do
    begin
      r_a := r_n.Attachments[i_a];
      for i_g := 0 to r_a.Geometry.Subsets.Count - 1 do
      begin
        r_g := r_a.Geometry.Subsets[i_g];
        subset_data := TGeometrySubsetData(r_g.UserData);
        CmdBuffer.Ptr.CopyBuffer(
          subset_data.VertexBufferStaging.VkHandle,
          subset_data.VertexBuffer.VkHandle,
          LabBufferCopy(subset_data.VertexBufferStaging.Size)
        );
        CmdBuffer.Ptr.CopyBuffer(
          subset_data.IndexBufferStaging.VkHandle,
          subset_data.IndexBuffer.VkHandle,
          LabBufferCopy(subset_data.IndexBufferStaging.Size)
        );
      end;
    end;
  end;
  CmdBuffer.Ptr.RecordEnd;
  QueueSubmit(SwapChain.Ptr.QueueFamilyGraphics, [CmdBuffer.Ptr.VkHandle], [], [], VK_NULL_HANDLE);
  QueueWaitIdle(SwapChain.Ptr.QueueFamilyGraphics);
  for i_n := 0 to Scene.Root.Children.Count - 1 do
  begin
    r_n := Scene.Root.Children[i_n];
    for i_a := 0 to r_n.Attachments.Count - 1 do
    begin
      r_a := r_n.Attachments[i_a];
      for i_g := 0 to r_a.Geometry.Subsets.Count - 1 do
      begin
        r_g := r_a.Geometry.Subsets[i_g];
        subset_data := TGeometrySubsetData(r_g.UserData);
        FreeAndNil(subset_data.VertexBufferStaging);
        FreeAndNil(subset_data.IndexBufferStaging);
      end;
    end;
  end;
end;

procedure TLabApp.Initialize;
  var fov: TVkFloat;
  var ColladaParser: TLabColladaParser;
begin
  //ColladaParser := TLabColladaParser.Create('../Models/skull.dae');
  //ColladaParser.RootNode.Dump;
  //ColladaParser.Free;
  Window := TLabWindow.Create(500, 500);
  Window.Caption := 'Vulkan Model';
  Device := TLabDevice.Create(
    PhysicalDevices[0],
    [LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT)))],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  Surface := TLabSurface.Create(Window);
  SwapChainCreate;
  CmdPool := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexGraphics);
  CmdBuffer := TLabCommandBuffer.Create(CmdPool);
  DescriptorSetLayout := TLabDescriptorSetLayout.Create(
    Device, [LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT))]
  );
  PipelineLayout := TLabPipelineLayout.Create(Device, [], [DescriptorSetLayout]);
  Scene := TLabScene.Create(Device);
  Scene.Add('../Models/maya/maya.dae');
  ProcessScene;
  DescriptorPool := TLabDescriptorPool.Create(
    Device,
    [LabDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1)],
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
        VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        0,
        1,
        nil,
        UniformBuffer.Ptr.BufferInfo
      )
    ],
    []
  );
  PipelineCache := TLabPipelineCache.Create(Device);
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  TransferBuffers;
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  SwapchainDestroy;
  Scene.Free;
  Fence := nil;
  Semaphore := nil;
  Pipeline := nil;
  PipelineCache := nil;
  DescriptorSets := nil;
  DescriptorPool := nil;
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
  var i_n, i_a, i_g: Integer;
  var r_n: TLabSceneNode;
  var r_a: TLabSceneNodeAttachmentGeometry;
  var r_g: TLabSceneGeometry.TSubset;
  var geom_data: TGeometryData;
  var subset_data: TGeometrySubsetData;
  var CurPipeline: TLabGraphicsPipeline;
  var r: TVkResult;
begin
  TLabVulkan.IsActive := Window.IsActive;
  if not TLabVulkan.IsActive then Exit;
  if Window.Mode = wm_minimized then Exit;
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
    Move(Transforms, UniformData^, SizeOf(Transforms));
    UniformBuffer.Ptr.Unmap;
  end;
  CmdBuffer.Ptr.RecordBegin();
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
  CmdBuffer.Ptr.BeginRenderPass(
    RenderPass.Ptr, FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(1.0, 0)]
  );
  CurPipeline := nil;
  for i_n := 0 to Scene.Root.Children.Count - 1 do
  begin
    r_n := Scene.Root.Children[i_n];
    for i_a := 0 to r_n.Attachments.Count - 1 do
    begin
      r_a := r_n.Attachments[i_a];
      geom_data := TGeometryData(r_a.Geometry.UserData);
      for i_g := 0 to r_a.Geometry.Subsets.Count - 1 do
      begin
        r_g := r_a.Geometry.Subsets[i_g];
        subset_data := TGeometrySubsetData(r_g.UserData);
        Pipeline := TLabGraphicsPipeline.FindOrCreate(
          Device, PipelineCache, PipelineLayout.Ptr,
          [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
          [subset_data.VertexShader.Ptr.Shader, subset_data.PixelShader.Ptr.Shader],
          RenderPass.Ptr, 0,
          LabPipelineViewportState(),
          LabPipelineInputAssemblyState(),
          LabPipelineVertexInputState(
            [subset_data.VertexBuffer.MakeBindingDesc(0)],
            subset_data.VertexBuffer.MakeAttributeDescArr(0, 0)
          ),
          LabPipelineRasterizationState(
            VK_FALSE, VK_FALSE,
            VK_POLYGON_MODE_FILL,
            TVkFlags(VK_CULL_MODE_BACK_BIT),
            VK_FRONT_FACE_COUNTER_CLOCKWISE
          ),
          LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
          LabPipelineMultisampleState(),
          LabPipelineColorBlendState(1, @LabDefaultColorBlendAttachment, [])
        );
        if not Assigned(CurPipeline)
        or (CurPipeline.Hash <> TLabGraphicsPipeline(Pipeline.Ptr).Hash) then
        begin
          CurPipeline := TLabGraphicsPipeline(Pipeline.Ptr);
          CmdBuffer.Ptr.BindPipeline(Pipeline.Ptr);
          CmdBuffer.Ptr.BindDescriptorSets(
            VK_PIPELINE_BIND_POINT_GRAPHICS,
            PipelineLayout.Ptr,
            0, 1, DescriptorSets.Ptr, [Transforms.Ptr.ItemOffset[geom_data.UniformOffset]]
          );
          CmdBuffer.Ptr.SetViewport([LabViewport(0, 0, Window.Width, Window.Height)]);
          CmdBuffer.Ptr.SetScissor([LabRect2D(0, 0, Window.Width, Window.Height)]);
        end;
        CmdBuffer.Ptr.BindVertexBuffers(0, [subset_data.VertexBuffer.VkHandle], [0]);
        CmdBuffer.Ptr.BindIndexBuffer(subset_data.IndexBuffer.VkHandle, 0, subset_data.IndexBuffer.IndexType);
        CmdBuffer.Ptr.DrawIndexed(subset_data.IndexBuffer.IndexCount);
      end;
    end;
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
