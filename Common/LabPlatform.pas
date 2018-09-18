unit LabPlatform;

interface

{$include LabPlatform.inc}
uses
  SysUtils;

function LabTimeMs: QWord;
function LabTimeSec: Single;
function LabTimeLoopMs(const Loop: QWord = 1000): QWord;
function LabTimeLoopSec(const Loop: Single = 1): Single;

implementation

function LabTimeMs: QWord;
{$if defined(Android)}
  var CurTimeVal: timeval;
{$endif}
begin
  {$if defined(Windows)}
  Result := GetTickCount64;
  {$elseif defined(Linux) or defined(Darwin)}
  Result := LongWord(Trunc(Now * 24 * 60 * 60 * 1000));
  {$elseif defined(Android)}
  gettimeofday(@CurTimeVal, nil);
  Result := CurTimeVal.tv_sec * 1000 + CurTimeVal.tv_usec div 1000;
  {$elseif defined(iOS)}
  Result := LongWord(Trunc(CACurrentMediaTime * 1000));
  {$endif}
end;

function LabTimeSec: Single;
begin
  Result := LabTimeMs * 0.001;
end;

function LabTimeLoopMs(const Loop: QWord): QWord;
begin
  Result := LabTimeMs mod Loop;
end;

function LabTimeLoopSec(const Loop: Single): Single;
begin
  Result := LabTimeLoopMs(QWord(Trunc(Loop * 1000))) * 0.001;
end;

end.
