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
  LabShader;

type
  TLabScene = class;

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
      const Desc: TLabColladaVertexDescriptor
    ): TLabSceneVertexShader;
    class function MakePixelShader(
      const AScene: TLabScene;
      const Desc: TLabColladaVertexDescriptor
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
  public
    property Scene: TLabScene read _Scene;
    property Subsets: TSubsetList read _Subsets;
    constructor Create(const AScene: TLabScene; const ColladaGeometry: TLabColladaGeometry);
    destructor Destroy; override;
  end;
  TLabSceneGeometryList = specialize TLabList<TLabSceneGeometry>;

  TLabSceneNode = class;
  TLabSceneNodeAttachment = class (TLabClass)
  private
    var _Scene: TLabScene;
    var _Node: TLabSceneNode;
  public
    constructor Create(const AScene: TLabScene; const ANode: TLabSceneNode);
    destructor Destroy; override;
  end;

  TLabSceneNodeAttachmentGeometry = class (TLabSceneNodeAttachment)
  private
    var _Geometry: TLabSceneGeometry;
  public
    property Geometry: TLabSceneGeometry read _Geometry;
    constructor Create(const AScene: TLabScene; const ANode: TLabSceneNode; const ColladaInstanceGeometry: TLabColladaInstanceGeometry);
    destructor Destroy; override;
  end;
  TLabSceneNodeAttachmentGeometryList = specialize TLabList<TLabSceneNodeAttachmentGeometry>;

  TLabSceneNode = class (TLabClass)
  public
    type TNodeList = specialize TLabList<TLabSceneNode>;
  private
    var _Scene: TLabScene;
    var _Parent: TLabSceneNode;
    var _Children: TNodeList;
    var _Transform: TLabMat;
    var _Attachments: TLabSceneNodeAttachmentGeometryList;
    procedure SetParent(const Value: TLabSceneNode);
  public
    property Scene: TLabScene read _Scene;
    property Parent: TLabSceneNode read _Parent write SetParent;
    property Children: TNodeList read _Children;
    property Transform: TLabMat read _Transform write _Transform;
    property Attachments: TLabSceneNodeAttachmentGeometryList read _Attachments;
    constructor Create(
      const AScene: TLabScene;
      const AParent: TLabSceneNode;
      const ANode: TLabColladaNode
    );
    destructor Destroy; override;
  end;

  TLabScene = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Root: TLabSceneNode;
    var _Geometries: TLabSceneGeometryList;
  public
    property Device: TLabDeviceShared read _Device;
    property Root: TLabSceneNode read _Root;
    procedure Add(const FileName: String);
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
  const Desc: TLabColladaVertexDescriptor
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
    //'layout (location = 0) in vec3 in_position;'#$D#$A +
    //'layout (location = 1) in vec3 in_normal;'#$D#$A +
    //'layout (location = 2) in vec3 in_color;'#$D#$A +
    //'layout (location = 0) out vec3 out_color;'#$D#$A +
    //'layout (location = 1) out vec3 out_normal;'#$D#$A +
    'out gl_PerVertex {'#$D#$A +
    '  vec4 gl_Position;'#$D#$A +
    '};'#$D#$A +
    'void main() {'#$D#$A +
    '<$code$>' +
    //'  out_normal = in_normal;'#$D#$A +
    //'  out_color = in_color;'#$D#$A +
    //'  gl_Position = xf.wvp * vec4(in_position, 1);'#$D#$A +
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
    Sem := GetSemanticName(Desc[i].Semantic);
    StrAttrIn += 'layout (location = ' + IntToStr(loc_in) + ') in vec' + IntToStr(Desc[i].DataCount) + ' in_' + Sem + ';'#$D#$A;
    Inc(loc_in);
    if (Desc[i].Semantic = as_position) then
    begin
      case Desc[i].DataCount of
        0: StrCode += '  gl_Position = vec4(0, 0, 0, 1);'#$D#$A;
        1: StrCode += '  gl_Position = xf.wvp * vec4(in_position, 0, 0, 1);'#$D#$A;
        2: StrCode += '  gl_Position = xf.wvp * vec4(in_position, 0, 1);'#$D#$A;
        3: StrCode += '  gl_Position = xf.wvp * vec4(in_position, 1);'#$D#$A;
        4: StrCode += '  gl_Position = xf.wvp * in_position;'#$D#$A;
      end;
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
  const Desc: TLabColladaVertexDescriptor
): TLabScenePixelShader;
  var ShaderCode: String = '#version 400'#$D#$A +
    '#extension GL_ARB_separate_shader_objects : enable'#$D#$A +
    '#extension GL_ARB_shading_language_420pack : enable'#$D#$A +
    '<$attribs$>' +
    //'layout (location = 0) in vec3 in_color;'#$D#$A +
    //'layout (location = 1) in vec3 in_normal;'#$D#$A +
    //'layout (location = 0) out vec4 outColor;'#$D#$A +
    'void main() {'#$D#$A +
    '<$code$>' +
    //'  vec3 normal = normalize(in_normal);'#$D#$A +
    //'  float c = (dot(normal, normalize(vec3(1, -1, 1))) * 0.5 + 0.5) * 0.8 + 0.2;'#$D#$A +
    //'  outColor = vec4(in_color * c, 1);'#$D#$A +
    '}'
  ;
  var StrAttr: String;
  var StrCode: String;
  var Code: String;
  var Sem: String;
  var i, loc: TVkInt32;
begin
  StrAttr := '';
  loc := 0;
  StrCode := 'vec4 color = vec4(1, 1, 1, 1);'#$D#$A;
  for i := 0 to High(Desc) do
  begin
    if Desc[i].Semantic = as_position then Continue;
    Sem := GetSemanticName(Desc[i].Semantic);
    StrAttr += 'layout (location = ' + IntToStr(loc) + ') in vec' + IntToStr(Desc[i].DataCount) + ' in_' + Sem + ';'#$D#$A;
    Inc(loc);
    case Desc[i].Semantic of
      as_normal:
      begin
        case Desc[i].DataCount of
          1: StrCode += '  vec3 normal = normalize(vec3(in_normal, 0, 0));'#$D#$A;
          2: StrCode += '  vec3 normal = normalize(vec3(in_normal, 0));'#$D#$A;
          4: StrCode += '  vec3 normal = normalize(in_normal.xyz);'#$D#$A;
          else StrCode += '  vec3 normal = normalize(in_normal);'#$D#$A;
        end;
        StrCode += '  color.xyz *= (dot(normal, normalize(vec3(1, -1, 1))) * 0.5 + 0.5) * 0.8 + 0.2;'#$D#$A;
      end;
      as_color:
      begin
        case Desc[i].DataCount of
          1: StrCode += '  color.x *= in_color;'#$D#$A;
          2: StrCode += '  color.xy *= in_color;'#$D#$A;
          3: StrCode += '  color.xyz *= in_color;'#$D#$A;
          4: StrCode += '  color *= in_color;'#$D#$A;
        end;
      end;
    end;
  end;
  StrAttr += 'layout (location = 0) out vec4 out_color;'#$D#$A;
  StrCode += '  out_color = color;'#$D#$A;
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

constructor TLabSceneNodeAttachmentGeometry.Create(
  const AScene: TLabScene;
  const ANode: TLabSceneNode;
  const ColladaInstanceGeometry: TLabColladaInstanceGeometry
);
begin
  inherited Create(AScene, ANode);
  if Assigned(ColladaInstanceGeometry.Geometry)
  and Assigned(ColladaInstanceGeometry.Geometry.UserData)
  and (ColladaInstanceGeometry.Geometry.UserData is TLabSceneGeometry) then
  begin
    _Geometry := TLabSceneGeometry(ColladaInstanceGeometry.Geometry.UserData);
  end;
end;

destructor TLabSceneNodeAttachmentGeometry.Destroy;
begin
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
  var Source: TLabColladaSource;
  var i, j, Offset, ind: TVkInt32;
  var crc: TVkUInt32;
begin
  _Geometry := AGeometry;
  VertexCount := 0;
  IndexCount := 0;
  Triangles.UserData := Self;
  VertexStride := Triangles.VertexSize;
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
  SetLength(AttribIndices, Triangles.Inputs.Count);
  for i := 0 to Triangles.Count * 3 - 1 do
  begin
    crc := 0;
    for j := 0 to Triangles.Inputs.Count - 1 do
    begin
      Offset := Triangles.Inputs[j].Offset;
      AttribIndices[j] := Triangles.Indices^[i * Triangles.Inputs.Count + Offset];
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
begin
  _Scene := AScene;
  _Children := TNodeList.Create;
  _Attachments := TLabSceneNodeAttachmentGeometryList.Create;
  Parent := AParent;
  if Assigned(ANode) then
  begin
    ANode.UserData := Self;
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
      end;
    end;
  end
  else
  begin
    _Transform := LabMatIdentity;
  end;
end;

destructor TLabSceneNode.Destroy;
begin
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
  Collada := TLabColladaParser.Create(FileName);
  if not Assigned(Collada.RootNode)
  or not Assigned(Collada.RootNode.Scene) then
  begin
    Collada.Free;
    Exit;
  end;
  for i := 0 to Collada.RootNode.LibGeometries.Geometries.Count - 1 do
  begin
    _Geometries.Add(TLabSceneGeometry.Create(Self, Collada.RootNode.LibGeometries.Geometries[i]));
  end;
  for i := 0 to Collada.RootNode.Scene.VisualScene.VisualScene.Nodes.Count - 1 do
  begin
    TLabSceneNode.Create(Self, _Root, Collada.RootNode.Scene.VisualScene.VisualScene.Nodes[i]);
  end;
  Collada.Free;
end;

constructor TLabScene.Create(const ADevice: TLabDeviceShared);
begin
  _Device := ADevice;
  _Root := TLabSceneNode.Create(Self, nil, nil);
  _Geometries := TLabSceneGeometryList.Create;
end;

destructor TLabScene.Destroy;
begin
  while _Geometries.Count > 0 do _Geometries.Pop.Free;
  _Geometries.Free;
  _Root.Free;
  inherited Destroy;
end;

end.
