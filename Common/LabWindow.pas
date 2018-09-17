unit LabWindow;

{$include LabPlatform.inc}
interface

uses
{$if defined(VK_USE_PLATFORM_WIN32_KHR)}
  Windows,
{$endif}
  LabTypes,
  LabThread,
  LabUtils,
  SysUtils;

type
  TLabWindow = class;

  TLabWindowProc = procedure (const Window: TLabWindow) of Object;
  TLabWindowMode = (wm_normal, wm_minimized, wm_maximized);

  TLabWindow = class (TLabClass)
  private
    class var _WndClass: TWndClassExA;
    class var _WndClassName: AnsiString;
    var _Width: Integer;
    var _Height: Integer;
    var _Mode: TLabWindowMode;
    var _Handle: HWND;
    var _Instance: HINST;
    var _Caption: AnsiString;
    var _OnCreate: TLabWindowProc;
    var _OnClose: TLabWindowProc;
    var _OnTick: TLabWindowProc;
    var _LoopThread: TLabThread;
    var _Active: Boolean;
    procedure SetCaption(const Value: AnsiString);
    procedure Initialize;
    procedure Finalize;
    procedure Loop;
    procedure Resize(const NewWidth, NewHeight: Integer; const NewMode: TLabWindowMode);
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    class property WndClass: TWndClassExA read _WndClass;
    class property WndClassName: AnsiString read _WndClassName;
    constructor Create; overload;
    constructor Create(const NewWidth, NewHeight: Integer); overload;
    destructor Destroy; override;
    property IsActive: Boolean read _Active;
    property Width: Integer read _Width;
    property Height: Integer read _Height;
    property Caption: AnsiString read _Caption write SetCaption;
    property Handle: HWND read _Handle;
    property Mode: TLabWindowMode read _Mode;
    property Instance: HINST read _Instance;
    property OnCreate: TLabWindowProc read _OnCreate write _OnCreate;
    property OnClose: TLabWindowProc read _OnClose write _OnClose;
    property OnTick: TLabWindowProc read _OnTick write _OnTick;
    procedure Close;
  end;
  TLabWindowShared = specialize TLabSharedRef<TLabWindow>;

implementation

function LabMessageHandler(Wnd: HWnd; Msg: UInt; wParam: WPARAM; lParam: LPARAM): LResult; stdcall;
  var Window: TLabWindow;
  var Mode: TLabWindowMode;
begin
  Window := TLabWindow(GetWindowLongPtrA(Wnd, GWLP_USERDATA));
  if not Assigned(Window) then Exit(DefWindowProc(Wnd, Msg, wParam, lParam));
  case Msg of
    WM_DESTROY, WM_QUIT, WM_CLOSE:
    begin
      Window.Close;
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
      case wParam of
        SIZE_MINIMIZED: Mode := wm_minimized;
        SIZE_MAXIMIZED: Mode := wm_maximized;
        else Mode := wm_normal;
      end;
      Window.Resize(lParam and $ffff, (lParam shr 16) and $ffff, Mode);
    end;
  end;
  Result := DefWindowProc(Wnd, Msg, wParam, lParam);
end;

//TLabWindow BEGIN
procedure TLabWindow.SetCaption(const Value: AnsiString);
begin
  if _Caption = Value then Exit;
end;

procedure TLabWindow.Initialize;
  var WndStyle: LongWord;
  var R: TRect;
begin
  _OnClose := nil;
  _OnTick := nil;
  _Caption := 'LabVulkan';
  if _Width < 128 then _Width := 128;
  if _Height < 32 then _Height := 32;
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
  _Handle := CreateWindowExA(
    WS_EX_WINDOWEDGE or WS_EX_APPWINDOW, PAnsiChar(_WndClassName), PAnsiChar(_Caption),
    WndStyle,
    R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top,
    0, 0, HInstance, nil
  );
  _Instance := GetWindowLongA(_Handle, GWL_HINSTANCE);
  SetWindowLongPtrA(_Handle, GWLP_USERDATA, PtrInt(Self));
  BringWindowToTop(_Handle);
  _Active := True;
  _LoopThread := TLabThread.Create;
  _LoopThread.Proc := @Loop;
  _LoopThread.Start;
end;

procedure TLabWindow.Finalize;
begin
  _LoopThread.WaitFor();
  _LoopThread.Free;
  DestroyWindow(_Handle);
end;

procedure TLabWindow.Loop;
begin
  if Assigned(_OnCreate) then _OnCreate(Self);
  while _Active do
  begin
    if Assigned(_OnTick) then _OnTick(Self);
  end;
  if Assigned(_OnClose) then _OnClose(Self);
end;

procedure TLabWindow.Resize(const NewWidth, NewHeight: Integer; const NewMode: TLabWindowMode);
begin
  _Mode := NewMode;
  _Width := NewWidth;
  _Height := NewHeight;
end;

class constructor TLabWindow.CreateClass;
begin
  LabLog('TLabWindow.CreateClass');
  _WndClassName := 'LabVulkan';
  FillChar(_WndClass, SizeOf(TWndClassExA), 0);
  _WndClass.cbSize := SizeOf(TWndClassExA);
  _WndClass.hIconSm := LoadIcon(MainInstance, 'MAINICON');
  _WndClass.hIcon := LoadIcon(MainInstance, 'MAINICON');
  _WndClass.hInstance := GetModuleHandle(nil);
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
  LabLog('TLabWindow.DestroyClass');
end;

constructor TLabWindow.Create;
begin
  Create(960, 540);
end;

constructor TLabWindow.Create(const NewWidth, NewHeight: Integer);
begin
  LabLog('TLabWindow.Create(' + IntToStr(NewWidth) + ', ' + IntToStr(NewHeight) + ')');
  inherited Create;
  _Width := NewWidth;
  _Height := NewHeight;
  _Mode := wm_normal;
  Initialize;
end;

destructor TLabWindow.Destroy;
begin
  if _Active then Close;
  Finalize;
  inherited Destroy;
  LabLog('TLabWindow.Destroy');
end;

procedure TLabWindow.Close;
begin
  _Active := False;
end;
//TLabWindow END

end.
