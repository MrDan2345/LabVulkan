unit LabDebugDraw;

interface

uses
  Vulkan,
  LabTypes,
  LabUtils,
  LabMath,
  LabDevice,
  LabBuffer,
  LabCommandBuffer,
  LabPipeline,
  LabRenderPass,
  LabScene,
  LabColladaParser,
  Classes,
  SysUtils;

type
  TLabDebugDraw = class (TLabClass)
  public
    type TVertex = record
      Position: TLabVec4;
      Color: TLabVec4;
    end;
    type TVertexArr = array[Word] of TVertex;
    type PVertexArr = ^TVertexArr;
    type TTransforms = packed record
      World: TLabMat;
      View: TLabMat;
      Projection: TLabMat;
      WVP: TLabMat;
    end;
    type PTransforms = ^TTransforms;
  private
    var _Device: TLabDeviceShared;
    var _VertexBuffer: TLabVertexBuffer;
    var _VertexBufferMap: PVertexArr;
    var _UniformBuffer: TLabUniformBuffer;
    var _UniformBufferMap: PTransforms;
    var _Vertices: array of TVertex;
    var _CurVertex: TVkInt32;
    var _FlushedVertices: TVkInt32;
    var _Shader: TLabSceneShader;
    var _PipelineLayout: TLabPipelineLayout;
    var _Pipeline: TLabPipelineShared;
    procedure Allocate(const Amount: TVkInt32);
    procedure AddLine(const v0, v1: TLabVec3; const c0, c1: TLabVec4);
  public
    property Transforms: PTransforms read _UniformBufferMap;
    constructor Create(const ADevice: TLabDeviceShared);
    destructor Destroy; override;
    procedure DrawTransform(const xf: TLabMat);
    procedure Flush;
    procedure Draw(
      const Cmd: TLabCommandBuffer;
      const PipelineCache: TLabPipelineCache;
      const RenderPass: TLabRenderPass;
      const Viewport: TVkViewport;
      const SampleCount: TVkSampleCountFlagBits = VK_SAMPLE_COUNT_1_BIT
    );
  end;

implementation

procedure TLabDebugDraw.Allocate(const Amount: TVkInt32);
begin
  if Length(_Vertices) >= Amount then Exit;
  SetLength(_Vertices, Amount);
end;

procedure TLabDebugDraw.AddLine(const v0, v1: TLabVec3; const c0, c1: TLabVec4);
begin
  Allocate(_CurVertex + 2);
  _Vertices[_CurVertex].Position := LabVec4(v0, 1);
  _Vertices[_CurVertex].Color := c0;
  Inc(_CurVertex);
  _Vertices[_CurVertex].Position := LabVec4(v1, 1);
  _Vertices[_CurVertex].Color := c1;
  Inc(_CurVertex);
end;

constructor TLabDebugDraw.Create(const ADevice: TLabDeviceShared);
begin
  inherited Create;
  _Device := ADevice;
  _CurVertex := 0;
  _FlushedVertices := 0;
  _UniformBuffer := TLabUniformBuffer.Create(
    _Device, SizeOf(Transforms), TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  );
  _UniformBuffer.Map(PVkVoid(_UniformBufferMap));
  _UniformBufferMap^.World.SetIdentity;
  _UniformBufferMap^.View.SetIdentity;
  _UniformBufferMap^.Projection.SetIdentity;
  _UniformBufferMap^.WVP.SetIdentity;
  _Shader := TLabSceneShaderFactory.MakeShader(
    _Device.Ptr,
    [
      LabColladaVertexAttribute(as_position),
      LabColladaVertexAttribute(as_color)
    ],
    [
      LabSceneShaderParameterUniform(
        _UniformBuffer.VkHandle, TVkFlags(VK_SHADER_STAGE_VERTEX_BIT)
      )
    ]
  );
  _PipelineLayout := TLabPipelineLayout.Create(_Device, [], [_Shader.DescriptorSetLayout]);
end;

destructor TLabDebugDraw.Destroy;
begin
  _PipelineLayout.Free;
  _Shader.Free;
  if Assigned(_VertexBuffer) then
  begin
    _VertexBuffer.Unmap;
    _VertexBuffer.Free;
  end;
  _UniformBuffer.Unmap;
  _UniformBuffer.Free;
  inherited Destroy;
end;

procedure TLabDebugDraw.DrawTransform(const xf: TLabMat);
  var ax, ay, az, p: TLabVec3;
  var cx, cy, cz: TLabVec4;
begin
  cx := LabVec4(1, 0, 0, 1);
  cy := LabVec4(0, 1, 0, 1);
  cz := LabVec4(0, 0, 1, 1);
  ax := xf.AxisX;
  ay := xf.AxisY;
  az := xf.AxisZ;
  p := xf.Translation;
  AddLine(p, p + ax, cx, cx);
  AddLine(p, p + ay, cy, cy);
  AddLine(p, p + az, cz, cz);
end;

procedure TLabDebugDraw.Flush;
  var s: TVkDeviceSize;
begin
  s := SizeOf(TVertex) * _CurVertex;
  if s = 0 then Exit;
  if not Assigned(_VertexBuffer)
  or (_VertexBuffer.Size < s) then
  begin
    if Assigned(_VertexBuffer) then
    begin
      _VertexBuffer.Unmap;
      _VertexBuffer.Free;
    end;
    _VertexBuffer := TLabVertexBuffer.Create(
      _Device, s, SizeOf(TVertex),
      [
        LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, 0),
        LabVertexBufferAttributeFormat(VK_FORMAT_R32G32B32A32_SFLOAT, 16)
      ],
      TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT), TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
    );
    _VertexBuffer.Map(PVkVoid(_VertexBufferMap), 0, _VertexBuffer.Size);
  end;
  Move(_Vertices[0], _VertexBufferMap^, s);
  _VertexBuffer.FlushMappedMemoryRanges([LabMappedMemoryRange(_VertexBuffer.Memory, 0, s)]);
  _UniformBuffer.FlushMappedMemoryRanges(LabMappedMemoryRange(_UniformBuffer.Memory, 0, _UniformBuffer.Size));
  _FlushedVertices := _CurVertex;
  _CurVertex := 0;
end;

procedure TLabDebugDraw.Draw(
  const Cmd: TLabCommandBuffer;
  const PipelineCache: TLabPipelineCache;
  const RenderPass: TLabRenderPass;
  const Viewport: TVkViewport;
  const SampleCount: TVkSampleCountFlagBits = VK_SAMPLE_COUNT_1_BIT
);
begin
  if not Assigned(_VertexBuffer) then Exit;
  _Pipeline := TLabGraphicsPipeline.FindOrCreate(
    _Device, PipelineCache, _PipelineLayout,
    [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR],
    [_Shader.VertexShader.Ptr.Shader, _Shader.PixelShader.Ptr.Shader],
    RenderPass, 0,
    LabPipelineViewportState(),
    LabPipelineInputAssemblyState(
      VK_PRIMITIVE_TOPOLOGY_LINE_LIST
    ),
    LabPipelineVertexInputState(
      [_VertexBuffer.MakeBindingDesc(0)],
      _VertexBuffer.MakeAttributeDescArr(0, 0)
    ),
    LabPipelineRasterizationState(
      VK_FALSE, VK_FALSE,
      VK_POLYGON_MODE_FILL,
      TVkFlags(VK_CULL_MODE_BACK_BIT),
      VK_FRONT_FACE_CLOCKWISE
    ),
    LabPipelineDepthStencilState(
      LabDefaultStencilOpState,
      LabDefaultStencilOpState,
      VK_FALSE, VK_FALSE
    ),
    LabPipelineMultisampleState(SampleCount),
    LabPipelineColorBlendState(1, @LabDefaultColorBlendAttachment, [])
  );
  Cmd.BindPipeline(_Pipeline.Ptr);
  Cmd.SetViewport([Viewport]);
  Cmd.SetScissor([LabRect2D(Round(Viewport.x), Round(Viewport.y), Round(Viewport.width), Round(Viewport.height))]);
  Cmd.BindDescriptorSets(
    VK_PIPELINE_BIND_POINT_GRAPHICS,
    _PipelineLayout,
    0, 1, _Shader.DescriptorSets.Ptr, []
  );
  Cmd.BindVertexBuffers(0, [_VertexBuffer.VkHandle], [0]);
  Cmd.Draw(_FlushedVertices);
end;

end.
