// [
//  project_bundle_2025-06-29_21-26-54-722.txt:
//  shaders.metal
// ]
#include <metal_stdlib>
using namespace metal;

// Uniforms struct to pass data from CPU to GPU
struct Uniforms {
    float time;
    int currentScene; // Use int for scene ID
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
    
    // Only execute this shader logic if it's the plasma scene
    if (uniforms.currentScene != 0) {
        return half4(0.0, 0.0, 0.0, 1.0); // Return black if not plasma scene
    }

    float2 uv = pos.xy / float2(800.0, 600.0);
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
// We'll use a simple gradient that scrolls.
fragment half4 fragment_scene2(float4 pos [[position]],
                                constant Uniforms &uniforms [[buffer(0)]]) {
    
    // Only execute this shader logic if it's the scrolling colors scene
    if (uniforms.currentScene != 1) {
        return half4(0.0, 0.0, 0.0, 1.0); // Return black if not scene 2
    }

    float2 uv = pos.xy / float2(800.0, 600.0);
    float time = uniforms.time;

    // Simple color based on UV coordinates and time for scrolling effect
    // Colors will shift horizontally and vertically based on time
    half r = half(sin(uv.x * 5.0 + time * 0.5) * 0.5 + 0.5); // Red band scrolling horizontally
    half g = half(sin(uv.y * 7.0 + time * 0.3) * 0.5 + 0.5); // Green band scrolling vertically
    half b = half(cos((uv.x + uv.y) * 3.0 + time * 0.7) * 0.5 + 0.5); // Blue band with diagonal movement

    return half4(r, g, b, 1.0);
}

// --- NEW SCENE ---
// Fragment shader for Scene 3: Circle Moire Effect
fragment half4 fragment_scene3_moire(float4 pos [[position]],
                                      constant Uniforms &uniforms [[buffer(0)]]) {
    // Only execute this shader logic if it's the moire scene
    if (uniforms.currentScene != 2) {
        return half4(0.0, 0.0, 0.0, 1.0);
    }
    
    float time = uniforms.time;
    float2 resolution = float2(800.0, 600.0);
    
    // Create aspect-corrected, centered coordinates from -1 to 1 on the shortest axis
    float2 p = (2.0 * pos.xy - resolution) / resolution.y;
    
    // --- Pattern 1 ---
    // Center moves in a circle
    float2 center1 = float2(sin(time * 0.4), cos(time * 0.4));
    float dist1 = length(p - center1);
    float rings1 = sin(dist1 * 25.0 - time * 6.0); // 25.0 = frequency, 6.0 = speed of rings expanding
    
    // --- Pattern 2 ---
    // Center moves in a different, larger circle
    float2 center2 = float2(sin(time * -0.6) * 1.2, cos(time * 0.5) * 1.2);
    float dist2 = length(p - center2);
    float rings2 = sin(dist2 * 20.0 - time * 8.0);
    
    // --- Combine Patterns ---
    // Adding the two sine waves together creates the interference pattern
    float combined = rings1 + rings2;
    
    // --- Colorization ---
    // Use the combined pattern to drive some psychedelic colors
    half r = half(0.5 + 0.5 * sin(combined * 3.14159));
    half g = half(0.5 + 0.5 * cos(combined * 3.14159 + time));
    half b = half(0.5 + 0.5 * sin(combined * 3.14159 * 0.8 - time));

    return half4(r, g, b, 1.0);
}