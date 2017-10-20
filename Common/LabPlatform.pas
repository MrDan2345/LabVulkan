unit LabPlatform;

interface

{$include LabPlatform.inc}
uses
  SysUtils;

function LabTimeMs: LongWord;
function LabTimeSec: Single;

implementation

function LabTimeMs: LongWord;
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

end.
