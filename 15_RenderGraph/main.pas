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
  LabFrameBuffer,
  LabPlatform,
  LabSync,
  LabUtils,
  LabScene,
  LabColladaParser,
  LabRenderGraph,
  Classes,
  SysUtils;

type
  TFrameGraph = class (TLabClass)
  public
    type TAttachment = class
    private
      var _Name: AnsiString;
    protected
      var _Format: TVkFormat;
    public
      property Name: AnsiString read _Name;
      property Format: TVkFormat read _Format;
      constructor Create(const AName: AnsiString; const AFormat: TVkFormat);
    end;
    type TAttachmentList = specialize TLabObjList<TAttachment>;
    type TPass = class
    public
      type TDependency = class
      private
        var _Pass: TPass;
        var _ForceSubpass: Boolean;
      public
        property Pass: TPass read _Pass;
        property ForceSubpass: Boolean read _ForceSubpass;
        constructor Create(const APass: TPass; const AForceSubpass: Boolean = False);
      end;
      type TDependencyList = specialize TLabObjList<TDependency>;
      type TAttachmentSlot = class
      private
        var _Attachment: TAttachment;
        var _PerRegion: Boolean;
        var _SlotLayout: TVkImageLayout;
      public
        property PerRegion: Boolean read _PerRegion write _PerRegion;
        property SlotLayout: TVkImageLayout read _SlotLayout write _SlotLayout;
        property Attachment: TAttachment read _Attachment;
        constructor Create(const AAttachment: TAttachment);
      end;
      type TSlotList = specialize TLabObjList<TAttachmentSlot>;
      type TSlotListTmp = specialize TLabList<TAttachmentSlot>;
      type TPassListTmp = specialize TLabList<TPass>;
    private
      var _Name: AnsiString;
      var _AttachmentsInput: TSlotList;
      var _AttachmentsColor: TSlotList;
      var _AttachmentDepth: TAttachmentSlot;
      var _Dependencies: TDependencyList;
    public
      property AttachmentsInput: TSlotList read _AttachmentsInput;
      property AttachmentsColor: TSlotList read _AttachmentsColor;
      property AttachmentDepth: TAttachmentSlot read _AttachmentDepth;
      property Dependencies: TDependencyList read _Dependencies;
      function AddAttachmentInput(const Attachment: TAttachment; const PerRegion: Boolean = False): TAttachmentSlot;
      function AddAttachmentColor(const Attachment: TAttachment): TAttachmentSlot;
      function SetAttachmentDepth(const Attachment: TAttachment): TAttachmentSlot;
      function HasInputAttachment(const Attachment: TAttachment; var PerRegion: Boolean): Boolean;
      function HasOutputAttachment(const Attachment: TAttachment): Boolean;
      constructor Create(const AName: AnsiString);
      destructor Destroy; override;
    end;
    type TPassList = specialize TLabObjList<TPass>;
    type TCompiledRenderPass = class
    public
      type TCompiledAttachmentSlot = class
      private
        var _Attachment: TAttachment;
        var _FirstLayout: TVkImageLayout;
        var _InitialLayout: TVkImageLayout;
        var _FinalLayout: TVkImageLayout;
        var _LoadOp: TVkAttachmentLoadOp;
        var _StoreOp: TVkAttachmentStoreOp;
        var _AttachmentIndex: TVkUInt32;
      public
        property Attachment: TAttachment read _Attachment;
        property FirstLayout: TVkImageLayout read _FinalLayout;
        property InitialLayout: TVkImageLayout read _InitialLayout write _InitialLayout;
        property FinalLayout: TVkImageLayout read _FinalLayout write _FinalLayout;
        property LoadOp: TVkAttachmentLoadOp read _LoadOp write _LoadOp;
        property StoreOp: TVkAttachmentStoreOp read _StoreOp write _StoreOp;
        property AttachmentIndex: TVkUInt32 read _AttachmentIndex write _AttachmentIndex;
        constructor Create(const AAttachment: TAttachment; const AFirstLayout: TVkImageLayout; const AIndex: TVkUInt32 = $ffffffff);
      end;
      type TCompiledSlotList = specialize TLabObjList<TCompiledAttachmentSlot>;
      type TCompiledRenderPassListTmp = specialize TLabList<TCompiledRenderPass>;
      var RenderPass: TLabRenderPassShared;
      var SubPassList: TPass.TPassListTmp;
      var Attachments: TCompiledSlotList;
      var Dependencies: TCompiledRenderPassListTmp;
      constructor Create;
      destructor Destroy; override;
      function DependsOnAttachment(const Attachment: TAttachment): TPass.TAttachmentSlot;
      function HasOutputAttachment(const Attachment: TAttachment): TCompiledAttachmentSlot;
      procedure AddAttachmentUnique(const Attachment: TAttachment; const FirstLayout: TVkImageLayout; const IgnoreIndex: TVkUint32);
    end;
    type TCompiledRenderPassList = specialize TLabObjList<TCompiledRenderPass>;
    type TCompiledRenderPassListShared = specialize TLabSharedRef<TCompiledRenderPassList>;
  private
    var _Device: TLabDeviceShared;
    var _PassList: TPassList;
    var _Attachments: TAttachmentList;
    var _CompiledRenderPasses: TCompiledRenderPassList;
  public
    property Device: TLabDeviceShared read _Device;
    property Passes: TPassList read _PassList;
    property CompiledRenderPasses: TCompiledRenderPassList read _CompiledRenderPasses;
    function NewPass(const AName: AnsiString): TPass;
    function NewAttachment(const AName: AnsiString): TAttachment;
    function NewAttachmentSwapChain(const AName: AnsiString; const ASwapChain: TLabSwapChainShared): TAttachmentSwapChain;
    function CompileRenderPasses: TCompiledRenderPassListShared;
    constructor Create(const ADevice: TLabDeviceShared);
    destructor Destroy; override;
  end;

  TLabApp = class (TLabVulkan)
  public
    var Window: TLabWindowShared;
    var Device: TLabDeviceShared;
    var Surface: TLabSurfaceShared;
    var SwapChain: TLabSwapChainShared;
    var CmdPool: TLabCommandPoolShared;
    var CmdBuffer: TLabCommandBufferShared;
    var Semaphore: TLabSemaphoreShared;
    var Fence: TLabFenceShared;
    var DepthBuffers: array of TLabDepthBufferShared;
    var FrameBuffers: array of TLabFrameBufferShared;
    var PipelineLayout: TLabPipelineLayoutShared;
    var Pipeline: TLabPipelineShared;
    var RenderPass: TLabRenderPassShared;
    var Shaders: TLabShaderGroupShared;
    var DescriptorSetsFactory: TLabDescriptorSetsFactoryShared;
    var DescriptorSets: TLabDescriptorSetsShared;
    var PipelineCache: TLabPipelineCacheShared;
    var UniformGlobal: TLabManagedUniformBufferShared;
    var UniformView: TLabManagedUniformBufferShared;
    var UniformInst: TLabManagedUniformBufferShared;
    var UniformData: TLabManagedUniformBufferShared;
    var CombinedShader: TLabCombinedShaderShared;
    constructor Create;
    procedure SwapchainCreate;
    procedure SwapchainDestroy;
    procedure UpdateTransforms;
    procedure TransferBuffers;
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
  end;

const
  FENCE_TIMEOUT = 100000000;

  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

var
  App: TLabApp;

implementation

constructor TFrameGraph.TCompiledRenderPass.TCompiledAttachmentSlot.Create(
  const AAttachment: TAttachment;
  const AFirstLayout: TVkImageLayout;
  const AIndex: TVkUInt32 = $ffffffff
);
begin
  _Attachment := AAttachment;
  _FirstLayout := AFirstLayout;
  _InitialLayout := VK_IMAGE_LAYOUT_UNDEFINED;
  _FinalLayout := VK_IMAGE_LAYOUT_UNDEFINED;
  _LoadOp := VK_ATTACHMENT_LOAD_OP_DONT_CARE;
  _StoreOp := VK_ATTACHMENT_STORE_OP_DONT_CARE;
  _AttachmentIndex := AIndex;
end;

constructor TFrameGraph.TCompiledRenderPass.Create;
begin
  SubPassList := TPass.TPassListTmp.Create;
  Attachments := TCompiledSlotList.Create;
  Dependencies := TCompiledRenderPassListTmp.Create;
end;

destructor TFrameGraph.TCompiledRenderPass.Destroy;
begin
  FreeAndNil(Dependencies);
  FreeAndNil(_Attachments);
  FreeAndNil(SubPassList);
  inherited Destroy;
end;

function TFrameGraph.TCompiledRenderPass.DependsOnAttachment(const Attachment: TAttachment): TPass.TAttachmentSlot;
  var i, j: TVkInt32;
begin
  for i := 0 to SubPassList.Count - 1 do
  for j := 0 to SubPassList[i].AttachmentsInput.Count - 1 do
  if SubPassList[i].AttachmentsInput[j].Attachment = Attachment then
  begin
    Exit(SubPassList[i].AttachmentsInput[j]);
  end;
  Exit(nil);
end;

function TFrameGraph.TCompiledRenderPass.HasOutputAttachment(const Attachment: TAttachment): TCompiledAttachmentSlot;
  var i, j: TVkInt32;
begin
  for i := 0 to SubPassList.Count - 1 do
  if SubPassList[i].HasOutputAttachment(Attachment) then
  begin
    for j := 0 to Attachments.Count - 1 do
    if Attachments[j].Attachment = Attachment then
    begin
      Exit(Attachments[j]);
    end;
  end;
  Exit(nil);
end;

procedure TFrameGraph.TCompiledRenderPass.AddAttachmentUnique(
  const Attachment: TAttachment;
  const FirstLayout: TVkImageLayout;
  const IgnoreIndex: TVkUint32
);
  var i: TVkInt32;
  var ind: TVkUInt32;
begin
  for i := 0 to Attachments.Count - 1 do
  if Attachments[i].Attachment = Attachment then
  begin
    Exit;
  end;
  if IgnoreIndex then
  begin
    ind := $ffffffff;
  end
  else
  begin
    ind := 0;
    for i := 0 to Attachments.Count - 1 do
    if (Attachments[i].AttachmentIndex <> $ffffffff)
    and (Attachments[i].AttachmentIndex >= ind) then
    begin
      ind := Attachments[i].AttachmentIndex + 1;
    end;
  end;
  Attachments.Add(TCompiledAttachmentSlot.Create(Attachment, FirstLayout, ind));
end;

constructor TFrameGraph.TPass.TDependency.Create(const APass: TPass; const AForceSubpass: Boolean);
begin
  Pass := APass;
  ForceSubpass := AForceSubpass;
end;

constructor TFrameGraph.TPass.TAttachmentSlot.Create(const AAttachment: TAttachment);
begin
  _SlotLayout := VK_IMAGE_LAYOUT_GENERAL;
  _Attachment := AAttachment;
end;

function TFrameGraph.TPass.AddAttachmentInput(const Attachment: TAttachment;
  const PerRegion: Boolean): TAttachmentSlot;
begin
  Result := TAttachmentSlot.Create(Attachment);
  Result.PerRegion := PerRegion;
  Result.SlotLayout := VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
  _AttachmentsInput.Add(Result);
end;

function TFrameGraph.TPass.AddAttachmentColor(const Attachment: TAttachment
  ): TAttachmentSlot;
begin
  Result := TAttachmentSlot.Create(Attachment);
  Result.SlotLayout := VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
  _AttachmentsColor.Add(Result);
end;

function TFrameGraph.TPass.SetAttachmentDepth(const Attachment: TAttachment
  ): TAttachmentSlot;
begin
  FreeAndNil(_AttachmentDepth);
  _AttachmentDepth := TAttachmentSlot.Create(Attachment);
  Result := _AttachmentDepth;
  Result.SlotLayout := VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
end;

function TFrameGraph.TPass.HasInputAttachment(
  const Attachment: TAttachment;
  var PerRegion: Boolean
): Boolean;
  var i: TVkInt32;
begin
  for i := 0 to _AttachmentsInput.Count - 1 do
  if _AttachmentsInput[i].Attachment = Attachment then
  begin
    PerRegion := PerRegion or _AttachmentsInput[i].PerRegion;
    Exit(True);
  end;
  Result := False;
end;

function TFrameGraph.TPass.HasOutputAttachment(const Attachment: TAttachment): Boolean;
  var i: TVkInt32;
begin
  for i := 0 to _AttachmentsColor.Count - 1 do
  if _AttachmentsColor[i].Attachment = Attachment then
  begin
    Exit(True);
  end;
  if Assigned(_AttachmentDepth)
  and (_AttachmentDepth.Attachment = Attachment) then
  begin
    Exit(True);
  end;
  Result := False;
end;

constructor TFrameGraph.TPass.Create(const AName: AnsiString);
begin
  _Name := AName;
  _AttachmentsInput := TSlotList.Create;
  _AttachmentsColor := TSlotList.Create;
  _AttachmentDepth := nil;
  _Dependencies := TDependencyList.Create;
end;

destructor TFrameGraph.TPass.Destroy;
begin
  FreeAndNil(_Dependencies);
  FreeAndNil(_AttachmentDepth);
  FreeAndNil(_AttachmentsColor);
  FreeAndNil(_AttachmentsInput);
  inherited Destroy;
end;

constructor TFrameGraph.TAttachment.Create(
  const AName: AnsiString;
  const AFormat: TVkFormat
);
begin
  _Name := AName;
  _Format := AFormat;
end;

function TFrameGraph.NewPass(const AName: AnsiString): TPass;
begin
  Result := TPass.Create(AName);
end;

function TFrameGraph.NewAttachment(const AName: AnsiString): TAttachment;
begin
  Result := TAttachment.Create(AName);
  _Attachments.Add(Result);
end;

function TFrameGraph.NewAttachmentSwapChain(const AName: AnsiString; const ASwapChain: TLabSwapChainShared): TAttachmentSwapChain;
begin
  Result := TAttachmentSwapChain.Create(AName, ASwapChain);
  _Attachments.Add(Result);
end;

function TFrameGraph.CompileRenderPasses: TCompiledRenderPassListShared;
  var List: TCompiledRenderPassList;
  procedure GenerateDependencies;
    var TempList: TPass.TPassListTmp;
    procedure FindDependencies(const Pass: TPass);
      var i, j: TVkInt32;
      var add_dep: Boolean;
    begin
      for i := 0 to TempList.Count - 1 do
      begin
        add_dep := False;
        per_region := False;
        for j := 0 to TempList[i].AttachmentsColor.Count - 1 do
        begin
          if Pass.HasInputAttachment(TempList[i].AttachmentsColor[j].Attachment, per_region) then
          begin
            add_dep := True;
          end;
        end;
        if Pass.HasInputAttachment(TempList[i].AttachmentDepth.Attachment, per_region) then
        begin
          add_dep := True;
        end;
        if add_dep then
        begin
          Pass.Dependencies.AddUnique(TPass.TDependency.Create(TempList[i], per_region));
        end;
      end;
    end;
    var i: TVkInt32;
  begin
    TempList := TPass.TPassListTmp.Create(_PassList.Count);
    for i := 0 to _PassList.Count - 1 do
    begin
      _PassList[i].Dependencies.Clear;
      TempList.Add(_PassList[i]);
    end;
    while TempList.Count > 0 do
    begin
      FindDependencies(TempList.Pop);
    end;
    TempList.Free;
  end;
  procedure GeneratePasses;
    procedure CreateCompiledPasses;
      var TempList: TPass.TPassListTmp;
      var pass_c: TCompiledRenderPass;
      procedure GatherSubpassDependencies(const CurPass: TPass);
      var i: TVkInt32;
      begin
        for i := 0 to CurPass.Dependencies.Count - 1 do
        if CurPass.Dependencies[i].ForceSubpass then
        begin
          TempList.Remove(CurPass.Dependencies[i]);
          pass_c.SubPassList.Insert(0, CurPass.Dependencies[i]);
          GatherSubpassDependencies(CurPass.Dependencies[i]);
        end;
      end;
    begin
      TempList := TPass.TPassListTmp.Create(_PassList.Count);
      for i := 0 to _PassList.Count - 1 do
      begin
        TempList.Add(_PassList[i]);
      end;
      while TempList.Count > 0 do
      begin
        pass := TempList.Pop;
        pass_c := TCompiledRenderPass.Create;
        _CompiledRenderPasses.Add(pass_c);
        pass_c.SubPassList.Add(pass);
        GatherSubpassDependencies(pass);
        for i := 0 to pass_c.SubPassList.Count - 1 do
        begin
          for j := 0 to pass_c.SubPassList[i].AttachmentsColor.Count - 1 do
          begin
            pass_c.AddAttachmentUnique(
              pass_c.SubPassList[i].AttachmentsColor[j].Attachment,
              pass_c.SubPassList[i].AttachmentsColor[j].SlotLayout,
              not pass_c.SubPassList[i].AttachmentsColor[j].PerRegion
            );
          end;
          if Assigned(pass_c.SubPassList[i].AttachmentDepth) then
          begin
            pass_c.AddAttachmentUnique(
              pass_c.SubPassList[i].AttachmentDepth.Attachment,
              pass_c.SubPassList[i].AttachmentDepth.SlotLayout,
              not pass_c.SubPassList[i].AttachmentsColor[j].PerRegion
            );
          end;
        end;
      end;
      TempList.Free;
    end;
    procedure GatherExternalDependencies;
      function FindCompiledPass(const Pass: TPass): TCompiledRenderPass;
        var i, j: TVkInt32;
      begin
        for i := 0 to _CompiledRenderPasses.Count - 1 do
        for j := 0 to _CompiledRenderPasses[i].SubPassList.Count - 1 do
        if _CompiledRenderPasses[i].SubPassList[j] = Pass then
        begin
          Exit(_CompiledRenderPasses[i]);
        end;
        Exit(nil);
      end;
      var i, j, d: TVkInt32;
    begin
      for i := 0 to _CompiledRenderPasses.Count - 1 do
      for j := 0 to _CompiledRenderPasses[i].SubPassList.Count - 1 do
      for d := 0 to _CompiledRenderPasses[i].SubPassList[j].Dependencies.Count - 1 do
      if not _CompiledRenderPasses[i].SubPassList[j].Dependencies[d].ForceSubpass then
      begin
        _CompiledRenderPasses[i].Dependencies.AddUnique(
          FindCompiledPass(_CompiledRenderPasses[i].SubPassList[j].Dependencies[d])
        );
      end;
    end;
    procedure GatherIndirectDependencies;
      type TAttachmentDependency = record
        Pass: TCompiledRenderPass;
        Layout: TVkImageLayout;
      end;
      var i, j, p: TVkInt32;
      var pass_c, dep_pass_c: TCompiledRenderPass;
      var slot: TPass.TAttachmentSlot;
      var dep: array of TAttachmentDependency;
    begin
      for i := 0 to _CompiledRenderPasses.Count - 1 do
      begin
        pass_c := _CompiledRenderPasses[i];
        for j := 0 to pass_c.Attachments.Count - 1 do
        begin
          SetLength(dep, 0);
          for p := i + 1 to _CompiledRenderPasses.Count - 1 do
          begin
            dep_pass_c := _CompiledRenderPasses[p];
            slot := dep_pass_c.DependsOnAttachment(pass_c.Attachments[j]);
            if Assigned(slot) then
            begin
              SetLength(dep, Length(dep) + 1);
              dep[High(dep)].Pass := dep_pass_c;
              dep[High(dep)].Layout := slot.SlotLayout;
            end;
          end;
          if Length(dep) > 1 then
          begin
            for j := 1 to High(dep) do
            if dep[j].Layout <> dep[j - 1].Layout then
            begin
              dep[j].Pass.Dependencies.AddUnique(dep[j - 1].Pass);
            end;
          end;
        end;
      end;
    end;
    procedure DeriveLayoutsAndLoadStore;
      var i_p, i_a: TVkInt32;
      var pass_c: TCompiledRenderPass;
      var slot_c: TCompiledRenderPass.TCompiledAttachmentSlot;
      var attachment: TPass.TAttachmentSlot;
    begin
      for i := 0 to _CompiledRenderPasses.Count - 1 do
      begin
        pass_c := _CompiledRenderPasses[i];
        for j := 0 to pass_c.Attachments.Count - 1 do
        begin
          for d := pass_c.Dependencies.Count - 1 downto 0 do
          begin
            slot_c := pass_c.Dependencies[d].HasOutputAttachment(pass_c.Attachments[j].Attachment);
            if Assigned(slot_c) then
            begin
              pass_c.Attachments[j].InitialLayout := pass_c.Attachments[j].FirstLayout;
              slot_c.FinalLayout := pass_c.Attachments[j].FirstLayout;
              pass_c.Attachments[j].LoadOp := VK_ATTACHMENT_LOAD_OP_LOAD;
              slot_c.StoreOp := VK_ATTACHMENT_STORE_OP_STORE;
            end;
          end;
        end;
      end;
    end;
    var i, j, a, n, attachment_count: TVkInt32;
    var pass_c: TCompiledRenderPass;
    var slot_c: TCompiledRenderPass.TCompiledAttachmentSlot;
    var attachments: array of TVkAttachmentDescription;
    var subpasses: array of TLabSubpassDescriptionData;
    var input_attachments: array of TVkAttachmentReference;
  begin
    CreateCompiledPasses;
    GatherExternalDependencies;
    GatherIndirectDependencies;
    for i := 0 to _CompiledRenderPasses.Count - 1 do
    begin
      pass_c := _CompiledRenderPasses[i];
      n := 0;
      for j := 0 to pass_c.Attachments.Count - 1 do
      if pass_c.Attachments[j].AttachmentIndex <> $ffffffff then
      begin
        n := LabMax(n, pass_c.Attachments[j].AttachmentIndex + 1);
      end;
      SetLength(attachments, n);
      for j := 0 to pass_c.Attachments.Count - 1 do
      if pass_c.Attachments[j].AttachmentIndex <> $ffffffff then
      begin
        slot_c := pass_c.Attachments[j];
        attachments[slot_c.AttachmentIndex] := LabAttachmentDescription(
          slot_c.Attachment.Format,
          slot_c.InitialLayout,
          slot_c.FinalLayout,
          VK_SAMPLE_COUNT_1_BIT,
          slot_c.LoadOp,
          slot_c.StoreOp,
          VK_ATTACHMENT_LOAD_OP_DONT_CARE,
          VK_ATTACHMENT_STORE_OP_DONT_CARE
        );
      end;
      SetLength(subpasses, pass_c.SubPassList.Count);
      for j := 0 to pass_c.SubPassList.Count - 1 do
      begin
        SetLength(input_attachments, 0);
        for a := 0 to pass_c.SubPassList[j].AttachmentsInput.Count - 1 do
        if pass_c.SubPassList[0].AttachmentsInput[a].PerRegion then
        begin
          SetLength(input_attachments, Length(input_attachments) + 1);
          input_attachments[High(input_attachments)].;
        end;
        subpasses[j] := LabSubpassDescriptionData(

        );
      end;
      pass_c.RenderPass := TLabRenderPass.Create(
        _Device, attachments,
      );
    end;
  end;
begin
  List := TCompiledRenderPassList.Create;
  Result := List;
  GenerateDependencies;
  GeneratePasses;
end;

constructor TFrameGraph.Create(const ADevice: TLabDeviceShared);
begin
  _Device := ADevice;
  _PassList := TPassList.Create;
  _Attachments := TAttachmentList.Create;
  _CompiledRenderPasses := TCompiledRenderPassList.Create;
end;

destructor TFrameGraph.Destroy;
begin
  FreeAndNil(_CompiledRenderPasses);
  FreeAndNil(_Attachments);
  FreeAndNil(_PassList);
  inherited Destroy;
end;

constructor TLabApp.Create;
begin
  //ReportFormats := True;
  //EnableLayerIfAvailable('VK_LAYER_LUNARG_api_dump');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_core_validation');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_parameter_validation');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_standard_validation');
  EnableLayerIfAvailable('VK_LAYER_LUNARG_object_tracker');
  EnableExtensionIfAvailable(VK_EXT_DEBUG_REPORT_EXTENSION_NAME);
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
    DepthBuffers[i] := TLabDepthBuffer.Create(Device, Window.Ptr.Width, Window.Ptr.Height);
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

procedure TLabApp.UpdateTransforms;
  var fov: TVkFloat;
  var W, V, P, C: TLabMat;
begin
  fov := LabDegToRad * 45;
  P := LabMatProj(fov, Window.Ptr.Width / Window.Ptr.Height, 0.1, 100);
  V := LabMatView(LabVec3(-5, 3, -10), LabVec3, LabVec3(0, 1, 0));
  W := LabMatRotationY((LabTimeLoopSec(5) / 5) * Pi * 2);
  C := LabMat(
    1, 0, 0, 0,
    0, -1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  );
  UniformView.Ptr.MemberAsMat('v')^ := V;
  UniformView.Ptr.MemberAsMat('p')^ := P;
  UniformView.Ptr.MemberAsMat('vp')^ := V * P * C;
  UniformView.Ptr.MemberAsMat('vp_i')^ := (V * P * C).Inverse;
  UniformInst.Ptr.MemberAsMat('w')^ := W;
  UniformGlobal.Ptr.MemberAsVec4('time')^ := LabVec4(LabTimeSec, LabTimeSec * 0.1, LabTimeSec * 10, sin(LabTimeSec * LabPi));
  UniformData.Ptr.MemberAsMat('mvp')^ := W * V * P * C;
end;

procedure TLabApp.TransferBuffers;
begin

end;

procedure TLabApp.Initialize;
  var map: PVkVoid;
  var ShaderBuildInfo: TLabShaderBuildInfo;
begin
  Window := TLabWindow.Create(500, 500);
  Window.Ptr.Caption := 'Vulkan Initialization';
  Device := TLabDevice.Create(
    PhysicalDevices[0],
    [
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_GRAPHICS_BIT))),
      LabQueueFamilyRequest(PhysicalDevices[0].Ptr.GetQueueFamiliyIndex(TVkFlags(VK_QUEUE_COMPUTE_BIT)))
    ],
    [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
  );
  Surface := TLabSurface.Create(Window);
  SwapChainCreate;
  CmdPool := TLabCommandPool.Create(Device, SwapChain.Ptr.QueueFamilyIndexGraphics);
  CmdBuffer := TLabCommandBuffer.Create(CmdPool);
  DescriptorSetsFactory := TLabDescriptorSetsFactory.Create(Device);
  DescriptorSets := DescriptorSetsFactory.Ptr.Request([
      LabDescriptorSetBindings([
          LabDescriptorBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
          LabDescriptorBinding(1, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
          LabDescriptorBinding(2, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)),
          LabDescriptorBinding(3, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT))
      ])
  ]);
  PipelineLayout := TLabPipelineLayout.Create(
    Device, [], [
      DescriptorSets.Ptr.Layout[0].Ptr
    ]
  );
  //VertexShader := TLabVertexShader.Create(Device, 'triangle_vs.spv');
  //PixelShader := TLabPixelShader.Create(Device, 'triangle_ps.spv');
  CombinedShader := TLabCombinedShader.CreateFromFile(App.Device, 'triangle_shader.txt');
  ShaderBuildInfo.JointCount := 0;
  ShaderBuildInfo.MaxJointWeights := 0;
  Shaders := CombinedShader.Ptr.Build(ShaderBuildInfo);
  UniformGlobal := CombinedShader.Ptr.FindUniform('global').CreateBuffer();
  UniformView := CombinedShader.Ptr.FindUniform('view').CreateBuffer();
  UniformInst := CombinedShader.Ptr.FindUniform('instance').CreateBuffer();
  UniformData := CombinedShader.Ptr.FindUniform('data').CreateBuffer(1);
  //Uniforms := TUniforms.Create;
  DescriptorSets.Ptr.UpdateSets(
    [
      LabWriteDescriptorSetUniformBuffer(
        DescriptorSets.Ptr.VkHandle[0], 0,
        [
          LabDescriptorBufferInfo(UniformGlobal.Ptr.VkHandle),
          LabDescriptorBufferInfo(UniformView.Ptr.VkHandle),
          LabDescriptorBufferInfo(UniformInst.Ptr.VkHandle),
          LabDescriptorBufferInfo(UniformData.Ptr.VkHandle)
        ]
      )
    ],
    []
  );
  PipelineCache := TLabPipelineCache.Create(Device);
  Pipeline := TLabGraphicsPipeline.Create(
    Device, PipelineCache, PipelineLayout.Ptr,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [LabShaderStage(Shaders.Ptr.Vertex.Ptr), LabShaderStage(Shaders.Ptr.Pixel.Ptr)],
    RenderPass.Ptr, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(
      VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
    ),
    LabPipelineVertexInputState([], []),
    LabPipelineRasterizationState(
      VK_FALSE, VK_FALSE, VK_POLYGON_MODE_FILL,
      TVkFlags(VK_CULL_MODE_NONE), VK_FRONT_FACE_COUNTER_CLOCKWISE
    ),
    LabPipelineDepthStencilState(LabDefaultStencilOpState, LabDefaultStencilOpState),
    LabPipelineMultisampleState(),
    LabPipelineColorBlendState([LabDefaultColorBlendAttachment], []),
    LabPipelineTesselationState(0)
  );
  Semaphore := TLabSemaphore.Create(Device);
  Fence := TLabFence.Create(Device);
  TransferBuffers;
end;

procedure TLabApp.Finalize;
begin
  Device.Ptr.WaitIdle;
  SwapchainDestroy;
  Shaders := nil;
  CombinedShader := nil;
  UniformGlobal := nil;
  UniformView := nil;
  UniformInst := nil;
  UniformData := nil;
  //Uniforms := nil;
  Fence := nil;
  Semaphore := nil;
  Pipeline := nil;
  PipelineCache := nil;
  PipelineLayout := nil;
  DescriptorSets := nil;
  DescriptorSetsFactory := nil;
  CmdBuffer := nil;
  CmdPool := nil;
  Surface := nil;
  Device := nil;
  Window := nil;
  Free;
end;

procedure TLabApp.Loop;
  var cur_buffer: TVkUInt32;
  var r: TVkResult;
begin
  TLabVulkan.IsActive := Window.Ptr.IsActive;
  if not TLabVulkan.IsActive
  or (Window.Ptr.Mode = wm_minimized)
  or (Window.Ptr.Width * Window.Ptr.Height = 0) then Exit;
  if (SwapChain.Ptr.Width <> Window.Ptr.Width)
  or (SwapChain.Ptr.Height <> Window.Ptr.Height) then
  begin
    Device.Ptr.WaitIdle;
    SwapchainDestroy;
    SwapchainCreate;
  end;
  UpdateTransforms;
  r := SwapChain.Ptr.AcquireNextImage(Semaphore);
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
  cur_buffer := SwapChain.Ptr.CurImage;
  CmdBuffer.Ptr.RecordBegin();
  CmdBuffer.Ptr.BeginRenderPass(
    RenderPass.Ptr, FrameBuffers[cur_buffer].Ptr,
    [LabClearValue(0.4, 0.7, 1.0, 1.0), LabClearValue(1.0, 0)]
  );
  CmdBuffer.Ptr.BindPipeline(Pipeline.Ptr);
  CmdBuffer.Ptr.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    PipelineLayout.Ptr,
    0, [DescriptorSets.Ptr.VkHandle[0]], []
  );
  CmdBuffer.Ptr.SetViewport([LabViewport(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  CmdBuffer.Ptr.SetScissor([LabRect2D(0, 0, Window.Ptr.Width, Window.Ptr.Height)]);
  CmdBuffer.Ptr.Draw(3);
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
  CmdPool.Ptr.Reset();
  QueuePresent(SwapChain.Ptr.QueueFamilyPresent, [SwapChain.Ptr.VkHandle], [cur_buffer], []);
end;

end.
