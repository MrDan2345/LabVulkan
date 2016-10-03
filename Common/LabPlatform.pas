unit LabPlatform;

interface

uses
  {$include LabPlatform.inc};

function LabTime: LongWord;

implementation

function LabTime: LongWord;
{$if defined(Android)}
  var CurTimeVal: timeval;
{$endif}
begin
  {$if defined(Windows)}
  Result := GetTickCount;
  {$elseif defined(Linux) or defined(Darwin)}
  Result := LongWord(Trunc(Now * 24 * 60 * 60 * 1000));
  {$elseif defined(Android)}
  gettimeofday(@CurTimeVal, nil);
  Result := CurTimeVal.tv_sec * 1000 + CurTimeVal.tv_usec div 1000;
  {$elseif defined(iOS)}
  Result := LongWord(Trunc(CACurrentMediaTime * 1000));
  {$endif}
end;

end.
