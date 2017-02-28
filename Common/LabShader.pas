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
  public
    property VkHandle: TVkShaderModule read _Handle;
    constructor Create(const ADevice: TLabDeviceShared; const Data: Pointer; const Size: TVkInt32);
    constructor Create(const ADevice: TLabDeviceShared; const FileName: AnsiString);
    destructor Destroy; override;
  end;
  TLabShaderShared = specialize TLabSharedRef<TLabShader>;

implementation

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
  LabAssetVkError(Vulkan.CreateShaderModule(_Device.Ptr.VkHandle, @shader_info, nil, @_Handle));
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

end.
