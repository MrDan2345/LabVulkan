unit LabDescriptorPool;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice;

type
  TLabDescriptorPool = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Handle: TVkDescriptorPool;
  public
    property VkHandle: TVkDescriptorPool read _Handle;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const PoolSizes: array of TVkDescriptorPoolSize;
      const MaxSets: TVkUInt32
    );
    destructor Destroy; override;
  end;
  TLabDescriptorPoolShared = specialize TLabSharedRef<TLabDescriptorPool>;

function LabDescriptorPoolSize(
  const DescriptorType: TVkDescriptorType;
  const DescriptorCount: TVkUInt32
): TVkDescriptorPoolSize;

implementation

function LabDescriptorPoolSize(
  const DescriptorType: TVkDescriptorType;
  const DescriptorCount: TVkUInt32
): TVkDescriptorPoolSize;
begin
  Result.type_ := DescriptorType;
  Result.descriptorCount := DescriptorCount;
end;

constructor TLabDescriptorPool.Create(
  const ADevice: TLabDeviceShared;
  const PoolSizes: array of TVkDescriptorPoolSize;
  const MaxSets: TVkUInt32
);
  var descriptor_pool_info: TVkDescriptorPoolCreateInfo;
begin
  LabLog('TLabDescriptorPool.Create');
  inherited Create;
  _Device := ADevice;
  FillChar(descriptor_pool_info, SizeOf(descriptor_pool_info), 0);
  descriptor_pool_info.sType := VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
  descriptor_pool_info.pNext := nil;
  descriptor_pool_info.maxSets := MaxSets;
  descriptor_pool_info.poolSizeCount := Length(PoolSizes);
  descriptor_pool_info.pPoolSizes := @PoolSizes[0];
  LabAssertVkError(vk.CreateDescriptorPool(_Device.Ptr.VkHandle, @descriptor_pool_info, nil, @_Handle));
end;

destructor TLabDescriptorPool.Destroy;
begin
  vk.DestroyDescriptorPool(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabDescriptorPool.Destroy');
end;

end.
