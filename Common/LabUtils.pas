unit LabUtils;

interface
{$modeswitch advancedrecords}

uses
  cmem,
  Classes,
  SysUtils,
  Vulkan,
  LabTypes,
  LabMath;

type
  generic TLabList<T> = class (TLabClass)
  private
    var _Items: array of T;
    var _Increment: Integer;
    var _ItemCount: Integer;
  public
    type TItemPtr = ^T;
    type TCmpFunc = function (const Item0, Item1: T): Boolean;
    type TCmpFuncObj = function (const Item0, Item1: T): Boolean of object;
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

  TLabDelegate = object
  public
    type TCallback = procedure (const Args: array of const) of Object;
  private
    var _Func: array of TCallback;
    function GetCallbackCount: TVkInt32; inline;
    class function CompareCallbacks(const a, b: TCallback): Boolean;
  public
    property CallbackCount: TVkInt32 read GetCallbackCount;
    procedure Add(const Callback: TCallback);
    procedure Add(const Callbacks: array of TCallback);
    procedure Remove(const Callback: TCallback);
    procedure Remove(const Callbacks: array of TCallback);
    procedure Call(const Args: array of const);
    procedure Clear;
  end;

  TLabStreamHelper = class
  private
    var _Stream: TStream;
    var _PosStack: array of TVkInt64;
    function GetSize: TVkInt64; inline;
    function GetPosition: TVkInt64; inline;
    function GetRemaining: TVkInt64; inline;
  public
    property Stream: TStream read _Stream;
    property Size: TVkInt64 read GetSize;
    property Position: TVkInt64 read GetPosition;
    property Remaining: TVkInt64 read GetRemaining;
    procedure PosPush;
    procedure PosPop;
    function EoF: Boolean; inline;
    function ReadBuffer(const Buffer: Pointer; const Count: TVkInt64): TVkInt64; inline;
    function ReadBool: Boolean; inline;
    function ReadUInt8: TVkUInt8; inline;
    function ReadUInt16: TVkUInt16; inline;
    function ReadUInt32: TVkUInt32; inline;
    function ReadInt8: TVkInt8; inline;
    function ReadInt16: TVkInt16; inline;
    function ReadInt32: TVkInt32; inline;
    function ReadInt64: TVkInt64; inline;
    function ReadFloat: TVkFloat; inline;
    function ReadDouble: TVkDouble; inline;
    function ReadColor: TLabColor; inline;
    function ReadStringA: AnsiString; inline;
    function ReadStringANT: AnsiString; inline;
    function ReadVec2: TLabVec2; inline;
    function ReadVec3: TLabVec3; inline;
    function ReadVec4: TLabVec4; inline;
    function ReadMat4x4: TLabMat; inline;
    function ReadMat4x3: TLabMat; inline;
    function ReadMat3x3: TLabMat; inline;
    function WriteBuffer(const Buffer: Pointer; const Count: TVkInt64): TVkInt64; inline;
    procedure WriteBool(const Value: Boolean); inline;
    procedure WriteUInt8(const Value: TVkUInt8); inline;
    procedure WriteUInt16(const Value: TVkUInt16); inline;
    procedure WriteUInt32(const Value: TVkUInt32); inline;
    procedure WriteInt8(const Value: TVkInt8); inline;
    procedure WriteInt16(const Value: TVkInt16); inline;
    procedure WriteInt32(const Value: TVkInt32); inline;
    procedure WriteInt64(const Value: TVkInt64); inline;
    procedure WriteFloat(const Value: TVkFloat); inline;
    procedure WriteDouble(const Value: TVkDouble); inline;
    procedure WriteColor(const Value: TLabColor); inline;
    procedure WriteStringARaw(const Value: AnsiString); inline;
    procedure WriteStringA(const Value: AnsiString); inline;
    procedure WriteStringANT(const Value: AnsiString); inline;
    procedure WriteVec2(const Value: TLabVec2); inline;
    procedure WriteVec3(const Value: TLabVec3); inline;
    procedure WriteVec4(const Value: TLabVec4); inline;
    procedure Skip(const Count: TVkInt64); inline;
    constructor Create(const AStream: TStream);
    destructor Destroy; override;
  end;

  TLabConstMemoryStream = class (TStream)
  private
    var _Memory: Pointer;
    var _Size: Int64;
    var _Position: Int64;
  protected
    function GetSize: Int64; override;
    function GetPosition: Int64; override;
  public
    function Read(var Buffer; Count: LongInt): LongInt; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    constructor Create(const Buffer: Pointer; const BufferSize: LongWord);
  end;

  generic TLabAlignedArray<T> = class (TLabClass)
  public
    type TItem = T;
    type PItem = ^TItem;
  private
    var _Data: PVkVoid;
    var _Alignment: TVkUInt32;
    var _Count: TVkUInt32;
    function GetBlockSize: TVkUInt32; inline;
    procedure SetCount(const Value: TVkUInt32); inline;
    function GetItem(const Index: TVkInt32): PItem; inline;
    function GetItemOffset(const Index: TVkInt32): TVkUInt32; inline;
    function GetDataSize: TVkUInt32; inline;
  public
    property Count: TVkUInt32 read _Count write SetCount;
    property Data: PVkVoid read _Data;
    property DataSize: TVkUInt32 read GetDataSize;
    property Items[const Index: TVkInt32]: PItem read GetItem; default;
    property ItemOffset[const Index: TVkInt32]: TVkUInt32 read GetItemOffset;
    constructor Create;
    constructor Create(const Alignment: TVkUInt32);
    destructor Destroy; override;
  end;

  TLabListString = specialize TLabList<AnsiString>;
  TLabListStringShared = specialize TLabSharedRef<TLabListString>;
  TLabListPointer = specialize TLabList<Pointer>;
  TLabListPointerShared = specialize TLabSharedRef<TLabListPointer>;

procedure LabZeroMem(const Ptr: Pointer; const Size: SizeInt);
function LabIsPOT(const v: TVkUInt32): Boolean; inline;
function LabIntLog2(const v: TVkUInt32): TVkUInt32; inline;
function LabMakePOT(const v: TVkUInt32): TVkUInt32; inline;
function LabCheckGlobalExtensionPresent(const ExtensionName: AnsiString): Boolean;
function LabCheckDeviceExtensionPresent(const PhysicalDevice: TVkPhysicalDevice; const ExtensionName: String): Boolean;
function LabCheckLayerAvailable(const LayerName: AnsiString): Boolean;
procedure LabLog(const Msg: AnsiString; const Offset: Integer = 0);
procedure LabLogOffset(const Offset: Integer);
procedure LabAssertVkError(const State: TVkResult);
function LabLogVkError(const State: TVkResult): TVkResult;
function LabVkErrorString(const State: TVkResult): String;
function LabVkValidHandle(const Handle: TVkDispatchableHandle): Boolean; inline;
procedure LabProfileStart(const Name: AnsiString);
procedure LabProfileStop;
function LabEncodeURL(const URL: String): String;
function LabDecodeURL(const URL: String): String;
function LabStrExplode(const Str: AnsiString; const Separator: AnsiString): TLabStrArrA;
function LabStrReplace(const Str, PatternOld, PatternNew: AnsiString): AnsiString;
function LabCRC32(const CRC: TVkUInt32; const Value: Pointer; const Count: TVkInt32): TVkUInt32;
function LabCRC64(const CRC: TVkUInt64; const Value: Pointer; const Count: TVkInt32): TVkUInt64;
function LabPtrToOrd(const Ptr: Pointer): PtrUInt; inline;
function LabOrdToPtr(const Ptr: PtrUInt): Pointer; inline;
function LabAlloc(const Size: TVkUInt32; const Align: TVkUInt32): PVkVoid; inline;
procedure LabFree(var Mem: PVkVoid); inline;
function LabRandomPi: TVkFloat; inline;
function LabRandom2Pi: TVkFloat; inline;
function LabRandomCirclePoint: TLabVec2; inline;
function LabRandomSpherePoint: TLabVec3; inline;

const LabFormatFeatures: array[0..23] of TVkFormatFeatureFlagBits = (
  VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT,
  VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT,
  VK_FORMAT_FEATURE_STORAGE_IMAGE_ATOMIC_BIT,
  VK_FORMAT_FEATURE_UNIFORM_TEXEL_BUFFER_BIT,
  VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_BIT,
  VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_ATOMIC_BIT,
  VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT,
  VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT,
  VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT,
  VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT,
  VK_FORMAT_FEATURE_BLIT_SRC_BIT,
  VK_FORMAT_FEATURE_BLIT_DST_BIT,
  VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT,
  VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_IMG,
  VK_FORMAT_FEATURE_TRANSFER_SRC_BIT,
  VK_FORMAT_FEATURE_TRANSFER_DST_BIT,
  VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_MINMAX_BIT_EXT,
  VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT,
  VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT,
  VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT,
  VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT,
  VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT,
  VK_FORMAT_FEATURE_DISJOINT_BIT,
  VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT
);

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
  var l, h, m: Integer;
begin
  l := 0;
  h := _ItemCount - 1;
  while l <= h do
  begin
    m := (l + h) shr 1;
    if (not CmpFunc(_Items[m], Item))
    and (not CmpFunc(Item, _Items[m])) then
    begin
      Exit(m);
    end
    else if CmpFunc(_Items[m], Item) then
    begin
      h := m - 1
    end
    else
    begin
      l := m + 1;
    end;
  end;
  if (l < _ItemCount)
  and (not CmpFunc(_Items[l], Item))
  and (not CmpFunc(Item, _Items[l])) then
  Exit(l) else Exit(-1);
end;

function TLabList.Search(const CmpFunc: TCmpFuncObj; const Item: T): Integer;
  var l, h, m: Integer;
begin
  l := 0;
  h := _ItemCount - 1;
  while l <= h do
  begin
    m := (l + h) shr 1;
    if (not CmpFunc(_Items[m], Item))
    and (not CmpFunc(Item, _Items[m])) then
    begin
      Exit(m);
    end
    else if CmpFunc(_Items[m], Item) then
    begin
      h := m - 1
    end
    else
    begin
      l := m + 1;
    end;
  end;
  if (l < _ItemCount)
  and (not CmpFunc(_Items[l], Item))
  and (not CmpFunc(Item, _Items[l])) then
  Exit(l) else Exit(-1);
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
    while CmpFunc(pivot, _Items[i]) do i := i + 1;
    while CmpFunc(_Items[j], pivot) do j := j - 1;
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
    while CmpFunc(pivot, _Items[i]) do i := i + 1;
    while CmpFunc(_Items[j], pivot) do j := j - 1;
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

//TLabDelegate BEGIN
function TLabDelegate.GetCallbackCount: TVkInt32;
begin
  Result := Length(_Func);
end;

class function TLabDelegate.CompareCallbacks(const a, b: TCallback): Boolean;
  type TDoublePtr = array[0..1] of Pointer;
  var ptr_a: TDoublePtr absolute a;
  var ptr_b: TDoublePtr absolute b;
begin
  Result := (ptr_a[0] = ptr_b[0]) and (ptr_a[1] = ptr_b[1]);
end;

procedure TLabDelegate.Add(const Callback: TCallback);
  var i: TVkInt32;
begin
  for i := 0 to High(_Func) do
  if CompareCallbacks(_Func[i], Callback) then Exit;
  SetLength(_Func, Length(_Func) + 1);
  _Func[High(_Func)] := Callback;
end;

procedure TLabDelegate.Add(const Callbacks: array of TCallback);
  var i: TVkInt32;
begin
  for i := 0 to High(Callbacks) do Add(Callbacks[i]);
end;

procedure TLabDelegate.Remove(const Callback: TCallback);
  var i, j: TVkInt32;
begin
  for i := 0 to High(_Func) do
  if CompareCallbacks(_Func[i], Callback) then
  begin
    for j := i to High(_Func) - 1 do
    begin
      _Func[j] := _Func[j + 1];
    end;
    SetLength(_Func, Length(_Func) - 1);
    Exit;
  end;
end;

procedure TLabDelegate.Remove(const Callbacks: array of TCallback);
  var i: TVkInt32;
begin
  for i := 0 to High(Callbacks) do Remove(Callbacks[i]);
end;

procedure TLabDelegate.Call(const Args: array of const);
  var i: TVkInt32;
begin
  for i := 0 to High(_Func) do _Func[i](Args);
end;

procedure TLabDelegate.Clear;
begin
  SetLength(_Func, 0);
end;
//TLabDelegate END

//TLabStreamHelper BEGIN
function TLabStreamHelper.GetSize: TVkInt64;
begin
  Result := _Stream.Size;
end;

function TLabStreamHelper.GetPosition: TVkInt64;
begin
  Result := _Stream.Position;
end;

function TLabStreamHelper.GetRemaining: TVkInt64;
begin
  Result := _Stream.Size - _Stream.Position;
end;

procedure TLabStreamHelper.PosPush;
begin
  SetLength(_PosStack, Length(_PosStack) + 1);
  _PosStack[High(_PosStack)] := _Stream.Position;
end;

procedure TLabStreamHelper.PosPop;
begin
  if Length(_PosStack) <= 0 then Exit;
  _Stream.Seek(_PosStack[High(_PosStack)], soFromBeginning);
  SetLength(_PosStack, Length(_PosStack) - 1);
end;

function TLabStreamHelper.EoF: Boolean;
begin
  Result := _Stream.Position >= _Stream.Size;
end;

function TLabStreamHelper.ReadBuffer(const Buffer: Pointer; const Count: TVkInt64): TVkInt64;
begin
  Result := Stream.Read(Buffer^, Count);
end;

{$Hints off}
function TLabStreamHelper.ReadBool: Boolean;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadUInt8: TVkUInt8;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadUInt16: TVkUInt16;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadUInt32: TVkUInt32;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadInt8: TVkInt8;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadInt16: TVkInt16;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadInt32: TVkInt32;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadInt64: TVkInt64;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadFloat: TVkFloat;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadDouble: TVkDouble;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadColor: TLabColor;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadStringA: AnsiString;
  var l: TVkUInt32;
begin
  l := ReadUInt32;
  SetLength(Result, l);
  ReadBuffer(@Result[1], l);
end;

function TLabStreamHelper.ReadStringANT: AnsiString;
  var b: TVkUInt8;
begin
  Result := '';
  b := ReadUInt8;
  while b <> 0 do
  begin
    Result += AnsiChar(b);
    b := ReadUInt8;
  end;
end;

function TLabStreamHelper.ReadVec2: TLabVec2;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadVec3: TLabVec3;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadVec4: TLabVec4;
begin
  Stream.Read(Result, SizeOf(Result));
end;

function TLabStreamHelper.ReadMat4x4: TLabMat;
begin
  Stream.Read(Result, SizeOf(Result));
end;

{$Warnings off}
function TLabStreamHelper.ReadMat4x3: TLabMat;
  var m4x3: array[0..3, 0..2] of TVkFloat;
begin
  ReadBuffer(@m4x3, SizeOf(m4x3));
  Result.SetValue(
    m4x3[0, 0], m4x3[1, 0], m4x3[2, 0], m4x3[3, 0],
    m4x3[0, 1], m4x3[1, 1], m4x3[2, 1], m4x3[3, 1],
    m4x3[0, 2], m4x3[1, 2], m4x3[2, 2], m4x3[3, 2],
    0, 0, 0, 1
  );
end;
{$Warnings on}

{$Warnings off}
function TLabStreamHelper.ReadMat3x3: TLabMat;
  var m3x3: array[0..2, 0..2] of TVkFloat;
begin
  ReadBuffer(@m3x3, SizeOf(m3x3));
  Result.SetValue(
    m3x3[0, 0], m3x3[1, 0], m3x3[2, 0], 0,
    m3x3[0, 1], m3x3[1, 1], m3x3[2, 1], 0,
    m3x3[0, 2], m3x3[1, 2], m3x3[2, 2], 0,
    0, 0, 0, 1
  );
end;
{$Warnings on}
{$Hints on}

function TLabStreamHelper.WriteBuffer(const Buffer: Pointer; const Count: TVkInt64): TVkInt64;
begin
  Result := Stream.Write(Buffer^, Count);
end;

procedure TLabStreamHelper.WriteBool(const Value: Boolean);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteUInt8(const Value: TVkUInt8);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteUInt16(const Value: TVkUInt16);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteUInt32(const Value: TVkUInt32);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteInt8(const Value: TVkInt8);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteInt16(const Value: TVkInt16);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteInt32(const Value: TVkInt32);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteInt64(const Value: TVkInt64);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteFloat(const Value: TVkFloat);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteDouble(const Value: TVkDouble);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteColor(const Value: TLabColor);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteStringARaw(const Value: AnsiString);
begin
  WriteBuffer(@Value[1], Length(Value));
end;

procedure TLabStreamHelper.WriteStringA(const Value: AnsiString);
begin
  WriteUInt32(Length(Value));
  WriteBuffer(@Value[1], Length(Value));
end;

procedure TLabStreamHelper.WriteStringANT(const Value: AnsiString);
begin
  WriteBuffer(@Value[1], Length(Value));
  WriteUInt8(0);
end;

procedure TLabStreamHelper.WriteVec2(const Value: TLabVec2);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteVec3(const Value: TLabVec3);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.WriteVec4(const Value: TLabVec4);
begin
  Stream.Write(Value, SizeOf(Value));
end;

procedure TLabStreamHelper.Skip(const Count: TVkInt64);
begin
  Stream.Seek(Count, soFromCurrent);
end;

constructor TLabStreamHelper.Create(const AStream: TStream);
begin
  _Stream := AStream;
end;

destructor TLabStreamHelper.Destroy;
begin
  inherited Destroy;
end;
//TLabStreamHelper END

//TLabConstMemoryStream BEGIN
function TLabConstMemoryStream.GetSize: Int64;
begin
  Result := _Size;
end;

function TLabConstMemoryStream.GetPosition: Int64;
begin
  Result := _Position;
end;

function TLabConstMemoryStream.Read(var Buffer; Count: LongInt): LongInt;
begin
  Result := 0;
  if (_Size > 0) and (_Position < _Size) and (_Position >= 0) then
  begin
    Result := Count;
    if (Result > (_Size - _Position)) then
    begin
      Result := (_Size - _Position);
    end;
    Move((_Memory + _Position)^, Buffer, Result);
    _Position += Result;
  end;
end;

function TLabConstMemoryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  case Word(Origin) of
    soFromBeginning: _Position := Offset;
    soFromEnd: _Position := _Size + Offset;
    soFromCurrent: _Position := _Position + Offset;
  end;
  Result := _Position;
end;

constructor TLabConstMemoryStream.Create(const Buffer: Pointer; const BufferSize: LongWord);
begin
  inherited Create;
  _Memory := Buffer;
  _Size := BufferSize;
  _Position := 0;
end;
//TLabConstMemoryStream END

//TLabAlignedArray BEGIN
function TLabAlignedArray.GetBlockSize: TVkUInt32;
begin
  Result := (SizeOf(TItem) + _Alignment - 1) and (not(_Alignment - 1));
end;

procedure TLabAlignedArray.SetCount(const Value: TVkUInt32);
begin
  if Value = _Count then Exit;
  if Assigned(_Data) then LabFree(_Data);
  _Count := Value;
  _Data := LabAlloc(GetDataSize, _Alignment);
end;

function TLabAlignedArray.GetItem(const Index: TVkInt32): PItem;
begin
  Result := PItem(_Data + (Index * GetBlockSize));
end;

function TLabAlignedArray.GetItemOffset(const Index: TVkInt32): TVkUInt32;
begin
  Result := TVkUInt32(Index) * GetBlockSize;
end;

function TLabAlignedArray.GetDataSize: TVkUInt32;
begin
  Result := GetBlockSize * _Count;
end;

constructor TLabAlignedArray.Create;
begin
  inherited Create;
  Create(SizeOf(TItem));
end;

constructor TLabAlignedArray.Create(const Alignment: TVkUInt32);
begin
  inherited Create;
  _Alignment := Alignment;
  _Count := 0;
  _Data := nil;
end;

destructor TLabAlignedArray.Destroy;
begin
  if Assigned(_Data) then LabFree(_Data);
  inherited Destroy;
end;
//TLabAlignedArray END

procedure LabZeroMem(const Ptr: Pointer; const Size: SizeInt);
begin
  if Ptr = nil then Exit;
  {$Warnings off}
  FillChar(Ptr^, Size, 0);
  {$Warnings on}
end;

function LabIsPOT(const v: TVkUInt32): Boolean;
begin
  Result := (v and (v - 1)) = 0;
end;

function LabIntLog2(const v: TVkUInt32): TVkUInt32;
  var v1, s: LongWord;
begin
  Result := TVkUInt8(v > $ffff) shl 4; v1 := v shr Result;
  s := TVkUInt8(v1 > $ff) shl 3; v1 := v1 shr s; Result := Result or s;
  s := TVkUInt8(v1 > $f) shl 2; v1 := v1 shr s; Result := Result or s;
  s := TVkUInt8(v1 > $3) shl 1; v1 := v1 shr s; Result := Result or s;
  Result := Result or (v1 shr 1);
end;

function LabMakePOT(const v: TVkUInt32): TVkUInt32;
begin
  Result := v - 1;
  Result := Result or (Result shr 1);
  Result := Result or (Result shr 2);
  Result := Result or (Result shr 4);
  Result := Result or (Result shr 8);
  Result := Result or (Result shr 16);
  Inc(Result);
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

function LabCheckLayerAvailable(const LayerName: AnsiString): Boolean;
  var layer_count: TVkUInt32;
  var layer_properties: array of TVkLayerProperties;
  var i: TVkInt32;
  var layer_name_lc: AnsiString;
begin
  vk.EnumerateInstanceLayerProperties(@layer_count, nil);
  if layer_count > 0 then
  begin
    layer_name_lc := LowerCase(LayerName);
    SetLength(layer_properties, layer_count);
    LabAssertVkError(vk.EnumerateInstanceLayerProperties(@layer_count, @layer_properties[0]));
    for i := 0 to layer_count - 1 do
    if LowerCase(AnsiString(layer_properties[i].layerName)) = layer_name_lc then
    begin
      Exit(True);
    end;
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

function LabEncodeURL(const URL: String): String;
  var i: integer;
begin
  Result := '';
  for i := 1 to Length(URL) do
  begin
    if not (URL[i] in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '~', '.', ':', '/']) then
    begin
      Result += '%' + IntToHex(Ord(URL[i]), 2);
    end
    else
    begin
      Result += URL[i];
    end;
  end;
end;

function LabDecodeURL(const URL: String): String;
  var i, len: integer;
begin
  Result := '';
  len := Length(URL);
  i := 1;
  while i <= len do
  begin
    if (URL[i] = '%') and (i + 1 < len) then
    begin
      Result += Chr(StrToIntDef('$' + URL[i + 1] + URL[i + 2], 32));
      Inc(i, 2);
    end
    else Result += URL[i];
    Inc(i);
  end;
end;

function LabStrExplode(const Str: AnsiString; const Separator: AnsiString): TLabStrArrA;
  var i, j: TVkInt32;
  var CurElement: TVkInt32;
  var PrevParamIndex: TVkInt32;
  var b: Boolean;
begin
  if Length(Separator) < 1 then
  begin
    SetLength(Result, 1);
    Result[0] := Str;
    Exit;
  end;
  Result := nil;
  SetLength(Result, Length(Str) + 1);
  CurElement := 0;
  PrevParamIndex := 1;
  for i := 1 to Length(Str) do
  begin
    b := True;
    for j := 0 to Length(Separator) - 1 do
    begin
      if Separator[j + 1] <> Str[i + j] then
      begin
        b := False;
        Break;
      end;
    end;
    if b then
    begin
      SetLength(Result[CurElement], i - PrevParamIndex);
      Move(Str[PrevParamIndex], Result[CurElement][1], i - PrevParamIndex);
      PrevParamIndex := i + Length(Separator);
      Inc(CurElement);
    end;
  end;
  if Length(Str) >= PrevParamIndex then
  begin
    SetLength(Result[CurElement], Length(Str) - PrevParamIndex + 1);
    Move(Str[PrevParamIndex], Result[CurElement][1], Length(Str) - PrevParamIndex + 1);
    Inc(CurElement);
  end
  else
  begin
    Result[CurElement] := '';
    Inc(CurElement);
  end;
  SetLength(Result, CurElement);
end;

function LabStrReplace(const Str, PatternOld, PatternNew: AnsiString): AnsiString;
  var StrArr: TLabStrArrA;
  var i, n: TVkInt32;
begin
  if (Length(PatternOld) > 0) and (Length(Str) > 0) then
  begin
    StrArr := LabStrExplode(Str, PatternOld);
    SetLength(Result, Length(Str) + Length(PatternNew) * Length(StrArr));
    n := 1;
    for i := 0 to High(StrArr) - 1 do
    begin
      Move(StrArr[i][1], Result[n], Length(StrArr[i]));
      Inc(n, Length(StrArr[i]));
      Move(PatternNew[1], Result[n], Length(PatternNew));
      Inc(n, Length(PatternNew));
    end;
    i := High(StrArr);
    Move(StrArr[i][1], Result[n], Length(StrArr[i]));
    Inc(n, Length(StrArr[i]));
    SetLength(Result, n - 1);
  end
  else
  Result := Str;
end;

function LabCRC32(
  const CRC: TVkUInt32;
  const Value: Pointer;
  const Count: TVkInt32
): TVkUInt32;
  const CRC32Table: array[0..255] of TVkUInt32 = (
    $00000000, $77073096, $ee0e612c, $990951ba, $076dc419, $706af48f, $e963a535,
    $9e6495a3, $0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd,
    $e7b82d07, $90bf1d91, $1db71064, $6ab020f2, $f3b97148, $84be41de, $1adad47d,
    $6ddde4eb, $f4d4b551, $83d385c7, $136c9856, $646ba8c0, $fd62f97a, $8a65c9ec,
    $14015c4f, $63066cd9, $fa0f3d63, $8d080df5, $3b6e20c8, $4c69105e, $d56041e4,
    $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b, $35b5a8fa, $42b2986c,
    $dbbbc9d6, $acbcf940, $32d86ce3, $45df5c75, $dcd60dcf, $abd13d59, $26d930ac,
    $51de003a, $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599, $b8bda50f,
    $2802b89e, $5f058808, $c60cd9b2, $b10be924, $2f6f7c87, $58684c11, $c1611dab,
    $b6662d3d, $76dc4190, $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f,
    $9fbfe4a5, $e8b8d433, $7807c9a2, $0f00f934, $9609a88e, $e10e9818, $7f6a0dbb,
    $086d3d2d, $91646c97, $e6635c01, $6b6b51f4, $1c6c6162, $856530d8, $f262004e,
    $6c0695ed, $1b01a57b, $8208f4c1, $f50fc457, $65b0d9c6, $12b7e950, $8bbeb8ea,
    $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3, $fbd44c65, $4db26158, $3ab551ce,
    $a3bc0074, $d4bb30e2, $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb, $4369e96a,
    $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5, $aa0a4c5f, $dd0d7cc9,
    $5005713c, $270241aa, $be0b1010, $c90c2086, $5768b525, $206f85b3, $b966d409,
    $ce61e49f, $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17, $2eb40d81,
    $b7bd5c3b, $c0ba6cad, $edb88320, $9abfb3b6, $03b6e20c, $74b1d29a, $ead54739,
    $9dd277af, $04db2615, $73dc1683, $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8,
    $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1, $f00f9344, $8708a3d2, $1e01f268,
    $6906c2fe, $f762575d, $806567cb, $196c3671, $6e6b06e7, $fed41b76, $89d32be0,
    $10da7a5a, $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5, $d6d6a3e8,
    $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b,
    $d80d2bda, $af0a1b4c, $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef,
    $4669be79, $cb61b38c, $bc66831a, $256fd2a0, $5268e236, $cc0c7795, $bb0b4703,
    $220216b9, $5505262f, $c5ba3bbe, $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7,
    $b5d0cf31, $2cd99e8b, $5bdeae1d, $9b64c2b0, $ec63f226, $756aa39c, $026d930a,
    $9c0906a9, $eb0e363f, $72076785, $05005713, $95bf4a82, $e2b87a14, $7bb12bae,
    $0cb61b38, $92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21, $86d3d2d4, $f1d4e242,
    $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1, $18b74777, $88085ae6,
    $ff0f6a70, $66063bca, $11010b5c, $8f659eff, $f862ae69, $616bffd3, $166ccf45,
    $a00ae278, $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7, $4969474d,
    $3e6e77db, $aed16a4a, $d9d65adc, $40df0b66, $37d83bf0, $a9bcae53, $debb9ec5,
    $47b2cf7f, $30b5ffe9, $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605,
    $cdd70693, $54de5729, $23d967bf, $b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94,
    $b40bbe37, $c30c8ea1, $5a05df1b, $2d02ef8d
  );
  type TUInt8Arr = array[Word] of TVkUInt8;
  type PUInt8Arr = ^TUInt8Arr;
  var i: TVkInt32;
  var pb: PUInt8Arr absolute Value;
begin
  Result := CRC xor $ffffffff;
  for i := 0 to Count - 1 do
  begin
    Result := ((Result shr 8) and $00ffffff) xor CRC32Table[(Result xor pb^[i]) and $ff];
  end;
  Result := Result xor $ffffffff;
end;

{$hints off}

function LabCRC64(
  const CRC: TVkUInt64;
  const Value: Pointer;
  const Count: TVkInt32
): TVkUInt64;
  const CRC64Table: array[0..255] of TVkUInt64 = (
    QWord($0000000000000000), QWord($7AD870C830358979), QWord($F5B0E190606B12F2), QWord($8F689158505E9B8B), QWord($C038E5739841B68F), QWord($BAE095BBA8743FF6),
    QWord($358804E3F82AA47D), QWord($4F50742BC81F2D04), QWord($AB28ECB46814FE75), QWord($D1F09C7C5821770C), QWord($5E980D24087FEC87), QWord($24407DEC384A65FE),
    QWord($6B1009C7F05548FA), QWord($11C8790FC060C183), QWord($9EA0E857903E5A08), QWord($E478989FA00BD371), QWord($7D08FF3B88BE6F81), QWord($07D08FF3B88BE6F8),
    QWord($88B81EABE8D57D73), QWord($F2606E63D8E0F40A), QWord($BD301A4810FFD90E), QWord($C7E86A8020CA5077), QWord($4880FBD87094CBFC), QWord($32588B1040A14285),
    QWord($D620138FE0AA91F4), QWord($ACF86347D09F188D), QWord($2390F21F80C18306), QWord($594882D7B0F40A7F), QWord($1618F6FC78EB277B), QWord($6CC0863448DEAE02),
    QWord($E3A8176C18803589), QWord($997067A428B5BCF0), QWord($FA11FE77117CDF02), QWord($80C98EBF2149567B), QWord($0FA11FE77117CDF0), QWord($75796F2F41224489),
    QWord($3A291B04893D698D), QWord($40F16BCCB908E0F4), QWord($CF99FA94E9567B7F), QWord($B5418A5CD963F206), QWord($513912C379682177), QWord($2BE1620B495DA80E),
    QWord($A489F35319033385), QWord($DE51839B2936BAFC), QWord($9101F7B0E12997F8), QWord($EBD98778D11C1E81), QWord($64B116208142850A), QWord($1E6966E8B1770C73),
    QWord($8719014C99C2B083), QWord($FDC17184A9F739FA), QWord($72A9E0DCF9A9A271), QWord($08719014C99C2B08), QWord($4721E43F0183060C), QWord($3DF994F731B68F75),
    QWord($B29105AF61E814FE), QWord($C849756751DD9D87), QWord($2C31EDF8F1D64EF6), QWord($56E99D30C1E3C78F), QWord($D9810C6891BD5C04), QWord($A3597CA0A188D57D),
    QWord($EC09088B6997F879), QWord($96D1784359A27100), QWord($19B9E91B09FCEA8B), QWord($636199D339C963F2), QWord($DF7ADABD7A6E2D6F), QWord($A5A2AA754A5BA416),
    QWord($2ACA3B2D1A053F9D), QWord($50124BE52A30B6E4), QWord($1F423FCEE22F9BE0), QWord($659A4F06D21A1299), QWord($EAF2DE5E82448912), QWord($902AAE96B271006B),
    QWord($74523609127AD31A), QWord($0E8A46C1224F5A63), QWord($81E2D7997211C1E8), QWord($FB3AA75142244891), QWord($B46AD37A8A3B6595), QWord($CEB2A3B2BA0EECEC),
    QWord($41DA32EAEA507767), QWord($3B024222DA65FE1E), QWord($A2722586F2D042EE), QWord($D8AA554EC2E5CB97), QWord($57C2C41692BB501C), QWord($2D1AB4DEA28ED965),
    QWord($624AC0F56A91F461), QWord($1892B03D5AA47D18), QWord($97FA21650AFAE693), QWord($ED2251AD3ACF6FEA), QWord($095AC9329AC4BC9B), QWord($7382B9FAAAF135E2),
    QWord($FCEA28A2FAAFAE69), QWord($8632586ACA9A2710), QWord($C9622C4102850A14), QWord($B3BA5C8932B0836D), QWord($3CD2CDD162EE18E6), QWord($460ABD1952DB919F),
    QWord($256B24CA6B12F26D), QWord($5FB354025B277B14), QWord($D0DBC55A0B79E09F), QWord($AA03B5923B4C69E6), QWord($E553C1B9F35344E2), QWord($9F8BB171C366CD9B),
    QWord($10E3202993385610), QWord($6A3B50E1A30DDF69), QWord($8E43C87E03060C18), QWord($F49BB8B633338561), QWord($7BF329EE636D1EEA), QWord($012B592653589793),
    QWord($4E7B2D0D9B47BA97), QWord($34A35DC5AB7233EE), QWord($BBCBCC9DFB2CA865), QWord($C113BC55CB19211C), QWord($5863DBF1E3AC9DEC), QWord($22BBAB39D3991495),
    QWord($ADD33A6183C78F1E), QWord($D70B4AA9B3F20667), QWord($985B3E827BED2B63), QWord($E2834E4A4BD8A21A), QWord($6DEBDF121B863991), QWord($1733AFDA2BB3B0E8),
    QWord($F34B37458BB86399), QWord($8993478DBB8DEAE0), QWord($06FBD6D5EBD3716B), QWord($7C23A61DDBE6F812), QWord($3373D23613F9D516), QWord($49ABA2FE23CC5C6F),
    QWord($C6C333A67392C7E4), QWord($BC1B436E43A74E9D), QWord($95AC9329AC4BC9B5), QWord($EF74E3E19C7E40CC), QWord($601C72B9CC20DB47), QWord($1AC40271FC15523E),
    QWord($5594765A340A7F3A), QWord($2F4C0692043FF643), QWord($A02497CA54616DC8), QWord($DAFCE7026454E4B1), QWord($3E847F9DC45F37C0), QWord($445C0F55F46ABEB9),
    QWord($CB349E0DA4342532), QWord($B1ECEEC59401AC4B), QWord($FEBC9AEE5C1E814F), QWord($8464EA266C2B0836), QWord($0B0C7B7E3C7593BD), QWord($71D40BB60C401AC4),
    QWord($E8A46C1224F5A634), QWord($927C1CDA14C02F4D), QWord($1D148D82449EB4C6), QWord($67CCFD4A74AB3DBF), QWord($289C8961BCB410BB), QWord($5244F9A98C8199C2),
    QWord($DD2C68F1DCDF0249), QWord($A7F41839ECEA8B30), QWord($438C80A64CE15841), QWord($3954F06E7CD4D138), QWord($B63C61362C8A4AB3), QWord($CCE411FE1CBFC3CA),
    QWord($83B465D5D4A0EECE), QWord($F96C151DE49567B7), QWord($76048445B4CBFC3C), QWord($0CDCF48D84FE7545), QWord($6FBD6D5EBD3716B7), QWord($15651D968D029FCE),
    QWord($9A0D8CCEDD5C0445), QWord($E0D5FC06ED698D3C), QWord($AF85882D2576A038), QWord($D55DF8E515432941), QWord($5A3569BD451DB2CA), QWord($20ED197575283BB3),
    QWord($C49581EAD523E8C2), QWord($BE4DF122E51661BB), QWord($3125607AB548FA30), QWord($4BFD10B2857D7349), QWord($04AD64994D625E4D), QWord($7E7514517D57D734),
    QWord($F11D85092D094CBF), QWord($8BC5F5C11D3CC5C6), QWord($12B5926535897936), QWord($686DE2AD05BCF04F), QWord($E70573F555E26BC4), QWord($9DDD033D65D7E2BD),
    QWord($D28D7716ADC8CFB9), QWord($A85507DE9DFD46C0), QWord($273D9686CDA3DD4B), QWord($5DE5E64EFD965432), QWord($B99D7ED15D9D8743), QWord($C3450E196DA80E3A),
    QWord($4C2D9F413DF695B1), QWord($36F5EF890DC31CC8), QWord($79A59BA2C5DC31CC), QWord($037DEB6AF5E9B8B5), QWord($8C157A32A5B7233E), QWord($F6CD0AFA9582AA47),
    QWord($4AD64994D625E4DA), QWord($300E395CE6106DA3), QWord($BF66A804B64EF628), QWord($C5BED8CC867B7F51), QWord($8AEEACE74E645255), QWord($F036DC2F7E51DB2C),
    QWord($7F5E4D772E0F40A7), QWord($05863DBF1E3AC9DE), QWord($E1FEA520BE311AAF), QWord($9B26D5E88E0493D6), QWord($144E44B0DE5A085D), QWord($6E963478EE6F8124),
    QWord($21C640532670AC20), QWord($5B1E309B16452559), QWord($D476A1C3461BBED2), QWord($AEAED10B762E37AB), QWord($37DEB6AF5E9B8B5B), QWord($4D06C6676EAE0222),
    QWord($C26E573F3EF099A9), QWord($B8B627F70EC510D0), QWord($F7E653DCC6DA3DD4), QWord($8D3E2314F6EFB4AD), QWord($0256B24CA6B12F26), QWord($788EC2849684A65F),
    QWord($9CF65A1B368F752E), QWord($E62E2AD306BAFC57), QWord($6946BB8B56E467DC), QWord($139ECB4366D1EEA5), QWord($5CCEBF68AECEC3A1), QWord($2616CFA09EFB4AD8),
    QWord($A97E5EF8CEA5D153), QWord($D3A62E30FE90582A), QWord($B0C7B7E3C7593BD8), QWord($CA1FC72BF76CB2A1), QWord($45775673A732292A), QWord($3FAF26BB9707A053),
    QWord($70FF52905F188D57), QWord($0A2722586F2D042E), QWord($854FB3003F739FA5), QWord($FF97C3C80F4616DC), QWord($1BEF5B57AF4DC5AD), QWord($61372B9F9F784CD4),
    QWord($EE5FBAC7CF26D75F), QWord($9487CA0FFF135E26), QWord($DBD7BE24370C7322), QWord($A10FCEEC0739FA5B), QWord($2E675FB4576761D0), QWord($54BF2F7C6752E8A9),
    QWord($CDCF48D84FE75459), QWord($B71738107FD2DD20), QWord($387FA9482F8C46AB), QWord($42A7D9801FB9CFD2), QWord($0DF7ADABD7A6E2D6), QWord($772FDD63E7936BAF),
    QWord($F8474C3BB7CDF024), QWord($829F3CF387F8795D), QWord($66E7A46C27F3AA2C), QWord($1C3FD4A417C62355), QWord($935745FC4798B8DE), QWord($E98F353477AD31A7),
    QWord($A6DF411FBFB21CA3), QWord($DC0731D78F8795DA), QWord($536FA08FDFD90E51), QWord($29B7D047EFEC8728)
  );
  type TUInt8Arr = array[Word] of TVkUInt8;
  type PUInt8Arr = ^TUInt8Arr;
  var i: TVkInt32;
  var pb: PUInt8Arr absolute Value;
begin
  Result := CRC xor QWord($ffffffffffffffff);
  for i := 0 to Count - 1 do
  begin
    Result := ((Result shr 8) and QWord($00ffffffffffffff)) xor CRC64Table[(Result xor pb^[i]) and $ff];
  end;
  Result := Result xor QWord($ffffffffffffffff);
end;

function LabPtrToOrd(const Ptr: Pointer): PtrUInt;
begin
  Result := PtrUInt(Ptr);
end;

function LabOrdToPtr(const Ptr: PtrUInt): Pointer;
begin
  Result := Pointer(Ptr);
end;
{$hints on}

function LabAlloc(const Size: TVkUInt32; const Align: TVkUInt32): PVkVoid;
  type TPtrArr = array[-1..0] of PVkVoid;
  type PPtrArr = ^TPtrArr;
  var offset: TVkUInt32;
  var ptr: PVkVoid;
begin
  offset := Align - 1 + SizeOf(PVkVoid);
  ptr := cmem.Malloc(Size + offset);
  if not Assigned(ptr) then Exit(nil);
  Result := LabOrdToPtr((LabPtrToOrd(ptr) + offset) and (not(Align - 1)));
  PPtrArr(@Result)^[-1] := ptr;
end;

procedure LabFree(var Mem: PVkVoid);
  type TPtrArr = array[-1..0] of PVkVoid;
  type PPtrArr = ^TPtrArr;
begin
  cmem.Free(PPtrArr(@Mem)^[-1]);
  Mem := nil;
end;

function LabRandomPi: TVkFloat;
begin
  Result := Random(Round(LabPi * 1000)) / 1000;
end;

function LabRandom2Pi: TVkFloat;
begin
  Result := Random(Round(LabTwoPi * 1000)) / 1000;
end;

{$Push}
{$Hints off}
function LabRandomCirclePoint: TLabVec2;
  var a: TVkFloat;
begin
  a := LabRandom2Pi;
  LabSinCos(a, Result.y, Result.x);
end;
{$Pop}

{$Push}
{$Hints off}
function LabRandomSpherePoint: TLabVec3;
  var a1, a2, s1, s2, c1, c2: TVkFloat;
begin
  a1 := LabRandom2Pi;
  a2 := LabRandom2Pi;
  LabSinCos(a1, s1, c1);
  LabSinCos(a2, s2, c2);
  Result.SetValue(c1 * c2, s2, s1 * c2);
end;
{$Pop}

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
