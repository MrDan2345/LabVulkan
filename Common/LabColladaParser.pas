unit LabColladaParser;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabMath,
  Classes,
  SysUtils,
  DOM,
  XMLRead;

type
  TLabListDOMString = specialize TLabList<DOMString>;
  TLabColladaObject = class
  public
    type TObjectList = specialize TLabList<TLabColladaObject>;
    type CSelf = class of TLabColladaObject;
  private
    _Tag: DOMString;
    _id: DOMString;
    _Scoped: Boolean;
    _Parent: TLabColladaObject;
    _Children: TObjectList;
    _UserData: TObject;
    _AutoFreeUserData: Boolean;
    procedure SetParent(const Value: TLabColladaObject); inline;
  protected
    procedure DumpBegin;
    procedure DumpEnd;
    procedure DumpData; virtual;
    procedure Resolve;
    procedure ResolveLinks; virtual;
    procedure Initialize;
    procedure InitializeObject; virtual;
    function ResolveObject(
      const Path: DOMString;
      const ObjectClass: CSelf
    ): TLabColladaObject;
  public
    property Tag: DOMString read _Tag;
    property id: DOMString read _id;
    property IsScoped: Boolean read _Scoped;
    property Parent: TLabColladaObject read _Parent write SetParent;
    property Children: TObjectList read _Children;
    property UserData: TObject read _UserData write _UserData;
    property AutoFreeUserData: Boolean read _AutoFreeUserData write _AutoFreeUserData;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
    function GetRoot: TLabColladaObject;
    function Find(const Path: DOMString): TLabColladaObject;
    function FindChild(const NodeID: DOMString): TLabColladaObject;
    function FindChildRecursive(const NodeID: DOMString): TLabColladaObject;
    procedure Dump;
  end;
  TLabColladaObjectList = TLabColladaObject.TObjectList;
  TLabColladaObjectClass = TLabColladaObject.CSelf;

  TLabColladaInstance = class (TLabColladaObject)
  private
    _url: DOMString;
  public
    property Url: DOMString read _url;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaInstanceList = specialize TLabList<TLabColladaInstance>;

  TLabColladaMaterial = class;

  TLabColladaInput = class (TLabColladaObject)
  private
    _Semantic: DOMString;
    _SourceRef: DOMString;
    _Source: TLabColladaObject;
    _Offset: TVkInt32;
    _Set: TVkInt32;
  protected
    procedure ResolveLinks; override;
  public
    property Semantic: DOMString read _Semantic;
    property Source: TLabColladaObject read _Source;
    property Offset: TVkInt32 read _Offset;
    property InputSet: TVkInt32 read _Set;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaInputList = specialize TLabList<TLabColladaInput>;

  TLabColladaArrayType = (
    at_invalid,
    at_bool,
    at_float,
    at_idref,
    at_int,
    at_name,
    at_sidref,
    at_token
  );

  TLabColladaDataArray = class (TLabColladaObject)
  private
    _Data: array of TVkUInt8;
    _DataString: array of DOMString;
    _Count: TVkInt32;
    _ItemSize: TVkInt32;
    _ArrayType: TLabColladaArrayType;
    function GetAsBool(const Index: TVkInt32): PBoolean; inline;
    function GetAsInt(const Index: TVkInt32): PVkInt32; inline;
    function GetAsFloat(const Index: TVkInt32): PVkFloat; inline;
    function GetAsString(const Index: TVkInt32): DOMString; inline;
    function GetRawData(const Offset: TVkInt32): Pointer; inline;
  public
    property ArrayType: TLabColladaArrayType read _ArrayType;
    property Count: TVkInt32 read _Count;
    property ItemSize: TVkInt32 read _ItemSize;
    property AsBool[const Index: TVkInt32]: PBoolean read GetAsBool;
    property AsInt[const Index: TVkInt32]: PVkInt32 read GetAsInt;
    property AsFloat[const Index: TVkInt32]: PVkFloat read GetAsFloat;
    property AsString[const Index: TVkInt32]: DOMString read GetAsString;
    property RawData[const Offset: TVkInt32]: Pointer read GetRawData;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
    class function NodeNameToArrayType(const NodeName: DOMString): TLabColladaArrayType;
    class function TypeNameToArrayType(const TypeName: DOMString): TLabColladaArrayType;
    class function IsDataArrayNode(const XMLNode: TDOMNode): Boolean;
  end;

  TLabColladaAccessor = class (TLabColladaObject)
  public
    type TParam = record
      Name: DOMString;
      ParamType: TLabColladaArrayType;
    end;
    type TParamArr = array[0..High(Word)] of TParam;
    type PParamArr = ^TParamArr;
  private
    _SourceRef: DOMString;
    _Source: TLabColladaDataArray;
    _Count: TVkInt32;
    _Stride: TVkInt32;
    _Params: array of TParam;
    function GetParams: PParamArr;
  protected
    procedure ResolveLinks; override;
  public
    property Source: TLabColladaDataArray read _Source;
    property Count: TVkInt32 read _Count;
    property Stride: TVkInt32 read _Stride;
    property Params: PParamArr read GetParams;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaSource = class (TLabColladaObject)
  private
    _DataArray: TLabColladaDataArray;
    _Accessor: TLabColladaAccessor;
  public
    property DataArray: TLabColladaDataArray read _DataArray;
    property Accessor: TLabColladaAccessor read _Accessor;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaSourceList = specialize TLabList<TLabColladaSource>;

  TLabColladaVertices = class (TLabColladaObject)
  private
    _Inputs: TLabColladaInputList;
  public
    property Inputs: TLabColladaInputList read _Inputs;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaVertexAttributeSemantic = (
    as_invalid,
    as_position,
    as_normal,
    as_tangent,
    as_binormal,
    as_color,
    as_texcoord
  );
  TLabColladaVertexAttribute = record
    Semantic: TLabColladaVertexAttributeSemantic;
    DataType: TLabColladaArrayType;
    DataCount: TVkUInt8;
    SetNumber: TVkUInt8;
  end;
  TLabColladaVertexDescriptor = array of TLabColladaVertexAttribute;
  TLabColladaTriangles = class (TLabColladaObject)
  private
    _MaterialRef: DOMString;
    _Count: TVkInt32;
    _Inputs: TLabColladaInputList;
    _Indices: array of TLabInt32;
    _VertexLayout: TLabColladaInputList;
    function GetVertexSize: TVkInt32;
    function GetIndices: PLabInt32Arr; inline;
    function GetVertexDescriptor: TLabColladaVertexDescriptor;
  protected
    procedure InitializeObject; override;
  public
    property Count: TVkInt32 read _Count;
    property Inputs: TLabColladaInputList read _Inputs;
    property Indices: PLabInt32Arr read GetIndices;
    property VertexLayout: TLabColladaInputList read _VertexLayout;
    property VertexSize: TVkInt32 read GetVertexSize;
    property VertexDescriptor: TLabColladaVertexDescriptor read GetVertexDescriptor;
    property Material: DOMString read _MaterialRef;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
    function CopyInputData(const Target: Pointer; const Input: TLabColladaInput; const Index: TVkInt32): Pointer;
  end;
  TLabColladaTrianglesList = specialize TLabList<TLabColladaTriangles>;

  TLabColladaMesh = class (TLabColladaObject)
  private
    _Sources: TLabColladaSourceList;
    _Vertices: TLabColladaVertices;
    _TrianglesList: TLabColladaTrianglesList;
  public
    property Sources: TLabColladaSourceList read _Sources;
    property Vertices: TLabColladaVertices read _Vertices;
    property TrianglesList: TLabColladaTrianglesList read _TrianglesList;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaMeshList = specialize TLabList<TLabColladaMesh>;

  TLabColladaImage = class (TLabColladaObject)
  private
    _Source: DOMString;
  public
    property Source: DOMString read _Source;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaImageList = specialize TLabList<TLabColladaImage>;

  TLabColladaEffectProfileParamType = (pt_invalid, pt_surface, pt_sampler, pt_float, pt_float2, pt_float3, pt_float4);

  TLabColladaEffectProfileParam = class (TLabColladaObject)
  public
    type TDataSurface = class
      InitFrom: DOMString;
      Image: TLabColladaImage;
    end;
    type TDataSampler = class
      Source: DOMString;
      Surface: TDataSurface;
    end;
    type TDataFloat = class
      Value: TLabFloat;
    end;
    type TDataFloat2 = class
      Value: TLabVec2;
    end;
    type TDataFloat3 = class
      Value: TLabVec3;
    end;
    type TDataFloat4 = class
      Value: TLabVec4;
    end;
  private
    _ParamType: TLabColladaEffectProfileParamType;
    _Data: TObject;
  public
    property ParamType: TLabColladaEffectProfileParamType read _ParamType;
    function AsSurface: TDataSurface; inline;
    function AsSampler: TDataSampler; inline;
    function AsFloat: TDataFloat; inline;
    function AsFloat2: TDataFloat2; inline;
    function AsFloat3: TDataFloat3; inline;
    function AsFloat4: TDataFloat4; inline;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaEffectProfileParamList = specialize TLabList<TLabColladaEffectProfileParam>;

  TLabColladaEffectProfile = class (TLabColladaObject)
  private
    _Params: TLabColladaEffectProfileParamList;
  protected
    procedure ResolveLinks; override;
  public
    property Params: TLabColladaEffectProfileParamList read _Params;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaEffect = class (TLabColladaObject)
  private
    _Profile: TLabColladaEffectProfile;
  public
    property Profile: TLabColladaEffectProfile read _Profile;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaEffectList = specialize TLabList<TLabColladaEffect>;

  TLabColladaInstanceEffect = class (TLabColladaInstance)
  private
    _Effect: TLabColladaEffect;
  protected
    procedure ResolveLinks; override;
  public
    property Effect: TLabColladaEffect read _Effect;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaMaterial = class (TLabColladaObject)
  private
    _InstanceEffect: TLabColladaInstanceEffect;
  public
    property InstanceEffect: TLabColladaInstanceEffect read _InstanceEffect;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaMaterialList = specialize TLabList<TLabColladaMaterial>;

  TLabColladaGeometry = class (TLabColladaObject)
  private
    _Name: DOMString;
    _Meshes: TLabColladaMeshList;
  public
    property Name: DOMString read _Name;
    property Meshes: TLabColladaMeshList read _Meshes;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaGeometryList = specialize TLabList<TLabColladaGeometry>;

  TLabColladaInstanceMaterial = class (TLabColladaObject)
  private
    _Symbol: DOMString;
    _Target: DOMString;
    _Material: TLabColladaMaterial;
  protected
    procedure ResolveLinks; override;
  public
    property Material: TLabColladaMaterial read _Material;
    property Symbol: DOMString read _Symbol;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaInstanceMaterialList = specialize TLabList<TLabColladaInstanceMaterial>;

  TLabColladaInstanceGeometry = class (TLabColladaInstance)
  private
    _Geometry: TLabColladaGeometry;
    _MaterialBindings: TLabColladaInstanceMaterialList;
  protected
    procedure ResolveLinks; override;
  public
    property Geometry: TLabColladaGeometry read _Geometry;
    property MaterialBindings: TLabColladaInstanceMaterialList read _MaterialBindings;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaNodeType = (nt_invalid, nt_node, nt_joint);

  TLabColladaNode = class (TLabColladaObject)
  public
    type TNodeList = specialize TLabList<TLabColladaNode>;
  private
    _Name: DOMString;
    _NodeType: TLabColladaNodeType;
    _Layers: TLabListDOMString;
    _Nodes: TNodeList;
    _Instances: TLabColladaInstanceList;
  public
    var Matrix: TLabMat;
    property Name: DOMString read _Name;
    property NodeType: TLabColladaNodeType read _NodeType;
    property Layers: TLabListDOMString read _Layers;
    property Nodes: TNodeList read _Nodes;
    property Instances: TLabColladaInstanceList read _Instances;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
    class function StringToNodeType(const NodeTypeName: DOMString): TLabColladaNodeType;
  end;
  TLabColladaNodeList = TLabColladaNode.TNodeList;

  TLabColladaVisualScene = class (TLabColladaObject)
  private
    _Nodes: TLabColladaNodeList;
  public
    property Nodes: TLabColladaNodeList read _Nodes;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;
  TLabColladaVisualSceneList = specialize TLabList<TLabColladaVisualScene>;

  TLabColladaLibraryMaterials = class (TLabColladaObject)
  private
    _Materials: TLabColladaMaterialList;
  public
    property Materials: TLabColladaMaterialList read _Materials;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaLibraryEffects = class (TLabColladaObject)
  private
    _Effects: TLabColladaEffectList;
  public
    property Effects: TLabColladaEffectList read _Effects;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaLibraryImages = class (TLabColladaObject)
  private
    _Images: TLabColladaImageList;
  public
    property Images: TLabColladaImageList read _Images;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaLibraryGeometries = class (TLabColladaObject)
  private
    _Geometries: TLabColladaGeometryList;
  public
    property Geometries: TLabColladaGeometryList read _Geometries;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaLibraryVisualScenes = class (TLabColladaObject)
  private
    _VisualScenes: TLabColladaVisualSceneList;
  public
    property VisualScenes: TLabColladaVisualSceneList read _VisualScenes;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaInstanceVisualScene = class (TLabColladaInstance)
  private
    _VisualScene: TLabColladaVisualScene;
  protected
    procedure ResolveLinks; override;
  public
    property VisualScene: TLabColladaVisualScene read _VisualScene;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaScene = class (TLabColladaObject)
  private
    _VisualScene: TLabColladaInstanceVisualScene;
  public
    property VisualScene: TLabColladaInstanceVisualScene read _VisualScene;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaAsset = class (TLabColladaObject)
  private
    _UpAxis: TLabSwizzle;
  public
    property UpAxis: TLabSwizzle read _UpAxis;
    constructor Create(const XMLNode: TDOMNode; const AParent: TLabColladaObject);
    destructor Destroy; override;
  end;

  TLabColladaRoot = class (TLabColladaObject)
  private
    _Asset: TLabColladaAsset;
    _LibMaterials: TLabColladaLibraryMaterials;
    _LibEffects: TLabColladaLibraryEffects;
    _LibImages: TLabColladaLibraryImages;
    _LibGeometries: TLabColladaLibraryGeometries;
    _LibVisualScenes: TLabColladaLibraryVisualScenes;
    _Scene: TLabColladaScene;
  public
    property Asset: TLabColladaAsset read _Asset;
    property LibMaterials: TLabColladaLibraryMaterials read _LibMaterials;
    property LibEffects: TLabColladaLibraryEffects read _LibEffects;
    property LibImages: TLabColladaLibraryImages read _LibImages;
    property LibGeometries: TLabColladaLibraryGeometries read _LibGeometries;
    property LibVisualScenes: TLabColladaLibraryVisualScenes read _LibVisualScenes;
    property Scene: TLabColladaScene read _Scene;
    constructor Create(const XMLNode: TDOMNode);
    destructor Destroy; override;
  end;

  TLabColladaParser = class
  private
    _RootNode: TLabColladaRoot;
    procedure ReadDocument(const Document: TXMLDocument);
  public
    property RootNode: TLabColladaRoot read _RootNode;
    constructor Create(const FileName: String);
    constructor Create(const Steam: TStream);
    destructor Destroy; override;
  end;

implementation

function FindAttribute(const Node: TDOMNode; const AttribName: DOMString): DOMString;
begin
  if TDOMElement(Node).hasAttribute(AttribName) then Result := TDOMElement(Node).GetAttribute(AttribName) else Result := '';
end;

function FindNextValue(const Str: DOMString; var CurPos: TVkInt32): DOMString;
begin
  Result := '';
  while (
    (CurPos <= Length(Str)) and (
      (Str[CurPos] = ' ')
      or (Str[CurPos] = #$D)
      or (Str[CurPos] = #$A)
    )
  ) do Inc(CurPos);
  while CurPos <= Length(Str) do
  begin
    if (
      (Str[CurPos] = ' ')
      or (Str[CurPos] = #$D)
      or (Str[CurPos] = #$A)
    ) then Break
    else
    begin
      Result += Str[CurPos];
      Inc(CurPos);
    end;
  end;
end;

function LoadMatrix(const Node: TDOMNode): TLabMat;
  var Data: DOMString;
  var x, y, p: TVkInt32;
begin
  Data := Node.TextContent;
  p := 1;
  for y := 0 to 3 do
  for x := 0 to 3 do
  begin
    Result.Mat[x, y] := StrToFloatDef(AnsiString(FindNextValue(Data, p)), 0);
  end;
end;

procedure TLabColladaObject.SetParent(const Value: TLabColladaObject);
begin
  if _Parent = Value then Exit;
  if Assigned(_Parent) then _Parent._Children.Remove(Self);
  _Parent := Value;
  if Assigned(_Parent) then _Parent._Children.Add(Self);
end;

procedure TLabColladaObject.DumpBegin;
begin
  LabLog(AnsiString(_Tag) + ': {', 2);
end;

procedure TLabColladaObject.DumpEnd;
begin
  LabLog('}', -2);
end;

procedure TLabColladaObject.DumpData;
begin
  if Length(_id) > 0 then LabLog('id: ' + AnsiString(_id));
end;

procedure TLabColladaObject.Resolve;
  var i: TVkInt32;
begin
  ResolveLinks;
  for i := 0 to _Children.Count - 1 do
  begin
    _Children[i].Resolve;
  end;
end;

procedure TLabColladaObject.ResolveLinks;
begin

end;

procedure TLabColladaObject.Initialize;
  var i: TVkInt32;
begin
  for i := 0 to _Children.Count - 1 do
  begin
    _Children[i].Initialize;
  end;
  InitializeObject;
end;

procedure TLabColladaObject.InitializeObject;
begin

end;

function TLabColladaObject.ResolveObject(const Path: DOMString;
  const ObjectClass: CSelf): TLabColladaObject;
begin
  Result := Find(Path);
  if Assigned(Result)
  and not (Result is ObjectClass) then
  begin
    Result := nil;
  end;
end;

constructor TLabColladaObject.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
begin
  _Scoped := False;
  _Children := TLabColladaObjectList.Create;
  _Tag := LowerCase(XMLNode.NodeName);
  _id := FindAttribute(XMLNode, 'id');
  _UserData := nil;
  _AutoFreeUserData := False;
  if Length(_id) = 0 then
  begin
    _id := FindAttribute(XMLNode, 'sid');
    if Length(_id) > 0 then _Scoped := True;
  end;
  Parent := AParent;
end;

destructor TLabColladaObject.Destroy;
begin
  if _AutoFreeUserData and Assigned(_UserData) then _UserData.Free;
  _Children.Free;
  inherited Destroy;
end;

function TLabColladaObject.GetRoot: TLabColladaObject;
begin
  if _Parent = nil then Exit(Self);
  Result := _Parent.GetRoot;
end;

function TLabColladaObject.Find(const Path: DOMString): TLabColladaObject;
  var SearchPath: DOMString;
  var ElementCount, i, p, n: TVkInt32;
  var PathArr: array of DOMString;
begin
  if Length(Path) = 0 then Exit(nil);
  SearchPath := Path;
  if SearchPath[1] = '#' then Delete(SearchPath, 1, 1);
  if Length(SearchPath) = 0 then Exit(nil);
  ElementCount := 1;
  for i := 1 to Length(SearchPath) do if SearchPath[i] = '/' then Inc(ElementCount);
  SetLength(PathArr, ElementCount);
  n := 0;
  p := 1;
  for i := 1 to Length(SearchPath) do
  if SearchPath[i] = '/' then
  begin
    SetLength(PathArr[n], i - p);
    Move(Path[p], PathArr[n][1], (i - p) * SizeOf(WideChar));
    p := i + 1;
    Inc(n);
  end;
  SetLength(PathArr[n], Length(SearchPath) + 1 - p);
  Move(SearchPath[p], PathArr[n][1], (Length(SearchPath) + 1 - p) * SizeOf(WideChar));
  Result := GetRoot;
  for i := 0 to High(PathArr) do
  begin
    Result := Result.FindChildRecursive(PathArr[i]);
    if not Assigned(Result) then Break;
  end;
  if not Assigned(Result) then LabLog('Unresolved link: ' + AnsiString(Path));
end;

function TLabColladaObject.FindChild(const NodeID: DOMString): TLabColladaObject;
  var i: TVkInt32;
begin
  for i := 0 to _Children.Count - 1 do
  if TLabColladaObject(_Children[i]).id = NodeID then
  begin
    Result := TLabColladaObject(_Children[i]);
    Exit;
  end;
  Result := nil;
end;

function TLabColladaObject.FindChildRecursive(const NodeID: DOMString): TLabColladaObject;
  var i: TVkInt32;
begin
  for i := 0 to _Children.Count - 1 do
  begin
    if TLabColladaObject(_Children[i]).id = NodeID then
    begin
      Result := TLabColladaObject(_Children[i]);
      Exit;
    end
    else
    begin
      Result := TLabColladaObject(_Children[i]).FindChildRecursive(NodeID);
      if Assigned(Result) then Exit;
    end;
  end;
  Result := nil;
end;

procedure TLabColladaObject.Dump;
  var i: TVkInt32;
begin
  DumpBegin;
  DumpData;
  for i := 0 to _Children.Count - 1 do
  begin
    _Children[i].Dump;
  end;
  DumpEnd;
end;

constructor TLabColladaGeometry.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _Name := FindAttribute(XMLNode, 'name');
  _Meshes := TLabColladaMeshList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'mesh' then
    begin
      _Meshes.Add(TLabColladaMesh.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaGeometry.Destroy;
begin
  while _Meshes.Count > 0 do _Meshes.Pop.Free;
  _Meshes.Free;
  inherited Destroy;
end;

procedure TLabColladaInput.ResolveLinks;
  var Obj: TLabColladaObject;
begin
  inherited ResolveLinks;
  Obj := Find(_SourceRef);
  if Assigned(Obj) and ((Obj is TLabColladaSource) or (Obj is TLabColladaVertices)) then
  begin
    _Source := Obj;
  end;
end;

constructor TLabColladaInput.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
begin
  inherited Create(XMLNode, AParent);
  _Semantic := UpperCase(FindAttribute(XMLNode, 'semantic'));
  _SourceRef := FindAttribute(XMLNode, 'source');
  _Offset := StrToIntDef(AnsiString(FindAttribute(XMLNode, 'offset')), 0);
  _Set := StrToIntDef(AnsiString(FindAttribute(XMLNode, 'set')), 0);
end;

destructor TLabColladaInput.Destroy;
begin
  inherited Destroy;
end;

function TLabColladaDataArray.GetAsBool(const Index: TVkInt32): PBoolean;
  var i: TVkInt32;
begin
  i := _ItemSize * Index;
  if (i < 0) or (i + _ItemSize > Length(_Data)) then Exit(nil);
  Result := PBoolean(@_Data[i]);
end;

function TLabColladaDataArray.GetAsInt(const Index: TVkInt32): PVkInt32;
  var i: TVkInt32;
begin
  i := _ItemSize * Index;
  if (i < 0) or (i + _ItemSize > Length(_Data)) then Exit(nil);
  Result := PVkInt32(@_Data[i]);
end;

function TLabColladaDataArray.GetAsFloat(const Index: TVkInt32): PVkFloat;
  var i: TVkInt32;
begin
  i := _ItemSize * Index;
  if (i < 0) or (i + _ItemSize > Length(_Data)) then Exit(nil);
  Result := PVkFloat(@_Data[i]);
end;

function TLabColladaDataArray.GetAsString(const Index: TVkInt32): DOMString;
begin
  if (Index < 0) or (Index > High(_DataString)) then Exit('');
  Result := _DataString[Index];
end;

function TLabColladaDataArray.GetRawData(const Offset: TVkInt32): Pointer;
begin
  Result := @_Data[Offset];
end;

constructor TLabColladaDataArray.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var Data: DOMString;
  var i, p: TVkInt32;
begin
  inherited Create(XMLNode, AParent);
  _ArrayType := NodeNameToArrayType(XMLNode.NodeName);
  _Count := StrToIntDef(AnsiString(FindAttribute(XMLNode, 'count')), 0);
  Data := XMLNode.TextContent;
  p := 1;
  case _ArrayType of
    at_bool:
    begin
      _ItemSize := SizeOf(Boolean);
      SetLength(_Data, _Count * _ItemSize);
      for i := 0 to _Count - 1 do
      begin
        AsBool[i]^ := StrToBoolDef(AnsiString(FindNextValue(Data, p)), False);
      end;
    end;
    at_int:
    begin
      _ItemSize := SizeOf(TVkInt32);
      SetLength(_Data, _Count * _ItemSize);
      for i := 0 to _Count - 1 do
      begin
        AsInt[i]^ := StrToIntDef(AnsiString(FindNextValue(Data, p)), 0);
      end;
    end;
    at_float:
    begin
      _ItemSize := SizeOf(TVkFloat);
      SetLength(_Data, _Count * _ItemSize);
      for i := 0 to _Count - 1 do
      begin
        AsFloat[i]^ := StrToFloatDef(AnsiString(FindNextValue(Data, p)), 0);
      end;
    end;
    at_sidref,
    at_idref,
    at_name:
    begin
      _ItemSize := 0;
      SetLength(_DataString, _Count);
      for i := 0 to _Count - 1 do
      begin
        _DataString[i] := FindNextValue(Data, p);
      end;
    end;
  end;
end;

destructor TLabColladaDataArray.Destroy;
begin
  inherited Destroy;
end;

class function TLabColladaDataArray.NodeNameToArrayType(
  const NodeName: DOMString
): TLabColladaArrayType;
  var NodeNameLC: DOMString;
begin
  NodeNameLC := LowerCase(NodeName);
  if NodeNameLC = 'bool_array' then Exit(at_bool);
  if NodeNameLC = 'float_array' then Exit(at_float);
  if NodeNameLC = 'idref_array' then Exit(at_idref);
  if NodeNameLC = 'int_array' then Exit(at_int);
  if NodeNameLC = 'name_array' then Exit(at_name);
  if NodeNameLC = 'sidref_array' then Exit(at_sidref);
  if NodeNameLC = 'token_array' then Exit(at_token);
  Result := at_invalid;
end;

class function TLabColladaDataArray.TypeNameToArrayType(
  const TypeName: DOMString
): TLabColladaArrayType;
  var TypeNameLC: DOMString;
begin
  TypeNameLC := LowerCase(TypeName);
  if TypeNameLC = 'bool' then Exit(at_bool);
  if TypeNameLC = 'float' then Exit(at_float);
  if TypeNameLC = 'idref' then Exit(at_idref);
  if TypeNameLC = 'int' then Exit(at_int);
  if TypeNameLC = 'name' then Exit(at_name);
  if TypeNameLC = 'sidref' then Exit(at_sidref);
  if TypeNameLC = 'token' then Exit(at_token);
  Result := at_invalid;
end;

class function TLabColladaDataArray.IsDataArrayNode(const XMLNode: TDOMNode): Boolean;
begin
  Result := NodeNameToArrayType(XMLNode.NodeName) <> at_invalid;
end;

function TLabColladaAccessor.GetParams: PParamArr;
begin
  Result := @_Params[0];
end;

procedure TLabColladaAccessor.ResolveLinks;
begin
  inherited ResolveLinks;
  _Source := ResolveObject(_SourceRef, TLabColladaDataArray) as TLabColladaDataArray;
end;

constructor TLabColladaAccessor.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
  var i: TVkInt32;
begin
  inherited Create(XMLNode, AParent);
  _SourceRef := FindAttribute(XMLNode, 'source');
  _Count := StrToIntDef(AnsiString(FindAttribute(XMLNode, 'count')), 0);
  _Stride := StrToIntDef(AnsiString(FindAttribute(XMLNode, 'stride')), 1);
  SetLength(_Params, _Stride);
  for i := 0 to High(_Params) do _Params[i].ParamType := at_invalid;
  CurNode := XMLNode.FirstChild;
  i := 0;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'param' then
    begin
      _Params[i].Name := FindAttribute(CurNode, 'name');
      _Params[i].ParamType := TLabColladaDataArray.TypeNameToArrayType(FindAttribute(CurNode, 'type'));
      Inc(i);
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaAccessor.Destroy;
begin
  inherited Destroy;
end;

constructor TLabColladaSource.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
begin
  inherited Create(XMLNode, AParent);
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    if not Assigned(_DataArray)
    and TLabColladaDataArray.IsDataArrayNode(CurNode) then
    begin
      _DataArray := TLabColladaDataArray.Create(CurNode, Self);
    end;
    CurNode := CurNode.NextSibling;
  end;
  _Accessor := nil;
  CurNode := XMLNode.FindNode('technique_common');
  if Assigned(CurNode) then
  begin
    CurNode := CurNode.FindNode('accessor');
    if Assigned(CurNode) then
    begin
      _Accessor := TLabColladaAccessor.Create(CurNode, Self);
    end;
  end;
end;

destructor TLabColladaSource.Destroy;
begin
  if Assigned(_Accessor) then _Accessor.Free;
  if Assigned(_DataArray) then _DataArray.Free;
  inherited Destroy;
end;

constructor TLabColladaVertices.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _Inputs := TLabColladaInputList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'input' then
    begin
      _Inputs.Add(TLabColladaInput.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaVertices.Destroy;
begin
  while _Inputs.Count > 0 do _Inputs.Pop.Free;
  _Inputs.Free;
  inherited Destroy;
end;

function TLabColladaTriangles.GetVertexSize: TVkInt32;
  var i, j: TVkInt32;
  var src: TLabColladaSource;
begin
  Result := 0;
  for i := 0 to _VertexLayout.Count - 1 do
  begin
    src := TLabColladaSource(_VertexLayout[i].Source);
    Result += src.Accessor.Source.ItemSize * src.Accessor.Stride;
  end;
end;

function TLabColladaTriangles.GetIndices: PLabInt32Arr;
begin
  Result := @_Indices[0];
end;

function TLabColladaTriangles.GetVertexDescriptor: TLabColladaVertexDescriptor;
  var CurAttr: TVkInt32;
  procedure AddInput(const Input: TLabColladaInput);
    const SemanticMap: array[0..5] of record
      Name: String;
      Value: TLabColladaVertexAttributeSemantic;
    end = (
      (Name: 'POSITION'; Value: as_position),
      (Name: 'COLOR'; Value: as_color),
      (Name: 'NORMAL'; Value: as_normal),
      (Name: 'TANGENT'; Value: as_tangent),
      (Name: 'BINORMAL'; Value: as_binormal),
      (Name: 'TEXCOORD'; Value: as_texcoord)
    );
    var Vertices: TLabColladaVertices;
    var Source: TLabColladaSource;
    var i: TVkInt32;
  begin
    if not Assigned(Input) or not Assigned(Input.Source) then Exit;
    if Input.Source is TLabColladaVertices then
    begin
      Vertices := TLabColladaVertices(Input.Source);
      for i := 0 to Vertices.Inputs.Count - 1 do
      begin
        AddInput(Vertices.Inputs[i]);
      end;
    end
    else if Input.Source is TLabColladaSource then
    begin
      Source := TLabColladaSource(Input.Source);
      if Source.DataArray.ArrayType in [at_bool, at_float, at_int] then
      begin
        for i := 0 to High(SemanticMap) do
        if SemanticMap[i].Name = AnsiString(Input.Semantic) then
        begin
          Result[CurAttr].Semantic := SemanticMap[i].Value;
          Result[CurAttr].DataType := Source.DataArray.ArrayType;
          Result[CurAttr].DataCount := Source.Accessor.Stride;
          Result[CurAttr].SetNumber := Input.InputSet;
          Inc(CurAttr);
          Break;
        end;
      end;
    end;
  end;
  var i: TVkInt32;
begin
  SetLength(Result, Inputs.Count);
  CurAttr := 0;
  for i := 0 to Inputs.Count - 1 do
  begin
    AddInput(Inputs[i]);
  end;
  if Length(Result) <> CurAttr then
  begin
    SetLength(Result, CurAttr);
  end;
end;

procedure TLabColladaTriangles.InitializeObject;
  procedure ProcessInput(const Input: TLabColladaInput);
    var i: Integer;
    var Vertices: TLabColladaVertices;
  begin
    if not Assigned(Input) or not Assigned(Input.Source) then Exit;
    if Input.Source is TLabColladaVertices then
    begin
      Vertices := TLabColladaVertices(Input.Source);
      for i := 0 to Vertices.Inputs.Count - 1 do
      begin
        ProcessInput(Vertices.Inputs[i]);
      end;
    end
    else
    begin
      _VertexLayout.Add(Input);
    end;
  end;
  var i: TVkInt32;
begin
  inherited InitializeObject;
  _VertexLayout.Clear;
  for i := 0 to _Inputs.Count - 1 do
  begin
    ProcessInput(_Inputs[i]);
  end;
end;

constructor TLabColladaTriangles.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName, IndexData: DOMString;
  var i, p: TVkInt32;
begin
  inherited Create(XMLNode, AParent);
  _MaterialRef := FindAttribute(XMLNode, 'material');
  _Count := StrToIntDef(AnsiString(FindAttribute(XMLNode, 'count')), 0);
  _Inputs := TLabColladaInputList.Create;
  _VertexLayout := TLabColladaInputList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'input' then
    begin
      _Inputs.Add(TLabColladaInput.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
  CurNode := XMLNode.FindNode('p');
  if Assigned(CurNode) then
  begin
    SetLength(_Indices, _Count * 3 * _Inputs.Count);
    IndexData := CurNode.TextContent;
    p := 1;
    for i := 0 to High(_Indices) do
    begin
      _Indices[i] := StrToIntDef(AnsiString(FindNextValue(IndexData, p)), 0);
    end;
  end;
end;

destructor TLabColladaTriangles.Destroy;
begin
  _VertexLayout.Free;
  while _Inputs.Count > 0 do _Inputs.Pop.Free;
  _Inputs.Free;
  inherited Destroy;
end;

function TLabColladaTriangles.CopyInputData(
  const Target: Pointer;
  const Input: TLabColladaInput;
  const Index: TVkInt32
): Pointer;
  var Dest: PVkUInt8;
  var Vertices: TLabColladaVertices;
  var Source: TLabColladaSource;
  var i: TVkInt32;
begin
  if not Assigned(Input) or not Assigned(Input.Source) then Exit;
  Dest := Target;
  if Input.Source is TLabColladaVertices then
  begin
    Vertices := TLabColladaVertices(Input.Source);
    for i := 0 to Vertices.Inputs.Count - 1 do
    begin
      Dest := CopyInputData(Dest, Vertices.Inputs[i], Index);
    end;
  end
  else if Input.Source is TLabColladaSource then
  begin
    Source := TLabColladaSource(Input.Source);
    if Source.DataArray.ArrayType in [at_bool, at_float, at_int] then
    begin
      Move(
        Source.DataArray.RawData[Source.DataArray.ItemSize * Source.Accessor.Stride * Index]^,
        Dest^,
        Source.DataArray.ItemSize * Source.Accessor.Stride
      );
      Inc(Dest, Source.DataArray.ItemSize * Source.Accessor.Stride);
    end;
  end;
  Result := Dest;
end;

constructor TLabColladaMesh.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _Sources := TLabColladaSourceList.Create;
  _Vertices := nil;
  _TrianglesList := TLabColladaTrianglesList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'source' then
    begin
      _Sources.Add(TLabColladaSource.Create(CurNode, Self));
    end
    else if NodeName = 'vertices' then
    begin
      if not Assigned(_Vertices) then
      begin
        _Vertices := TLabColladaVertices.Create(CurNode, Self);
      end;
    end
    else if NodeName = 'triangles' then
    begin
      _TrianglesList.Add(TLabColladaTriangles.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaMesh.Destroy;
begin
  if Assigned(_Vertices) then _Vertices.Free;
  while _TrianglesList.Count > 0 do _TrianglesList.Pop.Free;
  _TrianglesList.Free;
  while _Sources.Count > 0 do _Sources.Pop.Free;
  _Sources.Free;
  inherited Destroy;
end;

constructor TLabColladaImage.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
begin
  inherited Create(XMLNode, AParent);
  CurNode := XMLNode.FindNode('init_from');
  if Assigned(CurNode) then
  begin
    _Source := CurNode.TextContent;
  end;
end;

destructor TLabColladaImage.Destroy;
begin
  inherited Destroy;
end;

function TLabColladaEffectProfileParam.AsSurface: TDataSurface;
begin
  Result := _Data as TDataSurface;
end;

function TLabColladaEffectProfileParam.AsSampler: TDataSampler;
begin
  Result := _Data as TDataSampler;
end;

function TLabColladaEffectProfileParam.AsFloat: TDataFloat;
begin
  Result := _Data as TDataFloat;
end;

function TLabColladaEffectProfileParam.AsFloat2: TDataFloat2;
begin
  Result := _Data as TDataFloat2;
end;

function TLabColladaEffectProfileParam.AsFloat3: TDataFloat3;
begin
  Result := _Data as TDataFloat3;
end;

function TLabColladaEffectProfileParam.AsFloat4: TDataFloat4;
begin
  Result := _Data as TDataFloat4;
end;

constructor TLabColladaEffectProfileParam.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode, Node: TDOMNode;
  var NodeName, VecData: DOMString;
  var DataSurface: TDataSurface;
  var DataSampler: TDataSampler;
  var DataFloat: TDataFloat;
  var DataFloat2: TDataFloat2;
  var DataFloat3: TDataFloat3;
  var DataFloat4: TDataFloat4;
  var i, p: TVkInt32;
begin
  inherited Create(XMLNode, AParent);
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'surface' then
    begin
      DataSurface := TDataSurface.Create;
      Node := CurNode.FindNode('init_from');
      if Assigned(Node) then
      begin
        DataSurface.InitFrom := Node.TextContent;
      end;
      _Data := DataSurface;
      _ParamType := pt_surface;
    end
    else if (NodeName = 'sampler1d')
    or (NodeName = 'sampler2d')
    or (NodeName = 'sampler3d') then
    begin
      DataSampler := TDataSampler.Create;
      Node := CurNode.FindNode('source');
      if Assigned(Node) then
      begin
        DataSampler.Source := Node.TextContent;
      end;
      _Data := DataSampler;
      _ParamType := pt_sampler;
    end
    else if (NodeName = 'float') then
    begin
      DataFloat := TDataFloat.Create;
      VecData := CurNode.TextContent;
      p := 1;
      DataFloat.Value := StrToFloatDef(AnsiString(FindNextValue(VecData, p)), 0);
      _Data := DataFloat;
      _ParamType := pt_float;
    end
    else if (NodeName = 'float2') then
    begin
      DataFloat2 := TDataFloat2.Create;
      VecData := CurNode.TextContent;
      p := 1;
      for i := 0 to 1 do
      begin
        DataFloat2.Value[i] := StrToFloatDef(AnsiString(FindNextValue(VecData, p)), 0);
      end;
      _Data := DataFloat2;
      _ParamType := pt_float2;
    end
    else if (NodeName = 'float3') then
    begin
      DataFloat3 := TDataFloat3.Create;
      VecData := CurNode.TextContent;
      p := 1;
      for i := 0 to 2 do
      begin
        DataFloat3.Value[i] := StrToFloatDef(AnsiString(FindNextValue(VecData, p)), 0);
      end;
      _Data := DataFloat3;
      _ParamType := pt_float3;
    end
    else if (NodeName = 'float4') then
    begin
      DataFloat4 := TDataFloat4.Create;
      VecData := CurNode.TextContent;
      p := 1;
      for i := 0 to 3 do
      begin
        DataFloat4.Value[i] := StrToFloatDef(AnsiString(FindNextValue(VecData, p)), 0);
      end;
      _Data := DataFloat4;
      _ParamType := pt_float4;
    end
    else
    begin
      CurNode := CurNode.NextSibling;
      Continue;
    end;
    Break;
  end;
end;

destructor TLabColladaEffectProfileParam.Destroy;
begin
  if Assigned(_Data) then _Data.Free;
  inherited Destroy;
end;

procedure TLabColladaEffectProfile.ResolveLinks;
  var i, j: TVkInt32;
  var Obj: TLabColladaObject;
begin
  for i := 0 to _Params.Count - 1 do
  begin
    case _Params[i].ParamType of
      pt_sampler:
      begin
        Obj := Find(_Params[i].AsSampler.Source);
        if (Obj is TLabColladaEffectProfileParam)
        and (TLabColladaEffectProfileParam(Obj).ParamType = pt_surface) then
        begin
          _Params[i].AsSampler.Surface := TLabColladaEffectProfileParam(Obj).AsSurface;
        end;
      end;
      pt_surface:
      begin
        _Params[i].AsSurface.Image := TLabColladaImage(Find(_Params[i].AsSurface.InitFrom));
      end;
    end;
  end;
end;

constructor TLabColladaEffectProfile.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _Params := TLabColladaEffectProfileParamList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'newparam' then
    begin
      _Params.Add(TLabColladaEffectProfileParam.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaEffectProfile.Destroy;
begin
  while _Params.Count > 0 do _Params.Pop.Free;
  _Params.Free;
  inherited Destroy;
end;

constructor TLabColladaEffect.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'profile_common' then Break;
    CurNode := CurNode.NextSibling;
  end;
  if Assigned(CurNode) then
  begin
    _Profile := TLabColladaEffectProfile.Create(CurNode, Self);
  end;
end;

destructor TLabColladaEffect.Destroy;
begin
  if Assigned(_Profile) then _Profile.Free;
  inherited Destroy;
end;

constructor TLabColladaMaterial.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
begin
  inherited Create(XMLNode, AParent);
  CurNode := XMLNode.FindNode('instance_effect');
  if Assigned(CurNode) then
  begin
    _InstanceEffect := TLabColladaInstanceEffect.Create(CurNode, Self);
  end;
end;

destructor TLabColladaMaterial.Destroy;
begin
  FreeAndNil(_InstanceEffect);
  inherited Destroy;
end;

constructor TLabColladaInstance.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
begin
  inherited Create(XMLNode, AParent);
  _url := FindAttribute(XMLNode, 'url');
end;

destructor TLabColladaInstance.Destroy;
begin
  inherited Destroy;
end;

procedure TLabColladaInstanceMaterial.ResolveLinks;
  var Obj: TLabColladaObject;
begin
  inherited ResolveLinks;
  Obj := Find(_Target);
  if Assigned(Obj) and (Obj is TLabColladaMaterial) then
  begin
    _Material := TLabColladaMaterial(Obj);
  end;
end;

constructor TLabColladaInstanceMaterial.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
begin
  inherited Create(XMLNode, AParent);
  _Symbol := FindAttribute(XMLNode, 'symbol');
  _Target := FindAttribute(XMLNode, 'target');
end;

destructor TLabColladaInstanceMaterial.Destroy;
begin
  inherited Destroy;
end;

procedure TLabColladaInstanceEffect.ResolveLinks;
  var Obj: TLabColladaObject;
begin
  inherited ResolveLinks;
  Obj := Find(url);
  if Assigned(Obj) and (Obj is TLabColladaEffect) then
  begin
    _Effect := TLabColladaEffect(Obj);
  end;
end;

constructor TLabColladaInstanceEffect.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
begin
  inherited Create(XMLNode, AParent);
end;

destructor TLabColladaInstanceEffect.Destroy;
begin
  inherited Destroy;
end;

procedure TLabColladaInstanceGeometry.ResolveLinks;
  var Obj: TLabColladaObject;
begin
  inherited ResolveLinks;
  Obj := Find(url);
  if Assigned(Obj) and (Obj is TLabColladaGeometry) then
  begin
    _Geometry := TLabColladaGeometry(Obj);
  end;
end;

constructor TLabColladaInstanceGeometry.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _Geometry := nil;
  _MaterialBindings := TLabColladaInstanceMaterialList.Create;
  CurNode := XMLNode.FindNode('bind_material');
  if Assigned(CurNode) then
  begin
    CurNode := CurNode.FindNode('technique_common');
    if Assigned(CurNode) then
    begin
      CurNode := CurNode.FirstChild;
      while Assigned(CurNode) do
      begin
        NodeName := LowerCase(CurNode.NodeName);
        if NodeName = 'instance_material' then
        begin
          _MaterialBindings.Add(TLabColladaInstanceMaterial.Create(CurNode, Self));
        end;
        CurNode := CurNode.NextSibling;
      end;
    end;
  end;
end;

destructor TLabColladaInstanceGeometry.Destroy;
begin
  while _MaterialBindings.Count > 0 do _MaterialBindings.Pop.Free;
  _MaterialBindings.Free;
  inherited Destroy;
end;

constructor TLabColladaNode.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var Data, CurLayer: DOMString;
  var p, i: TVkInt32;
  var CurNode: TDOMNode;
  var NodeName: DOMString;
  var XfLookAt: array [0..8] of TVkFloat;
  var XfRotate: array [0..3] of TVkFloat;
  var XfScale: TLabVec3;
  var XfTranslate: TLabVec3;
  var XfSkew: array [0..6] of TVkFloat;
begin
  inherited Create(XMLNode, AParent);
  _Name := FindAttribute(XMLNode, 'name');
  _NodeType := StringToNodeType(FindAttribute(XMLNode, 'type'));
  _Layers := TLabListDOMString.Create;
  _Nodes := TLabColladaNodeList.Create;
  _Instances := TLabColladaInstanceList.Create;
  Data := FindAttribute(XMLNode, 'layer');
  if Length(Data) > 0 then
  begin
    p := 1;
    repeat
      CurLayer := FindNextValue(Data, p);
      if Length(CurLayer) > 0 then _Layers.Add(CurLayer);
    until Length(CurLayer) = 0;
  end;
  CurNode := XMLNode.FindNode('matrix');
  if Assigned(CurNode) then
  begin
    Matrix := LoadMatrix(CurNode);
  end
  else
  begin
    CurNode := XMLNode.FindNode('lookat');
    if Assigned(CurNode) then
    begin
      Data := CurNode.TextContent;
      p := 1;
      for i := 0 to 8 do
      begin
        XfLookAt[i] := StrToFloatDef(AnsiString(FindNextValue(Data, p)), 0);
      end;
      Matrix := LabMatView(
        LabVec3(XfLookAt[0], XfLookAt[1], XfLookAt[2]),
        LabVec3(XfLookAt[3], XfLookAt[4], XfLookAt[5]),
        LabVec3(XfLookAt[6], XfLookAt[7], XfLookAt[8])
      );
    end
    else
    begin
      Matrix := LabMatIdentity;
      CurNode := XMLNode.FirstChild;
      while Assigned(CurNode) do
      begin
        NodeName := LowerCase(CurNode.NodeName);
        if NodeName = 'rotate' then
        begin
          Data := CurNode.TextContent;
          p := 1;
          for i := 0 to 3 do
          begin
            XfRotate[i] := StrToFloatDef(AnsiString(FindNextValue(Data, p)), 0);
          end;
          Matrix := Matrix * LabMatRotation(LabVec3(XfRotate[0], XfRotate[1], XfRotate[2]), XfRotate[3] * LabDegToRad);
        end
        else if NodeName = 'scale' then
        begin
          Data := CurNode.TextContent;
          p := 1;
          for i := 0 to 2 do
          begin
            XfScale[i] := StrToFloatDef(AnsiString(FindNextValue(Data, p)), 0);
          end;
          Matrix := Matrix * LabMatScaling(XfScale);
        end
        else if NodeName = 'translate' then
        begin
          Data := CurNode.TextContent;
          p := 1;
          for i := 0 to 2 do
          begin
            XfTranslate[i] := StrToFloatDef(AnsiString(FindNextValue(Data, p)), 0);
          end;
          Matrix := Matrix * LabMatTranslation(XfTranslate);
        end
        else if NodeName = 'skew' then
        begin
          Data := CurNode.TextContent;
          p := 1;
          for i := 0 to 6 do
          begin
            XfSkew[i] := StrToFloatDef(AnsiString(FindNextValue(Data, p)), 0);
          end;
          Matrix := Matrix * LabMatSkew(LabVec3(XfSkew[4], XfSkew[5], XfSkew[6]), LabVec3(XfSkew[1], XfSkew[2], XfSkew[3]), XfSkew[0] * LabDegToRad);
        end;
        CurNode := CurNode.NextSibling;
      end;
    end;
  end;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'node' then
    begin
      _Nodes.Add(TLabColladaNode.Create(CurNode, Self));
    end
    else if NodeName = 'instance_geometry' then
    begin
      _Instances.Add(TLabColladaInstanceGeometry.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaNode.Destroy;
begin
  while _Instances.Count > 0 do _Instances.Pop.Free;
  _Instances.Free;
  while _Nodes.Count > 0 do _Nodes.Pop.Free;
  _Nodes.Free;
  _Layers.Free;
  inherited Destroy;
end;

class function TLabColladaNode.StringToNodeType(const NodeTypeName: DOMString): TLabColladaNodeType;
  var NodeTypeNameLC: DOMString;
begin
  NodeTypeNameLC := LowerCase(NodeTypeName);
  if NodeTypeNameLC = 'node' then Exit(nt_node);
  if NodeTypeNameLC = 'joint' then Exit(nt_joint);
  Result := nt_invalid;
end;

constructor TLabColladaVisualScene.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _Nodes := TLabColladaNodeList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'node' then
    begin
      _Nodes.Add(TLabColladaNode.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaVisualScene.Destroy;
begin
  while _Nodes.Count > 0 do _Nodes.Pop.Free;
  _Nodes.Free;
  inherited Destroy;
end;

constructor TLabColladaLibraryMaterials.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _Materials := TLabColladaMaterialList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'material' then
    begin
      _Materials.Add(TLabColladaMaterial.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaLibraryMaterials.Destroy;
begin
  while _Materials.Count > 0 do _Materials.Pop.Free;
  _Materials.Free;
  inherited Destroy;
end;

constructor TLabColladaLibraryEffects.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _Effects := TLabColladaEffectList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'effect' then
    begin
      _Effects.Add(TLabColladaEffect.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaLibraryEffects.Destroy;
begin
  while _Effects.Count > 0 do _Effects.Pop.Free;
  _Effects.Free;
  inherited Destroy;
end;

constructor TLabColladaLibraryImages.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _Images := TLabColladaImageList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'image' then
    begin
      _Images.Add(TLabColladaImage.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaLibraryImages.Destroy;
begin
  while _Images.Count > 0 do _Images.Pop.Free;
  _Images.Free;
  inherited Destroy;
end;

constructor TLabColladaLibraryGeometries.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _Geometries := TLabColladaGeometryList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'geometry' then
    begin
      _Geometries.Add(TLabColladaGeometry.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaLibraryGeometries.Destroy;
begin
  while _Geometries.Count > 0 do _Geometries.Pop.Free;
  _Geometries.Free;
  inherited Destroy;
end;

constructor TLabColladaLibraryVisualScenes.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _VisualScenes := TLabColladaVisualSceneList.Create;
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'visual_scene' then
    begin
      _VisualScenes.Add(TLabColladaVisualScene.Create(CurNode, Self));
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaLibraryVisualScenes.Destroy;
begin
  while _VisualScenes.Count > 0 do _VisualScenes.Pop.Free;
  _VisualScenes.Free;
  inherited Destroy;
end;

procedure TLabColladaInstanceVisualScene.ResolveLinks;
  var Obj: TLabColladaObject;
begin
  inherited ResolveLinks;
  Obj := Find(url);
  if Assigned(Obj) and (Obj is TLabColladaVisualScene) then
  begin
    _VisualScene := TLabColladaVisualScene(Obj);
  end;
end;

constructor TLabColladaInstanceVisualScene.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
begin
  inherited Create(XMLNode, AParent);
  _VisualScene := nil;
end;

destructor TLabColladaInstanceVisualScene.Destroy;
begin
  inherited Destroy;
end;

constructor TLabColladaScene.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
begin
  inherited Create(XMLNode, AParent);
  CurNode := XMLNode.FindNode('instance_visual_scene');
  if Assigned(CurNode) then
  begin
    _VisualScene := TLabColladaInstanceVisualScene.Create(CurNode, Self);
  end;
end;

destructor TLabColladaScene.Destroy;
begin
  if Assigned(_VisualScene) then
  begin
    _VisualScene.Free;
  end;
  inherited Destroy;
end;

constructor TLabColladaAsset.Create(
  const XMLNode: TDOMNode;
  const AParent: TLabColladaObject
);
  var CurNode: TDOMNode;
  var Str: DOMString;
begin
  inherited Create(XMLNode, AParent);
  _UpAxis.SetIdentity;
  CurNode := XMLNode.FindNode('up_axis');
  if Assigned(CurNode) then
  begin
    Str := LowerCase(CurNode.TextContent);
    if Str = 'x_up' then
    begin
      _UpAxis.SetValue(1, 0);
    end
    else if Str = 'z_up' then
    begin
      _UpAxis.SetValue(0, 2, 1);
    end;
  end;
end;

destructor TLabColladaAsset.Destroy;
begin
  inherited Destroy;
end;

constructor TLabColladaRoot.Create(
  const XMLNode: TDOMNode
);
  var CurNode: TDOMNode;
  var NodeName: DOMString;
begin
  inherited Create(XMLNode, nil);
  CurNode := XMLNode.FirstChild;
  while Assigned(CurNode) do
  begin
    NodeName := LowerCase(CurNode.NodeName);
    if NodeName = 'asset' then
    begin
      _Asset := TLabColladaAsset.Create(CurNode, Self);
    end
    else if NodeName = 'library_cameras' then
    begin
    end
    else if NodeName = 'library_lights' then
    begin
    end
    else if NodeName = 'library_images' then
    begin
      _LibImages := TLabColladaLibraryImages.Create(CurNode, Self);
    end
    else if NodeName = 'library_effects' then
    begin
      _LibEffects := TLabColladaLibraryEffects.Create(CurNode, Self);
    end
    else if NodeName = 'library_materials' then
    begin
      _LibMaterials := TLabColladaLibraryMaterials.Create(CurNode, Self);
    end
    else if NodeName = 'library_geometries' then
    begin
      _LibGeometries := TLabColladaLibraryGeometries.Create(CurNode, Self);
    end
    else if NodeName = 'library_controllers' then
    begin
    end
    else if NodeName = 'library_visual_scenes' then
    begin
      _LibVisualScenes := TLabColladaLibraryVisualScenes.Create(CurNode, Self);
    end
    else if NodeName = 'scene' then
    begin
      _Scene := TLabColladaScene.Create(CurNode, Self);
    end;
    CurNode := CurNode.NextSibling;
  end;
end;

destructor TLabColladaRoot.Destroy;
begin
  FreeAndNil(_LibMaterials);
  FreeAndNil(_LibEffects);
  FreeAndNil(_LibImages);
  FreeAndNil(_LibVisualScenes);
  FreeAndNil(_LibGeometries);
  FreeAndNil(_Scene);
  FreeAndNil(_Asset);
  inherited Destroy;
end;

procedure TLabColladaParser.ReadDocument(const Document: TXMLDocument);
begin
  if UpperCase(Document.DocumentElement.NodeName) <> 'COLLADA' then Exit;
  _RootNode := TLabColladaRoot.Create(Document.DocumentElement);
  _RootNode.Resolve;
  _RootNode.Initialize;
end;

constructor TLabColladaParser.Create(const FileName: String);
  var Doc: TXMLDocument;
begin
  try
    ReadXMLFile(Doc, FileName);
    ReadDocument(Doc);
  finally
    Doc.Free;
  end;
end;

constructor TLabColladaParser.Create(const Steam: TStream);
  var Doc: TXMLDocument;
begin
  try
    ReadXMLFile(Doc, Steam);
    ReadDocument(Doc);
  finally
    Doc.Free;
  end;
end;

destructor TLabColladaParser.Destroy;
begin
  if Assigned(_RootNode) then _RootNode.Free;
  inherited Destroy;
end;

end.
