unit main;

{$macro on}
{$include LabPlatform.inc}

interface

uses
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
  LabColladaParser,
  LabScene,
  LabFrameBuffer,
  LabPlatform,
  LabSync,
  LabUtils,
  LabImageData,
  Classes,
  SysUtils;

type
  TTransforms = record
    World: TLabMat;
    View: TLabMat;
    Projection: TLabMat;
    Clip: TLabMat;
    WVP: TLabMat;
  end;
  PTransforms = ^TTransforms;

  TTexture = class (TLabClass)
  private
    var Staging: TLabBufferShared;
    procedure Stage(const Args: array of const);
    procedure StageComplete(const Args: array of const);
  public
    var Image: TLabImageShared;
    var View: TLabImageViewShared;
    var Sampler: TLabSamplerShared;
    var MipLevels: TVkUInt32;
    var Alpha: Boolean;
    constructor Create(const FileName: String; const FilterLinear: Boolean = True; const UseMipMaps: Boolean = True);
    constructor Create(const ImageData: TLabImageData; const FilterLinear: Boolean = True; const UseMipMaps: Boolean = True);
    destructor Destroy; override;
  end;
  TTextureShared = specialize TLabSharedRef<TTexture>;

  TRenderTarget = object
    var Image: TLabImageShared;
    var View: TLabImageViewShared;
    procedure SetupImage(
      const Width: TVkUInt32;
      const Height: TVkUInt32;
      const Format: TVkFormat;
      const Usage: TVkImageUsageFlags;
      const SampleCount: TVkSampleCountFlagBits
    );
  end;

  TBackBuffer = class (TLabClass)
  private
    var _Window: TLabWindowShared;
    var _Device: TLabDeviceShared;
    var _Surface: TLabSurfaceShared;
    var _SwapChain: TLabSwapChainShared;
    var _RenderPass: TLabRenderPassShared;
    var _DepthBuffers: array of TLabDepthBufferShared;
    var _FrameBuffers: array of TLabFrameBufferShared;
    var _Semaphore: TLabSemaphoreShared;
    var _OnResize: TLabDelegate;
    var _OnSwapChainCreate: TLabDelegate;
    var _OnSwapChainDestroy: TLabDelegate;
    procedure SwapChainCreate;
    procedure SwapChainDestroy;
    function GetFrameBuffer(const Index: TVkInt32): TLabFrameBufferShared; inline;
    function GetDepthBuffer(const Index: TVkInt32): TLabDepthBufferShared; inline;
  public
    property Window: TLabWindowShared read _Window;
    property Device: TLabDeviceShared read _Device;
    property Surface: TLabSurfaceShared read _Surface;
    property SwapChain: TLabSwapChainShared read _SwapChain;
    property RenderPass: TLabRenderPassShared read _RenderPass;
    property ImageAquireSemaphore: TLabSemaphoreShared read _Semaphore;
    property OnResize: TLabDelegate read _OnResize;
    property OnSwapChainCreate: TLabDelegate read _OnSwapChainCreate;
    property OnSwapChainDestroy: TLabDelegate read _OnSwapChainDestroy;
    property FrameBuffers[const Index: TVkInt32]: TLabFrameBufferShared read GetFrameBuffer;
    property DepthBuffers[const Index: TVkInt32]: TLabDepthBufferShared read GetDepthBuffer;
    constructor Create(
      const AWindow: TLabWindowShared;
      const ADevice: TLabDeviceShared;
      const ASwapChainCreateCallbacks: array of TLabDelegate.TCallback;
      const ASwapChainDestroyCallbacks: array of TLabDelegate.TCallback;
      const AResizeCallbacks: array of TLabDelegate.TCallback
    );
    destructor Destroy; override;
    function FrameStart: Boolean;
    procedure FramePresent(const WaitSemaphores: array of TVkSemaphore);
  end;
  TBackBufferShared = specialize TLabSharedRef<TBackBuffer>;

  TDeferredBuffer = class (TLabClass)
  private
    var _BackBuffer: TBackBufferShared;
    var _WidthRT: TVkUInt32;
    var _HeightRT: TVkUInt32;
    var _RenderPass: TLabRenderPassShared;
    var _OnUpdateRenderTargets: TLabDelegate;
    procedure UpdateRenderTargets(const Params: array of const);
  public
    var RenderTargets: array of record
      Color: TRenderTarget;
      Depth: TRenderTarget;
      Normals: TRenderTarget;
      PhysParams: TRenderTarget;
      ZBuffer: TLabDepthBufferShared;
      FrameBuffer: TLabFrameBufferShared;
    end;
    property WidthRT: TVkUInt32 read _WidthRT;
    property HeightRT: TVkUInt32 read _HeightRT;
    property RenderPass: TLabRenderPassShared read _RenderPass;
    property OnUpdateRenderTargets: TLabDelegate read _OnUpdateRenderTargets;
    constructor Create(const ABackBuffer: TBackBufferShared; const AUpdateRenderTargetsCallbacks: array of TLabDelegate.TCallback);
    destructor Destroy; override;
  end;
  TDeferredBufferShared = specialize TLabSharedRef<TDeferredBuffer>;

  TScene = class (TLabClass)
  private
    type TUniformData = packed record
      wvp: TLabMat;
      w: TLabMat;
    end;
    type PUniformData = ^TUniformData;
    var UniformBuffer: TLabUniformBufferShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineLayout: TLabPipelineLayoutShared;
  public
    var UniformData: PUniformData;
    var Pipeline: TLabPipelineShared;
    var VertexShader: TLabVertexShaderShared;
    var TessCtrlShader: TLabTessControlShaderShared;
    var TessEvalShader: TLabTessEvaluationShaderShared;
    var PixelShader: TLabPixelShaderShared;
    constructor Create;
    destructor Destroy; override;
    procedure UpdateTransforms(const Params: array of const);
    procedure Draw(const Cmd: TLabCommandBuffer);
  end;
  TSceneShared = specialize TLabSharedRef<TScene>;

  TLight = class (TLabClass)
  private
    type TUniformData = packed record
      vp_i: TLabMat;
      screen_ratio: TLabVec4;
      camera_pos: TLabVec4;
    end;
    type PUniformData = ^TUniformData;
    var UniformBuffer: TLabUniformBufferShared;
    var UniformData: PUniformData;
    var VertexShader: TLabVertexShaderShared;
    var PixelShader: TLabPixelShaderShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    procedure Resize(const Params: array of const);
  public
    constructor Create;
    destructor Destroy; override;
    procedure UpdateTransforms(const Params: array of const);
    procedure BindOffscreenTargets(const Params: array of const);
    procedure Draw(const Cmd: TLabCommandBuffer);
  end;
  TLightShared = specialize TLabSharedRef<TLight>;

  TLabApp = class (TLabVulkan)
  public
    var Window: TLabWindowShared;
    var Device: TLabDeviceShared;
    var CmdPool: TLabCommandPoolShared;
    var Cmd: TLabCommandBufferShared;
    var Fence: TLabFenceShared;
    var BackBuffer: TBackBufferShared;
    var DeferredBuffer: TDeferredBufferShared;
    var DescriptorSetsFactory: TLabDescriptorSetsFactoryShared;
    var PipelineCache: TLabPipelineCacheShared;
    var OnStage: TLabDelegate;
    var OnStageComplete: TLabDelegate;
    var OnUpdateTransforms: TLabDelegate;
    var OnBindOffscreenTargets: TLabDelegate;
    var SampleCount: TVkSampleCountFlagBits;
    var Scene: TSceneShared;
    var Light: TLightShared;
    constructor Create;
    procedure UpdateRenderTargets(const Params: array of const);
    procedure UpdateTransforms;
    procedure TransferBuffers;
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
    procedure DrawScene;
    procedure DrawLights;
  end;

const
  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

var
  App: TLabApp;

implementation

procedure TLight.Resize(const Params: array of const);
  var w, h: TVkUInt32;
begin
  w := TVkUInt32(Params[0].VInteger);
  h := TVkUInt32(Params[1].VInteger);
  UniformData^.screen_ratio := LabVec4(w, h, 1 / w, 1 / h);
end;

constructor TLight.Create;
begin
  App.OnBindOffscreenTargets.Add(@BindOffscreenTargets);
  App.OnUpdateTransforms.Add(@UpdateTransforms);
  App.BackBuffer.Ptr.OnResize.Add(@Resize);
  VertexShader := TLabVertexShader.Create(App.Device, 'light_vs.spv');
  PixelShader := TLabPixelShader.Create(App.Device, 'light_ps.spv');
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings(
      [
        LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER),
        LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE),
        LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE),
        LabDescriptorBinding(3, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE),
        LabDescriptorBinding(4, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE)
      ],
      App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount
    )
  ]);
  PipelineLayout := TLabPipelineLayout.Create(
    App.Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]
  );
  Pipeline := TLabGraphicsPipeline.FindOrCreate(
    App.Device, App.PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_SCISSOR, VK_DYNAMIC_STATE_VIEWPORT],
    [LabShaderStage(VertexShader.Ptr), LabShaderStage(PixelShader.Ptr)],
    App.BackBuffer.Ptr.RenderPass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(App.SampleCount),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment],[]),
    LabPipelineTesselationState(0)
  );
  UniformBuffer := TLabUniformBuffer.Create(App.Device, SizeOf(TUniformData));
  UniformBuffer.Ptr.Map(UniformData);
  Resize([App.BackBuffer.Ptr.SwapChain.Ptr.Width, App.BackBuffer.Ptr.SwapChain.Ptr.Height]);
end;

destructor TLight.Destroy;
begin
  UniformBuffer.Ptr.Unmap;
  App.OnUpdateTransforms.Remove(@UpdateTransforms);
  App.OnBindOffscreenTargets.Remove(@BindOffscreenTargets);
  inherited Destroy;
end;

procedure TLight.UpdateTransforms(const Params: array of const);
  var xf: PTransforms;
begin
  xf := PTransforms(Params[0].VPointer);
  UniformData^.vp_i := (xf^.View * xf^.Projection * xf^.Clip).Inverse;
  UniformData^.camera_pos := LabVec4(LabMatViewPos(xf^.View), 1);
end;

procedure TLight.BindOffscreenTargets(const Params: array of const);
  var i: TVkInt32;
  var Writes: array of TLabWriteDescriptorSet;
begin
  SetLength(Writes, App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount * 5);
  for i := 0 to App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount - 1 do
  begin
    Writes[i * 5 + 0] := LabWriteDescriptorSetUniformBuffer(
      DescriptorSets.Ptr.VkHandle[i],
      0,
      [LabDescriptorBufferInfo(UniformBuffer.Ptr.VkHandle)]
    );
    Writes[i * 5 + 1] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      1,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Color.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * 5 + 2] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      2,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Depth.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * 5 + 3] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      3,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Normals.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * 5 + 4] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      4,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].PhysParams.View.Ptr.VkHandle
        )
      ]
    );
  end;
  DescriptorSets.Ptr.UpdateSets(Writes, []);
end;

procedure TLight.Draw(const Cmd: TLabCommandBuffer);
  var image_index: Integer;
begin
  image_index := App.BackBuffer.Ptr.SwapChain.Ptr.CurImage;
  Cmd.BindPipeline(Pipeline.Ptr);
  Cmd.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[image_index]], []
  );
  Cmd.Draw(3);
end;

constructor TScene.Create;
begin
  UniformBuffer := TLabUniformBuffer.Create(App.Device, SizeOf(TUniformData));
  UniformBuffer.Ptr.Map(UniformData);
  VertexShader := TLabVertexShader.Create(App.Device, 'sphere_vs.spv');
  TessCtrlShader := TLabTessControlShader.Create(App.Device, 'sphere_tcs.spv');
  TessEvalShader := TLabTessEvaluationShader.Create(App.Device, 'sphere_tes.spv');
  PixelShader := TLabPixelShader.Create(App.Device, 'sphere_ps.spv');
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request([
      LabDescriptorSetBindings([
        LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT))
      ])
  ]);
  DescriptorSets.Ptr.UpdateSets([
    LabWriteDescriptorSetUniformBuffer(DescriptorSets.Ptr.VkHandle[0], 0, LabDescriptorBufferInfo(UniformBuffer.Ptr.VkHandle))
  ], []);
  PipelineLayout := TLabPipelineLayout.Create(
    App.Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]
  );
  Pipeline := TLabGraphicsPipeline.FindOrCreate(
    App.Device, App.PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [
      LabShaderStage(VertexShader.Ptr),
      LabShaderStage(TessCtrlShader.Ptr),
      LabShaderStage(TessEvalShader.Ptr),
      LabShaderStage(PixelShader.Ptr)
    ],
    App.DeferredBuffer.Ptr.RenderPass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(VK_PRIMITIVE_TOPOLOGY_PATCH_LIST),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(
      //VK_FALSE, VK_FALSE, VK_POLYGON_MODE_FILL, TVkFlags(VK_CULL_MODE_BACK_BIT), VK_FRONT_FACE_COUNTER_CLOCKWISE
    ),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
    LabPipelineMultisampleState(App.SampleCount),
    LabPipelineColorBlendState(
      [
        LabDefaultColorBlendAttachment,
        LabDefaultColorBlendAttachment,
        LabDefaultColorBlendAttachment,
        LabDefaultColorBlendAttachment
      ],
      []
    ),
    LabPipelineTesselationState(3)
  );
  App.OnUpdateTransforms.Add(@UpdateTransforms);
end;

destructor TScene.Destroy;
begin
  App.OnUpdateTransforms.Remove(@UpdateTransforms);
  UniformBuffer.Ptr.Unmap;
  inherited Destroy;
end;

procedure TScene.UpdateTransforms(const Params: array of const);
  var xf: PTransforms;
begin
  xf := PTransforms(Params[0].VPointer);
  UniformData^.wvp := xf^.WVP;
  UniformData^.w := xf^.World;
end;

procedure TScene.Draw(const Cmd: TLabCommandBuffer);
begin
  Cmd.BindPipeline(Pipeline.Ptr);
  Cmd.BindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS, PipelineLayout.Ptr, 0, [DescriptorSets.Ptr.VkHandle[0]], []);
  Cmd.Draw(24);
end;

procedure TDeferredBuffer.UpdateRenderTargets(const Params: array of const);
  var i: TVkInt32;
  var SwapChain: TLabSwapChain;
begin
  SwapChain := TLabSwapChain(Params[0].VPointer);
  _WidthRT := LabMakePOT(LabMax(SwapChain.Width, 1));
  _HeightRT := LabMakePOT(LabMax(SwapChain.Height, 1));
  SetLength(RenderTargets, SwapChain.ImageCount);
  for i := 0 to SwapChain.ImageCount - 1 do
  begin
    RenderTargets[i].Color.SetupImage(_WidthRT, _HeightRT, VK_FORMAT_R8G8B8A8_UNORM, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT), App.SampleCount);
    RenderTargets[i].Depth.SetupImage(_WidthRT, _HeightRT, VK_FORMAT_R32_SFLOAT, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT), App.SampleCount);
    RenderTargets[i].Normals.SetupImage(_WidthRT, _HeightRT, VK_FORMAT_R8G8B8A8_SNORM, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT), App.SampleCount);
    RenderTargets[i].PhysParams.SetupImage(_WidthRT, _HeightRT, VK_FORMAT_R16G16_SFLOAT, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT), App.SampleCount);
    RenderTargets[i].ZBuffer := TLabDepthBuffer.Create(
      _BackBuffer.Ptr.Device, _WidthRT, _HeightRT, VK_FORMAT_UNDEFINED,
      TVkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT), App.SampleCount
    );
  end;
  _RenderPass := TLabRenderPass.Create(
    _BackBuffer.Ptr.Device,
    [
      LabAttachmentDescription(
        RenderTargets[0].Color.Image.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        App.SampleCount,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      ),
      LabAttachmentDescription(
        RenderTargets[0].Depth.Image.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        App.SampleCount,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      ),
      LabAttachmentDescription(
        RenderTargets[0].Normals.Image.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        App.SampleCount,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      ),
      LabAttachmentDescription(
        RenderTargets[0].PhysParams.Image.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        App.SampleCount,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      ),
      LabAttachmentDescription(
        RenderTargets[0].ZBuffer.Ptr.Format,
        VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        App.SampleCount,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      )
    ],
    [
      LabSubpassDescriptionData(
        [],
        [
          LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(1, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(2, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(3, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
        ],
        [],
        LabAttachmentReference(4, VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL),
        []
      )
    ],
    [
      LabSubpassDependency(
        VK_SUBPASS_EXTERNAL,
        0,
        TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
        TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
        TVkFlags(VK_ACCESS_MEMORY_READ_BIT),
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
      ),
      LabSubpassDependency(
        0,
        VK_SUBPASS_EXTERNAL,
        TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
        TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_ACCESS_MEMORY_READ_BIT),
        TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
      )
    ]
  );
  for i := 0 to SwapChain.ImageCount - 1 do
  begin
    RenderTargets[i].FrameBuffer := TLabFrameBuffer.Create(
      _BackBuffer.Ptr.Device, _RenderPass,
      SwapChain.Width, SwapChain.Height,
      [
        RenderTargets[i].Color.View.Ptr.VkHandle,
        RenderTargets[i].Depth.View.Ptr.VkHandle,
        RenderTargets[i].Normals.View.Ptr.VkHandle,
        RenderTargets[i].PhysParams.View.Ptr.VkHandle,
        RenderTargets[i].ZBuffer.Ptr.View.VkHandle
      ]
    );
  end;
  _OnUpdateRenderTargets.Call([Self]);
end;

constructor TDeferredBuffer.Create(
  const ABackBuffer: TBackBufferShared;
  const AUpdateRenderTargetsCallbacks: array of TLabDelegate.TCallback
);
begin
  _BackBuffer := ABackBuffer;
  _BackBuffer.Ptr.OnSwapChainCreate.Add(@UpdateRenderTargets);
  _OnUpdateRenderTargets.Add(AUpdateRenderTargetsCallbacks);
  UpdateRenderTargets([_BackBuffer.Ptr.SwapChain.Ptr]);
end;

destructor TDeferredBuffer.Destroy;
begin
  inherited Destroy;
end;

procedure TBackBuffer.SwapChainCreate;
  var i: TVkInt32;
begin
  if _SwapChain.IsValid then SwapChainDestroy;
  _SwapChain := TLabSwapChain.Create(_Device, _Surface);
  SetLength(_DepthBuffers, _SwapChain.Ptr.ImageCount);
  for i := 0 to _SwapChain.Ptr.ImageCount - 1 do
  begin
    _DepthBuffers[i] := TLabDepthBuffer.Create(_Device, _Window.Ptr.Width, _Window.Ptr.Height);
  end;
  _RenderPass := TLabRenderPass.Create(
    _Device,
    [
      LabAttachmentDescription(
        _SwapChain.Ptr.Format,
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
        _DepthBuffers[0].Ptr.Format,
        VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_LOAD,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_IMAGE_LAYOUT_UNDEFINED,
        0
      )
    ],
    [
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
  SetLength(_FrameBuffers, _SwapChain.Ptr.ImageCount);
  for i := 0 to _SwapChain.Ptr.ImageCount - 1 do
  begin
    _FrameBuffers[i] := TLabFrameBuffer.Create(
      _Device, _RenderPass,
      _SwapChain.Ptr.Width, _SwapChain.Ptr.Height,
      [
        _SwapChain.Ptr.Images[i]^.View.VkHandle,
        _DepthBuffers[i].Ptr.View.VkHandle
      ]
    );
  end;
  _OnSwapChainCreate.Call([_SwapChain.Ptr]);
end;

procedure TBackBuffer.SwapChainDestroy;
begin
  if not SwapChain.IsValid then Exit;
  _OnSwapChainDestroy.Call([_SwapChain.Ptr]);
  _FrameBuffers := nil;
  _DepthBuffers := nil;
  _RenderPass := nil;
  _SwapChain := nil;
end;

function TBackBuffer.GetFrameBuffer(const Index: TVkInt32): TLabFrameBufferShared;
begin
  Result := _FrameBuffers[Index];
end;

function TBackBuffer.GetDepthBuffer(const Index: TVkInt32): TLabDepthBufferShared;
begin
  Result := _DepthBuffers[Index];
end;

constructor TBackBuffer.Create(
  const AWindow: TLabWindowShared;
  const ADevice: TLabDeviceShared;
  const ASwapChainCreateCallbacks: array of TLabDelegate.TCallback;
  const ASwapChainDestroyCallbacks: array of TLabDelegate.TCallback;
  const AResizeCallbacks: array of TLabDelegate.TCallback
);
begin
  _Window := AWindow;
  _Device := ADevice;
  _Surface := TLabSurface.Create(_Window);
  _Semaphore := TLabSemaphore.Create(_Device);
  _OnSwapChainCreate.Add(ASwapChainCreateCallbacks);
  _OnSwapChainDestroy.Add(ASwapChainDestroyCallbacks);
  _OnResize.Add(AResizeCallbacks);
  SwapChainCreate;
end;

destructor TBackBuffer.Destroy;
begin
  SwapChainDestroy;
  inherited Destroy;
end;

function TBackBuffer.FrameStart: Boolean;
  procedure ResetSwapChain;
  begin
    _Device.Ptr.WaitIdle;
    SwapchainDestroy;
    SwapchainCreate;
    //OnBindOffscreenTargets.Call([]);
    //ScreenQuad.Ptr.Resize(Cmd.Ptr);
    _OnResize.Call([_SwapChain.Ptr.Width, _SwapChain.Ptr.Height]);
  end;
  var r: TVkResult;
begin
  if not TLabVulkan.IsActive
  or (_Window.Ptr.Mode = wm_minimized)
  or (_Window.Ptr.Width * _Window.Ptr.Height = 0) then Exit(False);
  if (_SwapChain.Ptr.Width <> _Window.Ptr.Width)
  or (_SwapChain.Ptr.Height <> _Window.Ptr.Height) then
  begin
    ResetSwapChain;
  end;
  r := SwapChain.Ptr.AcquireNextImage(_Semaphore);
  if r = VK_ERROR_OUT_OF_DATE_KHR then
  begin
    LabLogVkError(r);
    ResetSwapChain;
    Exit(False);
  end
  else
  begin
    LabAssertVkError(r);
  end;
  Result := True;
end;

procedure TBackBuffer.FramePresent(const WaitSemaphores: array of TVkSemaphore);
begin
  TLabVulkan.QueuePresent(_SwapChain.Ptr.QueueFamilyPresent, [_SwapChain.Ptr.VkHandle], [_SwapChain.Ptr.CurImage], WaitSemaphores);
end;

procedure TTexture.Stage(const Args: array of const);
  var Cmd: TLabCommandBuffer;
  var mip_src_width, mip_src_height, mip_dst_width, mip_dst_height: TVkUInt32;
  var i: TVkInt32;
begin
  Cmd := TLabCommandBuffer(Args[0].VObject);
  Cmd.PipelineBarrier(
    TVkFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
    TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
    0, [], [],
    [
      LabImageMemoryBarrier(
        Image.Ptr.VkHandle,
        VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        0, TVkFlags(VK_ACCESS_TRANSFER_WRITE_BIT),
        VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0, MipLevels
      )
    ]
  );
  Cmd.CopyBufferToImage(
    Staging.Ptr.VkHandle,
    Image.Ptr.VkHandle,
    VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    [
      LabBufferImageCopy(
        LabOffset3D(0, 0, 0),
        LabExtent3D(Image.Ptr.Width, Image.Ptr.Height, Image.Ptr.Depth),
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), 0
      )
    ]
  );
  mip_src_width := Image.Ptr.Width;
  mip_src_height := Image.Ptr.Height;
  for i := 0 to MipLevels - 2 do
  begin
    mip_dst_width := mip_src_width shr 1; if mip_dst_width <= 0 then mip_dst_width := 1;
    mip_dst_height := mip_src_height shr 1; if mip_dst_height <= 0 then mip_dst_height := 1;
    Cmd.PipelineBarrier(
      TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
      TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
      0, [], [],
      [
        LabImageMemoryBarrier(
          Image.Ptr.VkHandle,
          VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
          TVkFlags(VK_ACCESS_TRANSFER_WRITE_BIT), TVkFlags(VK_ACCESS_TRANSFER_READ_BIT),
          VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i)
        )
      ]
    );
    Cmd.BlitImage(
      Image.Ptr.VkHandle,
      VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
      Image.Ptr.VkHandle,
      VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
      [
        LabImageBlit(
          LabOffset3D(0, 0, 0), LabOffset3D(mip_src_width, mip_src_height, 1),
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i), 0, 1,
          LabOffset3D(0, 0, 0), LabOffset3D(mip_dst_width, mip_dst_height, 1),
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i + 1), 0, 1
        )
      ]
    );
    Cmd.PipelineBarrier(
      TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
      TVkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
      0, [], [],
      [
        LabImageMemoryBarrier(
          Image.Ptr.VkHandle,
          VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          TVkFlags(VK_ACCESS_TRANSFER_READ_BIT), TVkFlags(VK_ACCESS_SHADER_READ_BIT),
          VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
          TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), TVkUInt32(i)
        )
      ]
    );
    mip_src_width := mip_dst_width;
    mip_src_height := mip_dst_height;
  end;
  Cmd.PipelineBarrier(
    TVkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
    TVkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
    0, [], [],
    [
      LabImageMemoryBarrier(
        Image.Ptr.VkHandle,
        VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        TVkFlags(VK_ACCESS_TRANSFER_READ_BIT), TVkFlags(VK_ACCESS_SHADER_READ_BIT),
        VK_QUEUE_FAMILY_IGNORED, VK_QUEUE_FAMILY_IGNORED,
        TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), MipLevels - 1
      )
    ]
  );
end;

{$Push}{$Hints off}
procedure TTexture.StageComplete(const Args: array of const);
begin
  Staging := nil;
end;
{$Pop}

constructor TTexture.Create(const FileName: String; const FilterLinear: Boolean = True; const UseMipMaps: Boolean = True);
  var img: TLabImageDataPNG;
begin
  img := TLabImageDataPNG.Create;
  img.Load('../Images/' + FileName);
  Create(img, FilterLinear, UseMipMaps);
  img.Free;
end;

constructor TTexture.Create(const ImageData: TLabImageData; const FilterLinear: Boolean = True; const UseMipMaps: Boolean = True);
  var map: PVkVoid;
  var c: PLabColor;
  var x, y: TVkInt32;
  var Filter: TVkFilter;
  var MipMapMode: TVkSamplerMipmapMode;
  var AnisotropyEnabled: TVkBool32;
  var MaxAnisotropy: TVkFloat;
begin
  if UseMipMaps then
  begin
    MipLevels := LabIntLog2(LabMakePOT(LabMax(ImageData.Width, ImageData.Height))) + 1;
    MipMapMode := VK_SAMPLER_MIPMAP_MODE_LINEAR;
  end
  else
  begin
    MipLevels := 1;
    MipMapMode := VK_SAMPLER_MIPMAP_MODE_NEAREST;
  end;
  if FilterLinear then
  begin
    Filter := VK_FILTER_LINEAR;
    AnisotropyEnabled := VK_TRUE;
    MaxAnisotropy := 16;
  end
  else
  begin
    Filter := VK_FILTER_NEAREST;
    AnisotropyEnabled := VK_FALSE;
    MaxAnisotropy := 1;
  end;
  Alpha := False;
  for y := 0 to ImageData.Height - 1 do
  for x := 0 to ImageData.Width - 1 do
  if ImageData.Pixels[x, y].a < $ff then
  begin
    Alpha := True;
    Break;
  end;
  Image := TLabImage.Create(
    App.Device,
    VK_FORMAT_R8G8B8A8_UNORM,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    [], ImageData.Width, ImageData.Height, 1, MipLevels, 1, VK_SAMPLE_COUNT_1_BIT,
    VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  Staging := TLabBuffer.Create(
    App.Device, Image.Ptr.DataSize,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT), [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
  );
  map := nil;
  if (Staging.Ptr.Map(map)) then
  begin
    if ImageData.Format = idf_r8g8b8a8 then
    begin
      Move(ImageData.Data^, map^, ImageData.DataSize);
    end
    else
    begin
      c := PLabColor(map);
      for y := 0 to ImageData.Height - 1 do
      for x := 0 to ImageData.Width - 1 do
      begin
        c^ := ImageData.Pixels[x, y];
        Inc(c);
      end;
    end;
    Staging.Ptr.Unmap;
  end;
  View := TLabImageView.Create(
    App.Device, Image.Ptr.VkHandle, Image.Ptr.Format,
    TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
    0, MipLevels
  );
  Sampler := TLabSampler.Create(
    App.Device, Filter, Filter,
    VK_SAMPLER_ADDRESS_MODE_REPEAT, VK_SAMPLER_ADDRESS_MODE_REPEAT, VK_SAMPLER_ADDRESS_MODE_REPEAT,
    AnisotropyEnabled, MaxAnisotropy, MipMapMode, 0, 0, MipLevels - 1
  );
  App.OnStage.Add(@Stage);
  App.OnStageComplete.Add(@StageComplete);
end;

destructor TTexture.Destroy;
begin
  App.OnStage.Remove(@Stage);
  App.OnStageComplete.Remove(@StageComplete);
  inherited Destroy;
end;

procedure TRenderTarget.SetupImage(
  const Width: TVkUInt32;
  const Height: TVkUInt32;
  const Format: TVkFormat;
  const Usage: TVkImageUsageFlags;
  const SampleCount: TVkSampleCountFlagBits
);
begin
  Image := TLabImage.Create(
    App.Device, Format, Usage or TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT), [],
    Width, Height, 1, 1, 1, SampleCount, VK_IMAGE_TILING_OPTIMAL,
    VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE, TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  View := TLabImageView.Create(
    App.Device, Image.Ptr.VkHandle,
    Image.Ptr.Format
  );
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

{$Push}{$Hints off}
procedure TLabApp.UpdateRenderTargets(const Params: array of const);
begin
  OnBindOffscreenTargets.Call([]);
end;
{$Pop}

procedure TLabApp.UpdateTransforms;
  var fov: TVkFloat;
  var Transforms: TTransforms;
begin
  fov := LabDegToRad * 45;
  with Transforms do
  begin
    Projection := LabMatProj(fov, Window.Ptr.Width / Window.Ptr.Height, 1, 100);
    View := LabMatView(LabVec3(0, 4, -4), LabVec3, LabVec3(0, 1, 0));
    World := LabMatIdentity; //LabMatRotationY((LabTimeLoopSec(15) / 15) * Pi * 2);
    Clip := LabMat(
      1, 0, 0, 0,
      0, -1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    );
    WVP := World * View * Projection * Clip;
  end;
  OnUpdateTransforms.Call([@Transforms]);
end;

procedure TLabApp.TransferBuffers;
begin
  Cmd.Ptr.RecordBegin;
  OnStage.Call([Cmd.Ptr]);
  OnStage.Clear;
  Cmd.Ptr.RecordEnd;
  QueueSubmit(
    BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics,
    [Cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE
  );
  QueueWaitIdle(BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics);
  OnStageComplete.Call([]);
  OnStageComplete.Clear;
end;

procedure TLabApp.Initialize;
begin
  Window := TLabWindow.Create(500, 500);
  Window.Ptr.Caption := 'Vulkan Scene';
  Device := TLabDevice.Create(
    PhysicalDevices[0],
    [
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT))),
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_COMPUTE_BIT)))
    ],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  SampleCount := VK_SAMPLE_COUNT_1_BIT;
  DescriptorSetsFactory := TLabDescriptorSetsFactory.Create(Device);
  BackBuffer := TBackBuffer.Create(Window, Device, [], [], []);
  DeferredBuffer := TDeferredBuffer.Create(BackBuffer, [@UpdateRenderTargets]);
  CmdPool := TLabCommandPool.Create(Device, BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyIndexGraphics);
  Cmd := TLabCommandBuffer.Create(CmdPool);
  PipelineCache := TLabPipelineCache.Create(Device);
  Scene := TScene.Create;
  Light := TLight.Create;
  Fence := TLabFence.Create(Device);
  TransferBuffers;
  OnBindOffscreenTargets.Call([]);
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  Scene := nil;
  Light := nil;
  DeferredBuffer := nil;
  BackBuffer := nil;
  Cmd := nil;
  CmdPool := nil;
  PipelineCache := nil;
  DescriptorSetsFactory := nil;
  Fence := nil;
  Device := nil;
  Window := nil;
  Free;
end;

procedure TLabApp.Loop;
  var cur_buffer: TVkUInt32;
begin
  TLabVulkan.IsActive := Window.Ptr.IsActive;
  UpdateTransforms;
  if not BackBuffer.Ptr.FrameStart then Exit;
  cur_buffer := BackBuffer.Ptr.SwapChain.Ptr.CurImage;
  if OnStage.CallbackCount > 0 then
  begin
    TransferBuffers;
  end;
  Cmd.Ptr.RecordBegin();
  Cmd.Ptr.SetViewport([LabViewport(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  Cmd.Ptr.SetScissor([LabRect2D(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  Cmd.Ptr.BeginRenderPass(
    DeferredBuffer.Ptr.RenderPass.Ptr, DeferredBuffer.Ptr.RenderTargets[cur_buffer].FrameBuffer.Ptr,
    [LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(1, 0), LabClearValue(0, 0, 0, 0), LabClearValue(0, 0, 0, 0), LabClearValue(1.0, 0)]
  );
  DrawScene;
  Cmd.Ptr.EndRenderPass;
  Cmd.Ptr.BeginRenderPass(
    BackBuffer.Ptr.RenderPass.Ptr, BackBuffer.Ptr.FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.0, 0.0, 0.0, 1.0), LabClearValue(1.0, 0)]
  );
  DrawLights;
  Cmd.Ptr.EndRenderPass;
  Cmd.Ptr.RecordEnd;
  QueueSubmit(
    BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics,
    [Cmd.Ptr.VkHandle],
    [BackBuffer.Ptr.ImageAquireSemaphore.Ptr.VkHandle],
    [],
    Fence.Ptr.VkHandle,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  Fence.Ptr.WaitFor;
  Fence.Ptr.Reset;
  BackBuffer.Ptr.FramePresent([]);
end;

procedure TLabApp.DrawScene;
begin
  Scene.Ptr.Draw(Cmd.Ptr);
end;

procedure TLabApp.DrawLights;
begin
  Light.Ptr.Draw(Cmd.Ptr);
end;

end.
