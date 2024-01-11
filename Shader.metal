typedef struct {
  float3 position [[attribute(0)]];
  float3 color    [[attribute(1)]]; 
} Vertex;

typedef struct {
  float4 position [[position]];
  float4 color;
} Fragment;

vertex Fragment vertex_shader(Vertex v [[stage_in]]) {
  return (Fragment) {
    .position = float4(v.position, 1),
    .color    = float4(v.color,    1),
  };
}

fragment float4 fragment_shader(Fragment f [[stage_in]]) {
  return f.color;
}
