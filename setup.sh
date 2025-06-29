#!/bin/bash

# A script to create the necessary files for a basic C + Metal demo on macOS.
# VERSION 3: Fixes a typo in main.c and a structural error in renderer.m.

# Define some colors for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "Setting up C + Metal demo project (v3)..."
echo ""

# -----------------------------------------------------------------------------
# Create shaders.metal (No changes needed here)
# -----------------------------------------------------------------------------
echo -e "${CYAN}Creating shaders.metal...${NC}"
cat << 'EOF' > shaders.metal
#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float time;
};

vertex float4 vertex_main(uint vid [[vertex_id]]) {
    float4 positions[] = {
        { -1, -1, 0, 1 },
        {  3, -1, 0, 1 },
        { -1,  3, 0, 1 }
    };
    return positions[vid];
}

fragment half4 fragment_main(float4 pos [[position]],
                             constant Uniforms &uniforms [[buffer(0)]]) {
    
    float2 uv = pos.xy / float2(800.0, 600.0);
    float time = uniforms.time;

    float v1 = sin(uv.x * 10.0 + time);
    float v2 = sin((uv.y * 10.0 + sin(time * 0.5)) + time);
    float v3 = sin((uv.x + uv.y) * 5.0 + time * 2.0);
    
    float plasma = (v1 + v2 + v3) / 3.0;

    half r = half(sin(plasma * 3.14159));
    half g = half(cos(plasma * 3.14159));
    half b = half(sin(plasma * 3.14159 + time));

    return half4(r, g, b, 1.0);
}
EOF

# -----------------------------------------------------------------------------
# Create renderer.m (FIXED: Delegate class is now defined at the top level)
# -----------------------------------------------------------------------------
echo -e "${CYAN}Creating renderer.m...${NC}"
cat << 'EOF' > renderer.m
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

// --- FIX: Define the delegate class at the top level, not inside a function ---
@interface MyDelegate : NSObject <MTKViewDelegate>
@end

@implementation MyDelegate
- (void)drawInMTKView:(nonnull MTKView *)view {
    // We need to declare the C function we're going to call here
    extern void frame_callback(void* layer);
    frame_callback((__bridge void*)view.layer);
}
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {}
@end
// --- End of fix ---


// A C-callable function to run the app. We'll call this from main.c
void start_app(void) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    NSMenu *menubar = [NSMenu new];
    NSMenuItem *appMenuItem = [NSMenuItem new];
    [menubar addItem:appMenuItem];
    [NSApp setMainMenu:menubar];

    NSMenu *appMenu = [NSMenu new];
    NSString *appName = [[NSProcessInfo processInfo] processName];
    NSString *quitTitle = [@"Quit " stringByAppendingString:appName];
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle
                                                          action:@selector(terminate:)
                                                   keyEquivalent:@"q"];
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];

    NSRect frame = NSMakeRect(0, 0, 800, 600);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [window center];
    [window setTitle: @"C + Metal Demo"];
    [window makeKeyAndOrderFront:nil];
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    MTKView *view = [[MTKView alloc] initWithFrame:frame device:device];
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    
    view.delegate = [[MyDelegate alloc] init];
    window.contentView = view;

    [NSApp activateIgnoringOtherApps:YES];
    [NSApp run];
}
EOF

# -----------------------------------------------------------------------------
# Create main.c (FIXED: Corrected typo in clock_gettime)
# -----------------------------------------------------------------------------
echo -e "${CYAN}Creating main.c...${NC}"
cat << 'EOF' > main.c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

id<MTLDevice> MTLCreateSystemDefaultDevice(void);
void start_app(void);

id<MTLDevice> device;
id<MTLCommandQueue> commandQueue;
id<MTLRenderPipelineState> pipelineState;
id<MTLLibrary> defaultLibrary;

typedef struct {
    float time;
} Uniforms;

struct timespec startTime;

void setup_metal() {
    device = MTLCreateSystemDefaultDevice();
    commandQueue = [device newCommandQueue];

    NSError *error = nil;
    defaultLibrary = [device newDefaultLibrary];
    if (!defaultLibrary) {
        printf("Failed to load default library. Is shaders.metal in the same directory?\n");
        exit(1);
    }

    id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"fragment_main"];

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

    pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!pipelineState) {
        printf("Failed to create pipeline state: %s\n", [[error localizedDescription] UTF8String]);
        exit(1);
    }

    clock_gettime(CLOCK_MONOTONIC, &startTime);
}

void frame_callback(void* layer) {
    CAMetalLayer *metalLayer = (__bridge CAMetalLayer*)layer;
    
    struct timespec currentTime;
    // --- FIX: Replaced '¤tTime' with '¤tTime' ---
    clock_gettime(CLOCK_MONOTONIC, ¤tTime);
    float elapsedTime = (currentTime.tv_sec - startTime.tv_sec) + (currentTime.tv_nsec - startTime.tv_nsec) / 1e9f;

    Uniforms uniforms;
    uniforms.time = elapsedTime;

    id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
    if (!drawable) return;

    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    [renderEncoder setRenderPipelineState:pipelineState];
    [renderEncoder setVertexBytes:&uniforms length:sizeof(uniforms) atIndex:0];
    [renderEncoder setFragmentBytes:&uniforms length:sizeof(uniforms) atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

int main(int argc, const char * argv[]) {
    setup_metal();
    start_app();
    return 0;
}
EOF

# -----------------------------------------------------------------------------
# Final instructions
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}Project files created successfully!${NC}"
echo ""
echo "The code has been fixed. The compile command remains the same."
echo "To compile the demo, run this command:"
echo -e "${CYAN}clang -x objective-c main.c renderer.m -o mydemo -fobjc-arc -framework Metal -framework MetalKit -framework Cocoa -framework QuartzCore${NC}"
echo ""
echo "Then, to run the compiled program, use:"
echo -e "${CYAN}./mydemo${NC}"
echo ""