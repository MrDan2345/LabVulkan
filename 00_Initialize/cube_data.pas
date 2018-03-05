unit cube_data;

interface

uses
  Vulkan;

type
  TVertex = record
    posX, posY, posZ, posW: TVkFloat;  // Position data
    r, g, b, a: TVkFloat;              // Color
  end;

  TVertexUV = record
    posX, posY, posZ, posW: TVkFloat;  // Position data
    u, v: TVkFloat;                    // texture u,v
  end;

//#define XYZ1(_x_, _y_, _z_) (_x_), (_y_), (_z_), 1.f
//#define UV(_u_, _v_) (_u_), (_v_)

const g_vbData: array[0..35] of TVertex = (
    (posX:-1; posY:-1; posZ:-1; posW:1; r:0; g:0; b:0; a:1),  (posX:1; posY:-1; posZ:-1; posW:1; r:1; g:0; b:0; a:1),  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),
    (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),  (posX:1; posY:-1; posZ:-1; posW:1; r:1; g:0; b:0; a:1),  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:0; a:1),

    (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:0; b:1; a:1),  (posX:-1; posY:1; posZ:1; posW:1; r:0; g:1; b:1; a:1),  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:0; b:1; a:1),
    (posX:1; posY:-1; posZ:1; posW:1; r:1; g:0; b:1; a:1),  (posX:-1; posY:1; posZ:1; posW:1; r:0; g:1; b:1; a:1),  (posX:1; posY:1; posZ:1; posW:1; r:1; g:1; b:1; a:1),

    (posX:1; posY:1; posZ:1; posW:1; r:1; g:1; b:1; a:1),  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:0; a:1),  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:0; b:1; a:1),
    (posX:1; posY:-1; posZ:1; posW:1; r:1; g:0; b:1; a:1),  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:0; a:1),  (posX:1; posY:-1; posZ:-1; posW:1; r:1; g:0; b:0; a:1),

    (posX:-1; posY:1; posZ:1; posW:1; r:0; g:1; b:1; a:1),  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:0; b:1; a:1),  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),
    (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:0; b:1; a:1),  (posX:-1; posY:-1; posZ:-1; posW:1; r:0; g:0; b:0; a:1),

    (posX:1; posY:1; posZ:1; posW:1; r:1; g:1; b:1; a:1),  (posX:-1; posY:1; posZ:1; posW:1; r:0; g:1; b:1; a:1),  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:0; a:1),
    (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:0; a:1),  (posX:-1; posY:1; posZ:1; posW:1; r:0; g:1; b:1; a:1),  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),

    (posX:1; posY:-1; posZ:1; posW:1; r:1; g:0; b:1; a:1),  (posX:1; posY:-1; posZ:-1; posW:1; r:1; g:0; b:0; a:1),  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:0; b:1; a:1),
    (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:0; b:1; a:1),  (posX:1; posY:-1; posZ:-1; posW:1; r:1; g:0; b:0; a:1),  (posX:-1; posY:-1; posZ:-1; posW:1; r:0; g:0; b:0; a:1)
);

const g_vb_solid_face_colors_Data: array[0..35] of TVertex = (
  //(posX:_,posY:_,posZ:_,posW:1,r:_,g:_,b:_,a:1),
  // red face
  (posX:-1; posY:-1; posZ:1; posW:1; r:1; g:0; b:0; a:1),
  (posX:-1; posY:1; posZ:1; posW:1; r:1; g:0; b:0; a:1),
  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:0; b:0; a:1),
  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:0; b:0; a:1),
  (posX:-1; posY:1; posZ:1; posW:1; r:1; g:0; b:0; a:1),
  (posX:1; posY:1; posZ:1; posW:1; r:1; g:0; b:0; a:1),
  // green face
  (posX:-1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),
  (posX:1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),
  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),
  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),
  (posX:1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),
  (posX:1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),
  // blue face
  (posX:-1; posY:1; posZ:1; posW:1; r:0; g:0; b:1; a:1),
  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:0; b:1; a:1),
  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:0; b:1; a:1),
  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:0; b:1; a:1),
  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:0; b:1; a:1),
  (posX:-1; posY:-1; posZ:-1; posW:1; r:0; g:0; b:1; a:1),
  // yellow face
  (posX:1; posY:1; posZ:1; posW:1; r:1; g:1; b:0; a:1),
  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:0; a:1),
  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:1; b:0; a:1),
  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:1; b:0; a:1),
  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:0; a:1),
  (posX:1; posY:-1; posZ:-1; posW:1; r:1; g:1; b:0; a:1),
  // magenta face
  (posX:1; posY:1; posZ:1; posW:1; r:1; g:0; b:1; a:1),
  (posX:-1; posY:1; posZ:1; posW:1; r:1; g:0; b:1; a:1),
  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:0; b:1; a:1),
  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:0; b:1; a:1),
  (posX:-1; posY:1; posZ:1; posW:1; r:1; g:0; b:1; a:1),
  (posX:-1; posY:1; posZ:-1; posW:1; r:1; g:0; b:1; a:1),
  // cyan face
  (posX:1; posY:-1; posZ:1; posW:1; r:0; g:1; b:1; a:1),
  (posX:1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:1; a:1),
  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:1; b:1; a:1),
  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:1; b:1; a:1),
  (posX:1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:1; a:1),
  (posX:-1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:1; a:1)
);

const g_vb_texture_Data: array[0..35] of TVertexUV = (
  //(posX:_,posY:_,posZ:_,posW:1,u:_,v:_),
  // left face
  (posX:-1; posY:-1; posZ:-1; posW:1; u:1; v:0),
  (posX:-1; posY:1; posZ:1; posW:1; u:0; v:1),
  (posX:-1; posY:-1; posZ:1; posW:1; u:0; v:0),
  (posX:-1; posY:1; posZ:1; posW:1; u:0; v:1),
  (posX:-1; posY:-1; posZ:-1; posW:1; u:1; v:0),
  (posX:-1; posY:1; posZ:-1; posW:1; u:1; v:1),
  // front face
  (posX:-1; posY:-1; posZ:-1; posW:1; u:0; v:0),
  (posX:1; posY:-1; posZ:-1; posW:1; u:1; v:0),
  (posX:1; posY:1; posZ:-1; posW:1; u:1; v:1),
  (posX:-1; posY:-1; posZ:-1; posW:1; u:0; v:0),
  (posX:1; posY:1; posZ:-1; posW:1; u:1; v:1),
  (posX:-1; posY:1; posZ:-1; posW:1; u:0; v:1),
  // top face
  (posX:-1; posY:-1; posZ:-1; posW:1; u:0; v:1),
  (posX:1; posY:-1; posZ:1; posW:1; u:1; v:0),
  (posX:1; posY:-1; posZ:-1; posW:1; u:1; v:1),
  (posX:-1; posY:-1; posZ:-1; posW:1; u:0; v:1),
  (posX:-1; posY:-1; posZ:1; posW:1; u:0; v:0),
  (posX:1; posY:-1; posZ:1; posW:1; u:1; v:0),
  // bottom face
  (posX:-1; posY:1; posZ:-1; posW:1; u:0; v:0),
  (posX:1; posY:1; posZ:1; posW:1; u:1; v:1),
  (posX:-1; posY:1; posZ:1; posW:1; u:0; v:1),
  (posX:-1; posY:1; posZ:-1; posW:1; u:0; v:0),
  (posX:1; posY:1; posZ:-1; posW:1; u:1; v:0),
  (posX:1; posY:1; posZ:1; posW:1; u:1; v:1),
  // right face
  (posX:1; posY:1; posZ:-1; posW:1; u:0; v:1),
  (posX:1; posY:-1; posZ:1; posW:1; u:1; v:0),
  (posX:1; posY:1; posZ:1; posW:1; u:1; v:1),
  (posX:1; posY:-1; posZ:1; posW:1; u:1; v:0),
  (posX:1; posY:1; posZ:-1; posW:1; u:0; v:1),
  (posX:1; posY:-1; posZ:-1; posW:1; u:0; v:0),
  // back face
  (posX:-1; posY:1; posZ:1; posW:1; u:1; v:1),
  (posX:1; posY:1; posZ:1; posW:1; u:0; v:1),
  (posX:-1; posY:-1; posZ:1; posW:1; u:1; v:0),
  (posX:-1; posY:-1; posZ:1; posW:1; u:1; v:0),
  (posX:1; posY:1; posZ:1; posW:1; u:0; v:1),
  (posX:1; posY:-1; posZ:1; posW:1; u:0; v:0)
);

implementation

end.
