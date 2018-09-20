unit cube_data;

interface

uses
  Vulkan;

type
  TVertex = record
    posX, posY, posZ, posW: TVkFloat;
    r, g, b, a: TVkFloat;
    u, v: TVkFloat;
  end;

const g_vb_solid_face_colors_Data: array[0..35] of TVertex = (
  //(posX:_,posY:_,posZ:_,posW:1,r:_,g:_,b:_,a:1),
  // red face
  (posX:-1; posY:-1; posZ:1; posW:1; r:1; g:0; b:0; a:1; u:0; v:0),
  (posX:-1; posY:1; posZ:1; posW:1; r:1; g:0; b:0; a:1; u:0; v:1),
  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:0; b:0; a:1; u:1; v:0),
  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:0; b:0; a:1; u:1; v:0),
  (posX:-1; posY:1; posZ:1; posW:1; r:1; g:0; b:0; a:1; u:0; v:1),
  (posX:1; posY:1; posZ:1; posW:1; r:1; g:0; b:0; a:1; u:1; v:1),
  // green face
  (posX:-1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:0; a:1; u:0; v:0),
  (posX:1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:0; a:1; u:0; v:1),
  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1; u:1; v:0),
  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1; u:1; v:0),
  (posX:1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:0; a:1; u:0; v:1),
  (posX:1; posY:1; posZ:-1; posW:1; r:0; g:1; b:0; a:1; u:1; v:1),
  // blue face
  (posX:-1; posY:1; posZ:1; posW:1; r:0; g:0; b:1; a:1; u:0; v:0),
  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:0; b:1; a:1; u:0; v:1),
  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:0; b:1; a:1; u:1; v:0),
  (posX:-1; posY:1; posZ:-1; posW:1; r:0; g:0; b:1; a:1; u:1; v:0),
  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:0; b:1; a:1; u:0; v:1),
  (posX:-1; posY:-1; posZ:-1; posW:1; r:0; g:0; b:1; a:1; u:1; v:1),
  // yellow face
  (posX:1; posY:1; posZ:1; posW:1; r:1; g:1; b:0; a:1; u:0; v:0),
  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:0; a:1; u:0; v:1),
  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:1; b:0; a:1; u:1; v:0),
  (posX:1; posY:-1; posZ:1; posW:1; r:1; g:1; b:0; a:1; u:1; v:0),
  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:0; a:1; u:0; v:1),
  (posX:1; posY:-1; posZ:-1; posW:1; r:1; g:1; b:0; a:1; u:1; v:1),
  // white face
  (posX:1; posY:1; posZ:1; posW:1; r:1; g:1; b:1; a:1; u:0; v:0),
  (posX:-1; posY:1; posZ:1; posW:1; r:1; g:1; b:1; a:1; u:0; v:1),
  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:1; a:1; u:1; v:0),
  (posX:1; posY:1; posZ:-1; posW:1; r:1; g:1; b:1; a:1; u:1; v:0),
  (posX:-1; posY:1; posZ:1; posW:1; r:1; g:1; b:1; a:1; u:0; v:1),
  (posX:-1; posY:1; posZ:-1; posW:1; r:1; g:1; b:1; a:1; u:1; v:1),
  // cyan face
  (posX:1; posY:-1; posZ:1; posW:1; r:0; g:1; b:1; a:1; u:0; v:0),
  (posX:1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:1; a:1; u:0; v:1),
  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:1; b:1; a:1; u:1; v:0),
  (posX:-1; posY:-1; posZ:1; posW:1; r:0; g:1; b:1; a:1; u:1; v:0),
  (posX:1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:1; a:1; u:0; v:1),
  (posX:-1; posY:-1; posZ:-1; posW:1; r:0; g:1; b:1; a:1; u:1; v:1)
);

implementation

end.
