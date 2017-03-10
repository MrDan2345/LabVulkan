program Initialize;

{$include LabPlatform.inc}
uses
  //Heaptrc,
  LabApplication,
  Vulkan,
  SysUtils,
  Data;

var
  App: TLabApplicationShared;

begin
  //if FileExists('heaptrc.txt') then DeleteFile('heaptrc.txt');
  //SetHeapTraceOutput('heaptrc.txt');
  App := TLabApplication.Create;
  App.Ptr.Run;
end.

