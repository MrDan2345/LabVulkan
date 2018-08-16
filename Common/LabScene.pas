unit LabScene;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabMath,
  LabColladaParser,
  LabDevice,
  LabBuffer;

type
  TLabScene = class;

  TLabSceneGeometry = class (TLabClass)
  public
    type TSubset = class
    private
      var _Geometry: TLabSceneGeometry;
    public
      VertexBuffer: TLabVertexBuffer;
      VertexCount: TVkInt32;
      constructor Create(const AGeometry: TLabSceneGeometry; const Triangles: TLabColladaTriangles);
      destructor Destroy; override;
    end;
    type TSubsetList = specialize TLabList<TSubset>;
  private
    var _Scene: TLabScene;
    var _Subsets: TSubsetList;
  public
    property Scene: TLabScene read _Scene;
    property Subsets: TSubsetList read _Subsets;
    constructor Create(const AScene: TLabScene; const ColladaGeometry: TLabColladaGeometry);
    destructor Destroy; override;
  end;
  TLabSceneGeometryList = specialize TLabList<TLabSceneGeometry>;

  TLabSceneNode = class;
  TLabSceneNodeAttachment = class (TLabClass)
  private
    var _Scene: TLabScene;
    var _Node: TLabSceneNode;
  public
    constructor Create(const AScene: TLabScene; const ANode: TLabSceneNode);
    destructor Destroy; override;
  end;

  TLabSceneNodeAttachmentGeometry = class (TLabSceneNodeAttachment)
  private
    var _Geometry: TLabSceneGeometry;
  public
    property Geometry: TLabSceneGeometry read _Geometry;
    constructor Create(const AScene: TLabScene; const ANode: TLabSceneNode; const ColladaInstanceGeometry: TLabColladaInstanceGeometry);
    destructor Destroy; override;
  end;
  TLabSceneNodeAttachmentGeometryList = specialize TLabList<TLabSceneNodeAttachmentGeometry>;

  TLabSceneNode = class (TLabClass)
  public
    type TNodeList = specialize TLabList<TLabSceneNode>;
  private
    var _Scene: TLabScene;
    var _Parent: TLabSceneNode;
    var _Children: TNodeList;
    var _Transform: TLabMat;
    var _Attachments: TLabSceneNodeAttachmentGeometryList;
    procedure SetParent(const Value: TLabSceneNode);
  public
    property Scene: TLabScene read _Scene;
    property Parent: TLabSceneNode read _Parent write SetParent;
    property Children: TNodeList read _Children;
    property Transform: TLabMat read _Transform write _Transform;
    property Attachments: TLabSceneNodeAttachmentGeometryList read _Attachments;
    constructor Create(
      const AScene: TLabScene;
      const AParent: TLabSceneNode;
      const ANode: TLabColladaNode
    );
    destructor Destroy; override;
  end;

  TLabScene = class (TLabClass)
  private
    var _Device: TLabDeviceShared;
    var _Root: TLabSceneNode;
    var _Geometries: TLabSceneGeometryList;
  public
    property Device: TLabDeviceShared read _Device;
    property Root: TLabSceneNode read _Root;
    procedure Add(const FileName: String);
    constructor Create(const ADevice: TLabDeviceShared);
    destructor Destroy; override;
  end;

implementation

constructor TLabSceneNodeAttachmentGeometry.Create(
  const AScene: TLabScene;
  const ANode: TLabSceneNode;
  const ColladaInstanceGeometry: TLabColladaInstanceGeometry
);
begin
  inherited Create(AScene, ANode);
  if Assigned(ColladaInstanceGeometry.Geometry)
  and Assigned(ColladaInstanceGeometry.Geometry.UserData)
  and (ColladaInstanceGeometry.Geometry.UserData is TLabSceneGeometry) then
  begin
    _Geometry := TLabSceneGeometry(ColladaInstanceGeometry.Geometry.UserData);
  end;
end;

destructor TLabSceneNodeAttachmentGeometry.Destroy;
begin
  inherited Destroy;
end;

constructor TLabSceneNodeAttachment.Create(
  const AScene: TLabScene;
  const ANode: TLabSceneNode
);
begin
  _Scene := AScene;
  _Node := ANode;
end;

destructor TLabSceneNodeAttachment.Destroy;
begin
  inherited Destroy;
end;

constructor TLabSceneGeometry.TSubset.Create(
  const AGeometry: TLabSceneGeometry;
  const Triangles: TLabColladaTriangles
);
  function GetFormat(const Source: TLabColladaSource): TVkFormat;
  begin
    case Source.DataArray.ArrayType of
      at_float:
      begin
        case Source.Accessor.Stride of
          1: Result := VK_FORMAT_R32_SFLOAT;
          2: Result := VK_FORMAT_R32G32_SFLOAT;
          3: Result := VK_FORMAT_R32G32B32_SFLOAT;
          4: Result := VK_FORMAT_R32G32B32A32_SFLOAT;
          else Result := VK_FORMAT_UNDEFINED;
        end;
      end;
      at_int:
      begin
        case Source.Accessor.Stride of
          1: Result := VK_FORMAT_R32_SINT;
          2: Result := VK_FORMAT_R32G32_SINT;
          3: Result := VK_FORMAT_R32G32B32_SINT;
          4: Result := VK_FORMAT_R32G32B32A32_SINT;
          else Result := VK_FORMAT_UNDEFINED;
        end;
      end;
      at_bool:
      begin
        case Source.Accessor.Stride of
          1: Result := VK_FORMAT_R8_UINT;
          2: Result := VK_FORMAT_R8G8_UINT;
          3: Result := VK_FORMAT_R8G8B8_UINT;
          4: Result := VK_FORMAT_R8G8B8A8_UINT;
          else Result := VK_FORMAT_UNDEFINED;
        end;
      end
      else Result := VK_FORMAT_UNDEFINED;
    end;
  end;
  var VStride: TVkInt32;
  var Buffer: array of TVkUInt8;
  var BufferPtr, MapPtr: Pointer;
  var Attributes: array of TLabVertexBufferAttributeFormat;
  var Source: TLabColladaSource;
  var i, j, Offset: TVkInt32;
begin
  _Geometry := AGeometry;
  VertexCount := Triangles.Count * 3;
  Triangles.UserData := Self;
  VStride := Triangles.VertexSize;
  SetLength(Buffer, VStride * Triangles.Count * 3);
  BufferPtr := @Buffer[0];
  for i := 0 to Triangles.Count - 1 do
  for j := 0 to Triangles.Inputs.Count - 1 do
  begin
    Offset := Triangles.Inputs[j].Offset;
    BufferPtr := Triangles.CopyInputData(
      BufferPtr, Triangles.Inputs[j],
      Triangles.Indices^[i * Triangles.Inputs.Count + Offset]
    );
  end;
  SetLength(Attributes, Triangles.VertexDescription.Count);
  Offset := 0;
  for i := 0 to Triangles.VertexDescription.Count - 1 do
  begin
    Source := Triangles.VertexDescription[i].Source as TLabColladaSource;
    Attributes[i] := LabVertexBufferAttributeFormat(
      GetFormat(Source), Offset
    );
    Offset += Source.DataArray.ItemSize * Source.Accessor.Stride;
  end;
  VertexBuffer := TLabVertexBuffer.Create(_Geometry.Scene.Device, Length(Buffer), VStride, Attributes);
  MapPtr := nil;
  if VertexBuffer.Map(MapPtr) then
  begin
    Move(Buffer[0], MapPtr^, Length(Buffer));
    VertexBuffer.Unmap;
  end;
end;

destructor TLabSceneGeometry.TSubset.Destroy;
begin
  VertexBuffer.Free;
  inherited Destroy;
end;

constructor TLabSceneGeometry.Create(
  const AScene: TLabScene;
  const ColladaGeometry: TLabColladaGeometry
);
  var i, j: TVkInt32;
begin
  ColladaGeometry.UserData := Self;
  _Scene := AScene;
  _Subsets := TSubsetList.Create;
  for i := 0 to ColladaGeometry.Meshes.Count - 1 do
  begin
    for j := 0 to ColladaGeometry.Meshes[i].TrianglesList.Count - 1 do
    begin
      _Subsets.Add(TSubset.Create(Self, ColladaGeometry.Meshes[i].TrianglesList[j]));
    end;
  end;
end;

destructor TLabSceneGeometry.Destroy;
begin
  while _Subsets.Count > 0 do _Subsets.Pop.Free;
  _Subsets.Free;
  inherited Destroy;
end;

procedure TLabSceneNode.SetParent(const Value: TLabSceneNode);
begin
  if _Parent = Value then Exit;
  if Assigned(_Parent) then _Parent.Children.Remove(Self);
  _Parent := Value;
  if Assigned(_Parent) then _Parent.Children.Add(Self);
end;

constructor TLabSceneNode.Create(
  const AScene: TLabScene;
  const AParent: TLabSceneNode;
  const ANode: TLabColladaNode
);
  var i: TVkInt32;
begin
  _Scene := AScene;
  _Children := TNodeList.Create;
  _Attachments := TLabSceneNodeAttachmentGeometryList.Create;
  Parent := AParent;
  if Assigned(ANode) then
  begin
    ANode.UserData := Self;
    _Transform := ANode.Matrix;
    for i := 0 to ANode.Children.Count - 1 do
    begin
      if ANode.Children[i] is TLabColladaNode then
      begin
        TLabSceneNode.Create(_Scene, Self, TLabColladaNode(ANode.Children[i]));
      end
      else if ANode.Children[i] is TLabColladaInstanceGeometry then
      begin
        _Attachments.Add(TLabSceneNodeAttachmentGeometry.Create(_Scene, Self, TLabColladaInstanceGeometry(ANode.Children[i])));
      end;
    end;
  end
  else
  begin
    _Transform := LabMatIdentity;
  end;
end;

destructor TLabSceneNode.Destroy;
begin
  while _Attachments.Count > 0 do _Attachments.Pop.Free;
  _Attachments.Free;
  while _Children.Count > 0 do _Children.Pop.Free;
  _Children.Free;
  inherited Destroy;
end;

procedure TLabScene.Add(const FileName: String);
  var Collada: TLabColladaParser;
  var i: TVkInt32;
begin
  Collada := TLabColladaParser.Create(FileName);
  if not Assigned(Collada.RootNode)
  or not Assigned(Collada.RootNode.Scene) then
  begin
    Collada.Free;
    Exit;
  end;
  for i := 0 to Collada.RootNode.LibGeometries.Geometries.Count - 1 do
  begin
    _Geometries.Add(TLabSceneGeometry.Create(Self, Collada.RootNode.LibGeometries.Geometries[i]));
  end;
  for i := 0 to Collada.RootNode.Scene.VisualScene.VisualScene.Nodes.Count - 1 do
  begin
    TLabSceneNode.Create(Self, _Root, Collada.RootNode.Scene.VisualScene.VisualScene.Nodes[i]);
  end;
  Collada.Free;
end;

constructor TLabScene.Create(const ADevice: TLabDeviceShared);
begin
  _Device := ADevice;
  _Root := TLabSceneNode.Create(Self, nil, nil);
  _Geometries := TLabSceneGeometryList.Create;
end;

destructor TLabScene.Destroy;
begin
  while _Geometries.Count > 0 do _Geometries.Pop.Free;
  _Root.Free;
  inherited Destroy;
end;

end.
