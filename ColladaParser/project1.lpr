program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Windows,
  Classes,
  LabMath,
  LabColladaParser,
  GL;

{$R *.res}

type TVertex = packed record
  Pos: TLabVec3;
  Color: TLabVec4;
end;

var WindowHandle: HWND;
var AppRunning: Boolean;
var Context: HGLRC;
var DC: HDC;
var Collada: TLabColladaParser;

procedure Initialize;
  var Vertices: array[0..3] of TVertex;
  var Indices: array[0..5] of Word;
begin
  Collada := TLabColladaParser.Create('../Models/skull.dae');
  Collada.RootNode.Dump;
  Vertices[0].Pos.SetValue(-2, 2, 0); Vertices[0].Color.SetValue(1, 0, 0, 1);
  Vertices[1].Pos.SetValue(2, 2, 0); Vertices[1].Color.SetValue(0, 1, 0, 1);
  Vertices[2].Pos.SetValue(-2, -2, 0); Vertices[2].Color.SetValue(0, 0, 1, 1);
  Vertices[3].Pos.SetValue(2, -2, 0); Vertices[3].Color.SetValue(1, 1, 0, 1);
end;

procedure Finalize;
begin
  Collada.Free;
end;

procedure OnUpdate;
begin

end;

procedure OnRender;
  var W, V, P, WV: TLabMat;
  var gi, mi, ti, i, j, vi, n: Integer;
  var g: TLabColladaGeometry;
  var m: TLabColladaMesh;
  var t: TLabColladaTriangles;
  var s: TLabColladaSource;
begin
  W := LabMatRotationY(GetTickCount * 0.001);
  V := LabMatView(LabVec3(0, 5, -5), LabVec3(0, 0, 0), LabVec3(0, 1, 0));
  P := LabMatProj(Pi / 4, 1, 1, 100);
  WV := W * V;
  glMatrixMode(GL_MODELVIEW);
  glLoadMatrixf(@WV);
  glMatrixMode(GL_PROJECTION);
  glLoadMatrixf(@P);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  glEnable(GL_DEPTH_TEST);

  glBegin(GL_TRIANGLES);
  for gi := 0 to Collada.RootNode.LibGeometries.Geometries.Count - 1 do
  begin
    g := Collada.RootNode.LibGeometries.Geometries[gi];
    for mi := 0 to g.Meshes.Count - 1 do
    begin
      m := g.Meshes[mi];
      for ti := 0 to m.TrianglesList.Count - 1 do
      begin
        t := m.TrianglesList[ti];
        vi := -1;
        for i := 0 to t.Inputs.Count - 1 do
        if t.Inputs[i].Semantic = 'VERTEX' then
        begin
          vi := i;
          Break;
        end;
        if vi > -1 then
        begin
          for j := 0 to t.Count * 3 - 1 do
          begin
            for i := 0 to t.Inputs.Count - 1 do
            if i <> vi then
            begin
              s := t.Inputs[i].Source as TLabColladaSource;
              n := t.Indices^[t.Inputs.Count * j + t.Inputs[i].Offset];
              if t.Inputs[i].Semantic = 'NORMAL' then
              begin
                case s.DataArray.ArrayType of
                  at_float:
                  begin
                    case s.Accessor.Stride of
                      3:
                      begin
                        glNormal3f(
                          s.DataArray.AsFloat[n * s.Accessor.Stride + 0]^,
                          s.DataArray.AsFloat[n * s.Accessor.Stride + 1]^,
                          s.DataArray.AsFloat[n * s.Accessor.Stride + 2]^
                        );
                      end;
                    end;
                  end;
                end;
              end
              else if t.Inputs[i].Semantic = 'COLOR' then
              begin
                case s.DataArray.ArrayType of
                  at_float:
                  begin
                    case s.Accessor.Stride of
                      3:
                      begin
                        glColor3f(
                          s.DataArray.AsFloat[n * s.Accessor.Stride + 0]^,
                          s.DataArray.AsFloat[n * s.Accessor.Stride + 1]^,
                          s.DataArray.AsFloat[n * s.Accessor.Stride + 2]^
                        );
                      end;
                    end;
                  end;
                end;
              end;
            end;
            i := vi;
            s := ((t.Inputs[i].Source as TLabColladaVertices).Inputs[0].Source as TLabColladaSource);
            n := t.Indices^[t.Inputs.Count * j + t.Inputs[i].Offset];
            case s.DataArray.ArrayType of
              at_float:
              begin
                case s.Accessor.Stride of
                  3:
                  begin
                    glVertex3f(
                      s.DataArray.AsFloat[n * s.Accessor.Stride + 0]^,
                      s.DataArray.AsFloat[n * s.Accessor.Stride + 1]^,
                      s.DataArray.AsFloat[n * s.Accessor.Stride + 2]^
                    );
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  glEnd;

  //glBegin(GL_QUADS);
  //glColor4f(1, 0, 0, 1); glVertex3f(-2, 2, 0);
  //glColor4f(0, 1, 0, 1); glVertex3f(2, 2, 0);
  //glColor4f(0, 0, 1, 1); glVertex3f(2, -2, 0);
  //glColor4f(1, 1, 0, 1); glVertex3f(-2, -2, 0);
  //glEnd;

  SwapBuffers(DC);
end;

function MessageHandler(Wnd: HWnd; Msg: UInt; wParam: WPARAM; lParam: LPARAM): LResult; stdcall;
begin
  case Msg of
    WM_DESTROY, WM_QUIT, WM_CLOSE:
    begin
      PostQuitMessage(0);
      Result := 0;
      Exit;
    end;
    WM_KEYDOWN:
    begin
      if wParam = VK_ESCAPE then AppRunning := False;
    end;
    WM_KEYUP:
    begin

    end;
    WM_LBUTTONDOWN:
    begin

    end;
    WM_LBUTTONUP:
    begin

    end;
    WM_RBUTTONDOWN:
    begin

    end;
    WM_RBUTTONUP:
    begin

    end;
    WM_MBUTTONDOWN:
    begin

    end;
    WM_MBUTTONUP:
    begin

    end;
  end;
  Result := DefWindowProcA(Wnd, Msg, wParam, lParam);
end;

procedure CreateWindow(const W, H: Integer; const Caption: AnsiString = 'PureOGL');
  var WndClass: TWndClassExA;
  var WndClassName: AnsiString;
  var R: TRect;
  var WndStyle: DWord;
begin
  WndClassName := 'PureOGL';
  FillChar(WndClass, SizeOf(TWndClassExA), 0);
  WndClass.cbSize := SizeOf(TWndClassExA);
  WndClass.hIconSm := LoadIcon(MainInstance, 'MAINICON');
  WndClass.hIcon := LoadIcon(MainInstance, 'MAINICON');
  WndClass.hInstance := HInstance;
  WndClass.hCursor := LoadCursor(0, IDC_ARROW);
  WndClass.lpszClassName := PAnsiChar(WndClassName);
  WndClass.style := CS_HREDRAW or CS_VREDRAW or CS_OWNDC or CS_DBLCLKS;
  WndClass.lpfnWndProc := @MessageHandler;
  if RegisterClassExA(WndClass) = 0 then
  WndClassName := 'Static';
  WndStyle := (
    WS_CAPTION or
    WS_POPUP or
    WS_VISIBLE or
    WS_EX_TOPMOST or
    WS_MINIMIZEBOX or
    WS_SYSMENU
  );
  R.Left := (GetSystemMetrics(SM_CXSCREEN) - W) div 2;
  R.Right := R.Left + W;
  R.Top := (GetSystemMetrics(SM_CYSCREEN) - H) div 2;
  R.Bottom := R.Top + H;
  AdjustWindowRect(R, WndStyle, False);
  WindowHandle := CreateWindowExA(
    0, PAnsiChar(WndClassName), PAnsiChar(Caption),
    WndStyle,
    R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top,
    0, 0, HInstance, nil
  );
end;

procedure FreeWindow;
begin
  DestroyWindow(WindowHandle);
end;

procedure CreateDevice;
  var pfd: TPixelFormatDescriptor;
  var pf: Integer;
  var R: TRect;
begin
  DC := GetDC(WindowHandle);
  FillChar(pfd, SizeOf(pfd), 0);
  pfd.nSize := SizeOf(pfd);
  pfd.nVersion := 1;
  pfd.dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
  pfd.iPixelType := PFD_TYPE_RGBA;
  pfd.cColorBits := 32;
  pfd.cAlphaBits := 8;
  pfd.cDepthBits := 16;
  pfd.iLayerType := PFD_MAIN_PLANE;
  pf := ChoosePixelFormat(DC, @pfd);
  SetPixelFormat(DC, pf, @pfd);
  Context := wglCreateContext(DC);
  wglMakeCurrent(DC, Context);
  GetClientRect(WindowHandle, R);
  glViewport(0, 0, R.Right - R.Left, R.Bottom - R.Top);
  glClearColor(0.5, 0.5, 0.5, 1);
  glClearDepth(1);
  glEnable(GL_TEXTURE_2D);
  glShadeModel(GL_SMOOTH);
  glDisable(GL_CULL_FACE);
  glEnable(GL_BLEND);
end;

procedure FreeDevice;
begin
  wglMakeCurrent(DC, Context);
  wglDeleteContext(Context);
  ReleaseDC(WindowHandle, DC);
end;

procedure Loop;
  var msg: TMsg;
begin
  AppRunning := True;
  FillChar(msg, SizeOf(msg), 0);
  while AppRunning
  and (msg.message <> WM_QUIT)
  and (msg.message <> WM_DESTROY)
  and (msg.message <> WM_CLOSE) do
  begin
    if PeekMessage(msg, 0, 0, 0, PM_REMOVE) then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end
    else
    begin
      OnUpdate;
      OnRender;
    end
  end;
  ExitCode := 0;
end;

begin
  CreateWindow(800, 600);
  CreateDevice;
  Initialize;
  Loop;
  Finalize;
  FreeDevice;
  FreeWindow;
end.

