unit LabRenderGraph;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice,
  LabRenderPass;

type
  TLabMetaRenderObject = class (TLabClass)
  public
    type TAutoFreeList = specialize TLabObjList<TObject>;
    type TLabMetaRenderObjectClass = class of TLabMetaRenderObject;
  private
    var _Name: String;
    var _AutoFree: TAutoFreeList;
  protected
    var Next: TLabMetaRenderObject;
    var Prev: TLabMetaRenderObject;
    class var List: TLabMetaRenderObject;
    procedure AutoFreeAdd(const Obj: TObject);
    procedure AutoFreeRemove(const Obj: TObject);
  public
    property Name: String read _Name;
    class constructor CreateClass;
    class function Find(const AName: String): TLabMetaRenderObject;
    class function Find(const AName: String; const AClass: TLabMetaRenderObjectClass): TLabMetaRenderObject;
    constructor Create(const AName: String); virtual;
    destructor Destroy; override;
  end;
  TLabMetaRenderObjectList = specialize TLabList<TLabMetaRenderObject>;

  TLabMetaImage = class (TLabMetaRenderObject)
  private
    var _Format: TVkFormat;
    var _Samples: TVkSampleCountFlagBits;
    var Layout: TVkImageLayout;
  public
    property Format: TVkFormat read _Format;
    property Samples: TVkSampleCountFlagBits read _Samples;
    constructor Create(
      const AName: String;
      const AFormat: TVkFormat = VK_FORMAT_UNDEFINED;
      const ASamples: TVkSampleCountFlagBits = VK_SAMPLE_COUNT_1_BIT
    ); overload;
  end;

  TLabMetaRenderPassAttachment = class (TLabMetaRenderObject)
  private
    var _Image: TLabMetaImage;
    var LayoutInitial: TVkImageLayout;
    var LayoutFinal: TVkImageLayout;
    var LayoutCurrent: TVkImageLayout;
  public
    property Image: TLabMetaImage read _Image;
    constructor Create(const AName: String); override;
  end;
  TLabMetaRenderPassAttachmentList = specialize TLabList<TLabMetaRenderPassAttachment>;
  TLabMetaRenderPassAttachmentShared = specialize TLabSharedRef<TLabMetaRenderPassAttachment>;

  TLabMetaRenderPass = class (TLabMetaRenderObject)
  private
    var _AttachmentInput: TLabMetaRenderPassAttachmentList;
    var _AttachmentColor: TLabMetaRenderPassAttachmentList;
    var _AttachmentDepth: TLabMetaRenderPassAttachmentShared;
    function GetAttachmentInput(const Index: TVkUInt32): TLabMetaRenderPassAttachment; inline;
    function GetAttachmentInputCount: TVkUInt32; inline;
    function GetAttachmentColor(const Index: TVkUInt32): TLabMetaRenderPassAttachment; inline;
    function GetAttachmentColorCount: TVkUInt32; inline;
    function GetAttachmentDepth: TLabMetaRenderPassAttachment; inline;
    function GetAttachmentCount: TVkUInt32; inline;
  public
    property AttachmentInput[const Index: TVkUInt32]: TLabMetaRenderPassAttachment read GetAttachmentInput;
    property AttachmentInputCount: TVkUInt32 read GetAttachmentInputCount;
    property AttachmentColor[const Index: TVkUInt32]: TLabMetaRenderPassAttachment read GetAttachmentColor;
    property AttachmentColorCount: TVkUInt32 read GetAttachmentColorCount;
    property AttachmentDepth: TLabMetaRenderPassAttachment read GetAttachmentDepth;
    property AttachmentCount: TVkUInt32 read GetAttachmentCount;
    function AddAttachmentInput(const AttachmentName: String): TLabMetaRenderPassAttachment;
    function AddAttachmentColor(const AttachmentName: String): TLabMetaRenderPassAttachment;
    function SetAttachmentDepth(const AttachmentName: String): TLabMetaRenderPassAttachment;
    constructor Create(const AName: String); override;
  end;
  TLabMetaRenderPassList = specialize TLabList<TLabMetaRenderPass>;

  TLabRenderGraph = class (TLabMetaRenderObject)
  public
    type TRenderPassList = specialize TLabRefList<TLabRenderPassShared>;
  private
    var _Passes: TRenderPassList;
    var _RenderPassList: TLabMetaRenderPassList;
  public
    constructor Create;
    constructor Create(const AName: String); override;
    destructor Destroy; override;
    function AddRenderPass(const RenderPassName: String): TLabMetaRenderPass;
    function ImageCreate(
      const ImageName: String;
      const ImageFormat: TVkFormat;
      const ImageSamples: TVkSampleCountFlagBits = VK_SAMPLE_COUNT_1_BIT
    ): TLabMetaImage;
    procedure Build(const Device: TLabDeviceShared);
  end;

implementation

constructor TLabMetaImage.Create(
  const AName: String;
  const AFormat: TVkFormat;
  const ASamples: TVkSampleCountFlagBits
);
begin
  inherited Create(AName);
  _Format := AFormat;
  _Samples := ASamples;
  Layout := VK_IMAGE_LAYOUT_UNDEFINED;
end;

constructor TLabMetaRenderPassAttachment.Create(const AName: String);
begin
  inherited Create(AName);
  _Image := TLabMetaImage(Find(AName, TLabMetaImage));
  LayoutInitial := VK_IMAGE_LAYOUT_UNDEFINED;
  LayoutFinal := VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
  LayoutCurrent := VK_IMAGE_LAYOUT_UNDEFINED;
end;

function TLabMetaRenderPass.GetAttachmentInput(const Index: TVkUInt32): TLabMetaRenderPassAttachment;
begin
  Result := _AttachmentInput[Index];
end;

function TLabMetaRenderPass.GetAttachmentInputCount: TVkUInt32;
begin
  Result := _AttachmentInput.Count;
end;

function TLabMetaRenderPass.GetAttachmentColor(const Index: TVkUInt32): TLabMetaRenderPassAttachment;
begin
  Result := _AttachmentColor[Index];
end;

function TLabMetaRenderPass.GetAttachmentColorCount: TVkUInt32;
begin
  Result := _AttachmentColor.Count;
end;

function TLabMetaRenderPass.GetAttachmentDepth: TLabMetaRenderPassAttachment;
begin
  Result := _AttachmentDepth.Ptr;
end;

function TLabMetaRenderPass.GetAttachmentCount: TVkUInt32;
begin
  Result := _AttachmentInput.Count + _AttachmentColor.Count + TVkUInt32(_AttachmentDepth.IsValid);
end;

function TLabMetaRenderPass.AddAttachmentInput(const AttachmentName: String): TLabMetaRenderPassAttachment;
begin
  Result := TLabMetaRenderPassAttachment(Find(AttachmentName, TLabMetaRenderPassAttachment));
  if Assigned(Result) then _AttachmentInput.Add(Result);
end;

function TLabMetaRenderPass.AddAttachmentColor(const AttachmentName: String): TLabMetaRenderPassAttachment;
begin
  Result := TLabMetaRenderPassAttachment(Find(AttachmentName, TLabMetaRenderPassAttachment));
  if Assigned(Result) then _AttachmentColor.Add(Result);
end;

function TLabMetaRenderPass.SetAttachmentDepth(const AttachmentName: String): TLabMetaRenderPassAttachment;
begin
  Result := TLabMetaRenderPassAttachment(Find(AttachmentName, TLabMetaRenderPassAttachment));
  _AttachmentDepth := Result;
end;

constructor TLabMetaRenderPass.Create(const AName: String);
begin
  inherited Create(AName);
  _AttachmentColor := TLabMetaRenderPassAttachmentList.Create;
  AutoFreeAdd(_AttachmentInput);
  AutoFreeAdd(_AttachmentColor);
end;

procedure TLabMetaRenderObject.AutoFreeAdd(const Obj: TObject);
begin
  _AutoFree.Add(Obj);
end;

procedure TLabMetaRenderObject.AutoFreeRemove(const Obj: TObject);
begin
  _AutoFree.Remove(Obj);
end;

class constructor TLabMetaRenderObject.CreateClass;
begin
  List := nil;
end;

class function TLabMetaRenderObject.Find(const AName: String): TLabMetaRenderObject;
  var Cur: TLabMetaRenderObject;
begin
  Cur := List;
  while Assigned(Cur) do
  begin
    if Cur.Name = AName then Exit(Cur);
    Cur := Cur.Next;
  end;
  Result := nil;
end;

class function TLabMetaRenderObject.Find(const AName: String; const AClass: TLabMetaRenderObjectClass): TLabMetaRenderObject;
  var Cur: TLabMetaRenderObject;
begin
  Cur := List;
  while Assigned(Cur) do
  begin
    if (Cur is AClass) and (Cur.Name = AName) then Exit(Cur);
    Cur := Cur.Next;
  end;
  Result := nil;
end;

constructor TLabMetaRenderObject.Create(const AName: String);
begin
  if Assigned(List) then List.Prev := Self;
  Next := List;
  Prev := nil;
  List := Self;
  _Name := AName;
  _AutoFree := TAutoFreeList.Create;
end;

destructor TLabMetaRenderObject.Destroy;
begin
  _AutoFree.Free;
  if Assigned(Prev) then Prev.Next := Next;
  if Assigned(Next) then Next.Prev := Prev;
  if List = Self then List := Next;
  inherited Destroy;
end;

constructor TLabRenderGraph.Create;
begin
  Create('render_graph');
end;

constructor TLabRenderGraph.Create(const AName: String);
begin
  inherited Create(AName);
  _RenderPassList := TLabMetaRenderPassList.Create;
  _Passes := TRenderPassList.Create;
  AutoFreeAdd(_RenderPassList);
  AutoFreeAdd(_Passes);
end;

destructor TLabRenderGraph.Destroy;
begin
  inherited Destroy;
end;

function TLabRenderGraph.AddRenderPass(const RenderPassName: String): TLabMetaRenderPass;
begin
  Result := TLabMetaRenderPass.Create(RenderPassName);
  _RenderPassList.Add(Result);
end;

function TLabRenderGraph.ImageCreate(
  const ImageName: String;
  const ImageFormat: TVkFormat;
  const ImageSamples: TVkSampleCountFlagBits
): TLabMetaImage;
begin
  Result := TLabMetaImage.Create(ImageName, ImageFormat, ImageSamples);
  AutoFreeAdd(Result);
end;

procedure TLabRenderGraph.Build(const Device: TLabDeviceShared);
  procedure TransitionImage(const Img: TLabMetaImage);
    function FindImageAttaqchment(const RenderPass: TLabMetaRenderPass): TLabMetaRenderPassAttachment;
      var i: Integer;
    begin
      for i := 0 to RenderPass.AttachmentInputCount - 1 do
      if RenderPass.AttachmentInput[i].Image = Img then
      begin
        Exit(RenderPass.AttachmentInput[i]);
      end;
      for i := 0 to RenderPass.AttachmentColorCount - 1 do
      if RenderPass.AttachmentColor[i].Image = Img then
      begin
        Exit(RenderPass.AttachmentColor[i]);
      end;
      if Assigned(RenderPass.AttachmentDepth) and
      (RenderPass.AttachmentDepth.Image = Img) then
      begin
        Exit(RenderPass.AttachmentDepth);
      end;
      Result := nil;
    end;
    var i, j: Integer;
    var rp: TLabMetaRenderPass;
    var att, att_prev: TLabMetaRenderPassAttachment;
  begin
    att_prev := nil;
    for i := 0 to _RenderPassList.Count - 1 do
    begin
      rp := _RenderPassList[i];
      att := FindImageAttaqchment(rp);
      if Assigned(att) then
      begin
        if Assigned(att_prev) then
        begin
          att_prev.LayoutFinal := att.LayoutCurrent;
          Img.Layout := att.LayoutCurrent;
        end;
        att.LayoutInitial := Img.Layout;
        Img.Layout := att.LayoutCurrent;
        att_prev := att;
      end;
    end;
  end;
  var i, j, n: Integer;
  var rp: TLabMetaRenderPass;
  var att: TLabMetaRenderPassAttachment;
  var attachments: array of TVkAttachmentDescription;
  var att_input: array of TVkAttachmentReference;
  var att_color: array of TVkAttachmentReference;
  var att_depth: TVkAttachmentReference;
  var obj: TLabMetaRenderObject;
begin
  if _RenderPassList.Count <= 0 then Exit;
  rp := _RenderPassList[0];
  for i := 0 to rp.AttachmentInputCount - 1 do
  begin
    rp.AttachmentInput[i].Image.Layout := VK_IMAGE_LAYOUT_UNDEFINED;
  end;
  for i := 0 to rp.AttachmentColorCount - 1 do
  begin
    rp.AttachmentColor[i].Image.Layout := VK_IMAGE_LAYOUT_UNDEFINED;
  end;
  if Assigned(rp.AttachmentDepth) then
  begin
    rp.AttachmentDepth.Image.Layout := VK_IMAGE_LAYOUT_UNDEFINED;
  end;
  for i := 0 to _RenderPassList.Count - 1 do
  begin
    rp := _RenderPassList[i];
    for j := 0 to rp.AttachmentInputCount - 1 do
    begin
      rp.AttachmentInput[j].LayoutCurrent := VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
      rp.AttachmentInput[j].LayoutFinal := VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    end;
    for j := 0 to rp.AttachmentColorCount - 1 do
    begin
      rp.AttachmentColor[j].LayoutCurrent := VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
      rp.AttachmentColor[j].LayoutFinal := VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    end;
    if Assigned(_RenderPassList[i].AttachmentDepth) then
    begin
      rp.AttachmentDepth.LayoutCurrent := VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
      rp.AttachmentDepth.LayoutFinal := VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    end;
  end;
  obj := List;
  while Assigned(obj) do
  begin
    if obj is TLabMetaImage then
    begin
      TransitionImage(TLabMetaImage(obj));
    end;
    obj := obj.Next;
  end;
  for i := 0 to _RenderPassList.Count - 1 do
  begin
    rp := _RenderPassList[i];
    SetLength(attachments, rp.AttachmentCount);
    SetLength(att_input, rp.AttachmentInputCount);
    SetLength(att_color, rp.AttachmentColorCount);
    n := 0;
    for j := 0 to rp.AttachmentInputCount - 1 do
    begin
      att := rp.AttachmentInput[j];
      attachments[n] := LabAttachmentDescription(
        att.Image.Format, att.LayoutFinal, att.Image.Samples,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_DONT_CARE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_DONT_CARE,
        att.LayoutInitial
      );
      att_input[j] := LabAttachmentReference(n, att.LayoutCurrent);
      Inc(n);
    end;
    for j := 0 to rp.AttachmentColorCount - 1 do
    begin
      att := rp.AttachmentColor[j];
      attachments[n] := LabAttachmentDescription(
        att.Image.Format, att.LayoutFinal, att.Image.Samples,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_DONT_CARE,
        att.LayoutInitial
      );
      att_color[j] := LabAttachmentReference(
        n, att.LayoutCurrent
      );
      Inc(n);
    end;
    if Assigned(rp.AttachmentDepth) then
    begin
      att := rp.AttachmentDepth;
      attachments[n] := LabAttachmentDescription(
        att.Image.Format, att.LayoutFinal, att.Image.Samples,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_STORE,
        VK_ATTACHMENT_LOAD_OP_DONT_CARE, VK_ATTACHMENT_STORE_OP_DONT_CARE,
        att.LayoutInitial
      );
      att_depth := LabAttachmentReference(n, att.LayoutCurrent);
      Inc(n);
    end
    else
    begin
      att_depth := LabAttachmentReferenceInvalid;
    end;
    //TLabRenderPass.Create(
    //  Device, attachments,
    //  [
    //    LabSubpassDescriptionData(
    //      att_input, att_color, [], att_depth, []
    //    )
    //  ],
    //
    //);
  end;
end;

end.
