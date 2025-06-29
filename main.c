// [
//  project_bundle_2025-06-29_21-26-54-722.txt:
//  main.c
// ]
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

extern id<MTLDevice> MTLCreateSystemDefaultDevice(void);
extern void start_app(void);

// Global Metal objects
id<MTLDevice> device;
id<MTLCommandQueue> commandQueue;
id<MTLRenderPipelineState> pipelineState;
id<MTLLibrary> defaultLibrary;

// Enum to define our different scenes
typedef enum {
    SCENE_PLASMA = 0,
    SCENE_SCROLLING_COLORS = 1,
    SCENE_MOIRE_CIRCLES = 2 // ADDED: New scene type
} SceneType;

// Structure to hold uniform data passed to the GPU shaders.
typedef struct {
    float time;
    SceneType currentScene; // Add scene type to uniforms
} Uniforms;

struct timespec startTime;

// Function to set up Metal pipeline for a specific shader
void setup_pipeline(SceneType scene) {
    NSError *error = nil;
    id<MTLFunction> vertexProgram = nil;
    id<MTLFunction> fragmentProgram = nil;
    MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm;

    // Load the appropriate shader function based on the scene
    if (scene == SCENE_PLASMA) {
        vertexProgram = [defaultLibrary newFunctionWithName:@"vertex_main"];
        fragmentProgram = [defaultLibrary newFunctionWithName:@"fragment_main"];
    } else if (scene == SCENE_SCROLLING_COLORS) {
        vertexProgram = [defaultLibrary newFunctionWithName:@"vertex_main"];
        fragmentProgram = [defaultLibrary newFunctionWithName:@"fragment_scene2"];
    } else if (scene == SCENE_MOIRE_CIRCLES) { // ADDED: Pipeline setup for the new scene
        vertexProgram = [defaultLibrary newFunctionWithName:@"vertex_main"];
        fragmentProgram = [defaultLibrary newFunctionWithName:@"fragment_scene3_moire"];
    } else {
        printf("Error: Unknown scene type %d\n", scene);
        exit(1);
    }

    if (!vertexProgram || !fragmentProgram) {
        printf("Failed to find vertex or fragment shader functions for scene %d.\n", scene);
        exit(1);
    }

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat;

    pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!pipelineState) {
        printf("Failed to create pipeline state for scene %d: %s\n", scene, [[error localizedDescription] UTF8String]);
        exit(1);
    }
}


void setup_metal() {
    device = MTLCreateSystemDefaultDevice();
    if (!device) {
        printf("Metal is not supported on this device.\n");
        exit(1);
    }

    commandQueue = [device newCommandQueue];
    if (!commandQueue) {
        printf("Failed to create command queue.\n");
        exit(1);
    }

    NSError *error = nil;
    defaultLibrary = [device newDefaultLibrary];
    if (!defaultLibrary) {
        printf("Failed to load default library. Ensure shaders.metal is compiled or available.\n");
        exit(1);
    }
    
    // Initialize with the first scene
    setup_pipeline(SCENE_PLASMA);

    clock_gettime(CLOCK_MONOTONIC, &startTime);
}

// Store the current scene state
SceneType currentScene = SCENE_PLASMA;
// MODIFIED: Define transition times
const float TIME_FOR_SCENE_2 = 10.0; // seconds
const float TIME_FOR_SCENE_3 = 20.0; // seconds

void frame_callback(void* layer) {
    CAMetalLayer *metalLayer = (__bridge CAMetalLayer*)layer;
    
    struct timespec currentTime;
    clock_gettime(CLOCK_MONOTONIC, &currentTime);
    
    float elapsedTime = (currentTime.tv_sec - startTime.tv_sec) + (currentTime.tv_nsec - startTime.tv_nsec) / 1e9f;

    // --- MODIFIED: Scene Management ---
    // This logic now supports transitioning through all three scenes.
    if (currentScene == SCENE_PLASMA && elapsedTime >= TIME_FOR_SCENE_2) {
        currentScene = SCENE_SCROLLING_COLORS;
        // Reconfigure the pipeline for the new scene's shader
        setup_pipeline(currentScene);
        printf("Transitioning to Scene 2: Scrolling Colors\n");
    } else if (currentScene == SCENE_SCROLLING_COLORS && elapsedTime >= TIME_FOR_SCENE_3) {
        currentScene = SCENE_MOIRE_CIRCLES;
        // Reconfigure the pipeline for the final scene
        setup_pipeline(currentScene);
        printf("Transitioning to Scene 3: Circle Moire\n");
    }

    // Prepare uniform data
    Uniforms uniforms;
    uniforms.time = elapsedTime;
    uniforms.currentScene = currentScene; // Pass current scene to shader

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
    // Fragment shader also needs uniforms to know about the scene
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