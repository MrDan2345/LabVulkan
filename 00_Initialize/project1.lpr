program project1;

{$mode objfpc}{$H+}

uses
  Heaptrc,
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Messages,
  Windows,
  SysUtils,
  Classes,
  Vulkan,
  sample_info,
  LabMath,
  LabPlatform,
  LabVulkan,
  LabWindow,
  LabSwapChain,
  LabDescriptorSet,
  LabPipeline,
  LabRenderPass,
  LabDevice,
  LabSurface,
  LabImage,
  LabSync
  { you can add units after this };

procedure Main;
begin
  App := TLabApp.Create;
  TLabVulkan.Run;
end;

begin
  if FileExists('heaptrc.txt') then DeleteFile('heaptrc.txt');
  SetHeapTraceOutput('heaptrc.txt');
  Main;
end.

