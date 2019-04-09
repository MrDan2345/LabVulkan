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
  LabTextures,
  Classes,
  SysUtils,
  Math;

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

  TLightData = class (TLabClass)
    type TUniformVertex = packed record
      VP: TLabMat;
    end;
    type PUniformVertex = ^TUniformVertex;
    type TUniformBufferVertex = specialize TLabUniformBuffer<TUniformVertex>;
    type TUniformBufferVertexShared = specialize TLabSharedRef<TUniformBufferVertex>;
    type TUniformPixel = packed record
      VP_i: TLabMat;
      rt_ratio: TLabVec4;
      camera_pos: TLabVec4;
    end;
    type PUniformPixel = ^TUniformPixel;
    type TUniformBufferPixel = specialize TLabUniformBuffer<TUniformPixel>;
    type TUniformBufferPixelShared = specialize TLabSharedRef<TUniformBufferPixel>;
    type TLightVertex = packed record
      x, y, z, w: TVkFloat;
    end;
    type TLightInstance = packed record
      pos: TLabVec4;
      color: TLabVec4;
      vel: TLabVec4;
    end;
    type TLightInstanceArr = array[Word] of TLightInstance;
    type PLightInstanceArr = ^TLightInstanceArr;
    const light_vertices: array[0..5] of TLightVertex = (
      (x:0; y:1; z:0; w:1), (x:1; y:0; z:0; w:1), (x:0; y:0; z:1; w:1), (x:-1; y:0; z:0; w:1), (x:0; y:0; z:-1; w:1), (x:0; y:-1; z:0; w:1)
    );
    const light_indices: array[0..23] of TVkUInt16 = (
      0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1,
      1, 4, 5, 4, 3, 5, 3, 2, 5, 2, 1, 5
    );
    type TComputeTask = class
      type TComputeUniforms = packed record
        bounds_min: TLabVec4;
        bounds_max: TLabVec4;
        box_x: TLabVec4;
        box_y: TLabVec4;
        box_z: TLabVec4;
      end;
      type PComputeUniforms = ^TComputeUniforms;
      type TUniformBufferCompute = specialize TLabUniformBuffer<TComputeUniforms>;
      type TUnifromBufferComputeShared = specialize TLabSharedRef<TUniformBufferCompute>;
      var ComputeShader: TLabComputeShaderShared;
      var UniformBuffer: TUnifromBufferComputeShared;
      var DescriptorSets: TLabDescriptorSetsShared;
      var PipelineLayout: TLabPipelineLayoutShared;
      var Pipeline: TLabPipelineShared;
      var Uniforms: PComputeUniforms;
      var Cmd: TLabCommandBufferShared;
      var Fence: TLabFenceShared;
      constructor Create(const StorageBuffer: TLabBuffer; const InstanceCount: TVkUInt32);
      destructor Destroy; override;
      procedure Run;
    end;
    var InstanceCount: TVkUInt32;
    var VertexBuffer: TLabVertexBufferShared;
    var VertexStaging: TLabBufferShared;
    var IndexBuffer: TLabIndexBufferShared;
    var IndexStaging: TLabIndexBufferShared;
    var InstanceBuffer: TLabVertexBufferShared;
    var InstanceStaging: TLabBufferShared;
    var VertexShader: TLabVertexShaderShared;
    var TessControlShader: TLabTessControlShaderShared;
    var TessEvalShader: TLabTessEvaluationShaderShared;
    var PixelShader: TLabPixelShaderShared;
    var Sampler: TLabSamplerShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var UniformBufferVertex: TUniformBufferVertexShared;
    var UniformBufferPixel: TUniformBufferPixelShared;
    var UniformsVertex: PUniformVertex;
    var UniformsPixel: PUniformPixel;
    var ComputeTask: TComputeTask;
    constructor Create;
    destructor Destroy; override;
    procedure Stage(const Args: array of const);
    procedure UpdateTransforms(const Args: array of const);
    procedure BindOffscreenTargets(const Args: array of const);
    procedure Draw(const Cmd: TLabCommandBuffer; const ImageIndex: TVkUInt32);
  end;
  TLightDataShared = specialize TLabSharedRef<TLightData>;

  TIBLight = class (TLabClass)
  private
    type TUniformData = packed record
      vp_i: TLabMat;
      screen_ratio: TLabVec4;
      camera_pos: TLabVec4;
      exposure: TVkFloat;
      gamma: TVkFloat;
    end;
    type PUniformData = ^TUniformData;
    type TUniformBuffer = specialize TLabUniformBuffer<TUniformData>;
    type TUniformBufferShared = specialize TLabSharedRef<TUniformBuffer>;
    var UniformBuffer: TUniformBufferShared;
    var UniformData: PUniformData;
    var VertexShader: TLabVertexShaderShared;
    var PixelShader: TLabPixelShaderShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var TextureEnv: TLabTextureCubeShared;
    var TextureIrradiance: TLabTextureCubeShared;
    var TexturePrefiltered: TLabTextureCubeShared;
    var TextureBRDFLUT: TLabTexture2DShared;
    procedure Resize(const Params: array of const);
    procedure LoadEnvMap;
    procedure GenerateIrradianceMap;
    procedure GeneratePrefilteredMap;
    procedure GenerateBRDFLUT;
  public
    constructor Create;
    destructor Destroy; override;
    procedure UpdateTransforms(const Params: array of const);
    procedure BindOffscreenTargets(const Params: array of const);
    procedure Draw(const Cmd: TLabCommandBuffer);
  end;
  TIBLightShared = specialize TLabSharedRef<TIBLight>;

  TPostProcessSSAO = class (TLabClass)
  private
    type TUniformOcclusionSamples = packed record
      ScreenRatio: TLabVec4;
      V: TLabMat;
      P: TLabMat;
      P_i: TLabMat;
      Samples: array[0..63] of TLabVec4;
      RandomVectors: array[0..63] of TLabVec4;
    end;
    type TUniformBufferOcclusionSamples = specialize TLabUniformBuffer<TUniformOcclusionSamples>;
    type TUniformBufferOcclusionSamplesShared = specialize TLabSharedRef<TUniformBufferOcclusionSamples>;
    var ScreenVS: TLabVertexShaderShared;
    var OcclusionPS: TLabPixelShaderShared;
    var RenderTarget: TRenderTarget;
    var RenderPass: TLabRenderPassShared;
    var FrameBuffer: TLabFrameBufferShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var UniformBufferOcclusionSamples: TUniformBufferOcclusionSamplesShared;
    procedure Resize(const Params: array of const);
    procedure GenerateOcclusionSamples;
  public
    constructor Create;
    destructor Destroy; override;
    procedure UpdateTransforms(const Params: array of const);
    procedure BindOffscreenTargets(const Params: array of const);
    procedure Draw(const Cmd: TLabCommandBuffer);
  end;
  TPostProcessSSAOShared = specialize TLabSharedRef<TPostProcessSSAO>;

  TScene = class (TLabClass)
  public
    type TUniformGlobal = packed record
      time: TLabVec4;
    end;
    type TUniformBufferGlobal = specialize TLabUniformBuffer<TUniformGlobal>;
    type TUniformBufferGlobalShared = specialize TLabSharedRef<TUniformBufferGlobal>;
    type TUnifromView = packed record
      v: TLabMat;
      p: TLabMat;
      vp: TLabMat;
      vp_i: TLabMat;
    end;
    type TUniformBufferView = specialize TLabUniformBuffer<TUnifromView>;
    type TUniformBufferViewShared = specialize TLabSharedRef<TUniformBufferView>;
    type TUniformInstance = packed record
      w: TLabMat;
    end;
    type TUniformBufferInstance = specialize TLabUniformBufferDynamic<TUniformInstance>;
    type TUniformBufferInstanceShared = specialize TLabSharedRef<TUniformBufferInstance>;
    type TNodeData = class (TLabClass)
    private
      var _Node: TLabSceneNode;
    public
      var UniformOffset: TVkInt32;
      constructor Create(const Node: TLabSceneNode);
      destructor Destroy; override;
    end;
    type TGeometrySubsetData = class (TLabClass)
    private
      var _Subset: TLabSceneGeometry.TSubset;
      var VertexBufferStaging: TLabBuffer;
      var IndexBufferStaging: TLabBuffer;
      procedure Stage(const Params: array of const);
      procedure StageComplete(const Params: array of const);
    public
      var VertexBuffer: TLabVertexBuffer;
      var IndexBuffer: TLabIndexBuffer;
      constructor Create(const Subset: TLabSceneGeometry.TSubset);
      destructor Destroy; override;
    end;
    type TSkinSubsetData = class (TLabClass)
    private
      var _Subset: TLabSceneControllerSkin.TSubset;
      var VertexBufferStaging: TLabBuffer;
      procedure Stage(const Params: array of const);
      procedure StageComplete(const Params: array of const);
    public
      var VertexBuffer: TLabVertexBuffer;
      constructor Create(const Subset: TLabSceneControllerSkin.TSubset);
      destructor Destroy; override;
    end;
    TInstanceData = class (TLabClass)
    public
      type TPass = class
      public
        var GeomSubset: TLabSceneGeometry.TSubset;
        var SkinSubset: TLabSceneControllerSkin.TSubset;
        var Material: TLabSceneMaterial;
        var Shader: TLabSceneShaderShared;
        var PipelineLayout: TLabPipelineLayoutShared;
        var Images: array of TTexture;
        var Pipeline: TLabPipelineShared;
      end;
      type TPassList = specialize TLabList<TPass>;
      type TUniformJoint = specialize TLabUniformBuffer<TLabMat>;
    private
      var _Scene: TScene;
      var _Attachment: TLabSceneNodeAttachment;
      procedure SetupRenderPasses(
        const Geom: TLabSceneGeometry;
        const Skin: TLabSceneControllerSkin;
        const MaterialBindings: TLabSceneMaterialBindingList
      );
    public
      var Passes: TPassList;
      var JointUniformBuffer: TUniformJoint;
      var JointUniforms: PLabMatArr;
      var Joints: TLabSceneNodeList;
      procedure UpdateSkinTransforms(const Params: array of const);
      constructor Create(const AScene: TScene; const Attachment: TLabSceneNodeAttachmentGeometry);
      constructor Create(const AScene: TScene; const Attachment: TLabSceneNodeAttachmentController);
      destructor Destroy; override;
    end;
  private
    var Scene: TLabScene;
    var UniformBufferGlobal: TUniformBufferGlobalShared;
    var UniformBufferView: TUniformBufferViewShared;
    var UniformBufferInstance: TUniformBufferInstanceShared;
    procedure ProcessScene;
    procedure UpdateTransforms(const Params: array of const);
    function GetUniformBufferOffsetAlignment(const BufferSize: TVkDeviceSize): TVkDeviceSize;
  public
    var CameraInst: TLabSceneNodeAttachmentCamera;
    constructor Create;
    destructor Destroy; override;
    procedure Draw(const Cmd: TLabCommandBuffer);
  end;
  TSceneShared = specialize TLabSharedRef<TScene>;

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
      Material: TRenderTarget;
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

  TLabApp = class (TLabVulkan)
  public
    var Window: TLabWindowShared;
    var Device: TLabDeviceShared;
    var CmdPool: TLabCommandPoolShared;
    var CmdPoolCompute: TLabCommandPoolShared;
    var Cmd: TLabCommandBufferShared;
    var Fence: TLabFenceShared;
    var BackBuffer: TBackBufferShared;
    var DeferredBuffer: TDeferredBufferShared;
    var DescriptorSetsFactory: TLabDescriptorSetsFactoryShared;
    var PipelineCache: TLabPipelineCacheShared;
    var Scene: TSceneShared;
    //var LightData: TLightDataShared;
    var SSAO: TPostProcessSSAOShared;
    var Lighting: TIBLightShared;
    var DitherMask: TTextureShared;
    var SampleCount: TVkSampleCountFlagBits;
    var OnStage: TLabDelegate;
    var OnStageComplete: TLabDelegate;
    var OnUpdateTransforms: TLabDelegate;
    var OnBindOffscreenTargets: TLabDelegate;
    constructor Create;
    procedure UpdateRenderTargets(const Params: array of const);
    procedure UpdateTransforms;
    procedure TransferBuffers;
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
  end;

const
  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

var
  App: TLabApp;

implementation

procedure TPostProcessSSAO.Resize(const Params: array of const);
  var SwapChain: TLabSwapChain;
  var w, h: TVkUInt32;
begin
  SwapChain := TLabSwapChain(Params[0].VPointer);
  UniformBufferOcclusionSamples.Ptr.Buffer^.ScreenRatio := LabVec4(
    SwapChain.Width, SwapChain.Height, 1 / SwapChain.Width, 1 / SwapChain.Height
  );
  w := LabMakePOT(LabMax(SwapChain.Width, 1));
  h := LabMakePOT(LabMax(SwapChain.Height, 1));
  RenderTarget.SetupImage(
    w, h, VK_FORMAT_R8G8B8A8_UNORM,
    TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
    VK_SAMPLE_COUNT_1_BIT
  );
  RenderPass := TLabRenderPass.Create(
    App.Device,
    [
      LabAttachmentDescription(
        VK_FORMAT_R8G8B8A8_UNORM, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_STORE
      )
    ],
    LabSubpassDescriptionData(
      [],
      [
        LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
      ],
      [],
      LabAttachmentReferenceInvalid,
      []
    ),
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
  FrameBuffer := TLabFrameBuffer.Create(
    App.Device, RenderPass,
    SwapChain.Width, SwapChain.Height,
    [
      RenderTarget.View.Ptr.VkHandle
    ]
  );
end;

procedure TPostProcessSSAO.GenerateOcclusionSamples;
  var i: Integer;
  var vec: TLabVec3;
  var s: Single;
begin
  Randomize;
  with UniformBufferOcclusionSamples.Ptr.Buffer^ do
  begin
    for i := 0 to High(Samples) do
    begin
      vec := LabRandomSpherePoint;
      vec.z := Abs(vec.z);
      s := i / High(Samples);
      vec := vec * LabLerpFloat(0.1, 1, s * s);
      Samples[i] := LabVec4(vec, 0);
    end;
    for i := 0 to High(RandomVectors) do
    begin
      RandomVectors[i] := LabVec4(LabRandomCirclePoint, LabRandomCirclePoint);
    end;
  end;
end;

constructor TPostProcessSSAO.Create;
begin
  App.OnBindOffscreenTargets.Add(@BindOffscreenTargets);
  App.OnUpdateTransforms.Add(@UpdateTransforms);
  App.BackBuffer.Ptr.OnSwapChainCreate.Add(@Resize);
  ScreenVS := TLabVertexShader.Create(App.Device, 'screen_vs.spv');
  OcclusionPS := TLabPixelShader.Create(App.Device, 'ssao_ps.spv');
  UniformBufferOcclusionSamples := TUniformBufferOcclusionSamples.Create(App.Device);
  GenerateOcclusionSamples;
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request(
    [
      LabDescriptorSetBindings(
        [
          LabDescriptorBinding(
            0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
          ),
          LabDescriptorBinding(
            1, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
          ),
          LabDescriptorBinding(
            2, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
          )
        ],
        App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount
      )
    ]
  );
  Resize([App.BackBuffer.Ptr.SwapChain.Ptr]);
  PipelineLayout := TLabPipelineLayout.Create(
    App.Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]
  );
  Pipeline := TLabGraphicsPipeline.FindOrCreate(
    App.Device, App.PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [LabShaderStage(ScreenVS.Ptr), LabShaderStage(OcclusionPS.Ptr)],
    RenderPass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment], []),
    LabPipelineTesselationState(0)
  );
end;

destructor TPostProcessSSAO.Destroy;
begin
  if App.BackBuffer.IsValid then App.BackBuffer.Ptr.OnSwapChainCreate.Remove(@Resize);
  App.OnUpdateTransforms.Remove(@UpdateTransforms);
  App.OnBindOffscreenTargets.Remove(@BindOffscreenTargets);
  inherited Destroy;
end;

procedure TPostProcessSSAO.UpdateTransforms(const Params: array of const);
  var xf: PTransforms;
begin
  xf := PTransforms(Params[0].VPointer);
  with UniformBufferOcclusionSamples.Ptr.Buffer^ do
  begin
    V := xf^.View;
    P := xf^.Projection * xf^.Clip;
    P_i := (xf^.Projection * xf^.Clip).Inverse;
  end;
end;

procedure TPostProcessSSAO.BindOffscreenTargets(const Params: array of const);
  var i: TVkInt32;
  var Writes: array of TLabWriteDescriptorSet;
  const binding_count = 3;
begin
  SetLength(Writes, App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount * binding_count);
  for i := 0 to App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount - 1 do
  begin
    Writes[i * binding_count + 0] := LabWriteDescriptorSetUniformBuffer(
      DescriptorSets.Ptr.VkHandle[i],
      0,
      [
        LabDescriptorBufferInfo(
          UniformBufferOcclusionSamples.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 1] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      1,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Depth.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 2] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      2,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Normals.View.Ptr.VkHandle
        )
      ]
    );
  end;
  DescriptorSets.Ptr.UpdateSets(Writes, []);
end;

procedure TPostProcessSSAO.Draw(const Cmd: TLabCommandBuffer);
begin
  Cmd.BeginRenderPass(
    RenderPass.Ptr, FrameBuffer.Ptr,
    [LabClearValue(1, 1, 1, 1)]
  );
  Cmd.SetScissor([LabRect2D(0, 0, App.BackBuffer.Ptr.SwapChain.Ptr.Width, App.BackBuffer.Ptr.SwapChain.Ptr.Height)]);
  Cmd.SetViewport([LabViewport(0, 0, App.BackBuffer.Ptr.SwapChain.Ptr.Width, App.BackBuffer.Ptr.SwapChain.Ptr.Height)]);
  Cmd.BindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS, PipelineLayout.Ptr, 0, [DescriptorSets.Ptr.VkHandle[0]], []);
  Cmd.BindPipeline(Pipeline.Ptr);
  Cmd.Draw(3);
  Cmd.EndRenderPass;
end;

procedure TScene.TInstanceData.SetupRenderPasses(
  const Geom: TLabSceneGeometry;
  const Skin: TLabSceneControllerSkin;
  const MaterialBindings: TLabSceneMaterialBindingList
);
  var pc: TVkInt32;
  var Pass: TPass;
  var Params: TLabSceneShaderParameters;
  procedure AddParamImage(const Image: TTexture; const Semantics: TLabSceneShaderParameterSemanticSet);
  begin
    SetLength(Pass.Images, Length(Pass.Images) + 1);
    Pass.Images[High(Pass.Images)] := Image;
    Params[pc] := LabSceneShaderParameterImage(
      Image.View.Ptr.VkHandle,
      Image.Sampler.Ptr.VkHandle,
      Semantics,
      TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
    );
    Inc(pc);
  end;
  var i, j: TVkInt32;
  var r_s: TLabSceneGeometry.TSubset;
  var Image: TTexture;
  var SkinInfo: TLabSceneShaderSkinInfo;
  var DeferredInfo: TLabSceneShaderDeferredInfo;
  var si_ptr: PLabSceneShaderSkinInfo;
  var sem: TLabSceneShaderParameterSemanticSet;
  var tex_name: String;
begin
  if Assigned(Skin) then
  begin
    si_ptr := @SkinInfo;
    SkinInfo.JointCount := Length(Skin.Joints);
    SkinInfo.MaxJointWeights := Skin.MaxWeightCount;
  end
  else
  begin
    si_ptr := nil;
  end;
  DeferredInfo.ColorOutput := 0;
  DeferredInfo.DepthOutput := 1;
  DeferredInfo.NormalsOutlput := 2;
  DeferredInfo.MaterialOutput := 3;
  for i := 0 to Geom.Subsets.Count - 1 do
  begin
    r_s := Geom.Subsets[i];
    Pass := TPass.Create;
    pc := 3;//uniform buffers;
    pc += 1;//dither mask
    if Assigned(Skin) then Inc(pc);
    for j := 0 to MaterialBindings.Count - 1 do
    if r_s.Material = MaterialBindings[j].Symbol then
    begin
      Pass.Material := MaterialBindings[j].Material;
      Break;
    end;
    if Assigned(Pass.Material) then
    begin
      for j := 0 to Pass.Material.Effect.Params.Count - 1 do
      if Pass.Material.Effect.Params[j].ParameterType = pt_sampler then
      begin
        Inc(pc);
      end;
    end;
    SetLength(Params, pc);
    pc := 0;
    Params[pc] := LabSceneShaderParameterUniform(
      _Scene.UniformBufferGlobal.Ptr.VkHandle, [], TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
    );
    Inc(pc);
    Params[pc] := LabSceneShaderParameterUniform(
      _Scene.UniformBufferView.Ptr.VkHandle, [], TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
    );
    Inc(pc);
    Params[pc] := LabSceneShaderParameterUniformDynamic(
      _Scene.UniformBufferInstance.Ptr.VkHandle, [], TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
    );
    Inc(pc);
    if Assigned(Skin) then
    begin
      Params[pc] := LabSceneShaderParameterUniform(
        JointUniformBuffer.VkHandle, [], TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
      );
      Inc(pc);
    end;
    if Assigned(Pass.Material) then
    begin
      for j := 0 to Pass.Material.Effect.Params.Count - 1 do
      if Pass.Material.Effect.Params[j].ParameterType = pt_sampler then
      begin
        sem := [];
        tex_name := Pass.Material.Effect.Params[j].Name;
        if Pos('_c_', tex_name) > 0 then sem += [sps_color_map];
        if Pos('_n_', tex_name) > 0 then sem += [sps_normal_map];
        if Pos('_m_', tex_name) > 0 then sem += [sps_material_map];
        Image := TTexture(TLabSceneEffectParameterSampler(Pass.Material.Effect.Params[j]).Image.UserData);
        AddParamImage(Image, sem);
      end;
    end;
    AddParamImage(App.DitherMask.Ptr, [sps_dither_mask]);
    Pass.GeomSubset := r_s;
    if Assigned(Skin) then
    begin
      Pass.SkinSubset := Skin.Subsets[i];
    end
    else
    begin
      Pass.SkinSubset := nil;
    end;
    Pass.Shader := TLabSceneShaderFactory.MakeShader(App.Device, r_s.VertexDescriptor, Params, si_ptr, @DeferredInfo);
    Pass.PipelineLayout := TLabPipelineLayout.Create(App.Device, [], [Pass.Shader.Ptr.DescriptorSetLayout.Ptr]);
    Passes.Add(Pass);
  end;
end;

{$Push}{$Hints off}
procedure TScene.TInstanceData.UpdateSkinTransforms(const Params: array of const);
  var Skin: TLabSceneControllerSkin;
  var i: TVkInt32;
  var m: TLabMat;
begin
  if not (_Attachment is TLabSceneNodeAttachmentController)
  or not (TLabSceneNodeAttachmentController(_Attachment).Controller is TLabSceneControllerSkin) then Exit;
  Skin := TLabSceneControllerSkin(TLabSceneNodeAttachmentController(_Attachment).Controller);
  for i := 0 to Joints.Count - 1 do
  begin
    m := Joints[i].Transform;//CombinedTransform(Joints[i]);
    m := (Skin.BindShapeMatrix * Skin.Joints[i].BindPose) * m;
    JointUniforms^[i] := m;
  end;
end;
{$Pop}

constructor TScene.TInstanceData.Create(const AScene: TScene; const Attachment: TLabSceneNodeAttachmentGeometry);
begin
  _Scene := AScene;
  _Attachment := Attachment;
  Passes := TPassList.Create;
  SetupRenderPasses(Attachment.Geometry, nil, Attachment.MaterialBindings);
end;

constructor TScene.TInstanceData.Create(const AScene: TScene; const Attachment: TLabSceneNodeAttachmentController);
  var Skin: TLabSceneControllerSkin;
  var i: TVkInt32;
begin
  _Scene := AScene;
  _Attachment := Attachment;
  Passes := TPassList.Create;
  if not (Attachment.Controller is TLabSceneControllerSkin) then Exit;
  Skin := TLabSceneControllerSkin(Attachment.Controller);
  JointUniformBuffer := TUniformJoint.Create(App.Device, Length(Skin.Joints));
  JointUniforms := PLabMatArr(JointUniformBuffer.Buffer);
  Joints := TLabSceneNodeList.Create;
  Joints.Allocate(Length(Skin.Joints));
  for i := 0 to Joints.Count - 1 do
  begin
    Joints[i] := Attachment.Skeleton.FindBySID(Skin.Joints[i].JointName);
    if not Assigned(Joints[i]) then
    begin
      Joints[i] := Attachment.Skeleton.FindByID(Skin.Joints[i].JointName);
      if not Assigned(Joints[i]) then
      begin
        Joints[i] := Attachment.Skeleton.FindByName(Skin.Joints[i].JointName);
      end;
    end;
    JointUniforms^[i] := LabMatIdentity;
  end;
  SetupRenderPasses(Skin.Geometry, Skin, Attachment.MaterialBindings);
  App.OnUpdateTransforms.Add(@UpdateSkinTransforms);
end;

destructor TScene.TInstanceData.Destroy;
begin
  App.OnUpdateTransforms.Remove(@UpdateSkinTransforms);
  FreeAndNil(Joints);
  if Assigned(JointUniformBuffer) then
  begin
    JointUniformBuffer.Unmap;
    FreeAndNil(JointUniformBuffer);
  end;
  while Passes.Count > 0 do Passes.Pop.Free;
  Passes.Free;
  inherited Destroy;
end;

procedure TScene.TSkinSubsetData.Stage(const Params: array of const);
  var Cmd: TLabCommandBuffer;
begin
  Cmd := TLabCommandBuffer(Params[0].VPointer);
  Cmd.CopyBuffer(
    VertexBufferStaging.VkHandle,
    VertexBuffer.VkHandle,
    [LabBufferCopy(VertexBuffer.Size)]
  );
end;

{$Push}{$Hints off}
procedure TScene.TSkinSubsetData.StageComplete(const Params: array of const);
begin
  FreeAndNil(VertexBufferStaging);
end;
{$Pop}

constructor TScene.TSkinSubsetData.Create(const Subset: TLabSceneControllerSkin.TSubset);
  const FormatMap: array[1..4] of array[0..1] of TVkFormat = (
    (VK_FORMAT_R32_UINT, VK_FORMAT_R32_SFLOAT),
    (VK_FORMAT_R32G32_UINT, VK_FORMAT_R32G32_SFLOAT),
    (VK_FORMAT_R32G32B32_UINT, VK_FORMAT_R32G32B32_SFLOAT),
    (VK_FORMAT_R32G32B32A32_UINT, VK_FORMAT_R32G32B32A32_SFLOAT)
  );
  var Attribs: array[0..1] of TLabVertexBufferAttributeFormat;
  var map: Pointer;
begin
  _Subset := Subset;
  Attribs[0] := LabVertexBufferAttributeFormat(FormatMap[Subset.Skin.MaxWeightCount][0], 0);
  Attribs[1] := LabVertexBufferAttributeFormat(FormatMap[Subset.Skin.MaxWeightCount][1], Subset.Skin.MaxWeightCount * SizeOf(TVkUInt32));
  VertexBuffer := TLabVertexBuffer.Create(
    App.Device,
    Subset.Skin.VertexStride * Subset.GeometrySubset.VertexCount, Subset.Skin.VertexStride, Attribs,
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
    Move(Subset.WeightData^, map^, VertexBuffer.Size);
    VertexBufferStaging.Unmap;
  end;
  Subset.FreeWeightData;
  App.OnStage.Add(@Stage);
  App.OnStageComplete.Add(@StageComplete);
end;

destructor TScene.TSkinSubsetData.Destroy;
begin
  App.OnStage.Remove(@Stage);
  App.OnStageComplete.Remove(@StageComplete);
  FreeAndNil(VertexBufferStaging);
  FreeAndNil(VertexBuffer);
  inherited Destroy;
end;

procedure TScene.TGeometrySubsetData.Stage(const Params: array of const);
  var Cmd: TLabCommandBuffer;
begin
  Cmd := TLabCommandBuffer(Params[0].VPointer);
  Cmd.CopyBuffer(
    VertexBufferStaging.VkHandle,
    VertexBuffer.VkHandle,
    LabBufferCopy(VertexBufferStaging.Size)
  );
  Cmd.CopyBuffer(
    IndexBufferStaging.VkHandle,
    IndexBuffer.VkHandle,
    LabBufferCopy(IndexBufferStaging.Size)
  );
end;

{$Push}{$Hints off}
procedure TScene.TGeometrySubsetData.StageComplete(const Params: array of const);
begin
  FreeAndNil(VertexBufferStaging);
  FreeAndNil(IndexBufferStaging);
end;
{$Pop}

constructor TScene.TGeometrySubsetData.Create(const Subset: TLabSceneGeometry.TSubset);
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
  App.OnStage.Add(@Stage);
  App.OnStageComplete.Add(@StageComplete);
end;

destructor TScene.TGeometrySubsetData.Destroy;
begin
  App.OnStage.Remove(@Stage);
  App.OnStageComplete.Remove(@StageComplete);
  FreeAndNil(VertexBufferStaging);
  FreeAndNil(VertexBuffer);
  FreeAndNil(IndexBufferStaging);
  FreeAndNil(IndexBuffer);
  inherited Destroy;
end;

constructor TScene.TNodeData.Create(const Node: TLabSceneNode);
begin
  _Node := Node;
  UniformOffset := 0;
end;

destructor TScene.TNodeData.Destroy;
begin
  inherited Destroy;
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
    RenderTargets[i].Material.SetupImage(_WidthRT, _HeightRT, VK_FORMAT_R8G8B8A8_UNORM, TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT), App.SampleCount);
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
        RenderTargets[0].Material.Image.Ptr.Format,
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
        RenderTargets[i].Material.View.Ptr.VkHandle,
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

procedure TScene.ProcessScene;
  var inst_count: Integer;
  procedure ProcessNode(const Node: TLabSceneNode);
    var i: Integer;
    var nd: TNodeData;
  begin
    for i := 0 to Node.Attachments.Count - 1 do
    if (Node.Attachments[i] is TLabSceneNodeAttachmentGeometry)
    or (Node.Attachments[i] is TLabSceneNodeAttachmentController) then
    begin
      nd := TNodeData.Create(Node);
      nd.UniformOffset := inst_count;
      Node.UserData := nd;
      Inc(inst_count);
      Break;
    end;
    for i := 0 to Node.Children.Count - 1 do
    begin
      ProcessNode(Node.Children[i]);
    end;
  end;
  procedure CreateInstances(const Node: TLabSceneNode);
    var i: Integer;
  begin
    for i := 0 to Node.Attachments.Count - 1 do
    begin
      if Node.Attachments[i] is TLabSceneNodeAttachmentGeometry then
      begin
        Node.Attachments[i].UserData := TInstanceData.Create(Self, TLabSceneNodeAttachmentGeometry(Node.Attachments[i]));
      end
      else if Node.Attachments[i] is TLabSceneNodeAttachmentController then
      begin
        Node.Attachments[i].UserData := TInstanceData.Create(Self, TLabSceneNodeAttachmentController(Node.Attachments[i]));
      end
      else if Node.Attachments[i] is TLabSceneNodeAttachmentCamera then
      begin
        if not Assigned(CameraInst) then CameraInst := TLabSceneNodeAttachmentCamera(Node.Attachments[i]);
      end;
    end;
    for i := 0 to Node.Children.Count - 1 do
    begin
      CreateInstances(Node.Children[i]);
    end;
  end;
  var r_g: TLabSceneGeometry;
  var r_s: TLabSceneGeometry.TSubset;
  var r_i: TLabSceneImage;
  var r_c: TLabSceneControllerSkin;
  var i_i, i_g, i_s, i_c: Integer;
begin
  for i_g := 0 to Scene.Geometries.Count - 1 do
  begin
    r_g := Scene.Geometries[i_g];
    for i_s := 0 to r_g.Subsets.Count - 1 do
    begin
      r_s := r_g.Subsets[i_s];
      r_s.UserData := TGeometrySubsetData.Create(r_s);
    end;
  end;
  for i_c := 0 to Scene.Controllers.Count - 1 do
  if Scene.Controllers[i_c] is TLabSceneControllerSkin then
  begin
    r_c := TLabSceneControllerSkin(Scene.Controllers[i_c]);
    for i_s := 0 to r_c.Subsets.Count - 1 do
    begin
      r_c.Subsets[i_s].UserData := TSkinSubsetData.Create(r_c.Subsets[i_s]);
    end;
  end;
  for i_i := 0 to Scene.Images.Count - 1 do
  begin
    r_i := Scene.Images[i_i];
    r_i.UserData := TTexture.Create(r_i.Image);
  end;
  CameraInst := nil;
  inst_count := 0;
  UniformBufferGlobal := TUniformBufferGlobal.Create(App.Device, 1, TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT));
  UniformBufferView := TUniformBufferView.Create(App.Device, 1, TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT));
  ProcessNode(Scene.Root);
  if inst_count = 0 then Exit;
  UniformBufferInstance := TUniformBufferInstance.Create(App.Device, inst_count, TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT));
  CreateInstances(Scene.Root);
end;

procedure TScene.UpdateTransforms(const Params: array of const);
  var xf: PTransforms;
  procedure UpdateNode(const Node: TLabSceneNode);
    var i_n: Integer;
    var nd: TNodeData;
  begin
    nd := TNodeData(Node.UserData);
    if Assigned(nd) then
    with UniformBufferInstance.Ptr.Buffer[nd.UniformOffset]^ do
    begin
      w := Node.Transform * xf^.World;
    end;
    for i_n := 0 to Node.Children.Count - 1 do
    begin
      UpdateNode(Node.Children[i_n]);
    end;
  end;
  const anim_loop = 0.25;
  var t: TVkFloat;
begin
  if Scene.DefaultAnimationClip.MaxTime > LabEPS then
  begin
    t := LabTimeLoopSec(Scene.DefaultAnimationClip.MaxTime * anim_loop) / anim_loop;
    Scene.DefaultAnimationClip.Sample(t, True);
  end;
  xf := PTransforms(Params[0].VPointer);
  UniformBufferGlobal.Ptr.Buffer^.time := LabVec4(
    LabTimeSec, LabTimeLoopSec * LabTwoPi,
    sin(LabTimeLoopSec * LabTwoPi), cos(LabTimeLoopSec * LabTwoPi)
  );
  UniformBufferGlobal.Ptr.FlushAll;
  with UniformBufferView.Ptr.Buffer^ do
  begin
    v := xf^.View;
    p := xf^.Projection * xf^.Clip;
    vp := xf^.View * xf^.Projection * xf^.Clip;
    vp_i := (xf^.View * xf^.Projection * xf^.Clip).Inverse;
  end;
  UpdateNode(Scene.Root);
  if UniformBufferInstance.IsValid then UniformBufferInstance.Ptr.FlushAll;
end;

function TScene.GetUniformBufferOffsetAlignment(const BufferSize: TVkDeviceSize): TVkDeviceSize;
  var align: TVkDeviceSize;
begin
  align := App.Device.Ptr.PhysicalDevice.Ptr.Properties^.limits.minUniformBufferOffsetAlignment;
  Result := BufferSize;
  if align > 0 then
  begin
    Result := (Result + align - 1) and (not(align - 1));
  end;
end;

constructor TScene.Create;
  var xf: TLabMat;
begin
  Scene := TLabScene.Create(App.Device);
  //Scene.Add('../Models/scene.dae');
  //Scene.Add('../Models/maya/maya_anim.dae');
  Scene.Add('../Models/Cerberus/cerberus.dae');
  //xf := Scene.FindNode('Armature').Transform;
  //xf := xf * LabMatRotationY(-LabPi * 0.5) * LabMatScaling(0.75);
  //Scene.FindNode('Armature').Transform := xf;
  App.OnUpdateTransforms.Add(@UpdateTransforms);
  ProcessScene;
end;

destructor TScene.Destroy;
begin
  App.OnUpdateTransforms.Remove(@UpdateTransforms);
  if UniformBufferInstance.IsValid then UniformBufferInstance.Ptr.Unmap;
  Scene.Free;
  inherited Destroy;
end;

procedure TScene.Draw(const Cmd: TLabCommandBuffer);
  var cur_pipeline: TLabGraphicsPipeline;
  procedure RenderNode(const Node: TLabSceneNode);
    var nd: TNodeData;
    var i, i_a, i_p: Integer;
    var r_sg: TLabSceneGeometry.TSubset;
    var r_ss: TLabSceneControllerSkin.TSubset;
    var r_p: TInstanceData.TPass;
    var inst_data: TInstanceData;
    var geom_data: TGeometrySubsetData;
    var skin_data: TSkinSubsetData;
    var vertex_state: TLabPipelineVertexInputState;
    var attrib_desc: TLabVertexInputAttributeDescriptionArr;
  begin
    nd := TNodeData(Node.UserData);
    if Assigned(nd) then
    for i_a := 0 to Node.Attachments.Count - 1 do
    if Assigned(Node.Attachments[i_a].UserData)
    and (Node.Attachments[i_a].UserData is TInstanceData) then
    begin
      inst_data := TInstanceData(Node.Attachments[i_a].UserData);
      for i_p := 0 to inst_data.Passes.Count - 1 do
      begin
        r_p := inst_data.Passes[i_p];
        r_sg := r_p.GeomSubset;
        r_ss := r_p.SkinSubset;
        geom_data := TGeometrySubsetData(r_sg.UserData);
        if Assigned(r_ss) then skin_data := TSkinSubsetData(r_ss.UserData);
        if not r_p.Pipeline.IsValid then
        begin
          if Assigned(r_ss) then
          begin
            SetLength(attrib_desc, geom_data.VertexBuffer.AttributeCount + skin_data.VertexBuffer.AttributeCount);
            for i := 0 to geom_data.VertexBuffer.AttributeCount - 1 do
            begin
              attrib_desc[i] := geom_data.VertexBuffer.MakeAttributeDesc(i, i, 0);
            end;
            for i := 0 to skin_data.VertexBuffer.AttributeCount - 1 do
            begin
              attrib_desc[geom_data.VertexBuffer.AttributeCount + i] := (
                skin_data.VertexBuffer.MakeAttributeDesc(i, geom_data.VertexBuffer.AttributeCount + i, 1)
              );
            end;
            vertex_state := LabPipelineVertexInputState(
              [
                geom_data.VertexBuffer.MakeBindingDesc(0),
                skin_data.VertexBuffer.MakeBindingDesc(1)
              ],
              attrib_desc
            );
          end
          else
          begin
            vertex_state := LabPipelineVertexInputState(
              [geom_data.VertexBuffer.MakeBindingDesc(0)],
              geom_data.VertexBuffer.MakeAttributeDescArr(0, 0)
            );
          end;
          r_p.Pipeline := TLabGraphicsPipeline.FindOrCreate(
            App.Device, App.PipelineCache, r_p.PipelineLayout.Ptr,
            [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
            [
              LabShaderStage(r_p.Shader.Ptr.VertexShader.Ptr.Shader),
              LabShaderStage(r_p.Shader.Ptr.PixelShader.Ptr.Shader)
            ],
            App.DeferredBuffer.Ptr.RenderPass.Ptr, 0,
            LabPipelineViewportState(),
            LabPipelineInputAssemblyState(),
            vertex_state,
            LabPipelineRasterizationState(
              VK_FALSE, VK_FALSE,
              VK_POLYGON_MODE_FILL,
              TVkFlags(VK_CULL_MODE_BACK_BIT),
              VK_FRONT_FACE_COUNTER_CLOCKWISE
            ),
            LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
            LabPipelineMultisampleState(App.SampleCount, VK_TRUE, 0.3, nil, VK_TRUE),
            LabPipelineColorBlendState(
              [
                LabDefaultColorBlendAttachment,
                LabDefaultColorBlendAttachment,
                LabDefaultColorBlendAttachment,
                LabDefaultColorBlendAttachment
              ],
              []
            ),
            LabPipelineTesselationState(0)
          );
        end;
        if not Assigned(cur_pipeline)
        or (cur_pipeline.Hash <> TLabGraphicsPipeline(r_p.Pipeline.Ptr).Hash) then
        begin
          cur_pipeline := TLabGraphicsPipeline(r_p.Pipeline.Ptr);
          Cmd.BindPipeline(cur_pipeline);
        end;
        Cmd.BindDescriptorSets(
          VK_PIPELINE_BIND_POINT_GRAPHICS,
          r_p.PipelineLayout.Ptr,
          0, [r_p.Shader.Ptr.DescriptorSets.Ptr.VkHandle[0]], [UniformBufferInstance.Ptr.BufferOffset[nd.UniformOffset]]
        );
        if Assigned(r_ss) then
        begin
          Cmd.BindVertexBuffers(
            0,
            [
              geom_data.VertexBuffer.VkHandle,
              skin_data.VertexBuffer.VkHandle
            ], [0, 0]
          );
        end
        else
        begin
          Cmd.BindVertexBuffers(0, [geom_data.VertexBuffer.VkHandle], [0]);
        end;
        Cmd.BindIndexBuffer(geom_data.IndexBuffer.VkHandle, 0, geom_data.IndexBuffer.IndexType);
        Cmd.DrawIndexed(geom_data.IndexBuffer.IndexCount);
      end;
    end;
    for i := 0 to Node.Children.Count - 1 do
    begin
      RenderNode(Node.Children[i]);
    end;
  end;
begin
  cur_pipeline := nil;
  RenderNode(Scene.Root);
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

constructor TLightData.TComputeTask.Create(const StorageBuffer: TLabBuffer; const InstanceCount: TVkUInt32);
  var dg: TVkUInt32;
  const bounds_size = 7;
  const bounds_offset: TLabVec3 = (x: 0; y: 3; z: 0);
begin
  inherited Create;
  ComputeShader := TLabComputeShader.Create(App.Device, 'cs.spv');
  UniformBuffer := TUniformBufferCompute.Create(App.Device);
  Uniforms := UniformBuffer.Ptr.Buffer;
  if UniformBuffer.Ptr.Map(Uniforms) then
  begin
    FillChar(Uniforms^, SizeOf(TComputeUniforms), 0);
    Uniforms^.bounds_min := LabVec4(-bounds_size + bounds_offset.x, -bounds_size + bounds_offset.y, -bounds_size + bounds_offset.z, 0);
    Uniforms^.bounds_max := LabVec4(bounds_size + bounds_offset.x, bounds_size + bounds_offset.y, bounds_size + bounds_offset.z, 0);
  end;
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings([
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_COMPUTE_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_COMPUTE_BIT))
    ])
  ]);
  PipelineLayout := TLabPipelineLayout.Create(
    App.Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]
  );
  DescriptorSets.Ptr.UpdateSets(
    [
      LabWriteDescriptorSetStorageBuffer(
        DescriptorSets.Ptr.VkHandle[0], 0, LabDescriptorBufferInfo(StorageBuffer.VkHandle)
      ),
      LabWriteDescriptorSetUniformBuffer(
        DescriptorSets.Ptr.VkHandle[0], 1, LabDescriptorBufferInfo(UniformBuffer.Ptr.VkHandle)
      )
    ],
    []
  );
  Pipeline := TLabComputePipeline.Create(
    App.Device, App.PipelineCache, PipelineLayout.Ptr, ComputeShader,
    [
      LabSpecializationMapEntry(0, 0, SizeOf(InstanceCount))
    ],
    @InstanceCount, SizeOf(InstanceCount)
  );
  Fence := TLabFence.Create(App.Device);
  Cmd := TLabCommandBuffer.Create(App.CmdPoolCompute);
  Cmd.Ptr.RecordBegin;
  Cmd.Ptr.BindPipeline(Pipeline.Ptr);
  Cmd.Ptr.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_COMPUTE,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[0]],
    []
  );
  dg := Trunc((InstanceCount - 1) / 256) + 1;
  Cmd.Ptr.DispatchCompute(dg, 1, 1);
  Cmd.Ptr.RecordEnd;
end;

destructor TLightData.TComputeTask.Destroy;
begin
  UniformBuffer.Ptr.Unmap;
  inherited Destroy;
end;

procedure TLightData.TComputeTask.Run;
begin
  App.QueueSubmit(
    App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyCompute,
    [Cmd.Ptr.VkHandle],
    [],
    [],
    Fence.Ptr.VkHandle
  );
  Fence.Ptr.WaitFor;
  Fence.Ptr.Reset;
end;

constructor TLightData.Create;
  var i: TVkInt32;
  var map: PVkVoid;
  const light_radius_scale = 5;
  const light_intensity_scale = 0.5;
  const light_speed_scale = 1.5;
begin
  InstanceCount := 256;
  VertexBuffer := TLabVertexBuffer.Create(
    App.Device,
    SizeOf(light_vertices), SizeOf(TLightVertex),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, 0)
    ],
    TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  VertexStaging := TLabBuffer.Create(
    App.Device,
    VertexBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
    [],
    VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  map := nil;
  if VertexStaging.Ptr.Map(map) then
  begin
    Move(light_vertices, map^, SizeOf(light_vertices));
    VertexStaging.Ptr.FlushAll;
    VertexStaging.Ptr.Unmap;
  end;
  IndexBuffer := TLabIndexBuffer.Create(
    App.Device, Length(light_indices), VK_INDEX_TYPE_UINT16,
    TVkFlags(VK_BUFFER_USAGE_INDEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  IndexStaging := TLabBuffer.Create(
    App.Device, IndexBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
    [],
    VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  if IndexStaging.Ptr.Map(map) then
  begin
    Move(light_indices, map^, SizeOf(light_indices));
    IndexStaging.Ptr.FlushAll;
    IndexStaging.Ptr.Unmap;
  end;
  InstanceBuffer := TLabVertexBuffer.Create(
    App.Device, SizeOf(TLightInstance) * InstanceCount, SizeOf(TLightInstance),
    [
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, LabPtrToOrd(@TLightInstance( nil^ ).pos)),
      LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, LabPtrToOrd(@TLightInstance( nil^ ).color))
    ],
    TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT) or TVkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkFlags(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  InstanceStaging := TLabBuffer.Create(
    App.Device, InstanceBuffer.Ptr.Size,
    TVkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
    [], VK_SHARING_MODE_EXCLUSIVE,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  Randomize;
  if InstanceStaging.Ptr.Map(map) then
  begin
    for i := 0 to InstanceCount - 1 do
    begin
      PLightInstanceArr(map)^[i].pos := LabVec4(
        (Random * 2 - 1) * 6,
        (Random * 2 - 1) * 6,
        (Random * 2 - 1) * 6,
        light_radius_scale * (Random * 1.5 + 0.2)
      );
      PLightInstanceArr(map)^[i].color := LabVec4(
        light_intensity_scale * (Random * 0.8 + 0.2),
        light_intensity_scale * (Random * 0.8 + 0.2),
        light_intensity_scale * (Random * 0.8 + 0.2),
        1
      );
      PLightInstanceArr(map)^[i].vel := LabVec4(light_speed_scale * LabRandomSpherePoint, 0);
    end;
    InstanceStaging.Ptr.FlushAll;
    InstanceStaging.Ptr.Unmap;
  end;
  VertexShader := TLabVertexShader.Create(App.Device, 'light_vs.spv');
  TessControlShader := TLabTessCtrlShader.Create(App.Device, 'light_tcs.spv');
  TessEvalShader := TLabTessEvalShader.Create(App.Device, 'light_tes.spv');
  if App.SampleCount = VK_SAMPLE_COUNT_1_BIT then
  begin
    PixelShader := TLabPixelShader.Create(App.Device, 'light_ps.spv');
  end
  else
  begin
    PixelShader := TLabPixelShader.Create(App.Device, 'light_ps_ms.spv');
  end;
  Sampler := TLabSampler.Create(
    App.Device, VK_FILTER_NEAREST, VK_FILTER_NEAREST,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_FALSE, 1, VK_SAMPLER_MIPMAP_MODE_NEAREST
  );
  UniformBufferVertex := TUniformBufferVertex.Create(App.Device);
  UniformsVertex := UniformBufferVertex.Ptr.Buffer;
  UniformBufferPixel := TUniformBufferPixel.Create(App.Device);
  UniformsPixel := UniformBufferPixel.Ptr.Buffer;
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings([
      LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT)),
      LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(3, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(4, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
      LabDescriptorBinding(5, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
    ], App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount)
  ]);
  for i := 0 to App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount - 1 do
  begin
    DescriptorSets.Ptr.UpdateSets(
      [
        LabWriteDescriptorSetUniformBuffer(
          DescriptorSets.Ptr.VkHandle[i],
          0, [LabDescriptorBufferInfo(UniformBufferVertex.Ptr.VkHandle)]
        ),
        LabWriteDescriptorSetUniformBuffer(
          DescriptorSets.Ptr.VkHandle[i],
          1, [LabDescriptorBufferInfo(UniformBufferPixel.Ptr.VkHandle)]
        )
      ], []
    );
  end;
  PipelineLayout := TLabPipelineLayout.Create(
    App.Device, [], [DescriptorSets.Ptr.Layout[0].Ptr]
  );
  ComputeTask := TComputeTask.Create(InstanceBuffer.Ptr, InstanceCount);
  App.OnStage.Add(@Stage);
  App.OnUpdateTransforms.Add(@UpdateTransforms);
  App.OnBindOffscreenTargets.Add(@BindOffscreenTargets);
end;

destructor TLightData.Destroy;
begin
  ComputeTask.Free;
  App.OnBindOffscreenTargets.Remove(@BindOffscreenTargets);
  App.OnUpdateTransforms.Remove(@UpdateTransforms);
  App.OnStage.Remove(@Stage);
  inherited Destroy;
end;

procedure TLightData.Stage(const Args: array of const);
  var Cmd: TLabCommandBuffer;
begin
  Cmd := TLabCommandBuffer(Args[0].VObject);
  Cmd.CopyBuffer(VertexStaging.Ptr.VkHandle, VertexBuffer.Ptr.VkHandle, [LabBufferCopy(VertexBuffer.Ptr.Size)]);
  Cmd.CopyBuffer(InstanceStaging.Ptr.VkHandle, InstanceBuffer.Ptr.VkHandle, [LabBufferCopy(InstanceBuffer.Ptr.Size)]);
  Cmd.CopyBuffer(IndexStaging.Ptr.VkHandle, IndexBuffer.Ptr.VkHandle, [LabBufferCopy(IndexBuffer.Ptr.Size)]);
end;

procedure TLightData.UpdateTransforms(const Args: array of const);
  var xf: PTransforms;
  var VP: TLabMat;
  var v_pos: TLabVec3;
begin
  xf := PTransforms(Args[0].VPointer);
  ComputeTask.Uniforms^.box_x := LabVec4;//LabVec4(TLabVec3(xf^.World.AxisX).Norm, 0);
  ComputeTask.Uniforms^.box_y := LabVec4;//(TLabVec3(xf^.World.AxisY).Norm, 0);
  ComputeTask.Uniforms^.box_z := LabVec4;//(TLabVec3(xf^.World.AxisZ).Norm, 0);
  v_pos := LabVec3(-xf^.View.e30, -xf^.View.e31, -xf^.View.e32);
  v_pos := v_pos.Transform3x3(xf^.View.Transpose);
  VP := xf^.View * xf^.Projection * xf^.Clip;
  UniformsVertex^.VP := VP;
  UniformsPixel^.VP_i := VP.Inverse;
  UniformsPixel^.camera_pos := LabVec4(v_pos, 0);
  ComputeTask.Run;
end;

{$Push}{$Hints off}
procedure TLightData.BindOffscreenTargets(const Args: array of const);
  var i: TVkInt32;
  var Writes: array of TLabWriteDescriptorSet;
  const image_count = 4;
begin
  SetLength(Writes, App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount * image_count);
  for i := 0 to App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount - 1 do
  begin
    Writes[i * image_count + 0] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      2,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Depth.View.Ptr.VkHandle,
          Sampler.Ptr.VkHandle
        )
      ]
    );
    Writes[i * image_count + 1] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      3,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Color.View.Ptr.VkHandle,
          //App.Texture.View.Ptr.VkHandle,
          Sampler.Ptr.VkHandle
        )
      ]
    );
    Writes[i * image_count + 2] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      4,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Normals.View.Ptr.VkHandle,
          Sampler.Ptr.VkHandle
        )
      ]
    );
    Writes[i * image_count + 3] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      5,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Material.View.Ptr.VkHandle,
          Sampler.Ptr.VkHandle
        )
      ]
    );
  end;
  DescriptorSets.Ptr.UpdateSets(Writes, []);
  UniformsPixel^.rt_ratio := LabVec4(
    1 / App.BackBuffer.Ptr.SwapChain.Ptr.Width,
    1 / App.BackBuffer.Ptr.SwapChain.Ptr.Height,
    App.BackBuffer.Ptr.SwapChain.Ptr.Width / App.DeferredBuffer.Ptr.WidthRT,
    App.BackBuffer.Ptr.SwapChain.Ptr.Height / App.DeferredBuffer.Ptr.HeightRT
  );
end;
{$Pop}

procedure TLightData.Draw(const Cmd: TLabCommandBuffer; const ImageIndex: TVkUInt32);
  var shader_stage_ps: TLabShaderStage;
begin
  if App.SampleCount = VK_SAMPLE_COUNT_1_BIT then
  begin
    shader_stage_ps := LabShaderStage(PixelShader.Ptr);
  end
  else
  begin
    shader_stage_ps := LabShaderStage(
      PixelShader.Ptr,
      @App.SampleCount,
      SizeOf(App.SampleCount),
      LabSpecializationMapEntry(0, 0, SizeOf(App.SampleCount))
    );
  end;
  Pipeline := TLabGraphicsPipeline.FindOrCreate(
    App.Device, App.PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [
      LabShaderStage(VertexShader.Ptr),
      LabShaderStage(TessControlShader.Ptr),
      LabShaderStage(TessEvalShader.Ptr),
      shader_stage_ps
    ],
    App.BackBuffer.Ptr.RenderPass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(
      VK_PRIMITIVE_TOPOLOGY_PATCH_LIST
    ),
    LabPipelineVertexInputState(
      [VertexBuffer.Ptr.MakeBindingDesc(0), InstanceBuffer.Ptr.MakeBindingDesc(1, VK_VERTEX_INPUT_RATE_INSTANCE)],
      [
        VertexBuffer.Ptr.MakeAttributeDesc(0, 0, 0),
        InstanceBuffer.Ptr.MakeAttributeDesc(0, 1, 1),
        InstanceBuffer.Ptr.MakeAttributeDesc(1, 2, 1)
      ]
    ),
    LabPipelineRasterizationState(
      //VK_FALSE, VK_FALSE,
      //VK_POLYGON_MODE_LINE
    ),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_TRUE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState(
      [
        LabPipelineColorBlendAttachmentState(
          VK_TRUE,
          VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE,
          VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE
        )
      ], []
    ),
    LabPipelineTesselationState(3)
  );
  Cmd.BindPipeline(Pipeline.Ptr);
  Cmd.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[ImageIndex]], []
  );
  Cmd.BindVertexBuffers(0, [VertexBuffer.Ptr.VkHandle, InstanceBuffer.Ptr.VkHandle], [0, 0]);
  Cmd.BindIndexBuffer(IndexBuffer.Ptr.VkHandle);
  Cmd.DrawIndexed(IndexBuffer.Ptr.IndexCount, InstanceCount);
end;

procedure TIBLight.Resize(const Params: array of const);
  var w, h: TVkUInt32;
begin
  w := TVkUInt32(Params[0].VInteger);
  h := TVkUInt32(Params[1].VInteger);
  UniformData^.screen_ratio := LabVec4(w, h, 1 / w, 1 / h);
end;

procedure TIBLight.LoadEnvMap;
  const tex_size = 1024;
  var tex2d: TLabTexture2D;
  var tmp_cmd: TLabCommandBufferShared;
  var render_pass: TLabRenderPassShared;
  var attachments: array[0..5] of TVkAttachmentDescription;
  var i: Integer;
  var frame_buffer: TLabFrameBufferShared;
  var vs: TLabVertexShaderShared;
  var ps: TLabPixelShaderShared;
  var pipeline_layout: TLabPipelineLayoutShared;
  var pipeline_tmp: TLabPipelineShared;
  var desc_sets: TLabDescriptorSetsShared;
  var viewport: TVkViewport;
  var scissor: TVkRect2D;
  var view_arr: array[0..5] of TLabImageViewShared;
begin
  TextureEnv := TLabTextureCube.Create(
    App.Device,
    tex_size, VK_FORMAT_R16G16B16A16_SFLOAT,
    VK_IMAGE_LAYOUT_UNDEFINED,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    True
  );
  for i := 0 to 5 do
  begin
    view_arr[i] := TLabImageView.Create(
      App.Device, TextureEnv.Ptr.Image.Ptr.VkHandle, TextureEnv.Ptr.Image.Ptr.Format,
      TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
      0, 1, i, 1
    );
  end;
  tex2d := TLabTexture2D.Create(App.Device, '../Images/Arches_E_PineTree_3k.hdr', False);
  //tex2d := TLabTexture2D.Create(App.Device, '../Images/Tropical_Beach/Tropical_Beach_3k.hdr', False);
  //tex2d := TLabTexture2D.Create(App.Device, '../Images/Mono_Lake_C/Mono_Lake_C_Ref.hdr', False);
  //tex2d := TLabTexture2D.Create(App.Device, '../Images/hdrvfx_0012_sand/hdrvfx_0012_sand_v11_Ref.hdr', False);
  //tex2d := TLabTexture2D.Create(App.Device, '../Images/Summi_Pool/Summi_Pool_3k.hdr', False);
  //tex2d := TLabTexture2D.Create(App.Device, '../Images/Milkyway/Milkyway_small.hdr', False);
  //tex2d := TLabTexture2D.Create(App.Device, '../Images/Factory_Catwalk/Factory_Catwalk_2k.hdr', False);
  //tex2d := TLabTexture2D.Create(App.Device, '../Images/Hamarikyu_Bridge_B/14-Hamarikyu_Bridge_B_3k.hdr', False);
  //tex2d := TLabTexture2D.Create(App.Device, '../Images/Theatre_Center/Theatre-Center_2k.hdr', False);
  //tex2d := TLabTexture2D.Create(App.Device, '../Images/CharlesRiver/CharlesRiver_Ref.hdr', False);
  for i := 0 to High(attachments) do
  begin
    attachments[i] := LabAttachmentDescription(
      TextureEnv.Ptr.Format, {VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL} VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_SAMPLE_COUNT_1_BIT,
      VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_STORE, VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_DONT_CARE,
      VK_IMAGE_LAYOUT_UNDEFINED
    );
  end;
  render_pass := TLabRenderPass.Create(
    App.Device,
    attachments,
    [
      LabSubpassDescriptionData(
        [],
        [
          LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(1, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(2, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(3, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(4, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(5, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
        ],
        [],
        LabAttachmentReferenceInvalid,
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
  frame_buffer := TLabFrameBuffer.Create(
    App.Device, render_pass, tex_size, tex_size,
    [
      view_arr[0].Ptr.VkHandle,
      view_arr[1].Ptr.VkHandle,
      view_arr[2].Ptr.VkHandle,
      view_arr[3].Ptr.VkHandle,
      view_arr[4].Ptr.VkHandle,
      view_arr[5].Ptr.VkHandle
    ]
  );
  desc_sets := App.DescriptorSetsFactory.Ptr.Request(
    [
      LabDescriptorSetBindings(
        [
          LabDescriptorBinding(
            0, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
          )
        ]
      )
    ]
  );
  pipeline_layout := TLabPipelineLayout.Create(
    App.Device, [],
    [
      desc_sets.Ptr.Layout[0].Ptr
    ]
  );
  desc_sets.Ptr.UpdateSets(
    LabWriteDescriptorSetImageSampler(
      desc_sets.Ptr.VkHandle[0], 0,
      LabDescriptorImageInfo(
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        tex2d.View.Ptr.VkHandle,
        tex2d.Sampler.Ptr.VkHandle
      )
    ),
    []
  );
  vs := TLabVertexShader.Create(App.Device, 'shaders/pbr/cube_map_vs.spv');
  ps := TLabPixelShader.Create(App.Device, 'shaders/pbr/gen_cube_map_ps.spv');
  viewport := LabViewport(0, 0, tex_size, tex_size);
  scissor := LabRect2D(0, 0, tex_size, tex_size);
  pipeline_tmp := TLabGraphicsPipeline.FindOrCreate(
    App.Device, App.PipelineCache, pipeline_layout.Ptr, [],
    [LabShaderStage(vs.Ptr), LabShaderStage(ps.Ptr)],
    render_pass, 0,
    LabPipelineViewportState(1, @viewport, 1, @scissor),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment,
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment
    ], []),
    LabPipelineTesselationState(0)
  );
  tmp_cmd := TLabCommandBuffer.Create(App.CmdPool);
  tmp_cmd.Ptr.RecordBegin();
  tex2d.Stage([tmp_cmd.Ptr]);
  tmp_cmd.Ptr.BeginRenderPass(
    render_pass.Ptr, frame_buffer.Ptr,
    [
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0)
    ]
  );
  tmp_cmd.Ptr.BindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline_layout.Ptr, 0, [desc_sets.Ptr.VkHandle[0]], []);
  tmp_cmd.Ptr.BindPipeline(pipeline_tmp.Ptr);
  tmp_cmd.Ptr.Draw(3);
  tmp_cmd.Ptr.EndRenderPass;
  tmp_cmd.Ptr.RecordEnd;
  TLabVulkan.QueueSubmit(
    App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics,
    [tmp_cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  TLabVulkan.QueueWaitIdle(App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics);
  tex2d.Free;
  tmp_cmd.Ptr.RecordBegin();
  TextureEnv.Ptr.GenMipMaps(tmp_cmd.Ptr);
  tmp_cmd.Ptr.RecordEnd;
  TLabVulkan.QueueSubmit(
    App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics,
    [tmp_cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    0
  );
  TLabVulkan.QueueWaitIdle(App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics);
end;

procedure TIBLight.GenerateIrradianceMap;
  const tex_size = 64;
  var tmp_cmd: TLabCommandBufferShared;
  var render_pass: TLabRenderPassShared;
  var attachments: array[0..5] of TVkAttachmentDescription;
  var i: Integer;
  var frame_buffer: TLabFrameBufferShared;
  var vs: TLabVertexShaderShared;
  var ps: TLabPixelShaderShared;
  var pipeline_layout: TLabPipelineLayoutShared;
  var pipeline_tmp: TLabPipelineShared;
  var desc_sets: TLabDescriptorSetsShared;
  var viewport: TVkViewport;
  var scissor: TVkRect2D;
  var view_arr: array[0..5] of TLabImageViewShared;
begin
  TextureIrradiance := TLabTextureCube.Create(
    App.Device,
    tex_size, VK_FORMAT_R16G16B16A16_SFLOAT,
    VK_IMAGE_LAYOUT_UNDEFINED,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
    TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
    True
  );
  for i := 0 to 5 do
  begin
    view_arr[i] := TLabImageView.Create(
      App.Device, TextureIrradiance.Ptr.Image.Ptr.VkHandle, TextureIrradiance.Ptr.Image.Ptr.Format,
      TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
      0, 1, i, 1
    );
  end;
  for i := 0 to High(attachments) do
  begin
    attachments[i] := LabAttachmentDescription(
      TextureIrradiance.Ptr.Format, {VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL} VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK_SAMPLE_COUNT_1_BIT,
      VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_STORE, VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_DONT_CARE,
      VK_IMAGE_LAYOUT_UNDEFINED
    );
  end;
  render_pass := TLabRenderPass.Create(
    App.Device,
    attachments,
    [
      LabSubpassDescriptionData(
        [],
        [
          LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(1, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(2, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(3, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(4, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(5, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
        ],
        [],
        LabAttachmentReferenceInvalid,
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
  frame_buffer := TLabFrameBuffer.Create(
    App.Device, render_pass, tex_size, tex_size,
    [
      view_arr[0].Ptr.VkHandle,
      view_arr[1].Ptr.VkHandle,
      view_arr[2].Ptr.VkHandle,
      view_arr[3].Ptr.VkHandle,
      view_arr[4].Ptr.VkHandle,
      view_arr[5].Ptr.VkHandle
    ]
  );
  desc_sets := App.DescriptorSetsFactory.Ptr.Request(
    [
      LabDescriptorSetBindings(
        [
          LabDescriptorBinding(
            0, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
          )
        ]
      )
    ]
  );
  pipeline_layout := TLabPipelineLayout.Create(
    App.Device, [],
    [
      desc_sets.Ptr.Layout[0].Ptr
    ]
  );
  desc_sets.Ptr.UpdateSets(
    LabWriteDescriptorSetImageSampler(
      desc_sets.Ptr.VkHandle[0], 0,
      LabDescriptorImageInfo(
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        TextureEnv.Ptr.View.Ptr.VkHandle,
        TextureEnv.Ptr.Sampler.Ptr.VkHandle
      )
    ),
    []
  );
  vs := TLabVertexShader.Create(App.Device, 'shaders/pbr/cube_map_vs.spv');
  ps := TLabPixelShader.Create(App.Device, 'shaders/pbr/gen_irradiance_map_ps.spv');
  viewport := LabViewport(0, 0, tex_size, tex_size);
  scissor := LabRect2D(0, 0, tex_size, tex_size);
  pipeline_tmp := TLabGraphicsPipeline.FindOrCreate(
    App.Device, App.PipelineCache, pipeline_layout.Ptr, [],
    [LabShaderStage(vs.Ptr), LabShaderStage(ps.Ptr)],
    render_pass, 0,
    LabPipelineViewportState(1, @viewport, 1, @scissor),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment,
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment
    ], []),
    LabPipelineTesselationState(0)
  );
  tmp_cmd := TLabCommandBuffer.Create(App.CmdPool);
  tmp_cmd.Ptr.RecordBegin();
  tmp_cmd.Ptr.BeginRenderPass(
    render_pass.Ptr, frame_buffer.Ptr,
    [
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0),
      LabClearValue(0.0, 0.0, 0.0, 1.0)
    ]
  );
  tmp_cmd.Ptr.BindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline_layout.Ptr, 0, [desc_sets.Ptr.VkHandle[0]], []);
  tmp_cmd.Ptr.BindPipeline(pipeline_tmp.Ptr);
  tmp_cmd.Ptr.Draw(3);
  tmp_cmd.Ptr.EndRenderPass;
  tmp_cmd.Ptr.RecordEnd;
  TLabVulkan.QueueSubmit(
    App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics,
    [tmp_cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  TLabVulkan.QueueWaitIdle(App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics);
  tmp_cmd.Ptr.RecordBegin();
  TextureIrradiance.Ptr.GenMipMaps(tmp_cmd.Ptr);
  tmp_cmd.Ptr.RecordEnd;
  TLabVulkan.QueueSubmit(
    App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics,
    [tmp_cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    0
  );
  TLabVulkan.QueueWaitIdle(App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics);
end;

procedure TIBLight.GeneratePrefilteredMap;
  const tex_size = 512;
  var tmp_cmd: TLabCommandBufferShared;
  var render_pass: TLabRenderPassShared;
  var attachments: array[0..5] of TVkAttachmentDescription;
  var i, m, ts: Integer;
  var frame_buffers: array of TLabFrameBufferShared;
  var vs: TLabVertexShaderShared;
  var ps: TLabPixelShaderShared;
  var pipeline_layout: TLabPipelineLayoutShared;
  var pipeline_tmp: TLabPipelineShared;
  var desc_sets: TLabDescriptorSetsShared;
  var view_arr: array of array[0..5] of TLabImageViewShared;
  var push_consts: record
    roughness: TVkFloat;
    sample_count: TVkUInt32;
  end;
begin
  TexturePrefiltered := TLabTextureCube.Create(
    App.Device,
    tex_size, VK_FORMAT_R16G16B16A16_SFLOAT,
    VK_IMAGE_LAYOUT_UNDEFINED,
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT) or
    TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT),
    True
  );
  SetLength(view_arr, TexturePrefiltered.Ptr.MipLevels);
  for m := 0 to TexturePrefiltered.Ptr.MipLevels - 1 do
  for i := 0 to 5 do
  begin
    view_arr[m][i] := TLabImageView.Create(
      App.Device, TexturePrefiltered.Ptr.Image.Ptr.VkHandle, TexturePrefiltered.Ptr.Image.Ptr.Format,
      TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT), VK_IMAGE_VIEW_TYPE_2D,
      m, 1, i, 1
    );
  end;
  for i := 0 to High(attachments) do
  begin
    attachments[i] := LabAttachmentDescription(
      TexturePrefiltered.Ptr.Format, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_SAMPLE_COUNT_1_BIT,
      VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_STORE, VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_DONT_CARE,
      VK_IMAGE_LAYOUT_UNDEFINED
    );
  end;
  render_pass := TLabRenderPass.Create(
    App.Device,
    attachments,
    [
      LabSubpassDescriptionData(
        [],
        [
          LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(1, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(2, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(3, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(4, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL),
          LabAttachmentReference(5, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
        ],
        [],
        LabAttachmentReferenceInvalid,
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
  SetLength(frame_buffers, TexturePrefiltered.Ptr.MipLevels);
  for m := 0 to TexturePrefiltered.Ptr.MipLevels - 1 do
  begin
    ts := Round(tex_size * Math.intpower(0.5, m));
    frame_buffers[m] := TLabFrameBuffer.Create(
      App.Device, render_pass, ts, ts,
      [
        view_arr[m][0].Ptr.VkHandle,
        view_arr[m][1].Ptr.VkHandle,
        view_arr[m][2].Ptr.VkHandle,
        view_arr[m][3].Ptr.VkHandle,
        view_arr[m][4].Ptr.VkHandle,
        view_arr[m][5].Ptr.VkHandle
      ]
    );
  end;
  desc_sets := App.DescriptorSetsFactory.Ptr.Request(
    [
      LabDescriptorSetBindings(
        [
          LabDescriptorBinding(
            0, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)
          )
        ]
      )
    ]
  );
  pipeline_layout := TLabPipelineLayout.Create(
    App.Device, [
      LabPushConstantRange(
        TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
        0, SizeOf(push_consts)
      )
    ],
    [
      desc_sets.Ptr.Layout[0].Ptr
    ]
  );
  desc_sets.Ptr.UpdateSets(
    LabWriteDescriptorSetImageSampler(
      desc_sets.Ptr.VkHandle[0], 0,
      LabDescriptorImageInfo(
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        TextureEnv.Ptr.View.Ptr.VkHandle,
        TextureEnv.Ptr.Sampler.Ptr.VkHandle
      )
    ),
    []
  );
  vs := TLabVertexShader.Create(App.Device, 'shaders/pbr/cube_map_vs.spv');
  ps := TLabPixelShader.Create(App.Device, 'shaders/pbr/gen_prefiltered_map_ps.spv');
  pipeline_tmp := TLabGraphicsPipeline.FindOrCreate(
    App.Device, App.PipelineCache, pipeline_layout.Ptr, [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [LabShaderStage(vs.Ptr), LabShaderStage(ps.Ptr)],
    render_pass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment,
      LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment, LabDefaultColorBlendAttachment
    ], []),
    LabPipelineTesselationState(0)
  );
  tmp_cmd := TLabCommandBuffer.Create(App.CmdPool);
  tmp_cmd.Ptr.RecordBegin();
  for m := 0 to TexturePrefiltered.Ptr.MipLevels - 1 do
  begin
    ts := Round(tex_size * Math.intpower(0.5, m));
    tmp_cmd.Ptr.SetScissor([LabRect2D(0, 0, ts, ts)]);
    tmp_cmd.Ptr.SetViewport([LabViewport(0, 0, ts, ts)]);
    tmp_cmd.Ptr.BeginRenderPass(
      render_pass.Ptr, frame_buffers[m].Ptr,
      [
        LabClearValue(0.0, 0.0, 0.0, 1.0),
        LabClearValue(0.0, 0.0, 0.0, 1.0),
        LabClearValue(0.0, 0.0, 0.0, 1.0),
        LabClearValue(0.0, 0.0, 0.0, 1.0),
        LabClearValue(0.0, 0.0, 0.0, 1.0),
        LabClearValue(0.0, 0.0, 0.0, 1.0)
      ]
    );
    tmp_cmd.Ptr.BindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline_layout.Ptr, 0, [desc_sets.Ptr.VkHandle[0]], []);
    tmp_cmd.Ptr.BindPipeline(pipeline_tmp.Ptr);
    push_consts.roughness := m / (TexturePrefiltered.Ptr.MipLevels - 1);
    push_consts.sample_count := 64;
    tmp_cmd.Ptr.PushConstants(pipeline_layout.Ptr, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT), 0, SizeOf(push_consts), @push_consts);
    tmp_cmd.Ptr.Draw(3);
    tmp_cmd.Ptr.EndRenderPass;
  end;
  tmp_cmd.Ptr.RecordEnd;
  TLabVulkan.QueueSubmit(
    App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics,
    [tmp_cmd.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  TLabVulkan.QueueWaitIdle(App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics);
end;

procedure TIBLight.GenerateBRDFLUT;
  const tex_size = 512;
  var cmd_tmp: TLabCommandBufferShared;
  var pipeline_layout: TLabPipelineLayoutShared;
  var pipeline_tmp: TLabPipelineShared;
  var vs: TLabVertexShaderShared;
  var ps: TLabPixelShaderShared;
  var render_pass: TLabRenderPassShared;
  var frame_buffer: TLabFrameBufferShared;
begin
  TextureBRDFLUT := TLabTexture2D.Create(
    App.Device,
    VK_FORMAT_R16G16_SFLOAT, tex_size, tex_size,
    TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or
    TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
    TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
    False,
    False
  );
  vs := TLabVertexShader.Create(App.Device, 'shaders/pbr/brdflut_vs.spv');
  ps := TLabPixelShader.Create(App.Device, 'shaders/pbr/brdflut_ps.spv');
  render_pass := TLabRenderPass.Create(
    App.Device,
    [
      LabAttachmentDescription(
        TextureBRDFLUT.Ptr.Format,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_STORE
      )
    ],
    [
      LabSubpassDescriptionData(
        [],
        [
          LabAttachmentReference(0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
        ],
        [],
        LabAttachmentReferenceInvalid,
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
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
      ),
      LabSubpassDependency(
        0,
        VK_SUBPASS_EXTERNAL,
        TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
        TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
        TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_ACCESS_MEMORY_READ_BIT)
      )
    ]
  );
  pipeline_layout := TLabPipelineLayout.Create(
    App.Device, [], []
  );
  pipeline_tmp := TLabGraphicsPipeline.Create(
    App.Device, App.PipelineCache, pipeline_layout.Ptr,
    [VK_DYNAMIC_STATE_SCISSOR, VK_DYNAMIC_STATE_VIEWPORT],
    [LabShaderStage(vs.Ptr), LabShaderStage(ps.Ptr)],
    render_pass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment], []),
    LabPipelineTesselationState(0)
  );
  frame_buffer := TLabFrameBuffer.Create(
    App.Device, render_pass,
    TextureBRDFLUT.Ptr.Width, TextureBRDFLUT.Ptr.Height,
    [TextureBRDFLUT.Ptr.View.Ptr.VkHandle]
  );
  cmd_tmp := TLabCommandBuffer.Create(App.CmdPool);
  cmd_tmp.Ptr.RecordBegin();
  cmd_tmp.Ptr.BeginRenderPass(
    render_pass.Ptr, frame_buffer.ptr,
    [LabClearValue(0.0, 0.0, 0.0, 1.0)]
  );
  cmd_tmp.Ptr.BindPipeline(pipeline_tmp.Ptr);
  cmd_tmp.Ptr.SetViewport([LabViewport(0, 0, TextureBRDFLUT.Ptr.Width, TextureBRDFLUT.Ptr.Height)]);
  cmd_tmp.Ptr.SetScissor(LabRect2D(0, 0, TextureBRDFLUT.Ptr.Width, TextureBRDFLUT.Ptr.Height));
  cmd_tmp.Ptr.Draw(3);
  cmd_tmp.Ptr.EndRenderPass;
  cmd_tmp.Ptr.RecordEnd;
  TLabVulkan.QueueSubmit(
    App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics,
    [cmd_tmp.Ptr.VkHandle],
    [],
    [],
    VK_NULL_HANDLE,
    TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
  );
  TLabVulkan.QueueWaitIdle(App.BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyGraphics);
end;

constructor TIBLight.Create;
  var ps_stage: TLabShaderStage;
begin
  App.OnBindOffscreenTargets.Add(@BindOffscreenTargets);
  App.OnUpdateTransforms.Add(@UpdateTransforms);
  App.BackBuffer.Ptr.OnResize.Add(@Resize);
  VertexShader := TLabVertexShader.Create(App.Device, 'shaders/pbr/screen_vs.spv');
  if App.SampleCount <> VK_SAMPLE_COUNT_1_BIT then
  begin
    PixelShader := TLabPixelShader.Create(App.Device, 'shaders/pbr/env_ps_ms.spv');
    ps_stage := LabShaderStage(
      PixelShader.Ptr,
      @App.SampleCount, SizeOf(App.SampleCount),
      LabSpecializationMapEntry(0, 0, SizeOf(App.SampleCount))
    );
  end
  else
  begin
    PixelShader := TLabPixelShader.Create(App.Device, 'shaders/pbr/env_ps.spv');
    ps_stage := LabShaderStage(PixelShader.Ptr)
  end;
  LoadEnvMap;
  GenerateIrradianceMap;
  GeneratePrefilteredMap;
  GenerateBRDFLUT;
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request([
    LabDescriptorSetBindings(
      [
        LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER),
        LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE),
        LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE),
        LabDescriptorBinding(3, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE),
        LabDescriptorBinding(4, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE),
        LabDescriptorBinding(5, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE),
        LabDescriptorBinding(6, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
        LabDescriptorBinding(7, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
        LabDescriptorBinding(8, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER)
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
    [LabShaderStage(VertexShader.Ptr), ps_stage],
    App.BackBuffer.Ptr.RenderPass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment],[]),
    LabPipelineTesselationState(0)
  );
  UniformBuffer := TUniformBuffer.Create(App.Device);
  UniformData := UniformBuffer.Ptr.Buffer;
  Resize([App.BackBuffer.Ptr.SwapChain.Ptr.Width, App.BackBuffer.Ptr.SwapChain.Ptr.Height]);
end;

destructor TIBLight.Destroy;
begin
  if App.BackBuffer.IsValid then App.BackBuffer.Ptr.OnResize.Remove(@Resize);
  App.OnUpdateTransforms.Remove(@UpdateTransforms);
  App.OnBindOffscreenTargets.Remove(@BindOffscreenTargets);
  inherited Destroy;
end;

procedure TIBLight.UpdateTransforms(const Params: array of const);
  var xf: PTransforms;
begin
  xf := PTransforms(Params[0].VPointer);
  UniformData^.vp_i := (xf^.View * xf^.Projection * xf^.Clip).Inverse;
  UniformData^.camera_pos := LabVec4(LabMatViewPos(xf^.View), 1);
  UniformData^.exposure := 4.5;
  UniformData^.gamma := 2.2;
end;

procedure TIBLight.BindOffscreenTargets(const Params: array of const);
  var i: TVkInt32;
  var Writes: array of TLabWriteDescriptorSet;
  const binding_count = 9;
begin
  SetLength(Writes, App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount * binding_count);
  for i := 0 to App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount - 1 do
  begin
    Writes[i * binding_count + 0] := LabWriteDescriptorSetUniformBuffer(
      DescriptorSets.Ptr.VkHandle[i],
      0,
      [LabDescriptorBufferInfo(UniformBuffer.Ptr.VkHandle)]
    );
    Writes[i * binding_count + 1] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      1,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Color.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 2] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      2,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Depth.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 3] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      3,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Normals.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 4] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      4,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Material.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 5] := LabWriteDescriptorSetImage(
      DescriptorSets.Ptr.VkHandle[i],
      5,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.SSAO.Ptr.RenderTarget.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 6] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      6,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          TextureIrradiance.Ptr.View.Ptr.VkHandle,
          TextureIrradiance.Ptr.Sampler.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 7] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      7,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          TexturePrefiltered.Ptr.View.Ptr.VkHandle,
          TexturePrefiltered.Ptr.Sampler.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 8] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      8,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          TextureBRDFLUT.Ptr.View.Ptr.VkHandle,
          TextureBRDFLUT.Ptr.Sampler.Ptr.VkHandle
        )
      ]
    );
  end;
  DescriptorSets.Ptr.UpdateSets(Writes, []);
end;

procedure TIBLight.Draw(const Cmd: TLabCommandBuffer);
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
    if Assigned(Scene.Ptr.CameraInst) then
    begin
      View := Scene.Ptr.CameraInst.View;
    end
    else
    begin
      View := LabMatView(LabVec3(-5, 8, -10), LabVec3, LabVec3(0, 1, 0));
    end;
    //World := LabMatIdentity;
    //World := LabMatRotationY(LabTwoPi * 0.01);
    World := LabMatRotationY((LabTimeLoopSec(30) / 30) * Pi * 2);
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
  SampleCount := Device.Ptr.PhysicalDevice.Ptr.GetSupportedSampleCount(
    [
      //VK_SAMPLE_COUNT_8_BIT,
      VK_SAMPLE_COUNT_4_BIT,
      VK_SAMPLE_COUNT_2_BIT
    ]
  );
  SampleCount := VK_SAMPLE_COUNT_1_BIT;
  DescriptorSetsFactory := TLabDescriptorSetsFactory.Create(Device);
  BackBuffer := TBackBuffer.Create(Window, Device, [], [], [@UpdateRenderTargets]);
  DeferredBuffer := TDeferredBuffer.Create(BackBuffer, []);
  CmdPool := TLabCommandPool.Create(Device, BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyIndexGraphics);
  CmdPoolCompute := TLabCommandPool.Create(Device, BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyIndexCompute);
  Cmd := TLabCommandBuffer.Create(CmdPool);
  PipelineCache := TLabPipelineCache.Create(Device);
  DitherMask := TTexture.Create('../Images/dither_mask.png', False, False);
  Scene := TScene.Create;
  //LightData := TLightData.Create;
  SSAO := TPostProcessSSAO.Create;
  Lighting := TIBLight.Create;
  Fence := TLabFence.Create(Device);
  TransferBuffers;
  OnBindOffscreenTargets.Call([]);
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  Lighting := nil;
  //LightData := nil;
  DeferredBuffer := nil;
  SSAO := nil;
  DitherMask := nil;
  BackBuffer := nil;
  Scene := nil;
  Fence := nil;
  PipelineCache := nil;
  Cmd := nil;
  CmdPool := nil;
  CmdPoolCompute := nil;
  DescriptorSetsFactory := nil;
  Device := nil;
  Window := nil;
  Free;
end;

procedure TLabApp.Loop;
  var cur_buffer: TVkUInt32;
begin
  TLabVulkan.IsActive := Window.Ptr.IsActive;
  if not BackBuffer.Ptr.FrameStart then Exit;
  UpdateTransforms;
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
    [LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(1, 0), LabClearValue(0, 0, 0, 0), LabClearValue(0, 0, 0, 0), LabClearValue(1, 0)]
  );
  Scene.Ptr.Draw(Cmd.Ptr);
  //Cube.Ptr.Draw(Cmd.Ptr);
  Cmd.Ptr.EndRenderPass;
  SSAO.Ptr.Draw(Cmd.Ptr);
  Cmd.Ptr.BeginRenderPass(
    BackBuffer.Ptr.RenderPass.Ptr, BackBuffer.Ptr.FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.0, 0.0, 0.0, 1.0), LabClearValue(1.0, 0)]
  );
  Lighting.Ptr.Draw(Cmd.Ptr);
  //LightData.Ptr.Draw(Cmd.Ptr, cur_buffer);
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

end.
