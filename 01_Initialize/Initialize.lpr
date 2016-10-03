program Initialize;

uses
  {$include LabPlatform.inc},
  LabApplication,
  Vulkan;

var
  App: TLabApplication;

begin
  App := TLabApplication.Create;
  App.Run;
end.

