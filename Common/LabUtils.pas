unit LabUtils;

interface
{$modeswitch advancedrecords}

uses
  SysUtils,
  Vulkan,
  LabTypes;

type
  generic TLabList<T> = class (TLabClass)
  private
    var _Items: array of T;
    var _Increment: Integer;
    var _ItemCount: Integer;
  public
    type TItemPtr = ^T;
    type TCmpFunc = function (const Item0, Item1: T): Integer;
    type TCmpFuncObj = function (const Item0, Item1: T): Integer of object;
  protected
    procedure SetItem(const Index: Integer; const Value: T); inline;
    function GetItem(const Index: Integer): T; inline;
    procedure SetCapacity(const Value: Integer); inline;
    function GetCapacity: Integer; inline;
    function GetFirst: T; inline;
    function GetLast: T; inline;
    function GetData: TItemPtr; inline;
  public
    constructor Create;
    constructor Create(const DefaultCapacity: Integer; Increment: Integer = 256);
    destructor Destroy; override;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read _ItemCount;
    property Items[const Index: Integer]: T read GetItem write SetItem; default;
    property First: T read GetFirst;
    property Last: T read GetLast;
    property Data: TItemPtr read GetData;
    function Find(const Item: T): Integer;
    function Add(const Item: T): Integer;
    function Pop: T;
    function Extract(const Index: Integer): T;
    function Insert(const Index: Integer; const Item: T): Integer;
    procedure Delete(const Index: Integer; const ItemCount: Integer = 1);
    procedure Remove(const Item: T);
    procedure Clear;
    procedure Allocate(const Amount: Integer);
    procedure Allocate(const Amount: Integer; const DefaultValue: T);
    function Search(const CmpFunc: TCmpFunc; const Item: T): Integer; overload;
    function Search(const CmpFunc: TCmpFuncObj; const Item: T): Integer; overload;
    procedure Sort(const CmpFunc: TCmpFunc; RangeStart, RangeEnd: Integer); overload;
    procedure Sort(const CmpFunc: TCmpFuncObj; RangeStart, RangeEnd: Integer); overload;
    procedure Sort(const CmpFunc: TCmpFunc); overload;
    procedure Sort(const CmpFunc: TCmpFuncObj); overload;
  end;

  generic TLabRefList<T> = class (TLabClass)
  private
    var _Items: array of T;
    var _Increment: Integer;
    var _ItemCount: Integer;
  public
    type TItemPtr = ^T;
    type TCmpFunc = function (const Item0, Item1: T): Integer;
    type TCmpFuncObj = function (const Item0, Item1: T): Integer of object;
  protected
    procedure SetItem(const Index: Integer; const Value: T); inline;
    function GetItem(const Index: Integer): T; inline;
    procedure SetCapacity(const Value: Integer); inline;
    function GetCapacity: Integer; inline;
    function GetFirst: T; inline;
    function GetLast: T; inline;
    function GetData: TItemPtr; inline;
  public
    constructor Create;
    constructor Create(const DefaultCapacity: Integer; Increment: Integer = 256);
    destructor Destroy; override;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read _ItemCount;
    property Items[const Index: Integer]: T read GetItem write SetItem; default;
    property First: T read GetFirst;
    property Last: T read GetLast;
    property Data: TItemPtr read GetData;
    function Find(const Item: T): Integer;
    function Add(const Item: T): Integer;
    function Pop: T;
    function Extract(const Index: Integer): T;
    function Insert(const Index: Integer; const Item: T): Integer;
    procedure Delete(const Index: Integer; const ItemCount: Integer = 1);
    procedure Remove(const Item: T);
    procedure Clear;
    procedure Allocate(const Amount: Integer);
    procedure Allocate(const Amount: Integer; const DefaultValue: T);
    function Search(const CmpFunc: TCmpFunc; const Item: T): Integer; overload;
    function Search(const CmpFunc: TCmpFuncObj; const Item: T): Integer; overload;
    procedure Sort(const CmpFunc: TCmpFunc; RangeStart, RangeEnd: Integer); overload;
    procedure Sort(const CmpFunc: TCmpFuncObj; RangeStart, RangeEnd: Integer); overload;
    procedure Sort(const CmpFunc: TCmpFunc); overload;
    procedure Sort(const CmpFunc: TCmpFuncObj); overload;
  end;

  TLabListString = specialize TLabList<AnsiString>;
  TLabListStringShared = specialize TLabSharedRef<TLabListString>;

procedure LabZeroMem(const Ptr: Pointer; const Size: SizeInt);
function LabCheckGlobalExtensionPresent(const ExtensionName: AnsiString): Boolean;
function LabCheckDeviceExtensionPresent(const PhysicalDevice: TVkPhysicalDevice; const ExtensionName: String): Boolean;
procedure LabLog(const Msg: AnsiString; const Offset: Integer = 0);
procedure LabLogOffset(const Offset: Integer);
procedure LabAssertVkError(const State: TVkResult);
function LabLogVkError(const State: TVkResult): TVkResult;
function LabVkErrorString(const State: TVkResult): String;
function LabVkValidHandle(const Handle: TVkDispatchableHandle): Boolean; inline;
procedure LabProfileStart(const Name: AnsiString);
procedure LabProfileStop;

implementation

type TProfileTime = record
  tv: Double;
  name: AnsiString;
end;

var LogFile: Text;
var LogOffset: Integer = 0;
var LogLock: Integer = 0;
var ProfileStack: array [0..127] of TProfileTime;
var ProfileIndex: Integer = -1;

//TLabList BEGIN
{$Hints off}
procedure TLabList.SetItem(const Index: Integer; const Value: T);
begin
  _Items[Index] := Value;
end;

function TLabList.GetItem(const Index: Integer): T;
begin
  Result := _Items[Index];
end;

procedure TLabList.SetCapacity(const Value: Integer);
begin
  SetLength(_Items, Value);
end;

function TLabList.GetCapacity: Integer;
begin
  Result := Length(_Items);
end;

function TLabList.GetFirst: T;
begin
  Result := _Items[0];
end;

function TLabList.GetLast: T;
begin
  Result := _Items[_ItemCount - 1];
end;

function TLabList.GetData: TItemPtr;
begin
  if _ItemCount > 0 then
  Result := @_Items[0]
  else
  Result := nil;
end;

constructor TLabList.Create;
begin
  _Increment := 256;
  _ItemCount := 0;
end;

constructor TLabList.Create(const DefaultCapacity: Integer; Increment: Integer);
begin
  if DefaultCapacity > 0 then SetCapacity(DefaultCapacity);
  if Increment < 1 then _Increment := 1 else _Increment := Increment;
  _ItemCount := 0;
end;

destructor TLabList.Destroy;
begin
  inherited Destroy;
end;

function TLabList.Find(const Item: T): Integer;
  var i: Integer;
begin
  for i := 0 to _ItemCount - 1 do
  if _Items[i] = Item then
  begin
    Result := i;
    Exit;
  end;
  Result := -1;
end;

function TLabList.Add(const Item: T): Integer;
begin
  if Length(_Items) <= _ItemCount then
  SetLength(_Items, Length(_Items) + _Increment);
  _Items[_ItemCount] := Item;
  Result := _ItemCount;
  Inc(_ItemCount);
end;

function TLabList.Pop: T;
begin
  Result := Extract(_ItemCount - 1);
end;

function TLabList.Extract(const Index: Integer): T;
begin
  Result := _Items[Index];
  Delete(Index);
end;

function TLabList.Insert(const Index: Integer; const Item: T): Integer;
  var i: Integer;
begin
  if Length(_Items) <= _ItemCount then
  SetLength(_Items, Length(_Items) + _Increment);
  if Index < _ItemCount then
  begin
    for i := _ItemCount - 1 downto Index do
    _Items[i + 1] := _Items[i];
    _Items[Index] := Item;
    Result := Index;
  end
  else
  begin
    _Items[_ItemCount] := Item;
    Result := _ItemCount;
  end;
  Inc(_ItemCount);
end;

procedure TLabList.Delete(const Index: Integer; const ItemCount: Integer);
  var i: Integer;
begin
  for i := Index to _ItemCount - (1 + ItemCount) do
  begin
    _Items[i] := _Items[i + ItemCount];
  end;
  Dec(_ItemCount, ItemCount);
end;

procedure TLabList.Remove(const Item: T);
  var i: Integer;
begin
  i := Find(Item);
  if i > -1 then Delete(i);
end;

procedure TLabList.Clear;
begin
  _ItemCount := 0;
end;

procedure TLabList.Allocate(const Amount: Integer);
begin
  SetCapacity(_ItemCount + Amount);
  _ItemCount += Amount;
end;

procedure TLabList.Allocate(const Amount: Integer; const DefaultValue: T);
  var i, j: Integer;
begin
  j := _ItemCount;
  Allocate(Amount);
  for i := j to _ItemCount - 1 do
  begin
    _Items[i] := DefaultValue;
  end;
end;

function TLabList.Search(const CmpFunc: TCmpFunc; const Item: T): Integer;
  var l, h, m, r: Integer;
begin
  l := 0;
  h := _ItemCount - 1;
  while l <= h do
  begin
    m := (l + h) shr 1;
    r := CmpFunc(_Items[m], Item);
    if r = 0 then Exit(m)
    else if r < 0 then l := m + 1
    else h := m - 1;
  end;
  if (l < _ItemCount) and (CmpFunc(_Items[l], Item) = 0) then Exit(l) else Exit(-1);
end;

function TLabList.Search(const CmpFunc: TCmpFuncObj; const Item: T): Integer;
  var l, h, m, r: Integer;
begin
  l := 0;
  h := _ItemCount - 1;
  while l <= h do
  begin
    m := (l + h) shr 1;
    r := CmpFunc(_Items[m], Item);
    if r = 0 then Exit(m)
    else if r < 0 then l := m + 1
    else h := m - 1;
  end;
  if (l < _ItemCount) and (CmpFunc(_Items[l], Item) = 0) then Exit(l) else Exit(-1);
end;

procedure TLabList.Sort(const CmpFunc: TCmpFunc; RangeStart, RangeEnd: Integer);
  var i, j : LongInt;
  var tmp, pivot: T;
begin
  if RangeEnd < RangeStart then Exit;
  i := RangeStart;
  j := RangeEnd;
  pivot := _Items[(RangeStart + RangeEnd) shr 1];
  repeat
    while CmpFunc(pivot, _Items[i]) > 0 do i := i + 1;
    while CmpFunc(pivot, _Items[j]) < 0 do j := j - 1;
    if i <= j then
    begin
      tmp := _Items[i];
      _Items[i] := _Items[j];
      _Items[j] := tmp;
      j := j - 1;
      i := i + 1;
    end;
  until i > j;
  if RangeStart < j then Sort(CmpFunc, RangeStart, j);
  if i < RangeEnd then Sort(CmpFunc, i, RangeEnd);
end;

procedure TLabList.Sort(const CmpFunc: TCmpFuncObj; RangeStart, RangeEnd: Integer);
  var i, j : LongInt;
  var tmp, pivot: T;
begin
  i := RangeStart;
  j := RangeEnd;
  pivot := _Items[(RangeStart + RangeEnd) shr 1];
  repeat
    while CmpFunc(pivot, _Items[i]) > 0 do i := i + 1;
    while CmpFunc(pivot, _Items[j]) < 0 do j := j - 1;
    if i <= j then
    begin
      tmp := _Items[i];
      _Items[i] := _Items[j];
      _Items[j] := tmp;
      j := j - 1;
      i := i + 1;
    end;
  until i > j;
  if RangeStart < j then Sort(CmpFunc, RangeStart, j);
  if i < RangeEnd then Sort(CmpFunc, i, RangeEnd);
end;

procedure TLabList.Sort(const CmpFunc: TCmpFunc);
begin
  Sort(CmpFunc, 0, _ItemCount - 1);
end;

procedure TLabList.Sort(const CmpFunc: TCmpFuncObj);
begin
  Sort(CmpFunc, 0, _ItemCount - 1);
end;
{$Hints on}
//TLabList END

//TLabRefList BEGIN
procedure TLabRefList.SetItem(const Index: Integer; const Value: T);
begin
  _Items[Index] := Value;
end;

function TLabRefList.GetItem(const Index: Integer): T;
begin
  Result := _Items[Index];
end;

procedure TLabRefList.SetCapacity(const Value: Integer);
  var j, i: Integer;
begin
  j := Length(_Items);
  SetLength(_Items, Value);
  for i := j to High(_Items) do
  begin
    _Items[i] := nil;
  end;
end;

function TLabRefList.GetCapacity: Integer;
begin
  Result := Length(_Items);
end;

function TLabRefList.GetFirst: T;
begin
  Result := _Items[0];
end;

function TLabRefList.GetLast: T;
begin
  Result := _Items[_ItemCount - 1];
end;

function TLabRefList.GetData: TItemPtr;
begin
  if _ItemCount > 0 then
  Result := @_Items[0]
  else
  Result := nil;
end;

constructor TLabRefList.Create;
begin
  inherited Create;
  _Increment := 256;
  _ItemCount := 0;
end;

constructor TLabRefList.Create(const DefaultCapacity: Integer; Increment: Integer);
begin
  if DefaultCapacity > 0 then SetCapacity(DefaultCapacity);
  if Increment < 1 then _Increment := 1 else _Increment := Increment;
  _ItemCount := 0;
end;

destructor TLabRefList.Destroy;
  var i: Integer;
begin
  for i := 0 to _ItemCount - 1 do
  begin
    _Items[i] := nil;
  end;
  inherited Destroy;
end;

function TLabRefList.Find(const Item: T): Integer;
  var i: Integer;
begin
  for i := 0 to _ItemCount - 1 do
  if _Items[i]._Ptr = Item._Ptr then
  begin
    Result := i;
    Exit;
  end;
  Result := -1;
end;

function TLabRefList.Add(const Item: T): Integer;
begin
  if Length(_Items) <= _ItemCount then
  SetLength(_Items, Length(_Items) + _Increment);
  _Items[_ItemCount] := Item;
  Result := _ItemCount;
  Inc(_ItemCount);
end;

function TLabRefList.Pop: T;
begin
  Result := Extract(_ItemCount - 1);
end;

function TLabRefList.Extract(const Index: Integer): T;
begin
  Result := _Items[Index];
  Delete(Index);
end;

function TLabRefList.Insert(const Index: Integer; const Item: T): Integer;
  var i: Integer;
begin
  if Length(_Items) <= _ItemCount then
  SetLength(_Items, Length(_Items) + _Increment);
  if Index < _ItemCount then
  begin
    for i := _ItemCount - 1 downto Index do
    _Items[i + 1] := _Items[i];
    _Items[Index] := Item;
    Result := Index;
  end
  else
  begin
    _Items[_ItemCount] := Item;
    Result := _ItemCount;
  end;
  Inc(_ItemCount);
end;

procedure TLabRefList.Delete(const Index: Integer; const ItemCount: Integer);
  var i: Integer;
begin
  for i := Index to _ItemCount - (1 + ItemCount) do
  begin
    _Items[i] := _Items[i + ItemCount];
    _Items[i + ItemCount] := nil;
  end;
  Dec(_ItemCount, ItemCount);
end;

procedure TLabRefList.Remove(const Item: T);
  var i: Integer;
begin
  i := Find(Item);
  if i > -1 then
  Delete(i);
end;

procedure TLabRefList.Clear;
  var i: Integer;
begin
  for i := 0 to _ItemCount - 1 do
  begin
    _Items[i] := nil;
  end;
  _ItemCount := 0;
end;

procedure TLabRefList.Allocate(const Amount: Integer);
begin
  SetCapacity(_ItemCount + Amount);
  _ItemCount += Amount;
end;

procedure TLabRefList.Allocate(const Amount: Integer; const DefaultValue: T);
  var i, j: Integer;
begin
  j := _ItemCount;
  Allocate(Amount);
  for i := j to _ItemCount - 1 do
  begin
    _Items[i] := DefaultValue;
  end;
end;

function TLabRefList.Search(const CmpFunc: TCmpFunc; const Item: T): Integer;
  var l, h, m, r: Integer;
begin
  l := 0;
  h := _ItemCount - 1;
  while l <= h do
  begin
    m := (l + h) shr 1;
    r := CmpFunc(_Items[m], Item);
    if r = 0 then Exit(m)
    else if r < 0 then l := m + 1
    else h := m - 1;
  end;
  if (l < _ItemCount) and (CmpFunc(_Items[l], Item) = 0) then Exit(l) else Exit(-1);
end;

function TLabRefList.Search(const CmpFunc: TCmpFuncObj; const Item: T): Integer;
  var l, h, m, r: Integer;
begin
  l := 0;
  h := _ItemCount - 1;
  while l <= h do
  begin
    m := (l + h) shr 1;
    r := CmpFunc(_Items[m], Item);
    if r = 0 then Exit(m)
    else if r < 0 then l := m + 1
    else h := m - 1;
  end;
  if (l < _ItemCount) and (CmpFunc(_Items[l], Item) = 0) then Exit(l) else Exit(-1);
end;

procedure TLabRefList.Sort(const CmpFunc: TCmpFunc; RangeStart, RangeEnd: Integer);
  var i, j : LongInt;
  var tmp, pivot: T;
begin
  if RangeEnd < RangeStart then Exit;
  i := RangeStart;
  j := RangeEnd;
  pivot := _Items[(RangeStart + RangeEnd) shr 1];
  repeat
    while CmpFunc(pivot, _Items[i]) > 0 do i := i + 1;
    while CmpFunc(pivot, _Items[j]) < 0 do j := j - 1;
    if i <= j then
    begin
      tmp := _Items[i];
      _Items[i] := _Items[j];
      _Items[j] := tmp;
      j := j - 1;
      i := i + 1;
    end;
  until i > j;
  if RangeStart < j then Sort(CmpFunc, RangeStart, j);
  if i < RangeEnd then Sort(CmpFunc, i, RangeEnd);
end;

procedure TLabRefList.Sort(const CmpFunc: TCmpFuncObj; RangeStart, RangeEnd: Integer);
  var i, j : LongInt;
  var tmp, pivot: T;
begin
  i := RangeStart;
  j := RangeEnd;
  pivot := _Items[(RangeStart + RangeEnd) shr 1];
  repeat
    while CmpFunc(pivot, _Items[i]) > 0 do i := i + 1;
    while CmpFunc(pivot, _Items[j]) < 0 do j := j - 1;
    if i <= j then
    begin
      tmp := _Items[i];
      _Items[i] := _Items[j];
      _Items[j] := tmp;
      j := j - 1;
      i := i + 1;
    end;
  until i > j;
  if RangeStart < j then Sort(CmpFunc, RangeStart, j);
  if i < RangeEnd then Sort(CmpFunc, i, RangeEnd);
end;

procedure TLabRefList.Sort(const CmpFunc: TCmpFunc);
begin
  Sort(CmpFunc, 0, _ItemCount - 1);
end;

procedure TLabRefList.Sort(const CmpFunc: TCmpFuncObj);
begin
  Sort(CmpFunc, 0, _ItemCount - 1);
end;
//TLabRefList END

procedure LabZeroMem(const Ptr: Pointer; const Size: SizeInt);
begin
  if Ptr = nil then Exit;
  {$Warnings off}
  FillChar(Ptr^, Size, 0);
  {$Warnings on}
end;

function LabCheckGlobalExtensionPresent(const ExtensionName: AnsiString): Boolean;
  var ext_count: TVkUInt32;
  var extensions: array of TVkExtensionProperties;
  var ext: TVkExtensionProperties;
begin
  ext_count := 0;
  vk.EnumerateInstanceExtensionProperties(nil, @ext_count, nil);
  SetLength(extensions, ext_count);
  vk.EnumerateInstanceExtensionProperties(nil, @ext_count, @extensions[0]);
  for ext in extensions do
  if ExtensionName = ext.extensionName then
  begin
    Result := True;
    Exit;
  end;
  Result := False;
end;

function LabCheckDeviceExtensionPresent(const PhysicalDevice: TVkPhysicalDevice; const ExtensionName: String): Boolean;
  var ext_count: TVkUInt32;
  var extensions: array of TVkExtensionProperties;
  var ext: TVkExtensionProperties;
begin
  ext_count := 0;
  vk.EnumerateDeviceExtensionProperties(PhysicalDevice, nil, @ext_count, nil);
  SetLength(extensions, ext_count);
  vk.EnumerateDeviceExtensionProperties(PhysicalDevice, nil, @ext_count, @extensions[0]);
  for ext in extensions do
  if ExtensionName = ext.extensionName then
  begin
    Result := True;
    Exit;
  end;
  Result := False;
end;

procedure LabLog(const Msg: AnsiString; const Offset: Integer);
  var Spaces: AnsiString;
begin
  if (Offset < 0) then
  begin
    LabLogOffset(Offset);
  end;
  if LogOffset > 0 then
  begin
    SetLength(Spaces, LogOffset);
    FillChar(Spaces[1], LogOffset, ' ');
    WriteLn(LogFile, Spaces + Msg);
    WriteLn(Spaces + Msg);
  end
  else
  begin
    WriteLn(LogFile, Msg);
    WriteLn(Msg);
  end;
  if (Offset > 0) then
  begin
    LabLogOffset(Offset);
  end;
end;

procedure LabLogOffset(const Offset: Integer);
begin
  while InterlockedCompareExchange(LogLock, 1, 0) = 1 do;
  LogOffset := LogOffset + Offset;
  InterLockedExchange(LogLock, 0);
end;

procedure LabAssertVkError(const State: TVkResult);
begin
  Assert(LabLogVkError(State) = VK_SUCCESS, LabVkErrorString(State));
end;

function LabLogVkError(const State: TVkResult): TVkResult;
begin
  if State <> VK_SUCCESS then
  begin
    WriteLn('Vulkan Error: ' + LabVkErrorString(State));
  end;
  Result := State;
end;

function LabVkValidHandle(const Handle: TVkDispatchableHandle): Boolean;
begin
  Result := Handle <> VK_NULL_HANDLE;
end;

procedure LabProfileStart(const Name: AnsiString);
begin
  Inc(ProfileIndex);
  ProfileStack[ProfileIndex].name := Name;
  ProfileStack[ProfileIndex].tv := Now * 24 * 60 * 60;
end;

procedure LabProfileStop;
  var t: Double;
begin
  if ProfileIndex < 0 then Exit;
  t := Now * 24 * 60 * 60 - ProfileStack[ProfileIndex].tv;
  LabLog('Profile[' + ProfileStack[ProfileIndex].name + ']: ' + FloatToStr(t));
  Dec(ProfileIndex);
end;

function LabVkErrorString(const State: TVkResult): String;
begin
  case State of
    VK_NOT_READY: Result := 'NOT_READY';
    VK_TIMEOUT: Result := 'TIMEOUT';
    VK_EVENT_SET: Result := 'EVENT_SET';
    VK_EVENT_RESET: Result := 'EVENT_RESET';
    VK_INCOMPLETE: Result := 'INCOMPLETE';
    VK_ERROR_OUT_OF_HOST_MEMORY: Result := 'ERROR_OUT_OF_HOST_MEMORY';
    VK_ERROR_OUT_OF_DEVICE_MEMORY: Result := 'ERROR_OUT_OF_DEVICE_MEMORY';
    VK_ERROR_INITIALIZATION_FAILED: Result := 'ERROR_INITIALIZATION_FAILED';
    VK_ERROR_DEVICE_LOST: Result := 'ERROR_DEVICE_LOST';
    VK_ERROR_MEMORY_MAP_FAILED: Result := 'ERROR_MEMORY_MAP_FAILED';
    VK_ERROR_LAYER_NOT_PRESENT: Result := 'ERROR_LAYER_NOT_PRESENT';
    VK_ERROR_EXTENSION_NOT_PRESENT: Result := 'ERROR_EXTENSION_NOT_PRESENT';
    VK_ERROR_FEATURE_NOT_PRESENT: Result := 'ERROR_FEATURE_NOT_PRESENT';
    VK_ERROR_INCOMPATIBLE_DRIVER: Result := 'ERROR_INCOMPATIBLE_DRIVER';
    VK_ERROR_TOO_MANY_OBJECTS: Result := 'ERROR_TOO_MANY_OBJECTS';
    VK_ERROR_FORMAT_NOT_SUPPORTED: Result := 'ERROR_FORMAT_NOT_SUPPORTED';
    VK_ERROR_SURFACE_LOST_KHR: Result := 'ERROR_SURFACE_LOST_KHR';
    VK_ERROR_NATIVE_WINDOW_IN_USE_KHR: Result := 'ERROR_NATIVE_WINDOW_IN_USE_KHR';
    VK_SUBOPTIMAL_KHR: Result := 'SUBOPTIMAL_KHR';
    VK_ERROR_OUT_OF_DATE_KHR: Result := 'ERROR_OUT_OF_DATE_KHR';
    VK_ERROR_INCOMPATIBLE_DISPLAY_KHR: Result := 'ERROR_INCOMPATIBLE_DISPLAY_KHR';
    VK_ERROR_VALIDATION_FAILED_EXT: Result := 'ERROR_VALIDATION_FAILED_EXT';
    VK_ERROR_INVALID_SHADER_NV: Result := 'ERROR_INVALID_SHADER_NV';
    else Result := 'UNKNOWN_ERROR';
  end;
end;

initialization
begin
  Assign(LogFile, 'LabLog.txt');
  Rewrite(LogFile);
end;

finalization
begin
  Close(LogFile);
end;

end.
