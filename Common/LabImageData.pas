unit LabImageData;

{$mode objfpc}

interface

uses
  Types,
  Classes,
  ZBase,
  ZInflate,
  ZDeflate,
  SysUtils,
  LabTypes,
  LabMath,
  LabUtils;

type
  TLabImageDataFormat = (
    idf_none,
    idf_g8,
    idf_g16,
    idf_g8a8,
    idf_g16a16,
    idf_r8g8b8,
    idf_r16g16b16,
    idf_r8g8b8a8,
    idf_r16g16b16a16,
    idf_r32g32b32_f
  );

  TLabImagePixelReadProc = function (const x, y: Integer): TLabColor of Object;
  TLabImagePixelWriteProc = procedure (const x, y: Integer; const Value: TLabColor) of Object;

  TLabImageData = class
  protected
    _Width: Integer;
    _Height: Integer;
    _BPP: Integer;
    _Data: Pointer;
    _DataSize: LongWord;
    _Format: TLabImageDataFormat;
    _ReadProc: TLabImagePixelReadProc;
    _WriteProc: TLabImagePixelWriteProc;
    procedure SetFormat(const f: TLabImageDataFormat);
    function GetPixel(const x, y: Integer): TLabColor;
    function ReadNone(const x, y: Integer): TLabColor;
    function ReadG8(const x, y: Integer): TLabColor;
    function ReadG16(const x, y: Integer): TLabColor;
    function ReadG8A8(const x, y: Integer): TLabColor;
    function ReadG16A16(const x, y: Integer): TLabColor;
    function ReadR8G8B8(const x, y: Integer): TLabColor;
    function ReadR16G16B16(const x, y: Integer): TLabColor;
    function ReadR8G8B8A8(const x, y: Integer): TLabColor;
    function ReadR16G16B16A16(const x, y: Integer): TLabColor;
    function ReadR32G32B32_F(const x, y: Integer): TLabColor;
    procedure SetPixel(const x, y: Integer; const Value: TLabColor);
    procedure WriteNone(const x, y: Integer; const Value: TLabColor);
    procedure WriteG8(const x, y: Integer; const Value: TLabColor);
    procedure WriteG16(const x, y: Integer; const Value: TLabColor);
    procedure WriteG8A8(const x, y: Integer; const Value: TLabColor);
    procedure WriteG16A16(const x, y: Integer; const Value: TLabColor);
    procedure WriteR8G8B8(const x, y: Integer; const Value: TLabColor);
    procedure WriteR16G16B16(const x, y: Integer; const Value: TLabColor);
    procedure WriteR8G8B8A8(const x, y: Integer; const Value: TLabColor);
    procedure WriteR16G16B16A16(const x, y: Integer; const Value: TLabColor);
    procedure WriteR32G32B32_F(const x, y: Integer; const Value: TLabColor);
    procedure DataAlloc; overload;
    procedure DataAlloc(const Size: LongWord); overload;
    procedure DataFree;
    class procedure RegisterImageFormat;
  public
    property Width: Integer read _Width;
    property Height: Integer read _Height;
    property Data: Pointer read _Data;
    property BPP: Integer read _BPP;
    property DataSize: LongWord read _DataSize;
    property Format: TLabImageDataFormat read _Format;
    property Pixels[const x, y: Integer]: TLabColor read GetPixel write SetPixel; default;
    function DataAt(const x, y: Integer): Pointer; inline;
    class function CanLoad(const Stream: TStream): Boolean; virtual; overload;
    class function CanLoad(const FileName: String): Boolean; virtual; overload;
    class function CanLoad(const Buffer: Pointer; const Size: Integer): Boolean; virtual; overload;
    class function CanLoad(const StreamHelper: TLabStreamHelper): Boolean; virtual; abstract; overload;
    procedure Load(const Stream: TStream); virtual; overload;
    procedure Load(const FileName: String); virtual; overload;
    procedure Load(const Buffer: Pointer; const Size: Integer); virtual; overload;
    procedure Load(const StreamHelper: TLabStreamHelper); virtual; abstract; overload;
    procedure Save(const Stream: TStream); virtual; overload;
    procedure Save(const FileName: String); virtual; overload;
    procedure Save(const StreamHelper: TLabStreamHelper); virtual; abstract; overload;
    procedure Allocate(const NewFormat: TLabImageDataFormat; const NewWidth, NewHeight: Integer);
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TLabImageDataClass = class of TLabImageData;

  TLabImageDataPNG = class(TLabImageData)
  protected
    class procedure Decompress(const Buffer: Pointer; const Size: Integer; const Output: TStream);
    class procedure Compress(const Buffer: Pointer; const Size: Integer; const Output: TStream);
    class function Swap16(const n: Word): Word;
    class function Swap32(const n: LongWord): LongWord;
    class function GetCRC(const Buffer: Pointer; const Size: Integer): LongWord;
  public
    class constructor CreateClass;
    class function CanLoad(const StreamHelper: TLabStreamHelper): Boolean; override;
    procedure Load(const StreamHelper: TLabStreamHelper); override;
    procedure Save(const StreamHelper: TLabStreamHelper); override;
  end;

  TLabImageDataHDR = class(TLabImageData)
  protected
    class function CompareHeader(const Test: AnsiString; const StreamHelper: TLabStreamHelper): Boolean;
    class function ReadToken(const StreamHelper: TLabStreamHelper): String;
  public
    class constructor CreateClass;
    class function CanLoad(const StreamHelper: TLabStreamHelper): Boolean; override;
    procedure Load(const StreamHelper: TLabStreamHelper); override;
    procedure Save(const StreamHelper: TLabStreamHelper); override;
  end;

var ImageFormats: array of TLabImageDataClass;
procedure LabRegisterImageFormat(const ImageType: TLabImageDataClass);
function LabPickImageFormat(const StreamHelper: TLabStreamHelper): TLabImageDataClass;
function LabPickImageFormat(const Stream: TStream): TLabImageDataClass;
function LabPickImageFormat(const FileName: String): TLabImageDataClass;
function LabPickImageFormat(const Buffer: Pointer; const Size: Integer): TLabImageDataClass;

implementation

uses
  Math;

const HDRHeaders: array[0..1] of AnsiString = ('#?RADIANCE', '#?RGBE');

procedure LabRegisterImageFormat(const ImageType: TLabImageDataClass);
  var f: TLabImageDataClass;
begin
  for f in ImageFormats do
  if f = ImageType then Exit;
  SetLength(ImageFormats, Length(ImageFormats) + 1);
  ImageFormats[High(ImageFormats)] := ImageType;
end;

function LabPickImageFormat(const StreamHelper: TLabStreamHelper): TLabImageDataClass;
  var f: TLabImageDataClass;
begin
  for f in ImageFormats do
  if f.CanLoad(StreamHelper) then Exit(f);
  Result := nil;
end;

function LabPickImageFormat(const Stream: TStream): TLabImageDataClass;
  var sh: TLabStreamHelper;
begin
  sh := TLabStreamHelper.Create(Stream);
  try
    Result := LabPickImageFormat(sh);
  finally
    sh.Free;
  end;
end;

function LabPickImageFormat(const FileName: String): TLabImageDataClass;
  var fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead);
  try
    Result := LabPickImageFormat(fs);
  finally
    fs.Free;
  end;
end;

function LabPickImageFormat(const Buffer: Pointer; const Size: Integer): TLabImageDataClass;
  var ms: TLabConstMemoryStream;
begin
  ms := TLabConstMemoryStream.Create(Buffer, Size);
  try
    Result := LabPickImageFormat(ms);
  finally
    ms.Free;
  end;
end;

class function TLabImageDataHDR.CompareHeader(const Test: AnsiString; const StreamHelper: TLabStreamHelper): Boolean;
  var header: AnsiString;
begin
  if StreamHelper.Remaining <= Length(Test) then Exit(False);
  StreamHelper.PosPush;
  SetLength(header, Length(Test));
  StreamHelper.ReadBuffer(@header[1], Length(Test));
  Result := header = Test;
  StreamHelper.PosPop;
end;

class function TLabImageDataHDR.ReadToken(const StreamHelper: TLabStreamHelper): String;
  var n: TLabUInt8;
begin
  StreamHelper.PosPush;
  n := 0;
  repeat
    if AnsiChar(StreamHelper.ReadUInt8) = #$A then Break;
    Inc(n);
  until StreamHelper.EoF;
  StreamHelper.PosPop;
  if n > 0 then
  begin
    SetLength(Result, n);
    StreamHelper.ReadBuffer(@Result[1], n);
  end
  else
  begin
    Result := '';
  end;
  StreamHelper.Skip(1);
end;

class constructor TLabImageDataHDR.CreateClass;
begin
  RegisterImageFormat;
end;

class function TLabImageDataHDR.CanLoad(const StreamHelper: TLabStreamHelper): Boolean;
  var i: TLabInt32;
begin
  for i := 0 to High(HDRHeaders) do
  if CompareHeader(HDRHeaders[i], StreamHelper) then Exit(True);
  Result := False;
end;

procedure TLabImageDataHDR.Load(const StreamHelper: TLabStreamHelper);
  type TRGBE = array[0..3] of TLabUInt8;
  procedure WritePixel(const rgbe: TRGBE; const x, y: TLabUInt32);
    var f1: TLabFloat;
    var d: PLabFloatArr;
  begin
    d := PLabFloatArr(DataAt(x, y));
    if rgbe[3] <> 0 then
    begin
      f1 := Math.ldexp(1.0, rgbe[3] - (128 + 8));
      d^[0] := rgbe[0] * f1;
      d^[1] := rgbe[1] * f1;
      d^[2] := rgbe[2] * f1;
    end
    else
    begin
       d^[0] := 0;
       d^[1] := 0;
       d^[2] := 0;
    end;
  end;
  var token: AnsiString;
  var token_arr: TLabStrArrA;
  var format_valid: Boolean;
  var w, h, j, i, k, n, z, len: TLabUInt32;
  var c, v: TLabUInt8;
  var rgbe: TRGBE;
  var scanline: array of TRGBE;
  var c1, c2: TLabUInt8;
begin
  ReadToken(StreamHelper);
  format_valid := False;
  repeat
    token := ReadToken(StreamHelper);
    if token = 'FORMAT=32-bit_rle_rgbe' then format_valid := True;
  until Length(token) = 0;
  if not format_valid then Exit;
  token := ReadToken(StreamHelper);
  token_arr := LabStrExplode(token, ' ');
  if Length(token_arr) < 4 then Exit;
  w := 0; h := 0;
  if token_arr[0] = '-Y' then h := StrToIntDef(token_arr[1], 0);
  if token_arr[2] = '+X' then w := StrToIntDef(token_arr[3], 0);
  Allocate(idf_r32g32b32_f, w, h);
  if (w < 8) or (w >= 32768) then
  begin
    for j := 0 to h - 1 do
    for i := 0 to w - 1 do
    begin
      StreamHelper.ReadBuffer(@rgbe, 4);
      WritePixel(rgbe, i, j);
    end;
  end
  else
  begin
    for j := 0 to h - 1 do
    begin
      c1 := StreamHelper.ReadUInt8;
      c2 := StreamHelper.ReadUInt8;
      len := StreamHelper.ReadUInt8;
      if (c1 <> 2) or (c2 <> 2) or (len and $80 > 0) then
      begin
       StreamHelper.Skip(-3);
       for i := 0 to w - 1 do
       begin
         StreamHelper.ReadBuffer(@rgbe, 4);
         WritePixel(rgbe, i, j);
       end;
       Continue;
      end;
      len := len shl 8;
      len := len or StreamHelper.ReadUInt8;
      if len <> w then Exit;
      if Length(scanline) = 0 then SetLength(scanline, w);
      for k := 0 to 3 do
      begin
        i := 0;
        n := width - i;
        while (n > 0) do
        begin
          c := StreamHelper.ReadUInt8;
          if c > 128 then
          begin
            v := StreamHelper.ReadUInt8;
            c -= 128;
            if c > n then Exit;
            for z := 0 to c - 1 do
            begin
              scanline[i][k] := v;
              Inc(i);
            end;
          end
          else
          begin
            if c > n then Exit;
            for z := 0 to c - 1 do
            begin
              scanline[i][k] := StreamHelper.ReadUInt8;
              Inc(i);
            end;
          end;
          n := width - i;
        end;
      end;
      for i := 0 to w - 1 do
      begin
        WritePixel(scanline[i], i, j);
      end;
    end;
  end;
end;

procedure TLabImageDataHDR.Save(const StreamHelper: TLabStreamHelper);
begin

end;

procedure TLabImageData.SetFormat(const f: TLabImageDataFormat);
begin
  _Format := f;
  case _Format of
    idf_none:
    begin
      _BPP := 0;
      _ReadProc := @ReadNone;
      _WriteProc := @WriteNone;
    end;
    idf_g8:
    begin
      _BPP := 1;
      _ReadProc := @ReadG8;
      _WriteProc := @WriteG8;
    end;
    idf_g16:
    begin
      _BPP := 2;
      _ReadProc := @ReadG16;
      _WriteProc := @WriteG16;
    end;
    idf_g8a8:
    begin
      _BPP := 2;
      _ReadProc := @ReadG8A8;
      _WriteProc := @WriteG8A8;
    end;
    idf_g16a16:
    begin
      _BPP := 4;
      _ReadProc := @ReadG16A16;
      _WriteProc := @WriteG16A16;
    end;
    idf_r8g8b8:
    begin
      _BPP := 3;
      _ReadProc := @ReadR8G8B8;
      _WriteProc := @WriteR8G8B8;
    end;
    idf_r16g16b16:
    begin
      _BPP := 6;
      _ReadProc := @ReadR16G16B16;
      _WriteProc := @WriteR16G16B16;
    end;
    idf_r8g8b8a8:
    begin
      _BPP := 4;
      _ReadProc := @ReadR8G8B8A8;
      _WriteProc := @WriteR8G8B8A8;
    end;
    idf_r16g16b16a16:
    begin
      _BPP := 8;
      _ReadProc := @ReadR16G16B16A16;
      _WriteProc := @WriteR16G16B16A16;
    end;
    idf_r32g32b32_f:
    begin
      _BPP := 12;
      _ReadProc := @ReadR32G32B32_F;
      _WriteProc := @WriteR32G32B32_F;
    end;
  end;
end;

function TLabImageData.GetPixel(const x, y: Integer): TLabColor;
begin
  Result := _ReadProc(x, y);
end;

{$Hints off}
function TLabImageData.ReadNone(const x, y: Integer): TLabColor;
begin
  PLongWord(@Result)^ := 0;
end;
{$Hints on}

function TLabImageData.ReadG8(const x, y: Integer): TLabColor;
  var c: Byte;
begin
  c := PByte(_Data + y * _Width + x)^;
  Result.r := c;
  Result.g := c;
  Result.b := c;
  Result.a := $ff;
end;

function TLabImageData.ReadG16(const x, y: Integer): TLabColor;
  var c: Byte;
begin
  c := PByte(_Data + (y * _Width + x) * _BPP + 1)^;
  Result.r := c;
  Result.g := c;
  Result.b := c;
  Result.a := $ff;
end;

function TLabImageData.ReadG8A8(const x, y: Integer): TLabColor;
  var d: Word;
  var c: Byte;
begin
  d := PWord(_Data + (y * _Width + x) * _BPP)^;
  c := d and $ff;
  Result.r := c;
  Result.g := c;
  Result.b := c;
  Result.a := (d shr 8) and $ff;
end;

function TLabImageData.ReadG16A16(const x, y: Integer): TLabColor;
  var d: LongWord;
  var c: Byte;
begin
  d := PLongWord(_Data + (y * _Width + x) * _BPP)^;
  c := (d shr 8) and $ff;
  Result.r := c;
  Result.g := c;
  Result.b := c;
  Result.a := (d shr 24) and $ff;
end;

function TLabImageData.ReadR8G8B8(const x, y: Integer): TLabColor;
  var d: LongWord;
begin
  d := PLongWord(_Data + (y * _Width + x) * _BPP)^ and $ffffff;
  Result.r := d and $ff;
  Result.g := (d shr 8) and $ff;
  Result.b := (d shr 16) and $ff;
  Result.a := $ff;
end;

function TLabImageData.ReadR16G16B16(const x, y: Integer): TLabColor;
  var b: PByte;
begin
  b := PByte(_Data + (y * _Width + x) * _BPP + 1);
  Result.r := b^; Inc(b, 2);
  Result.g := b^; Inc(b, 2);
  Result.b := b^;
  Result.a := $ff;
end;

function TLabImageData.ReadR8G8B8A8(const x, y: Integer): TLabColor;
begin
  PLongWord(@Result)^ := PLongWord(_Data + (y * _Width + x) * _BPP)^;
end;

function TLabImageData.ReadR16G16B16A16(const x, y: Integer): TLabColor;
  var d: PByte;
begin
  d := PByte(_Data + (y * _Width + x) * _BPP + 1);
  Result.r := d^; Inc(d, 2);
  Result.g := d^; Inc(d, 2);
  Result.b := d^; Inc(d, 2);
  Result.a := d^;
end;

function TLabImageData.ReadR32G32B32_F(const x, y: Integer): TLabColor;
  function ftob(const f: TLabFloat): Byte;
    var i: TLabInt32;
    const gamma = 1.0 / 2.2;
  begin
    i := Round(power(f, gamma) * $ff);
    if i < 0 then i := 0 else if i > $ff then i := $ff;
    Result := i;
  end;
  var f: PLabFloatArr;
begin
  f := PLabFloatArr(DataAt(x, y));
  Result.r := ftob(f^[0]);
  Result.g := ftob(f^[1]);
  Result.b := ftob(f^[2]);
  Result.a := 1;
end;

procedure TLabImageData.SetPixel(const x, y: Integer; const Value: TLabColor);
begin
  _WriteProc(x, y, Value);
end;

{$Hints off}
procedure TLabImageData.WriteNone(const x, y: Integer; const Value: TLabColor);
begin

end;
{$Hints on}

procedure TLabImageData.WriteG8(const x, y: Integer; const Value: TLabColor);
  var d: PByte;
begin
  d := PByte(_Data + (y * _Width + x) * _BPP);
  d^ := Value.r;
end;

procedure TLabImageData.WriteG16(const x, y: Integer; const Value: TLabColor);
  var d: PByte;
begin
  d := PByte(_Data + (y * _Width + x) * _BPP);
  d^ := 0; Inc(d);
  d^ := Value.r;
end;

procedure TLabImageData.WriteG8A8(const x, y: Integer; const Value: TLabColor);
  var d: PByte;
begin
  d := PByte(_Data + (y * _Width + x) * _BPP);
  d^ := Value.r; Inc(d);
  d^ := Value.a;
end;

procedure TLabImageData.WriteG16A16(const x, y: Integer; const Value: TLabColor);
  var d: PByte;
begin
  d := PByte(_Data + (y * _Width + x) * _BPP);
  d^ := 0; Inc(d); d^ := Value.r; Inc(d);
  d^ := 0; Inc(d); d^ := Value.a;
end;

procedure TLabImageData.WriteR8G8B8(const x, y: Integer; const Value: TLabColor);
  var d: PByte;
begin
  d := PByte(_Data + (y * _Width + x) * _BPP);
  d^ := Value.r; Inc(d);
  d^ := Value.g; Inc(d);
  d^ := Value.b;
end;

procedure TLabImageData.WriteR16G16B16(const x, y: Integer; const Value: TLabColor);
  var d: PByte;
begin
  d := PByte(_Data + (y * _Width + x) * _BPP);
  d^ := 0; Inc(d); d^ := Value.r; Inc(d);
  d^ := 0; Inc(d); d^ := Value.g; Inc(d);
  d^ := 0; Inc(d); d^ := Value.b;
end;

procedure TLabImageData.WriteR8G8B8A8(const x, y: Integer; const Value: TLabColor);
begin
  PLongWord(_Data + (y * _Width + x) * _BPP)^ := PLongWord(@Value)^;
end;

procedure TLabImageData.WriteR16G16B16A16(const x, y: Integer; const Value: TLabColor);
  var d: PByte;
begin
  d := PByte(_Data + (y * _Width + x) * _BPP);
  d^ := 0; Inc(d); d^ := Value.r; Inc(d);
  d^ := 0; Inc(d); d^ := Value.g; Inc(d);
  d^ := 0; Inc(d); d^ := Value.b; Inc(d);
  d^ := 0; Inc(d); d^ := Value.a;
end;

procedure TLabImageData.WriteR32G32B32_F(const x, y: Integer; const Value: TLabColor);
  var f: PLabFloatArr;
  const gamma = 2.2;
  const rcp_ff = 1 / $ff;
begin
  f := PLabFloatArr(DataAt(x, y));
  f^[0] := power(Value.r * rcp_ff, gamma);
  f^[1] := power(Value.g * rcp_ff, gamma);
  f^[2] := power(Value.b * rcp_ff, gamma);
end;

procedure TLabImageData.DataAlloc;
begin
  if _BPP > 0 then
  begin
    DataAlloc(_Width * _Height * _BPP);
  end;
end;

procedure TLabImageData.DataAlloc(const Size: LongWord);
begin
  if _DataSize > 0 then DataFree;
  _DataSize := Size;
  GetMem(_Data, _DataSize);
end;

procedure TLabImageData.DataFree;
begin
  if _DataSize > 0 then
  begin
    Freemem(_Data, _DataSize);
    _DataSize := 0;
  end;
end;

function TLabImageData.DataAt(const x, y: Integer): Pointer;
begin
  Result := _Data + (y * _Width + x) * _BPP;
end;

class procedure TLabImageData.RegisterImageFormat;
begin
  LabRegisterImageFormat(TLabImageDataClass(ClassType));
end;

class function TLabImageData.CanLoad(const Stream: TStream): Boolean;
  var sh: TLabStreamHelper;
begin
  sh := TLabStreamHelper.Create(Stream);
  try
    Result := CanLoad(sh);
  finally
    sh.Free;
  end;
end;

class function TLabImageData.CanLoad(const FileName: String): Boolean;
  var fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead);
  try
    Result := CanLoad(fs);
  finally
    fs.Free;
  end;
end;

class function TLabImageData.CanLoad(const Buffer: Pointer; const Size: Integer): Boolean;
  var ms: TLabConstMemoryStream;
begin
  ms := TLabConstMemoryStream.Create(Buffer, Size);
  try
    Result := CanLoad(ms);
  finally
    ms.Free;
  end;
end;

procedure TLabImageData.Load(const Stream: TStream);
  var sh: TLabStreamHelper;
begin
  sh := TLabStreamHelper.Create(Stream);
  try
    Load(sh);
  finally
    sh.Free;
  end;
end;

procedure TLabImageData.Load(const FileName: String);
  var fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead);
  try
    Load(fs);
  finally
    fs.Free;
  end;
end;

procedure TLabImageData.Load(const Buffer: Pointer; const Size: Integer);
  var ms: TLabConstMemoryStream;
begin
  ms := TLabConstMemoryStream.Create(Buffer, Size);
  try
    Load(ms);
  finally
    ms.Free;
  end;
end;

procedure TLabImageData.Save(const Stream: TStream);
  var sh: TLabStreamHelper;
begin
  sh := TLabStreamHelper.Create(Stream);
  try
    Save(sh);
  finally
    sh.Free;
  end;
end;

procedure TLabImageData.Save(const FileName: String);
  var fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmCreate);
  try
    Save(fs);
  finally
    fs.Free;
  end;
end;

procedure TLabImageData.Allocate(const NewFormat: TLabImageDataFormat; const NewWidth, NewHeight: Integer);
begin
  SetFormat(NewFormat);
  _Width := NewWidth;
  _Height := NewHeight;
  DataAlloc;
end;

constructor TLabImageData.Create;
begin
  inherited Create;
  _Width := 0;
  _Height := 0;
  _BPP := 0;
  _Data := nil;
  _DataSize := 0;
  _Format := idf_none;
end;

destructor TLabImageData.Destroy;
begin
  DataFree;
  inherited Destroy;
end;

type
  {$MINENUMSIZE 1}
  TColorType = (
    ctGrayscale = 0,
    ctTrueColor = 2,
    ctIndexedColor = 3,
    ctGrayscaleAlpha = 4,
    ctTrueColorAlpha = 6
  );
  {$MINENUMSIZE 4}

  TFilter = (
    flNone = 0,
    flSub = 1,
    flUp = 2,
    flAverage = 3,
    flPaeth = 4
  );

  TInterlace = (
    inNone = 0,
    inAdam7 = 1
  );

  TChunk = packed record
    ChunkLength: LongWord;
    ChunkType: array[0..3] of AnsiChar;
    ChunkData: Pointer;
    ChunkCRC: LongWord;
  end;

  TChunkIHDR = packed record
    Width: LongWord;
    Height: LongWord;
    BitDepth: Byte;
    ColorType: TColorType;
    CompMethod: Byte;
    FilterMethod: Byte;
    InterlaceMethod: TInterlace;
  end;

  TChunkPLTE = packed record
    Entries: array of record r, g, b: Byte; end;
  end;

  TChunkIDAT = array of Byte;

const
  PNGHeader: AnsiString = (#137#80#78#71#13#10#26#10);
  CRCTable: array[0..255] of LongWord = (
    $00000000, $77073096, $EE0E612C, $990951BA, $076DC419, $706AF48F, $E963A535, $9E6495A3,
    $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
    $1DB71064, $6AB020F2, $F3B97148, $84BE41DE, $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
    $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
    $3B6E20C8, $4C69105E, $D56041E4, $A2677172, $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
    $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
    $26D930AC, $51DE003A, $C8D75180, $BFD06116, $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
    $2802B89E, $5F058808, $C60CD9B2, $B10BE924, $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
    $76DC4190, $01DB7106, $98D220BC, $EFD5102A, $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
    $7807C9A2, $0F00F934, $9609A88E, $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
    $6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
    $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
    $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2, $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
    $4369E96A, $346ED9FC, $AD678846, $DA60B8D0, $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
    $5005713C, $270241AA, $BE0B1010, $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F,
    $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4, $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
    $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
    $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8, $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
    $F00F9344, $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB, $196C3671, $6E6B06E7,
    $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC, $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
    $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252, $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
    $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60, $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
    $CB61B38C, $BC66831A, $256FD2A0, $5268E236, $CC0C7795, $BB0B4703, $220216B9, $5505262F,
    $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
    $9B64C2B0, $EC63F226, $756AA39C, $026D930A, $9C0906A9, $EB0E363F, $72076785, $05005713,
    $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
    $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E, $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
    $88085AE6, $FF0F6A70, $66063BCA, $11010B5C, $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
    $A00AE278, $D70DD2EE, $4E048354, $3903B3C2, $A7672661, $D06016F7, $4969474D, $3E6E77DB,
    $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
    $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6, $BAD03605, $CDD70693, $54DE5729, $23D967BF,
    $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D
  );

function CheckCRC(const Chunk: TChunk): Boolean;
  var i: Integer;
  var CRC: LongWord;
  var Data: PByte;
begin
  CRC := $ffffffff;
  for i := 0 to 3 do
  CRC := CRCTable[(CRC xor Byte(Chunk.ChunkType[i])) and $ff] xor (CRC shr 8);
  Data := Chunk.ChunkData;
  for i := 0 to Chunk.ChunkLength - 1 do
  begin
    CRC := CRCTable[(CRC xor Data^) and $ff] xor (CRC shr 8);
    Inc(Data);
  end;
  CRC := CRC xor $ffffffff;
  Result := CRC = Chunk.ChunkCRC;
end;

//TLabImageDataPNG BEGIN
{$Hints off}
class procedure TLabImageDataPNG.Decompress(const Buffer: Pointer; const Size: Integer; const Output: TStream);
  var ZStreamRec: z_stream;
  var ZResult: Integer;
  var TempBuffer: Pointer;
  const BufferSize = $8000;
begin
  FillChar(ZStreamRec, SizeOf(z_stream), 0);
  ZStreamRec.next_in := Buffer;
  ZStreamRec.avail_in := Size;
  if inflateInit(ZStreamRec) < 0 then Exit;
  GetMem(TempBuffer, BufferSize);
  try
    while ZStreamRec.avail_in > 0 do
    begin
      ZStreamRec.next_out := TempBuffer;
      ZStreamRec.avail_out := BufferSize;
      inflate(ZStreamRec, Z_NO_FLUSH);
      Output.Write(TempBuffer^, BufferSize - ZStreamRec.avail_out);
    end;
    repeat
      ZStreamRec.next_out := TempBuffer;
      ZStreamRec.avail_out := BufferSize;
      ZResult := inflate(ZStreamRec, Z_FINISH);
      Output.Write(TempBuffer^, BufferSize - ZStreamRec.avail_out);
    until (ZResult = Z_STREAM_END) and (ZStreamRec.avail_out > 0);
  finally
    FreeMem(TempBuffer, BufferSize);
    inflateEnd(ZStreamRec);
  end;
end;

class procedure TLabImageDataPNG.Compress(const Buffer: Pointer; const Size: Integer; const Output: TStream);
  var ZStreamRec: z_stream;
  var ZResult: Integer;
  var TempBuffer: Pointer;
  const BufferSize = $8000;
begin
  GetMem(TempBuffer, BufferSize);
  FillChar(ZStreamRec, SizeOf(z_stream), 0);
  ZStreamRec.next_in := Buffer;
  ZStreamRec.avail_in := Size;
  if DeflateInit(ZStreamRec, Z_BEST_COMPRESSION) < 0 then
  begin
    FreeMem(TempBuffer, BufferSize);
    Exit;
  end;
  try
    while ZStreamRec.avail_in > 0 do
    begin
      ZStreamRec.next_out := TempBuffer;
      ZStreamRec.avail_out := BufferSize;
      Deflate(ZStreamRec, Z_NO_FLUSH);
      Output.WriteBuffer(TempBuffer^, BufferSize - ZStreamRec.avail_out);
    end;
    repeat
      ZStreamRec.next_out := TempBuffer;
      ZStreamRec.avail_out := BufferSize;
      ZResult := Deflate(ZStreamRec, Z_FINISH);
      Output.WriteBuffer(TempBuffer^, BufferSize - ZStreamRec.avail_out);
    until (ZResult = Z_STREAM_END) and (ZStreamRec.avail_out > 0);
  finally
    FreeMem(TempBuffer, BufferSize);
    DeflateEnd(ZStreamRec);
  end;
end;

class function TLabImageDataPNG.Swap16(const n: Word): Word;
  type TByte2 = array[0..1] of Byte;
  var t: Word;
begin
  TByte2(t)[0] := TByte2(n)[1];
  TByte2(t)[1] := TByte2(n)[0];
  Result := t;
end;

class function TLabImageDataPNG.Swap32(const n: LongWord): LongWord;
  type TByte4 = array[0..3] of Byte;
  var t: LongWord;
begin
  TByte4(t)[0] := TByte4(n)[3];
  TByte4(t)[1] := TByte4(n)[2];
  TByte4(t)[2] := TByte4(n)[1];
  TByte4(t)[3] := TByte4(n)[0];
  Result := t;
end;
{$Hints on}

class function TLabImageDataPNG.GetCRC(const Buffer: Pointer; const Size: Integer): LongWord;
  var i: Integer;
  var pb: PByte;
begin
  Result := $ffffffff;
  pb := Buffer;
  for i := 0 to Size - 1 do
  begin
    Result:= CRCTable[(Result xor pb^) and $ff] xor (Result shr 8);
    Inc(pb);
  end;
  Result := Result xor $ffffffff;
end;

class constructor TLabImageDataPNG.CreateClass;
begin
  RegisterImageFormat;
end;

class function TLabImageDataPNG.CanLoad(const StreamHelper: TLabStreamHelper): Boolean;
  var Header: array[0..7] of AnsiChar;
begin
  Result := False;
  if StreamHelper.Remaining < 8 then Exit;
  StreamHelper.PosPush;
  {$Hints off}
  StreamHelper.ReadBuffer(@Header, 8);
  {$Hints on}
  Result := Header = PNGHeader;
  StreamHelper.PosPop;
end;

procedure TLabImageDataPNG.Load(const StreamHelper: TLabStreamHelper);
  var sh: TLabStreamHelper absolute StreamHelper;
  var Header: array[0..7] of AnsiChar;
  var ChunkData: array of Byte;
  var Chunk: TChunk;
  var ChunkIHDR: TChunkIHDR;
  var ChunkPLTE: TChunkPLTE;
  var ChunkIDAT: array of TChunkIDAT;
  var TranspG: Word;
  var TranspRGB: array[0..2] of Word;
  var TranspPalette: array of Byte;
  var Transp: Boolean;
  var KeepReading: Boolean;
  procedure ReadChunk;
  begin
    sh.ReadBuffer(@Chunk.ChunkLength, 4); Chunk.ChunkLength := Swap32(Chunk.ChunkLength);
    sh.ReadBuffer(@Chunk.ChunkType, 4);
    if Length(ChunkData) < Integer(Chunk.ChunkLength) then
    SetLength(ChunkData, Chunk.ChunkLength);
    Chunk.ChunkData := @ChunkData[0];
    sh.ReadBuffer(Chunk.ChunkData, Chunk.ChunkLength);
    sh.ReadBuffer(@Chunk.ChunkCRC, 4); Chunk.ChunkCRC := Swap32(Chunk.ChunkCRC);
  end;
  var i, j, Pass: Integer;
  var PixelDataSize: LongInt;
  var CompressedData: TMemoryStream;
  var DecompressedData: TMemoryStream;
  var CurFilter: TFilter;
  var ScanLineCur: PByteArray;
  var ScanLinePrev: PByteArray;
  var ScanLineSize: LongWord;
  var BitPerPixel: Byte;
  var BitStep: Byte;
  var BitMask: Byte;
  var BitCur: Byte;
  function UnpackBits(const Bits: Byte): Byte;
  begin
    Result := Round((Bits / BitMask) * $ff);
  end;
  function GetA(const Pos: Integer): Byte;
  begin
    if ChunkIHDR.BitDepth < 8 then
    begin
      if Pos > 0 then
      Result := ScanlineCur^[Pos - 1]
      else
      Result := 0;
    end
    else
    begin
      if Pos >= PixelDataSize then
      Result := ScanlineCur^[Pos - PixelDataSize]
      else
      Result := 0;
    end;
  end;
  function GetB(const Pos: Integer): Byte;
  begin
    if ScanlinePrev <> nil then
    Result := ScanlinePrev^[Pos]
    else
    Result := 0;
  end;
  function GetC(const Pos: Integer): Byte;
  begin
    if ScanlinePrev <> nil then
    begin
      if ChunkIHDR.BitDepth < 8 then
      begin
        if Pos > 0 then
        Result := ScanlinePrev^[Pos - 1]
        else
        Result := 0;
      end
      else
      begin
        if Pos >= PixelDataSize then
        Result := ScanlinePrev^[Pos - PixelDataSize]
        else
        Result := 0;
      end;
    end
    else
    Result := 0;
  end;
  function PaethPredictor(const a, b, c: Byte): Byte;
    var p, pa, pb, pc: Integer;
  begin
    p := Integer(a) + Integer(b) - Integer(c);
    pa := Abs(p - a);
    pb := Abs(p - b);
    pc := Abs(p - c);
    if (pa <= pb) and (pa <= pc) then Result := a
    else if (pb <= pc) then Result := b
    else Result := c;
  end;
  function FilterSub(const x: Byte; const Pos: Integer): Byte;
  begin
    Result := (x + GetA(Pos)) and $ff;
  end;
  function FilterUp(const x: Byte; const Pos: Integer): Byte;
  begin
    Result := (x + GetB(Pos)) and $ff;
  end;
  function FilterAverage(const x: Byte; const Pos: Integer): Byte;
  begin
    Result := (x + (GetA(Pos) + GetB(Pos)) div 2) and $ff;
  end;
  function FilterPaeth(const x: Byte; const Pos: Integer): Byte;
  begin
    Result := (x + PaethPredictor(GetA(Pos), GetB(Pos), GetC(Pos))) and $ff;
  end;
  const RowStart: array[0..7] of Integer = (0, 0, 0, 4, 0, 2, 0, 1);
  const ColStart: array[0..7] of Integer = (0, 0, 4, 0, 2, 0, 1, 0);
  const RowOffset: array[0..7] of Integer = (1, 8, 8, 8, 4, 4, 2, 2);
  const ColOffset: array[0..7] of Integer = (1, 8, 8, 4, 4, 2, 2, 1);
  var PassRows: LongInt;
  var PassCols: LongInt;
  var PassStart: LongInt;
  var PassEnd: LongInt;
  var x, y, b: Integer;
  var DataPtr: Pointer;
begin
  {$Hints off}
  sh.ReadBuffer(@Header, 8);
  {$Hints on}
  if Header = PNGHeader then
  begin
    ChunkIDAT := nil;
    Transp := False;
    KeepReading := True;
    while KeepReading do
    begin
      ReadChunk;
      if CheckCRC(Chunk) then
      begin
        if (Chunk.ChunkType = 'IHDR') then
        begin
          ChunkIHDR.Width := Swap32(PLongWord(@PByteArray(Chunk.ChunkData)^[0])^);
          ChunkIHDR.Height := Swap32(PLongWord(@PByteArray(Chunk.ChunkData)^[4])^);
          ChunkIHDR.BitDepth := PByteArray(Chunk.ChunkData)^[8];
          ChunkIHDR.ColorType := TColorType(PByteArray(Chunk.ChunkData)^[9]);
          ChunkIHDR.CompMethod := PByteArray(Chunk.ChunkData)^[10];
          ChunkIHDR.FilterMethod := PByteArray(Chunk.ChunkData)^[11];
          ChunkIHDR.InterlaceMethod := TInterlace(PByteArray(Chunk.ChunkData)^[12]);
          if ChunkIHDR.CompMethod <> 0 then Exit;
          if ChunkIHDR.FilterMethod <> 0 then Exit;
          if Byte(ChunkIHDR.InterlaceMethod) > 1 then Exit;
          case ChunkIHDR.ColorType of
            ctGrayscale:
            begin
              if not (ChunkIHDR.BitDepth in [1, 2, 4, 8, 16]) then Exit;
              if ChunkIHDR.BitDepth = 16 then
              PixelDataSize := 2 else PixelDataSize := 1;
              case ChunkIHDR.BitDepth of
                1:
                begin
                  BitPerPixel := 8;
                  BitStep := 1;
                  BitMask := 1;
                  SetFormat(idf_g8);
                end;
                2:
                begin
                  BitPerPixel := 4;
                  BitStep := 2;
                  BitMask := 3;
                  SetFormat(idf_g8);
                end;
                4:
                begin
                  BitPerPixel := 2;
                  BitStep := 4;
                  BitMask := 15;
                  SetFormat(idf_g8);
                end;
                8: SetFormat(idf_g8);
                16: SetFormat(idf_g16);
              end;
            end;
            ctTrueColor:
            begin
              if not (ChunkIHDR.BitDepth in [8, 16]) then Exit;
              PixelDataSize := 3 * ChunkIHDR.BitDepth div 8;
              case ChunkIHDR.BitDepth of
                8: SetFormat(idf_r8g8b8);
                16: SetFormat(idf_r16g16b16);
              end;
            end;
            ctIndexedColor:
            begin
              if not (ChunkIHDR.BitDepth in [1, 2, 4, 8]) then Exit;
              PixelDataSize := 1;
              SetFormat(idf_r8g8b8);
              case ChunkIHDR.BitDepth of
                1:
                begin
                  BitPerPixel := 8;
                  BitStep := 1;
                  BitMask := 1;
                end;
                2:
                begin
                  BitPerPixel := 4;
                  BitStep := 2;
                  BitMask := 3;
                end;
                4:
                begin
                  BitPerPixel := 2;
                  BitStep := 4;
                  BitMask := 15;
                end;
              end;
            end;
            ctGrayscaleAlpha:
            begin
              if not (ChunkIHDR.BitDepth in [8, 16]) then Exit;
              PixelDataSize := 2 * ChunkIHDR.BitDepth div 8;
              case ChunkIHDR.BitDepth of
                8: SetFormat(idf_g8a8);
                16: SetFormat(idf_g16a16);
              end;
            end;
            ctTrueColorAlpha:
            begin
              if not (ChunkIHDR.BitDepth in [8, 16]) then Exit;
              PixelDataSize := 4 * ChunkIHDR.BitDepth div 8;
              case ChunkIHDR.BitDepth of
                8: SetFormat(idf_r8g8b8a8);
                16: SetFormat(idf_r16g16b16a16);
              end;
            end;
            else
            Exit;
          end;
        end
        else if (Chunk.ChunkType = 'IEND') then
        begin
          KeepReading := False;
        end
        else if (Chunk.ChunkType = 'PLTE') then
        begin
          SetLength(ChunkPLTE.Entries, Chunk.ChunkLength div 3);
          Move(Chunk.ChunkData^, ChunkPLTE.Entries[0], Chunk.ChunkLength);
        end
        else if (Chunk.ChunkType = 'IDAT') then
        begin
          SetLength(ChunkIDAT, Length(ChunkIDAT) + 1);
          SetLength(ChunkIDAT[High(ChunkIDAT)], Chunk.ChunkLength);
          Move(Chunk.ChunkData^, ChunkIDAT[High(ChunkIDAT)][0], Chunk.ChunkLength);
        end
        else if (Chunk.ChunkType = 'tRNS') then
        begin
          Transp := True;
          case ChunkIHDR.ColorType of
            ctGrayscale:
            begin
              TranspG := Swap16(PWord(Chunk.ChunkData)^);
              if Format = idf_g8 then
              SetFormat(idf_g8a8)
              else
              SetFormat(idf_g16a16);
            end;
            ctTrueColor:
            begin
              for i := 0 to 2 do
              TranspRGB[i] := Swap16(PWord(Chunk.ChunkData)^);
              if Format = idf_r8g8b8 then
              SetFormat(idf_r8g8b8a8)
              else
              SetFormat(idf_r16g16b16a16);
            end;
            ctIndexedColor:
            begin
              SetLength(TranspPalette, Chunk.ChunkLength);
              Move(Chunk.ChunkData^, TranspPalette[0], Chunk.ChunkLength);
              SetFormat(idf_r8g8b8a8);
            end;
            ctGrayscaleAlpha, ctTrueColorAlpha: Exit;
          end;
        end;
      end;
    end;
    CompressedData := TMemoryStream.Create;
    DecompressedData := TMemoryStream.Create;
    try
      CompressedData.Position := 0;
      DecompressedData.Position := 0;
      for i := 0 to High(ChunkIDAT) do
      begin
        CompressedData.Write(ChunkIDAT[i][0], Length(ChunkIDAT[i]));
      end;
      Decompress(CompressedData.Memory, CompressedData.Size, DecompressedData);
      _Width := ChunkIHDR.Width;
      _Height := ChunkIHDR.Height;
      DataAlloc;
      DecompressedData.Position := 0;
      case ChunkIHDR.InterlaceMethod of
        inAdam7: begin PassStart := 1; PassEnd := 7; end;
        else begin PassStart := 0; PassEnd := 0; end;
      end;
      DataPtr := DecompressedData.Memory;
      for Pass := PassStart to PassEnd do
      begin
        PassRows := _Height div RowOffset[Pass];
        if (_Height mod RowOffset[Pass]) > RowStart[Pass] then Inc(PassRows);
        PassCols := _Width div ColOffset[Pass];
        if (_Width mod ColOffset[Pass]) > ColStart[Pass] then Inc(PassCols);
        if (PassRows > 0) and (PassCols > 0) then
        begin
          ScanlineSize := PixelDataSize * PassCols;
          ScanlinePrev := nil;
          ScanlineCur := DataPtr;
          if ChunkIHDR.BitDepth < 8 then
          begin
            if ScanlineSize mod BitPerPixel > 0 then
            ScanlineSize := (ScanlineSize div BitPerPixel + 1)
            else
            ScanlineSize := (ScanlineSize div BitPerPixel);
          end;
          Inc(DataPtr, (Integer(ScanlineSize) + 1) * PassRows);
          y := RowStart[Pass];
          for j := 0 to PassRows - 1 do
          begin
            CurFilter := TFilter(ScanlineCur^[0]);
            {$Hints off}
            ScanlineCur := PByteArray(PtrUInt(ScanlineCur) + 1);
            {$Hints on}
            if ChunkIHDR.BitDepth > 8 then
            for i := 0 to ScanlineSize div 2 - 1 do
            PWord(@ScanlineCur^[i * 2])^ := Swap16(PWord(@ScanlineCur^[i * 2])^);
            x := ColStart[Pass];
            case CurFilter of
              flSub:
              for i := 0 to ScanlineSize - 1 do
              ScanlineCur^[i] := FilterSub(ScanlineCur^[i], i);
              flUp:
              for i := 0 to ScanlineSize - 1 do
              ScanlineCur^[i] := FilterUp(ScanlineCur^[i], i);
              flAverage:
              for i := 0 to ScanlineSize - 1 do
              ScanlineCur^[i] := FilterAverage(ScanlineCur^[i], i);
              flPaeth:
              for i := 0 to ScanlineSize - 1 do
              ScanlineCur^[i] := FilterPaeth(ScanlineCur^[i], i);
            end;
            if ChunkIHDR.ColorType = ctIndexedColor then
            begin
              if ChunkIHDR.BitDepth < 8 then
              begin
                for i := 0 to PassCols - 1 do
                begin
                  BitCur := (ScanlineCur^[i div BitPerPixel] shr (8 - (i mod BitPerPixel + 1) * BitStep)) and BitMask;
                  PByte(_Data + (y * _Width + x) * _BPP + 0)^ := ChunkPLTE.Entries[BitCur].r;
                  PByte(_Data + (y * _Width + x) * _BPP + 1)^ := ChunkPLTE.Entries[BitCur].g;
                  PByte(_Data + (y * _Width + x) * _BPP + 2)^ := ChunkPLTE.Entries[BitCur].b;
                  if Transp then
                  begin
                    if BitCur > High(TranspPalette) then
                    PByte(_Data + (y * _Width + x) * _BPP + 3)^ := $ff
                    else
                    PByte(_Data + (y * _Width + x) * _BPP + 3)^ := TranspPalette[BitCur];
                  end;
                  x := x + ColOffset[Pass];
                end;
              end
              else //8 or 16 bit
              begin
                for i := 0 to PassCols - 1 do
                begin
                  PByte(_Data + (y * _Width + x) * _BPP + 0)^ := ChunkPLTE.Entries[ScanlineCur^[i]].r;
                  PByte(_Data + (y * _Width + x) * _BPP + 1)^ := ChunkPLTE.Entries[ScanlineCur^[i]].g;
                  PByte(_Data + (y * _Width + x) * _BPP + 2)^ := ChunkPLTE.Entries[ScanlineCur^[i]].b;
                  if Transp then
                  begin
                    if ScanlineCur^[i] > High(TranspPalette) then
                    PByte(_Data + (y * _Width + x) * _BPP + 3)^ := $ff
                    else
                    PByte(_Data + (y * _Width + x) * _BPP + 3)^ := TranspPalette[ScanlineCur^[i]];
                  end;
                  x := x + ColOffset[Pass];
                end;
              end;
            end
            else //non indexed
            begin
              if ChunkIHDR.BitDepth < 8 then
              begin
                for i := 0 to PassCols - 1 do
                begin
                  BitCur := (ScanlineCur^[i div BitPerPixel] shr (8 - (i mod BitPerPixel + 1) * BitStep)) and BitMask;
                  if Transp then
                  begin
                    if ChunkIHDR.ColorType = ctGrayscale then
                    begin
                      if BitCur = TranspG and BitMask then
                      PByte(_Data + (y * _Width + x) * _BPP + 1)^ := 0
                      else
                      PByte(_Data + (y * _Width + x) * _BPP + 1)^ := $ff;
                    end;
                  end;
                  BitCur := UnpackBits(BitCur);
                  PByte(_Data + (y * _Width + x) * _BPP)^ := BitCur;
                  x := x + ColOffset[Pass];
                end;
              end
              else //8 or 16 bit
              begin
                for i := 0 to PassCols - 1 do
                begin
                  for b := 0 to PixelDataSize - 1 do
                  PByte(_Data + (y * _Width + x) * _BPP + b)^ := ScanlineCur^[i * PixelDataSize + b];
                  if Transp then
                  begin
                    if ChunkIHDR.ColorType = ctGrayscale then
                    begin
                      if ChunkIHDR.BitDepth = 8 then
                      begin
                        if ScanlineCur^[i * PixelDataSize] = Byte(TranspG and $ff) then
                        PByteArray(_Data)^[(y * _Width + x) * _BPP + PixelDataSize] := 0
                        else
                        PByteArray(_Data)^[(y * _Width + x) * _BPP + PixelDataSize] := $ff;
                      end
                      else
                      begin
                        if PWord(@ScanlineCur^[i * PixelDataSize])^ = TranspG then
                        PWord(@PByteArray(_Data)^[(y * _Width + x) * _BPP + PixelDataSize])^ := 0
                        else
                        PWord(@PByteArray(_Data)^[(y * _Width + x) * _BPP + PixelDataSize])^ := $ffff;
                      end;
                    end
                    else
                    begin
                      if ChunkIHDR.BitDepth = 8 then
                      begin
                        if (ScanlineCur^[i * PixelDataSize + 0] = Byte(TranspRGB[0] and $ff))
                        and (ScanlineCur^[i * PixelDataSize + 1] = Byte(TranspRGB[1] and $ff))
                        and (ScanlineCur^[i * PixelDataSize + 2] = Byte(TranspRGB[2] and $ff)) then
                        PByte(_Data + (y * _Width + x) * _BPP + 3)^ := 0
                        else
                        PByte(_Data + (y * _Width + x) * _BPP + 3)^ := $ff;
                      end
                      else
                      begin
                        if (PWord(@ScanlineCur^[i * PixelDataSize + 0])^ = TranspRGB[0])
                        and (PWord(@ScanlineCur^[i * PixelDataSize + 2])^ = TranspRGB[1])
                        and (PWord(@ScanlineCur^[i * PixelDataSize + 4])^ = TranspRGB[2]) then
                        PWord(_Data + (y * _Width + x) * _BPP + 6)^ := 0
                        else
                        PWord(_Data + (y * _Width + x) * _BPP + 6)^ := $ffff;
                      end;
                    end;
                  end;
                  x := x + ColOffset[Pass];
                end;
              end;
            end;
            ScanlinePrev := ScanlineCur;
            {$Hints off}
            ScanlineCur := PByteArray(PtrUInt(ScanlineCur) + ScanlineSize);
            {$Hints on}
            y := y + RowOffset[Pass];
          end;
        end;
      end;
    finally
      CompressedData.Free;
      DecompressedData.Free;
    end;
  end;
end;

procedure TLabImageDataPNG.Save(const StreamHelper: TLabStreamHelper);
  var sh: TLabStreamHelper absolute StreamHelper;
  var ChunkType: array[0..3] of AnsiChar;
  var ChunkCompress: Boolean;
  var ChunkStreamDecompressed: TMemoryStream;
  var ChunkStreamCompressed: TMemoryStream;
  procedure ChunkBegin(const ChunkName: AnsiString);
  begin
    ChunkType := ChunkName[1] + ChunkName[2] + ChunkName[3] + ChunkName[4];
    ChunkCompress := ChunkType = 'IDAT';
    ChunkStreamDecompressed := TMemoryStream.Create;
    ChunkStreamCompressed := TMemoryStream.Create;
  end;
  procedure ChunkEnd;
  begin
    ChunkStreamDecompressed.Position := 0;
    ChunkStreamCompressed.Write(ChunkType, 4);
    if ChunkStreamDecompressed.Size > 0 then
    begin
      if ChunkCompress then
      Compress(ChunkStreamDecompressed.Memory, ChunkStreamDecompressed.Size, ChunkStreamCompressed)
      else
      ChunkStreamCompressed.Write(ChunkStreamDecompressed.Memory^, ChunkStreamDecompressed.Size);
    end;
    sh.WriteInt32(Swap32(ChunkStreamCompressed.Size - 4));
    ChunkStreamCompressed.Position := 0;
    sh.WriteBuffer(ChunkStreamCompressed.Memory, ChunkStreamCompressed.Size);
    ChunkStreamCompressed.Position := 0;
    sh.WriteUInt32(Swap32(GetCRC(ChunkStreamCompressed.Memory, ChunkStreamCompressed.Size)));
    ChunkStreamDecompressed.Free;
    ChunkStreamCompressed.Free;
  end;
  procedure ChunkWrite(const Buffer: Pointer; const Size: Int64);
  begin
    ChunkStreamDecompressed.WriteBuffer(Buffer^, Size);
  end;
  procedure ChunkWriteInt4U(const v: LongWord);
  begin
    ChunkWrite(@v, 4);
  end;
  procedure ChunkWriteInt4S(const v: Integer);
  begin
    ChunkWrite(@v, 4);
  end;
  procedure ChunkWriteInt2U(const v: Word);
  begin
    ChunkWrite(@v, 2);
  end;
  procedure ChunkWriteInt2S(const v: SmallInt);
  begin
    ChunkWrite(@v, 2);
  end;
  procedure ChunkWriteInt1U(const v: Byte);
  begin
    ChunkWrite(@v, 1);
  end;
  procedure ChunkWriteInt1S(const v: ShortInt);
  begin
    ChunkWrite(@v, 1);
  end;
  var ImageData: Pointer;
  var ImageDataSize: Integer;
  var pb: PByte;
  var i, j: Integer;
begin
  sh.WriteBuffer(@PNGHeader[1], 8);
  ChunkBegin('IHDR');
  ChunkWriteInt4S(Swap32(_Width));
  ChunkWriteInt4S(Swap32(_Height));
  ChunkWriteInt1U(8);
  ChunkWriteInt1U(Byte(ctTrueColorAlpha));
  ChunkWriteInt1U(0);
  ChunkWriteInt1U(0);
  ChunkWriteInt1U(0);
  ChunkEnd;
  ChunkBegin('IDAT');
  ImageDataSize := (_Width * 4 + 1) * _Height;
  GetMem(ImageData, ImageDataSize);
  pb := ImageData;
  for j := 0 to _Height - 1 do
  begin
    pb^ := 0; Inc(pb);
    for i := 0 to _Width - 1 do
    begin
      PLabColor(pb)^ := Pixels[i, j];
      Inc(pb, 4);
    end;
  end;
  ChunkWrite(ImageData, ImageDataSize);
  FreeMem(ImageData, ImageDataSize);
  ChunkEnd;
  ChunkBegin('IEND');
  ChunkEnd;
end;
//TLabImageDataPNG END

end.

