unit LabDescriptorSet;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabDevice,
  LabDescriptorPool,
  SysUtils;

type
  TLabDescriptorSetLayout = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Bindings: array of TVkDescriptorSetLayoutBinding;
    var _Flags: TVkDescriptorSetLayoutCreateFlags;
    var _Handle: TVkDescriptorSetLayout;
    var _Hash: TVkUInt32;
    function GetBindingCount: TVkUInt32; inline;
    function GetBinding(const Index: TVkUInt32): PVkDescriptorSetLayoutBinding; inline;
  public
    property VkHandle: TVkDescriptorSetLayout read _Handle;
    property BindingCount: TVkUInt32 read GetBindingCount;
    property Binding[const Index: TVkUInt32]: PVkDescriptorSetLayoutBinding read GetBinding;
    property Hash: TVkUInt32 read _Hash;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ABindings: array of TVkDescriptorSetLayoutBinding;
      const AFlags: TVkDescriptorSetLayoutCreateFlags = 0
    );
    destructor Destroy; override;
  end;
  TLabDescriptorSetLayoutShared = specialize TLabSharedRef<TLabDescriptorSetLayout>;
  TLabDescriptorSetLayoutWeak = specialize TLabWeakRef<TLabDescriptorSetLayout>;

  TLabWriteDescriptorSet = record
    WriteDescriptorSet: TVkWriteDescriptorSet;
    ImageInfos: array of TVkDescriptorImageInfo;
    BufferInfos: array of TVkDescriptorBufferInfo;
    TexelBufferViews: array of TVkBufferView;
  end;

  TLabDescriptorSets = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Pool: TLabDescriptorPoolShared;
    var _Layouts: array of TLabDescriptorSetLayoutShared;
    var _Handles: array of TVkDescriptorSet;
    function GetHandleCount: TVkInt32; inline;
    function GetHandle(const Index: TVkInt32): TVkDescriptorSet; inline;
    function GetHandlePtr(const Index: TVkInt32): PVkDescriptorSet; inline;
    function GetLayout(const Index: TVkInt32): TLabDescriptorSetLayoutShared; inline;
  public
    property SetCount: TVkInt32 read GetHandleCount;
    property Pool: TLabDescriptorPoolShared read _Pool;
    property VkHandle[const Index: TVkInt32]: TVkDescriptorSet read GetHandle; default;
    property VkHandlePtr[const Index: TVkInt32]: PVkDescriptorSet read GetHandlePtr;
    property Layout[const Index: TVkInt32]: TLabDescriptorSetLayoutShared read GetLayout;
    constructor Create(
      const ADevice: TLabDeviceShared;
      const ADescriptorPool: TLabDescriptorPool;
      const ALayouts: array of TLabDescriptorSetLayout
    );
    destructor Destroy; override;
    procedure UpdateSets(
      const Writes: array of TLabWriteDescriptorSet;
      const Copies: array of TVkCopyDescriptorSet
    );
  end;
  TLabDescriptorSetsShared = specialize TLabSharedRef<TLabDescriptorSets>;

  TLabDescriptorSetBindings = record
    Bindings: array of TVkDescriptorSetLayoutBinding;
    SetCount: TVkUInt32;
  end;

  TLabDescriptorSetsFactory = class (TLabClass)
  private
    type TPool = class (TLabClass)
      type TPoolPtr = ^TPool;
      type TDescriptorType = record
        DescriptorType: TVkDescriptorType;
        CountTotal: TVkUInt32;
        CountAvailable: TVkUInt32;
        CountTmp: TVkUInt32;
      end;
      var PoolList: TPoolPtr;
      var Prev: TPool;
      var Next: TPool;
      var Pool: TLabDescriptorPoolShared;
      var DescriptorTypes: array of TDescriptorType;
      var CountSetTotal: TVkUInt32;
      var CountSetAvailable: TVkUInt32;
      var Hash: TVkUInt64;
      constructor Create(
        const ADevice: TLabDeviceShared;
        const APoolSizes: array of TVkDescriptorPoolSize;
        const AMaxSets: TVkUInt32;
        const APoolList: TPoolPtr
      );
      destructor Destroy; override;
      function Allocate(
        const Sizes: array of TVkDescriptorPoolSize;
        const SetCount: TVkUInt32 = 1
      ): Boolean;
      procedure Deallocate(
        const Sizes: array of TVkDescriptorPoolSize;
        const SetCount: TVkUInt32 = 1
      );
    end;
    type TLayoutTracker = class (TLabClass)
    public
      type TLayoutTrackerPtr = ^TLayoutTracker;
    private
      var _TrackerList: TLayoutTrackerPtr;
    public
      var Next: TLayoutTracker;
      var Prev: TLayoutTracker;
      var Layout: TLabDescriptorSetLayoutWeak;
      constructor Create(const ALayout: TLabDescriptorSetLayout; const ATrackerList: TLayoutTrackerPtr);
      destructor Destroy; override;
    end;
    type TPoolAllocTracker = class (TLabClass)
      Pool: TPool;
      Sizes: array of TVkDescriptorPoolSize;
      SetCount: TVkUInt32;
      constructor Create(
        const APool: TPool;
        const ASizes: array of TVkDescriptorPoolSize;
        const ASetCount: TVkUInt32 = 1
      );
      destructor Destroy; override;
    end;
    var _Device: TLabDeviceShared;
    var _PoolList: TPool;
    var _LayoutList: TLayoutTracker;
    function FindLayout(const Bindings: array of TVkDescriptorSetLayoutBinding): TLabDescriptorSetLayoutShared;
  public
    constructor Create(const ADevice: TLabDeviceShared);
    destructor Destroy; override;
    function Request(
      const Layouts: array of TLabDescriptorSetBindings
    ): TLabDescriptorSetsShared;
  end;
  TLabDescriptorSetsFactoryShared = specialize TLabSharedRef<TLabDescriptorSetsFactory>;

function LabDescriptorBinding(
  const Binding: TVkUInt32;
  const DescriptorType: TVkDescriptorType;
  const DescriptorCount: TVkUInt32 = 1;
  const StageFlags: TVkShaderStageFlags = TVkFlags(VK_SHADER_STAGE_ALL);
  const PImmutableSamplers: PVkSampler = nil
): TVkDescriptorSetLayoutBinding;

function LabWriteDescriptorSet(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const DescriptorType: TVkDescriptorType;
  const DstArrayElement: TVkUInt32;
  const DescriptorCount: TVkUInt32;
  const ImageInfos: array of TVkDescriptorImageInfo;
  const BufferInfos: array of TVkDescriptorBufferInfo;
  const TexelBufferViews: array of TVkBufferView
): TLabWriteDescriptorSet;

function LabWriteDescriptorSetStorageBuffer(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet;

function LabWriteDescriptorSetStorageBufferDynamic(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet;

function LabWriteDescriptorSetUniformBuffer(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet;

function LabWriteDescriptorSetUniformBufferDynamic(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet;

function LabWriteDescriptorSetImageSampler(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const ImageInfo: array of TVkDescriptorImageInfo
): TLabWriteDescriptorSet;

function LabWriteDescriptorSetImage(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const ImageInfo: array of TVkDescriptorImageInfo
): TLabWriteDescriptorSet;

function LabDescriptorBufferInfo(
  const Buffer: TVkBuffer;
  const Offset: TVkDeviceSize = 0;
  const Range: TVkDeviceSize = VK_WHOLE_SIZE
): TVkDescriptorBufferInfo; inline;

function LabDescriptorImageInfo(
  const ImageLayout: TVkImageLayout;
  const ImageView: TVkImageView;
  const Sampler: TVkSampler = VK_NULL_HANDLE
): TVkDescriptorImageInfo; inline;

function LabDescriptorSetBindings(const Bindings: array of TVkDescriptorSetLayoutBinding; const SetCount: TVkInt32 = 1): TLabDescriptorSetBindings;

implementation

constructor TLabDescriptorSetsFactory.TPoolAllocTracker.Create(
  const APool: TPool;
  const ASizes: array of TVkDescriptorPoolSize;
  const ASetCount: TVkUInt32
);
begin
  Pool := APool;
  SetLength(Sizes, Length(ASizes));
  Move(ASizes[0], Sizes[0], SizeOf(TVkDescriptorPoolSize) * Length(Sizes));
  SetCount := ASetCount;
end;

destructor TLabDescriptorSetsFactory.TPoolAllocTracker.Destroy;
begin
  Pool.Deallocate(Sizes, SetCount);
  inherited Destroy;
end;

constructor TLabDescriptorSetsFactory.TPool.Create(
  const ADevice: TLabDeviceShared;
  const APoolSizes: array of TVkDescriptorPoolSize; const AMaxSets: TVkUInt32;
  const APoolList: TPoolPtr
);
  var i: TVkInt32;
begin
  SetLength(DescriptorTypes, Length(APoolSizes));
  for i := 0 to High(APoolSizes) do
  begin
    DescriptorTypes[i].DescriptorType := APoolSizes[i].type_;
    DescriptorTypes[i].CountTotal := APoolSizes[i].descriptorCount;
    DescriptorTypes[i].CountAvailable := APoolSizes[i].descriptorCount;
  end;
  CountSetTotal := AMaxSets;
  CountSetAvailable := AMaxSets;
  Pool := TLabDescriptorPool.Create(ADevice, APoolSizes, AMaxSets);
  PoolList := APoolList;
  Prev := nil;
  Next := PoolList^;
  PoolList^ := Self;
end;

destructor TLabDescriptorSetsFactory.TPool.Destroy;
begin
  if Assigned(Prev) then Prev.Next := Next;
  if Assigned(Next) then Next.Prev := Prev;
  if PoolList^ = Self then PoolList^ := Next;
  Pool := nil;
  inherited Destroy;
end;

function TLabDescriptorSetsFactory.TPool.Allocate(
  const Sizes: array of TVkDescriptorPoolSize;
  const SetCount: TVkUInt32
): Boolean;
  var i, j: TVkInt32;
begin
  Result := CountSetAvailable >= SetCount;
  if not Result then Exit;
  for i := 0 to High(DescriptorTypes) do
  begin
    DescriptorTypes[i].CountTmp := DescriptorTypes[i].CountAvailable;
  end;
  for i := 0 to High(Sizes) do
  begin
    Result := False;
    for j := 0 to High(DescriptorTypes) do
    begin
      if (Sizes[i].type_ = DescriptorTypes[j].DescriptorType)
      and (DescriptorTypes[j].CountTmp >= SetCount * Sizes[i].descriptorCount) then
      begin
        Result := True;
        DescriptorTypes[j].CountTmp -= SetCount * Sizes[i].descriptorCount;
        Break;
      end;
      if not Result then Exit;
    end;
  end;
  CountSetAvailable -= SetCount;
  for i := 0 to High(DescriptorTypes) do
  begin
    DescriptorTypes[i].CountAvailable := DescriptorTypes[i].CountTmp;
  end;
end;

procedure TLabDescriptorSetsFactory.TPool.Deallocate(
  const Sizes: array of TVkDescriptorPoolSize;
  const SetCount: TVkUInt32
);
  var i, j: TVkInt32;
begin
  for i := 0 to High(Sizes) do
  begin
    for j := 0 to High(DescriptorTypes) do
    begin
      if (Sizes[i].type_ = DescriptorTypes[j].DescriptorType)
      and (DescriptorTypes[j].CountTotal - DescriptorTypes[j].CountAvailable >= SetCount * Sizes[i].descriptorCount) then
      begin
        DescriptorTypes[j].CountAvailable += SetCount * Sizes[i].descriptorCount;
      end;
    end;
  end;
  CountSetAvailable += SetCount;
end;

constructor TLabDescriptorSetsFactory.TLayoutTracker.Create(
  const ALayout: TLabDescriptorSetLayout;
  const ATrackerList: TLayoutTrackerPtr
);
begin
  _TrackerList := ATRackerList;
  Layout := ALayout;
  Prev := nil;
  Next := _TrackerList^;
  if Assigned(_TrackerList^) then
  begin
    _TrackerList^.Prev := Self;
  end;
  _TrackerList^ := Self;
end;

destructor TLabDescriptorSetsFactory.TLayoutTracker.Destroy;
begin
  if Assigned(Prev) then Prev.Next := Next;
  if Assigned(Next) then Next.Prev := Prev;
  if _TrackerList^ = Self then _TrackerList^ := Next;
  inherited Destroy;
end;

function TLabDescriptorSetLayout.GetBindingCount: TVkUInt32;
begin
  Result := Length(_Bindings);
end;

function TLabDescriptorSetLayout.GetBinding(const Index: TVkUInt32): PVkDescriptorSetLayoutBinding;
begin
  Result := @_Bindings[Index];
end;

constructor TLabDescriptorSetLayout.Create(
  const ADevice: TLabDeviceShared;
  const ABindings: array of TVkDescriptorSetLayoutBinding;
  const AFlags: TVkDescriptorSetLayoutCreateFlags
);
  var i: Integer;
  var descriptor_set_layout_info: TVkDescriptorSetLayoutCreateInfo;
begin
  LabLog('TLabDescriptorSetLayout.Create');
  _Device := ADevice;
  _Flags := AFlags;
  SetLength(_Bindings, Length(ABindings));
  Move(ABindings[0], _Bindings[0], Length(_Bindings) * SizeOf(TVkDescriptorSetLayoutBinding));
  for i := 0 to High(_Bindings) do
  if _Bindings[i].binding = $ffffffff then _Bindings[i].binding := TVkUInt32(i);
  {$Push}{$Hints off}
  FillChar(descriptor_set_layout_info, SizeOf(descriptor_set_layout_info), 0);
  {$Pop}
  descriptor_set_layout_info.sType := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
  descriptor_set_layout_info.pNext := nil;
  descriptor_set_layout_info.flags := _Flags;
  descriptor_set_layout_info.bindingCount := Length(_Bindings);
  descriptor_set_layout_info.pBindings := @_Bindings[0];
  LabAssertVkError(Vulkan.CreateDescriptorSetLayout(_Device.Ptr.VkHandle, @descriptor_set_layout_info, nil, @_Handle));
  _Hash := LabCRC32(0, @_Flags, SizeOf(_Flags));
  _Hash := LabCRC32(_Hash, @_Bindings[0], Length(_Bindings) * SizeOf(TVkDescriptorSetLayoutBinding));
end;

destructor TLabDescriptorSetLayout.Destroy;
begin
  Vulkan.DestroyDescriptorSetLayout(_Device.Ptr.VkHandle, _Handle, nil);
  inherited Destroy;
  LabLog('TLabDescriptorSetLayout.Destroy');
end;

function TLabDescriptorSets.GetHandleCount: TVkInt32;
begin
  Result := Length(_Handles);
end;

function TLabDescriptorSets.GetHandle(const Index: TVkInt32): TVkDescriptorSet;
begin
  Result := _Handles[Index];
end;

function TLabDescriptorSets.GetHandlePtr(const Index: TVkInt32): PVkDescriptorSet;
begin
  Result := @_Handles[Index];
end;

function TLabDescriptorSets.GetLayout(const Index: TVkInt32): TLabDescriptorSetLayoutShared;
begin
  Result := _Layouts[Index];
end;

constructor TLabDescriptorSets.Create(
  const ADevice: TLabDeviceShared;
  const ADescriptorPool: TLabDescriptorPool;
  const ALayouts: array of TLabDescriptorSetLayout
);
  var alloc_info: array[0..0] of TVkDescriptorSetAllocateInfo;
  var layouts: array of TVkDescriptorSetLayout;
  var i: TVkInt32;
begin
  LabLog('TLabDescriptorSets.Create');
  _Device := ADevice;
  _Pool := ADescriptorPool;
  SetLength(_Layouts, Length(ALayouts));
  SetLength(_Handles, Length(ALayouts));
  SetLength(layouts, Length(ALayouts));
  for i := 0 to High(ALayouts) do
  begin
    _Layouts[i] := ALayouts[i];
    layouts[i] := ALayouts[i].VkHandle;
  end;
  alloc_info[0].sType := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
  alloc_info[0].pNext := nil;
  alloc_info[0].descriptorPool := _Pool.Ptr.VkHandle;
  alloc_info[0].descriptorSetCount := Length(layouts);
  alloc_info[0].pSetLayouts := @layouts[0];
  LabAssertVkError(Vulkan.AllocateDescriptorSets(_Device.Ptr.VkHandle, @alloc_info[0], @_Handles[0]));
end;

destructor TLabDescriptorSets.Destroy;
begin
  LabAssertVkError(Vulkan.FreeDescriptorSets(_Device.Ptr.VkHandle, _Pool.Ptr.VkHandle, Length(_Handles), @_Handles[0]));
  inherited Destroy;
  LabLog('TLabDescriptorSets.Destroy');
end;

procedure TLabDescriptorSets.UpdateSets(
  const Writes: array of TLabWriteDescriptorSet;
  const Copies: array of TVkCopyDescriptorSet
);
  var WriteData: array of TVkWriteDescriptorSet;
  var WritePtr: PVkWriteDescriptorSet;
  var CopyPtr: PVkCopyDescriptorSet;
  var i: TVkInt32;
begin
  if Length(Writes) > 0 then
  begin
    SetLength(WriteData, Length(Writes));
    for i := 0 to High(Writes) do
    begin
      WriteData[i] := Writes[i].WriteDescriptorSet;
    end;
    WritePtr := @WriteData[0];
  end
  else
  begin
    WritePtr := nil;
  end;
  if Length(Copies) > 0 then
  begin
    CopyPtr := @Copies[0];
  end
  else
  begin
    CopyPtr := nil;
  end;
  Vulkan.UpdateDescriptorSets(_Device.Ptr.VkHandle, Length(Writes), WritePtr, Length(Copies), CopyPtr);
end;

function TLabDescriptorSetsFactory.FindLayout(const Bindings: array of TVkDescriptorSetLayoutBinding): TLabDescriptorSetLayoutShared;
  var Tracker: TLayoutTracker;
  var layout: TLabDescriptorSetLayoutShared;
  var i, j: TVkInt32;
  var match: Boolean;
begin
  Result := nil;
  Tracker := _LayoutList;
  while Assigned(Tracker) do
  begin
    layout := Tracker.Layout.AsShared;
    if layout.IsValid
    and (layout.Ptr.BindingCount = Length(Bindings)) then
    begin
      match := False;
      for i := 0 to High(Bindings) do
      begin
        match := False;
        for j := 0 to layout.Ptr.BindingCount - 1 do
        if (layout.Ptr.Binding[j]^.binding = Bindings[i].binding)
        and (layout.Ptr.Binding[j]^.descriptorType = Bindings[i].descriptorType)
        and (layout.Ptr.Binding[j]^.descriptorCount = Bindings[i].descriptorCount)
        and (layout.Ptr.Binding[j]^.stageFlags = Bindings[i].stageFlags) then
        begin
          match := True;
          Break;
        end;
        if not match then Break;
      end;
      if match then
      begin
        Result := layout;
        Exit;
      end;
    end;
    Tracker := Tracker.Next;
  end;
  Result := TLabDescriptorSetLayout.Create(_Device, Bindings);
  Tracker := TLayoutTracker.Create(Result.Ptr, @_LayoutList);
  Result.Ptr.AddReference(Tracker);
end;

constructor TLabDescriptorSetsFactory.Create(const ADevice: TLabDeviceShared);
begin
  _Device := ADevice;
  _PoolList := nil;
  _LayoutList := nil;
end;

destructor TLabDescriptorSetsFactory.Destroy;
begin
  while Assigned(_LayoutList) do
  begin
    _LayoutList.Layout.Ptr.RemoveReference(_LayoutList);
    _LayoutList.Free;
  end;
  while Assigned(_PoolList) do _PoolList.Free;
  inherited Destroy;
end;

function TLabDescriptorSetsFactory.Request(
  const Layouts: array of TLabDescriptorSetBindings
): TLabDescriptorSetsShared;
  var Pool: TPool;
  var Sizes: array of TVkDescriptorPoolSize;
  var i, j, n: TVkInt32;
  var size_found: Boolean;
  var AllocTracker: TPoolAllocTracker;
  var desc_layouts: array of TLabDescriptorSetLayout;
  var layouts_shared: array of TLabDescriptorSetLayoutShared;
  var max_sets: TVkUInt32;
begin
  max_sets := 0;
  for i := 0 to High(Layouts) do
  begin
    max_sets += Layouts[i].SetCount;
    for j := 0 to High(Layouts[i].Bindings) do
    begin
      size_found := False;
      for n := 0 to High(Sizes) do
      if Sizes[n].type_ = Layouts[i].Bindings[j].descriptorType then
      begin
        Sizes[n].descriptorCount += Layouts[i].Bindings[j].descriptorCount * Layouts[i].SetCount;
        size_found := True;
        Break;
      end;
      if not size_found then
      begin
        SetLength(Sizes, Length(Sizes) + 1);
        n := High(Sizes);
        Sizes[n].type_ := Layouts[i].Bindings[j].descriptorType;
        Sizes[n].descriptorCount := Layouts[i].Bindings[j].descriptorCount * Layouts[i].SetCount;
      end;
    end;
  end;
  Pool := _PoolList;
  while Assigned(Pool) do
  begin
    if Pool.Allocate(Sizes) then Break;
    Pool := Pool.Next;
  end;
  if not Assigned(Pool) then
  begin
    Pool := TPool.Create(_Device, Sizes, max_sets, @_PoolList);
    Pool.Allocate(Sizes);
  end;
  AllocTracker := TPoolAllocTracker.Create(Pool, Sizes);
  SetLength(desc_layouts, max_sets);
  SetLength(layouts_shared, Length(Layouts));
  n := 0;
  for i := 0 to High(Layouts) do
  begin
    layouts_shared[i] := FindLayout(Layouts[i].Bindings);
    for j := 0 to Layouts[i].SetCount - 1 do
    begin
      desc_layouts[n] := layouts_shared[i].Ptr;
      Inc(n);
    end;
  end;
  Result := TLabDescriptorSets.Create(_Device, Pool.Pool.Ptr, desc_layouts);
  Result.Ptr.AddReference(AllocTracker);
end;

function LabDescriptorBinding(
  const Binding: TVkUInt32;
  const DescriptorType: TVkDescriptorType;
  const DescriptorCount: TVkUInt32;
  const StageFlags: TVkShaderStageFlags;
  const PImmutableSamplers: PVkSampler
): TVkDescriptorSetLayoutBinding;
begin
  Result.binding := Binding;
  Result.descriptorType := DescriptorType;
  Result.descriptorCount := DescriptorCount;
  Result.stageFlags := StageFlags;
  Result.pImmutableSamplers := PImmutableSamplers;
end;

function LabWriteDescriptorSet(const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32; const DescriptorType: TVkDescriptorType;
  const DstArrayElement: TVkUInt32; const DescriptorCount: TVkUInt32;
  const ImageInfos: array of TVkDescriptorImageInfo;
  const BufferInfos: array of TVkDescriptorBufferInfo;
  const TexelBufferViews: array of TVkBufferView): TLabWriteDescriptorSet;
begin
  Result.WriteDescriptorSet.sType := VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
  Result.WriteDescriptorSet.pNext := nil;
  Result.WriteDescriptorSet.dstSet := DstSet;
  Result.WriteDescriptorSet.dstBinding := DstBinding;
  Result.WriteDescriptorSet.dstArrayElement := DstArrayElement;
  Result.WriteDescriptorSet.descriptorCount := DescriptorCount;
  Result.WriteDescriptorSet.descriptorType := DescriptorType;
  if Length(ImageInfos) > 0 then
  begin
    SetLength(Result.ImageInfos, Length(ImageInfos));
    Move(ImageInfos[0], Result.ImageInfos[0], SizeOf(TVkDescriptorImageInfo));
    Result.WriteDescriptorSet.pImageInfo := @Result.ImageInfos[0];
  end
  else
  begin
    Result.WriteDescriptorSet.pImageInfo := nil;
  end;
  if Length(BufferInfos) > 0 then
  begin
    SetLength(Result.BufferInfos, Length(BufferInfos));
    Move(BufferInfos[0], Result.BufferInfos[0], SizeOf(TVkDescriptorBufferInfo));
    Result.WriteDescriptorSet.pBufferInfo := @Result.BufferInfos[0];
  end
  else
  begin
    Result.WriteDescriptorSet.pBufferInfo := nil;
  end;
  if Length(TexelBufferViews) > 0 then
  begin
    SetLength(Result.TexelBufferViews, Length(TexelBufferViews));
    Move(TexelBufferViews[0], Result.TexelBufferViews[0], SizeOf(TVkBufferView));
    Result.WriteDescriptorSet.pTexelBufferView := @TexelBufferViews[0];
  end
  else
  begin
    Result.WriteDescriptorSet.pTexelBufferView := nil;
  end;
end;

function LabWriteDescriptorSetStorageBuffer(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet;
begin
  Result := LabWriteDescriptorSet(
    DstSet, DstBinding,
    VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
    0, Length(BufferInfo), [], BufferInfo, []
  );
end;

function LabWriteDescriptorSetStorageBufferDynamic(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet;
begin
  Result := LabWriteDescriptorSet(
    DstSet, DstBinding,
    VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC,
    0, Length(BufferInfo), [], BufferInfo, []
  );
end;

function LabWriteDescriptorSetUniformBuffer(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet;
begin
  Result := LabWriteDescriptorSet(
    DstSet, DstBinding,
    VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
    0, Length(BufferInfo), [], BufferInfo, []
  );
end;

function LabWriteDescriptorSetUniformBufferDynamic(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const BufferInfo: array of TVkDescriptorBufferInfo
): TLabWriteDescriptorSet;
begin
  Result := LabWriteDescriptorSet(
    DstSet, DstBinding,
    VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
    0, Length(BufferInfo), [], BufferInfo, []
  );
end;

function LabWriteDescriptorSetImageSampler(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const ImageInfo: array of TVkDescriptorImageInfo
): TLabWriteDescriptorSet;
begin
  Result := LabWriteDescriptorSet(
    DstSet, DstBinding,
    VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
    0, Length(ImageInfo), ImageInfo, [], []
  );
end;

function LabWriteDescriptorSetImage(
  const DstSet: TVkDescriptorSet;
  const DstBinding: TVkUInt32;
  const ImageInfo: array of TVkDescriptorImageInfo
): TLabWriteDescriptorSet;
begin
  Result := LabWriteDescriptorSet(
    DstSet, DstBinding,
    VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE,
    0, Length(ImageInfo), ImageInfo, [], []
  );
end;

function LabDescriptorBufferInfo(
  const Buffer: TVkBuffer;
  const Offset: TVkDeviceSize;
  const Range: TVkDeviceSize
): TVkDescriptorBufferInfo;
begin
  Result.buffer := Buffer;
  Result.offset := Offset;
  Result.range := Range;
end;

function LabDescriptorImageInfo(
  const ImageLayout: TVkImageLayout;
  const ImageView: TVkImageView;
  const Sampler: TVkSampler
): TVkDescriptorImageInfo;
begin
  Result.imageLayout := ImageLayout;
  Result.imageView := ImageView;
  Result.sampler := Sampler;
end;

function LabDescriptorSetBindings(
  const Bindings: array of TVkDescriptorSetLayoutBinding;
  const SetCount: TVkInt32): TLabDescriptorSetBindings;
begin
  SetLength(Result.Bindings, Length(Bindings));
  Move(Bindings[0], Result.Bindings[0], Length(Bindings) * SizeOf(TVkDescriptorSetLayoutBinding));
  Result.SetCount := SetCount;
end;

end.
