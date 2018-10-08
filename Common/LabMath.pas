unit LabMath;

interface

uses
  Vulkan,
  Types,
  SysUtils;

type
  TLabFloat = TVkFloat;
  PLabFloat = ^TLabFloat;
  TLabFloatArr = array[Word] of TLabFloat;
  PLabFloatArr = ^TLabFloatArr;
  TLabInt8 = TVkInt8;
  PLabInt8 = ^TLabInt8;
  TLabUInt8 = TVkUInt8;
  PLabUInt8 = ^TLabUInt8;
  TLabUInt8Arr = array[Word] of TLabUInt8;
  PLabUInt8Arr = ^TLabUInt8Arr;
  TLabInt16 = TVkInt16;
  PLabInt16 = ^TLabInt16;
  TLabUInt16 = TVkUInt16;
  PLabUInt16 = ^TLabUInt16;
  TLabInt32 = TVkInt32;
  PLabInt32 = ^TLabInt32;
  TLabInt32Arr = array[Word] of TLabInt32;
  PLabInt32Arr = ^TLabInt32Arr;
  TLabUInt32 = TVkUInt32;
  PLabUInt32 = ^TLabUInt32;
  TLabInt64 = TVkInt64;
  PLabInt64 = ^TLabInt64;
  TLabUInt64 = TVkUInt64;
  PLabUInt64 = ^TLabUInt64;

  TLabMatRef = array[0..15] of TLabFloat;
  PLabMatRef = ^TLabMatRef;
  TLabVec2Ref = array[0..1] of TLabFloat;
  PLabVec2Ref = ^TLabVec2Ref;
  TLabVec3Ref = array[0..2] of TLabFloat;
  PLabVec3Ref = ^TLabVec3Ref;
  TLabVec4Ref = array[0..3] of TLabFloat;
  PLabVec4Ref = ^TLabVec4Ref;
  TLabQuatRef = array[0..3] of TLabFloat;
  PLabQuatRef = ^TLabQuatRef;

  TLabSwizzle = object
  private
    const DefaultSwizzle: TLabUInt8 = (0 or (1 shl 2) or (2 shl 4) or (3 shl 6));
    var _Remap: TLabUInt8;
    function GetOffset(const Index: TLabUInt8): TLabUInt8; inline;
    procedure SetOffset(const Index: TLabUInt8; const Value: TLabUInt8); inline;
  public
    property Remap: TLabUInt8 read _Remap;
    property Offset[const Index: TLabUInt8]: TLabUInt8 read GetOffset write SetOffset; default;
    procedure SetIdentity; inline;
    procedure SetValue(
      const ord0: TLabUInt8 = 0;
      const ord1: TLabUInt8 = 1;
      const ord2: TLabUInt8 = 2;
      const ord3: TLabUInt8 = 3
    );
  end;

  PLabMat = ^TLabMat;
  TLabMat = object
  private
    function GetMat(const ix, iy: TLabInt32): TLabFloat; inline;
    function GetAxisX: TLabVec3Ref; inline;
    function GetAxisY: TLabVec3Ref; inline;
    function GetAxisZ: TLabVec3Ref; inline;
    procedure SetAxisX(const Value: TLabVec3Ref); inline;
    procedure SetAxisY(const Value: TLabVec3Ref); inline;
    procedure SetAxisZ(const Value: TLabVec3Ref); inline;
    procedure SetMat(const ix, iy: TLabInt32; const Value: TLabFloat); inline;
    function GetTranslation: TLabVec3Ref; inline;
    procedure SetTranslation(const Value: TLabVec3Ref); inline;
  public
    var Arr: array [0..15] of TLabFloat;
    property e00: TLabFloat read Arr[0] write Arr[0];
    property e01: TLabFloat read Arr[1] write Arr[1];
    property e02: TLabFloat read Arr[2] write Arr[2];
    property e03: TLabFloat read Arr[3] write Arr[3];
    property e10: TLabFloat read Arr[4] write Arr[4];
    property e11: TLabFloat read Arr[5] write Arr[5];
    property e12: TLabFloat read Arr[6] write Arr[6];
    property e13: TLabFloat read Arr[7] write Arr[7];
    property e20: TLabFloat read Arr[8] write Arr[8];
    property e21: TLabFloat read Arr[9] write Arr[9];
    property e22: TLabFloat read Arr[10] write Arr[10];
    property e23: TLabFloat read Arr[11] write Arr[11];
    property e30: TLabFloat read Arr[12] write Arr[12];
    property e31: TLabFloat read Arr[13] write Arr[13];
    property e32: TLabFloat read Arr[14] write Arr[14];
    property e33: TLabFloat read Arr[15] write Arr[15];
    property Mat[const ix, iy: TLabInt32]: TLabFloat read GetMat write SetMat; default;
    property Translation: TLabVec3Ref read GetTranslation write SetTranslation;
    property AxisX: TLabVec3Ref read GetAxisX write SetAxisX;
    property AxisY: TLabVec3Ref read GetAxisY write SetAxisY;
    property AxisZ: TLabVec3Ref read GetAxisZ write SetAxisZ;
    procedure SetValue(
      const m00, m10, m20, m30: TLabFloat;
      const m01, m11, m21, m31: TLabFloat;
      const m02, m12, m22, m32: TLabFloat;
      const m03, m13, m23, m33: TLabFloat
    ); overload; inline;
    procedure SetIdentity; inline;
    procedure SetZero; inline;
    function Transpose: TLabMat; inline;
    function Inverse: TLabMat; inline;
    function ToStr: AnsiString;
    function Swizzle(const Remap: TLabSwizzle): TLabMat; inline;
  end;
  TLabMatArr = array[Word] of TLabMat;
  PLabMatArr = ^TLabMatArr;

  PLabVec2 = ^TLabVec2;
  TLabVec2 = object
  private
    function GetArr(const Index: TLabInt32): TLabFloat; inline;
    procedure SetArr(const Index: TLabInt32; const Value: TLabFloat); inline;
  public
    var x, y: TLabFloat;
    property Arr[const Index: TLabInt32]: TLabFloat read GetArr write SetArr; default;
    procedure SetValue(const vx, vy: TLabFloat); inline;
    procedure SetZero; inline;
    function Norm: TLabVec2;
    function Dot(const v: TLabVec2): TLabFloat;
    function Cross(const v: TLabVec2): TLabFloat;
    function Angle(const v: TLabVec2): TLabFloat;
    function AngleOX: TLabFloat;
    function AngleOY: TLabFloat;
    function Len: TLabFloat;
    function LenSq: TLabFloat;
    function Perp: TLabVec2;
    function Reflect(const n: TLabVec2): TLabVec2;
    function Transform3x3(const m: TLabMat): TLabVec2;
    function Transform4x3(const m: TLabMat): TLabVec2;
    function Transform4x4(const m: TLabMat): TLabVec2;
    function AsVec3: TLabVec3Ref; inline;
    function AsVec4: TLabVec4Ref; inline;
    function Swizzle(const Remap: TLabSwizzle): TLabVec2; inline;
  end;

  PLabVec3 = ^TLabVec3;
  TLabVec3 = object
  private
    function GetArr(const Index: TLabInt32): TLabFloat; inline;
    procedure SetArr(const Index: TLabInt32; const Value: TLabFloat); inline;
  public
    var x, y, z: TLabFloat;
    property Arr[const Index: TLabInt32]: TLabFloat read GetArr write SetArr; default;
    procedure SetValue(const vx, vy, vz: TLabFloat); inline;
    procedure SetZero; inline;
    function Norm: TLabVec3;
    function Dot(const v: TLabVec3): TLabFloat;
    function Cross(const v: TLabVec3): TLabVec3;
    function Len: TLabFloat;
    function LenSq: TLabFloat;
    function Transform3x3(const m: TLabMat): TLabVec3;
    function Transform4x3(const m: TLabMat): TLabVec3;
    function Transform4x4(const m: TLabMat): TLabVec3;
    function AsVec4: TLabVec4Ref; inline;
    function Swizzle(const Remap: TLabSwizzle): TLabVec3; inline;
  end;

  PLabVec4 = ^TLabVec4;
  TLabVec4 = object
  private
    function GetArr(const Index: TLabInt32): TLabFloat; inline;
    procedure SetArr(const Index: TLabInt32; const Value: TLabFloat); inline;
  public
    var x, y, z, w: TLabFloat;
    property Arr[const Index: TLabInt32]: TLabFloat read GetArr write SetArr; default;
    procedure SetValue(const vx, vy, vz, vw: TLabFloat); inline;
    function Swizzle(const Remap: TLabSwizzle): TLabVec4; inline;
  end;

  PLabQuat = ^TLabQuat;
  TLabQuat = object
  private
    function GetArr(const Index: TLabInt32): TLabFloat; inline;
    procedure SetArr(const Index: TLabInt32; const Value: TLabFloat); inline;
  public
    var x, y, z, w: TLabFloat;
    property Arr[const Index: TLabInt32]: TLabFloat read GetArr write SetArr; default;
    procedure SetValue(const qx, qy, qz, qw: TLabFloat); inline;
  end;

  PLabBox = ^TLabBox;
  TLabBox = object
  private
    function GetArr(const Index: TLabInt32): TLabFloat; inline;
    procedure SetArr(const Index: TLabInt32; const Value: TLabFloat); inline;
  public
    var c, vx, vy, vz: TLabVec3;
    property Arr[const Index: TLabInt32]: TLabFloat read GetArr write SetArr; default;
    procedure SetValue(const bc, bx, by, bz: TLabVec3); inline;
    function Transform(const m: TLabMat): TLabBox;
  end;

  PLabAABox = ^TLabAABox;
  TLabAABox = object
  private
    function GetArr(const Index: TLabInt32): TLabFloat; inline;
    procedure SetArr(const Index: TLabInt32; const Value: TLabFloat); inline;
    function GetSize: TLabVec3; inline;
    function GetSizeX: TLabFloat; inline;
    function GetSizeY: TLabFloat; inline;
    function GetSizeZ: TLabFloat; inline;
  public
    var MinV, MaxV: TLabVec3;
    property Arr[const Index: TLabInt32]: TLabFloat read GetArr write SetArr; default;
    property Size: TLabVec3 read GetSize;
    property SizeX: TLabFloat read GetSizeX;
    property SizeY: TLabFloat read GetSizeY;
    property SizeZ: TLabFloat read GetSizeZ;
    procedure SetValue(const BMinV, BMaxV: TLabVec3); inline; overload;
    procedure SetValue(const v: TLabVec3); inline; overload;
    procedure Include(const v: TLabVec3); inline; overload;
    procedure Include(const b: TLabAABox); inline; overload;
    procedure Merge(const b: TLabAABox);
    function Intersect(const b: TLabAABox): Boolean; inline;
  end;

  PLabSphere = ^TLabSphere;
  TLabSphere = object
  private
    function GetArr(const Index: TLabInt32): TLabFloat; inline;
    procedure SetArr(const Index: TLabInt32; const Value: TLabFloat); inline;
  public
    var c: TLabVec3;
    var r: TLabFloat;
    property Arr[const Index: TLabInt32]: TLabFloat read GetArr write SetArr; default;
    procedure SetValue(const sc: TLabVec3; const sr: TLabFloat); inline;
  end;

  PLabPlane = ^TLabPlane;
  TLabPlane = object
  private
    function GetArr(const Index: TLabInt32): TLabFloat; inline;
    procedure SetArr(const Index: TLabInt32; const Value: TLabFloat); inline;
    function GetA: TLabFloat; inline;
    procedure SetA(const Value: TLabFloat); inline;
    function GetB: TLabFloat; inline;
    procedure SetB(const Value: TLabFloat); inline;
    function GetC: TLabFloat; inline;
    procedure SetC(const Value: TLabFloat); inline;
  public
    var n: TLabVec3;
    var d: TLabFloat;
    property Arr[const Index: TLabInt32]: TLabFloat read GetArr write SetArr; default;
    property a: TLabFloat read GetA write SetA;
    property b: TLabFloat read GetB write SetB;
    property c: TLabFloat read GetC write SetC;
    procedure SetValue(const pa, pb, pc, pd: TLabFloat); overload; inline;
    procedure SetValue(const pn: TLabVec3; const pd: TLabFloat); overload; inline;
    procedure SetValue(const v0, v1, v2: TLabVec3); overload; inline;
  end;

  PLabRay3 = ^TLabRay3;
  TLabRay3 = object
  private
    function GetArr(const Index: TLabInt32): TLabFloat; inline;
    procedure SetArr(const Index: TLabInt32; const Value: TLabFloat); inline;
  public
    var Origin: TLabVec3;
    var Dir: TLabVec3;
    property Arr[const Index: TLabInt32]: TLabFloat read GetArr write SetArr; default;
    procedure SetValue(const ROrigin, RDir: TLabVec3); inline;
  end;

  TLabFrustumCheck = (
    fc_inside,
    fc_intersect,
    fc_outside
  );

  PLabFrustum = ^TLabFrustum;
  TLabFrustum = object
  private
    var _Planes: array[0..5] of TLabPlane;
    var _RefV: PLabMat;
    var _RefP: PLabMat;
    function GetPlane(const Index: TLabInt32): PLabPlane; inline;
    procedure Normalize; inline;
    function DistanceToPoint(const PlaneIndex: TLabInt32; const Pt: TLabVec3): TLabFloat; inline;
  public
    property RefV: PLabMat read _RefV write _RefV;
    property RefP: PLabMat read _RefP write _RefP;
    property Planes[const Index: TLabInt32]: PLabPlane read GetPlane;
    procedure Update;
    procedure ExtractPoints(const OutV: PLabVec3);
    function IntersectFrustum(const Frustum: TLabFrustum): Boolean;
    function CheckSphere(const Center: TLabVec3; const Radius: TLabFloat): TLabFrustumCheck; overload;
    function CheckSphere(const Sphere: TLabSphere): TLabFrustumCheck; overload;
    function CheckBox(const MinV, MaxV: TLabVec3): TLabFrustumCheck; overload;
    function CheckBox(const Box: TLabAABox): TLabFrustumCheck; overload;
  end;

  TLabRect = object
  private
    procedure SetX(const Value: TLabFloat); inline;
    procedure SetY(const Value: TLabFloat); inline;
    procedure SetWidth(const Value: TLabFloat); inline;
    function GetWidth: TLabFloat; inline;
    procedure SetHeight(const Value: TLabFloat); inline;
    function GetHeight: TLabFloat; inline;
    procedure SetTopLeft(const Value: TLabVec2); inline;
    function GetTopLeft: TLabVec2; inline;
    procedure SetTopRight(const Value: TLabVec2); inline;
    function GetTopRight: TLabVec2; inline;
    procedure SetBottomLeft(const Value: TLabVec2); inline;
    function GetBottomLeft: TLabVec2; inline;
    procedure SetBottomRight(const Value: TLabVec2); inline;
    function GetBottomRight: TLabVec2; inline;
    function GetCenter: TLabVec2; inline;
  public
    var Left: TLabFloat;
    var Top: TLabFloat;
    var Right: TLabFloat;
    var Bottom: TLabFloat;
    property x: TLabFloat read Left write SetX;
    property y: TLabFloat read Top write SetY;
    property l: TLabFloat read Left write Left;
    property t: TLabFloat read Top write Top;
    property r: TLabFloat read Right write Right;
    property b: TLabFloat read Bottom write Bottom;
    property w: TLabFloat read GetWidth write SetWidth;
    property h: TLabFloat read GetHeight write SetHeight;
    property tl: TLabVec2 read GetTopLeft write SetTopLeft;
    property tr: TLabVec2 read GetTopRight write SetTopRight;
    property bl: TLabVec2 read GetBottomLeft write SetBottomLeft;
    property br: TLabVec2 read GetBottomRight write SetBottomRight;
    property Width: TLabFloat read GetWidth write SetWidth;
    property Height: TLabFloat read GetHeight write SetHeight;
    property TopLeft: TLabVec2 read GetTopLeft write SetTopLeft;
    property TopRight: TLabVec2 read GetTopRight write SetTopRight;
    property BottomLeft: TLabVec2 read GetBottomLeft write SetBottomLeft;
    property BottomRight: TLabVec2 read GetBottomRight write SetBottomRight;
    property Center: TLabVec2 read GetCenter;
    function Contains(const v: TLabVec2): Boolean; inline; overload;
    function Contains(const vx, vy: TLabFloat): Boolean; inline; overload;
    function Clip(const ClipRect: TLabRect): TLabRect; inline;
    function Expand(const Dimensions: TLabVec2): TLabRect; inline; overload;
    function Expand(const dx, dy: TLabFloat): TLabRect; inline; overload;
  end;
  PLabRect = ^TLabRect;

  TLabRotation2 = object
  private
    function GetAngle: TLabFloat; inline;
    function GetAxisX: TLabVec2;
    function GetAxisY: TLabVec2;
    procedure SetAngle(const Angle: TLabFloat); inline;
    procedure SetAxisX(const Value: TLabVec2);
    procedure SetAxisY(const Value: TLabVec2);
  public
    var s, c: TLabFloat;
    property Angle: TLabFloat read GetAngle write SetAngle;
    property AxisX: TLabVec2 read GetAxisX write SetAxisX;
    property AxisY: TLabVec2 read GetAxisY write SetAxisY;
    procedure SetValue(const rs, rc: TLabFloat); inline;
    procedure SetIdentity; inline;
    procedure Normalize; inline;
    function Transform(const v: TLabVec2): TLabVec2; inline;
    function TransformInv(const v: TLabVec2): TLabVec2; inline;
  end;
  PLabRotation2 = ^TLabRotation2;

  TLabTransform2 = object
  public
    var p: TLabVec2;
    var r: TLabRotation2;
    procedure SetValue(const tp: TLabVec2; const tr: TLabRotation2); inline;
    procedure SetIdentity; inline;
    function Transform(const v: TLabVec2): TLabVec2; inline;
    function TransformInv(const v: TLabVec2): TLabVec2; inline;
  end;
  PLabTransform2 = ^TLabTransform2;

  TLabVec2Arr = array[Word] of TLabVec2;
  PLabVec2Arr = ^TLabVec2Arr;

  TLabPolyTriang = record
    v: array of TLabVec2;
    Triangles: array of array[0..2] of TLabInt32;
  end;
  PLabPolyTriang = ^TLabPolyTriang;

  operator := (v: TLabVec2): TLabVec2Ref; inline;
  operator := (vr: TLabVec2Ref): TLabVec2; inline;
  operator := (v: TLabVec2): TPoint; inline;
  operator := (p: TPoint): TLabVec2; inline;
  operator := (v: TLabVec3): TLabVec3Ref; inline;
  operator := (vr: TLabVec3Ref): TLabVec3; inline;
  operator := (v: TLabVec4): TLabVec4Ref; inline;
  operator := (vr: TLabVec4Ref): TLabVec4; inline;
  operator := (m: TLabMat): TLabMatRef; inline;
  operator := (mr: TLabMatRef): TLabMat; inline;
  operator := (r: TLabRect): TRect; inline;
  operator := (r: TRect): TLabRect; inline;
  operator := (b: TLabBox): TLabAABox; inline;
  operator := (b: TLabAABox): TLabBox; inline;
  operator := (r: TLabRotation2): TLabFloat; inline;
  operator := (a: TLabFloat): TLabRotation2; inline;
  operator - (v: TLabVec2): TLabVec2; inline;
  operator - (v: TLabVec3): TLabVec3; inline;
  operator - (v0, v1: TLabVec2): TLabVec2; inline;
  operator - (v0, v1: TLabVec3): TLabVec3; inline;
  operator - (v: TLabVec2; f: TLabFloat): TLabVec2; inline;
  operator - (v: TLabVec3; f: TLabFloat): TLabVec3; inline;
  operator - (v: TLabVec4; f: TLabFloat): TLabVec4; inline;
  operator - (v: TLabVec2; p: TPoint): TLabVec2; inline;
  operator - (p: TPoint; v: TLabVec2): TLabVec2; inline;
  operator + (v0, v1: TLabVec2): TLabVec2; inline;
  operator + (v0, v1: TLabVec3): TLabVec3; inline;
  operator + (v: TLabVec2; f: TLabFloat): TLabVec2; inline;
  operator + (v: TLabVec3; f: TLabFloat): TLabVec3; inline;
  operator + (v: TLabVec4; f: TLabFloat): TLabVec4; inline;
  operator + (f: TLabFloat; v: TLabVec2): TLabVec2; inline;
  operator + (f: TLabFloat; v: TLabVec3): TLabVec3; inline;
  operator + (f: TLabFloat; v: TLabVec4): TLabVec4; inline;
  operator + (b: TLabAABox; v: TLabVec3): TLabAABox; inline;
  operator + (v: TLabVec2; p: TPoint): TLabVec2; inline;
  operator + (p: TPoint; v: TLabVec2): TLabVec2; inline;
  operator * (v: TLabVec2; f: TLabFloat): TLabVec2; inline;
  operator * (v: TLabVec3; f: TLabFloat): TLabVec3; inline;
  operator * (v: TLabVec4; f: TLabFloat): TLabVec4; inline;
  operator * (f: TLabFloat; v: TLabVec2): TLabVec2; inline;
  operator * (f: TLabFloat; v: TLabVec3): TLabVec3; inline;
  operator * (f: TLabFloat; v: TLabVec4): TLabVec4; inline;
  operator * (v0: TLabVec2; v1: TLabVec2): TLabVec2; inline;
  operator * (v0: TLabVec3; v1: TLabVec3): TLabVec3; inline;
  operator * (v0: TLabVec4; v1: TLabVec4): TLabVec4; inline;
  operator * (v: TLabVec2; m: TLabMat): TLabVec2; inline;
  operator * (v: TLabVec3; m: TLabMat): TLabVec3; inline;
  operator * (m0, m1: TLabMat): TLabMat; inline;
  operator / (v: TLabVec2; f: TLabFloat): TLabVec2; inline;
  operator / (v: TLabVec3; f: TLabFloat): TLabVec3; inline;
  operator = (v0, v1: TLabVec2): Boolean; inline;
  operator = (v0, v1: TLabVec3): Boolean; inline;
  operator = (v0, v1: TLabVec4): Boolean; inline;
  operator = (q0, q1: TLabQuat): Boolean; inline;
  operator = (m0, m1: TLabMat): Boolean; inline;
  operator mod(const a, b: Double): Double; inline;
  operator mod(const a, b: Single): Single; inline;

function LabSwizzle(
  const ord0: TLabUInt8 = 0;
  const ord1: TLabUInt8 = 1;
  const ord2: TLabUInt8 = 2;
  const ord3: TLabUInt8 = 3
): TLabSwizzle; inline;
function LabRect(const x, y, w, h: TLabFloat): TLabRect; inline;
function LabVec2: TLabVec2; inline;
function LabVec2(const x, y: TLabFloat): TLabVec2; inline;
function LabVec2(const pt: TPoint): TLabVec2; inline;
function LabVec2InRect(const v: TLabVec2; const r: TLabRect): Boolean; inline;
function LabVec2InPoly(const v: TLabVec2; const VArr: PLabVec2; const VCount: TLabInt32): Boolean;
function LabVec3: TLabVec3; inline;
function LabVec3(const x, y, z: TLabFloat): TLabVec3; inline; overload;
function LabVec3(const v2: TLabVec2; const z: TLabFloat): TLabVec3; inline; overload;
function LabVec4: TLabVec4; inline;
function LabVec4(const x, y, z, w: TLabFloat): TLabVec4; inline;
function LabRotation2: TLabRotation2; inline; overload;
function LabRotation2(const s, c: TLabFloat): TLabRotation2; inline; overload;
function LabRotation2(const Angle: TLabFloat): TLabRotation2; inline; overload;
function LabTransform2: TLabTransform2; inline; overload;
function LabTransform2(const p: TLabVec2; const r: TLabRotation2): TLabTransform2; inline;
function LabQuat: TLabQuat; inline;
function LabQuat(const x, y, z, w: TLabFloat): TLabQuat; inline;
function LabQuat(const Axis: TLabVec3; const Angle: TLabFloat): TLabQuat; inline;
function LabQuat(const m: TLabMat): TLabQuat; inline;
function LabQuatDot(const q0, q1: TLabQuat): TLabFloat; inline;
function LabQuatSlerp(const q0, q1: TLabQuat; const s: TLabFloat): TLabQuat;
function LabMat(
  const m00, m10, m20, m30: TLabFloat;
  const m01, m11, m21, m31: TLabFloat;
  const m02, m12, m22, m32: TLabFloat;
  const m03, m13, m23, m33: TLabFloat
): TLabMat; inline;
function LabMat(const AxisX, AxisY, AxisZ, Translation: TLabVec3): TLabMat; inline;
function LabMatIdentity: TLabMat; inline;
function LabMatZero: TLabMat; inline;
function LabMatScaling(const x, y, z: TLabFloat): TLabMat; inline;
function LabMatScaling(const v: TLabVec3): TLabMat; inline;
function LabMatScaling(const s: TLabFloat): TLabMat; inline;
function LabMatTranslation(const x, y, z: TLabFloat): TLabMat; inline;
function LabMatTranslation(const v: TLabVec3): TLabMat; inline;
function LabMatRotationX(const a: TLabFloat): TLabMat; inline;
function LabMatRotationY(const a: TLabFloat): TLabMat; inline;
function LabMatRotationZ(const a: TLabFloat): TLabMat; inline;
function LabMatRotation(const x, y, z, a: TLabFloat): TLabMat; inline;
function LabMatRotation(const v: TLabVec3; const a: TLabFloat): TLabMat; inline;
function LabMatRotation(const q: TLabQuat): TLabMat; inline;
function LabMatSkew(const Amount, Axis: TLabVec3; const Angle: TLabFloat): TLabMat; inline;
function LabMatView(const Pos, Target, Up: TLabVec3): TLabMat; inline;
function LabMatOrth(const Width, Height, ZNear, ZFar: TLabFloat): TLabMat; inline;
function LabMatOrth2D(const Width, Height, ZNear, ZFar: TLabFloat; const FlipH: Boolean = False; const FlipV: Boolean = True): TLabMat; inline;
function LabMatProj(const FOV, Aspect, ZNear, ZFar: TLabFloat): TLabMat; inline;
function LabMatTranspose(const m: TLabMat): TLabMat; inline;
procedure LabMatDecompose(const OutScaling: PLabVec3; const OutRotation: PLabQuat; const OutTranslation: PLabVec3; const m: TLabMat);
function LabMatCompare(const m0, m1: TLabMat): Boolean; inline;

function LabMin(const f0, f1: TLabFloat): TLabFloat; inline; overload;
function LabMin(const v0, v1: TLabInt32): TLabInt32; inline; overload;
function LabMin(const v0, v1: TLabUInt32): TLabUInt32; inline; overload;
function LabMax(const f0, f1: TLabFloat): TLabFloat; inline; overload;
function LabMax(const v0, v1: TLabInt32): TLabInt32; inline; overload;
function LabMax(const v0, v1: TLabUInt32): TLabUInt32; inline; overload;
function LabClamp(const f, LimMin, LimMax: TLabFloat): TLabFloat; inline;
function LabSmoothStep(const t, f0, f1: TLabFloat): TLabFloat; inline;
function LabLerpFloat(const v0, v1, t: TLabFloat): TLabFloat; inline;
function LabBezierFloat(const f0, f1, f2, f3: TLabFloat; const t: TLabFloat): TLabFloat; inline;
function LabLerpVec2(const v0, v1: TLabVec2; const t: TLabFloat): TLabVec2; inline;
function LabLerpVec3(const v0, v1: TLabVec3; const t: TLabFloat): TLabVec3; inline;
function LabLerpVec4(const v0, v1: TLabVec4; const t: TLabFloat): TLabVec4; inline;
function LabLerpQuat(const v0, v1: TLabQuat; const t: TLabFloat): TLabQuat; inline;
function LabCosrpFloat(const f0, f1: TLabFloat; const s: TLabFloat): TLabFloat; inline;
function LabVec2CatmullRom(const v0, v1, v2, v3: TLabVec2; const t: TLabFloat): TLabVec2; inline;
function LabVec3CatmullRom(const v0, v1, v2, v3: TLabVec3; const t: TLabFloat): TLabVec3; inline;
function LabVec2Bezier(const v0, v1, v2, v3: TLabVec2; const t: TLabFloat): TLabVec2; inline;

function LabCoTan(const x: TLabFloat): TLabFloat; inline;
function LabArcCos(const x: TLabFloat): TLabFloat;
function LabArcTan2(const y, x: TLabFloat): TLabFloat;
procedure LabSinCos(const Angle: TLabFloat; var s, c: TLabFloat);

function LabProject2DPointToLine(const lv0, lv1, v: TLabVec2; var InSegment: Boolean): TLabVec2;
function LabProject3DPointToLine(const lv0, lv1, v: TLabVec3; var InSegment: Boolean): TLabVec3;
function LabProject3DPointToPlane(const p: TLabPlane; const v: TLabVec3): TLabVec3;

function LabIntersect2DLineVsLine(const l0v0, l0v1, l1v0, l1v1: TLabVec2; var xp: TLabVec2): Boolean;
function LabIntersect2DLineVsSegment(const l0, l1, s0, s1: TLabVec2; var xp: TLabVec2): Boolean;
function LabIntersect2DSegmentVsSegment(const s0v0, s0v1, s1v0, s1v1: TLabVec2; var xp: TLabVec2): Boolean;
function LabIntersect2DLineVsCircle(const lv0, lv1, cc: TLabVec2; const r: TLabFloat; var xp0, xp1: TLabVec2): Boolean;
function LabIntersect2DSegmentVsCircle(const lv0, lv1, cc: TLabVec2; const r: TLabFloat; var xp0, xp1: TLabVec2; var xb0, xb1: Boolean): Boolean;
function LabIntersect2DLineVsRect(const lv0, lv1: TLabVec2; const r: TLabRect; var xp0, xp1: TLabVec2): Boolean;
function LabIntersect2DSegmentVsRect(const lv0, lv1: TLabVec2; const r: TLabRect; var xp0, xp1: TLabVec2): Boolean;
function LabIntersect3DLineVsPlane(const lv0, lv1: TLabVec3; const p: TLabPlane; var xp: TLabVec3): Boolean;
function LabIntersect3DLineVsSphere(const lv0, lv1: TLabVec3; const s: TLabSphere; var xp0, xp1: TLabVec3): Boolean;
function LabIntersect3Planes(const p1, p2, p3: TLabPlane; var xp: TLabVec3): Boolean;
function LabIntersect3DRayVsPlane(const r: TLabRay3; const p: TLabPlane; var xp: TLabVec3; var xd: TLabFloat): Boolean;
function LabIntersect3DRayVsTriangle(const r: TLabRay3; const v0, v1, v2: TLabVec3; var xp: TLabVec3; var xd: TLabFloat): Boolean;

function LabDistance3DLineToLine(const l0v0, l0v1, l1v0, l1v1: TLabVec3; var d0, d1: TLabVec3): TLabFloat;
function LabDistance3DSegmentToSegment(const l0v0, l0v1, l1v0, l1v1: TLabVec3): TLabFloat;

function LabTriangleArea(const v0, v1, v2: TLabVec2): TLabFloat; overload;
function LabTriangleArea(const v0, v1, v2: TLabVec3): TLabFloat; overload;
function LabTriangleNormal(const v0, v1, v2: TLabVec3): TLabVec3;
procedure LabTriangleTBN(const v1, v2, v3: TLabVec3; const uv1, uv2, uv3: TLabVec2; var T, B, N: TLabVec3);
function LabPolyTriangulate(const Triang: PLabPolyTriang): Boolean;

function LabLineVsCircle(const v0, v1, c: TLabVec2; const r: TLabFloat; var p0, p1: PLabVec2): Boolean;
function LabLineVsLine(const l0v0, l0v1, l1v0, l1v1: TLabVec2; var p: TLabVec2): Boolean;
function LabLineVsLineInf(const l0v0, l0v1, l1v0, l1v1: TLabVec2; var p: TLabVec2): Boolean;
function LabRectVsRect(const r0, r1: TLabRect; var Resp: TLabVec2): Boolean;
function LabRectVsTri(const r: TLabRect; const Tri: PLabVec2): Boolean;
function LabRay2VsRect(const RayOrigin, RayDir: TLabVec2; const R: TLabRect; var Intersection: TLabVec2; var Dist: TLabFloat): Boolean;
function LabBallistics(const PosOrigin, PosTarget: TLabVec2; const TotalVelocity, Gravity: TLabFloat; var Trajectory0, Trajectory1: TLabVec2; var Time0, Time1: TLabFloat): Boolean;

procedure LabMatAdd(const OutM, InM1, InM2: PLabMat);
procedure LabMatSub(const OutM, InM1, InM2: PLabMat);
procedure LabMatFltMul(const OutM, InM: PLabMat; const s: PLabFloat);
procedure LabMatMul(const OutM, InM1, InM2: PLabMat);
procedure LabMatInv(const OutM, InM: PLabMat);
procedure LabVec2MatMul3x3(const OutV, InV: PLabVec2; const InM: PLabMat); inline;
procedure LabVec2MatMul4x3(const OutV, InV: PLabVec2; const InM: PLabMat); inline;
procedure LabVec2MatMul4x4(const OutV, InV: PLabVec2; const InM: PLabMat); inline;
procedure LabVec2Rotation2Mul(const OutV, InV: PLabVec2; const InR: PLabRotation2); inline;
procedure LabVec2Rotation2MulInv(const OutV, InV: PLabVec2; const InR: PLabRotation2); inline;
procedure LabVec2Transform2Mul(const OutV, InV: PLabVec2; const InT: PLabTransform2); inline;
procedure LabVec2Transform2MulInv(const OutV, InV: PLabVec2; const InT: PLabTransform2); inline;
procedure LabVec3MatMul3x3(const OutV, InV: PLabVec3; const InM: PLabMat);
procedure LabVec3MatMul4x3(const OutV, InV: PLabVec3; const InM: PLabMat);
procedure LabVec3MatMul4x4(const OutV, InV: PLabVec3; const InM: PLabMat);
procedure LabVec4MatMul(const OutV, InV: PLabVec4; const InM: PLabMat);
function LabVec3Len(const InV: PLabVec3): TLabFloat;
function LabVec4Len(const InV: PLabVec4): TLabFloat;
procedure LabVec2Norm(const OutV, InV: PLabVec2); inline;
procedure LabVec3Norm(const OutV, InV: PLabVec3);
procedure LabVec4Norm(const OutV, InV: PLabVec4);
procedure LabVec3Cross(const OutV, InV1, InV2: PLabVec3);
procedure LabRotation2Mul(const OutR, InR1, InR2: PLabRotation2); inline;
procedure LabRotation2MulInv(const OutR, InR1, InR2: PLabRotation2); inline;
procedure LabTransform2Mul(const OutT, InT1, InT2: PLabTransform2); inline;
procedure LabTransform2MulInv(const OutT, InT1, InT2: PLabTransform2); inline;

const
  LabEPS = 1E-5;
  LabPi = Pi;
  LabHalfPi = Pi * 0.5;
  LabTwoPi = Pi * 2;
  LabDegToRad = Pi / 180;
  LabRadToDeg = 180 / Pi;

implementation

//TLabSwizzle BEGIN
function TLabSwizzle.GetOffset(const Index: TLabUInt8): TLabUInt8;
begin
  Result := (_Remap shr (Index * 2)) and 3;
end;

procedure TLabSwizzle.SetOffset(const Index: TLabUInt8; const Value: TLabUInt8);
  var ind: TLabUInt8;
begin
  ind := Index * 2;
  _Remap := (_Remap and (not (3 shl ind))) or (Value shl ind);
end;

procedure TLabSwizzle.SetIdentity;
begin
  _Remap := DefaultSwizzle;
end;

procedure TLabSwizzle.SetValue(
  const ord0: TLabUInt8;
  const ord1: TLabUInt8;
  const ord2: TLabUInt8;
  const ord3: TLabUInt8
);
  var i: TLabInt32;
begin
  _Remap := ord0 or (ord1 shl 2) or (ord2 shl 4) or (ord3 shl 6);
end;
//TLabSwizzle END

//TLabMat BEGIN
function TLabMat.GetMat(const ix, iy: TLabInt32): TLabFloat;
begin
  Result := Arr[ix * 4 + iy];
end;

function TLabMat.GetAxisX: TLabVec3Ref;
begin
  Result := PLabVec3(@Arr[0])^;
end;

function TLabMat.GetAxisY: TLabVec3Ref;
begin
  Result := PLabVec3(@Arr[4])^;
end;

function TLabMat.GetAxisZ: TLabVec3Ref;
begin
  Result := PLabVec3(@Arr[8])^;
end;

procedure TLabMat.SetAxisX(const Value: TLabVec3Ref);
begin
  PLabVec3(@Arr[0])^ := Value;
end;

procedure TLabMat.SetAxisY(const Value: TLabVec3Ref);
begin
  PLabVec3(@Arr[4])^ := Value;
end;

procedure TLabMat.SetAxisZ(const Value: TLabVec3Ref);
begin
  PLabVec3(@Arr[8])^ := Value;
end;

procedure TLabMat.SetMat(const ix, iy: TLabInt32; const Value: TLabFloat);
begin
  Arr[ix * 4 + iy] := Value;
end;

function TLabMat.GetTranslation: TLabVec3Ref;
begin
  Result := PLabVec3(@Arr[12])^;
end;

procedure TLabMat.SetTranslation(const Value: TLabVec3Ref);
begin
  PLabVec3(@Arr[12])^ := Value;
end;

procedure TLabMat.SetValue(
      const m00, m10, m20, m30: TLabFloat;
      const m01, m11, m21, m31: TLabFloat;
      const m02, m12, m22, m32: TLabFloat;
      const m03, m13, m23, m33: TLabFloat
    );
begin
  Arr[0] := m00; Arr[4] := m10; Arr[8] := m20; Arr[12] := m30;
  Arr[1] := m01; Arr[5] := m11; Arr[9] := m21; Arr[13] := m31;
  Arr[2] := m02; Arr[6] := m12; Arr[10] := m22; Arr[14] := m32;
  Arr[3] := m03; Arr[7] := m13; Arr[11] := m23; Arr[15] := m33;
end;

procedure TLabMat.SetIdentity;
begin
  Self := LabMatIdentity;
end;

procedure TLabMat.SetZero;
begin
  Self := LabMatZero;
end;

function TLabMat.Transpose: TLabMat;
begin
  Result := LabMatTranspose(Self);
end;

function TLabMat.Inverse: TLabMat;
begin
  LabMatInv(@Result, @Self);
end;

function TLabMat.ToStr: AnsiString;
begin
  Result := (
    'TLabMat('#$D#$A +
    FormatFloat('0.0##', e00) + ', ' + FormatFloat('0.0##', e10) + ', ' + FormatFloat('0.0##', e20) + ', ' + FormatFloat('0.0##', e20) + ', '#$D#$A +
    FormatFloat('0.0##', e01) + ', ' + FormatFloat('0.0##', e11) + ', ' + FormatFloat('0.0##', e21) + ', ' + FormatFloat('0.0##', e21) + ', '#$D#$A +
    FormatFloat('0.0##', e02) + ', ' + FormatFloat('0.0##', e12) + ', ' + FormatFloat('0.0##', e22) + ', ' + FormatFloat('0.0##', e22) + ', '#$D#$A +
    FormatFloat('0.0##', e03) + ', ' + FormatFloat('0.0##', e13) + ', ' + FormatFloat('0.0##', e23) + ', ' + FormatFloat('0.0##', e23) + #$D#$A +
    ')'
  );
end;

function TLabMat.Swizzle(const Remap: TLabSwizzle): TLabMat;
begin
  Result := {Self * LabMat(
    1, 0, 0, 0,
    0, 0, 1, 0,
    0, 1, 0, 0,
    0, 0, 0, 1
  );         }

  LabMat(
    Mat[Remap[0], Remap[0]], Mat[Remap[1], Remap[0]], Mat[Remap[2], Remap[0]], Mat[Remap[3], Remap[0]],
    Mat[Remap[0], Remap[1]], Mat[Remap[1], Remap[1]], Mat[Remap[2], Remap[1]], Mat[Remap[3], Remap[1]],
    Mat[Remap[0], Remap[2]], Mat[Remap[1], Remap[2]], Mat[Remap[2], Remap[2]], Mat[Remap[3], Remap[2]],
    Mat[Remap[0], Remap[3]], Mat[Remap[1], Remap[3]], Mat[Remap[2], Remap[3]], Mat[Remap[3], Remap[3]]
  );
end;
//TLabMat END

//TLabVec2 BEGIN
function TLabVec2.GetArr(const Index: TLabInt32): TLabFloat;
begin
  Result := PLabFloatArr(@x)^[Index];
end;

procedure TLabVec2.SetArr(const Index: TLabInt32; const Value: TLabFloat);
begin
  PLabFloatArr(@x)^[Index] := Value;
end;

procedure TLabVec2.SetValue(const vx, vy: TLabFloat);
begin
  x := vx; y := vy;
end;

procedure TLabVec2.SetZero;
begin
  x := 0; y := 0;
end;

function TLabVec2.Norm: TLabVec2;
begin
  LabVec2Norm(@Result, @Self);
end;

function TLabVec2.Dot(const v: TLabVec2): TLabFloat;
begin
  Result := x * v.x + y * v.y;
end;

function TLabVec2.Cross(const v: TLabVec2): TLabFloat;
begin
  Result := x * v.y - y * v.x;
end;

function TLabVec2.Angle(const v: TLabVec2): TLabFloat;
  var VLen: TLabFloat;
begin
  VLen := Len * v.Len;
  if VLen > 0 then
  Result := LabArcCos(Dot(v) / VLen)
  else
  Result := 0;
end;

function TLabVec2.AngleOX: TLabFloat;
begin
  Result := LabArcTan2(y, x);
end;

function TLabVec2.AngleOY: TLabFloat;
begin
  Result := LabArcTan2(x, y);
end;

function TLabVec2.Len: TLabFloat;
begin
  Result := Sqrt(x * x + y * y);
end;

function TLabVec2.LenSq: TLabFloat;
begin
  Result := x * x + y * y;
end;

function TLabVec2.Perp: TLabVec2;
begin
  {$Warnings off}
  Result.SetValue(-y, x);
  {$Warnings on}
end;

function TLabVec2.Reflect(const n: TLabVec2): TLabVec2;
  var d: TLabFloat;
begin
  d := Dot(n);
  Result := Self - n * (2 * d);
end;

function TLabVec2.Transform3x3(const m: TLabMat): TLabVec2;
begin
  LabVec2MatMul3x3(@Result, @Self, @m);
end;

function TLabVec2.Transform4x3(const m: TLabMat): TLabVec2;
begin
  LabVec2MatMul4x3(@Result, @Self, @m);
end;

function TLabVec2.Transform4x4(const m: TLabMat): TLabVec2;
begin
  LabVec2MatMul4x4(@Result, @Self, @m);
end;

function TLabVec2.AsVec3: TLabVec3Ref;
begin
  Result := LabVec3(x, y, 0);
end;

function TLabVec2.AsVec4: TLabVec4Ref;
begin
  Result := LabVec4(x, y, 0, 0);
end;

function TLabVec2.Swizzle(const Remap: TLabSwizzle): TLabVec2;
begin
  Result := LabVec2(Arr[Remap[0]], Arr[Remap[1]]);
end;
//TLabVec2 END

//TLabVec3 BEGIN
function TLabVec3.GetArr(const Index: TLabInt32): TLabFloat;
begin
  Result := PLabFloatArr(@x)^[Index];
end;

procedure TLabVec3.SetArr(const Index: TLabInt32; const Value: TLabFloat);
begin
  PLabFloatArr(@x)^[Index] := Value;
end;

procedure TLabVec3.SetValue(const vx, vy, vz: TLabFloat);
begin
  x := vx; y := vy; z := vz;
end;

procedure TLabVec3.SetZero;
begin
  x := 0; y := 0; z := 0;
end;

function TLabVec3.Norm: TLabVec3;
begin
  LabVec3Norm(@Result, @Self);
end;

function TLabVec3.Dot(const v: TLabVec3): TLabFloat;
begin
  Result := x * v.x + y * v.y + z * v.z;
end;

function TLabVec3.Cross(const v: TLabVec3): TLabVec3;
begin
  LabVec3Cross(@Result, @Self, @v);
end;

function TLabVec3.Len: TLabFloat;
begin
  Result := LabVec3Len(@Self);
end;

function TLabVec3.LenSq: TLabFloat;
begin
  Result := x * x + y * y + z * z;
end;

function TLabVec3.Transform3x3(const m: TLabMat): TLabVec3;
begin
  LabVec3MatMul3x3(@Result, @Self, @m);
end;

function TLabVec3.Transform4x3(const m: TLabMat): TLabVec3;
begin
  LabVec3MatMul4x3(@Result, @Self, @m);
end;

function TLabVec3.Transform4x4(const m: TLabMat): TLabVec3;
begin
  LabVec3MatMul4x4(@Result, @Self, @m);
end;

function TLabVec3.AsVec4: TLabVec4Ref;
begin
  Result := LabVec4(x, y, z, 0);
end;

function TLabVec3.Swizzle(const Remap: TLabSwizzle): TLabVec3;
begin
  Result := LabVec3(Arr[Remap[0]], Arr[Remap[1]], Arr[Remap[2]]);
end;
//TLabVec3 END

//TLabVec4 BEGIN
function TLabVec4.GetArr(const Index: TLabInt32): TLabFloat;
begin
  Result := PLabFloatArr(@x)^[Index];
end;

procedure TLabVec4.SetArr(const Index: TLabInt32; const Value: TLabFloat);
begin
  PLabFloatArr(@x)^[Index] := Value;
end;

procedure TLabVec4.SetValue(const vx, vy, vz, vw: TLabFloat);
begin
  x := vx; y := vy; z := vz; w := vw;
end;

function TLabVec4.Swizzle(const Remap: TLabSwizzle): TLabVec4;
begin
  Result := LabVec4(Arr[Remap[0]], Arr[Remap[1]], Arr[Remap[2]], Arr[Remap[3]]);
end;
//TLabVec4 END

//TLabQuat BEGIN
function TLabQuat.GetArr(const Index: TLabInt32): TLabFloat;
begin
  Result := PLabFloatArr(@x)^[Index];
end;

procedure TLabQuat.SetArr(const Index: TLabInt32; const Value: TLabFloat);
begin
  PLabFloatArr(@x)^[Index] := Value;
end;

procedure TLabQuat.SetValue(const qx, qy, qz, qw: TLabFloat);
begin
  x := qx; y := qy; z := qz; w := qw;
end;
//TLabQuat END

//TLabBox BEGIN
function TLabBox.GetArr(const Index: TLabInt32): TLabFloat;
begin
  Result := PLabFloatArr(@c.x)^[Index];
end;

procedure TLabBox.SetArr(const Index: TLabInt32; const Value: TLabFloat);
begin
  PLabFloatArr(@c.x)^[Index] := Value;
end;

procedure TLabBox.SetValue(const bc, bx, by, bz: TLabVec3);
begin
  c := bc; vx := bx; vy := by; vz := bz;
end;

function TLabBox.Transform(const m: TLabMat): TLabBox;
begin
  Result.c := c.Transform4x3(m);
  Result.vx := vx.Transform3x3(m);
  Result.vy := vy.Transform3x3(m);
  Result.vz := vz.Transform3x3(m);
end;
//TLabBox END

//TLabAABox BEGIN
function TLabAABox.GetArr(const Index: TLabInt32): TLabFloat;
begin
  Result := PLabFloatArr(@MinV.x)^[Index];
end;

procedure TLabAABox.SetArr(const Index: TLabInt32; const Value: TLabFloat);
begin
  PLabFloatArr(@MinV.x)^[Index] := Value;
end;

function TLabAABox.GetSize: TLabVec3;
begin
  Result := MaxV - MinV;
end;

function TLabAABox.GetSizeX: TLabFloat;
begin
  Result := MaxV.x - MinV.x;
end;

function TLabAABox.GetSizeY: TLabFloat;
begin
  Result := MaxV.y - MinV.y;
end;

function TLabAABox.GetSizeZ: TLabFloat;
begin
  Result := MaxV.z - MinV.z;
end;

procedure TLabAABox.SetValue(const BMinV, BMaxV: TLabVec3);
begin
  MinV := BMinV; MaxV := BMaxV;
end;

procedure TLabAABox.SetValue(const v: TLabVec3);
begin
  MinV := v; MaxV := v;
end;

procedure TLabAABox.Include(const v: TLabVec3);
begin
  if v.x < MinV.x then MinV.x := v.x
  else if v.x > MaxV.x then MaxV.x := v.x;
  if v.y < MinV.y then MinV.y := v.y
  else if v.y > MaxV.y then MaxV.y := v.y;
  if v.z < MinV.z then MinV.z := v.z
  else if v.z > MaxV.z then MaxV.z := v.z;
end;

procedure TLabAABox.Include(const b: TLabAABox);
begin
  if b.MinV.x < MinV.x then MinV.x := b.MinV.x
  else if b.MaxV.x > MaxV.x then MaxV.x := b.MaxV.x;
  if b.MinV.y < MinV.y then MinV.y := b.MinV.y
  else if b.MaxV.y > MaxV.y then MaxV.y := b.MaxV.y;
  if b.MinV.z < MinV.z then MinV.z := b.MinV.z
  else if b.MaxV.z > MaxV.z then MaxV.z := b.MaxV.z;
end;

procedure TLabAABox.Merge(const b: TLabAABox);
begin
  if b.MinV.x < MinV.x then MinV.x := b.MinV.x
  else if b.MaxV.x > MaxV.x then MaxV.x := b.MaxV.x;
  if b.MinV.y < MinV.y then MinV.y := b.MinV.y
  else if b.MaxV.y > MaxV.y then MaxV.y := b.MaxV.y;
  if b.MinV.z < MinV.z then MinV.z := b.MinV.z
  else if b.MaxV.z > MaxV.z then MaxV.z := b.MaxV.z;
end;

function TLabAABox.Intersect(const b: TLabAABox): Boolean;
begin
  Result := (
    (MinV.x < b.MaxV.x)
    and (MinV.y < b.MaxV.y)
    and (MinV.z < b.MaxV.z)
    and (MaxV.x > b.MinV.x)
    and (MaxV.y > b.MinV.y)
    and (MaxV.z > b.MinV.z)
  );
end;
//TLabAABox END

//TLabSphere BEGIN
function TLabSphere.GetArr(const Index: TLabInt32): TLabFloat;
begin
  Result := PLabFloatArr(@c.x)^[Index];
end;

procedure TLabSphere.SetArr(const Index: TLabInt32; const Value: TLabFloat);
begin
  PLabFloatArr(@c.x)^[Index] := Value;
end;

procedure TLabSphere.SetValue(const sc: TLabVec3; const sr: TLabFloat);
begin
  c := sc; r := sr;
end;
//TLabSphere END

//TLabPlane BEGIN
function TLabPlane.GetArr(const Index: TLabInt32): TLabFloat;
begin
  Result := PLabFloatArr(@n.x)^[Index];
end;

procedure TLabPlane.SetArr(const Index: TLabInt32; const Value: TLabFloat);
begin
  PLabFloatArr(@n.x)^[Index] := Value;
end;

function TLabPlane.GetA: TLabFloat;
begin
  Result := n.x;
end;

procedure TLabPlane.SetA(const Value: TLabFloat);
begin
  n.x := Value;
end;

function TLabPlane.GetB: TLabFloat;
begin
  Result := n.y;
end;

procedure TLabPlane.SetB(const Value: TLabFloat);
begin
  n.y := Value;
end;

function TLabPlane.GetC: TLabFloat;
begin
  Result := n.z;
end;

procedure TLabPlane.SetC(const Value: TLabFloat);
begin
  n.z := Value;
end;

procedure TLabPlane.SetValue(const pa, pb, pc, pd: TLabFloat);
begin
  n.x := pa; n.y := pb; n.z := pc; d := pd;
end;

procedure TLabPlane.SetValue(const pn: TLabVec3; const pd: TLabFloat);
begin
  n := pn; d := pd;
end;

procedure TLabPlane.SetValue(const v0, v1, v2: TLabVec3);
begin
  n := LabTriangleNormal(v0, v1, v2);
  d := n.Dot(v0);
end;
//TLabPlane END

//TLabRay3 BEGIN
function TLabRay3.GetArr(const Index: TLabInt32): TLabFloat;
begin
  Result := PLabFloatArr(@Origin.x)^[Index];
end;

procedure TLabRay3.SetArr(const Index: TLabInt32; const Value: TLabFloat);
begin
  PLabFloatArr(@Origin.x)^[Index] := Value;
end;

procedure TLabRay3.SetValue(const ROrigin, RDir: TLabVec3);
begin
  Origin := ROrigin; Dir := RDir;
end;
//TLabRay3 END

//TLabFrustum BEGIN
function TLabFrustum.GetPlane(const Index: TLabInt32): PLabPlane;
begin
  Result := @_Planes[Index];
end;

procedure TLabFrustum.Normalize;
  var i: TLabInt32;
  var Rcp: TLabFloat;
begin
  for i := 0 to 5 do
  begin
    Rcp := 1 / LabVec3Len(@_Planes[i].n);
    _Planes[i].N.x := _Planes[i].N.x * Rcp;
    _Planes[i].N.y := _Planes[i].N.y * Rcp;
    _Planes[i].N.z := _Planes[i].N.z * Rcp;
    _Planes[i].D := _Planes[i].D * Rcp;
  end;
end;

function TLabFrustum.DistanceToPoint(const PlaneIndex: TLabInt32; const Pt: TLabVec3): TLabFloat;
begin
  Result := _Planes[PlaneIndex].n.Dot(Pt) + _Planes[PlaneIndex].d;
end;

procedure TLabFrustum.Update;
  var m: TLabMat;
begin
  LabMatMul(@m, _RefV, _RefP);
  //Left plane
  _Planes[0].N.x := m.e03 + m.e00;
  _Planes[0].N.y := m.e13 + m.e10;
  _Planes[0].N.z := m.e23 + m.e20;
  _Planes[0].D := m.e33 + m.e30;

  //Right plane
  _Planes[1].N.x := m.e03 - m.e00;
  _Planes[1].N.y := m.e13 - m.e10;
  _Planes[1].N.z := m.e23 - m.e20;
  _Planes[1].D := m.e33 - m.e30;

  //Top plane
  _Planes[2].N.x := m.e03 - m.e01;
  _Planes[2].N.y := m.e13 - m.e11;
  _Planes[2].N.z := m.e23 - m.e21;
  _Planes[2].D := m.e33 - m.e31;

  //Bottom plane
  _Planes[3].N.x := m.e03 + m.e01;
  _Planes[3].N.y := m.e13 + m.e11;
  _Planes[3].N.z := m.e23 + m.e21;
  _Planes[3].D := m.e33 + m.e31;

  //Near plane
  _Planes[4].N.x := m.e02;
  _Planes[4].N.y := m.e12;
  _Planes[4].N.z := m.e22;
  _Planes[4].D := m.e32;

  //Far plane
  _Planes[5].N.x := m.e03 - m.e02;
  _Planes[5].N.y := m.e13 - m.e12;
  _Planes[5].N.z := m.e23 - m.e22;
  _Planes[5].D := m.e33 - m.e32;

  Normalize;
end;

procedure TLabFrustum.ExtractPoints(const OutV: PLabVec3);
  var pv: PLabVec3;
begin
  pv := OutV;
  //0 - Left
  //1 - Right
  //2 - Top
  //3 - Bottom
  //4 - Near
  //5 - Far
  LabIntersect3Planes(_Planes[4], _Planes[0], _Planes[2], pv^); Inc(pv);
  LabIntersect3Planes(_Planes[5], _Planes[0], _Planes[2], pv^); Inc(pv);
  LabIntersect3Planes(_Planes[4], _Planes[2], _Planes[1], pv^); Inc(pv);
  LabIntersect3Planes(_Planes[5], _Planes[2], _Planes[1], pv^); Inc(pv);
  LabIntersect3Planes(_Planes[4], _Planes[1], _Planes[3], pv^); Inc(pv);
  LabIntersect3Planes(_Planes[5], _Planes[1], _Planes[3], pv^); Inc(pv);
  LabIntersect3Planes(_Planes[4], _Planes[3], _Planes[0], pv^); Inc(pv);
  LabIntersect3Planes(_Planes[5], _Planes[3], _Planes[0], pv^);
end;

function TLabFrustum.IntersectFrustum(const Frustum: TLabFrustum): Boolean;
  function FrustumOutside(const f1, f2: TLabFrustum): Boolean;
    var Points: array[0..7] of TLabVec3;
    var i, j, n: TLabInt32;
  begin
    f2.ExtractPoints(@Points[0]);
    for i := 0 to 5 do
    begin
      n := 0;
      for j := 0 to 7 do
      begin
        if f1.DistanceToPoint(i, Points[j]) < 0 then
        Inc(n);
      end;
      if n >= 8 then
      begin
        Result := True;
        Exit;
      end;
    end;
    Result := False;
  end;
begin
  Result := (
    (not FrustumOutside(Self, Frustum))
    and (not FrustumOutside(Frustum, Self))
  );
end;

function TLabFrustum.CheckSphere(const Center: TLabVec3; const Radius: TLabFloat): TLabFrustumCheck;
  var i: TLabInt32;
  var d: TLabFloat;
begin
  Result := fc_inside;
  for i := 0 to 5 do
  begin
    d := DistanceToPoint(i, Center);
    if d < -Radius then
    begin
      Result := fc_outside;
      Exit;
    end;
    if d < Radius then
    Result := fc_intersect;
  end;
end;

function TLabFrustum.CheckSphere(const Sphere: TLabSphere): TLabFrustumCheck;
begin
  Result := CheckSphere(Sphere.c, Sphere.r);
end;

function TLabFrustum.CheckBox(const MinV, MaxV: TLabVec3): TLabFrustumCheck;
  var i: TLabInt32;
  var MaxPt, MinPt: TLabVec3;
begin
  Result := fc_inside;
  for i := 0 to 5 do
  begin
    if _Planes[i].N.x <= 0 then
    begin
      MinPt.x := MinV.x;
      MaxPt.x := MaxV.x;
    end
    else
    begin
      MinPt.x := MaxV.x;
      MaxPt.x := MinV.x;
    end;
    if _Planes[i].N.y <= 0 then
    begin
      MinPt.y := MinV.y;
      MaxPt.y := MaxV.y;
    end
    else
    begin
      MinPt.y := MaxV.y;
      MaxPt.y := MinV.y;
    end;
    if _Planes[i].N.z <= 0 then
    begin
      MinPt.z := MinV.z;
      MaxPt.z := MaxV.z;
    end
    else
    begin
      MinPt.z :=MaxV.z;
      MaxPt.z :=MinV.z;
    end;
    if DistanceToPoint(i, MinPt) < 0 then
    begin
      Result := fc_outside;
      Exit;
    end;
    if DistanceToPoint(i, MaxPt) <= 0 then
    Result := fc_intersect;
  end;
end;

function TLabFrustum.CheckBox(const Box: TLabAABox): TLabFrustumCheck;
begin
  Result := CheckBox(Box.MinV, Box.MaxV);
end;
//TLabFrustum END

//TLabRect BEGIN
procedure TLabRect.SetX(const Value: TLabFloat);
  var d: TLabFloat;
begin
  d := w;
  Left := Value;
  w := d;
end;

procedure TLabRect.SetY(const Value: TLabFloat);
  var d: TLabFloat;
begin
  d := h;
  Top := Value;
  h := d;
end;

procedure TLabRect.SetWidth(const Value: TLabFloat);
begin
  Right := Left + Value;
end;

function TLabRect.GetWidth: TLabFloat;
begin
  Result := Right - Left;
end;

procedure TLabRect.SetHeight(const Value: TLabFloat);
begin
  Bottom := Top + Value;
end;

function TLabRect.GetHeight: TLabFloat;
begin
  Result := Bottom - Top;
end;

procedure TLabRect.SetTopLeft(const Value: TLabVec2);
begin
  Left := Value.x;
  Top := Value.y;
end;

function TLabRect.GetTopLeft: TLabVec2;
begin
  {$Warnings off}
  Result.SetValue(Left, Top);
  {$Warnings on}
end;

procedure TLabRect.SetTopRight(const Value: TLabVec2);
begin
  Top := Value.y;
  Right := Value.x;
end;

function TLabRect.GetTopRight: TLabVec2;
begin
  {$Warnings off}
  Result.SetValue(Right, Top);
  {$Warnings on}
end;

procedure TLabRect.SetBottomLeft(const Value: TLabVec2);
begin
  Left := Value.x;
  Bottom := Value.y;
end;

function TLabRect.GetBottomLeft: TLabVec2;
begin
  {$Warnings off}
  Result.SetValue(Left, Bottom);
  {$Warnings on}
end;

procedure TLabRect.SetBottomRight(const Value: TLabVec2);
begin
  Right := Value.x;
  Bottom := Value.y;
end;

function TLabRect.GetBottomRight: TLabVec2;
begin
  {$Warnings off}
  Result.SetValue(Right, Bottom);
  {$Warnings on}
end;

function TLabRect.GetCenter: TLabVec2;
begin
  {$Warnings off}
  Result.SetValue((l + r) * 0.5, (t + b) * 0.5);
  {$Warnings on}
end;

function TLabRect.Contains(const v: TLabVec2): Boolean;
begin
  Result := Contains(v.x, v.y);
end;

function TLabRect.Contains(const vx, vy: TLabFloat): Boolean;
begin
  Result := (vx > l) and (vx < r) and (vy > t) and (vy < b);
end;

function TLabRect.Clip(const ClipRect: TLabRect): TLabRect;
begin
  Result.l := LabMax(l, ClipRect.l);
  Result.t := LabMax(t, ClipRect.t);
  Result.r := LabMin(r, ClipRect.r);
  Result.b := LabMin(b, ClipRect.b);
end;

function TLabRect.Expand(const Dimensions: TLabVec2): TLabRect;
begin
  Result := Expand(Dimensions.x, Dimensions.y);
end;

function TLabRect.Expand(const dx, dy: TLabFloat): TLabRect;
begin
  Result.l := l - dx;
  Result.t := t - dy;
  Result.r := r + dx;
  Result.b := b + dy;
end;
//TLabRect END

//TLabRotation2 BEGIN
function TLabRotation2.GetAngle: TLabFloat;
begin
  Result := LabArcTan2(s, c);
end;

{$Warnings off}
function TLabRotation2.GetAxisX: TLabVec2;
begin
  Result.SetValue(c, s);
end;
{$Warnings on}

procedure TLabRotation2.SetAxisX(const Value: TLabVec2);
begin
  s := Value.y;
  c := Value.x;
end;

{$Warnings off}
function TLabRotation2.GetAxisY: TLabVec2;
begin
  Result.SetValue(-s, c);
end;
{$Warnings on}

procedure TLabRotation2.SetAxisY(const Value: TLabVec2);
begin
  s := -Value.x; c := Value.y;
end;

procedure TLabRotation2.SetAngle(const Angle: TLabFloat);
begin
  LabSinCos(Angle, s, c);
end;

procedure TLabRotation2.SetValue(const rs, rc: TLabFloat);
begin
  s := rs; c := rc;
end;

procedure TLabRotation2.SetIdentity;
begin
  s := 0; c := 1;
end;

procedure TLabRotation2.Normalize;
begin
  LabVec2Norm(@Self, @Self);
end;

function TLabRotation2.Transform(const v: TLabVec2): TLabVec2;
begin
  LabVec2Rotation2Mul(@Result, @v, @Self);
end;

function TLabRotation2.TransformInv(const v: TLabVec2): TLabVec2;
begin
  LabVec2Rotation2MulInv(@Result, @v, @Self);
end;
//TLabRotation2 END

//TLabTransform2 BEGIN
procedure TLabTransform2.SetValue(const tp: TLabVec2; const tr: TLabRotation2);
begin
  p := tp; r := tr;
end;

procedure TLabTransform2.SetIdentity;
begin
  p.SetZero;
  r.SetIdentity;
end;

function TLabTransform2.Transform(const v: TLabVec2): TLabVec2;
begin
  LabVec2Transform2Mul(@Result, @v, @Self);
end;

function TLabTransform2.TransformInv(const v: TLabVec2): TLabVec2;
begin
  LabVec2Transform2MulInv(@Result, @v, @Self);
end;
//TLabTransform2 END

operator := (v: TLabVec2): TLabVec2Ref;
begin
  Result[0] := v.x; Result[1] := v.y;
end;

operator := (vr: TLabVec2Ref): TLabVec2;
begin
  Result.x := vr[0]; Result.y := vr[1];
end;

operator := (v: TLabVec2): TPoint;
begin
  Result.x := Round(v.x);
  Result.y := Round(v.y);
end;

operator := (p: TPoint): TLabVec2;
begin
  Result.x := p.x;
  Result.y := p.y;
end;

operator := (v: TLabVec3): TLabVec3Ref;
begin
  Result[0] := v.x; Result[1] := v.y; Result[2] := v.z;
end;

operator := (vr: TLabVec3Ref): TLabVec3;
begin
  Result.x := vr[0]; Result.y := vr[1]; Result.z := vr[2];
end;

operator := (v: TLabVec4): TLabVec4Ref;
begin
  Result[0] := v.x; Result[1] := v.y; Result[2] := v.z; Result[3] := v.w;
end;

operator := (vr: TLabVec4Ref): TLabVec4;
begin
  Result.x := vr[0]; Result.y := vr[1]; Result.z := vr[2]; Result.w := vr[3];
end;

operator := (m: TLabMat): TLabMatRef;
begin
  Result[0] := m.e00; Result[1] := m.e10; Result[2] := m.e20; Result[3] := m.e30;
  Result[4] := m.e01; Result[5] := m.e11; Result[6] := m.e21; Result[7] := m.e31;
  Result[8] := m.e02; Result[9] := m.e12; Result[10] := m.e22; Result[11] := m.e32;
  Result[12] := m.e03; Result[13] := m.e13; Result[14] := m.e23; Result[15] := m.e33;
end;

operator := (mr: TLabMatRef): TLabMat;
begin
  Result.e00 := mr[0]; Result.e10 := mr[1]; Result.e20 := mr[2]; Result.e30 := mr[3];
  Result.e01 := mr[4]; Result.e11 := mr[5]; Result.e21 := mr[6]; Result.e31 := mr[7];
  Result.e02 := mr[8]; Result.e12 := mr[9]; Result.e22 := mr[10]; Result.e32 := mr[11];
  Result.e03 := mr[12]; Result.e13 := mr[13]; Result.e23 := mr[14]; Result.e33 := mr[15];
end;

operator := (r: TLabRect): TRect;
begin
  Result.Left := Round(r.l);
  Result.Top := Round(r.t);
  Result.Right := Round(r.r);
  Result.Bottom := Round(r.b);
end;

operator := (r: TRect): TLabRect;
begin
  Result.l := r.Left;
  Result.t := r.Top;
  Result.r := r.Right;
  Result.b := r.Bottom;
end;

operator := (b: TLabBox): TLabAABox;
var
  i: TLabInt32;
  v: array[0..7] of TLabVec3;
begin
  v[0] := b.c + b.vx + b.vy + b.vz;
  v[1] := b.c + b.vx + b.vy - b.vz;
  v[2] := b.c - b.vx + b.vy - b.vz;
  v[3] := b.c - b.vx + b.vy + b.vz;
  v[4] := b.c + b.vx - b.vy + b.vz;
  v[5] := b.c + b.vx - b.vy - b.vz;
  v[6] := b.c - b.vx - b.vy - b.vz;
  v[7] := b.c - b.vx - b.vy + b.vz;
  Result.MinV := v[0];
  Result.MaxV := v[0];
  for i := 1 to 7 do
  begin
    if v[i].x < Result.MinV.x then Result.MinV.x := v[i].x;
    if v[i].y < Result.MinV.y then Result.MinV.y := v[i].y;
    if v[i].z < Result.MinV.z then Result.MinV.z := v[i].z;
    if v[i].x > Result.MaxV.x then Result.MaxV.x := v[i].x;
    if v[i].y > Result.MaxV.y then Result.MaxV.y := v[i].y;
    if v[i].z > Result.MaxV.z then Result.MaxV.z := v[i].z;
  end;
end;

operator := (b: TLabAABox): TLabBox;
  var v: TLabVec3;
begin
  Result.c := (b.MinV + b.MaxV) * 0.5;
  v := (b.MaxV - b.MinV) * 0.5;
  Result.vx.SetValue(v.x, 0, 0);
  Result.vy.SetValue(0, v.y, 0);
  Result.vz.SetValue(0, 0, v.z);
end;

operator := (r: TLabRotation2): TLabFloat;
begin
  Result := r.Angle;
end;

operator := (a: TLabFloat): TLabRotation2;
begin
  Result.Angle := a;
end;

operator - (v: TLabVec2): TLabVec2;
begin
  Result.x := -v.x;
  Result.y := -v.y;
end;

operator - (v: TLabVec3): TLabVec3;
begin
  Result.x := -v.x;
  Result.y := -v.y;
  Result.z := -v.z;
end;

operator - (v0, v1: TLabVec2): TLabVec2;
begin
  Result.x := v0.x - v1.x;
  Result.y := v0.y - v1.y;
end;

operator - (v0, v1: TLabVec3): TLabVec3;
begin
  Result.x := v0.x - v1.x;
  Result.y := v0.y - v1.y;
  Result.z := v0.z - v1.z;
end;

operator - (v: TLabVec2; f: TLabFloat): TLabVec2;
begin
  Result.x := v.x - f;
  Result.y := v.y - f;
end;

operator - (v: TLabVec3; f: TLabFloat): TLabVec3;
begin
  Result.x := v.x - f;
  Result.y := v.y - f;
  Result.z := v.z - f;
end;

operator - (v: TLabVec4; f: TLabFloat): TLabVec4;
begin
  Result.x := v.x - f;
  Result.y := v.y - f;
  Result.z := v.z - f;
  Result.w := v.w - f;
end;

operator - (v: TLabVec2; p: TPoint): TLabVec2;
begin
  Result.x := v.x - p.x;
  Result.y := v.y - p.y;
end;

operator - (p: TPoint; v: TLabVec2): TLabVec2;
begin
  Result.x := p.x - v.x;
  Result.y := p.y - v.y;
end;

operator + (v0, v1: TLabVec2): TLabVec2;
begin
  Result.x := v0.x + v1.x;
  Result.y := v0.y + v1.y;
end;

operator + (v0, v1: TLabVec3): TLabVec3;
begin
  Result.x := v0.x + v1.x;
  Result.y := v0.y + v1.y;
  Result.z := v0.z + v1.z;
end;

operator + (v: TLabVec2; f: TLabFloat): TLabVec2;
begin
  Result.x := v.x + f;
  Result.y := v.y + f;
end;

operator + (v: TLabVec3; f: TLabFloat): TLabVec3;
begin
  Result.x := v.x + f;
  Result.y := v.y + f;
  Result.z := v.z + f;
end;

operator + (v: TLabVec4; f: TLabFloat): TLabVec4;
begin
  Result.x := v.x + f;
  Result.y := v.y + f;
  Result.z := v.z + f;
  Result.w := v.w + f;
end;

operator + (f: TLabFloat; v: TLabVec2): TLabVec2;
begin
  Result.x := v.x + f;
  Result.y := v.y + f;
end;

operator + (f: TLabFloat; v: TLabVec3): TLabVec3;
begin
  Result.x := v.x + f;
  Result.y := v.y + f;
  Result.z := v.z + f;
end;

operator + (f: TLabFloat; v: TLabVec4): TLabVec4;
begin
  Result.x := v.x + f;
  Result.y := v.y + f;
  Result.z := v.z + f;
  Result.w := v.w + f;
end;

operator + (b: TLabAABox; v: TLabVec3): TLabAABox;
begin
  Result.MinV := b.MinV;
  Result.MaxV := b.MaxV;
  if v.x < Result.MinV.x then Result.MinV.x := v.x
  else if v.x > Result.MaxV.x then Result.MaxV.x := v.x;
  if v.y < Result.MinV.y then Result.MinV.y := v.y
  else if v.y > Result.MaxV.y then Result.MaxV.y := v.y;
  if v.z < Result.MinV.z then Result.MinV.z := v.z
  else if v.z > Result.MaxV.z then Result.MaxV.z := v.z;
end;

operator + (v: TLabVec2; p: TPoint): TLabVec2;
begin
  Result.x := v.x + p.x;
  Result.y := v.y + p.y;
end;

operator + (p: TPoint; v: TLabVec2): TLabVec2;
begin
  Result.x := v.x + p.x;
  Result.y := v.y + p.y;
end;

operator * (v: TLabVec2; f: TLabFloat): TLabVec2;
begin
  Result.x := v.x * f;
  Result.y := v.y * f;
end;

operator * (v: TLabVec3; f: TLabFloat): TLabVec3;
begin
  Result.x := v.x * f;
  Result.y := v.y * f;
  Result.z := v.z * f;
end;

operator * (v: TLabVec4; f: TLabFloat): TLabVec4;
begin
  Result.x := v.x * f;
  Result.y := v.y * f;
  Result.z := v.z * f;
  Result.w := v.w * f;
end;

operator * (f: TLabFloat; v: TLabVec2): TLabVec2;
begin
  Result.x := v.x * f;
  Result.y := v.y * f;
end;

operator * (f: TLabFloat; v: TLabVec3): TLabVec3;
begin
  Result.x := v.x * f;
  Result.y := v.y * f;
  Result.z := v.z * f;
end;

operator * (f: TLabFloat; v: TLabVec4): TLabVec4;
begin
  Result.x := v.x * f;
  Result.y := v.y * f;
  Result.z := v.z * f;
  Result.w := v.w * f;
end;

operator * (v0: TLabVec2; v1: TLabVec2): TLabVec2;
begin
  Result.x := v0.x * v1.x;
  Result.y := v0.y * v1.y;
end;

operator * (v0: TLabVec3; v1: TLabVec3): TLabVec3;
begin
  Result.x := v0.x * v1.x;
  Result.y := v0.y * v1.y;
  Result.z := v0.z * v1.z;
end;

operator * (v0: TLabVec4; v1: TLabVec4): TLabVec4;
begin
  Result.x := v0.x * v1.x;
  Result.y := v0.y * v1.y;
  Result.z := v0.z * v1.z;
  Result.w := v0.w * v1.w;
end;

operator * (v: TLabVec2; m: TLabMat): TLabVec2;
begin
  LabVec2MatMul4x3(@Result, @v, @m);
end;

operator * (v: TLabVec3; m: TLabMat): TLabVec3;
begin
  LabVec3MatMul4x3(@Result, @v, @m);
end;

operator * (m0, m1: TLabMat): TLabMat;
begin
  LabMatMul(@Result, @m0, @m1);
end;

operator / (v: TLabVec2; f: TLabFloat): TLabVec2;
  var RcpF: TLabFloat;
begin
  RcpF := 1 / f;
  Result.x := v.x * RcpF;
  Result.y := v.y * RcpF;
end;

operator / (v: TLabVec3; f: TLabFloat): TLabVec3;
  var RcpF: TLabFloat;
begin
  RcpF := 1 / f;
  Result.x := v.x * RcpF;
  Result.y := v.y * RcpF;
  Result.z := v.z * RcpF;
end;

operator = (v0, v1: TLabVec2): Boolean;
begin
  Result := (Abs(v0.x - v1.x) < LabEPS) and (Abs(v0.y - v1.y) < LabEPS);
end;

operator = (v0, v1: TLabVec3): Boolean;
begin
  Result := (Abs(v0.x - v1.x) < LabEPS) and (Abs(v0.y - v1.y) < LabEPS) and (Abs(v0.z - v1.z) < LabEPS);
end;

operator = (v0, v1: TLabVec4): Boolean;
begin
  Result := (Abs(v0.x - v1.x) < LabEPS) and (Abs(v0.y - v1.y) < LabEPS) and (Abs(v0.z - v1.z) < LabEPS) and (Abs(v0.w - v1.w) < LabEPS);
end;

operator = (q0, q1: TLabQuat): Boolean;
begin
  Result := (Abs(q0.x - q1.x) < LabEPS) and (Abs(q0.y - q1.y) < LabEPS) and (Abs(q0.z - q1.z) < LabEPS) and (Abs(q0.w - q1.w) < LabEPS);
end;

operator = (m0, m1: TLabMat): Boolean;
  var i: Integer;
begin
  for i := 0 to 15 do
  if Abs(m0.Arr[i] - m1.Arr[i]) >= LabEPS then Exit(False);
  Result := True;
end;

operator mod(const a, b: Double): Double; inline;
begin
  Result := a - b * Int(a / b);
end;

operator mod(const a, b: Single): Single; inline;
begin
  Result := a - b * Int(a / b);
end;

{$Warnings off}

function LabSwizzle(
  const ord0: TLabUInt8;
  const ord1: TLabUInt8;
  const ord2: TLabUInt8;
  const ord3: TLabUInt8
): TLabSwizzle;
begin
  Result.SetValue(ord0, ord1, ord2, ord3);
end;

function LabRect(const x, y, w, h: TLabFloat): TLabRect;
begin
  Result.x := x;
  Result.y := y;
  Result.w := w;
  Result.h := h;
end;
{$Warnings off}

function LabVec2: TLabVec2;
begin
  Result.x := 0; Result.y := 0;
end;

function LabVec2(const x, y: TLabFloat): TLabVec2;
begin
  Result.x := x; Result.y := y;
end;

function LabVec2(const pt: TPoint): TLabVec2;
begin
  Result.x := pt.x; Result.y := pt.y;
end;

function LabVec2InRect(const v: TLabVec2; const r: TLabRect): Boolean;
begin
  Result := (
    (v.x >= r.l)
    and (v.x <= r.r)
    and (v.y >= r.t)
    and (v.y <= r.b)
  );
end;

function LabVec2InPoly(const v: TLabVec2; const VArr: PLabVec2; const VCount: TLabInt32): Boolean;
var
  i: TLabInt32;
  pi, pj: PLabVec2;
begin
  Result := False;
  if VCount < 3 then Exit;
  pj := @PLabVec2Arr(VArr)^[VCount - 1];
  for i := 0 to VCount - 1 do
  begin
    pi := @PLabVec2Arr(VArr)^[i];
    if (((pi^.y <= v.y) and (v.y < pj^.y)) or ((pj^.y <= v.y) and (v.y < pi^.y)))
    and (v.x < (pj^.x - pi^.x) * (v.y - pi^.y) / (pj^.y - pi^.y) + pi^.x) then
    Result := not Result;
    pj := pi;
  end;
end;

function LabVec3: TLabVec3;
begin
  Result.x := 0; Result.y := 0; Result.z := 0;
end;

function LabVec3(const x, y, z: TLabFloat): TLabVec3;
begin
  Result.x := x; Result.y := y; Result.z := z;
end;

function LabVec3(const v2: TLabVec2; const z: TLabFloat): TLabVec3;
begin
  Result.x := v2.x; Result.y := v2.y; Result.z := z;
end;

function LabVec4: TLabVec4;
begin
  Result.x := 0; Result.y := 0; Result.z := 0; Result.w := 0;
end;

function LabVec4(const x, y, z, w: TLabFloat): TLabVec4;
begin
  Result.x := x; Result.y := y; Result.z := z; Result.w := w;
end;

function LabRotation2: TLabRotation2;
begin
  Result.SetIdentity;
end;

function LabRotation2(const s, c: TLabFloat): TLabRotation2;
begin
  Result.SetValue(s, c);
end;

function LabRotation2(const Angle: TLabFloat): TLabRotation2;
begin
  Result.SetAngle(Angle);
end;

function LabTransform2: TLabTransform2;
begin
  Result.SetIdentity;
end;

function LabTransform2(const p: TLabVec2; const r: TLabRotation2): TLabTransform2;
begin
  Result.p := p; Result.r := r;
end;

function LabQuat: TLabQuat;
begin
  Result.x := 0; Result.y := 0; Result.z := 0; Result.w := 1;
end;

function LabQuat(const x, y, z, w: TLabFloat): TLabQuat;
begin
  Result.x := x; Result.y := y; Result.z := z; Result.w := w;
end;

function LabQuat(const Axis: TLabVec3; const Angle: TLabFloat): TLabQuat;
  var AxisNorm: TLabVec3;
  var s, c: TLabFloat;
begin
  {$Hints off}
  AxisNorm := Axis.Norm;
  LabSinCos(Angle * 0.5, s, c);
  Result.x := s * AxisNorm.x;
  Result.y := s * AxisNorm.y;
  Result.z := s * AxisNorm.z;
  Result.w := c;
  {$Hints on}
end;

function LabQuat(const m: TLabMat): TLabQuat;
  var Trace, SqrtTrace, RcpSqrtTrace, MaxDiag, s: TLabFloat;
  var MaxI, i: TLabInt32;
begin
  Trace := m.e00 + m.e11 + m.e22 + 1;
  if Trace > 0 then
  begin
    SqrtTrace := Sqrt(Trace);
    RcpSqrtTrace := 0.5 / SqrtTrace;
    Result.x := (m.e12 - m.e21) * RcpSqrtTrace;
    Result.y := (m.e20 - m.e02) * RcpSqrtTrace;
    Result.z := (m.e01 - m.e10) * RcpSqrtTrace;
    Result.w := SqrtTrace * 0.5;
    Exit;
  end;
  MaxI := 0;
  MaxDiag := m.e00;
  for i := 1 to 2 do
  if m.Mat[i, i] > MaxDiag then
  begin
    MaxI := i;
    MaxDiag := m.Mat[i, i];
  end;
  case MaxI of
    0:
    begin
      s := 2 * Sqrt(1 + m.e00 - m.e11 - m.e22);
      Result.x := 0.25 * s; s := 1 / s;
      Result.y := (m.e01 + m.e10) * s;
      Result.z := (m.e02 + m.e20) * s;
      Result.w := (m.e12 - m.e21) * s;
    end;
    1:
    begin
      s := 2 * Sqrt(1 + m.e11 - m.e00 - m.e22);
      Result.y := 0.25 * s; s := 1 / s;
      Result.x := (m.e01 + m.e10) * s;
      Result.z := (m.e12 + m.e21) * s;
      Result.w := (m.e20 - m.e02) * s;
    end;
    2:
    begin
      s := 2 * Sqrt(1 + m.e22 - m.e00 - m.e11);
      Result.z := 0.25 * s; s := 1 / s;
      Result.x := (m.e02 + m.e20) * s;
      Result.y := (m.e12 + m.e21) * s;
      Result.w := (m.e01 - m.e10) * s;
    end;
  end;
end;

function LabQuatDot(const q0, q1: TLabQuat): TLabFloat;
begin
  Result := q0.x * q1.x + q0.y * q1.y + q0.z * q1.z + q0.w * q1.w;
end;

function LabQuatSlerp(const q0, q1: TLabQuat; const s: TLabFloat): TLabQuat;
  var SinTh, CosTh, Th, ra, rb: TLabFloat;
  var qa, qb: TLabQuat;
begin
  qa := q0;
  qb := q1;
  CosTh := qa.x * qb.x + qa.y * qb.y + qa.z * qb.z + qa.w * qb.w;
  if CosTh < 0 then
  begin
    qb.x := -qb.x; qb.y := -qb.y; qb.z := -qb.z;
    CosTh := -CosTh;
  end;
  if CosTh >= 1.0 then
  begin
    Result := qa;
    Exit;
  end;
  Th := LabArcCos(CosTh);
  SinTh := Sin(Th);
  ra := Sin((1 - s) * Th) / SinTh;
  rb := Sin(s * Th) / SinTh;
  Result.x := qa.x * ra + qb.x * rb;
  Result.y := qa.y * ra + qb.y * rb;
  Result.z := qa.z * ra + qb.z * rb;
  Result.w := qa.w * ra + qb.w * rb;
end;

function LabMat(
  const m00, m10, m20, m30: TLabFloat;
  const m01, m11, m21, m31: TLabFloat;
  const m02, m12, m22, m32: TLabFloat;
  const m03, m13, m23, m33: TLabFloat
): TLabMat;
begin
  {$Warnings off}
  Result.SetValue(
    m00, m10, m20, m30,
    m01, m11, m21, m31,
    m02, m12, m22, m32,
    m03, m13, m23, m33
  );
  {$Warnings on}
end;

function LabMat(const AxisX, AxisY, AxisZ, Translation: TLabVec3): TLabMat;
begin
  {$Warnings off}
  Result.SetValue(
    AxisX.x, AxisY.x, AxisZ.x, Translation.x,
    AxisX.y, AxisY.y, AxisZ.y, Translation.y,
    AxisX.z, AxisY.z, AxisZ.z, Translation.z,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatIdentity: TLabMat;
begin
  {$Warnings off}
  Result.SetValue(
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatZero: TLabMat;
begin
  {$Warnings off}
  Result.SetValue(
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0
  );
  {$Warnings on}
end;

function LabMatScaling(const x, y, z: TLabFloat): TLabMat;
begin
  {$Warnings off}
  Result.SetValue(
    x, 0, 0, 0,
    0, y, 0, 0,
    0, 0, z, 0,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatScaling(const v: TLabVec3): TLabMat;
begin
  {$Warnings off}
  Result.SetValue(
    v.x, 0, 0, 0,
    0, v.y, 0, 0,
    0, 0, v.z, 0,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatScaling(const s: TLabFloat): TLabMat;
begin
  {$Warnings off}
  Result.SetValue(
    s, 0, 0, 0,
    0, s, 0, 0,
    0, 0, s, 0,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatTranslation(const x, y, z: TLabFloat): TLabMat;
begin
  {$Warnings off}
  Result.SetValue(
    1, 0, 0, x,
    0, 1, 0, y,
    0, 0, 1, z,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatTranslation(const v: TLabVec3): TLabMat;
begin
  {$Warnings off}
  Result.SetValue(
    1, 0, 0, v.x,
    0, 1, 0, v.y,
    0, 0, 1, v.z,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatRotationX(const a: TLabFloat): TLabMat;
  var s, c: TLabFloat;
begin
  {$Hints off}
  LabSinCos(a, s, c);
  {$Hints on}
  {$Warnings off}
  Result.SetValue(
    1, 0, 0, 0,
    0, c, -s, 0,
    0, s, c, 0,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatRotationY(const a: TLabFloat): TLabMat;
  var s, c: TLabFloat;
begin
  {$Hints off}
  LabSinCos(a, s, c);
  {$Hints on}
  {$Warnings off}
  Result.SetValue(
    c, 0, s, 0,
    0, 1, 0, 0,
    -s, 0, c, 0,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatRotationZ(const a: TLabFloat): TLabMat;
  var s, c: TLabFloat;
begin
  {$Hints off}
  LabSinCos(a, s, c);
  {$Hints on}
  {$Warnings off}
  Result.SetValue(
    c, -s, 0, 0,
    s, c, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatRotation(const x, y, z, a: TLabFloat): TLabMat;
begin
  Result := LabMatRotation(LabVec3(x, y, z), a);
end;

function LabMatRotation(const v: TLabVec3; const a: TLabFloat): TLabMat;
  var vr: TLabVec3;
  var s, c, cr, xs, ys, zs, crxy, crxz, cryz: TLabFloat;
begin
  LabVec3Norm(@vr, @v);
  {$Hints off}
  LabSinCos(a, s, c);
  {$Hints on}
  cr := 1 - c;
  xs := vr.x * s;
  ys := vr.y * s;
  zs := vr.z * s;
  crxy := cr * vr.x * vr.y;
  crxz := cr * vr.x * vr.z;
  cryz := cr * vr.y * vr.z;
  {$Warnings off}
  Result.SetValue(
    cr * v.x * v.x + c, -zs + crxy, ys + crxz, 0,
    zs + crxy, cr * v.y * v.y + c, -xs + cryz, 0,
    -ys + crxz, xs + cryz, cr * v.z * v.z + c, 0,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatRotation(const q: TLabQuat): TLabMat;
  var xx, yy, zz, xy, xz, yz, wx, wy, wz: TLabFloat;
begin
  xx := 2 * q.x * q.x;
  yy := 2 * q.y * q.y;
  zz := 2 * q.z * q.z;
  xy := 2 * q.x * q.y;
  xz := 2 * q.x * q.z;
  yz := 2 * q.y * q.z;
  wx := 2 * q.w * q.x;
  wy := 2 * q.w * q.y;
  wz := 2 * q.w * q.z;
  {$Warnings off}
  Result.SetValue(
    1 - yy - zz, xy - wz, xz + wy, 0,
    xy + wz, 1 - xx - zz, yz - wx, 0,
    xz - wy, yz + wx, 1 - xx - yy, 0,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatSkew(const Amount, Axis: TLabVec3; const Angle: TLabFloat): TLabMat;
  var vr: TLabVec3;
  var s, c, cr, xs, ys, zs, crxy, crxz, cryz: TLabFloat;
begin
  LabVec3Norm(@vr, @Axis);
  {$Hints off}
  LabSinCos(Angle, s, c);
  {$Hints on}
  cr := 1 - c;
  xs := vr.x * s;
  ys := vr.y * s;
  zs := vr.z * s;
  crxy := cr * vr.x * vr.y;
  crxz := cr * vr.x * vr.z;
  cryz := cr * vr.y * vr.z;
  {$Warnings off}
  Result.SetValue(
    LabLerpFloat(1, cr * Axis.x * Axis.x + c, Amount.x), LabLerpFloat(1, -zs + crxy, Amount.y), LabLerpFloat(1, ys + crxz, Amount.z), 0,
    LabLerpFloat(1, zs + crxy, Amount.x), LabLerpFloat(1, cr * Axis.y * Axis.y + c, Amount.y), LabLerpFloat(1, -xs + cryz, Amount.z), 0,
    LabLerpFloat(1, -ys + crxz, Amount.x), LabLerpFloat(1, xs + cryz, Amount.y), LabLerpFloat(1, cr * Axis.z * Axis.z + c, Amount.z), 0,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatView(const Pos, Target, Up: TLabVec3): TLabMat;
  var VecX, VecY, VecZ: TLabVec3;
begin
  VecZ := (Target - Pos).Norm;
  VecX := Up.Cross(VecZ).Norm;
  VecY := VecZ.Cross(VecX).Norm;
  {$Warnings off}
  Result.SetValue(
    VecX.x, VecX.y, VecX.z, -VecX.Dot(Pos),
    VecY.x, VecY.y, VecY.z, -VecY.Dot(Pos),
    VecZ.x, VecZ.y, VecZ.z, -VecZ.Dot(Pos),
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatOrth(const Width, Height, ZNear, ZFar: TLabFloat): TLabMat;
  var RcpD: TLabFloat;
begin
  RcpD := 1 / (ZFar - ZNear);
  {$Warnings off}
  Result.SetValue(
    2 / Width, 0, 0, 0,
    0, 2 / Height, 0, 0,
    0, 0, RcpD, -ZNear * RcpD,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatOrth2D(const Width, Height, ZNear, ZFar: TLabFloat; const FlipH: Boolean = False; const FlipV: Boolean = True): TLabMat;
  var RcpD: TLabFloat;
  var x, y, w, h: TLabFloat;
begin
  if FlipH then begin x := 1; w := -2 / Width; end else begin x := -1; w := 2 / Width; end;
  if FlipV then begin y := 1; h := -2 / Height; end else begin y := -1; h := 2 / Height; end;
  RcpD := 1 / (ZFar - ZNear);
  {$Warnings off}
  Result.SetValue(
    w, 0, 0, x,
    0, h, 0, y,
    0, 0, RcpD, -ZNear * RcpD,
    0, 0, 0, 1
  );
  {$Warnings on}
end;

function LabMatProj(const FOV, Aspect, ZNear, ZFar: TLabFloat): TLabMat;
  var ct, q: TLabFloat;
begin
  ct := LabCoTan(FOV * 0.5);
  q := ZFar / (ZFar - ZNear);
  {$Warnings off}
  Result.SetValue(
    ct / Aspect, 0, 0, 0,
    0, ct, 0, 0,
    0, 0, q, -q * ZNear,
    0, 0, 1, 0
  );
  {$Warnings on}
end;

function LabMatTranspose(const m: TLabMat): TLabMat;
begin
  {$Warnings off}
  Result.SetValue(
    m.e00, m.e01, m.e02, m.e03,
    m.e10, m.e11, m.e12, m.e13,
    m.e20, m.e21, m.e22, m.e23,
    m.e30, m.e31, m.e32, m.e33
  );
  {$Warnings on}
end;

procedure LabMatDecompose(const OutScaling: PLabVec3; const OutRotation: PLabQuat; const OutTranslation: PLabVec3; const m: TLabMat);
  var mn: TLabMat;
  var v: TLabVec3;
begin
  if OutScaling <> nil then
  begin
    OutScaling^.x := PLabVec3(@m.e00)^.Len;
    OutScaling^.y := PLabVec3(@m.e10)^.Len;
    OutScaling^.z := PLabVec3(@m.e20)^.Len;
  end;
  if OutTranslation <> nil then
  begin
    OutTranslation^ := PLabVec3(@m.e30)^;
  end;
  if OutRotation <> nil then
  begin
    if OutScaling <> nil then
    begin
      if (OutScaling^.x = 0) or (OutScaling^.y = 0) or (OutScaling^.z = 0) then
      begin
        OutRotation^.SetValue(0, 0, 0, 1);
        Exit;
      end;
      v.x := 1 / OutScaling^.x;
      v.y := 1 / OutScaling^.y;
      v.z := 1 / OutScaling^.z;
    end
    else
    begin
      v.SetValue(PLabVec3(@m.e00)^.Len, PLabVec3(@m.e10)^.Len, PLabVec3(@m.e20)^.Len);
      if (v.x = 0) or (v.y = 0) or (v.z = 0) then
      begin
        OutRotation^.SetValue(0, 0, 0, 1);
        Exit;
      end;
      v.x := 1 / v.x;
      v.y := 1 / v.y;
      v.z := 1 / v.z;
    end;
    mn.SetValue(
      m.e00 * v.x, m.e10 * v.y, m.e20 * v.z, 0,
      m.e01 * v.x, m.e11 * v.y, m.e21 * v.z, 0,
      m.e02 * v.x, m.e12 * v.y, m.e22 * v.z, 0,
      0, 0, 0, 1
    );
    OutRotation^ := LabQuat(mn);
  end;
end;

function LabMatCompare(const m0, m1: TLabMat): Boolean;
  var i: TLabInt32;
begin
  Result := True;
  for i := 0 to 15 do
  if Abs(m0.Arr[i] - m1.Arr[i]) > LabEPS then
  begin
    Result := False;
    Exit;
  end;
end;

function LabLerpFloat(const v0, v1, t: TLabFloat): TLabFloat;
begin
  Result := v0 + (v1 - v0) * t;
end;

function LabMin(const f0, f1: TLabFloat): TLabFloat;
begin
  if f0 < f1 then Result := f0 else Result := f1;
end;

function LabMin(const v0, v1: TLabInt32): TLabInt32;
begin
  if v0 < v1 then Result := v0 else Result := v1;
end;

function LabMin(const v0, v1: TLabUInt32): TLabUInt32;
begin
  if v0 < v1 then Result := v0 else Result := v1;
end;

function LabMax(const f0, f1: TLabFloat): TLabFloat;
begin
  if f0 > f1 then Result := f0 else Result := f1;
end;

function LabMax(const v0, v1: TLabInt32): TLabInt32;
begin
  if v0 > v1 then Result := v0 else Result := v1;
end;

function LabMax(const v0, v1: TLabUInt32): TLabUInt32;
begin
  if v0 > v1 then Result := v0 else Result := v1;
end;

function LabClamp(const f, LimMin, LimMax: TLabFloat): TLabFloat;
begin
  if f < LimMin then Result := LimMin
  else if f > LimMax then Result := LimMax
  else Result := f;
end;

function LabSmoothStep(const t, f0, f1: TLabFloat): TLabFloat;
begin
  Result := LabClamp((t - f0) / (f1 - f0), 0, 1);
end;

function LabBezierFloat(const f0, f1, f2, f3: TLabFloat; const t: TLabFloat): TLabFloat;
  var t2, t3: TLabFloat;
begin
  t2 := t * t;
  t3 := t2 * t;
  Result := t3 * f3 + (3 * t2 - 3 * t3) * f2 + (3 * t3 - 6 * t2 + 3 * t) * f1 + (3 * t2 - t3 - 3 * t + 1) * f0;
end;

function LabLerpVec2(const v0, v1: TLabVec2; const t: TLabFloat): TLabVec2;
begin
  Result.x := v0.x + (v1.x - v0.x) * t;
  Result.y := v0.y + (v1.y - v0.y) * t;
end;

function LabLerpVec3(const v0, v1: TLabVec3; const t: TLabFloat): TLabVec3;
begin
  Result.x := v0.x + (v1.x - v0.x) * t;
  Result.y := v0.y + (v1.y - v0.y) * t;
  Result.z := v0.z + (v1.z - v0.z) * t;
end;

function LabLerpVec4(const v0, v1: TLabVec4; const t: TLabFloat): TLabVec4;
begin
  Result.x := v0.x + (v1.x - v0.x) * t;
  Result.y := v0.y + (v1.y - v0.y) * t;
  Result.z := v0.z + (v1.z - v0.z) * t;
  Result.w := v0.w + (v1.w - v0.w) * t;
end;

function LabLerpQuat(const v0, v1: TLabQuat; const t: TLabFloat): TLabQuat;
begin
  Result.x := v0.x + (v1.x - v0.x) * t;
  Result.y := v0.y + (v1.y - v0.y) * t;
  Result.z := v0.z + (v1.z - v0.z) * t;
  Result.w := v0.w + (v1.w - v0.w) * t;
end;

function LabCosrpFloat(const f0, f1: TLabFloat; const s: TLabFloat): TLabFloat;
begin
  Result := f0 + (f1 - f0) * (1.0 - Cos(s * Pi)) * 0.5;
end;

function LabVec2CatmullRom(const v0, v1, v2, v3: TLabVec2; const t: TLabFloat): TLabVec2;
begin
  Result.x := 0.5 * (2 * v1.x + (v2.x - v0.x) * t + (2 * v0.x - 5 * v1.x + 4 * v2.x - v3.x) * t * t + (v3.x - 3 * v2.x + 3 * v1.x - v0.x) * t * t * t);
  Result.y := 0.5 * (2 * v1.y + (v2.y - v0.y) * t + (2 * v0.y - 5 * v1.y + 4 * v2.y - v3.y) * t * t + (v3.y - 3 * v2.y + 3 * v1.y - v0.y) * t * t * t);
end;

function LabVec3CatmullRom(const v0, v1, v2, v3: TLabVec3; const t: TLabFloat): TLabVec3;
begin
  Result.x := 0.5 * (2 * v1.x + (v2.x - v0.x) * t + (2 * v0.x - 5 * v1.x + 4 * v2.x - v3.x) * t * t + (v3.x - 3 * v2.x + 3 * v1.x - v0.x) * t * t * t);
  Result.y := 0.5 * (2 * v1.y + (v2.y - v0.y) * t + (2 * v0.y - 5 * v1.y + 4 * v2.y - v3.y) * t * t + (v3.y - 3 * v2.y + 3 * v1.y - v0.y) * t * t * t);
  Result.z := 0.5 * (2 * v1.z + (v2.z - v0.z) * t + (2 * v0.z - 5 * v1.z + 4 * v2.z - v3.z) * t * t + (v3.z - 3 * v2.z + 3 * v1.z - v0.z) * t * t * t);
end;

function LabVec2Bezier(const v0, v1, v2, v3: TLabVec2; const t: TLabFloat): TLabVec2;
  var t2, t3: TLabFloat;
begin
  t2 := t * t;
  t3 := t2 * t;
  Result := t3 * v3 + (3 * t2 - 3 * t3) * v2 + (3 * t3 - 6 * t2 + 3 * t) * v1 + (3 * t2 - t3 - 3 * t + 1) * v0;
end;

function LabCoTan(const x: TLabFloat): TLabFloat;
  var s, c: TLabFloat;
begin
  {$Hints off}
  LabSinCos(x, s, c);
  {$Hints on}
  Result := c / s;
end;

{$ifdef LabCpu386}
{$Warnings off}
function LabArcCos(const x: TLabFloat): TLabFloat; assembler;
asm
  fld1
  fld x
  fst st(2)
  fmul st(0), st(0)
  fsubp
  fsqrt
  fxch
  fpatan
end;
{$Warnings on}
{$else}
function LabArcCos(const x: TLabFloat): TLabFloat;
begin
  Result := LabArcTan2(Sqrt((1 + x) * (1 - x)), x);
end;
{$endif}

{$ifdef LabCpu386}
function LabArcTan2(const y, x: TLabFloat): TLabFloat; assembler;
asm
  fld y
  fld x
  fpatan
  fwait
end;
{$else}
function LabArcTan2(const y, x: TLabFloat): TLabFloat;
begin
  if x = 0 then
  begin
    if y = 0 then Result := 0
    else if y > 0 then Result := LabHalfPi
    else if y < 0 then Result := -LabHalfPi;
  end
  else
  Result := ArcTan(y / x);
  if x < 0 then
  Result := Result + pi;
  if Result > pi then
  Result := Result - LabTwoPi;
end;
{$endif}

{$ifdef LabCpu386}
procedure LabSinCos(const Angle: TLabFloat; var s, c: TLabFloat); assembler;
asm
  fld Angle
  fsincos
  fstp [edx]
  fstp [eax]
  fwait
end;
{$else}
procedure LabSinCos(const Angle: TLabFloat; var s, c: TLabFloat);
begin
  s := Sin(Angle);
  c := Cos(Angle);
end;
{$endif}

function LabProject2DPointToLine(const lv0, lv1, v: TLabVec2; var InSegment: Boolean): TLabVec2;
  var u: TLabFloat;
begin
  u := ((v.x - lv0.x) * (lv1.x - lv0.x) + (v.y - lv0.y) * (lv1.y - lv0.y)) / (Sqr(lv1.x - lv0.x) + Sqr(lv1.y - lv0.y));
  Result := LabVec2(lv0.x + u * (lv1.x - lv0.x), lv0.y + u * (lv1.y - lv0.y));
  InSegment := (u >= 0) and (u <= 1);
end;

function LabProject3DPointToLine(const lv0, lv1, v: TLabVec3; var InSegment: Boolean): TLabVec3;
  var u: TLabFloat;
begin
  u := (
    ((v.x - lv0.x) * (lv1.x - lv0.x) + (v.y - lv0.y) * (lv1.y - lv0.y) + (v.z - lv0.z) * (lv1.z - lv0.z)) /
    (Sqr(lv1.x - lv0.x) + Sqr(lv1.y - lv0.y) + Sqr(lv1.z - lv0.z))
  );
  Result := LabVec3(lv0.x + u * (lv1.x - lv0.x), lv0.y + u * (lv1.y - lv0.y), lv0.z + u * (lv1.z - lv0.z));
  InSegment := (u >= 0) and (u <= 1);
end;

function LabProject3DPointToPlane(const p: TLabPlane; const v: TLabVec3): TLabVec3;
begin
  Result := v + (p.n * (p.d - p.n.Dot(v)));
end;

function LabIntersect2DLineVsLine(const l0v0, l0v1, l1v0, l1v1: TLabVec2; var xp: TLabVec2): Boolean;
  var u: TLabVec2 absolute l0v0;
  var v, n: TLabVec2;
  var t, nv: TLabFloat;
begin
  v := l0v1 - l0v0;
  n := (l1v1 - l1v0).Perp;
  nv := n.Dot(v);
  if Abs(nv) < LabEPS then Exit(False);
  t := (n.Dot(l1v0) - n.Dot(u)) / nv;
  xp := u + v * t;
  Result := True;
end;

function LabIntersect2DLineVsSegment(const l0, l1, s0, s1: TLabVec2; var xp: TLabVec2): Boolean;
  var u: TLabVec2 absolute s0;
  var v, n: TLabVec2;
  var t, nv: TLabFloat;
begin
  v := s1 - s0;
  n := (l1 - l0).Perp;
  nv := n.Dot(v);
  if Abs(nv) < LabEPS then Exit(False);
  t := (n.Dot(l0) - n.Dot(u)) / nv;
  xp := u + v * t;
  Result := (t >= 0) and (t <= 1);
end;

function LabIntersect2DSegmentVsSegment(
  const s0v0, s0v1, s1v0, s1v1: TLabVec2;
  var xp: TLabVec2
): Boolean;
  var u: TLabVec2 absolute s0v0;
  var v, n, d: TLabVec2;
  var t, nv: TLabFloat;
begin
  v := s0v1 - s0v0;
  d := s1v1 - s1v0;
  n := d.Perp;
  nv := n.Dot(v);
  if Abs(nv) < LabEPS then Exit(False);
  t := (n.Dot(s1v0) - n.Dot(u)) / nv;
  xp := u + v * t;
  Result := (t >= 0) and (t <= 1); if not Result then Exit;
  t := d.Dot(xp);
  Result := (t >= d.Dot(s1v0)) and (t <= d.Dot(s1v1));
end;

function LabIntersect2DLineVsCircle(const lv0, lv1, cc: TLabVec2; const r: TLabFloat; var xp0, xp1: TLabVec2): Boolean;
  var g, v: TLabVec2;
  var a, b, c, d, d_sqrt, a2: TLabFloat;
begin
  g := lv0 - cc;
  v := lv0 - lv1;
  a := v.Dot(v);
  b := 2 * v.Dot(g);
  c := g.Dot(g) - (r * r);
  d := b * b - 4 * a * c;
  if d < 0 then Exit(False);
  d_sqrt := Sqrt(d);
  a2 := 2 * a;
  xp0 := lv0 + v * ((-b + d_sqrt) / a2);
  xp1 := lv0 + v * ((-b - d_sqrt) / a2);
  Result := True;
end;

function LabIntersect2DSegmentVsCircle(const lv0, lv1, cc: TLabVec2; const r: TLabFloat; var xp0, xp1: TLabVec2; var xb0, xb1: Boolean): Boolean;
  var g, v: TLabVec2;
  var a, b, c, d, d_sqrt, a2, p0, p1: TLabFloat;
begin
  g := lv0 - cc;
  v := lv1 - lv0;
  a := v.Dot(v);
  b := 2 * v.Dot(g);
  c := g.Dot(g) - (r * r);
  d := b * b - 4 * a * c;
  if d < 0 then Exit(False);
  d_sqrt := Sqrt(d);
  a2 := 2 * a;
  p0 := (-b + d_sqrt) / a2;
  p1 := (-b - d_sqrt) / a2;
  xb0 := ((p0 >= 0) and (p0 <= 1));
  xb1 := ((p1 >= 0) and (p1 <= 1));
  xp0 := lv0 + v * p0;
  xp1 := lv0 + v * p1;
  Result := xb0 or xb1;
end;

function LabIntersect2DLineVsRect(const lv0, lv1: TLabVec2; const r: TLabRect; var xp0, xp1: TLabVec2): Boolean;
  var tn, tf, d, t, t0, t1: TLabFloat;
  var v: TLabVec2;
  var i: TLabInt32;
begin
  tn := -1E+16;
  tf := 1E+16;
  v := lv1 - lv0;
  for i := 0 to 1 do
  begin
    if Abs(v[i]) < LabEPS then
    begin
      if (lv0[i] < r.tl[i])
      or (lv0[i] > r.br[i]) then
      Exit(False);
    end;
    d := 1 / v[i];
    t0 := (r.tl[i] - lv0[i]) * d;
    t1 := (r.br[i] - lv0[i]) * d;
    if t0 > t1 then
    begin
      t := t1;
      t1 := t0;
      t0 := t;
    end;
    if t0 > tn then tn := t0;
    if t1 < tf then tf := t1;
    if (tn > tf) then Exit(False);
  end;
  xp0 := lv0 + v * tn;
  xp1 := lv0 + v * tf;
  Result := True;
end;

function LabIntersect2DSegmentVsRect(const lv0, lv1: TLabVec2; const r: TLabRect; var xp0, xp1: TLabVec2): Boolean;
  var tn, tf, d, t, t0, t1: TLabFloat;
  var v: TLabVec2;
  var i: TLabInt32;
begin
  tn := 0;
  tf := 1;
  v := lv1 - lv0;
  for i := 0 to 1 do
  begin
    if Abs(v[i]) < LabEPS then
    begin
      if (lv0[i] < r.tl[i])
      or (lv0[i] > r.br[i]) then
      Exit(False);
    end;
    d := 1 / v[i];
    t0 := (r.tl[i] - lv0[i]) * d;
    t1 := (r.br[i] - lv0[i]) * d;
    if t0 > t1 then
    begin
      t := t1;
      t1 := t0;
      t0 := t;
    end;
    if t0 > tn then tn := t0;
    if t1 < tf then tf := t1;
    if (tn > tf) or (tf < 0) then Exit(False);
  end;
  xp0 := lv0 + v * tn;
  xp1 := lv0 + v * tf;
  Result := True;
end;

function LabIntersect3DLineVsPlane(const lv0, lv1: TLabVec3; const p: TLabPlane; var xp: TLabVec3): Boolean;
  var u: TLabVec3 absolute lv0;
  var v: TLabVec3;
  var vn, t: TLabFloat;
begin
  v := lv1 - lv0;
  vn := v.Dot(p.n);
  if Abs(vn) < LabEPS then Exit(False);
  t := (p.d - p.n.Dot(u)) / vn;
  xp := u + v * t;
  Result := True;
end;

function LabIntersect3DLineVsSphere(const lv0, lv1: TLabVec3; const s: TLabSphere; var xp0, xp1: TLabVec3): Boolean;
  var g, v: TLabVec3;
  var a, b, c, d, d_sqrt, a2: TLabFloat;
begin
  g := lv0 - s.c;
  v := lv1 - lv0;
  a := v.Dot(v);
  b := 2 * v.Dot(g);
  c := g.Dot(g) - (s.r * s.r);
  d := b * b - 4 * a * c;
  if d < 0 then Exit(False);
  d_sqrt := Sqrt(d);
  a2 := 2 * a;
  xp0 := lv1 + v * ((-b + d_sqrt) / a2);
  xp1 := lv1 + v * ((-b - d_sqrt) / a2);
  Result := True;
end;

function LabIntersect3Planes(const p1, p2, p3: TLabPlane; var xp: TLabVec3): Boolean;
  var Det: TLabFloat;
begin
  Det := -p1.n.Dot(p2.n.Cross(p3.n));
  if Abs(Det) < LabEPS then Exit(False);
  xp := ((p2.n.Cross(p3.n) * p1.d) + (p3.n.Cross(p1.n) * p2.d) + (p1.n.Cross(p2.n) * p3.d)) / Det;
  Result := True;
end;

function LabIntersect3DRayVsPlane(
  const r: TLabRay3;
  const p: TLabPlane;
  var xp: TLabVec3;
  var xd: TLabFloat
): Boolean;
  var dn: TLabFloat;
begin
  dn := r.Dir.Dot(p.n);
  if Abs(dn) < LabEPS then Exit(False);
  xd := (p.d - p.n.Dot(r.Origin)) / dn;
  xp := r.Origin + r.Dir * xd;
  Result := True;
end;

function LabIntersect3DRayVsTriangle(const r: TLabRay3; const v0, v1, v2: TLabVec3; var xp: TLabVec3; var xd: TLabFloat): Boolean;
  var e1, e2, p, q, d: TLabVec3;
  var det, det_rcp, u, v, t: TLabFloat;
begin
  e1 := v1 - v0;
  e2 := v2 - v0;
  p := r.Dir.Cross(e2);
  det := e1.Dot(p);
  if (det > -LabEPS) and (det < LabEPS) then Exit(False);
  det_rcp := 1 / det;
  d := r.Origin - v0;
  u := d.Dot(p) * det_rcp;
  if (u < 0) or (u > 1) then Exit(False);
  q := d.Cross(e1);
  v := r.Dir.Dot(q) * det_rcp;
  if (v < 0) or (u + v > 1) then Exit(False);
  t := e2.Dot(q) * det_rcp;
  if (t > LabEPS) then
  begin
    xd := t;
    xp := (r.Dir * t) + r.Origin;
    Exit(True);
  end;
  Result := False;
end;

function LabDistance3DLineToLine(const l0v0, l0v1, l1v0, l1v1: TLabVec3; var d0, d1: TLabVec3): TLabFloat;
  var u, v, w: TLabVec3;
  var a, b, c, d, e, dv, sc, tc: TLabFloat;
begin
  u := l0v1 - l0v0;
  v := l1v1 - l1v0;
  w := l0v0 - l1v0;
  a := u.Dot(u);
  b := u.Dot(v);
  c := v.Dot(v);
  d := u.Dot(w);
  e := v.Dot(w);
  dv := a * c - b * b;
  if abs(dv) < LabEPS then
  begin
    sc := 0.0;
    tc := d / b;
  end
  else
  begin
    dv := 1 / dv;
    sc := (b * e - c * d) * dv;
    tc := (a * e - b * d) * dv;
  end;
  d0 := l0v0 + (u * sc);
  d1 := l1v0 + (v * tc);
  Result := (d1 - d0).Len;
end;

function LabDistance3DSegmentToSegment(const l0v0, l0v1, l1v0, l1v1: TLabVec3): TLabFloat;
  var u, v, w, dp: TLabVec3;
  var a, b, c, d, e, s, sc, sn, sd, tc, tn, td: TLabFloat;
begin
  u := l0v1 - l0v1;
  v := l1v1 - l1v0;
  w := l0v0 - l1v0;
  a := u.Dot(u);
  b := u.Dot(v);
  c := v.Dot(v);
  d := u.Dot(w);
  e := v.Dot(w);
  s := a * c - b * b;
  sc := s; sn := s; sd := s;
  tc := s; tn := s; td := s;
  if (s < LabEPS) then
  begin
    sn := 0;
    sd := 1;
    tn := e;
    td := c;
  end
  else
  begin
    sn := (b * e - c * d);
    tn := (a * e - b * d);
    if (sn < 0) then
    begin
      sn := 0;
      tn := e;
      td := c;
    end
    else if (sn > sd) then
    begin
      sn := sd;
      tn := e + b;
      td := c;
    end;
  end;
  if tn < 0 then
  begin
    tn := 0;
    if -d < 0 then sn := 0.0
    else if -d > a then sn := sd
    else
    begin
      sn := -d;
      sd := a;
    end;
  end
  else if tn > td then
  begin
    tn := td;
    if -d + b < 0 then sn := 0
    else if -d + b > a then sn := sd
    else
    begin
      sn := -d + b;
      sd := a;
    end;
  end;
  if Abs(sn) < LabEPS then sc := 0 else sc := sn / sd;
  if Abs(tn) < LabEPS then tc := 0 else tc := tn / td;
  dp := w + (sc * u) - (tc * v);
  Result := dp.Len;
end;

function LabTriangleArea(const v0, v1, v2: TLabVec2): TLabFloat;
  var d0, d1, d2, s: TLabFloat;
begin
  d0 := (v0 - v1).Len;
  d1 := (v1 - v2).Len;
  d2 := (v2 - v0).Len;
  s := (d0 + d1 + d2) * 0.5;
  Result := Sqrt(s * (s - d0) * (s - d1) * (s - d2));
end;

function LabTriangleArea(const v0, v1, v2: TLabVec3): TLabFloat;
  var d0, d1, d2, s: TLabFloat;
begin
  d0 := (v0 - v1).Len;
  d1 := (v1 - v2).Len;
  d2 := (v2 - v0).Len;
  s := (d0 + d1 + d2) * 0.5;
  Result := Sqrt(s * (s - d0) * (s - d1) * (s - d2));
end;

function LabTriangleNormal(const v0, v1, v2: TLabVec3): TLabVec3;
begin
  Result := (v1 - v0).Cross(v2 - v0).Norm;
end;

procedure LabTriangleTBN(
  const v1, v2, v3: TLabVec3;
  const uv1, uv2, uv3: TLabVec2;
  var T, B, N: TLabVec3
);
  var FaceNormal, Side1, Side2, cp: TLabVec3;
  var Rcpcpx: TLabFloat;
begin
  FaceNormal := LabTriangleNormal(v1, v2, v3);
  Side1.SetValue(v2.x - v1.x, uv2.x - uv1.x, uv2.y - uv1.y);
  Side2.SetValue(v3.x - v1.x, uv3.x - uv1.x, uv3.y - uv1.y);
  cp := Side1.Cross(Side2);
  Rcpcpx := 1 / cp.x;
  T.x := -cp.y * Rcpcpx; B.x := -cp.z * Rcpcpx;
  Side1.x := v2.y - v1.y; Side2.x := v3.y - v1.y;
  cp := Side1.Cross(Side2);
  T.y := -cp.y * Rcpcpx; B.y := -cp.z * Rcpcpx;
  Side1.x := v2.z - v1.z; Side2.x := v3.z - v1.z;
  cp := Side1.Cross(Side2);
  T.z := -cp.y * Rcpcpx; B.z := -cp.z * Rcpcpx;
  T := T.Norm; B := B.Norm;
  N := T.Cross(B).Norm;
  if N.Dot(FaceNormal) < 0 then N := -N;
end;

function LabPolyTriangulate(const Triang: PLabPolyTriang): Boolean;
  function InsideTriangle(const Ax, Ay, Bx, By, Cx, Cy, Px, Py: TLabFloat): Boolean;
  begin
    Result := (
      ((Cx - Bx) * (Py - By) - (Cy - By) * (Px - Bx) >= 0)
      and ((Bx - Ax) * (Py - Ay) - (By - Ay) * (Px - Ax) >= 0)
      and ((Ax - Cx) * (Py - Cy) - (Ay - Cy) * (Px - Cx) >= 0)
    );
  end;
  function Area: TLabFloat;
    var i, j: TLabInt32;
  begin
    Result := 0;
    i := High(Triang^.v);
    for j := 0 to High(Triang^.v) do
    begin
      Result := Result + Triang^.v[i].x * Triang^.v[j].y - Triang^.v[j].x * Triang^.v[i].y;
      i := j;
    end;
    Result := Result * 0.5;
  end;
  function Snip(const u, v, w, n: TLabInt32; const Ind: PLabInt32Arr): Boolean;
    var i: TLabInt32;
    var Ax, Ay, Bx, By, Cx, Cy, Px, Py: TLabFloat;
  begin
    Ax := Triang^.v[Ind^[u]].x;
    Ay := Triang^.v[Ind^[u]].y;
    Bx := Triang^.v[Ind^[v]].x;
    By := Triang^.v[Ind^[v]].y;
    Cx := Triang^.v[Ind^[w]].x;
    Cy := Triang^.v[Ind^[w]].y;
    if 1E-5 > (((Bx - Ax) * (Cy - Ay)) - ((By - Ay) * (Cx - Ax))) then
    begin
      Result := False;
      Exit;
    end;
    for i := 0 to n - 1 do
    begin
      if (i = u) or (i = v) or (i = w) then Continue;
      Px := Triang^.v[Ind^[i]].x;
      Py := Triang^.v[Ind^[i]].y;
      if InsideTriangle(Ax, Ay, Bx, By, Cx, Cy, Px, Py) then
      begin
        Result := False;
        Exit;
      end;
    end;
    Result := True;
  end;
  var u, v, w, i, n, nv, c: TLabInt32;
  var s, t: TLabInt32;
  var Ind: array of TLabInt32;
begin
  n := Length(Triang^.v);
  if n < 3 then
  begin
    Result := False;
    Exit;
  end;
  SetLength(Triang^.Triangles, n);
  SetLength(Ind, n);
  if Area > 0 then
  for i := 0 to n - 1 do Ind[i] := i
  else
  for i := 0 to n - 1 do Ind[i] := n - 1 - i;
  nv := n;
  c := nv * 2;
  i := 0;
  v := nv - 1;
  t := 0;
  while nv > 2 do
  begin
    if c - 1 <= 0 then
    begin
      SetLength(Triang^.Triangles, 0);
      Result := False;
      Exit;
    end;
    u := v; if nv <= u then u := 0;
    v := u + 1; if nv <= v then v := 0;
    w := v + 1; if nv <= w then w := 0;
    if Snip(u, v, w, nv, @Ind[0]) then
    begin
      Triang^.Triangles[t][0] := Ind[u];
      Triang^.Triangles[t][1] := Ind[v];
      Triang^.Triangles[t][2] := Ind[w];
      Inc(t);
      for s := v to nv - 2 do
      Ind[s] := Ind[s + 1];
      Dec(nv);
      c := nv * 2;
      i := 0;
    end
    else
    begin
      Inc(i);
      if (i > nv + 1) then
      begin
        SetLength(Triang^.Triangles, 0);
        Result := False;
        Exit;
      end;
      v := v + 1; if nv <= v then v := 0;
    end;
  end;
  SetLength(Triang^.Triangles, t);
  Result := True;
end;

function LabLineVsCircle(const v0, v1, c: TLabVec2; const r: TLabFloat; var p0, p1: PLabVec2): Boolean;
  var dx, dy, a, b, d, x0, x1, y0, y1: TLabFloat;
  var asq, bsq, rsq, l, h: TLabFloat;
  var rv0, rv1: TLabVec2;
begin
  Result := False;
  p0 := nil; p1 := nil;
  rv0 := v0 - c; rv1 := v1 - c;
  if rv0.x < rv1.x then begin x0 := rv0.x; x1 := rv1.x; end else begin x0 := rv1.x; x1 := rv0.x end;
  if rv0.y < rv1.y then begin y0 := rv0.y; y1 := rv1.y; end else begin y0 := rv1.y; y1 := rv0.y end;
  if (x0 > r) or (x1 < -r) or (y0 > r) or (y1 < -r) then
  begin
    Result := False;
    Exit;
  end;
  dx := rv0.x - rv1.x; dy := rv0.y - rv1.y;
  rsq := r * r;
  if Abs(dx) < LabEPS then
  begin
    if Abs(dy) < LabEPS then
    begin
      Result := False;
      Exit;
    end
    else
    begin
      x0 := rv0.x;
      d := rsq - (x0 * x0);
      x0 := x0 + c.x;
      if rv0.y < rv1.y then begin l := rv0.y; h := rv1.y end else begin l := rv1.y; h := rv0.y end;
      if d < 0 then
      begin
        Result := False;
        Exit;
      end
      else if d < LabEPS then
      begin
        if (0 >= l) and (0 <= h) then
        begin
          Result := True;
          New(p0); p0^.x := x0; p0^.y := c.y;
          Exit;
        end
        else
        begin
          Result := False;
          Exit;
        end;
      end
      else
      begin
        d := Sqrt(d);
        if (d >= l) and (d <= h) then
        begin
          New(p0); p0^.x := x0; p0^.y := d + c.y;
        end;
        if (-d >= l) and (-d <= h) then
        begin
          New(p1); p1^.x := x0; p1^.y := -d + c.y;
          if p0 = nil then
          begin
            p0 := p1;
            p1 := nil;
          end;
        end;
        if p0 <> nil then
        Result := True;
        Exit;
      end;
    end;
  end
  else if Abs(dy) < LabEPS then
  begin
    y0 := rv0.y;
    d := rsq - (y0 * y0);
    y0 := y0 + c.y;
    if rv0.x < rv1.x then begin l := rv0.x; h := rv1.x end else begin l := rv1.x; h := rv0.x end;
    if d < 0 then
    begin
      Result := False;
      Exit;
    end
    else if d < LabEPS then
    begin
      if (0 >= l) and (0 <= h) then
      begin
        Result := True;
        New(p0); p0^.x := c.x; p0^.y := y0;
        Exit;
      end
      else
      begin
        Result := False;
        Exit;
      end;
    end
    else
    begin
      d := Sqrt(d);
      if (d >= l) and (d <= h) then
      begin
        New(p0); p0^.x := d + c.x; p0^.y := y0;
      end;
      if (-d >= l) and (-d <= h) then
      begin
        New(p1); p1^.x := -d + c.x; p1^.y := y0;
        if p0 = nil then
        begin
          p0 := p1;
          p1 := nil;
        end;
      end;
      if p0 <> nil then
      Result := True;
      Exit;
    end;
  end;
  a := dy / dx;
  b := rv0.y - rv0.x * a;
  asq := a * a; bsq := b * b;
  d := 4 * (asq * rsq - bsq + rsq);
  if d < 0 then
  begin
    Result := False;
    Exit;
  end
  else if d < LabEPS then
  begin
    if Abs(dx) > Abs(dy) then
    begin
      if rv0.x < rv1.x then begin l := rv0.x; h := rv1.x end else begin l := rv1.x; h := rv0.x end;
      x0 := -(a * b) / (asq + 1);
      if (x0 >= l) and (x0 <= h) then
      begin
        Result := True;
        y0 := x0 * a + b;
        New(p0); p0^.x := x0 + c.x; p0^.y := y0 + c.y;
        Exit;
      end
      else
      begin
        Result := False;
        Exit;
      end;
    end
    else
    begin
      if rv0.y < rv1.y then begin l := rv0.y; h := rv1.y end else begin l := rv1.y; h := rv0.y end;
      y0 := b / (asq + 1);
      if (y0 >= l) and (y0 <= h) then
      begin
        Result := True;
        x0 := (y0 - b) / a;
        New(p0); p0^.x := x0 + c.x; p0^.y := y0 + c.y;
        Exit;
      end
      else
      begin
        Result := False;
        Exit;
      end;
    end;
  end
  else
  begin
    d := Sqrt(d);
    if Abs(dx) > Abs(dy) then
    begin
      if rv0.x < rv1.x then begin l := rv0.x; h := rv1.x end else begin l := rv1.x; h := rv0.x end;
      x0 := -(2 * a * b + d) / (2 * asq + 2);
      if (x0 >= l) and (x0 <= h) then
      begin
        y0 := x0 * a + b;
        New(p0); p0^.x := x0 + c.x; p0^.y := y0 + c.y;
      end;
      x1 := -(2 * a * b - d) / (2 * asq + 2);
      if (x1 >= l) and (x1 <= h) then
      begin
        y1 := x1 * a + b;
        New(p1); p1^.x := x1 + c.x; p1^.y := y1 + c.y;
        if p0 = nil then
        begin
          p0 := p1;
          p1 := nil;
        end;
      end;
      if (p0 <> nil) then
      Result := True;
      Exit;
    end
    else
    begin
      if rv0.y < rv1.y then begin l := rv0.y; h := rv1.y end else begin l := rv1.y; h := rv0.y end;
      y0 := (2 * b + a * d) / (2 * asq + 2);
      if (y0 >= l) and (y0 <= h) then
      begin
        x0 := (y0 - b) / a;
        New(p0); p0^.x := x0 + c.x; p0^.y := y0 + c.y;
      end;
      y1 := (2 * b - a * d) / (2 * asq + 2);
      if (y1 >= l) and (y1 <= h) then
      begin
        x1 := (y1 - b) / a;
        New(p1); p1^.x := x1 + c.x; p1^.y := y1 + c.y;
        if p0 = nil then
        begin
          p0 := p1;
          p1 := nil;
        end;
      end;
      if (p0 <> nil) then
      Result := True;
      Exit;
    end;
  end;
end;

function LabLineVsLine(const l0v0, l0v1, l1v0, l1v1: TLabVec2; var p: TLabVec2): Boolean;
  var a0, b0, a1, b1, x, y: TLabFloat;
  var lv0, lv1, lh0, lh1: Boolean;
  var xl, xh, yl, yh: TLabFloat;
  var xl0, xh0, yl0, yh0: TLabFloat;
  var xl1, xh1, yl1, yh1: TLabFloat;
begin
  if l0v0.x < l0v1.x then begin xl0 := l0v0.x; xh0 := l0v1.x; end else begin xl0 := l0v1.x; xh0 := l0v0.x; end;
  if l0v0.y < l0v1.y then begin yl0 := l0v0.y; yh0 := l0v1.y; end else begin yl0 := l0v1.y; yh0 := l0v0.y; end;
  if l1v0.x < l1v1.x then begin xl1 := l1v0.x; xh1 := l1v1.x; end else begin xl1 := l1v1.x; xh1 := l1v0.x; end;
  if l1v0.y < l1v1.y then begin yl1 := l1v0.y; yh1 := l1v1.y; end else begin yl1 := l1v1.y; yh1 := l1v0.y; end;
  if (xl0 > xh1) or (xl1 > xh0) or (yl0 > yh1) or (yl1 > yh0) then
  begin
    Result := False;
    Exit;
  end;
  lv0 := Abs(l0v0.x - l0v1.x) < LabEPS;
  lv1 := Abs(l1v0.x - l1v1.x) < LabEPS;
  if lv0 and lv1 then
  begin
    if Abs(l0v0.x - l1v0.x) < LabEPS then
    begin
      p.x := l0v0.x;
      if yh0 < yh1 then yh := yh0 else yh := yh1;
      if yl0 > yl1 then yl := yl0 else yl := yl1;
      p.y := (yh + yl) * 0.5;
      Result := True;
    end
    else
    Result := False;
    Exit;
  end;
  lh0 := Abs(l0v0.y - l0v1.y) < LabEPS;
  lh1 := Abs(l1v0.y - l1v1.y) < LabEPS;
  if lh0 and lh1 then
  begin
    if Abs(l0v0.y - l1v0.y) < LabEPS then
    begin
      p.y := l0v0.y;
      if xh0 < xh1 then xh := xh0 else xh := xh1;
      if xl0 > xl1 then xl := xl0 else xl := xl1;
      p.x := (xh + xl) * 0.5;
      Result := True;
    end
    else
    Result := False;
    Exit;
  end;
  if lv0 and lh1 then
  begin
    x := l0v0.x; y := l1v0.y;
  end
  else if lh0 and lv1 then
  begin
    x := l1v0.x; y := l0v0.y;
  end
  else if lv0 then
  begin
    x := l0v0.x;
    a1 := (l1v1.y - l1v0.y) / (l1v1.x - l1v0.x);
    b1 := l1v0.y - l1v0.x * a1;
    y := x * a1 + b1;
  end
  else if lh0 then
  begin
    y := l0v0.y;
    a1 := (l1v1.y - l1v0.y) / (l1v1.x - l1v0.x);
    b1 := l1v0.y - l1v0.x * a1;
    x := (y - b1) / a1;
  end
  else if lv1 then
  begin
    x := l1v0.x;
    a0 := (l0v1.y - l0v0.y) / (l0v1.x - l0v0.x);
    b0 := l0v0.y - l0v0.x * a0;
    y := x * a0 + b0;
  end
  else if lh1 then
  begin
    y := l1v0.y;
    a0 := (l0v1.y - l0v0.y) / (l0v1.x - l0v0.x);
    b0 := l0v0.y - l0v0.x * a0;
    x := (y - b0) / a0;
  end
  else
  begin
    a0 := (l0v1.y - l0v0.y) / (l0v1.x - l0v0.x);
    b0 := l0v0.y - l0v0.x * a0;
    a1 := (l1v1.y - l1v0.y) / (l1v1.x - l1v0.x);
    b1 := l1v0.y - l1v0.x * a1;
    if Abs(a1 - a0) < LabEPS then
    begin
      if xh0 < xh1 then xh := xh0 else xh := xh1;
      if xl0 > xl1 then xl := xl0 else xl := xl1;
      x := (xh + xl) * 0.5;
    end
    else
    x := (b0 - b1) / (a1 - a0);
    y := a0 * x + b0;
  end;
  if xl0 > xl1 then xl := xl0 else xl := xl1;
  if xh0 < xh1 then xh := xh0 else xh := xh1;
  if yl0 > yl1 then yl := yl0 else yl := yl1;
  if yh0 < yh1 then yh := yh0 else yh := yh1;
  if (x < xl) or (x > xh) or (y < yl) or (y > yh) then
  begin
    Result := False;
    Exit;
  end;
  p.SetValue(x, y);
  Result := True;
end;

function LabLineVsLineInf(const l0v0, l0v1, l1v0, l1v1: TLabVec2; var p: TLabVec2): Boolean;
  var a0, b0, a1, b1, x, y: TLabFloat;
  var lv0, lv1, lh0, lh1: Boolean;
  var xl, xh, yl, yh: TLabFloat;
  var xl0, xh0, yl0, yh0: TLabFloat;
  var xl1, xh1, yl1, yh1: TLabFloat;
begin
  if l0v0.x < l0v1.x then begin xl0 := l0v0.x; xh0 := l0v1.x; end else begin xl0 := l0v1.x; xh0 := l0v0.x; end;
  if l0v0.y < l0v1.y then begin yl0 := l0v0.y; yh0 := l0v1.y; end else begin yl0 := l0v1.y; yh0 := l0v0.y; end;
  if l1v0.x < l1v1.x then begin xl1 := l1v0.x; xh1 := l1v1.x; end else begin xl1 := l1v1.x; xh1 := l1v0.x; end;
  if l1v0.y < l1v1.y then begin yl1 := l1v0.y; yh1 := l1v1.y; end else begin yl1 := l1v1.y; yh1 := l1v0.y; end;
  lv0 := Abs(l0v0.x - l0v1.x) < LabEPS;
  lv1 := Abs(l1v0.x - l1v1.x) < LabEPS;
  if lv0 and lv1 then
  begin
    if Abs(l0v0.x - l1v0.x) < LabEPS then
    begin
      p.x := l0v0.x;
      if yh0 < yh1 then yh := yh0 else yh := yh1;
      if yl0 > yl1 then yl := yl0 else yl := yl1;
      p.y := (yh + yl) * 0.5;
      Result := True;
    end
    else
    Result := False;
    Exit;
  end;
  lh0 := Abs(l0v0.y - l0v1.y) < LabEPS;
  lh1 := Abs(l1v0.y - l1v1.y) < LabEPS;
  if lh0 and lh1 then
  begin
    if Abs(l0v0.y - l1v0.y) < LabEPS then
    begin
      p.y := l0v0.y;
      if xh0 < xh1 then xh := xh0 else xh := xh1;
      if xl0 > xl1 then xl := xl0 else xl := xl1;
      p.x := (xh + xl) * 0.5;
      Result := True;
    end
    else
    Result := False;
    Exit;
  end;
  if lv0 and lh1 then
  begin
    x := l0v0.x; y := l1v0.y;
  end
  else if lh0 and lv1 then
  begin
    x := l1v0.x; y := l0v0.y;
  end
  else if lv0 then
  begin
    x := l0v0.x;
    a1 := (l1v1.y - l1v0.y) / (l1v1.x - l1v0.x);
    b1 := l1v0.y - l1v0.x * a1;
    y := x * a1 + b1;
  end
  else if lh0 then
  begin
    y := l0v0.y;
    a1 := (l1v1.y - l1v0.y) / (l1v1.x - l1v0.x);
    b1 := l1v0.y - l1v0.x * a1;
    x := (y - b1) / a1;
  end
  else if lv1 then
  begin
    x := l1v0.x;
    a0 := (l0v1.y - l0v0.y) / (l0v1.x - l0v0.x);
    b0 := l0v0.y - l0v0.x * a0;
    y := x * a0 + b0;
  end
  else if lh1 then
  begin
    y := l1v0.y;
    a0 := (l0v1.y - l0v0.y) / (l0v1.x - l0v0.x);
    b0 := l0v0.y - l0v0.x * a0;
    x := (y - b0) / a0;
  end
  else
  begin
    a0 := (l0v1.y - l0v0.y) / (l0v1.x - l0v0.x);
    b0 := l0v0.y - l0v0.x * a0;
    a1 := (l1v1.y - l1v0.y) / (l1v1.x - l1v0.x);
    b1 := l1v0.y - l1v0.x * a1;
    if Abs(a1 - a0) < LabEPS then
    begin
      if xh0 < xh1 then xh := xh0 else xh := xh1;
      if xl0 > xl1 then xl := xl0 else xl := xl1;
      x := (xh + xl) * 0.5;
    end
    else
    x := (b0 - b1) / (a1 - a0);
    y := a0 * x + b0;
  end;
  p.SetValue(x, y);
  Result := True;
end;

function LabRectVsRect(const r0, r1: TLabRect; var Resp: TLabVec2): Boolean;
  var dx0, dx1, dy0, dy1, dy, dx: TLabFloat;
begin
  Result := False;
  dx0 := r0.r - r1.l; dx1 := r1.r - r0.l;
  if (dx0 < 0) or (dx1 < 0) then Exit;
  dy0 := r0.b - r1.t; dy1 := r1.b - r0.t;
  if (dy0 < 0) or (dy1 < 0) then Exit;
  Result := True;
  if dx0 < dx1 then dx := dx0 else dx := dx1;
  if dy0 < dy1 then dy := dy0 else dy := dy1;
  if dx < dy then
  begin
    Resp.y := 0;
    if dx0 < dx1 then
    Resp.x := dx0
    else
    Resp.x := -dx1;
  end
  else
  begin
    Resp.x := 0;
    if dy0 < dy1 then
    Resp.y := dy0
    else
    Resp.y := -dy1;
  end;
end;

function LabRectVsTri(const r: TLabRect; const Tri: PLabVec2): Boolean;
  var i: TLabInt32;
  var n: array[0..2] of TLabVec2;
  var d: array[0..2] of TLabFloat;
  var vmin: TLabVec2;
  var xmin, xmax, ymin, ymax: Boolean;
  var TriArr: PLabVec2Arr absolute Tri;
begin
  Result := True;
  xmin := True; xmax := True; ymin := True; ymax := True;
  for i := 0 to 2 do
  begin
    if TriArr^[i].x >= r.l then xmin := False;
    if TriArr^[i].x <= r.r then xmax := False;
    if TriArr^[i].y >= r.t then ymin := False;
    if TriArr^[i].y <= r.b then ymax := False;
    n[i] := (TriArr^[i] - TriArr^[(i + 1) mod 3]).Perp;
    d[i] := n[i].Dot(TriArr^[i]);
  end;
  if xmin or xmax or ymin or ymax then Exit(False);
  if n[0].Dot(TriArr^[2]) > d[0] then
  for i := 0 to 2 do
  begin
    n[i] := -n[i];
    d[i] := -d[i];
  end;
  for i := 0 to 2 do
  begin
    if n[i].x >= 0 then vmin.x := r.l else vmin.x := r.r;
    if n[i].y >= 0 then vmin.y := r.t else vmin.y := r.b;
    if n[i].Dot(vmin) - d[i] > 0 then Exit(False);
  end;
end;

function LabRay2VsRect(const RayOrigin, RayDir: TLabVec2; const R: TLabRect; var Intersection: TLabVec2; var Dist: TLabFloat): Boolean;
  var d, t, t0, t1, tn, tf: TLabFloat;
  var i: TLabInt32;
begin
  Result := False;
  tn := -1E+16;
  tf := 1E+16;
  for i := 0 to 1 do
  begin
    if Abs(RayDir[i]) < LabEPS then
    begin
      if (RayOrigin[i] < R.TopLeft[i])
      or (RayOrigin[i] > R.BottomRight[i]) then
      Exit;
    end;
    d := 1 / RayDir[i];
    t0 := (R.TopLeft[i] - RayOrigin[i]) * d;
    t1 := (R.BottomRight[i] - RayOrigin[i]) * d;
    if t0 > t1 then
    begin
      t := t1;
      t1 := t0;
      t0 := t;
    end;
    if t0 > tn then
    tn := t0;
    if t1 < tf then
    tf := t1;
    if (tn > tf) or (tf < 0) then Exit;
  end;
  if tn > 0 then
  begin
    Intersection.x := RayOrigin.x + RayDir.x * tn;
    Intersection.y := RayOrigin.y + RayDir.y * tn;
    Dist := tn;
  end
  else
  begin
    Intersection.x := RayOrigin.x + RayDir.x * tf;
    Intersection.y := RayOrigin.y + RayDir.y * tf;
    Dist := tf;
  end;
  Result := True;
end;

function LabBallistics(const PosOrigin, PosTarget: TLabVec2; const TotalVelocity, Gravity: TLabFloat; var Trajectory0, Trajectory1: TLabVec2; var Time0, Time1: TLabFloat): Boolean;
  var x, y, x2, vt2, vt4, gr, gr2, dc, n0, n1, t2, t, vx, vy: Double;
begin
  x := PosTarget.x - PosOrigin.x;
  x2 := x * x;
  y := PosTarget.y - PosOrigin.y;
  vt2 := TotalVelocity * TotalVelocity;
  vt4 := vt2 * vt2;
  gr := Gravity; gr2 := gr * gr;
  dc := 16 * (2 * vt2 * y * gr + vt4 -  x2 * gr2);
  if dc > 0 then
  begin
    dc := Sqrt(dc);
    n0 := 4 * vt2 + 4 * y * gr;
    n1 := 1 / (2 * gr2);
    t2 := (n0 - dc) * n1;
    if t2 >= 0 then
    begin
      t := Sqrt(t2);
      vx := x / t;
      vy := (2 * y - gr * t2) / (2 * t);
      vx := Sqrt(vt2 - vy * vy);
      if (x < 0) <> (vx < 0) then vx := -vx;
      Trajectory0.x := vx;
      Trajectory0.y := vy;
      if Trajectory0.Len > TotalVelocity then
      Trajectory0 := Trajectory0.Norm * TotalVelocity;
      Time0 := t;
    end
    else
    begin
      Trajectory0.SetValue(0, 0);
      Time0 := 0;
      Result := False;
      Exit;
    end;
    t2 := (n0 + dc) * n1;
    if t2 >= 0 then
    begin
      t := Sqrt(t2);
      vx := x / t;
      vy := (2 * y - gr * t2) / (2 * t);
      Trajectory1.x := vx;
      Trajectory1.y := vy;
      if Trajectory1.Len > TotalVelocity then
      Trajectory1 := Trajectory1.Norm * TotalVelocity;
      Time1 := t;
    end
    else
    begin
      Trajectory1.SetValue(0, 0);
      Time1 := 0;
      Result := False;
      Exit;
    end;
    Result := True;
  end
  else
  begin
    Trajectory0.SetValue(0, 0);
    Trajectory1.SetValue(0, 0);
    Time0 := 0;
    Time1 := 0;
    Result := False;
  end;
end;

procedure LabMatAdd(const OutM, InM1, InM2: PLabMat);
begin
  with OutM^ do
  begin
    e00 := InM1^.e00 + InM2^.e00; e10 := InM1^.e10 + InM2^.e10; e20 := InM1^.e20 + InM2^.e20; e30 := InM1^.e30 + InM2^.e30;
    e01 := InM1^.e01 + InM2^.e01; e11 := InM1^.e11 + InM2^.e11; e21 := InM1^.e21 + InM2^.e21; e31 := InM1^.e31 + InM2^.e31;
    e02 := InM1^.e02 + InM2^.e02; e12 := InM1^.e12 + InM2^.e12; e22 := InM1^.e22 + InM2^.e22; e32 := InM1^.e32 + InM2^.e32;
    e03 := InM1^.e03 + InM2^.e03; e13 := InM1^.e13 + InM2^.e13; e23 := InM1^.e23 + InM2^.e23; e33 := InM1^.e33 + InM2^.e33;
  end;
end;

procedure LabMatSub(const OutM, InM1, InM2: PLabMat);
begin
  with OutM^ do
  begin
    e00 := InM1^.e00 - InM2^.e00; e10 := InM1^.e10 - InM2^.e10; e20 := InM1^.e20 - InM2^.e20; e30 := InM1^.e30 - InM2^.e30;
    e01 := InM1^.e01 - InM2^.e01; e11 := InM1^.e11 - InM2^.e11; e21 := InM1^.e21 - InM2^.e21; e31 := InM1^.e31 - InM2^.e31;
    e02 := InM1^.e02 - InM2^.e02; e12 := InM1^.e12 - InM2^.e12; e22 := InM1^.e22 - InM2^.e22; e32 := InM1^.e32 - InM2^.e32;
    e03 := InM1^.e03 - InM2^.e03; e13 := InM1^.e13 - InM2^.e13; e23 := InM1^.e23 - InM2^.e23; e33 := InM1^.e33 - InM2^.e33;
  end;
end;

procedure LabMatFltMul(const OutM, InM: PLabMat; const s: PLabFloat);
begin
  OutM^.e00 := InM^.e00 * s^;
  OutM^.e10 := InM^.e10 * s^;
  OutM^.e20 := InM^.e20 * s^;
  OutM^.e30 := InM^.e30 * s^;
  OutM^.e01 := InM^.e01 * s^;
  OutM^.e11 := InM^.e11 * s^;
  OutM^.e21 := InM^.e21 * s^;
  OutM^.e31 := InM^.e31 * s^;
  OutM^.e02 := InM^.e02 * s^;
  OutM^.e12 := InM^.e12 * s^;
  OutM^.e22 := InM^.e22 * s^;
  OutM^.e32 := InM^.e32 * s^;
  OutM^.e03 := InM^.e03 * s^;
  OutM^.e13 := InM^.e13 * s^;
  OutM^.e23 := InM^.e23 * s^;
  OutM^.e33 := InM^.e33 * s^;
end;

procedure LabMatMul(const OutM, InM1, InM2: PLabMat);
  var mr: TLabMat;
begin
  with mr do
  begin
    e00 := InM1^.e00 * InM2^.e00 + InM1^.e01 * InM2^.e10 + InM1^.e02 * InM2^.e20 + InM1^.e03 * InM2^.e30;
    e10 := InM1^.e10 * InM2^.e00 + InM1^.e11 * InM2^.e10 + InM1^.e12 * InM2^.e20 + InM1^.e13 * InM2^.e30;
    e20 := InM1^.e20 * InM2^.e00 + InM1^.e21 * InM2^.e10 + InM1^.e22 * InM2^.e20 + InM1^.e23 * InM2^.e30;
    e30 := InM1^.e30 * InM2^.e00 + InM1^.e31 * InM2^.e10 + InM1^.e32 * InM2^.e20 + InM1^.e33 * InM2^.e30;
    e01 := InM1^.e00 * InM2^.e01 + InM1^.e01 * InM2^.e11 + InM1^.e02 * InM2^.e21 + InM1^.e03 * InM2^.e31;
    e11 := InM1^.e10 * InM2^.e01 + InM1^.e11 * InM2^.e11 + InM1^.e12 * InM2^.e21 + InM1^.e13 * InM2^.e31;
    e21 := InM1^.e20 * InM2^.e01 + InM1^.e21 * InM2^.e11 + InM1^.e22 * InM2^.e21 + InM1^.e23 * InM2^.e31;
    e31 := InM1^.e30 * InM2^.e01 + InM1^.e31 * InM2^.e11 + InM1^.e32 * InM2^.e21 + InM1^.e33 * InM2^.e31;
    e02 := InM1^.e00 * InM2^.e02 + InM1^.e01 * InM2^.e12 + InM1^.e02 * InM2^.e22 + InM1^.e03 * InM2^.e32;
    e12 := InM1^.e10 * InM2^.e02 + InM1^.e11 * InM2^.e12 + InM1^.e12 * InM2^.e22 + InM1^.e13 * InM2^.e32;
    e22 := InM1^.e20 * InM2^.e02 + InM1^.e21 * InM2^.e12 + InM1^.e22 * InM2^.e22 + InM1^.e23 * InM2^.e32;
    e32 := InM1^.e30 * InM2^.e02 + InM1^.e31 * InM2^.e12 + InM1^.e32 * InM2^.e22 + InM1^.e33 * InM2^.e32;
    e03 := InM1^.e00 * InM2^.e03 + InM1^.e01 * InM2^.e13 + InM1^.e02 * InM2^.e23 + InM1^.e03 * InM2^.e33;
    e13 := InM1^.e10 * InM2^.e03 + InM1^.e11 * InM2^.e13 + InM1^.e12 * InM2^.e23 + InM1^.e13 * InM2^.e33;
    e23 := InM1^.e20 * InM2^.e03 + InM1^.e21 * InM2^.e13 + InM1^.e22 * InM2^.e23 + InM1^.e23 * InM2^.e33;
    e33 := InM1^.e30 * InM2^.e03 + InM1^.e31 * InM2^.e13 + InM1^.e32 * InM2^.e23 + InM1^.e33 * InM2^.e33;
  end;
  OutM^ := mr;
end;

procedure LabMatInv(const OutM, InM: PLabMat);
  var d, di: TLabFloat;
begin
  di := InM^.e00;
  d := 1 / di;
  with OutM^ do
  begin
    e00 := d;
    e10 := -InM^.e10 * d;
    e20 := -InM^.e20 * d;
    e30 := -InM^.e30 * d;
    e01 := InM^.e01 * d;
    e02 := InM^.e02 * d;
    e03 := InM^.e03 * d;
    e11 := InM^.e11 + e10 * e01 * di;
    e12 := InM^.e12 + e10 * e02 * di;
    e13 := InM^.e13 + e10 * e03 * di;
    e21 := InM^.e21 + e20 * e01 * di;
    e22 := InM^.e22 + e20 * e02 * di;
    e23 := InM^.e23 + e20 * e03 * di;
    e31 := InM^.e31 + e30 * e01 * di;
    e32 := InM^.e32 + e30 * e02 * di;
    e33 := InM^.e33 + e30 * e03 * di;
    di := e11;
    d := 1 / di;
    e11 := d;
    e01 := -e01 * d;
    e21 := -e21 * d;
    e31 := -e31 * d;
    e10 := e10 * d;
    e12 := e12 * d;
    e13 := e13 * d;
    e00 := e00 + e01 * e10 * di;
    e02 := e02 + e01 * e12 * di;
    e03 := e03 + e01 * e13 * di;
    e20 := e20 + e21 * e10 * di;
    e22 := e22 + e21 * e12 * di;
    e23 := e23 + e21 * e13 * di;
    e30 := e30 + e31 * e10 * di;
    e32 := e32 + e31 * e12 * di;
    e33 := e33 + e31 * e13 * di;
    di := e22;
    d := 1 / di;
    e22 := d;
    e02 := -e02 * d;
    e12 := -e12 * d;
    e32 := -e32 * d;
    e20 := e20 * d;
    e21 := e21 * d;
    e23 := e23 * d;
    e00 := e00 + e02 * e20 * di;
    e01 := e01 + e02 * e21 * di;
    e03 := e03 + e02 * e23 * di;
    e10 := e10 + e12 * e20 * di;
    e11 := e11 + e12 * e21 * di;
    e13 := e13 + e12 * e23 * di;
    e30 := e30 + e32 * e20 * di;
    e31 := e31 + e32 * e21 * di;
    e33 := e33 + e32 * e23 * di;
    di := e33;
    d := 1 / di;
    e33 := d;
    e03 := -e03 * d;
    e13 := -e13 * d;
    e23 := -e23 * d;
    e30 := e30 * d;
    e31 := e31 * d;
    e32 := e32 * d;
    e00 := e00 + e03 * e30 * di;
    e01 := e01 + e03 * e31 * di;
    e02 := e02 + e03 * e32 * di;
    e10 := e10 + e13 * e30 * di;
    e11 := e11 + e13 * e31 * di;
    e12 := e12 + e13 * e32 * di;
    e20 := e20 + e23 * e30 * di;
    e21 := e21 + e23 * e31 * di;
    e22 := e22 + e23 * e32 * di;
  end;
end;

procedure LabVec2MatMul3x3(const OutV, InV: PLabVec2; const InM: PLabMat);
  var vr: TLabVec2;
begin
  vr.x := InV^.x * InM^.e00 + InV^.y * InM^.e10;
  vr.y := InV^.x * InM^.e01 + InV^.y * InM^.e11;
  OutV^ := vr;
end;

procedure LabVec2MatMul4x3(const OutV, InV: PLabVec2; const InM: PLabMat);
  var vr: TLabVec2;
begin
  vr.x := InV^.x * InM^.e00 + InV^.y * InM^.e10 + InM^.e30;
  vr.y := InV^.x * InM^.e01 + InV^.y * InM^.e11 + InM^.e31;
  OutV^ := vr;
end;

procedure LabVec2MatMul4x4(const OutV, InV: PLabVec2; const InM: PLabMat);
  var vr: TLabVec2;
  var w: TLabFloat;
begin
  vr.x := InV^.x * InM^.e00 + InV^.y * InM^.e10 + InM^.e30;
  vr.y := InV^.x * InM^.e01 + InV^.y * InM^.e11 + InM^.e31;
  w := 1 / (InV^.x * InM^.e03 + InV^.y * InM^.e13 + InM^.e33);
  OutV^.x := vr.x * w;
  OutV^.y := vr.y * w;
end;

procedure LabVec2Rotation2Mul(const OutV, InV: PLabVec2; const InR: PLabRotation2);
  var r: TLabVec2;
begin
  {$warnings off}
  r.SetValue(
    InV^.x * InR^.c - InV^.y * InR^.s,
    InV^.x * InR^.s + InV^.y * InR^.c
  );
  {$warnings on}
  OutV^ := r;
end;

procedure LabVec2Rotation2MulInv(const OutV, InV: PLabVec2; const InR: PLabRotation2);
  var r: TLabVec2;
begin
  {$warnings off}
  r.SetValue(
    InV^.x * InR^.c + InV^.y * InR^.s,
    InV^.y * InR^.c - InV^.x * InR^.s
  );
  {$warnings on}
  OutV^ := r;
end;

procedure LabVec2Transform2Mul(const OutV, InV: PLabVec2; const InT: PLabTransform2);
begin
  {$warnings off}
  OutV^.SetValue(
    (InT^.r.c * InV^.x - InT^.r.s * InV^.y) + InT^.p.x,
    (InT^.r.s * InV^.x + InT^.r.c * InV^.y) + InT^.p.y
  );
  {$warnings on}
end;

procedure LabVec2Transform2MulInv(const OutV, InV: PLabVec2; const InT: PLabTransform2);
  var px, py: TLabFloat;
begin
  px := InV^.x - InT^.p.x;
  py := InV^.y - InT^.p.y;
  {$warnings off}
  OutV^.SetValue(InT^.r.c * px + InT^.r.s * py, -InT^.r.s * px + InT^.r.c * py);
  {$warnings on}
end;

procedure LabVec3MatMul3x3(const OutV, InV: PLabVec3; const InM: PLabMat);
  var vr: TLabVec3;
begin
  vr.x := InV^.x * InM^.e00 + InV^.y * InM^.e10 + InV^.z * InM^.e20;
  vr.y := InV^.x * InM^.e01 + InV^.y * InM^.e11 + InV^.z * InM^.e21;
  vr.z := InV^.x * InM^.e02 + InV^.y * InM^.e12 + InV^.z * InM^.e22;
  OutV^ := vr;
end;

procedure LabVec3MatMul4x3(const OutV, InV: PLabVec3; const InM: PLabMat);
  var vr: TLabVec3;
begin
  vr.x := InV^.x * InM^.e00 + InV^.y * InM^.e10 + InV^.z * InM^.e20 + InM^.e30;
  vr.y := InV^.x * InM^.e01 + InV^.y * InM^.e11 + InV^.z * InM^.e21 + InM^.e31;
  vr.z := InV^.x * InM^.e02 + InV^.y * InM^.e12 + InV^.z * InM^.e22 + InM^.e32;
  OutV^ := vr;
end;

procedure LabVec3MatMul4x4(const OutV, InV: PLabVec3; const InM: PLabMat);
  var vr: TLabVec3;
  var w: TLabFloat;
begin
  vr.x := InV^.x * InM^.e00 + InV^.y * InM^.e10 + InV^.z * InM^.e20 + InM^.e30;
  vr.y := InV^.x * InM^.e01 + InV^.y * InM^.e11 + InV^.z * InM^.e21 + InM^.e31;
  vr.z := InV^.x * InM^.e02 + InV^.y * InM^.e12 + InV^.z * InM^.e22 + InM^.e32;
  w := 1 / (InV^.x * InM^.e03 + InV^.y * InM^.e13 + InV^.z * InM^.e23 + InM^.e33);
  OutV^.x := vr.x * w;
  OutV^.y := vr.y * w;
  OutV^.z := vr.z * w;
end;

procedure LabVec4MatMul(const OutV, InV: PLabVec4; const InM: PLabMat);
  var vr: TLabVec4;
begin
  vr.x := InV^.x * InM^.e00 + InV^.y * InM^.e10 + InV^.z * InM^.e20 + InV^.w * InM^.e30;
  vr.y := InV^.x * InM^.e01 + InV^.y * InM^.e11 + InV^.z * InM^.e21 + InV^.w * InM^.e31;
  vr.z := InV^.x * InM^.e02 + InV^.y * InM^.e12 + InV^.z * InM^.e22 + InV^.w * InM^.e32;
  vr.w := InV^.x * InM^.e03 + InV^.y * InM^.e13 + InV^.z * InM^.e23 + InV^.w * InM^.e33;
  OutV^ := vr;
end;

function LabVec3Len(const InV: PLabVec3): TLabFloat;
begin
  Result := Sqrt(InV^.x * InV^.x + InV^.y * InV^.y + InV^.z * InV^.z);
end;

function LabVec4Len(const InV: PLabVec4): TLabFloat;
begin
  Result := Sqrt(InV^.x * InV^.x + InV^.y * InV^.y + InV^.z * InV^.z + InV^.w * InV^.w);
end;

procedure LabVec2Norm(const OutV, InV: PLabVec2);
  var d: TLabFloat;
begin
  d := Sqrt(InV^.x * InV^.x + InV^.y * InV^.y);
  if d > 0 then
  begin
    d := 1 / d;
    OutV^.x := InV^.x * d;
    OutV^.y := InV^.y * d;
  end
  else
  begin
    OutV^.x := 0;
    OutV^.y := 0;
  end;
end;

procedure LabVec3Norm(const OutV, InV: PLabVec3);
  var d: TLabFloat;
begin
  d := Sqrt(InV^.x * InV^.x + InV^.y * InV^.y + InV^.z * InV^.z);
  if d > 0 then
  begin
    d := 1 / d;
    OutV^.x := InV^.x * d;
    OutV^.y := InV^.y * d;
    OutV^.z := InV^.z * d;
  end
  else
  begin
    OutV^.x := 0;
    OutV^.y := 0;
    OutV^.z := 0;
  end;
end;

procedure LabVec4Norm(const OutV, InV: PLabVec4);
  var d: TLabFloat;
begin
  d := Sqrt(InV^.x * InV^.x + InV^.y * InV^.y + InV^.z * InV^.z + InV^.w * InV^.w);
  if d > 0 then
  begin
    d := 1 / d;
    OutV^.x := InV^.x * d;
    OutV^.y := InV^.y * d;
    OutV^.z := InV^.z * d;
    OutV^.w := InV^.w * d;
  end
  else
  begin
    OutV^.x := 0;
    OutV^.y := 0;
    OutV^.z := 0;
    OutV^.w := 0;
  end;
end;

procedure LabVec3Cross(const OutV, InV1, InV2: PLabVec3);
begin
  OutV^.x := InV1^.y * InV2^.z - InV1^.z * InV2^.y;
  OutV^.y := InV1^.z * InV2^.x - InV1^.x * InV2^.z;
  OutV^.z := InV1^.x * InV2^.y - InV1^.y * InV2^.x;
end;

procedure LabRotation2Mul(const OutR, InR1, InR2: PLabRotation2);
  var r: TLabRotation2;
begin
  {$warnings off}
  r.SetValue(
    InR2^.s * InR1^.c + InR2^.c * InR1^.s,
    InR2^.c * InR1^.c - InR2^.s * InR1^.s
  );
  {$warnings on}
  OutR^ := r;
end;

procedure LabRotation2MulInv(const OutR, InR1, InR2: PLabRotation2);
  var r: TLabRotation2;
begin
  {$warnings off}
  r.SetValue(
    InR2^.c * InR1^.s - InR2^.s * InR1^.c,
    InR2^.c * InR1^.c + InR2^.s * InR1^.s
  );
  {$warnings on}
  OutR^ := r;
end;

procedure LabTransform2Mul(const OutT, InT1, InT2: PLabTransform2);
  var rt: TLabTransform2;
begin
  LabVec2Rotation2Mul(@rt.p, @InT1^.p, @InT2^.r);
  rt.p += InT2^.p;
  LabRotation2Mul(@rt.r, @InT1^.r, @InT2^.r);
  OutT^ := rt;
end;

procedure LabTransform2MulInv(const OutT, InT1, InT2: PLabTransform2);
  var rt: TLabTransform2;
  var dp: TLabVec2;
begin
  dp := InT1^.p - InT2^.p;
  LabVec2Rotation2MulInv(@rt.p, @dp, @InT2^.r);
  LabRotation2MulInv(@rt.r, @InT1^.r, @InT2^.r);
  OutT^ := rt;
end;

end.

