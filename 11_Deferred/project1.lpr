program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Messages,
  Windows,
  SysUtils,
  Classes,
  LabVulkan,
  Main;

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

