program Initialize;

{$include LabPlatform.inc}
uses
  LabApplication,
  Vulkan,
  SysUtils;

var
  App: TLabApplicationShared;

begin
  if FileExists('heaptrc.txt') then DeleteFile('heaptrc.txt');
  SetHeapTraceOutput('heaptrc.txt');
  App := TLabApplication.Create;
  App.Ptr.Run;
end.

