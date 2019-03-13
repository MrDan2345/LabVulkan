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

  TMyTexture2D = class (TLabTexture2D)
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

  TMyTextureCube = class (TLabTextureCube)
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
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
    type TUniformBufferArray = specialize TLabUniformBufferDynamic<TUniformData>;
    type TUniformBufferArrayShared = specialize TLabSharedRef<TUniformBufferArray>;
    var UniformBuffer: TUniformBufferArrayShared;
    type TMaterial = packed record
      Roughness: TVkFloat;
      Metallic: TVkFloat;
    end;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    const arr_size = 10;
  public
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
    type TUniformBuffer = specialize TLabUniformBuffer<TUniformData>;
    type TUniformBufferShared = specialize TLabSharedRef<TUniformBuffer>;
    var UniformBuffer: TUniformBufferShared;
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
    var LightingIB: TIBLightShared;
    var LightingPoint: TLightShared;
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

procedure TMyTextureCube.AfterConstruction;
begin
  inherited AfterConstruction;
  App.OnStage.Add(@Stage);
  App.OnStageComplete.Add(@StageComplete);
end;

procedure TMyTextureCube.BeforeDestruction;
begin
  App.OnStageComplete.Remove(@StageComplete);
  App.OnStage.Remove(@Stage);
  inherited BeforeDestruction;
end;

procedure TMyTexture2D.AfterConstruction;
begin
  inherited AfterConstruction;
  App.OnStage.Add(@Stage);
  App.OnStageComplete.Add(@StageComplete);
end;

procedure TMyTexture2D.BeforeDestruction;
begin
  App.OnStageComplete.Remove(@StageComplete);
  App.OnStage.Remove(@Stage);
  inherited BeforeDestruction;
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
    tex_size, VK_FORMAT_R32G32B32A32_SFLOAT,
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
  vs := TLabVertexShader.Create(App.Device, 'cube_map_vs.spv');
  ps := TLabPixelShader.Create(App.Device, 'gen_cube_map_ps.spv');
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
    tex_size, VK_FORMAT_R32G32B32A32_SFLOAT,
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
  vs := TLabVertexShader.Create(App.Device, 'cube_map_vs.spv');
  ps := TLabPixelShader.Create(App.Device, 'gen_irradiance_map_ps.spv');
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
  const tex_size = 1024;
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
    tex_size, VK_FORMAT_R32G32B32A32_SFLOAT,
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
  vs := TLabVertexShader.Create(App.Device, 'cube_map_vs.spv');
  ps := TLabPixelShader.Create(App.Device, 'gen_prefiltered_map_ps.spv');
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
  vs := TLabVertexShader.Create(App.Device, 'brdflut_vs.spv');
  ps := TLabPixelShader.Create(App.Device, 'brdflut_ps.spv');
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
begin
  App.OnBindOffscreenTargets.Add(@BindOffscreenTargets);
  App.OnUpdateTransforms.Add(@UpdateTransforms);
  App.BackBuffer.Ptr.OnResize.Add(@Resize);
  VertexShader := TLabVertexShader.Create(App.Device, 'screen_vs.spv');
  PixelShader := TLabPixelShader.Create(App.Device, 'env_ps.spv');
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
        LabDescriptorBinding(5, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
        LabDescriptorBinding(6, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
        LabDescriptorBinding(7, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER)
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
  UniformBuffer := TUniformBuffer.Create(App.Device);
  UniformData := UniformBuffer.Ptr.Buffer;
  Resize([App.BackBuffer.Ptr.SwapChain.Ptr.Width, App.BackBuffer.Ptr.SwapChain.Ptr.Height]);
end;

destructor TIBLight.Destroy;
begin
  UniformBuffer.Ptr.Unmap;
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
  const binding_count = 8;
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
          App.DeferredBuffer.Ptr.RenderTargets[i].PhysParams.View.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 5] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      5,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          TextureIrradiance.Ptr.View.Ptr.VkHandle,
          TextureIrradiance.Ptr.Sampler.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 6] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      6,
      [
        LabDescriptorImageInfo(
          VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
          TexturePrefiltered.Ptr.View.Ptr.VkHandle,
          TexturePrefiltered.Ptr.Sampler.Ptr.VkHandle
        )
      ]
    );
    Writes[i * binding_count + 7] := LabWriteDescriptorSetImageSampler(
      DescriptorSets.Ptr.VkHandle[i],
      7,
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
  VertexShader := TLabVertexShader.Create(App.Device, 'screen_vs.spv');
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
    LabPipelineColorBlendState([
      LabPipelineColorBlendAttachmentState(
        VK_TRUE, VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE, VK_BLEND_FACTOR_ONE
      )
    ],[]),
    LabPipelineTesselationState(0)
  );
  UniformBuffer := TUniformBuffer.Create(App.Device, SizeOf(TUniformData));
  UniformData := UniformBuffer.Ptr.Buffer;
  Resize([App.BackBuffer.Ptr.SwapChain.Ptr.Width, App.BackBuffer.Ptr.SwapChain.Ptr.Height]);
end;

destructor TLight.Destroy;
begin
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
  UniformBuffer := TUniformBufferArray.Create(App.Device, arr_size * arr_size, TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT));
  VertexShader := TLabVertexShader.Create(App.Device, 'sphere_vs.spv');
  TessCtrlShader := TLabTessControlShader.Create(App.Device, 'sphere_tcs.spv');
  TessEvalShader := TLabTessEvaluationShader.Create(App.Device, 'sphere_tes.spv');
  PixelShader := TLabPixelShader.Create(App.Device, 'sphere_ps.spv');
  DescriptorSets := App.DescriptorSetsFactory.Ptr.Request([
      LabDescriptorSetBindings([
        LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, 1, TVkFlags(VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT))
      ])
  ]);
  DescriptorSets.Ptr.UpdateSets([
    LabWriteDescriptorSetUniformBufferDynamic(
      DescriptorSets.Ptr.VkHandle[0], 0, LabDescriptorBufferInfo(UniformBuffer.Ptr.VkHandle))
  ], []);
  PipelineLayout := TLabPipelineLayout.Create(
    App.Device,
    [LabPushConstantRange(TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT), 0, SizeOf(TMaterial))],
    [DescriptorSets.Ptr.Layout[0].Ptr]
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
  var w: TLabMat;
  var i_x, i_y: TVkUInt32;
  var s_x, s_y: Single;
  const offset_x = 10;
  const offset_y = 10;
begin
  xf := PTransforms(Params[0].VPointer);
  for i_y := 0 to arr_size - 1 do
  for i_x := 0 to arr_size - 1 do
  begin
    s_x := i_x / (arr_size - 1);
    s_y := i_y / (arr_size - 1);
    w := LabMatTranslation(
      offset_x * (s_x * 2 - 1),
      0,
      offset_y * (s_y * 2 - 1)
    );
    UniformBuffer.Ptr[i_y * arr_size + i_x]^.wvp := w * xf^.WVP;
    UniformBuffer.Ptr[i_y * arr_size + i_x]^.w := w * xf^.World;
  end;
end;

procedure TScene.Draw(const Cmd: TLabCommandBuffer);
  var i, i_x, i_y: TVkUInt32;
  var s_x, s_y: Single;
  var m: TMaterial;
begin
  Cmd.BindPipeline(Pipeline.Ptr);
  for i_y := 0 to arr_size - 1 do
  for i_x := 0 to arr_size - 1 do
  begin
    s_x := i_x / (arr_size - 1);
    s_y := i_y / (arr_size - 1);
    i := i_y * arr_size + i_x;
    m.Roughness := s_x;
    m.Metallic := s_y;
    Cmd.PushConstants(PipelineLayout.Ptr, TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT), 0, SizeOf(TMaterial), @m);
    Cmd.BindDescriptorSets(
      VK_PIPELINE_BIND_POINT_GRAPHICS, PipelineLayout.Ptr, 0,
      [DescriptorSets.Ptr.VkHandle[0]],
      [UniformBuffer.Ptr.BufferOffset[i]]
    );
    Cmd.Draw(24);
  end;
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
    View := LabMatView(
      LabVec3(cos(LabTimeLoopSec(30) / 30 * Pi * 2) * 20, sin(LabTimeLoopSec(155) / 155 * Pi * 2) * 20, sin(LabTimeLoopSec(30) / 30 * Pi * 2) * 20),
      LabVec3(0, 0, -2), LabVec3(0, 1, 0)
    );
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
  LightingIB := TIBLight.Create;
  LightingPoint := TLight.Create;
  Fence := TLabFence.Create(Device);
  TransferBuffers;
  OnBindOffscreenTargets.Call([]);
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  Scene := nil;
  LightingIB := nil;
  LightingPoint := nil;
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
  LightingIB.Ptr.Draw(Cmd.Ptr);
  //LightingPoint.Ptr.Draw(Cmd.Ptr);
end;

end.
