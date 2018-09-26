unit cube_data;

interface

uses
  Vulkan;

type
  TVertex = record
    posX, posY, posZ, posW: TVkFloat;
    r, g, b, a: TVkFloat;
  end;

const g_vb: array[0..7] of TVertex = (
  (posX:-1; posY:-1; posZ:-1; posW:1; r:1; g:0; b:0; a:1),
  (posX:1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:0; a:1),
  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:0; b:1; a:1),
  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:1; b:0; a:1),
  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:1; b:1; a:1),
  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:0; b:1; a:1),
  (posX:-1; posY:1; posZ:1; posW:1; r:1; g:1; b:1; a:1),
  (posX:1; posY:1; posZ:1; posW:1; r:0.5; g:0.5; b:0.5; a:1)
);

const g_ib: array[0..35] of TVkUInt16 = (
  //bottom face
  0, 2, 3, 0, 3, 1,
  //front face
  2, 6, 7, 2, 7, 3,
  //right face
  3, 7, 5, 3, 5, 1,
  //rear face
  1, 5, 4, 1, 4, 0,
  //left face
  0, 4, 6, 0, 6, 2,
  //top face
  6, 4, 5, 6, 5, 7
);

implementation

end.
