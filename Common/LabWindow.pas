unit LabWindow;

interface

uses
  {$include LabPlatform.inc},
  LabThread;

type
  TLabWindow = class;

  TLabWindowProc = procedure (Window: TLabWindow) of Object;

  TLabWindow = class
  private
    class var _WndClass: TWndClassExA;
    class var _WndClassName: AnsiString;
    var _Width: Integer;
    var _Height: Integer;
    var _Handle: HWND;
    var _Instance: HINSTANCE;
    var _Caption: AnsiString;
    var _OnClose: TLabWindowProc;
    var _OnTick: TLabWindowProc;
    var _LoopThread: TLabThread;
    var _Active: Boolean;
    procedure SetCaption(const Value: AnsiString);
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    constructor Create; overload;
    constructor Create(const NewWidth, NewHeight: Integer); overload;
    destructor Destroy; override;
    property Width: Integer read _Width;
    property Height: Integer read _Height;
    property Caption: AnsiString read _Caption write SetCaption;
    property Handle: HWND read _Handle write _Handle;
    property OnClose: TLabWindowProc read _OnClose write _OnClose;
    property OnTick: TLabWindowProc read _OnTick write _OnTick;
    procedure Close;
  end;

implementation

function LabMessageHandler(Wnd: HWnd; Msg: UInt; wParam: WPARAM; lParam: LPARAM): LResult; stdcall;
  var Window: TLabWindow;
begin
  case Msg of
    WM_DESTROY, WM_QUIT, WM_CLOSE:
    begin
      Window := TLabWindow(GetWindowLongPtrA(Wnd, GWLP_USERDATA));
      if Assigned(Window) then Window.Close;
    end;
    WM_CHAR:
    begin
      //g2.Window.AddMessage(@g2.Window.OnPrint, wParam, 0, 0);
    end;
    WM_KEYDOWN:
    begin
      //g2.Window.AddMessage(@g2.Window.OnKeyDown, wParam, 0, 0);
    end;
    WM_KEYUP:
    begin
      //g2.Window.AddMessage(@g2.Window.OnKeyUp, wParam, 0, 0);
    end;
    WM_LBUTTONDOWN:
    begin
      //g2.Window.AddMessage(@g2.Window.OnMouseDown, G2MB_Left, lParam and $ffff, (lParam shr 16) and $ffff);
    end;
    WM_LBUTTONDBLCLK:
    begin
      //g2.Window.AddMessage(@g2.Window.OnMouseDown, G2MB_Left, lParam and $ffff, (lParam shr 16) and $ffff);
    end;
    WM_LBUTTONUP:
    begin
      //g2.Window.AddMessage(@g2.Window.OnMouseUp, G2MB_Left, lParam and $ffff, (lParam shr 16) and $ffff);
    end;
    WM_RBUTTONDOWN:
    begin
      //g2.Window.AddMessage(@g2.Window.OnMouseDown, G2MB_Right, lParam and $ffff, (lParam shr 16) and $ffff);
    end;
    WM_RBUTTONDBLCLK:
    begin
      //g2.Window.AddMessage(@g2.Window.OnMouseDown, G2MB_Right, lParam and $ffff, (lParam shr 16) and $ffff);
    end;
    WM_RBUTTONUP:
    begin
      //g2.Window.AddMessage(@g2.Window.OnMouseUp, G2MB_Right, lParam and $ffff, (lParam shr 16) and $ffff);
    end;
    WM_MBUTTONDOWN:
    begin
      //g2.Window.AddMessage(@g2.Window.OnMouseDown, G2MB_Middle, lParam and $ffff, (lParam shr 16) and $ffff);
    end;
    WM_MBUTTONDBLCLK:
    begin
      //g2.Window.AddMessage(@g2.Window.OnMouseDown, G2MB_Middle, lParam and $ffff, (lParam shr 16) and $ffff);
    end;
    WM_MBUTTONUP:
    begin
      //g2.Window.AddMessage(@g2.Window.OnMouseUp, G2MB_Middle, lParam and $ffff, (lParam shr 16) and $ffff);
    end;
    WM_MOUSEWHEEL:
    begin
      //g2.Window.AddMessage(@g2.Window.OnScroll, SmallInt((LongWord(wParam) shr 16) and $ffff), 0, 0);
    end;
    WM_SETCURSOR:
    begin
      //Windows.SetCursor(g2.Window.Cursor);
      //if g2.Window.Cursor <> g2.Window.CursorArrow then Exit;
    end;
    WM_SIZE:
    begin
      //if wParam <> SIZE_MINIMIZED then
      //begin
      //  if wParam = SIZE_MAXIMIZED then WindowMode := 1 else WindowMode := 0;
      //  g2.Window.AddMessage(@g2.Window.OnResize, WindowMode, lParam and $ffff, (lParam shr 16) and $ffff);
      //end;
    end;
  end;
  Result := DefWindowProc(Wnd, Msg, wParam, lParam);
end;

procedure TLabWindow.SetCaption(const Value: AnsiString);
begin
  if _Caption = Value then Exit;
end;

procedure TLabWindow.Initialize;
begin
  _OnClose := nil;
  _OnTick := nil;
  _Caption := 'LabVulkan';
  if _Width < 128 then _Width := 128;
  if _Height < 32 then _Height := 32;
  _Active := True;
  _LoopThread := TLabThread.Create;
  _LoopThread.Proc := @Loop;
  _LoopThread.Start;
end;

procedure TLabWindow.Finalize;
begin
  _LoopThread.WaitFor();
  _LoopThread.Free;
end;

procedure TLabWindow.Loop;
  var WndStyle: LongWord;
  var R: TRect;
  var WndClassName: AnsiString;
  var msg: TMsg;
begin
  WndStyle := (
    WS_CAPTION or
    WS_POPUP or
    WS_VISIBLE or
    WS_EX_TOPMOST or
    WS_MINIMIZEBOX or
    WS_MAXIMIZEBOX or
    WS_SYSMENU
  );
  WndStyle := WndStyle or WS_THICKFRAME;
  R.Left := (GetSystemMetrics(SM_CXSCREEN) - _Width) shr 1;
  R.Right := R.Left + _Width;
  R.Top := (GetSystemMetrics(SM_CYSCREEN) - _Height) shr 1;
  R.Bottom := R.Top + _Height;
  AdjustWindowRect(R, WndStyle, False);
  WndClassName := _WndClassName;
  _Handle := CreateWindowExA(
    WS_EX_WINDOWEDGE or WS_EX_APPWINDOW, PAnsiChar(WndClassName), PAnsiChar(_Caption),
    WndStyle,
    R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top,
    0, 0, HInstance, nil
  );
  _Instance := GetWindowLongA(_Handle, GWL_HINSTANCE);
  SetWindowLongPtrA(_Handle, GWLP_USERDATA, PtrInt(Self));
  BringWindowToTop(_Handle);
  {$Warnings off}
  FillChar(msg, SizeOf(msg), 0);
  {$Warnings on}
  while _Active do
  begin
    if PeekMessage(msg, 0, 0, 0, PM_REMOVE) then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end
    else
    begin
      if Assigned(_OnTick) then _OnTick(Self);
    end
  end;
  if Assigned(_OnClose) then _OnClose(Self);
  DestroyWindow(_Handle);
end;

class constructor TLabWindow.CreateClass;
begin
  _WndClassName := 'LabVulkan';
  FillChar(_WndClass, SizeOf(TWndClassExA), 0);
  _WndClass.cbSize := SizeOf(TWndClassExA);
  _WndClass.hIconSm := LoadIcon(MainInstance, 'MAINICON');
  _WndClass.hIcon := LoadIcon(MainInstance, 'MAINICON');
  _WndClass.hInstance := HInstance;
  _WndClass.hCursor := LoadCursor(0, IDC_ARROW);
  _WndClass.lpszClassName := PAnsiChar(_WndClassName);
  _WndClass.style := CS_HREDRAW or CS_VREDRAW or CS_OWNDC or CS_DBLCLKS;
  _WndClass.lpfnWndProc := @LabMessageHandler;
  if RegisterClassExA(_WndClass) = 0 then
  begin
    _WndClassName := 'Static';
  end;
end;

class destructor TLabWindow.DestroyClass;
begin
  if _WndClassName = 'LabVulkan' then
  begin
    UnregisterClassA(PAnsiChar(_WndClassName), _WndClass.hInstance);
  end;
  DestroyIcon(_WndClass.hIconSm);
  DestroyIcon(_WndClass.hIcon);
  DestroyCursor(_WndClass.hCursor);
end;

constructor TLabWindow.Create;
begin
  _Width := 960;
  _Height := 540;
  Initialize;
end;

constructor TLabWindow.Create(const NewWidth, NewHeight: Integer);
begin
  _Width := NewWidth;
  _Height := NewHeight;
  Initialize;
end;

destructor TLabWindow.Destroy;
begin
  if _Active then Close;
  Finalize;
  inherited Destroy;
end;

procedure TLabWindow.Close;
begin
  _Active := False;
end;

end.
