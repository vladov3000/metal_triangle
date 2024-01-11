#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <Quartz/Quartz.h>

typedef struct {
  float x, y, z;
} Vector3;

typedef struct {
  Vector3 position;
  Vector3 color;
} Vertex;

Vertex vertices[] = {
  {    0,      1, 0, 1, 0, 0 },
  {  0.71, -0.71, 0, 0, 1, 0 },
  { -0.71, -0.71, 0, 0, 0, 1 },
};

int main() {
  NSError* error;

  NSRect window_rect = [[NSScreen mainScreen] frame];

  NSUInteger window_style
    = NSWindowStyleMaskTitled
    | NSWindowStyleMaskClosable
    | NSWindowStyleMaskResizable
    | NSWindowStyleMaskMiniaturizable;

  NSWindow* window = [[NSWindow alloc] initWithContentRect:window_rect
						 styleMask:window_style
						   backing:NSBackingStoreBuffered
						     defer:NO];

  window.title = @"Triangle";
  [window makeKeyAndOrderFront:nil];

  NSApplication* app = [NSApplication sharedApplication];
  [app setActivationPolicy:NSApplicationActivationPolicyRegular];
  [app activateIgnoringOtherApps:YES];
  [app finishLaunching];

  NSDate*       distant_past = [NSDate distantPast];
  id<MTLDevice> device       = MTLCreateSystemDefaultDevice();
  
  CAMetalLayer* layer = [CAMetalLayer layer];
  layer.device        = device;
  layer.pixelFormat   = MTLPixelFormatBGRA8Unorm;

  NSView* view       = [NSView new];
  view.wantsLayer    = YES;
  view.layer         = layer;
  window.contentView = view;

  MTLVertexDescriptor* vertex      = [MTLVertexDescriptor new];
  vertex.attributes[0].format      = MTLVertexFormatFloat3;
  vertex.attributes[0].offset      = offsetof(Vertex, position);
  vertex.attributes[0].bufferIndex = 0;
  vertex.attributes[1].format      = MTLVertexFormatFloat3;
  vertex.attributes[1].offset      = offsetof(Vertex, color);
  vertex.attributes[1].bufferIndex = 0;
  vertex.layouts[0].stride         = sizeof(Vertex);

  MTLRenderPipelineDescriptor* pipeline    = [MTLRenderPipelineDescriptor new];
  id<MTLLibrary>               library     = [device newDefaultLibrary];
  pipeline.vertexFunction                  = [library newFunctionWithName:@"vertex_shader"];
  pipeline.fragmentFunction                = [library newFunctionWithName:@"fragment_shader"];
  pipeline.vertexDescriptor                = vertex;
  pipeline.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
  
  id<MTLRenderPipelineState> pipeline_state = [device newRenderPipelineStateWithDescriptor:pipeline
										      error:&error];
  if (error != nil) {
    NSLog(@"%@", error);
  }
  
  id<MTLCommandQueue> command_queue = [device newCommandQueue];

  id<MTLBuffer> vertex_buffer = [device newBufferWithBytes:vertices
						    length:sizeof(vertices)
						   options:0];
  
  while (true) {
    while (true) {
      NSEvent* event = [app nextEventMatchingMask:NSEventMaskAny
					untilDate:distant_past
					   inMode:NSDefaultRunLoopMode
					  dequeue:YES];
      if (event == nil)
	break;
      
      switch (event.type) {

      case NSEventTypeKeyDown:
	if (event.keyCode == 53)
	  exit(EXIT_SUCCESS);

      default:
	[app sendEvent:event];
	break;
      }
      [app updateWindows];
    }

    id<CAMetalDrawable> drawable   = [layer nextDrawable];
    if (drawable == nil)
      continue;

    MTLRenderPassDescriptor* pass        = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture     = drawable.texture;
    pass.colorAttachments[0].loadAction  = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor  = MTLClearColorMake(0, 0, 0, 1);
    id<MTLCommandBuffer> command_buffer  = [command_queue commandBuffer];
    id<MTLRenderCommandEncoder> encoder  = [command_buffer renderCommandEncoderWithDescriptor:pass];
    [encoder setRenderPipelineState:pipeline_state];
    [encoder setVertexBuffer:vertex_buffer offset:0 atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [encoder endEncoding];
    [command_buffer presentDrawable:drawable];
    [command_buffer commit];
    [layer display];
  }
}
