unit LabApplication;

interface

uses
  {$include LabPlatform.inc},
  LabWindow,
  LabThread,
  LabRenderer;

type
  TLabApplication = class (TInterfacedObject)
  private
    var _Window: TLabWindow;
    var _UpdateThread: TLabThread;
    var _Active: Boolean;
    procedure OnWindowClose(Wnd: TLabWindow);
    procedure Update;
    procedure Stop;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Run;
  end;

implementation

procedure TLabApplication.OnWindowClose(Wnd: TLabWindow);
begin
  if Wnd = _Window then Stop;
end;

procedure TLabApplication.Update;
begin
  while _Active do
  begin
    //Logical update thread
  end;
end;

procedure TLabApplication.Stop;
begin
  _Active := False;
end;

constructor TLabApplication.Create;
begin
  inherited Create;
  _Active := False;
  _Window := TLabWindow.Create;
  _Window.OnClose := @OnWindowClose;
  _UpdateThread := TLabThread.Create;
  _UpdateThread.Proc := @Update;
end;

destructor TLabApplication.Destroy;
begin
  _UpdateThread.Free;
  _Window.Free;
  inherited Destroy;
end;

procedure TLabApplication.Run;
begin
  _Active := True;
  _UpdateThread.Start;
  while _Active do
  begin
    //Gather, process window messages and sync other threads
  end;
  _UpdateThread.WaitFor();
end;

end.
