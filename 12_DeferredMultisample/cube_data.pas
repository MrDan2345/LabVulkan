unit cube_data;

interface

uses
  Vulkan;

type
  TVertex = record
    x, y, z, w: TVkFloat;
    nx, ny, nz: TVkFloat;
    tx, ty, tz: TVkFloat;
    r, g, b, a: TVkFloat;
    u, v: TVkFloat;
  end;

const g_vb_solid_face_colors_Data: array[0..71] of TVertex = (
  //(posX:_,posY:_,posZ:_,posW:1,r:_,g:_,b:_,a:1),
  // red face
  (x:-1; y:-1; z:1; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:1; g:0; b:0; a:1; u:0; v:0),
  (x:-1; y:1; z:1; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:1; g:0; b:0; a:1; u:0; v:1),
  (x:1; y:-1; z:1; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:1; g:0; b:0; a:1; u:1; v:0),
  (x:1; y:-1; z:1; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:1; g:0; b:0; a:1; u:1; v:0),
  (x:-1; y:1; z:1; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:1; g:0; b:0; a:1; u:0; v:1),
  (x:1; y:1; z:1; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:1; g:0; b:0; a:1; u:1; v:1),
  // green face
  (x:1; y:-1; z:-1; w:1; nx:0; ny:0; nz:-1; tx:-1; ty:0; tz:0; r:0; g:1; b:0; a:1; u:0; v:0),
  (x:1; y:1; z:-1; w:1; nx:0; ny:0; nz:-1; tx:-1; ty:0; tz:0; r:0; g:1; b:0; a:1; u:0; v:1),
  (x:-1; y:-1; z:-1; w:1; nx:0; ny:0; nz:-1; tx:-1; ty:0; tz:0; r:0; g:1; b:0; a:1; u:1; v:0),
  (x:-1; y:-1; z:-1; w:1; nx:0; ny:0; nz:-1; tx:-1; ty:0; tz:0; r:0; g:1; b:0; a:1; u:1; v:0),
  (x:1; y:1; z:-1; w:1; nx:0; ny:0; nz:-1; tx:-1; ty:0; tz:0; r:0; g:1; b:0; a:1; u:0; v:1),
  (x:-1; y:1; z:-1; w:1; nx:0; ny:0; nz:-1; tx:-1; ty:0; tz:0; r:0; g:1; b:0; a:1; u:1; v:1),
  // blue face
  (x:-1; y:1; z:1; w:1; nx:-1; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0; g:0; b:1; a:1; u:0; v:0),
  (x:-1; y:-1; z:1; w:1; nx:-1; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0; g:0; b:1; a:1; u:0; v:1),
  (x:-1; y:1; z:-1; w:1; nx:-1; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0; g:0; b:1; a:1; u:1; v:0),
  (x:-1; y:1; z:-1; w:1; nx:-1; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0; g:0; b:1; a:1; u:1; v:0),
  (x:-1; y:-1; z:1; w:1; nx:-1; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0; g:0; b:1; a:1; u:0; v:1),
  (x:-1; y:-1; z:-1; w:1; nx:-1; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0; g:0; b:1; a:1; u:1; v:1),
  // yellow face
  (x:1; y:1; z:-1; w:1; nx:1; ny:0; nz:0; tx:0; ty:0; tz:1; r:1; g:1; b:0; a:1; u:0; v:0),
  (x:1; y:-1; z:-1; w:1; nx:1; ny:0; nz:0; tx:0; ty:0; tz:1; r:1; g:1; b:0; a:1; u:0; v:1),
  (x:1; y:1; z:1; w:1; nx:1; ny:0; nz:0; tx:0; ty:0; tz:1; r:1; g:1; b:0; a:1; u:1; v:0),
  (x:1; y:1; z:1; w:1; nx:1; ny:0; nz:0; tx:0; ty:0; tz:1; r:1; g:1; b:0; a:1; u:1; v:0),
  (x:1; y:-1; z:-1; w:1; nx:1; ny:0; nz:0; tx:0; ty:0; tz:1; r:1; g:1; b:0; a:1; u:0; v:1),
  (x:1; y:-1; z:1; w:1; nx:1; ny:0; nz:0; tx:0; ty:0; tz:1; r:1; g:1; b:0; a:1; u:1; v:1),
  // white face
  (x:1; y:1; z:1; w:1; nx:0; ny:1; nz:0; tx:0; ty:0; tz:-1; r:1; g:1; b:1; a:1; u:0; v:0),
  (x:-1; y:1; z:1; w:1; nx:0; ny:1; nz:0; tx:0; ty:0; tz:-1; r:1; g:1; b:1; a:1; u:0; v:1),
  (x:1; y:1; z:-1; w:1; nx:0; ny:1; nz:0; tx:0; ty:0; tz:-1; r:1; g:1; b:1; a:1; u:1; v:0),
  (x:1; y:1; z:-1; w:1; nx:0; ny:1; nz:0; tx:0; ty:0; tz:-1; r:1; g:1; b:1; a:1; u:1; v:0),
  (x:-1; y:1; z:1; w:1; nx:0; ny:1; nz:0; tx:0; ty:0; tz:-1; r:1; g:1; b:1; a:1; u:0; v:1),
  (x:-1; y:1; z:-1; w:1; nx:0; ny:1; nz:0; tx:0; ty:0; tz:-1; r:1; g:1; b:1; a:1; u:1; v:1),
  // cyan face
  (x:1; y:-1; z:1; w:1; nx:0; ny:-1; nz:0; tx:1; ty:0; tz:0; r:0; g:1; b:1; a:1; u:0; v:0),
  (x:1; y:-1; z:-1; w:1; nx:0; ny:-1; nz:0; tx:1; ty:0; tz:0; r:0; g:1; b:1; a:1; u:0; v:1),
  (x:-1; y:-1; z:1; w:1; nx:0; ny:-1; nz:0; tx:1; ty:0; tz:0; r:0; g:1; b:1; a:1; u:1; v:0),
  (x:-1; y:-1; z:1; w:1; nx:0; ny:-1; nz:0; tx:1; ty:0; tz:0; r:0; g:1; b:1; a:1; u:1; v:0),
  (x:1; y:-1; z:-1; w:1; nx:0; ny:-1; nz:0; tx:1; ty:0; tz:0; r:0; g:1; b:1; a:1; u:0; v:1),
  (x:-1; y:-1; z:-1; w:1; nx:0; ny:-1; nz:0; tx:1; ty:0; tz:0; r:0; g:1; b:1; a:1; u:1; v:1),

    // outter back
  (x:-10; y:-10; z:10; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:0; v:0),
  (x:10; y:-10; z:10; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:-10; y:10; z:10; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  (x:10; y:-10; z:10; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:10; y:10; z:10; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:1; v:1),
  (x:-10; y:10; z:10; w:1; nx:0; ny:0; nz:1; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  // outter front
  (x:10; y:-10; z:-10; w:1; nx:0; ny:0; nz:-10; tx:-1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:0; v:0),
  (x:-10; y:-10; z:-10; w:1; nx:0; ny:0; nz:-10; tx:-1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:10; y:100; z:-10; w:1; nx:0; ny:0; nz:-10; tx:-1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  (x:-10; y:-10; z:-10; w:1; nx:0; ny:0; nz:-10; tx:-1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:-10; y:10; z:-10; w:1; nx:0; ny:0; nz:-10; tx:-1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:1; v:1),
  (x:10; y:10; z:-10; w:1; nx:0; ny:0; nz:-10; tx:-1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  // outter left
  (x:-10; y:10; z:10; w:1; nx:-10; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:0; v:0),
  (x:-10; y:10; z:-10; w:1; nx:-10; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:-10; y:-10; z:10; w:1; nx:-10; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  (x:-10; y:10; z:-10; w:1; nx:-10; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:-10; y:-10; z:-10; w:1; nx:-10; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:1; v:1),
  (x:-10; y:-10; z:10; w:1; nx:-10; ny:0; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  // outter right
  (x:10; y:10; z:-10; w:1; nx:10; ny:0; nz:0; tx:0; ty:0; tz:1; r:0.5; g:0.5; b:0.5; a:1; u:0; v:0),
  (x:10; y:10; z:10; w:1; nx:10; ny:0; nz:0; tx:0; ty:0; tz:1; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:10; y:-10; z:-10; w:1; nx:10; ny:0; nz:0; tx:0; ty:0; tz:1; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  (x:10; y:10; z:10; w:1; nx:10; ny:0; nz:0; tx:0; ty:0; tz:1; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:10; y:-10; z:10; w:1; nx:10; ny:0; nz:0; tx:0; ty:0; tz:1; r:0.5; g:0.5; b:0.5; a:1; u:1; v:1),
  (x:10; y:-10; z:-10; w:1; nx:10; ny:0; nz:0; tx:0; ty:0; tz:1; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  // outter top
  (x:10; y:10; z:10; w:1; nx:0; ny:10; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:0; v:0),
  (x:10; y:10; z:-10; w:1; nx:0; ny:10; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:-10; y:10; z:10; w:1; nx:0; ny:10; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  (x:10; y:10; z:-10; w:1; nx:0; ny:10; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:-10; y:10; z:-10; w:1; nx:0; ny:10; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:1; v:1),
  (x:-10; y:10; z:10; w:1; nx:0; ny:10; nz:0; tx:0; ty:0; tz:-1; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  // outter bottom
  (x:10; y:-10; z:10; w:1; nx:0; ny:-10; nz:0; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:0; v:0),
  (x:-10; y:-10; z:10; w:1; nx:0; ny:-10; nz:0; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:10; y:-10; z:-10; w:1; nx:0; ny:-10; nz:0; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1),
  (x:-10; y:-10; z:10; w:1; nx:0; ny:-10; nz:0; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:1; v:0),
  (x:-10; y:-10; z:-10; w:1; nx:0; ny:-10; nz:0; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:1; v:1),
  (x:10; y:-10; z:-10; w:1; nx:0; ny:-10; nz:0; tx:1; ty:0; tz:0; r:0.5; g:0.5; b:0.5; a:1; u:0; v:1)
);

//const fullscreen_quad_vb: array[0..3] of TVertex = (
//  (x:-1; y:-1; z:0.5; w:1; r:1; g:1; b:1; a:1; u:0; v:0),
//  (x:1; y:-1; z:0.5; w:1; r:1; g:1; b:1; a:1; u:1; v:0),
//  (x:-1; y:1; z:0.5; w:1; r:1; g:1; b:1; a:1; u:0; v:1),
//  (x:1; y:1; z:0.5; w:1; r:1; g:1; b:1; a:1; u:1; v:1)
//);

const fullscreen_quad_ib: array[0..5] of TVkUInt16 = (
  0, 1, 2, 2, 1, 3
);

implementation

end.
