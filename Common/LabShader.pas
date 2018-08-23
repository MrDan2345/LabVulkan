unit LabShader;

interface

uses
  Vulkan,
  Classes,
  LabTypes,
  LabUtils,
  LabDevice;

type
  TLabShader = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkShaderModule;
    var _StageCreateInfo: TVkPipelineShaderStageCreateInfo;
    var _Hash: TVkUInt32;
    function GetStageCreateInfo: PVkPipelineShaderStageCreateInfo; inline;
  public
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
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32); override;
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString); override;
  end;

  TLabPixelShader = class (TLabShader)
  public
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32); override;
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString); override;
  end;

  TLabShaderStages = array of TVkPipelineShaderStageCreateInfo;
function LabShaderStages(const Shaders: array of TLabShader): TLabShaderStages;
function LabShaderStages(const Shaders: array of TLabShaderShared): TLabShaderStages;

implementation

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

function LabShaderStages(const Shaders: array of TLabShader): TLabShaderStages;
  var i: Integer;
begin
  SetLength(Result, Length(Shaders));
  for i := 0 to High(Shaders) do Move(Shaders[i].StageCreateInfo^, Result[i], SizeOf(TVkPipelineShaderStageCreateInfo));
end;

function LabShaderStages(const Shaders: array of TLabShaderShared): TLabShaderStages;
  var i: Integer;
begin
  SetLength(Result, Length(Shaders));
  for i := 0 to High(Shaders) do Move(Shaders[i].Ptr.StageCreateInfo^, Result[i], SizeOf(TVkPipelineShaderStageCreateInfo));
end;

end.
