unit LabShader;
{$macro on}

interface

uses
  Vulkan,
  Classes,
  LabTypes,
  LabUtils,
  LabDevice,
  SysUtils,
  Process;

type
  TLabShader = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkShaderModule;
    var _StageCreateInfo: TVkPipelineShaderStageCreateInfo;
    var _Hash: TVkUInt32;
    function GetStageCreateInfo: PVkPipelineShaderStageCreateInfo; inline;
  public
    class function Stage: TVkShaderStageFlagBits; virtual; abstract;
    property VkHandle: TVkShaderModule read _Handle;
    property StageCreateInfo: PVkPipelineShaderStageCreateInfo read GetStageCreateInfo;
    property Hash: TVkUInt32 read _Hash;
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32); virtual;
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString); virtual;
    destructor Destroy; override;
  end;
  TLabShaderShared = specialize TLabSharedRef<TLabShader>;

  TLabVertexShader = class (TLabShader)
  public
    class function Stage: TVkShaderStageFlagBits; override;
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32); override;
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString); override;
  end;
  TLabVertexShaderShared = specialize TLabSharedRef<TLabVertexShader>;

  TLabPixelShader = class (TLabShader)
  public
    class function Stage: TVkShaderStageFlagBits; override;
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32); override;
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString); override;
  end;
  TLabPixelShaderShared = specialize TLabSharedRef<TLabPixelShader>;

  TLabComputeShader = class (TLabShader)
  public
    class function Stage: TVkShaderStageFlagBits; override;
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32); override;
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString); override;
  end;
  TLabComputeShaderShared = specialize TLabSharedRef<TLabComputeShader>;

  TLabGeomShader = class (TLabShader)
  public
    class function Stage: TVkShaderStageFlagBits; override;
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32); override;
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString); override;
  end;
  TLabGeometryShaderShared = specialize TLabSharedRef<TLabGeomShader>;

  TLabTessCtrlShader = class (TLabShader)
  public
    class function Stage: TVkShaderStageFlagBits; override;
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32); override;
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString); override;
  end;
  TLabTessControlShaderShared = specialize TLabSharedRef<TLabTessCtrlShader>;

  TLabTessEvalShader = class (TLabShader)
  public
    class function Stage: TVkShaderStageFlagBits; override;
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32); override;
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString); override;
  end;
  TLabTessEvaluationShaderShared = specialize TLabSharedRef<TLabTessEvalShader>;

  generic TLabCachedShader<T> = class (TLabShader)
  private
    type TShader = T;
    type TSelf = specialize TLabCachedShader<TShader>;
    type TShaderList = specialize TLabList<TSelf>;
    class var List: TShaderList;
    class var ListSort: Boolean;
    var CodeHash: TVkUInt32;
    class function MakeHash(const ShaderCode: String): TVkUInt32;
    class function CmpShaders(const a, b: TSelf): Boolean;
    class procedure SortList;
    class function Find(const AHash: TVkUInt32): TSelf;
    class function FindCache(const AHash: TVkUInt32): TLabByteArr;
    class function CompileShader(const ShaderCode: String; const ShaderHash: TVkUInt32 = 0): TLabByteArr;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    class function Stage: TVkShaderStageFlagBits; override;
    class function FindOrCreate(const ADevice: TLabDeviceShared; const ShaderCode: String): TSelf;
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32); override;
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString); override;
    destructor Destroy; override;
  end;

  TLabVertexShaderCached = specialize TLabCachedShader<TLabVertexShader>;
  TLabVertexShaderCachedShared = specialize TLabSharedRef<TLabVertexShaderCached>;
  TLabTessCtrlShaderCached = specialize TLabCachedShader<TLabTessCtrlShader>;
  TLabTessCtrlShaderCachedShared = specialize TLabSharedRef<TLabTessCtrlShaderCached>;
  TLabTessEvalCachedShader = specialize TLabCachedShader<TLabTessEvalShader>;
  TLabTessEvalShaderCachedShared = specialize TLabSharedRef<TLabTessEvalCachedShader>;
  TLabGeomShaderCached = specialize TLabCachedShader<TLabGeomShader>;
  TLabGeomShaderCachedShared = specialize TLabSharedRef<TLabGeomShaderCached>;
  TLabPixelShaderCached = specialize TLabCachedShader<TLabPixelShader>;
  TLabPixelShaderCachedShared = specialize TLabSharedRef<TLabPixelShaderCached>;
  TLabComputeShaderCached = specialize TLabCachedShader<TLabComputeShader>;
  TLabComputeShaderCachedShared = specialize TLabSharedRef<TLabComputeShaderCached>;

  TLabShaderGroup = class (TLabClass)
    Vertex: TLabVertexShaderCachedShared;
    TessCtrl: TLabTessCtrlShaderCachedShared;
    TessEval: TLabTessEvalShaderCachedShared;
    Geometry: TLabGeomShaderCachedShared;
    Pixel: TLabPixelShaderCachedShared;
  end;
  TLabShaderGroupShared = specialize TLabSharedRef<TLabShaderGroup>;

  TLabShaderBuildInfo = object
    VertexDescriptors: array of TLabVertexAttribute;
    MaxJointWeights: TVkInt32;
    JointCount: TVkInt32;
  end;

  TLabCombinedShader = class (TLabClass)
  public
    type TDataItem = object
      ItemName: String;
      ItemType: String;
      ArrayCount: TVkInt32;
      function IsArray: Boolean; inline;
      function IsOpenArray: Boolean; inline;
    end;
    type TDataBlock = array of TDataItem;
    type PDataBlock = ^TDataBlock;
    type TStage = class
    public
      var Entry: AnsiString;
      var Code: AnsiString;
      var Inputs: TDataBlock;
      var Outputs: TDataBlock;
      var NextStage: TStage;
      var ShaderCode: String;
      constructor Create;
    end;
    type TStageVertex = class (TStage)
    public
    end;
    type TStageTessCtrl = class (TStage)
    public
    end;
    type TStageTessEval = class (TStage)
    public
    end;
    type TStageGeometry = class (TStage)
    public
    end;
    type TStagePixel = class (TStage)
    public
    end;
    type TUniform = class
    public
      var Name: String;
      var Stages: TVkShaderStageFlags;
      var Data: TDataBlock;
      procedure AddItem(const ItemName: String; const ItemType: String; const ArrayCount: Integer = -1);
      constructor Create;
    end;
    type TUniformList = specialize TLabObjList<TUniform>;
  private
    var _Device: TLabDeviceShared;
    var _Name: String;
    var _StageVertex: TStageVertex;
    var _StageTessCtrl: TStageTessCtrl;
    var _StageTessEval: TStageTessEval;
    var _StageGeometry: TStageGeometry;
    var _StagePixel: TStagePixel;
    var _Uniforms: TUniformList;
  public
    property Device: TLabDeviceShared read _Device;
    property Name: String read _Name;
    function Build(const BuildInfo: TLabShaderBuildInfo): TLabShaderGroupShared;
    class function CreateFromFile(const ADevice: TLabDeviceShared; const FileName: String): TLabCombinedShader;
    constructor Create(const ADevice: TLabDeviceShared; const ShaderCode: String);
    destructor Destroy; override;
  end;
  TLabCombinedShaderShared = specialize TLabSharedRef<TLabCombinedShader>;

  TLabShaderStage = record
    shader: TLabShaderShared;
    info: TVkPipelineShaderStageCreateInfo;
    spec: TVkSpecializationInfo;
    entries: array of TVkSpecializationMapEntry;
  end;

  TLabShaderStages = array of TLabShaderStage;

function LabSpecializationMapEntry(const ConstantID: TVkUInt32; const Offset: TVkUInt32; const Size: TVkSize): TVkSpecializationMapEntry; inline;
function LabShaderStage(const Shader: TLabShader): TLabShaderStage; inline;
function LabShaderStage(
  const Shader: TLabShader;
  const SpecData: PVkVoid;
  const SpecDataSize: TVkSize;
  const SpecEntries: array of TVkSpecializationMapEntry
): TLabShaderStage;
function LabShaderStages(const Shaders: array of TLabShader): TLabShaderStages;
function LabShaderStages(const Shaders: array of TLabShaderShared): TLabShaderStages;

implementation

function TLabCombinedShader.TDataItem.IsArray: Boolean;
begin
  Result := ArrayCount > -1;
end;

function TLabCombinedShader.TDataItem.IsOpenArray: Boolean;
begin
  Result := ArrayCount = 0;
end;

class function TLabCachedShader.MakeHash(const ShaderCode: String): TVkUInt32;
begin
  Result := LabCRC32(0, @ShaderCode[1], Length(ShaderCode));
end;

class function TLabCachedShader.CmpShaders(const a, b: TSelf): Boolean;
begin
  Result := a.CodeHash > b.CodeHash;
end;

class procedure TLabCachedShader.SortList;
begin
  if (not ListSort) then Exit;
  List.Sort(@CmpShaders);
  ListSort := False;
end;

class function TLabCachedShader.Find(const AHash: TVkUInt32): TSelf;
  var l, h, m: Integer;
begin
  SortList;
  l := 0;
  h := List.Count - 1;
  while l <= h do
  begin
    m := (l + h) shr 1;
    if List[m].Hash > AHash then
    h := m - 1
    else if List[m].Hash < AHash then
    l := m + 1
    else Exit(List[m]);
  end;
  if (l < List.Count)
  and (List[l].Hash = AHash)
  then Exit(List[l]) else Exit(nil);
end;

class function TLabCachedShader.FindCache(const AHash: TVkUInt32): TLabByteArr;
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

class function TLabCachedShader.CompileShader(const ShaderCode: String; const ShaderHash: TVkUInt32): TLabByteArr;
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
    case Stage of
      VK_SHADER_STAGE_VERTEX_BIT: st := 'vert';
      VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT: st := 'tesc';
      VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT: st := 'tese';
      VK_SHADER_STAGE_GEOMETRY_BIT: st := 'geom';
      VK_SHADER_STAGE_FRAGMENT_BIT: st := 'frag';
      else st := 'comp';
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

class constructor TLabCachedShader.CreateClass;
begin
  List := TShaderList.Create;
  ListSort := False;
end;

class destructor TLabCachedShader.DestroyClass;
begin
  List.Free;
end;

class function TLabCachedShader.Stage: TVkShaderStageFlagBits;
begin
  Result := TShader.Stage;
end;

class function TLabCachedShader.FindOrCreate(const ADevice: TLabDeviceShared; const ShaderCode: String): TSelf;
  var shader_hash: TVkUInt32;
  var shader_data: TLabByteArr;
begin
  shader_hash := MakeHash(ShaderCode);
  Result := Find(shader_hash);
  if Assigned(Result) then Exit;
  shader_data := FindCache(shader_hash);
  if Length(shader_data) = 0 then
  begin
    shader_data := CompileShader(ShaderCode, shader_hash);
  end;
  if Length(shader_data) = 0 then Exit(nil);
  Result := TSelf.Create(ADevice, @shader_data[0], Length(shader_data));
  Result.CodeHash := shader_hash;
end;

constructor TLabCachedShader.Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32);
begin
  inherited Create(ADevice, Data, Size);
  _StageCreateInfo.stage := Stage;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
  CodeHash := 0;
end;

constructor TLabCachedShader.Create(const ADevice: TLabDeviceShared; const FileName: AnsiString);
begin
  inherited Create(ADevice, FileName);
  _StageCreateInfo.stage := Stage;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
  CodeHash := 0;
end;

destructor TLabCachedShader.Destroy;
begin
  List.Remove(Self);
  inherited Destroy;
end;

function TLabShader.GetStageCreateInfo: PVkPipelineShaderStageCreateInfo;
begin
  Result := @_StageCreateInfo;
end;

constructor TLabShader.Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32);
  var shader_info: TVkShaderModuleCreateInfo;
begin
  LabLog('TLabShader.Create');
  inherited Create;
  LabZeroMem(@shader_info, SizeOf(shader_info));
  shader_info.sType := VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
  shader_info.codeSize := Size;
  shader_info.pCode := PVkUInt32(Data);
  _Device := ADevice;
  LabAssertVkError(Vulkan.CreateShaderModule(_Device.Ptr.VkHandle, @shader_info, nil, @_Handle));
  _StageCreateInfo.sType := VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  _StageCreateInfo.pNext := nil;
  _StageCreateInfo.pSpecializationInfo := nil;
  _StageCreateInfo.flags := 0;
  _StageCreateInfo.stage := VK_SHADER_STAGE_ALL;
  _StageCreateInfo.pName := 'main';
  _StageCreateInfo.module := _Handle;
  _Hash := LabCRC32(0, Data, Size);
end;

constructor TLabShader.Create(const ADevice: TLabDeviceShared; const FileName: AnsiString);
  var fs: TFileStream;
  var ms: TMemoryStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead);
  try
    ms := TMemoryStream.Create;
    ms.LoadFromStream(fs);
    ms.Position := 0;
    Create(ADevice, ms.Memory, ms.Size);
    ms.Free;
  finally
    fs.Free;
  end;
end;

destructor TLabShader.Destroy;
begin
  if LabVkValidHandle(_Handle) then
  begin
    Vulkan.DestroyShaderModule(_Device.Ptr.VkHandle, _Handle, nil);
  end;
  inherited Destroy;
  LabLog('TLabShader.Destroy');
end;

class function TLabVertexShader.Stage: TVkShaderStageFlagBits;
begin
  Result := VK_SHADER_STAGE_VERTEX_BIT;
end;

constructor TLabVertexShader.Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32);
begin
  inherited Create(ADevice, Data, Size);
  _StageCreateInfo.stage := VK_SHADER_STAGE_VERTEX_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

constructor TLabVertexShader.Create(const ADevice: TLabDeviceShared; const FileName: AnsiString);
begin
  inherited Create(ADevice, FileName);
  _StageCreateInfo.stage := VK_SHADER_STAGE_VERTEX_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

class function TLabPixelShader.Stage: TVkShaderStageFlagBits;
begin
  Result := VK_SHADER_STAGE_FRAGMENT_BIT;
end;

constructor TLabPixelShader.Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32);
begin
  inherited Create(ADevice, Data, Size);
  _StageCreateInfo.stage := VK_SHADER_STAGE_FRAGMENT_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

constructor TLabPixelShader.Create(const ADevice: TLabDeviceShared; const FileName: AnsiString);
begin
  inherited Create(ADevice, FileName);
  _StageCreateInfo.stage := VK_SHADER_STAGE_FRAGMENT_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

class function TLabComputeShader.Stage: TVkShaderStageFlagBits;
begin
  Result := VK_SHADER_STAGE_COMPUTE_BIT;
end;

constructor TLabComputeShader.Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32);
begin
  inherited Create(ADevice, Data, Size);
  _StageCreateInfo.stage := VK_SHADER_STAGE_COMPUTE_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

constructor TLabComputeShader.Create(const ADevice: TLabDeviceShared;
  const FileName: AnsiString);
begin
  inherited Create(ADevice, FileName);
  _StageCreateInfo.stage := VK_SHADER_STAGE_COMPUTE_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

class function TLabGeomShader.Stage: TVkShaderStageFlagBits;
begin
  Result := VK_SHADER_STAGE_GEOMETRY_BIT;
end;

constructor TLabGeomShader.Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32);
begin
  inherited Create(ADevice, Data, Size);
  _StageCreateInfo.stage := VK_SHADER_STAGE_GEOMETRY_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

constructor TLabGeomShader.Create(const ADevice: TLabDeviceShared; const FileName: AnsiString);
begin
  inherited Create(ADevice, FileName);
  _StageCreateInfo.stage := VK_SHADER_STAGE_GEOMETRY_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

class function TLabTessCtrlShader.Stage: TVkShaderStageFlagBits;
begin
  Result := VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT;
end;

constructor TLabTessCtrlShader.Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32);
begin
  inherited Create(ADevice, Data, Size);
  _StageCreateInfo.stage := VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

constructor TLabTessCtrlShader.Create(const ADevice: TLabDeviceShared; const FileName: AnsiString);
begin
  inherited Create(ADevice, FileName);
  _StageCreateInfo.stage := VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

class function TLabTessEvalShader.Stage: TVkShaderStageFlagBits;
begin
  Result := VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT;
end;

constructor TLabTessEvalShader.Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32);
begin
  inherited Create(ADevice, Data, Size);
  _StageCreateInfo.stage := VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

constructor TLabTessEvalShader.Create(const ADevice: TLabDeviceShared; const FileName: AnsiString);
begin
  inherited Create(ADevice, FileName);
  _StageCreateInfo.stage := VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT;
  _Hash := LabCRC32(_Hash, @_StageCreateInfo.stage, SizeOf(_StageCreateInfo.stage));
end;

procedure TLabCombinedShader.TUniform.AddItem(
  const ItemName: String;
  const ItemType: String;
  const ArrayCount: Integer
);
begin
  SetLength(Data, Length(Data) + 1);
  Data[High(Data)].ItemName := ItemName;
  Data[High(Data)].ItemType := ItemType;
  Data[High(Data)].ArrayCount := ArrayCount;
end;

constructor TLabCombinedShader.TUniform.Create;
begin
  Stages := TVkFlags(VK_SHADER_STAGE_ALL);
end;

constructor TLabCombinedShader.TStage.Create;
begin
  Entry := 'main';
end;

function TLabCombinedShader.Build(const BuildInfo: TLabShaderBuildInfo): TLabShaderGroupShared;
  const AttribName: array[0..5] of record
    Semantic: TLabVertexAttributeSemantic;
    Name: String;
  end = (
    (Semantic: as_position; Name: 'position'),
    (Semantic: as_normal; Name: 'normal'),
    (Semantic: as_tangent; Name: 'tangent'),
    (Semantic: as_binormal; Name: 'binormal'),
    (Semantic: as_color; Name: 'color'),
    (Semantic: as_texcoord; Name: 'texcoord')
  );
  function GetAttribName(const Attrib: TLabVertexAttribute): String;
    var i: Integer;
  begin
    for i := 0 to High(AttribName) do
    if AttribName[i].Semantic = Attrib.Semantic then
    begin
      Exit(AttribName[i].Name);
    end;
    Result := '';
  end;
  function GetAttribType(const Attrib: TLabVertexAttribute): String;
  begin
    if Attrib.DataCount = 1 then
    begin
      case Attrib.DataType of
        dt_bool: Result := 'bool';
        dt_float: Result := 'float';
        dt_int: Result := 'int';
        else Result := '';
      end;
    end
    else
    begin
      case Attrib.DataType of
        dt_bool: Result := 'bvec' + Attrib.DataCount.ToString;
        dt_float: Result := 'vec' + Attrib.DataCount.ToString;
        dt_int: Result := 'ivec' + Attrib.DataCount.ToString;
        else Result := '';
      end;
    end;
  end;
  function FindVertexAttrib(const AttribName: String): Boolean;
    var i: Integer;
  begin
    for i := 0 to High(BuildInfo.VertexDescriptors) do
    begin
      if GetAttribName(BuildInfo.VertexDescriptors[i]) = AttribName then Exit(True);
    end;
    Result := False;
  end;
  function DataItemToStr(const DataItem: TDataItem; const Prefix: String = ''): String;
  begin
    Result := DataItem.ItemType;
    Result += ' ' + Prefix + DataItem.ItemName;
    if DataItem.IsArray then
    begin
      Result += '[';
      if not DataItem.IsOpenArray then
      begin
        Result += DataItem.ArrayCount.ToString;
      end;
      Result += ']';
    end;
  end;
  function IncVal(var Val: Integer): Integer;
  begin
    Result := Val;
    Inc(Val);
  end;
  var code: String;
  var uniform_bindings: array of Integer;
  var binding: Integer;
  procedure WriteVaryingDataBlock(const DataBlock: TDataBlock; const Prefix: String; const MapTo: PDataBlock = nil);
    function FindMapLoc(const Name: String): Integer;
      var i: Integer;
    begin
      for i := 0 to High(MapTo^) do
      if MapTo^[i].ItemName = Name then
      begin
        Exit(i);
      end;
      Result := -1;
    end;
    var loc, i, n: Integer;
    var loc_remap: array of Integer;
  begin
    if Assigned(MapTo) then
    begin
      SetLength(loc_remap, Length(DataBlock));
      n := 0;
      for i := 0 to High(loc_remap) do
      begin
        loc_remap[i] := FindMapLoc(DataBlock[i].ItemName);
        if loc_remap[i] = -1 then
        begin
          loc_remap[i] := Length(loc_remap) + n;
          Inc(n);
        end;
      end;
      for i := 0 to High(DataBlock) do
      begin
        code += 'layout (location = ' + IncVal(loc_remap[i]).ToString + ') ' + Prefix + ' ' + DataItemToStr(DataBlock[i], Prefix + '_') + ';'#$D#$A;
      end;
    end
    else
    begin
      loc := 0;
      for i := 0 to High(DataBlock) do
      begin
        code += 'layout (location = ' + IncVal(loc).ToString + ') ' + Prefix + ' ' + DataItemToStr(DataBlock[i], Prefix + '_') + ';'#$D#$A;
      end;
    end;
  end;
  procedure WriteUniforms(const ShaderStage: TVkShaderStageFlagBits);
    var i, j: Integer;
  begin
    for i := 0 to _Uniforms.Count - 1 do
    if (_Uniforms[i].Stages and TVkFLags(ShaderStage)) > 0 then
    begin
      if uniform_bindings[i] = -1 then
      begin
        uniform_bindings[i] := IncVal(binding);
      end;
      code += 'layout (std140, binding = ' + uniform_bindings[i].ToString + ') uniform t_' + _Uniforms[i].Name + ' {'#$D#$A;
      for j := 0 to High(_Uniforms[i].Data) do
      begin
        code += '  ' + DataItemToStr(_Uniforms[i].Data[j]) + ';'#$D#$A;
      end;
      code += '} ' + _Uniforms[i].Name + ';'#$D#$A;
    end;
  end;
  var i, location: Integer;
begin
  Result := TLabShaderGroup.Create;
  SetLength(uniform_bindings, _Uniforms.Count);
  for i := 0 to High(uniform_bindings) do
  begin
    uniform_bindings[i] := -1;
  end;
  binding := 0;
  code := '#version 400'#$D#$A;
  code += '#extension GL_ARB_separate_shader_objects : enable'#$D#$A;
  code += '#extension GL_ARB_shading_language_420pack : enable'#$D#$A;
  code += 'layout (std140, binding = ' + IncVal(binding).ToString + ') uniform t_global {'#$D#$A;
  code += '  vec4 time;'#$D#$A;
  code += '} global;'#$D#$A;
  code += 'layout (std140, binding = ' + IncVal(binding).ToString + ') uniform t_view {'#$D#$A;
  code += '  mat4 v;'#$D#$A;
  code += '  mat4 p;'#$D#$A;
  code += '  mat4 vp;'#$D#$A;
  code += '  mat4 vp_i;'#$D#$A;
  code += '} view;'#$D#$A;
  code += 'layout (std140, binding = ' + IncVal(binding).ToString + ') uniform t_instance {'#$D#$A;
  code += '  mat4 w;'#$D#$A;
  code += '} instance;'#$D#$A;
  WriteUniforms(VK_SHADER_STAGE_VERTEX_BIT);
  location := 0;
  for i := 0 to High(BuildInfo.VertexDescriptors) do
  begin
    code += 'layout (location = ' + IncVal(location).ToString + ') in ';
    code += GetAttribType(BuildInfo.VertexDescriptors[i]) + ' in_' + GetAttribName(BuildInfo.VertexDescriptors[i]) + ';'#$D#$A;
  end;
  for i := 0 to High(_StageVertex.Inputs) do
  begin
    if not FindVertexAttrib(_StageVertex.Inputs[i].ItemName) then
    begin
      code += 'const ' + _StageVertex.Inputs[i].ItemType + ' in_' + _StageVertex.Inputs[i].ItemName + ' = ' + _StageVertex.Inputs[i].ItemType + '(0);'#$D#$A;
    end;
  end;
  WriteVaryingDataBlock(_StageVertex.Outputs, 'out');
  code += _StageVertex.Code;
  Result.Ptr.Vertex := TLabVertexShaderCached.FindOrCreate(_Device, code);
  code := '#version 400'#$D#$A;
  code += '#extension GL_ARB_separate_shader_objects : enable'#$D#$A;
  code += '#extension GL_ARB_shading_language_420pack : enable'#$D#$A;
  WriteUniforms(VK_SHADER_STAGE_FRAGMENT_BIT);
  location := 0;
  WriteVaryingDataBlock(_StagePixel.Inputs, 'in', @_StageVertex.Outputs);
  location := 0;
  WriteVaryingDataBlock(_StagePixel.Outputs, 'out');
  code += _StagePixel.Code;
  Result.Ptr.Pixel := TLabPixelShaderCached.FindOrCreate(_Device, code);
end;

class function TLabCombinedShader.CreateFromFile(const ADevice: TLabDeviceShared; const FileName: String): TLabCombinedShader;
  var sc: String;
  var fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead);
  try
    SetLength(sc, fs.Size);
    fs.Read(sc[1], fs.Size);
    Result := TLabCombinedShader.Create(ADevice, sc);
  finally
    fs.Free;
  end;
end;

constructor TLabCombinedShader.Create(const ADevice: TLabDeviceShared; const ShaderCode: String);
  type TValueType = (vt_integer, vt_float, vt_string, vt_word);
  type TValue = record
    v: String;
    t: TValueType;
  end;
  type TValues = array of TValue;
  {$define exit_success := begin SyntaxPop; Exit(True); end;}
  {$define exit_fail := begin SyntaxPop; Exit(False); end;}
  var p: TLabParser;
  var token: String;
  var tt: TLabTokenType;
  var SyntaxGlobal: TLabParserSyntax;
  var SyntaxShader: TLabParserSyntax;
  var SyntaxNumber: TLabParserSyntax;
  var SyntaxStage: TLabParserSyntax;
  var SyntaxUniform: TLabParserSyntax;
  var SyntaxDataBlock: TLabParserSyntax;
  var SyntaxCode: TLabParserSyntax;
  var SyntaxStack: array of PLabParserSyntax;
  const DefaultSymbols: array[0..7] of AnsiString = ('{', '}', ':', ';', '.', '=', '[', ']');
  procedure SyntaxPush(const Syntax: PLabParserSyntax);
  begin
    SetLength(SyntaxStack, Length(SyntaxStack) + 1);
    SyntaxStack[High(SyntaxStack)] := Syntax;
    p.Syntax := Syntax;
  end;
  procedure SyntaxPop;
  begin
    if Length(SyntaxStack) > 0 then
    begin
      SetLength(SyntaxStack, Length(SyntaxStack) - 1);
    end;
    if Length(SyntaxStack) > 0 then
    begin
      p.Syntax := SyntaxStack[High(SyntaxStack)];
    end
    else
    begin
      p.Syntax := nil;
    end;
  end;
  procedure NextToken;
  begin
    token := p.NextToken(tt);
  end;
  function VerifyToken(const TokenTypes: array of TLabTokenType; const Tokens: array of String): Boolean;
    var i: Integer;
  begin
    Result := False;
    for i := 0 to High(TokenTypes) do
    if TokenTypes[i] = tt then
    begin
      Result := True;
      Break;
    end;
    if not Result then Exit;
    for i := 0 to High(Tokens) do
    if Tokens[i] = token then Exit(True);
    Result := False;
  end;
  function VerifyNextToken(const TokenTypes: array of TLabTokenType; const Tokens: array of String): Boolean;
  begin
    NextToken;
    Result := VerifyToken(TokenTypes, Tokens);
  end;
  function ParseValues(var Values: TValues; const MinValueCount: Integer = 1): Boolean;
    function ParseValue(var v: TValue): Boolean;
      var num: AnsiString;
    begin
      if not (tt in [ttString, ttWord, ttNumber]) then Exit(False);
      case tt of
        ttNumber:
        begin
          num := token;
          p.StatePush;
          SyntaxPush(@SyntaxNumber);
          if VerifyNextToken([ttSymbol], ['.']) then
          begin
            NextToken;
            if tt = ttNumber then
            begin
              p.StateDiscard;
              v.v := num + '.' + token;
              v.t := vt_float;
            end
            else
            begin
              v.v := num;
              v.t := vt_integer;
            end;
          end
          else
          begin
            v.v := num;
            v.t := vt_integer;
          end;
          SyntaxPop;
        end;
        ttString:
        begin
          v.v := token;
          v.t := vt_string;
        end;
        ttWord:
        begin
          v.v := token;
          v.t := vt_word;
        end;
      end;
      Exit(True);
    end;
    var v: TValue;
  begin
    SetLength(Values, 0);
    if not VerifyNextToken([ttSymbol], ['=']) then Exit(False);
    NextToken;
    if VerifyToken([ttSymbol], ['[']) then
    begin
      NextToken;
      while not ((tt = ttSymbol) and (token = ']')) do
      begin
        if tt = ttEOF then Exit(False);
        if not ParseValue(v) then Exit(False);
        SetLength(Values, Length(Values) + 1);
        Values[High(Values)] := v;
        if not VerifyNextToken([ttSymbol], [',', ']']) then Exit(False);
      end;
    end
    else
    begin
      if not ParseValue(v) then Exit(False);
      SetLength(Values, 1);
      Values[0] := v;
    end;
    if not VerifyNextToken([ttSymbol], [';']) then Exit(False);
    if (MinValueCount > 0) and (Length(Values) < MinValueCount) then Exit(False);
    Exit(True);
  end;
  function ParseGlobal: Boolean;
    function ParseShader: Boolean;
      function ParseDataBlock(var DataBlock: TDataBlock): Boolean;
        var di_name, di_type: String;
        var di_arr: TVkInt32;
      begin
        SyntaxPush(@SyntaxDataBlock);
        while True do
        begin
          if VerifyNextToken([ttSymbol], ['}']) then Break;
          if tt <> ttWord then exit_fail;
          di_name := token;
          if not VerifyNextToken([ttSymbol], [':']) then exit_fail;
          NextToken;
          if tt <> ttWord then exit_fail;
          di_type := token;
          if not VerifyNextToken([ttSymbol], ['[', ';']) then exit_fail;
          di_arr := -1;
          if token = '[' then
          begin
            NextToken;
            if tt = ttNumber then
            begin
              di_arr := StrToIntDef(token, 0);
              NextToken;
            end
            else
            begin
              di_arr := 0;
            end;
            if not VerifyToken([ttSymbol], [']']) then exit_fail;
            if not VerifyNextToken([ttSymbol], [';']) then exit_fail;
          end;
          SetLength(DataBlock, Length(DataBlock) + 1);
          DataBlock[High(DataBlock)].ItemName := di_name;
          DataBlock[High(DataBlock)].ItemType := di_type;
          DataBlock[High(DataBlock)].ArrayCount := di_arr;
        end;
        SyntaxPop;
        Result := True;
      end;
      function ParseUniform: Boolean;
        var uniform: TUniform;
        var v: TValues;
        var val: TValue;
      begin
        uniform := TUniform.Create;
        _Uniforms.Add(uniform);
        SyntaxPush(@SyntaxUniform);
        while True do
        begin
          if VerifyNextToken([ttSymbol], ['}']) then Break;
          if not VerifyToken([ttKeyword], ['name', 'stages', 'data']) then exit_fail;
          if token = 'name' then
          begin
            if not ParseValues(v) then exit_fail;
            uniform.Name := v[0].v;
          end
          else if token = 'stages' then
          begin
            if not ParseValues(v, 0) then exit_fail;
            uniform.Stages := 0;
            for val in v do
            begin
              if val.v = 'vertex' then uniform.Stages := uniform.Stages or TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
              else if val.v = 'tess_ctrl' then uniform.Stages := uniform.Stages or TVkFlags(VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT)
              else if val.v = 'tess_eval' then uniform.Stages := uniform.Stages or TVkFlags(VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT)
              else if val.v = 'geometry' then uniform.Stages := uniform.Stages or TVkFlags(VK_SHADER_STAGE_GEOMETRY_BIT)
              else if val.v = 'pixel' then uniform.Stages := uniform.Stages or TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT);
            end;
          end
          else if token = 'data' then
          begin
            if not VerifyNextToken([ttSymbol], ['{']) then exit_fail;
            if not ParseDataBlock(uniform.Data) then exit_fail;
          end;
        end;
        SyntaxPop;
      end;
      function ParseStage(const Stage: TStage): Boolean;
        function ParseCode: Boolean;
          function CleanTabs(const Code: AnsiString): AnsiString;
            var pos: Integer;
            procedure NextLine;
              var i: Integer;
            begin
              for i := pos to Length(Code) do
              if Code[i] = #$A then
              begin
                pos := i + 1;
                Exit;
              end;
              pos := Length(Code) + 1;
            end;
            var min_tabs: Integer;
            var i, n: Integer;
          begin
            min_tabs := Integer.MaxValue;
            pos := 1;
            while pos <= Length(Code) do
            begin
              n := 0;
              for i := pos to Length(Code) do
              begin
                if Code[i] = #9 then Inc(n) else Break;
              end;
              if n < min_tabs then min_tabs := n;
              NextLine;
            end;
            if (min_tabs > 0) and (min_tabs < Integer.MaxValue) then
            begin
              pos := 1;
              Result := '';
              while pos <= Length(Code) do
              begin
                pos += min_tabs;
                for i := pos to Length(Code) do
                begin
                  n := i;
                  if Code[i] = #$A then
                  begin
                    Break;
                  end;
                end;
                Result += Code.Substring(pos - 1, n - (pos - 1));
                NextLine;
              end;
            end;
          end;
          var pos, scope: TVkInt32;
        begin
          SyntaxPush(@SyntaxCode);
          pos := p.Position;
          scope := 0;
          while True do
          begin
            NextToken;
            if tt = ttEOF then exit_fail;
            if VerifyToken([ttSymbol], ['{']) then Inc(scope);
            if VerifyToken([ttSymbol], ['}']) then
            begin
              if scope = 0 then
              begin
                Stage.Code := p.Text.Substring(pos, p.Position - pos - 1);
                Stage.Code := CleanTabs(Stage.Code.TrimLeft([#$D, #$A]).TrimRight([#$D, #$A, #9]));
                exit_success;
              end;
              Dec(scope);
            end;
          end;
          SyntaxPop;
        end;
        var v: TValues;
      begin
        SyntaxPush(@SyntaxStage);
        while True do
        begin
          if VerifyNextToken([ttSymbol], ['}']) then Break;
          if VerifyToken([ttSymbol], [';']) then Continue;
          if not VerifyToken([ttKeyword], ['entry', 'input', 'output', 'code']) then exit_fail;
          if token = 'entry' then
          begin
            if not ParseValues(v) then exit_fail;
            Stage.Entry := v[0].v;
          end
          else if token = 'input' then
          begin
            if not VerifyNextToken([ttSymbol], ['{']) then exit_fail;
            ParseDataBlock(Stage.Inputs);
          end
          else if token = 'output' then
          begin
            if not VerifyNextToken([ttSymbol], ['{']) then exit_fail;
            ParseDataBlock(Stage.Outputs);
          end
          else if token = 'code' then
          begin
            if not VerifyNextToken([ttSymbol], ['{']) then exit_fail;
            ParseCode;
          end;
        end;
        SyntaxPop;
        Result := True;
      end;
      var v: TValues;
      var stage: String;
    begin
      SyntaxPush(@SyntaxShader);
      while True do
      begin
        if VerifyNextToken([ttSymbol], ['}']) then Break;
        if not VerifyToken([ttKeyword], ['name', 'uniform', 'stage']) then exit_fail;
        if token = 'name' then
        begin
          if not ParseValues(v) then exit_fail;
          _Name := v[0].v;
        end
        else if token = 'uniform' then
        begin
          if not VerifyNextToken([ttSymbol], ['{']) then exit_fail;
          if not ParseUniform then exit_fail;
        end
        else if token = 'stage' then
        begin
          if not VerifyNextToken([ttSymbol], [':']) then exit_fail;
          if not VerifyNextToken([ttKeyword], ['vertex', 'tess_ctrl', 'tess_eval', 'geometry', 'pixel']) then exit_fail;
          stage := token;
          if not VerifyNextToken([ttSymbol], ['{']) then exit_fail;
          if stage = 'vertex' then
          begin
            _StageVertex := TStageVertex.Create;
            if not ParseStage(_StageVertex) then exit_fail;
          end
          else if stage = 'tess_ctrl' then
          begin
            _StageTessCtrl := TStageTessCtrl.Create;
            if not ParseStage(_StageTessCtrl) then exit_fail;
          end
          else if stage = 'tess_eval' then
          begin
            _StageTessEval := TStageTessEval.Create;
            if not ParseStage(_StageTessEval) then exit_fail;
          end
          else if stage = 'geometry' then
          begin
            _StageGeometry := TStageGeometry.Create;
            if not ParseStage(_StageGeometry) then exit_fail;
          end
          else if stage = 'pixel' then
          begin
            _StagePixel := TStagePixel.Create;
            if not ParseStage(_StagePixel) then exit_fail;
          end;
        end;
      end;
      SyntaxPop;
      Result := True;
    end;
  begin
    SyntaxPush(@SyntaxGlobal);
    if not VerifyNextToken([ttKeyword], ['shader']) then exit_fail;
    if not VerifyNextToken([ttSymbol], ['{']) then exit_fail;
    Result := ParseShader;
    SyntaxPop;
  end;
  {$undef exit_success}
  {$undef exit_fail}
  procedure LinkStages;
    function FindOutput(const Stage: TStage; const InputName: String): Integer;
      var i: Integer;
    begin
      for i := 0 to High(Stage.Outputs) do
      if Stage.Outputs[i].ItemName = InputName then
      begin
        Exit(i);
      end;
      Result := -1;
    end;
    var CurStage: TStage;
    var i, j: Integer;
  begin
    if not Assigned(_StageVertex) or not Assigned(_StagePixel) then Exit;
    CurStage := _StageVertex;
    if Assigned(_StageTessCtrl) and Assigned(_StageTessEval) then
    begin
      CurStage.NextStage := _StageTessCtrl;
      _StageTessCtrl.NextStage := _StageTessEval;
      CurStage := _StageTessEval;
    end;
    if Assigned(_StageGeometry) then
    begin
      CurStage.NextStage := _StageGeometry;
      CurStage := _StageGeometry;
    end;
    CurStage.NextStage := _StagePixel;
    CurStage := _StageVertex;
    while Assigned(CurStage) do
    begin
      if Assigned(CurStage.NextStage) then
      begin
        for i := 0 to High(CurStage.NextStage.Inputs) do
        begin
          j := FindOutput(CurStage, CurStage.NextStage.Inputs[i].ItemName);
          if j = -1 then
          begin
            j := Length(CurStage.Outputs);
            SetLength(CurStage.Outputs, Length(CurStage.Outputs) + 1);
            CurStage.Outputs[j] := CurStage.NextStage.Inputs[i];
          end;
        end;
      end;
      CurStage := CurStage.NextStage;
    end;
  end;
begin
  inherited Create;
  _Device := ADevice;
  _Uniforms := TUniformList.Create;
  p := TLabParser.Create(ShaderCode, True);
  with SyntaxGlobal do
  begin
    CaseSensitive := False;
    AddCommentLine('//');
    AddComment('/*', '*/');
    AddString('"');
    AddKeyWord('shader');
    AddSymbols(DefaultSymbols);
  end;
  with SyntaxShader do
  begin
    CaseSensitive := False;
    AddCommentLine('//');
    AddComment('/*', '*/');
    AddString('"');
    AddKeyWords([
      'name',
      'uniform',
      'stage',
      'vertex',
      'tess_ctrl',
      'tess_eval',
      'geometry',
      'pixel'
    ]);
    AddSymbols(DefaultSymbols);
  end;
  with SyntaxStage do
  begin
    CaseSensitive := False;
    AddCommentLine('//');
    AddComment('/*', '*/');
    AddString('"');
    AddKeyWords([
      'entry',
      'input',
      'output',
      'code'
    ]);
    AddSymbols(DefaultSymbols);
  end;
  with SyntaxUniform do
  begin
    CaseSensitive := False;
    AddCommentLine('//');
    AddComment('/*', '*/');
    AddString('"');
    AddKeyWords([
      'name',
      'stages',
      'data'
    ]);
    AddSymbols(DefaultSymbols);
  end;
  with SyntaxDataBlock do
  begin
    CaseSensitive := True;
    AddCommentLine('//');
    AddComment('/*', '*/');
    AddString('"');
    AddSymbols(DefaultSymbols);
  end;
  with SyntaxCode do
  begin
    CaseSensitive := True;
    AddCommentLine('//');
    AddCommentLine('#');
    AddComment('/*', '*/');
    AddSymbols(['{', '}']);
  end;
  with SyntaxNumber do
  begin
    CaseSensitive := False;
    AddSymbol('.');
  end;
  try
    if ParseGlobal then
    begin
      LinkStages;
    end;
  finally
    p.Free;
  end;
end;

destructor TLabCombinedShader.Destroy;
begin
  FreeAndNil(_StageVertex);
  FreeAndNil(_StageTessCtrl);
  FreeAndNil(_StageTessEval);
  FreeAndNil(_StageGeometry);
  FreeAndNil(_StagePixel);
  _Uniforms.Free;
  inherited Destroy;
end;

function LabSpecializationMapEntry(const ConstantID: TVkUInt32; const Offset: TVkUInt32; const Size: TVkSize): TVkSpecializationMapEntry;
begin
{$push}{$hints off}
  FillChar(Result, SizeOf(Result), 0);
{$pop}
  Result.constantID := ConstantID;
  Result.offset := Offset;
  Result.size := Size;
end;

function LabShaderStage(const Shader: TLabShader): TLabShaderStage;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.shader := Shader;
  Result.info := Shader.GetStageCreateInfo^;
end;

function LabShaderStage(
  const Shader: TLabShader;
  const SpecData: PVkVoid;
  const SpecDataSize: TVkSize;
  const SpecEntries: array of TVkSpecializationMapEntry
): TLabShaderStage;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.shader := Shader;
  Result.info := Shader.GetStageCreateInfo^;
  if Assigned(SpecData) and (Length(SpecEntries) > 0) then
  begin
    Result.info.pSpecializationInfo := @Result.spec;
    Result.spec.pData := SpecData;
    Result.spec.dataSize := SpecDataSize;
    Result.spec.mapEntryCount := Length(SpecEntries);
    SetLength(Result.entries, Length(SpecEntries));
    Move(SpecEntries[0], Result.entries[0], SizeOf(TVkSpecializationMapEntry) * Length(SpecEntries));
    Result.spec.pMapEntries := @Result.entries[0];
  end;
end;

function LabShaderStages(const Shaders: array of TLabShader): TLabShaderStages;
  var i: Integer;
begin
  SetLength(Result, Length(Shaders));
  for i := 0 to High(Shaders) do
  begin
    Result[i].info := Shaders[i].StageCreateInfo^;
  end;
end;

function LabShaderStages(const Shaders: array of TLabShaderShared): TLabShaderStages;
  var i: Integer;
begin
  SetLength(Result, Length(Shaders));
  for i := 0 to High(Shaders) do
  begin
    Result[i].info := Shaders[i].Ptr.StageCreateInfo^;
  end;
end;

end.
