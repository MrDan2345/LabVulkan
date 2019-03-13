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

  TLight = class (TLabClass)
  public
    type TDepthData = packed record
      v: TLabMat;
      p: TLabMat;
      vp: TLabMat;
      vp_i: TLabMat;
    end;
    type PDepthData = ^TDepthData;
    type TUniformBufferDepth = specialize TLabUniformBuffer<TDepthData>;
    type TUniformBufferDepthShared = specialize TLabSharedRef<TUniformBufferDepth>;
    type TLightData = packed record
      VP_i: TLabMat;
      VP_Light: TLabMat;
      ScreenRatio: TLabVec4;
      CameraPos: TLabVec4;
      LightDir: TLabVec4;
      LightColor: TLabVec4;
    end;
    type PLightData = ^TLightData;
    type TUniformBufferLight = specialize TLabUniformBuffer<TLightData>;
    type TUniformBufferLightShared = specialize TLabSharedRef<TUniformBufferLight>;
    var Inst: TLabSceneNodeAttachmentLight;
    var DepthRT: TRenderTarget;
    var DepthSampler: TLabSamplerShared;
    var DepthRenderPass: TLabRenderPassShared;
    var DepthFrameBuffer: TLabFrameBufferShared;
    var DepthUniformBuffer: TUniformBufferDepthShared;
    var DepthData: PDepthData;
    var DepthPipelineLayout: TLabPipelineLayoutShared;
    var DepthDescriptorSets: TLabDescriptorSetsShared;
    var LightVS: TLabVertexShaderShared;
    var LightPS: TLabPixelShaderShared;
    var LightDescriptorSets: TLabDescriptorSetsShared;
    var LightPipeline: TLabPipelineShared;
    var LightPipelineLayout: TLabPipelineLayoutShared;
    var LightUniformBuffer: TUniformBufferLightShared;
    var LightData: PLightData;
    procedure Resize(const Params: array of const);
    procedure UpdateTransforms(const Params: array of const);
    procedure BindOffscreenTargets(const Params: array of const);
    constructor Create(const LightInst: TLabSceneNodeAttachmentLight);
    destructor Destroy; override;
    procedure Draw(const Cmd: TLabCommandBuffer);
  end;
  TLightShared = specialize TLabSharedRef<TLight>;

  TScene = class (TLabClass)
  public
    type TUniformGlobal = packed record
      time: TLabVec4;
    end;
    type TUniformBufferGlobal = specialize TLabUniformBuffer<TUniformGlobal>;
    type TUniformBufferGlobalShared = specialize TLabSharedRef<TUniformBufferGlobal>;
    type TUniformView = packed record
      v: TLabMat;
      p: TLabMat;
      vp: TLabMat;
      vp_i: TLabMat;
    end;
    type TUniformBufferView = specialize TLabUniformBuffer<TUniformView>;
    type TUniformBufferViewShared = specialize TLabSharedRef<TUniformBufferView>;
    type TUniformInstance = packed record
      w: TLabMat;
    end;
    type TUniformBufferInstance = specialize TLabUniformBufferDynamic<TUniformInstance>;
    type TUniformBufferInstanceShared = specialize TLabSharedRef<TUniformBufferInstance>;
    type TUniformBufferJoint = specialize TLabUniformBuffer<TLabMat>;
    type TUniformBufferJointShared = specialize TLabSharedRef<TUniformBufferJoint>;
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
        var ShaderDepth: TLabSceneShaderShared;
        var PipelineLayout: TLabPipelineLayoutShared;
        var PipelineLayoutDepth: TLabPipelineLayoutShared;
        var Images: array of TTexture;
        var Pipeline: TLabPipelineShared;
        var PipelineDepth: TLabPipelineShared;
      end;
      type TPassList = specialize TLabList<TPass>;
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
      var JointUniformBuffer: TUniformBufferJoint;
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
    var LightInst: array of TLightShared;
    constructor Create;
    destructor Destroy; override;
    procedure Draw(const Cmd: TLabCommandBuffer);
    procedure DrawDepth(const Cmd: TLabCommandBuffer);
    procedure DrawLights(const Cmd: TLabCommandBuffer);
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

procedure TLight.Resize(const Params: array of const);
  var w, h: TVkUInt32;
begin
  w := TVkUInt32(Params[0].VInteger);
  h := TVkUInt32(Params[1].VInteger);
  LightData^.ScreenRatio := LabVec4(w, h, 1 / w, 1 / h);
end;

procedure TLight.UpdateTransforms(const Params: array of const);
  var xf: PTransforms;
  var light_v: TLabMat;
  var light_p: TLabMat;
begin
  xf := PTransforms(Params[0].VPointer);
  light_v := LabMatView(Inst.LightPos, Inst.LightPos + Inst.LightDir, Inst.LightUp);
  //light_p := LabMatProj(90 * LabDegToRad, 1, 1, 1000);
  light_p := LabMatOrth(50, 50, 1, 1000);
  DepthData^.v := light_v;
  DepthData^.p := light_p;
  DepthData^.vp := light_v * light_p * xf^.Clip;
  DepthData^.vp_i := (light_v * light_p * xf^.Clip).Inverse;
  DepthUniformBuffer.Ptr.FlushAll;
  LightData^.VP_i := (xf^.View * xf^.Projection * xf^.Clip).Inverse;
  LightData^.VP_Light := light_v * light_p * xf^.Clip;
  LightData^.CameraPos := LabVec4(LabMatViewPos(xf^.View), 1);
  LightData^.LightDir := LabVec4(Inst.LightDir, 0);
  LightData^.LightColor := LabVec4(Inst.LightColor, 0);
  LightUniformBuffer.Ptr.FlushAll;
  //UniformData^.exposure := 4.5;
  //UniformData^.gamma := 2.2;
end;

procedure TLight.BindOffscreenTargets(const Params: array of const);
  var i: TVkInt32;
  var Writes: array of TLabWriteDescriptorSet;
  const binding_count = 6;
begin
  SetLength(Writes, App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount * binding_count);
  for i := 0 to App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount - 1 do
  begin
    Writes[i * binding_count + 0] := LabWriteDescriptorSetUniformBuffer(
      LightDescriptorSets.Ptr.VkHandle[i],
      0,
      [LabDescriptorBufferInfo(LightUniformBuffer.Ptr.VkHandle)]
    );
    Writes[i * binding_count + 1] := LabWriteDescriptorSetImage(
      LightDescriptorSets.Ptr.VkHandle[i],
      1,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Color.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 2] := LabWriteDescriptorSetImage(
      LightDescriptorSets.Ptr.VkHandle[i],
      2,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Depth.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 3] := LabWriteDescriptorSetImage(
      LightDescriptorSets.Ptr.VkHandle[i],
      3,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Normals.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 4] := LabWriteDescriptorSetImage(
      LightDescriptorSets.Ptr.VkHandle[i],
      4,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          App.DeferredBuffer.Ptr.RenderTargets[i].Material.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 5] := LabWriteDescriptorSetImageSampler(
      LightDescriptorSets.Ptr.VkHandle[i],
      5,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          DepthRT.View.Ptr.VkHandle,
          DepthSampler.Ptr.VkHandle
        )
      ]
    );
  end;
  LightDescriptorSets.Ptr.UpdateSets(Writes, []);
end;

constructor TLight.Create(const LightInst: TLabSceneNodeAttachmentLight);
begin
  App.OnBindOffscreenTargets.Add(@BindOffscreenTargets);
  App.OnUpdateTransforms.Add(@UpdateTransforms);
  App.BackBuffer.Ptr.OnResize.Add(@Resize);
  Inst := LightInst;
  DepthRT.SetupImage(
    1024, 1024, VK_FORMAT_D32_SFLOAT,
    TVkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT)
    or TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
    VK_SAMPLE_COUNT_1_BIT
  );
  DepthSampler := TLabSampler.Create(
    App.Device, VK_FILTER_NEAREST, VK_FILTER_NEAREST,
    VK_SAMPLER_ADDRESS_MODE_REPEAT,
    VK_SAMPLER_ADDRESS_MODE_REPEAT,
    VK_SAMPLER_ADDRESS_MODE_REPEAT,
    //VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    //VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    //VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
    VK_FALSE,
    1, VK_SAMPLER_MIPMAP_MODE_NEAREST,
    0, 0, 0
  );
  DepthUniformBuffer := TUniformBufferDepth.Create(
    App.Device, 1, TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  DepthData := DepthUniformBuffer.Ptr.Buffer;
  DepthDescriptorSets := App.DescriptorSetsFactory.Ptr.Request(
    [LabDescriptorSetBindings(
      LabDescriptorBinding(
        0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
      )
    )]
  );
  DepthPipelineLayout := TLabPipelineLayout.Create(
    App.Device, [], [DepthDescriptorSets.Ptr.Layout[0].Ptr]
  );
  DepthRenderPass := TLabRenderPass.Create(
    App.Device,
    [
      LabAttachmentDescription(
        VK_FORMAT_D32_SFLOAT,
        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        VK_SAMPLE_COUNT_1_BIT,
        VK_ATTACHMENT_LOAD_OP_CLEAR,
        VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        VK_ATTACHMENT_STORE_OP_DONT_CARE
      )
    ],
    [
      LabSubpassDescriptionData(
        [],
        [],
        [],
        LabAttachmentReference(0, VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL),
        []
      )
    ],
    [
      LabSubpassDependency(
        VK_SUBPASS_EXTERNAL,
        0,
        TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
        TVkFlags(VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT),
        TVkFlags(VK_ACCESS_MEMORY_READ_BIT),
        TVkFlags(VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
      ),
      LabSubpassDependency(
        0,
        VK_SUBPASS_EXTERNAL,
        TVkFlags(VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT),
        TVkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
        TVkFlags(VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT) or TVkFlags(VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT),
        TVkFlags(VK_ACCESS_MEMORY_READ_BIT),
        TVkFlags(VK_DEPENDENCY_BY_REGION_BIT)
      )
    ]
  );
  DepthFrameBuffer := TLabFrameBuffer.Create(
    App.Device, DepthRenderPass, DepthRT.Image.Ptr.Width, DepthRT.Image.Ptr.Height,
    [DepthRT.View.Ptr.VkHandle]
  );
  LightVS := TLabVertexShader.Create(App.Device, 'screen_vs.spv');
  LightPS := TLabPixelShader.Create(App.Device, 'light_ps.spv');
  LightDescriptorSets := App.DescriptorSetsFactory.Ptr.Request(
    [
      LabDescriptorSetBindings(
        [
          LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
          LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
          LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
          LabDescriptorBinding(3, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
          LabDescriptorBinding(4, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT)),
          LabDescriptorBinding(5, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
        ],
        App.BackBuffer.Ptr.SwapChain.Ptr.ImageCount
      )
    ]
  );
  LightPipelineLayout := TLabPipelineLayout.Create(
    App.Device, [], [LightDescriptorSets.Ptr.Layout[0].Ptr]
  );
  LightPipeline := TLabGraphicsPipeline.FindOrCreate(
    App.Device, App.PipelineCache, LightPipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_SCISSOR, VK_DYNAMIC_STATE_VIEWPORT],
    [LabShaderStage(LightVS.Ptr), LabShaderStage(LightPS.Ptr)],
    App.BackBuffer.Ptr.RenderPass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState, VK_FALSE, VK_FALSE),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState(
      [
        LabPipelineColorBlendAttachmentState(
          VK_TRUE, VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE
        )
      ], []
    ),
    LabPipelineTesselationState(0)
  );
  LightUniformBuffer := TUniformBufferLight.Create(App.Device, 1, TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT));
  LightData := LightUniformBuffer.Ptr.Buffer;
  Resize([App.BackBuffer.Ptr.SwapChain.Ptr.Width, App.BackBuffer.Ptr.SwapChain.Ptr.Height]);
end;

destructor TLight.Destroy;
begin
  if App.BackBuffer.IsValid then
  begin
    App.BackBuffer.Ptr.OnResize.Remove(@Resize);
  end;
  App.OnUpdateTransforms.Remove(@UpdateTransforms);
  App.OnBindOffscreenTargets.Remove(@BindOffscreenTargets);
  inherited Destroy;
end;

procedure TLight.Draw(const Cmd: TLabCommandBuffer);
begin
  Cmd.BindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS, LightPipelineLayout.Ptr, 0, [LightDescriptorSets.Ptr.VkHandle[0]], []);
  Cmd.BindPipeline(LightPipeline.Ptr);
  Cmd.Draw(3);
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
  var ParamsDepth: TLabSceneShaderParameters;
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
    if Assigned(Skin) then Inc(pc);
    SetLength(ParamsDepth, pc);
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
    ParamsDepth[pc] := Params[pc];
    Inc(pc);
    Params[pc] := LabSceneShaderParameterUniform(
      _Scene.UniformBufferView.Ptr.VkHandle, [], TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
    );
    ParamsDepth[pc] := LabSceneShaderParameterUniform(
      _Scene.LightInst[0].Ptr.DepthUniformBuffer.Ptr.VkHandle, [], TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
    );
    Inc(pc);
    Params[pc] := LabSceneShaderParameterUniformDynamic(
      _Scene.UniformBufferInstance.Ptr.VkHandle, [], TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
    );
    ParamsDepth[pc] := Params[pc];
    Inc(pc);
    if Assigned(Skin) then
    begin
      Params[pc] := LabSceneShaderParameterUniform(
        JointUniformBuffer.VkHandle, [], TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
      );
      ParamsDepth[pc] := Params[pc];
      Inc(pc);
    end;
    Pass.ShaderDepth := TLabSceneShaderFactory.MakeShader(App.Device, r_s.VertexDescriptor, ParamsDepth, si_ptr, nil, True);
    Pass.PipelineLayoutDepth := TLabPipelineLayout.Create(App.Device, [], [Pass.ShaderDepth.Ptr.DescriptorSetLayout.Ptr]);
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
  JointUniformBuffer := TUniformBufferJoint.Create(App.Device, Length(Skin.Joints));
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
      end
      else if (Node.Attachments[i] is TLabSceneNodeAttachmentLight)
      and (TLabSceneNodeAttachmentLight(Node.Attachments[i]).Light.LightType = lt_directional) then
      begin
        SetLength(LightInst, Length(LightInst) + 1);
        LightInst[High(LightInst)] := TLight.Create(TLabSceneNodeAttachmentLight(Node.Attachments[i]));
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
  LightInst := nil;
  inst_count := 0;
  ProcessNode(Scene.Root);
  UniformBufferGlobal := TUniformBufferGlobal.Create(App.Device, 1, TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT));
  UniformBufferView := TUniformBufferView.Create(App.Device, 1, TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT));
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
  UpdateNode(Scene.Root);
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
  UniformBufferView.Ptr.FlushAll;
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
  Scene.Add('../Models/scene.dae');
  //Scene.Add('../Models/maya/maya_anim.dae');
  //Scene.Add('../Models/Cerberus/cerberus.dae');
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

procedure TScene.DrawDepth(const Cmd: TLabCommandBuffer);
  var cur_pipeline: TLabGraphicsPipeline;
  procedure RenderNode(const Node: TLabSceneNode; const Light: TLight);
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
        if not r_p.PipelineDepth.IsValid then
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
          r_p.PipelineDepth := TLabGraphicsPipeline.FindOrCreate(
            App.Device, App.PipelineCache, r_p.PipelineLayoutDepth.Ptr,
            [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
            [
              LabShaderStage(r_p.ShaderDepth.Ptr.VertexShader.Ptr.Shader),
              LabShaderStage(r_p.ShaderDepth.Ptr.PixelShader.Ptr.Shader)
            ],
            Light.DepthRenderPass.Ptr, 0,
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
            LabPipelineMultisampleState(VK_SAMPLE_COUNT_1_BIT),
            LabPipelineColorBlendState([LabDefaultColorBlendAttachment],[]),
            LabPipelineTesselationState(0)
          );
        end;
        if not Assigned(cur_pipeline)
        or (cur_pipeline.Hash <> TLabGraphicsPipeline(r_p.PipelineDepth.Ptr).Hash) then
        begin
          cur_pipeline := TLabGraphicsPipeline(r_p.PipelineDepth.Ptr);
          Cmd.BindPipeline(cur_pipeline);
        end;
        Cmd.BindDescriptorSets(
          VK_PIPELINE_BIND_POINT_GRAPHICS,
          r_p.PipelineLayoutDepth.Ptr,
          0, [r_p.ShaderDepth.Ptr.DescriptorSets.Ptr.VkHandle[0]], [UniformBufferInstance.Ptr.BufferOffset[nd.UniformOffset]]
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
      RenderNode(Node.Children[i], Light);
    end;
  end;
  var i: Integer;
begin
  for i := 0 to High(LightInst) do
  begin
    Cmd.BeginRenderPass(
      LightInst[i].Ptr.DepthRenderPass.Ptr,
      LightInst[i].Ptr.DepthFrameBuffer.Ptr,
      [LabClearValue(1, 0)]
    );
    Cmd.SetScissor([
      LabRect2D(
        0, 0,
        LightInst[i].Ptr.DepthRT.Image.Ptr.Width,
        LightInst[i].Ptr.DepthRT.Image.Ptr.Height
      )
    ]);
    Cmd.SetViewport([
      LabViewport(
        0, 0,
        LightInst[i].Ptr.DepthRT.Image.Ptr.Width,
        LightInst[i].Ptr.DepthRT.Image.Ptr.Height
      )
    ]);
    RenderNode(Scene.Root, LightInst[i].Ptr);
    Cmd.EndRenderPass;
  end;
end;

procedure TScene.DrawLights(const Cmd: TLabCommandBuffer);
  var i: Integer;
begin
  for i := 0 to High(LightInst) do
  begin
    LightInst[i].Ptr.Draw(Cmd);
  end;
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
  const DepthFormats = [
    VK_FORMAT_D16_UNORM,
    VK_FORMAT_D16_UNORM_S8_UINT,
    VK_FORMAT_D24_UNORM_S8_UINT,
    VK_FORMAT_D32_SFLOAT,
    VK_FORMAT_D32_SFLOAT_S8_UINT
  ];
  var ImageAspectFlags: TVkImageAspectFlags;
begin
  Image := TLabImage.Create(
    App.Device, Format, Usage or TVkFlags(VK_IMAGE_USAGE_SAMPLED_BIT), [],
    Width, Height, 1, 1, 1, SampleCount, VK_IMAGE_TILING_OPTIMAL,
    VK_IMAGE_TYPE_2D, VK_SHARING_MODE_EXCLUSIVE, TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  );
  if Format in DepthFormats then
  begin
    ImageAspectFlags := TVkFlags(VK_IMAGE_ASPECT_DEPTH_BIT);
  end
  else
  begin
    ImageAspectFlags := TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT);
  end;
  View := TLabImageView.Create(
    App.Device, Image.Ptr.VkHandle,
    Image.Ptr.Format, ImageAspectFlags
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
    //View := LabMatView(
    //  Scene.Ptr.LightInst[0].Ptr.Inst.LightPos,
    //  Scene.Ptr.LightInst[0].Ptr.Inst.LightPos + Scene.Ptr.LightInst[0].Ptr.Inst.LightDir,
    //  Scene.Ptr.LightInst[0].Ptr.Inst.LightUp
    //);
    World := LabMatIdentity;
    //World := LabMatRotationY((LabTimeLoopSec(15) / 15) * Pi * 2);
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
  Window.Ptr.Caption := 'Vulkan Shadow';
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
  BackBuffer := TBackBuffer.Create(Window, Device, [], [], []);
  DeferredBuffer := TDeferredBuffer.Create(BackBuffer, [@UpdateRenderTargets]);
  CmdPool := TLabCommandPool.Create(Device, BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyIndexGraphics);
  CmdPoolCompute := TLabCommandPool.Create(Device, BackBuffer.Ptr.SwapChain.Ptr.QueueFamilyIndexCompute);
  Cmd := TLabCommandBuffer.Create(CmdPool);
  PipelineCache := TLabPipelineCache.Create(Device);
  Scene := TScene.Create;
  Fence := TLabFence.Create(Device);
  TransferBuffers;
  OnBindOffscreenTargets.Call([]);
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  DeferredBuffer := nil;
  Scene := nil;
  BackBuffer := nil;
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
  Cmd.Ptr.EndRenderPass;
  Scene.Ptr.DrawDepth(Cmd.Ptr);
  Cmd.Ptr.BeginRenderPass(
    BackBuffer.Ptr.RenderPass.Ptr, BackBuffer.Ptr.FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.0, 0.0, 0.0, 1.0), LabClearValue(1.0, 0)]
  );
  Cmd.Ptr.SetViewport([LabViewport(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  Cmd.Ptr.SetScissor([LabRect2D(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  Scene.Ptr.DrawLights(Cmd.Ptr);
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
