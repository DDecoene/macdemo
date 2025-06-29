#include <stdio.h>
#include <stdlib.h>
#include <time.h> // For clock_gettime

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h> // For CAMetalLayer and related types

// Forward declarations for the Objective-C functions we use.
// This allows the C compiler to know they exist before they are defined.
extern id<MTLDevice> MTLCreateSystemDefaultDevice(void);
extern void start_app(void);

// Global Metal objects that will be used across different functions.
id<MTLDevice> device;
id<MTLCommandQueue> commandQueue;
id<MTLRenderPipelineState> pipelineState;
id<MTLLibrary> defaultLibrary;

// Structure to hold uniform data passed to the GPU shaders.
// In this case, just the time for animation.
typedef struct {
    float time;
} Uniforms;

// To measure elapsed time.
struct timespec startTime;

// Function to initialize Metal, create pipeline state, and start the timer.
void setup_metal() {
    // Get the default Metal device (your GPU).
    device = MTLCreateSystemDefaultDevice();
    if (!device) {
        printf("Metal is not supported on this device.\n");
        exit(1);
    }

    // Create a command queue for submitting drawing commands.
    commandQueue = [device newCommandQueue];
    if (!commandQueue) {
        printf("Failed to create command queue.\n");
        exit(1);
    }

    // Load the Metal shader library (shaders.metal).
    NSError *error = nil;
    // newDefaultLibrary searches for a library compiled from any .metal files in the project.
    defaultLibrary = [device newDefaultLibrary];
    if (!defaultLibrary) {
        printf("Failed to load default library. Ensure shaders.metal is compiled or available.\n");
        exit(1);
    }

    // Get the vertex and fragment shader functions from the library.
    id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"fragment_main"];

    if (!vertexProgram || !fragmentProgram) {
        printf("Failed to find vertex or fragment shader functions.\n");
        exit(1);
    }

    // Configure the render pipeline descriptor.
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    // Set the pixel format for the color output. BGRA8Unorm is common for display.
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

    // Create the render pipeline state object. This is compiled and optimized by Metal.
    pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!pipelineState) {
        printf("Failed to create pipeline state: %s\n", [[error localizedDescription] UTF8String]);
        exit(1);
    }

    // Record the start time for animation.
    clock_gettime(CLOCK_MONOTONIC, &startTime);
}

// This function is called by the MetalKit view's delegate for every frame.
// It handles the drawing logic.
void frame_callback(void* layer) {
    // Cast the generic void pointer back to our Metal Layer.
    CAMetalLayer *metalLayer = (__bridge CAMetalLayer*)layer;
    
    // Calculate elapsed time since the application started.
    struct timespec currentTime;
    // --- THIS IS THE CORRECTED LINE (should be ¤tTime, not ¤tTime) ---
    clock_gettime(CLOCK_MONOTONIC, &currentTime);
    // --- END OF CORRECTION ---
    
    float elapsedTime = (currentTime.tv_sec - startTime.tv_sec) + (currentTime.tv_nsec - startTime.tv_nsec) / 1e9f;

    // Prepare the uniform data to send to the shaders.
    Uniforms uniforms;
    uniforms.time = elapsedTime;

    // Get the next available drawable texture from the Metal layer.
    id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
    if (!drawable) return; // If no drawable is available, skip this frame.

    // Create a render pass descriptor. This describes how the rendering will happen.
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    // Set the texture to render into.
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    // Specify that the color attachment should be cleared at the start of the pass.
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    // Set the clear color to black.
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    
    // Create a command buffer to hold our drawing commands.
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    
    // Create a render command encoder to issue drawing commands.
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    // Set the render pipeline state we created earlier.
    [renderEncoder setRenderPipelineState:pipelineState];
    // Send the uniforms data to the vertex and fragment shaders.
    // We send it twice, once for vertex and once for fragment stage, at buffer index 0.
    [renderEncoder setVertexBytes:&uniforms length:sizeof(uniforms) atIndex:0];
    [renderEncoder setFragmentBytes:&uniforms length:sizeof(uniforms) atIndex:0];
    
    // Issue the draw command. We're drawing a single triangle that covers the whole screen.
    // MTLPrimitiveTypeTriangle: We're drawing triangles.
    // vertexStart: 0 (start from the first vertex).
    // vertexCount: 3 (a triangle has 3 vertices).
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    
    // End the render command encoder.
    [renderEncoder endEncoding];
    
    // Present the drawable to the screen after all commands are complete.
    [commandBuffer presentDrawable:drawable];
    
    // Commit the command buffer to the GPU for execution.
    [commandBuffer commit];
}

// The main entry point of our C program.
int main(int argc, const char * argv[]) {
    // Initialize Metal resources.
    setup_metal();
    // Start the macOS application event loop and windowing system.
    // This function will eventually call frame_callback for drawing.
    start_app();
    return 0; // Program exits when start_app() returns (window is closed).
}