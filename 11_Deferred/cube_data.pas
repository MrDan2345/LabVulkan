unit cube_data;

interface

uses
  Vulkan;

type
  TVertex = record
    x, y, z, w: TVkFloat;
    r, g, b, a: TVkFloat;
    u, v: TVkFloat;
  end;

const g_vb_solid_face_colors_Data: array[0..35] of TVertex = (
  //(posX:_,posY:_,posZ:_,posW:1,r:_,g:_,b:_,a:1),
  // red face
  (x:-1; y:-1; z:1; w:1; r:1; g:0; b:0; a:1; u:0; v:0),
  (x:-1; y:1; z:1; w:1; r:1; g:0; b:0; a:1; u:0; v:1),
  (x:1; y:-1; z:1; w:1; r:1; g:0; b:0; a:1; u:1; v:0),
  (x:1; y:-1; z:1; w:1; r:1; g:0; b:0; a:1; u:1; v:0),
  (x:-1; y:1; z:1; w:1; r:1; g:0; b:0; a:1; u:0; v:1),
  (x:1; y:1; z:1; w:1; r:1; g:0; b:0; a:1; u:1; v:1),
  // green face
  (x:-1; y:-1; z:-1; w:1; r:0; g:1; b:0; a:1; u:0; v:0),
  (x:1; y:-1; z:-1; w:1; r:0; g:1; b:0; a:1; u:0; v:1),
  (x:-1; y:1; z:-1; w:1; r:0; g:1; b:0; a:1; u:1; v:0),
  (x:-1; y:1; z:-1; w:1; r:0; g:1; b:0; a:1; u:1; v:0),
  (x:1; y:-1; z:-1; w:1; r:0; g:1; b:0; a:1; u:0; v:1),
  (x:1; y:1; z:-1; w:1; r:0; g:1; b:0; a:1; u:1; v:1),
  // blue face
  (x:-1; y:1; z:1; w:1; r:0; g:0; b:1; a:1; u:0; v:0),
  (x:-1; y:-1; z:1; w:1; r:0; g:0; b:1; a:1; u:0; v:1),
  (x:-1; y:1; z:-1; w:1; r:0; g:0; b:1; a:1; u:1; v:0),
  (x:-1; y:1; z:-1; w:1; r:0; g:0; b:1; a:1; u:1; v:0),
  (x:-1; y:-1; z:1; w:1; r:0; g:0; b:1; a:1; u:0; v:1),
  (x:-1; y:-1; z:-1; w:1; r:0; g:0; b:1; a:1; u:1; v:1),
  // yellow face
  (x:1; y:1; z:1; w:1; r:1; g:1; b:0; a:1; u:0; v:0),
  (x:1; y:1; z:-1; w:1; r:1; g:1; b:0; a:1; u:0; v:1),
  (x:1; y:-1; z:1; w:1; r:1; g:1; b:0; a:1; u:1; v:0),
  (x:1; y:-1; z:1; w:1; r:1; g:1; b:0; a:1; u:1; v:0),
  (x:1; y:1; z:-1; w:1; r:1; g:1; b:0; a:1; u:0; v:1),
  (x:1; y:-1; z:-1; w:1; r:1; g:1; b:0; a:1; u:1; v:1),
  // white face
  (x:1; y:1; z:1; w:1; r:1; g:1; b:1; a:1; u:0; v:0),
  (x:-1; y:1; z:1; w:1; r:1; g:1; b:1; a:1; u:0; v:1),
  (x:1; y:1; z:-1; w:1; r:1; g:1; b:1; a:1; u:1; v:0),
  (x:1; y:1; z:-1; w:1; r:1; g:1; b:1; a:1; u:1; v:0),
  (x:-1; y:1; z:1; w:1; r:1; g:1; b:1; a:1; u:0; v:1),
  (x:-1; y:1; z:-1; w:1; r:1; g:1; b:1; a:1; u:1; v:1),
  // cyan face
  (x:1; y:-1; z:1; w:1; r:0; g:1; b:1; a:1; u:0; v:0),
  (x:1; y:-1; z:-1; w:1; r:0; g:1; b:1; a:1; u:0; v:1),
  (x:-1; y:-1; z:1; w:1; r:0; g:1; b:1; a:1; u:1; v:0),
  (x:-1; y:-1; z:1; w:1; r:0; g:1; b:1; a:1; u:1; v:0),
  (x:1; y:-1; z:-1; w:1; r:0; g:1; b:1; a:1; u:0; v:1),
  (x:-1; y:-1; z:-1; w:1; r:0; g:1; b:1; a:1; u:1; v:1)
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

function Vertex(const x, y, z, w, r, g, b, a, u, v: TVkFloat): TVertex; inline;

implementation

function Vertex(const x, y, z, w, r, g, b, a, u, v: TVkFloat): TVertex;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
  Result.w := w;
  Result.r := r;
  Result.g := g;
  Result.b := b;
  Result.a := a;
  Result.u := u;
  Result.v := v;
end;

end.
