unit LabTypes;

{$modeswitch advancedrecords}

interface

uses
  Vulkan;

type
  TLabProc = procedure;
  TLabProcObj = procedure of Object;

  TLabColor = record
    r, g, b, a: Byte;
  end;
  PLabColor = ^TLabColor;
  TLabColorArr = array[Word] of TLabColor;
  PLabColorArr = ^TLabColorArr;

  generic TLabSharedRef<T> = record
  public
    type TPtr = T;
    type TSelf = specialize TLabSharedRef<T>;
  private
    var _Ptr: IInterface;
    function GetPtr: T; inline;
    procedure SetPtr(const Value: T); inline;
  public
    property Ptr: T read GetPtr write SetPtr;
    function IsValid: Boolean; inline;
    class operator := (const Value: T): TSelf; inline;
    class operator := (const Value: Pointer): TSelf; inline;
    class operator = (v1, v2: TSelf): Boolean; inline;
  end;

  generic TLabWeakRef<T> = record
  public
    type TPtr = T;
    type TSelf = specialize TLabWeakRef<T>;
    type TShared = specialize TLabSharedRef<T>;
  private
    var _Weak: IInterface;
    procedure Assign(const Value: TPtr);
  public
    function IsValid: Boolean; inline;
    function AsShared: TShared; inline;
    function Ptr: TPtr; inline;
    class operator := (const Value: TPtr): TSelf; inline;
    class operator := (const Value: TShared): TSelf; inline;
  end;

  TLabClass = class;
  TLabWeakCounter = class (TInterfacedObject)
  private
    var _Obj: TLabClass;
  public
    property Obj: TLabClass read _Obj write _Obj;
    constructor Create(const AObj: TLabClass);
    destructor Destroy; override;
  end;

  TLabClass = class (TObject, IUnknown)
  public
    type TShared = specialize TLabSharedRef<TLabClass>;
  protected
    class var _VulkanPtr: ^TVulkan;
    class var _VulkanInstance: TVkInstance;
    var _RefCount: Longint;
    var _Weak: TLabWeakCounter;
    var _References: array of TShared;
    function QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} iid : tguid;out obj) : longint;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    function _AddRef : longint;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    function _Release : longint;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
  protected
    property Weak: TLabWeakCounter read _Weak write _Weak;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    class function Vulkan: TVulkan; inline;
    class function VulkanInstance: TVkInstance; inline;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure AddReference(const Obj: TLabClass);
    procedure RemoveReference(const Obj: TLabClass);
    class function NewInstance: TObject; override;
    property RefCount: Longint read _RefCount;
  end;

  TLabStrArrA = array of AnsiString;
  TLabByteArr = array of TVkUInt8;

function LabOffset2D(const x, y: TVkInt32): TVkOffset2D; inline;
function LabOffset3D(const x, y, z: TVkInt32): TVkOffset3D; inline;
function LabExtent2D(const Width, Height: TVkUInt32): TVkExtent2D; inline;
function LabExtent3D(const Width, Height, Depth: TVkUInt32): TVkExtent3D; inline;
function LabRect2D(
  const X: TVkInt32;
  const Y: TVkInt32;
  const Width: TVkUInt32;
  const Height: TVkUInt32
): TVkRect2D; inline;

implementation

uses LabUtils;

//TLabSharedRef BEGIN
function TLabSharedRef.GetPtr: T;
begin
  Result := T(_Ptr as TLabClass);
end;

procedure TLabSharedRef.SetPtr(const Value: T);
begin
  _Ptr := IInterface(Value);
end;

function TLabSharedRef.IsValid: Boolean;
begin
  Result := _Ptr <> nil;
end;

class operator TLabSharedRef.:=(const Value: T): TSelf;
begin
  Result.Ptr := Value;
end;

class operator TLabSharedRef.:=(const Value: Pointer): TSelf;
begin
  Result.Ptr := T(Value);
end;

class operator TLabSharedRef.=(v1, v2: TSelf): Boolean;
begin
  Result := v1._Ptr = v2._Ptr;
end;
//TLabSharedRef END

//TLabWeakRef BEGIN
procedure TLabWeakRef.Assign(const Value: TPtr);
begin
  if Assigned(Value) then
  begin
    if Assigned(Value.Weak) then
    begin
      _Weak := Value.Weak;
    end
    else
    begin
      _Weak := TLabWeakCounter.Create(Value);
    end;
  end
  else
  begin
    _Weak := nil;
  end;
end;

function TLabWeakRef.IsValid: Boolean;
begin
  Result := Assigned(_Weak) and Assigned((_Weak as TLabWeakCounter).Obj);
end;

function TLabWeakRef.AsShared: TShared;
begin
  if IsValid then Result := T((_Weak as TLabWeakCounter).Obj) else Result := nil;
end;

function TLabWeakRef.Ptr: TPtr;
begin
  Result := TPtr((_Weak as TLabWeakCounter).Obj);
end;

class operator TLabWeakRef.:= (const Value: TPtr): TSelf;
begin
  Result.Assign(Value);
end;

class operator TLabWeakRef.:= (const Value: TShared): TSelf;
begin
  Result.Assign(Value.Ptr);
end;
//TLabWeakRef END

//TLabWeakCounter BEGIN
constructor TLabWeakCounter.Create(const AObj: TLabClass);
begin
  _Obj := AObj;
  _Obj._Weak := Self;
end;

destructor TLabWeakCounter.Destroy;
begin
  if Assigned(_Obj) then _Obj._Weak := nil;
  inherited Destroy;
end;
//TLabWeakCounter END

//TLabClass BEGIN
class constructor TLabClass.CreateClass;
begin
  LabLog('TLabClass.CreateClass');
  _VulkanPtr := @vk;
  _VulkanInstance := 0;
end;

class destructor TLabClass.DestroyClass;
begin
  LabLog('TLabClass.DestroyClass');
end;

class function TLabClass.Vulkan: TVulkan;
begin
  Result := _VulkanPtr^;
end;

class function TLabClass.VulkanInstance: TVkInstance;
begin
  Result := _VulkanInstance;
end;

function TLabClass.QueryInterface(constref iid: tguid; out obj): longint;
  stdcall;
begin
  if GetInterface(IID, Obj) then Result := S_OK else Result := Longint(E_NOINTERFACE);
end;

function TLabClass._AddRef: longint; stdcall;
begin
  Result := InterlockedIncrement(_RefCount);
end;

function TLabClass._Release: longint; stdcall;
begin
   Result := InterlockedDecrement(_RefCount);
   if Result = 0 then Self.Destroy;
end;

procedure TLabClass.AfterConstruction;
begin
   InterlockedDecrement(_RefCount);
end;

procedure TLabClass.BeforeDestruction;
begin
  if Assigned(_Weak) then _Weak._Obj := nil;
end;

procedure TLabClass.AddReference(const Obj: TLabClass);
  var i: TVkInt32;
begin
  for i := 0 to High(_References) do
  begin
    if _References[i].Ptr = Obj then Exit;
  end;
  SetLength(_References, Length(_References) + 1);
  i := High(_References);
  _References[i] := Obj;
end;

procedure TLabClass.RemoveReference(const Obj: TLabClass);
  var i, j: TVkInt32;
begin
  for i := 0 to High(_References) do
  if _References[i].Ptr = Obj then
  begin
    for j := i to High(_References) - 1 do
    begin
      _References[j] := _References[j + 1];
    end;
    SetLength(_References, Length(_References) - 1);
    Exit;
  end;
end;

class function TLabClass.NewInstance: TObject;
begin
   Result := inherited NewInstance;
   if NewInstance <> nil then TLabClass(Result)._RefCount := 1;
end;
//TLabClass END

function LabOffset2D(const x, y: TVkInt32): TVkOffset2D;
begin
  Result.x := x;
  Result.y := y;
end;

function LabOffset3D(const x, y, z: TVkInt32): TVkOffset3D;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
end;

function LabExtent2D(const Width, Height: TVkUInt32): TVkExtent2D;
begin
  Result.width := Width;
  Result.height := Height;
end;

function LabExtent3D(const Width, Height, Depth: TVkUInt32): TVkExtent3D;
begin
  Result.width := Width;
  Result.height := Height;
  Result.depth := Depth;
end;

function LabRect2D(
  const X: TVkInt32; const Y: TVkInt32;
  const Width: TVkUInt32; const Height: TVkUInt32
): TVkRect2D;
begin
  Result.offset.x := X;
  Result.offset.y := Y;
  Result.extent.width := Width;
  Result.extent.height := Height;
end;

end.
