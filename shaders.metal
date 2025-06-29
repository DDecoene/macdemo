// [
//  project_bundle_2025-06-29_21-26-54-722.txt:
//  shaders.metal
// ]
#include <metal_stdlib>
using namespace metal;

// Uniforms struct to pass data from CPU to GPU
// MODIFIED: Added resolution to match the C struct
struct Uniforms {
    float time;
    int currentScene;
    float2 resolution;
};

// Vertex shader: Positions the geometry.
vertex float4 vertex_main(uint vid [[vertex_id]]) {
    float4 positions[] = {
        { -1, -1, 0, 1 },
        {  3, -1, 0, 1 },
        { -1,  3, 0, 1 }
    };
    return positions[vid];
}

// Fragment shader for Scene 1: Plasma Effect
fragment half4 fragment_main(float4 pos [[position]],
                             constant Uniforms &uniforms [[buffer(0)]]) {
    
    if (uniforms.currentScene != 0) {
        return half4(0.0, 0.0, 0.0, 1.0);
    }

    // MODIFIED: Use resolution from uniforms
    float2 uv = pos.xy / uniforms.resolution;
    float time = uniforms.time;

    // --- Plasma Layer 1 ---
    float v1_l1 = sin(uv.x * 10.0 + time);
    float v2_l1 = sin((uv.y * 10.0 + sin(time * 0.5)) + time);
    float v3_l1 = sin((uv.x + uv.y) * 5.0 + time * 2.0);
    float plasma1 = (v1_l1 + v2_l1 + v3_l1) / 3.0;

    // --- Plasma Layer 2 ---
    float v1_l2 = cos(uv.x * 12.0 + time * 0.8);
    float v2_l2 = cos((uv.y * 8.0 + cos(time * 0.6)) + time * 1.2);
    float v3_l2 = cos((uv.x + uv.y) * 4.0 + time * 1.5);
    float plasma2 = (v1_l2 + v2_l2 + v3_l2) / 3.0;

    // --- Blending ---
    float blended_plasma = (plasma1 + plasma2) / 2.0;
    
    half r = half(sin(blended_plasma * 3.14159 * 1.5));
    half g = half(cos(blended_plasma * 3.14159 * 1.2));
    half b = half(sin((blended_plasma + time * 0.3) * 3.14159));

    return half4(r, g, b, 1.0);
}


// Fragment shader for Scene 2: Scrolling Colors
fragment half4 fragment_scene2(float4 pos [[position]],
                                constant Uniforms &uniforms [[buffer(0)]]) {
    
    if (uniforms.currentScene != 1) {
        return half4(0.0, 0.0, 0.0, 1.0);
    }

    // MODIFIED: Use resolution from uniforms
    float2 uv = pos.xy / uniforms.resolution;
    float time = uniforms.time;

    half r = half(sin(uv.x * 5.0 + time * 0.5) * 0.5 + 0.5);
    half g = half(sin(uv.y * 7.0 + time * 0.3) * 0.5 + 0.5);
    half b = half(cos((uv.x + uv.y) * 3.0 + time * 0.7) * 0.5 + 0.5);

    return half4(r, g, b, 1.0);
}

// Fragment shader for Scene 3: Circle Moire Effect
fragment half4 fragment_scene3_moire(float4 pos [[position]],
                                      constant Uniforms &uniforms [[buffer(0)]]) {
    if (uniforms.currentScene != 2) {
        return half4(0.0, 0.0, 0.0, 1.0);
    }
    
    float time = uniforms.time;
    
    // MODIFIED: Use resolution from uniforms for aspect-correct coordinates
    float2 p = (2.0 * pos.xy - uniforms.resolution) / uniforms.resolution.y;
    
    // --- Pattern 1 ---
    float2 center1 = float2(sin(time * 0.4), cos(time * 0.4));
    float dist1 = length(p - center1);
    float rings1 = sin(dist1 * 25.0 - time * 6.0);
    
    // --- Pattern 2 ---
    float2 center2 = float2(sin(time * -0.6) * 1.2, cos(time * 0.5) * 1.2);
    float dist2 = length(p - center2);
    float rings2 = sin(dist2 * 20.0 - time * 8.0);
    
    // --- Combine Patterns ---
    float combined = rings1 + rings2;
    
    // --- Colorization ---
    half r = half(0.5 + 0.5 * sin(combined * 3.14159));
    half g = half(0.5 + 0.5 * cos(combined * 3.14159 + time));
    half b = half(0.5 + 0.5 * sin(combined * 3.14159 * 0.8 - time));

    return half4(r, g, b, 1.0);
}