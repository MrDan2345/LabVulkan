unit LabThread;

interface

type

  TLabThreadState = (lab_ts_idle, lab_ts_running, lab_ts_finished);

  TLabThreadProc = procedure () of Object;

  TLabThread = class
  private
    var _ThreadHandle: TThreadID;
    var _ThreadID: TThreadID;
    var _State: TLabThreadState;
    var _Proc: TLabThreadProc;
    procedure Run; inline;
  protected
    procedure Execute; virtual;
  public
    property ThreadID: TThreadID read _ThreadID;
    property State: TLabThreadState read _State;
    property Proc: TLabThreadProc read _Proc write _Proc;
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure WaitFor(const Timeout: LongWord = $ffffffff);
  end;

  TG2CriticalSection = object
  private
    var _CS: TRTLCriticalSection;
  public
    procedure Initialize;
    procedure Finalize;
    procedure Enter;
    procedure Leave;
  end;


implementation

function LabThreadFunc(ThreadCaller: Pointer): PtrInt;
begin
  TLabThread(ThreadCaller).Run;
  Result := 0;
end;

procedure TLabThread.Run;
begin
  _State := lab_ts_running;
  Execute;
  _State := lab_ts_finished;
end;

procedure TLabThread.Execute;
begin
  if Assigned(_Proc) then _Proc;
end;

constructor TLabThread.Create;
begin
  inherited Create;
  _State := lab_ts_idle;
  _Proc := nil;
end;

destructor TLabThread.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure TLabThread.Start;
begin
  _ThreadHandle := BeginThread(@LabThreadFunc, Self, _ThreadID);
end;

procedure TLabThread.Stop;
begin
  if _State = lab_ts_running then
  KillThread(_ThreadHandle);
  if _State <> lab_ts_idle then
  CloseThread(_ThreadHandle);
end;

procedure TLabThread.WaitFor(const Timeout: LongWord);
begin
  WaitForThreadTerminate(_ThreadHandle, Timeout);
end;

procedure TG2CriticalSection.Initialize;
begin
  InitCriticalSection(_CS);
end;

procedure TG2CriticalSection.Finalize;
begin
  DoneCriticalSection(_CS);
end;

procedure TG2CriticalSection.Enter;
begin
  EnterCriticalSection(_CS);
end;

procedure TG2CriticalSection.Leave;
begin
  LeaveCriticalSection(_CS);
end;

end.
