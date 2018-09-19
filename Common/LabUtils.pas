unit LabUtils;

interface
{$modeswitch advancedrecords}

uses
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

  TLabStreamHelper = class
  private
    var _Stream: TStream;
    function GetSize: TVkInt64; inline;
    function GetPosition: TVkInt64; inline;
  public
    property Stream: TStream read _Stream;
    property Size: TVkInt64 read GetSize;
    property Position: TVkInt64 read GetPosition;
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

  TLabListString = specialize TLabList<AnsiString>;
  TLabListStringShared = specialize TLabSharedRef<TLabListString>;
  TLabListPointer = specialize TLabList<Pointer>;
  TLabListPointerShared = specialize TLabSharedRef<TLabListPointer>;

procedure LabZeroMem(const Ptr: Pointer; const Size: SizeInt);
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
    if CmpFunc(_Items[m], Item) then h := m - 1 else l := m + 1;
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
    if CmpFunc(_Items[m], Item) then h := m - 1 else l := m + 1;
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

//TLabStreamHelper BEGIN
function TLabStreamHelper.GetSize: TVkInt64;
begin
  Result := _Stream.Size;
end;

function TLabStreamHelper.GetPosition: TVkInt64;
begin
  Result := _Stream.Position;
end;

function TLabStreamHelper.ReadBuffer(const Buffer: Pointer; const Count: TVkInt64): TVkInt64;
begin
  Result := Stream.Read(Buffer^, Count);
end;

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

function TLabStreamHelper.WriteBuffer(const Buffer: Pointer; const Count: TVkInt64): TVkInt64;
begin
  Stream.WriteBuffer(Buffer^, Count);
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
  Result := ((Result shr 8) and $00ffffff) xor CRC32Table[(Result xor pb^[i]) and $ff];
  Result := Result xor $ffffffff;
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
