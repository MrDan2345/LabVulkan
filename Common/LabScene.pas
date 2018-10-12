unit LabScene;

interface

uses
  Vulkan,
  SysUtils,
  Classes,
  Process,
  LabTypes,
  LabUtils,
  LabMath,
  LabColladaParser,
  LabDevice,
  LabBuffer,
  LabShader,
  LabImageData;

type
  TLabScene = class;
  TLabSceneMaterial = class;
  TLabSceneNode = class;

  TLabSceneShader = class (TLabClass)
  private
    type TShaderList = specialize TLabList<TLabSceneShader>;
    class var _List: TShaderList;
    class var _ListSort: Boolean;
    var _Scene: TLabScene;
    var _Hash: TVkUInt32;
    function GetShader: TLabShader; inline;
  protected
    type TShaderType = (st_vs, st_ps);
    var _Shader: TLabShaderShared;
    class function MakeHash(const ShaderCode: String): TVkUInt32;
    class function CmpShaders(const a, b: TLabSceneShader): Boolean;
    class procedure SortList;
    class function Find(const AHash: TVkUInt32): TLabSceneShader;
    class function FindCache(const AHash: TVkUInt32): TLabByteArr;
    class function CompileShader(const ShaderCode: String; const ShaderType: TShaderType; const ShaderHash: TVkUInt32 = 0): TLabByteArr;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    property Scene: TLabScene read _Scene;
    property Hash: TVkUInt32 read _Hash;
    property Shader: TLabShader read GetShader;
    constructor Create(const AScene: TLabScene; const ShaderCode: String; const AHash: TVkUInt32 = 0); virtual;
    constructor Create(const AScene: TLabScene; const ShaderData: TLabByteArr; const AHash: TVkUInt32); virtual;
    destructor Destroy; override;
  end;
  TLabSceneShaderShared = specialize TLabSharedRef<TLabSceneShader>;

  TLabSceneVertexShader = class (TLabSceneShader)
  public
    class function FindOrCreate(const AScene: TLabScene; const ShaderCode: String): TLabSceneVertexShader;
    constructor Create(const AScene: TLabScene; const ShaderCode: String; const AHash: TVkUInt32 = 0); override;
    constructor Create(const AScene: TLabScene; const ShaderData: TLabByteArr; const AHash: TVkUInt32); override;
  end;
  TLabSceneVertexShaderShared = specialize TLabSharedRef<TLabSceneVertexShader>;

  TLabScenePixelShader = class (TLabSceneShader)
  public
    class function FindOrCreate(const AScene: TLabScene; const ShaderCode: String): TLabScenePixelShader;
    constructor Create(const AScene: TLabScene; const ShaderCode: String; const AHash: TVkUInt32 = 0); override;
    constructor Create(const AScene: TLabScene; const ShaderData: TLabByteArr; const AHash: TVkUInt32); override;
  end;
  TLabScenePixelShaderShared = specialize TLabSharedRef<TLabScenePixelShader>;

  TLabSceneShaderFactory = class (TLabClass)
  public
    const SemanticMap: array[0..5] of record
      Name: String;
      Value: TLabColladaVertexAttributeSemantic;
    end = (
      (Name: 'position'; Value: as_position),
      (Name: 'normal'; Value: as_normal),
      (Name: 'tangent'; Value: as_tangent),
      (Name: 'binorman'; Value: as_binormal),
      (Name: 'color'; Value: as_color),
      (Name: 'texcoord'; Value: as_texcoord)
    );
    class function GetSemanticName(const Semantic: TLabColladaVertexAttributeSemantic): String;
    class function GetSemanticValue(const SemanticName: String): TLabColladaVertexAttributeSemantic;
    class function MakeVertexShader(
      const AScene: TLabScene;
      const Desc: TLabColladaVertexDescriptor;
      const Material: TLabSceneMaterial
    ): TLabSceneVertexShader;
    class function MakePixelShader(
      const AScene: TLabScene;
      const Desc: TLabColladaVertexDescriptor;
      const Material: TLabSceneMaterial
    ): TLabScenePixelShader;
  end;

  TLabSceneGeometry = class (TLabClass)
  public
    type TSubset = class
    private
      var _Geometry: TLabSceneGeometry;
      var _UserData: TObject;
    public
      VertexCount: TVkInt32;
      VertexData: Pointer;
      VertexStride: TVkUInt32;
      VertexAttributes: array of TLabVertexBufferAttributeFormat;
      VertexDescriptor: TLabColladaVertexDescriptor;
      IndexCount: TVkInt32;
      IndexData: Pointer;
      IndexStride: TVkUInt8;
      IndexType: TVkIndexType;
      Material: String;
      property Geometry: TLabSceneGeometry read _Geometry;
      property UserData: TObject read _UserData write _UserData;
      procedure FreeVertexData;
      procedure FreeIndexData;
      constructor Create(const AGeometry: TLabSceneGeometry; const Triangles: TLabColladaTriangles);
      destructor Destroy; override;
    end;
    type TSubsetList = specialize TLabList<TSubset>;
  private
    var _Scene: TLabScene;
    var _Subsets: TSubsetList;
    var _UserData: TObject;
  public
    property Scene: TLabScene read _Scene;
    property Subsets: TSubsetList read _Subsets;
    property UserData: TObject read _UserData write _UserData;
    constructor Create(const AScene: TLabScene; const ColladaGeometry: TLabColladaGeometry);
    destructor Destroy; override;
  end;
  TLabSceneGeometryList = specialize TLabList<TLabSceneGeometry>;

  TLabSceneController = class (TLabClass)
  private
    _Scene: TLabScene;
  public
    property Scene: TLabScene read _Scene;
    constructor Create(const AScene: TLabScene);
    destructor Destroy; override;
  end;
  TLabSceneControllerList = specialize TLabList<TLabSceneController>;

  TLabSceneControllerSkin = class (TLabSceneController)
  public
    type TJoint = record
      JointName: AnsiString;
      BindPose: TLabMat;
    end;
    type TJoints = array of TJoint;
    type TWeight = record
      JointIndex: TVkInt32;
      JointWeight: TVkFloat;
    end;
    type TWeights = array of array of TWeight;
  private
    var _Geometry: TLabColladaGeometry;
    var _BindShapeMatrix: TLabMat;
    var _Joints: TJoints;
    var _Weights: TWeights;
    var _MaxWeightCount: TVkInt32;
  public
    property Geometry: TLabColladaGeometry read _Geometry;
    property BindShapeMatrix: TLabMat read _BindShapeMatrix;
    property Joints: TJoints read _Joints;
    property Weights: TWeights read _Weights;
    property MaxWeightCount: TVkInt32 read _MaxWeightCount;
    constructor Create(const AScene: TLabScene; const ColladaSkin: TLabColladaSkin);
    destructor Destroy; override;
  end;

  TLabSceneImage = class (TLabClass)
  private
    var _Scene: TLabScene;
    var _Image: TLabImageData;
    var _UserData: TObject;
  public
    property Scene: TLabScene read _Scene;
    property Image: TLabImageData read _Image;
    property UserData: TObject read _UserData write _UserData;
    constructor Create(const AScene: TLabScene; const ColladaImage: TLabColladaImage);
    destructor Destroy; override;
  end;
  TLabSceneImageList = specialize TLabList<TLabSceneImage>;

  TLabSceneEffectParameter = class (TLabClass)
  protected
    var _Scene: TLabScene;
    var _ParameterType: TLabColladaEffectProfileParamType;
    var _Name: String;
  public
    property ParameterType: TLabColladaEffectProfileParamType read _ParameterType;
    property Name: String read _Name;
    constructor Create(const AScene: TLabScene; const AName: String);
  end;
  TLabSceneEffectParameterList = specialize TLabList<TLabSceneEffectParameter>;

  TLabSceneEffectParameterSampler = class (TLabSceneEffectParameter)
  private
    var _Image: TLabSceneImage;
  public
    property Image: TLabSceneImage read _Image;
    constructor Create(const AScene: TLabScene; const Param: TLabColladaEffectProfileParam);
  end;

  TLabSceneEffectParameterFloat = class (TLabSceneEffectParameter)
  public
    constructor Create(const AScene: TLabScene; const Param: TLabColladaEffectProfileParam);
  end;

  TLabSceneEffectParameterFloat2 = class (TLabSceneEffectParameter)
  public
    constructor Create(const AScene: TLabScene; const Param: TLabColladaEffectProfileParam);
  end;

  TLabSceneEffectParameterFloat3 = class (TLabSceneEffectParameter)
  public
    constructor Create(const AScene: TLabScene; const Param: TLabColladaEffectProfileParam);
  end;

  TLabSceneEffectParameterFloat4 = class (TLabSceneEffectParameter)
  public
    constructor Create(const AScene: TLabScene; const Param: TLabColladaEffectProfileParam);
  end;

  TLabSceneEffect = class (TLabClass)
  private
    var _Scene: TLabScene;
    var _Params: TLabSceneEffectParameterList;
  public
    property Scene: TLabScene read _Scene;
    property Params: TLabSceneEffectParameterList read _Params;
    constructor Create(const AScene: TLabScene; const ColladaEffect: TLabColladaEffect);
    destructor Destroy; override;
  end;
  TLabSceneEffectList = specialize TLabList<TLabSceneEffect>;

  TLabSceneMaterial = class (TLabClass)
  private
    var _Scene: TLabScene;
    var _Effect: TLabSceneEffect;
  public
    property Scene: TLabScene read _Scene;
    property Effect: TLabSceneEffect read _Effect;
    constructor Create(const AScene: TLabScene; const ColladaMaterial: TLabColladaMaterial);
    destructor Destroy; override;
  end;
  TLabSceneMaterialList = specialize TLabList<TLabSceneMaterial>;

  TLabSceneAnimationTrack = class (TLabClass)
  public
    type TSampleType = (
      st_invalid,
      st_rotation_x,
      st_rotation_y,
      st_rotation_z,
      st_scale_x,
      st_scale_y,
      st_scale_z,
      st_position_x,
      st_position_y,
      st_position_z,
      st_transform
    );
    type TSampleTypeSet = set of TSampleType;
    const TSampleSingleFloat = [
      st_rotation_x, st_rotation_y, st_rotation_z,
      st_scale_x, st_scale_y, st_scale_z,
      st_position_x, st_position_y, st_position_z
    ];
    const TSampleRotationAngle = [
      st_rotation_x, st_rotation_y, st_rotation_z
    ];
    const TSampleScaling = [
      st_scale_x, st_scale_y, st_scale_z
    ];
    const TSamplePosition = [
      st_position_x, st_position_y, st_position_z
    ];
    type TKey = record
      Time: TVkFloat;
      Value: PVkFloat;
      Interpolation: TLabColladaAnimationInterpolation;
    end;
  private
    var _SampleType: TSampleType;
    var _SampleSize: TVkUInt32;
    var _SampleCount: TVkUInt32;
    var _Target: TLabSceneNode;
    var _MaxTime: TVkFloat;
    var _Keys: array of TKey;
    var _Data: Pointer;
    var _Sample: Pointer;
    function FindKey(const Time: TVkFloat; const Loop: Boolean = False): TVkInt32;
    procedure SampleData(const Output: Pointer; const Time: TVkFloat; const Loop: Boolean = False);
  public
    property MaxTime: TVkFloat read _MaxTime;
    procedure Sample(const Time: TVkFloat; const Loop: Boolean = False);
    constructor Create(const AScene: TLabScene; const ColladaChannel: TLabColladaAnimationChannel);
    destructor Destroy; override;
  end;
  TLabSceneAnimationTrackList = specialize TLabList<TLabSceneAnimationTrack>;

  TLabSceneAnimation = class (TLabClass)
  public
    type TList = specialize TLabList<TLabSceneAnimation>;
  private
    var _Scene: TLabScene;
    var _Animations: TList;
    var _Tracks: TLabSceneAnimationTrackList;
    function GetMaxTime: TVkFloat;
  public
    property Animations: TList read _Animations;
    property Tracks: TLabSceneAnimationTrackList read _Tracks;
    property MaxTime: TVkFloat read GetMaxTime;
    procedure Sample(const Time: TVkFloat; const Loop: Boolean = False);
    constructor Create(const AScene: TLabScene; const ColladaAnimation: TLabColladaAnimation);
    destructor Destroy; override;
  end;
  TLabSceneAnimationList = TLabSceneAnimation.TList;

  TLabSceneAnimationClip = class (TLabClass)
  private
    var _Name: AnsiString;
    var _Scene: TLabScene;
    var _Animations: TLabSceneAnimationList;
    var _MaxTime: TVkFloat;
  public
    property Name: AnsiString read _Name;
    property Animations: TLabSceneAnimationList read _Animations;
    property MaxTime: TVkFloat read _MaxTime;
    procedure Sample(const Time: TVkFloat; const Loop: Boolean = False);
    procedure UpdateMaxTime;
    constructor Create(const AScene: TLabScene; const AName: AnsiString);
    destructor Destroy; override;
  end;
  TLabSceneAnimationClipList = specialize TLabList<TLabSceneAnimationClip>;

  TLabSceneNodeAttachment = class (TLabClass)
  private
    var _Scene: TLabScene;
    var _Node: TLabSceneNode;
    var _UserData: TObject;
  public
    property UserData: TObject read _UserData write _UserData;
    constructor Create(const AScene: TLabScene; const ANode: TLabSceneNode);
    destructor Destroy; override;
  end;
  TLabSceneNodeAttachmentList = specialize TLabList<TLabSceneNodeAttachment>;

  type TLabSceneMaterialBinding = class
  private
    var _UserData: TObject;
  public
    Material: TLabSceneMaterial;
    Symbol: String;
    property UserData: TObject read _UserData write _UserData;
    destructor Destroy; override;
  end;
  type TLabSceneMaterialBindingList = specialize TLabList<TLabSceneMaterialBinding>;

  TLabSceneNodeAttachmentGeometry = class (TLabSceneNodeAttachment)
  private
    var _Geometry: TLabSceneGeometry;
    var _MaterialBindings: TLabSceneMaterialBindingList;
  public
    property Geometry: TLabSceneGeometry read _Geometry;
    property MaterialBindings: TLabSceneMaterialBindingList read _MaterialBindings;
    constructor Create(const AScene: TLabScene; const ANode: TLabSceneNode; const ColladaInstanceGeometry: TLabColladaInstanceGeometry);
    destructor Destroy; override;
  end;
  TLabSceneNodeAttachmentGeometryList = specialize TLabList<TLabSceneNodeAttachmentGeometry>;

  TLabSceneNodeAttachmentController = class (TLabSceneNodeAttachment)
  private
    var _Controller: TLabSceneController;
    var _Skeleton: TLabSceneNode;
    var _MaterialBindings: TLabSceneMaterialBindingList;
  public
    property Controller: TLabSceneController read _Controller;
    property Skeleton: TLabSceneNode read _Skeleton;
    property MaterialBindings: TLabSceneMaterialBindingList read _MaterialBindings;
    constructor Create(const AScene: TLabScene; const ANode: TLabSceneNode; const ColladaInstanceController: TLabColladaInstanceController);
    destructor Destroy; override;
  end;
  TLabSceneNodeAttachmentControllerList = specialize TLabList<TLabSceneNodeAttachmentController>;

  TLabSceneNode = class (TLabClass)
  public
    type TNodeList = specialize TLabList<TLabSceneNode>;
  private
    var _Scene: TLabScene;
    var _Parent: TLabSceneNode;
    var _Name: AnsiString;
    var _Children: TNodeList;
    var _Transform: TLabMat;
    var _Attachments: TLabSceneNodeAttachmentList;
    var _UserData: TObject;
    procedure SetParent(const Value: TLabSceneNode);
  public
    property Scene: TLabScene read _Scene;
    property Parent: TLabSceneNode read _Parent write SetParent;
    property Name: AnsiString read _Name;
    property Children: TNodeList read _Children;
    property Transform: TLabMat read _Transform write _Transform;
    property Attachments: TLabSceneNodeAttachmentList read _Attachments;
    property UserData: TObject read _UserData write _UserData;
    constructor Create(
      const AScene: TLabScene;
      const AParent: TLabSceneNode;
      const ANode: TLabColladaNode
    );
    destructor Destroy; override;
  end;

  TLabScene = class (TLabClass)
  private
    var _Path: String;
    var _Device: TLabDeviceShared;
    var _Root: TLabSceneNode;
    var _AxisRemap: TLabSwizzle;
    var _Images: TLabSceneImageList;
    var _Geometries: TLabSceneGeometryList;
    var _Controllers: TLabSceneControllerList;
    var _Effects: TLabSceneEffectList;
    var _Materials: TLabSceneMaterialList;
    var _Animations: TLabSceneAnimationList;
    var _AnimationClips: TLabSceneAnimationClipList;
    var _DefaultAnimationClip: TLabSceneAnimationClip;
  public
    property Device: TLabDeviceShared read _Device;
    property Root: TLabSceneNode read _Root;
    property AxisRemap: TLabSwizzle read _AxisRemap;
    property Images: TLabSceneImageList read _Images;
    property Effects: TLabSceneEffectList read _Effects;
    property Materials: TLabSceneMaterialList read _Materials;
    property Geometries: TLabSceneGeometryList read _Geometries;
    property Controllers: TLabSceneControllerList read _Controllers;
    property Animations: TLabSceneAnimationList read _Animations;
    property AnimationClips: TLabSceneAnimationClipList read _AnimationClips;
    property DefaultAnimationClip: TLabSceneAnimationClip read _DefaultAnimationClip;
    procedure Add(const FileName: String);
    function FindAnimationClip(const Name: AnsiString): TLabSceneAnimationClip;
    function FindNode(const Name: AnsiString): TLabSceneNode;
    function ResolvePath(const Path: String): String;
    constructor Create(const ADevice: TLabDeviceShared);
    destructor Destroy; override;
  end;

implementation

class function TLabSceneShaderFactory.GetSemanticName(const Semantic: TLabColladaVertexAttributeSemantic): String;
  var i: TVkInt32;
begin
  for i := 0 to High(SemanticMap) do
  if SemanticMap[i].Value = Semantic then
  begin
    Exit(SemanticMap[i].Name);
  end;
  Result := '';
end;

class function TLabSceneShaderFactory.GetSemanticValue(const SemanticName: String): TLabColladaVertexAttributeSemantic;
  var i: TVkInt32;
begin
  for i := 0 to High(SemanticMap) do
  if SemanticMap[i].Name = SemanticName then
  begin
    Exit(SemanticMap[i].Value);
  end;
  Result := as_invalid;
end;

class function TLabSceneShaderFactory.MakeVertexShader(
  const AScene: TLabScene;
  const Desc: TLabColladaVertexDescriptor;
  const Material: TLabSceneMaterial
): TLabSceneVertexShader;
  var ShaderCode: String = '#version 400'#$D#$A +
    '#extension GL_ARB_separate_shader_objects : enable'#$D#$A +
    '#extension GL_ARB_shading_language_420pack : enable'#$D#$A +
    'layout (std140, binding = 0) uniform t_xf {'#$D#$A +
    '  mat4 w;'#$D#$A +
    '  mat4 v;'#$D#$A +
    '  mat4 p;'#$D#$A +
    '  mat4 wvp;'#$D#$A +
    '} xf;'#$D#$A +
    '<$attribs$>' +
    'out gl_PerVertex {'#$D#$A +
    '  vec4 gl_Position;'#$D#$A +
    '};'#$D#$A +
    'void main() {'#$D#$A +
    '<$code$>' +
    '}'
  ;
  var StrAttrIn: String;
  var StrAttrOut: String;
  var StrCode: String;
  var Code: String;
  var Sem: String;
  var i, loc_in, loc_out: Integer;
begin
  StrAttrIn := '';
  StrAttrOut := '';
  StrCode := '';
  loc_in := 0;
  loc_out := 0;
  for i := 0 to High(Desc) do
  begin
    Sem := GetSemanticName(Desc[i].Semantic) + IntToStr(Desc[i].SetNumber);
    StrAttrIn += 'layout (location = ' + IntToStr(loc_in) + ') in vec' + IntToStr(Desc[i].DataCount) + ' in_' + Sem + ';'#$D#$A;
    Inc(loc_in);
    if (Desc[i].Semantic = as_position) then
    begin
      case Desc[i].DataCount of
        0: StrCode += '  gl_Position = vec4(0, 0, 0, 1);'#$D#$A;
        1: StrCode += '  gl_Position = xf.wvp * vec4(in_position0, 0, 0, 1);'#$D#$A;
        2: StrCode += '  gl_Position = xf.wvp * vec4(in_position0, 0, 1);'#$D#$A;
        3: StrCode += '  gl_Position = xf.wvp * vec4(in_position0, 1);'#$D#$A;
        4: StrCode += '  gl_Position = xf.wvp * in_position0;'#$D#$A;
      end;
    end
    else if (Desc[i].Semantic = as_normal) then
    begin
      case Desc[i].DataCount of
        1: StrCode += '  out_' + Sem + ' = mat3(xf.w) * vec3(in_' + Sem + ', 0, 0);'#$D#$A;
        2: StrCode += '  out_' + Sem + ' = mat3(xf.w) * vec3(in_' + Sem + ', 0);'#$D#$A;
        3: StrCode += '  out_' + Sem + ' = mat3(xf.w) * in_' + Sem + ';'#$D#$A;
        4: StrCode += '  out_' + Sem + ' = mat3(xf.w) * vec3(in_' + Sem + '.xyz);'#$D#$A;
      end;
      StrAttrOut += 'layout (location = ' + IntToStr(loc_out) + ') out vec3 out_' + Sem + ';'#$D#$A;
      Inc(loc_out);
    end
    else
    begin
      StrAttrOut += 'layout (location = ' + IntToStr(loc_out) + ') out vec' + IntToStr(Desc[i].DataCount) + ' out_' + Sem + ';'#$D#$A;
      Inc(loc_out);
      StrCode += '  out_' + Sem + ' = in_' + Sem + ';'#$D#$A;
    end;
  end;
  Code := LabStrReplace(ShaderCode, '<$attribs$>', StrAttrIn + StrAttrOut);
  Code := LabStrReplace(Code, '<$code$>', StrCode);
  Result := TLabSceneVertexShader.FindOrCreate(AScene, Code);
end;

class function TLabSceneShaderFactory.MakePixelShader(
  const AScene: TLabScene;
  const Desc: TLabColladaVertexDescriptor;
  const Material: TLabSceneMaterial
): TLabScenePixelShader;
  var ShaderCode: String = '#version 400'#$D#$A +
    '#extension GL_ARB_separate_shader_objects : enable'#$D#$A +
    '#extension GL_ARB_shading_language_420pack : enable'#$D#$A +
    '<$attribs$>' +
    'void main() {'#$D#$A +
    '<$code$>' +
    '}'
  ;
  var StrAttr: String;
  var StrCode: String;
  var Code: String;
  var Sem: String;
  var i, loc: TVkInt32;
  var Texture: String;
  var TexCoord: String;
begin
  StrAttr := '';
  Texture := '';
  TexCoord := '';
  for i := 0 to Material.Effect.Params.Count - 1 do
  if Material.Effect.Params[i].ParameterType = pt_sampler then
  begin
    Texture := 'tex_sampler0';
    Break;
  end;
  if Length(Texture) > 0 then
  begin
    StrAttr += 'layout (binding = 1) uniform sampler2D ' + Texture + ';'#$D#$A;
  end;
  loc := 0;
  StrCode := '  vec4 color = vec4(1, 1, 1, 1);'#$D#$A;
  for i := 0 to High(Desc) do
  begin
    if Desc[i].Semantic = as_position then Continue;
    Sem := GetSemanticName(Desc[i].Semantic) + IntToStr(Desc[i].SetNumber);
    StrAttr += 'layout (location = ' + IntToStr(loc) + ') in vec' + IntToStr(Desc[i].DataCount) + ' in_' + Sem + ';'#$D#$A;
    Inc(loc);
    case Desc[i].Semantic of
      as_normal:
      begin
        case Desc[i].DataCount of
          1: StrCode += '  vec3 normal = normalize(vec3(in_' + Sem + ', 0, 0));'#$D#$A;
          2: StrCode += '  vec3 normal = normalize(vec3(in_' + Sem + ', 0));'#$D#$A;
          4: StrCode += '  vec3 normal = normalize(in_' + Sem + '.xyz);'#$D#$A;
          else StrCode += '  vec3 normal = normalize(in_' + Sem + ');'#$D#$A;
        end;
        StrCode += '  color.xyz *= 1.4 * ((dot(normal, normalize(vec3(1, 1, -1))) * 0.5 + 0.5) * 0.9 + 0.1);'#$D#$A;
      end;
      as_color:
      begin
        case Desc[i].DataCount of
          1: StrCode += '  color.x *= in_' + Sem + ';'#$D#$A;
          2: StrCode += '  color.xy *= in_' + Sem + ';'#$D#$A;
          3: StrCode += '  color.xyz *= in_' + Sem + ';'#$D#$A;
          4: StrCode += '  color *= in_' + Sem + ';'#$D#$A;
        end;
      end;
      as_texcoord:
      begin
        if Length(TexCoord) = 0 then TexCoord := 'in_' + Sem;
      end;
    end;
  end;
  StrAttr += 'layout (location = 0) out vec4 out_color;'#$D#$A;
  if (Length(Texture) > 0)
  and (Length(TexCoord) > 0) then
  begin
    StrCode += '  color *= texture(' + Texture + ', vec2(' + TexCoord + '.x, -' + TexCoord + '.y));'#$D#$A;
  end;
  StrCode += '  out_color = color;'#$D#$A;
  //StrCode += '  out_color = texture(tex_sampler0, vec2(in_texcoord0.x, 1 - in_texcoord0.y));'#$D#$A;
  Code := LabStrReplace(ShaderCode, '<$attribs$>', StrAttr);
  Code := LabStrReplace(Code, '<$code$>', StrCode);
  Result := TLabScenePixelShader.FindOrCreate(ASCene, Code);
end;

function TLabSceneShader.GetShader: TLabShader;
begin
  Result := _Shader.Ptr;
end;

class function TLabSceneShader.MakeHash(const ShaderCode: String): TVkUInt32;
begin
  Result := LabCRC32(0, @ShaderCode[1], Length(ShaderCode));
end;

class function TLabSceneShader.CmpShaders(const a, b: TLabSceneShader): Boolean;
begin
  Result := a.Hash > b.Hash;
end;

class procedure TLabSceneShader.SortList;
begin
  if (not _ListSort) then Exit;
  _List.Sort(@CmpShaders);
  _ListSort := False;
end;

class function TLabSceneShader.Find(const AHash: TVkUInt32): TLabSceneShader;
  var l, h, m: Integer;
begin
  SortList;
  l := 0;
  h := _List.Count - 1;
  while l <= h do
  begin
    m := (l + h) shr 1;
    if _List[m].Hash > AHash then
    h := m - 1
    else if _List[m].Hash < AHash then
    l := m + 1
    else Exit(_List[m]);
  end;
  if (l < _List.Count)
  and (_List[l].Hash = AHash)
  then Exit(_List[l]) else Exit(nil);
end;

class function TLabSceneShader.FindCache(const AHash: TVkUInt32): TLabByteArr;
  var f: String;
  var fs: TFileStream;
begin
  f := ExpandFileName('../ShaderCache/' + IntToHex(AHash, 8) + '.spv');
  if FileExists(f) then
  begin
    fs := TFileStream.Create(f, fmOpenRead);
    try
      SetLength(Result, fs.Size);
      fs.Read(Result[0], fs.Size);
    finally
      fs.Free;
    end;
  end
  else
  begin
    Result := nil;
  end;
end;

class function TLabSceneShader.CompileShader(const ShaderCode: String; const ShaderType: TShaderType; const ShaderHash: TVkUInt32): TLabByteArr;
  var fs: TFileStream;
  var shader_hash: TVkUInt32;
  var f, fp, vk_dir, st, cl_out: String;
begin
  if ShaderHash = 0 then
  begin
    shader_hash := MakeHash(ShaderCode);
  end
  else
  begin
    shader_hash := ShaderHash;
  end;
  f := UpperCase(IntToHex(shader_hash, 8));
  fp := ExpandFileName('../ShaderCache/');
  if not DirectoryExists(fp) then ForceDirectories(fp);
  fs := TFileStream.Create(fp + f + '.txt', fmCreate);
  try
    fs.WriteBuffer(ShaderCode[1], Length(ShaderCode));
  finally
    fs.Free;
  end;
  vk_dir := GetEnvironmentVariable('VULKAN_SDK');
  if Length(vk_dir) > 0 then
  begin
    case ShaderType of
      st_vs: st := 'vert';
      st_ps: st := 'frag';
    end;
    //SysUtils.ExecuteProcess(
    //  vk_dir + '/Bin32/glslangValidator.exe',
    //  '-V -S ' + st + ' -t "' + fp + f + '.txt" -o "' + fp + f + '.spv"',
    //  []
    //);
    if (
      RunCommand(
        vk_dir + '/Bin32/glslangValidator.exe',
        ['-V -S ' + st + ' -t "' + fp + f + '.txt" -o "' + fp + f + '.spv"'],
        cl_out
      )
    ) then
    begin
      fs := TFileStream.Create(fp + f + '.spv', fmOpenRead);
      try
        SetLength(Result, fs.Size);
        fs.Read(Result[0], fs.Size);
      finally
        fs.Free;
      end;
    end
    else
    begin
      LabLog('Shader Compile Error: '#$D#$A + cl_out);
      Exit(nil);
    end;
  end
  else
  begin
    Exit(nil);
  end;
end;

class constructor TLabSceneShader.CreateClass;
begin
  _List := TShaderList.Create;
  _ListSort := False;
end;

class destructor TLabSceneShader.DestroyClass;
begin
  _List.Free;
end;

constructor TLabSceneShader.Create(const AScene: TLabScene; const ShaderCode: String; const AHash: TVkUInt32);
begin
  _Scene := AScene;
  if (AHash = 0) then
  begin
    _Hash := MakeHash(ShaderCode)
  end
  else
  begin
    _Hash := AHash;
  end;
  _List.Add(Self);
  _ListSort := True;
end;

constructor TLabSceneShader.Create(const AScene: TLabScene; const ShaderData: TLabByteArr; const AHash: TVkUInt32);
begin
  _Scene := AScene;
  _Hash := AHash;
  _List.Add(Self);
  _ListSort := True;
end;

destructor TLabSceneShader.Destroy;
begin
  _Shader := nil;
  _List.Remove(Self);
  inherited Destroy;
end;

class function TLabSceneVertexShader.FindOrCreate(const AScene: TLabScene; const ShaderCode: String): TLabSceneVertexShader;
  var shader_hash: TVkUInt32;
  var shader_data: TLabByteArr;
begin
  shader_hash := MakeHash(ShaderCode);
  Result := TLabSceneVertexShader(Find(shader_hash));
  if Assigned(Result) then Exit;
  shader_data := FindCache(shader_hash);
  if Length(shader_data) > 0 then
  begin
    Result := TLabSceneVertexShader.Create(AScene, shader_data, shader_hash);
    Exit;
  end;
  Result := TLabSceneVertexShader.Create(AScene, ShaderCode, shader_hash);
end;

constructor TLabSceneVertexShader.Create(const AScene: TLabScene; const ShaderCode: String; const AHash: TVkUInt32);
  var shader_data: TLabByteArr;
begin
  inherited Create(AScene, ShaderCode, AHash);
  shader_data := CompileShader(ShaderCode, st_vs, _Hash);
  _Shader := TLabVertexShader.Create(_Scene.Device, @shader_data[0], Length(shader_data));
end;

constructor TLabSceneVertexShader.Create(const AScene: TLabScene; const ShaderData: TLabByteArr; const AHash: TVkUInt32);
begin
  inherited Create(AScene, ShaderData, AHash);
  _Shader := TLabVertexShader.Create(_Scene.Device, @ShaderData[0], Length(ShaderData));
end;

class function TLabScenePixelShader.FindOrCreate(const AScene: TLabScene; const ShaderCode: String): TLabScenePixelShader;
  var shader_hash: TVkUInt32;
  var shader_data: TLabByteArr;
begin
  shader_hash := MakeHash(ShaderCode);
  Result := TLabScenePixelShader(Find(shader_hash));
  if Assigned(Result) then Exit;
  shader_data := FindCache(shader_hash);
  if Length(shader_data) > 0 then
  begin
    Result := TLabScenePixelShader.Create(AScene, shader_data, shader_hash);
    Exit;
  end;
  Result := TLabScenePixelShader.Create(AScene, ShaderCode, shader_hash);
end;

constructor TLabScenePixelShader.Create(const AScene: TLabScene; const ShaderCode: String; const AHash: TVkUInt32);
  var shader_data: TLabByteArr;
begin
  inherited Create(AScene, ShaderCode, AHash);
  shader_data := CompileShader(ShaderCode, st_ps, _Hash);
  _Shader := TLabPixelShader.Create(_Scene.Device, @shader_data[0], Length(shader_data));
end;

constructor TLabScenePixelShader.Create(const AScene: TLabScene; const ShaderData: TLabByteArr; const AHash: TVkUInt32);
begin
  inherited Create(AScene, ShaderData, AHash);
  _Shader := TLabPixelShader.Create(_Scene.Device, @ShaderData[0], Length(ShaderData));
end;

destructor TLabSceneMaterialBinding.Destroy;
begin
  FreeAndNil(_UserData);
  inherited Destroy;
end;

constructor TLabSceneNodeAttachmentGeometry.Create(
  const AScene: TLabScene;
  const ANode: TLabSceneNode;
  const ColladaInstanceGeometry: TLabColladaInstanceGeometry
);
  var i: Integer;
  var mb: TLabSceneMaterialBinding;
begin
  inherited Create(AScene, ANode);
  if Assigned(ColladaInstanceGeometry.Geometry)
  and Assigned(ColladaInstanceGeometry.Geometry.UserData)
  and (ColladaInstanceGeometry.Geometry.UserData is TLabSceneGeometry) then
  begin
    _Geometry := TLabSceneGeometry(ColladaInstanceGeometry.Geometry.UserData);
  end;
  _MaterialBindings := TLabSceneMaterialBindingList.Create;
  for i := 0 to ColladaInstanceGeometry.MaterialBindings.Count - 1 do
  begin
    if Assigned(ColladaInstanceGeometry.MaterialBindings[i].Material)
    and Assigned(ColladaInstanceGeometry.MaterialBindings[i].Material.UserData)
    and (ColladaInstanceGeometry.MaterialBindings[i].Material.UserData is TLabSceneMaterial) then
    begin
      mb := TLabSceneMaterialBinding.Create;
      mb.Material := TLabSceneMaterial(ColladaInstanceGeometry.MaterialBindings[i].Material.UserData);
      mb.Symbol := AnsiString(ColladaInstanceGeometry.MaterialBindings[i].Symbol);
      _MaterialBindings.Add(mb);
    end;
  end;
end;

destructor TLabSceneNodeAttachmentGeometry.Destroy;
begin
  while _MaterialBindings.Count > 0 do _MaterialBindings.Pop.Free;
  _MaterialBindings.Free;
  inherited Destroy;
end;

constructor TLabSceneNodeAttachmentController.Create(
  const AScene: TLabScene;
  const ANode: TLabSceneNode;
  const ColladaInstanceController: TLabColladaInstanceController
);
  var mb: TLabSceneMaterialBinding;
  var i: TVkInt32;
begin
  _Controller := TLabSceneController(ColladaInstanceController.Controller.UserData);
  _Skeleton := TLabSceneNode(ColladaInstanceController.Skeleton.UserData);
  _MaterialBindings := TLabSceneMaterialBindingList.Create;
  for i := 0 to ColladaInstanceController.MaterialBindings.Count - 1 do
  begin
    if Assigned(ColladaInstanceController.MaterialBindings[i].Material)
    and Assigned(ColladaInstanceController.MaterialBindings[i].Material.UserData)
    and (ColladaInstanceController.MaterialBindings[i].Material.UserData is TLabSceneMaterial) then
    begin
      mb := TLabSceneMaterialBinding.Create;
      mb.Material := TLabSceneMaterial(ColladaInstanceController.MaterialBindings[i].Material.UserData);
      mb.Symbol := AnsiString(ColladaInstanceController.MaterialBindings[i].Symbol);
      _MaterialBindings.Add(mb);
    end;
  end;
end;

destructor TLabSceneNodeAttachmentController.Destroy;
begin
  while _MaterialBindings.Count > 0 do _MaterialBindings.Pop.Free;
  _MaterialBindings.Free;
  inherited Destroy;
end;

constructor TLabSceneNodeAttachment.Create(
  const AScene: TLabScene;
  const ANode: TLabSceneNode
);
begin
  _Scene := AScene;
  _Node := ANode;
end;

destructor TLabSceneNodeAttachment.Destroy;
begin
  FreeAndNil(_UserData);
  inherited Destroy;
end;

procedure TLabSceneGeometry.TSubset.FreeVertexData;
begin
  if Assigned(VertexData) then
  begin
    FreeMemory(VertexData);
    VertexData := nil;
  end;
end;

procedure TLabSceneGeometry.TSubset.FreeIndexData;
begin
  if Assigned(IndexData) then
  begin
    FreeMemory(IndexData);
    IndexData := nil;
  end;
end;

constructor TLabSceneGeometry.TSubset.Create(
  const AGeometry: TLabSceneGeometry;
  const Triangles: TLabColladaTriangles
);
  function GetFormat(const Source: TLabColladaSource): TVkFormat;
  begin
    case Source.DataArray.ArrayType of
      at_float:
      begin
        case Source.Accessor.Stride of
          1: Result := VK_FORMAT_R32_SFLOAT;
          2: Result := VK_FORMAT_R32G32_SFLOAT;
          3: Result := VK_FORMAT_R32G32B32_SFLOAT;
          4: Result := VK_FORMAT_R32G32B32A32_SFLOAT;
          else Result := VK_FORMAT_UNDEFINED;
        end;
      end;
      at_int:
      begin
        case Source.Accessor.Stride of
          1: Result := VK_FORMAT_R32_SINT;
          2: Result := VK_FORMAT_R32G32_SINT;
          3: Result := VK_FORMAT_R32G32B32_SINT;
          4: Result := VK_FORMAT_R32G32B32A32_SINT;
          else Result := VK_FORMAT_UNDEFINED;
        end;
      end;
      at_bool:
      begin
        case Source.Accessor.Stride of
          1: Result := VK_FORMAT_R8_UINT;
          2: Result := VK_FORMAT_R8G8_UINT;
          3: Result := VK_FORMAT_R8G8B8_UINT;
          4: Result := VK_FORMAT_R8G8B8A8_UINT;
          else Result := VK_FORMAT_UNDEFINED;
        end;
      end
      else Result := VK_FORMAT_UNDEFINED;
    end;
  end;
  type TVertexRemap = record
    VertexIndex: TVkUInt32;
    crc: TVkUInt32;
  end;
  type TVertexRemapArr = array[0..High(Word)] of TVertexRemap;
  type PVertexRemapArr = ^TVertexRemapArr;
  var VertexRemap: PVertexRemapArr;
  function FindRemap(const crc: TVkUInt32): TVkInt32;
    var i: TVkInt32;
  begin
    for i := 0 to VertexCount - 1 do
    if VertexRemap^[i].crc = crc then
    begin
      Exit(VertexRemap^[i].VertexIndex);
    end;
    Exit(-1);
  end;
  var BufferPtrVert, BufferPtrInd: Pointer;
  procedure AddIndex(const Index: TVkUInt32);
  begin
    if IndexType = VK_INDEX_TYPE_UINT16 then
    begin
      PVkUInt16(BufferPtrInd)^ := TVkUInt16(Index);
    end
    else
    begin
      PVkUInt32(BufferPtrInd)^ := Index;
    end;
    Inc(BufferPtrInd, IndexStride);
    Inc(IndexCount);
  end;
  var AttribIndices: array of TVkInt32;
  var AttribSwizzles: array of TLabSwizzle;
  var Source: TLabColladaSource;
  var i, j, Offset, ind: TVkInt32;
  var crc, max_offset: TVkUInt32;
  var AssetSwizzle: TLabSwizzle;
  var Root: TLabColladaRoot;
begin
  _Geometry := AGeometry;
  VertexCount := 0;
  IndexCount := 0;
  Triangles.UserData := Self;
  VertexStride := Triangles.VertexSize;
  Material := AnsiString(Triangles.Material);
  if Triangles.Count * 3 > High(TVkUInt16) then
  begin
    IndexStride := 4;
    IndexType := VK_INDEX_TYPE_UINT32;
  end
  else
  begin
    IndexStride := 2;
    IndexType := VK_INDEX_TYPE_UINT16;
  end;
  VertexData := GetMemory(VertexStride * Triangles.Count * 3);
  IndexData := GetMemory(IndexStride * Triangles.Count * 3);
  VertexRemap := PVertexRemapArr(GetMemory(VertexStride * Triangles.Count * 3));
  BufferPtrVert := VertexData;
  BufferPtrInd := IndexData;
  max_offset := 0;
  for i := 0 to Triangles.Inputs.Count - 1 do
  if Triangles.Inputs[i].Offset > max_offset then
  begin
    max_offset := Triangles.Inputs[i].Offset;
  end;
  SetLength(AttribIndices, Triangles.Inputs.Count);
  for i := 0 to Triangles.Count * 3 - 1 do
  begin
    crc := 0;
    for j := 0 to Triangles.Inputs.Count - 1 do
    begin
      Offset := Triangles.Inputs[j].Offset;
      AttribIndices[j] := Triangles.Indices^[i * (max_offset + 1) + Offset];
      crc := LabCRC32(crc, @AttribIndices[j], SizeOf(TVkInt32));
    end;
    ind := FindRemap(crc);
    if ind > -1 then
    begin
      AddIndex(ind);
    end
    else
    begin
      for j := 0 to Triangles.Inputs.Count - 1 do
      begin
        BufferPtrVert := Triangles.CopyInputData(BufferPtrVert, Triangles.Inputs[j], AttribIndices[j]);
      end;
      VertexRemap^[VertexCount].crc := crc;
      VertexRemap^[VertexCount].VertexIndex := VertexCount;
      AddIndex(VertexCount);
      Inc(VertexCount);
    end;
  end;
  Freememory(VertexRemap);
  SetLength(VertexAttributes, Triangles.VertexLayout.Count);
  Offset := 0;
  for i := 0 to Triangles.VertexLayout.Count - 1 do
  begin
    Source := Triangles.VertexLayout[i].Source as TLabColladaSource;
    VertexAttributes[i] := LabVertexBufferAttributeFormat(
      GetFormat(Source), Offset
    );
    Offset += Source.DataArray.ItemSize * Source.Accessor.Stride;
  end;
  VertexDescriptor := Triangles.VertexDescriptor;
  AssetSwizzle := _Geometry.Scene.AxisRemap;
  SetLength(AttribSwizzles, Length(VertexDescriptor));
  Root := TLabColladaRoot(Triangles.GetRoot);
  for i := 0 to High(VertexDescriptor) do
  begin
    if (VertexDescriptor[i].Semantic in [as_position, as_normal, as_tangent, as_binormal]) then
    begin
      AttribSwizzles[i] := AssetSwizzle;
    end
    else
    begin
      AttribSwizzles[i].SetIdentity;
    end;
  end;
  for i := 0 to VertexCount - 1 do
  begin
    for j := 0 to High(VertexAttributes) do
    begin
      BufferPtrVert := VertexData + VertexStride * i + VertexAttributes[j].Offset;
      if VertexDescriptor[j].DataType = at_float then
      begin
        case VertexDescriptor[j].DataCount of
          2: PLabVec2(BufferPtrVert)^ := PLabVec2(BufferPtrVert)^.Swizzle(AttribSwizzles[j]);
          3: PLabVec3(BufferPtrVert)^ := PLabVec3(BufferPtrVert)^.Swizzle(AttribSwizzles[j]);
          4: PLabVec4(BufferPtrVert)^ := PLabVec4(BufferPtrVert)^.Swizzle(AttribSwizzles[j]);
        end;
      end;
    end;
  end;
end;

destructor TLabSceneGeometry.TSubset.Destroy;
begin
  FreeAndNil(_UserData);
  FreeVertexData;
  FreeIndexData;
  inherited Destroy;
end;

constructor TLabSceneGeometry.Create(
  const AScene: TLabScene;
  const ColladaGeometry: TLabColladaGeometry
);
  var i, j: TVkInt32;
begin
  ColladaGeometry.UserData := Self;
  _Scene := AScene;
  _Subsets := TSubsetList.Create;
  for i := 0 to ColladaGeometry.Meshes.Count - 1 do
  begin
    for j := 0 to ColladaGeometry.Meshes[i].TrianglesList.Count - 1 do
    begin
      _Subsets.Add(TSubset.Create(Self, ColladaGeometry.Meshes[i].TrianglesList[j]));
    end;
  end;
end;

destructor TLabSceneGeometry.Destroy;
begin
  while _Subsets.Count > 0 do _Subsets.Pop.Free;
  _Subsets.Free;
  FreeAndNil(_UserData);
  inherited Destroy;
end;

constructor TLabSceneController.Create(
  const AScene: TLabScene
);
begin
  _Scene := AScene;
end;

destructor TLabSceneController.Destroy;
begin
  inherited Destroy;
end;

constructor TLabSceneControllerSkin.Create(
  const AScene: TLabScene;
  const ColladaSkin: TLabColladaSkin
);
  var i, j: TVkInt32;
begin
  inherited Create(AScene);
  ColladaSkin.UserData := Self;
  _BindShapeMatrix := ColladaSkin.BindShapeMatrix;
  _Geometry := TLabColladaGeometry(ColladaSkin.Geometry.UserData);
  SetLength(_Joints, Length(ColladaSkin.Joints.Joints));
  for i := 0 to High(_Joints) do
  begin
    _Joints[i].JointName := AnsiString(ColladaSkin.Joints.Joints[i].JointName);
    _Joints[i].BindPose := ColladaSkin.Joints.Joints[i].BindPose;
  end;
  _MaxWeightCount := 0;
  SetLength(_Weights, ColladaSkin.VertexWeights.VCount);
  for i := 0 to High(_Weights) do
  begin
    SetLength(_Weights[i], Length(ColladaSkin.VertexWeights.Weights[i]));
    if Length(_Weights[i]) > _MaxWeightCount then _MaxWeightCount := Length(_Weights[i]);
    for j := 0 to High(_Weights[i]) do
    begin
      _Weights[i][j].JointIndex := ColladaSkin.VertexWeights.Weights[i][j].JointIndex;
      _Weights[i][j].JointWeight := ColladaSkin.VertexWeights.Weights[i][j].JointWeight;
    end;
  end;
end;

destructor TLabSceneControllerSkin.Destroy;
begin
  inherited Destroy;
end;

constructor TLabSceneImage.Create(
  const AScene: TLabScene;
  const ColladaImage: TLabColladaImage
);
  var Path: String;
begin
  _Scene := AScene;
  ColladaImage.UserData := Self;
  _Image := TLabImageDataPNG.Create;
  Path := AScene.ResolvePath(AnsiString(ColladaImage.Source));
  if FileExists(Path) then
  begin
    _Image.Load(Path);
  end;
end;

destructor TLabSceneImage.Destroy;
begin
  FreeAndNil(_UserData);
  _Image.Free;
  inherited Destroy;
end;

constructor TLabSceneEffectParameter.Create(const AScene: TLabScene; const AName: String);
begin
  _Scene := AScene;
  _Name := AName;
end;

constructor TLabSceneEffectParameterSampler.Create(
  const AScene: TLabScene;
  const Param: TLabColladaEffectProfileParam
);
begin
  _ParameterType := pt_sampler;
  inherited Create(AScene, AnsiString(Param.id));
  if Assigned(Param.AsSampler.Surface)
  and Assigned(Param.AsSampler.Surface.Image) then
  begin
    _Image := TLabSceneImage(Param.AsSampler.Surface.Image.UserData);
  end;
end;

constructor TLabSceneEffectParameterFloat.Create(
  const AScene: TLabScene;
  const Param: TLabColladaEffectProfileParam
);
begin
  _ParameterType := pt_float;
  inherited Create(AScene, AnsiString(Param.id));
end;

constructor TLabSceneEffectParameterFloat2.Create(
  const AScene: TLabScene;
  const Param: TLabColladaEffectProfileParam
);
begin
  _ParameterType := pt_float2;
  inherited Create(AScene, AnsiString(Param.id));
end;

constructor TLabSceneEffectParameterFloat3.Create(
  const AScene: TLabScene;
  const Param: TLabColladaEffectProfileParam
);
begin
  _ParameterType := pt_float3;
  inherited Create(AScene, AnsiString(Param.id));
end;

constructor TLabSceneEffectParameterFloat4.Create(
  const AScene: TLabScene;
  const Param: TLabColladaEffectProfileParam
);
begin
  _ParameterType := pt_float4;
  inherited Create(AScene, AnsiString(Param.id));
end;

constructor TLabSceneEffect.Create(
  const AScene: TLabScene;
  const ColladaEffect: TLabColladaEffect
);
  var i: TVkInt32;
begin
  _Scene := AScene;
  _Params := TLabSceneEffectParameterList.Create;
  ColladaEffect.UserData := Self;
  if Assigned(ColladaEffect.Profile) then
  begin
    for i := 0 to ColladaEffect.Profile.Params.Count - 1 do
    begin
      case ColladaEffect.Profile.Params[i].ParamType of
        pt_sampler: _Params.Add(TLabSceneEffectParameterSampler.Create(_Scene, ColladaEffect.Profile.Params[i]));
        pt_float: _Params.Add(TLabSceneEffectParameterFloat.Create(_Scene, ColladaEffect.Profile.Params[i]));
        pt_float2: _Params.Add(TLabSceneEffectParameterFloat2.Create(_Scene, ColladaEffect.Profile.Params[i]));
        pt_float3: _Params.Add(TLabSceneEffectParameterFloat3.Create(_Scene, ColladaEffect.Profile.Params[i]));
        pt_float4: _Params.Add(TLabSceneEffectParameterFloat4.Create(_Scene, ColladaEffect.Profile.Params[i]));
      end;
    end;
  end;
end;

destructor TLabSceneEffect.Destroy;
begin
  while _Params.Count > 0 do _Params.Pop.Free;
  _Params.Free;
  inherited Destroy;
end;

constructor TLabSceneMaterial.Create(
  const AScene: TLabScene;
  const ColladaMaterial: TLabColladaMaterial
);
begin
  _Scene := AScene;
  ColladaMaterial.UserData := Self;
  if Assigned(ColladaMaterial.InstanceEffect)
  and Assigned(ColladaMaterial.InstanceEffect.Effect)
  and Assigned(ColladaMaterial.InstanceEffect.Effect.UserData)
  and (ColladaMaterial.InstanceEffect.Effect.UserData is TLabSceneEffect) then
  begin
    _Effect := TLabSceneEffect(ColladaMaterial.InstanceEffect.Effect.UserData);
  end;
end;

destructor TLabSceneMaterial.Destroy;
begin
  inherited Destroy;
end;

function TLabSceneAnimationTrack.FindKey(
  const Time: TVkFloat;
  const Loop: Boolean
): TVkInt32;
  var i: TVkInt32;
  var t: TVkFloat;
begin
  t := Time;
  if Loop and (Time > _MaxTime) then
  begin
    t := Time mod _MaxTime;
  end;
  Result := High(_Keys);
  for i := 0 to High(_Keys) do
  if _Keys[i].Time <= Time then
  begin
    Result := i;
  end
  else Break;
end;

procedure TLabSceneAnimationTrack.SampleData(
  const Output: Pointer;
  const Time: TVkFloat;
  const Loop: Boolean
);
  var InFloat0, InFloat1: PVkFloat;
  var OutFloat: PVkFloat;
  var k0, k1, i: TVkInt32;
  var t, tgt0, tgt1: TVkFloat;
begin
  if not Loop then
  begin
    if Time <= _Keys[0].Time then
    begin
      Move(_Keys[0].Value^, Output^, _SampleSize * _SampleCount);
      Exit;
    end;
    if Time >= _Keys[High(_Keys)].Time then
    begin
      Move(_Keys[High(_Keys)].Value^, Output^, _SampleSize * _SampleCount);
      Exit;
    end;
  end;
  k0 := FindKey(Time);
  k1 := (k0 + 1) mod Length(_Keys);
  OutFloat := PVkFloat(Output);
  InFloat0 := PVkFloat(_Keys[k0].Value);
  InFloat1 := PVkFloat(_Keys[k1].Value);
  if k0 = k1 then
  for i := 0 to _SampleCount - 1 do
  begin
    OutFloat^ := InFloat0^;
    Inc(OutFloat); Inc(InFloat0);
    Exit;
  end;
  t := Time mod _Keys[High(_Keys)].Time;
  if k1 < k0 then
  begin
    t := t / _Keys[0].Time;
  end
  else
  begin
    t := (t - _Keys[k0].Time) / (_Keys[k1].Time - _Keys[k0].Time);
  end;
  case _Keys[k0].Interpolation of
    ai_step:
    begin
      for i := 0 to _SampleCount - 1 do
      begin
        OutFloat^ := InFloat0^;
        Inc(OutFloat); Inc(InFloat0);
      end;
    end;
    else
    begin
      for i := 0 to _SampleCount - 1 do
      begin
        OutFloat^ := LabLerpFloat(InFloat0^, InFloat1^, t);
        Inc(OutFloat); Inc(InFloat0); Inc(InFloat1);
      end;
    end;
  end;
end;

procedure TLabSceneAnimationTrack.Sample(const Time: TVkFloat; const Loop: Boolean);
  var Scaling, Rotation, Translation: TLabVec3;
begin
  if not Assigned(_Target) then Exit;
  SampleData(_Sample, Time, Loop);
  if _SampleType in TSampleSingleFloat then
  begin
    LabMatDecompose(@Scaling, nil, @Translation, _Target.Transform);
    Rotation := LabMatToEuler(_Target.Transform);
    case _SampleType of
      st_rotation_x: Rotation.x := LabDegToRad * PLabFloat(_Sample)^;
      st_rotation_y: Rotation.y := LabDegToRad * PLabFloat(_Sample)^;
      st_rotation_z: Rotation.z := LabDegToRad * PLabFloat(_Sample)^;
      st_scale_x: Scaling.x := PLabFloat(_Sample)^;
      st_scale_y: Scaling.y := PLabFloat(_Sample)^;
      st_scale_z: Scaling.z := PLabFloat(_Sample)^;
      st_position_x: Translation.x := PLabFloat(_Sample)^;
      st_position_y: Translation.y := PLabFloat(_Sample)^;
      st_position_z: Translation.z := PLabFloat(_Sample)^;
    end;
    _Target.Transform := LabMatScaling(Scaling) * LabEulerToMat(Rotation) * LabMatTranslation(Translation);
    Rotation := LabMatToEuler(_Target.Transform);
  end
  else if _SampleType = st_transform then
  begin
    _Target.Transform := PLabMat(_Sample)^;
  end;
end;

constructor TLabSceneAnimationTrack.Create(
  const AScene: TLabScene;
  const ColladaChannel: TLabColladaAnimationChannel
);
  const rotation_types: array [0..2] of TSampleType = (st_rotation_x, st_rotation_y, st_rotation_z);
  const scale_types: array [0..2] of TSampleType = (st_scale_x, st_scale_y, st_scale_z);
  const position_types: array [0..2] of TSampleType = (st_position_x, st_position_y, st_position_z);
  var prop_name: AnsiString;
  var i: TVkInt32;
begin
  if (ColladaChannel.Sampler.DataType <> at_float) then Exit;
  if Assigned(ColladaChannel.Target.UserData)
  and (ColladaChannel.Target.UserData is TLabSceneNode) then
  begin
    _Target := TLabSceneNode(ColladaChannel.Target.UserData);
  end;
  prop_name := LowerCase(ColladaChannel.TargetProperty);
  if prop_name = 'rotationx.angle' then _SampleType := rotation_types[AScene.AxisRemap.Offset[0]]
  else if prop_name = 'rotationy.angle' then _SampleType := rotation_types[AScene.AxisRemap.Offset[1]]
  else if prop_name = 'rotationz.angle' then _SampleType := rotation_types[AScene.AxisRemap.Offset[2]]
  else if prop_name = 'scale.x' then _SampleType := scale_types[AScene.AxisRemap.Offset[0]]
  else if prop_name = 'scale.y' then _SampleType := scale_types[AScene.AxisRemap.Offset[1]]
  else if prop_name = 'scale.z' then _SampleType := scale_types[AScene.AxisRemap.Offset[2]]
  else if (prop_name = 'trans.x') or (prop_name = 'location.x') then _SampleType := position_types[AScene.AxisRemap.Offset[0]]
  else if (prop_name = 'trans.y') or (prop_name = 'location.y') then _SampleType := position_types[AScene.AxisRemap.Offset[1]]
  else if (prop_name = 'trans.z') or (prop_name = 'location.z') then _SampleType := position_types[AScene.AxisRemap.Offset[2]]
  else if prop_name = 'transform' then _SampleType := st_transform;
  _SampleCount := 1;
  _SampleSize := ColladaChannel.Sampler.SampleSize;
  _MaxTime := ColladaChannel.MaxTime;
  SetLength(_Keys, ColladaChannel.Sampler.KeyCount);
  _Data := GetMemory(_SampleSize * (ColladaChannel.Sampler.KeyCount + 1));
  _Sample := _Data + _SampleSize * ColladaChannel.Sampler.KeyCount;
  for i := 0 to High(_Keys) do
  begin
    _Keys[i].Time := ColladaChannel.Sampler.Keys[i]^.Time;
    _Keys[i].Value := _Data + (_SampleSize * i);
    _Keys[i].Interpolation := ColladaChannel.Sampler.Keys[i]^.Interpolation;
    Move(ColladaChannel.Sampler.Keys[i]^.Value^, _Keys[i].Value^, _SampleSize);
    if _SampleType = st_transform then
    begin
      PLabMat(_Keys[i].Value)^ := PLabMat(_Keys[i].Value)^.Swizzle(AScene.AxisRemap);
    end;
  end;
end;

destructor TLabSceneAnimationTrack.Destroy;
begin
  if Assigned(_Data) then FreeMemory(_Data);
  inherited Destroy;
end;

function TLabSceneAnimation.GetMaxTime: TVkFloat;
  var i: TVkInt32;
begin
  Result := 0;
  for i := 0 to _Animations.Count - 1 do
  if _Animations[i].MaxTime > Result then
  begin
    Result := _Animations[i].MaxTime;
  end;
  for i := 0 to _Tracks.Count - 1 do
  if _Tracks[i].MaxTime > Result then
  begin
    Result := _Tracks[i].MaxTime;
  end;
end;

procedure TLabSceneAnimation.Sample(const Time: TVkFloat; const Loop: Boolean);
  var i: TVkInt32;
begin
  for i := 0 to _Animations.Count - 1 do
  begin
    _Animations[i].Sample(Time, Loop);
  end;
  for i := 0 to _Tracks.Count - 1 do
  begin
    _Tracks[i].Sample(Time, Loop);
  end;
end;

constructor TLabSceneAnimation.Create(
  const AScene: TLabScene;
  const ColladaAnimation: TLabColladaAnimation
);
  var i: TVkInt32;
begin
  _Scene := AScene;
  _Animations := TList.Create;
  _Tracks := TLabSceneAnimationTrackList.Create;
  for i := 0 to ColladaAnimation.Channels.Count - 1 do
  begin
    _Tracks.Add(TLabSceneAnimationTrack.Create(AScene, ColladaAnimation.Channels[i]));
  end;
  for i := 0 to ColladaAnimation.Animations.Count - 1 do
  begin
    _Animations.Add(TLabSceneAnimation.Create(AScene, ColladaAnimation.Animations[i]));
  end;
end;

destructor TLabSceneAnimation.Destroy;
begin
  while _Tracks.Count > 0 do _Tracks.Pop.Free;
  _Tracks.Free;
  while _Animations.Count > 0 do _Animations.Pop.Free;
  _Animations.Free;
  inherited Destroy;
end;

procedure TLabSceneAnimationClip.Sample(const Time: TVkFloat; const Loop: Boolean);
  var i: TVkInt32;
begin
  for i := 0 to _Animations.Count - 1 do
  begin
    _Animations[i].Sample(Time, Loop);
  end;
end;

procedure TLabSceneAnimationClip.UpdateMaxTime;
  var i: TVkInt32;
begin
  _MaxTime := 0;
  for i := 0 to _Animations.Count - 1 do
  if _Animations[i].MaxTime > _MaxTime then
  begin
    _MaxTime := _Animations[i].MaxTime;
  end;
end;

constructor TLabSceneAnimationClip.Create(const AScene: TLabScene; const AName: AnsiString);
begin
  _Scene := AScene;
  _Name := AName;
  _Animations := TLabSceneAnimationList.Create;
  _MaxTime := 0;
end;

destructor TLabSceneAnimationClip.Destroy;
begin
  _Animations.Free;
  inherited Destroy;
end;

procedure TLabSceneNode.SetParent(const Value: TLabSceneNode);
begin
  if _Parent = Value then Exit;
  if Assigned(_Parent) then _Parent.Children.Remove(Self);
  _Parent := Value;
  if Assigned(_Parent) then _Parent.Children.Add(Self);
end;

constructor TLabSceneNode.Create(
  const AScene: TLabScene;
  const AParent: TLabSceneNode;
  const ANode: TLabColladaNode
);
  var i: TVkInt32;
  var Root: TLabColladaRoot;
begin
  _Scene := AScene;
  _Children := TNodeList.Create;
  _Attachments := TLabSceneNodeAttachmentList.Create;
  Parent := AParent;
  if Assigned(ANode) then
  begin
    ANode.UserData := Self;
    if Length(ANode.Name) > 0 then
    begin
      _Name := AnsiString(ANode.Name);
    end
    else
    begin
      _Name := AnsiString(ANode.id);
    end;
    _Transform := ANode.Matrix;
    for i := 0 to ANode.Children.Count - 1 do
    begin
      if ANode.Children[i] is TLabColladaNode then
      begin
        TLabSceneNode.Create(_Scene, Self, TLabColladaNode(ANode.Children[i]));
      end
      else if ANode.Children[i] is TLabColladaInstanceGeometry then
      begin
        _Attachments.Add(TLabSceneNodeAttachmentGeometry.Create(_Scene, Self, TLabColladaInstanceGeometry(ANode.Children[i])));
      end
      else if ANode.Children[i] is TLabColladaInstanceController then
      begin
        _Attachments.Add(TLabSceneNodeAttachmentController.Create(_Scene, Self, TLabColladaInstanceController(ANode.Children[i])));
      end;
    end;
    _Transform := _Transform.Swizzle(_Scene.AxisRemap);
  end
  else
  begin
    _Transform := LabMatIdentity;
  end;
  if Assigned(_Parent) then _Transform := _Parent.Transform * _Transform;
end;

destructor TLabSceneNode.Destroy;
begin
  FreeAndNil(_UserData);
  while _Attachments.Count > 0 do _Attachments.Pop.Free;
  _Attachments.Free;
  while _Children.Count > 0 do _Children.Pop.Free;
  _Children.Free;
  inherited Destroy;
end;

procedure TLabScene.Add(const FileName: String);
  var Collada: TLabColladaParser;
  var i: TVkInt32;
begin
  _Path := ExpandFileName(ExtractFileDir(FileName) + PathDelim);
  Collada := TLabColladaParser.Create(FileName);
  Collada.RootNode.Dump;
  if not Assigned(Collada.RootNode)
  or not Assigned(Collada.RootNode.Scene) then
  begin
    Collada.Free;
    Exit;
  end;
  if Assigned(Collada.RootNode.Asset) then
  begin
    _AxisRemap := Collada.RootNode.Asset.UpAxis;
  end;
  if Assigned(Collada.RootNode.LibImages) then
  for i := 0 to Collada.RootNode.LibImages.Images.Count - 1 do
  begin
    _Images.Add(TLabSceneImage.Create(Self, Collada.RootNode.LibImages.Images[i]));
  end;
  if Assigned(Collada.RootNode.LibEffects) then
  for i := 0 to Collada.RootNode.LibEffects.Effects.Count - 1 do
  begin
    _Effects.Add(TLabSceneEffect.Create(Self, Collada.RootNode.LibEffects.Effects[i]));
  end;
  if Assigned(Collada.RootNode.LibMaterials) then
  for i := 0 to Collada.RootNode.LibMaterials.Materials.Count - 1 do
  begin
    _Materials.Add(TLabSceneMaterial.Create(Self, Collada.RootNode.LibMaterials.Materials[i]));
  end;
  if Assigned(Collada.RootNode.LibGeometries) then
  for i := 0 to Collada.RootNode.LibGeometries.Geometries.Count - 1 do
  begin
    _Geometries.Add(TLabSceneGeometry.Create(Self, Collada.RootNode.LibGeometries.Geometries[i]));
  end;
  if Assigned(Collada.RootNode.LibControllers) then
  for i := 0 to Collada.RootNode.LibControllers.Controllers.Count - 1 do
  begin
    if Collada.RootNode.LibControllers.Controllers[i].ControllerType = ct_skin then
    begin
      _Controllers.Add(TLabSceneControllerSkin.Create(Self, Collada.RootNode.LibControllers.Controllers[i].AsSkin));
    end;
  end;
  for i := 0 to Collada.RootNode.Scene.VisualScene.VisualScene.Nodes.Count - 1 do
  begin
    TLabSceneNode.Create(Self, _Root, Collada.RootNode.Scene.VisualScene.VisualScene.Nodes[i]);
  end;
  if Assigned(Collada.RootNode.LibAnimations) then
  for i := 0 to Collada.RootNode.LibAnimations.Animations.Count - 1 do
  begin
    _Animations.Add(TLabSceneAnimation.Create(Self, Collada.RootNode.LibAnimations.Animations[i]));
  end;
  _DefaultAnimationClip.Animations.Clear;
  for i := 0 to _Animations.Count - 1 do
  begin
    _DefaultAnimationClip.Animations.Add(_Animations[i]);
  end;
  _DefaultAnimationClip.UpdateMaxTime;
  Collada.Free;
  _Path := '';
end;

function TLabScene.FindAnimationClip(const Name: AnsiString): TLabSceneAnimationClip;
  var i: TVkInt32;
begin
  for i := 0 to _AnimationClips.Count - 1 do
  if _AnimationClips[i].Name = Name then
  begin
    Exit(_AnimationClips[i]);
  end;
  Exit(nil);
end;

function TLabScene.FindNode(const Name: AnsiString): TLabSceneNode;
  function SearchInParent(const Parent: TLabSceneNode): TLabSceneNode;
    var i: TVkInt32;
  begin
    for i := 0 to Parent.Children.Count - 1 do
    if Parent.Children[i].Name = Name then
    begin
      Exit(Parent.Children[i]);
    end;
    for i := 0 to Parent.Children.Count - 1 do
    begin
      Result := SearchInParent(Parent.Children[i]);
      if Assigned(Result) then Exit;
    end;
    Result := nil;
  end;
begin
  Result := SearchInParent(_Root);
end;

function TLabScene.ResolvePath(const Path: String): String;
  var FullPath: String;
begin
  FullPath := ExpandFileName(_Path + Path);
  if FileExists(FullPath) then Exit(FullPath);
  if FileExists(Path) then Exit(Path);
  Result := ExtractFileName(Path);
end;

constructor TLabScene.Create(const ADevice: TLabDeviceShared);
begin
  _Device := ADevice;
  _Root := TLabSceneNode.Create(Self, nil, nil);
  _Images := TLabSceneImageList.Create;
  _Geometries := TLabSceneGeometryList.Create;
  _Controllers := TLabSceneControllerList.Create;
  _Effects := TLabSceneEffectList.Create;
  _Materials := TLabSceneMaterialList.Create;
  _Animations := TLabSceneAnimationList.Create;
  _AnimationClips := TLabSceneAnimationClipList.Create;
  _DefaultAnimationClip := TLabSceneAnimationClip.Create(Self, 'Default');
  _AnimationClips.Add(_DefaultAnimationClip);
end;

destructor TLabScene.Destroy;
begin
  while _AnimationClips.Count > 0 do _AnimationClips.Pop.Free;
  _AnimationClips.Free;
  while _Animations.Count > 0 do _Animations.Pop.Free;
  _Animations.Free;
  while _Materials.Count > 0 do _Materials.Pop.Free;
  _Materials.Free;
  while _Effects.Count > 0 do _Effects.Pop.Free;
  _Effects.Free;
  while _Controllers.Count > 0 do _Controllers.Pop.Free;
  _Controllers.Free;
  while _Geometries.Count > 0 do _Geometries.Pop.Free;
  _Geometries.Free;
  while _Images.Count > 0 do _Images.Pop.Free;
  _Images.Free;
  _Root.Free;
  inherited Destroy;
end;

end.
