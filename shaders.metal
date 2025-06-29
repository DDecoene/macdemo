#include <metal_stdlib>
using namespace metal;

// Uniforms struct to pass data from CPU to GPU
struct Uniforms {
    float time;
    // We can add more uniforms later for control, like blending factors or speeds
};

// Vertex shader: Positions the geometry.
// For a full-screen effect, we just draw a triangle that covers the viewport.
vertex float4 vertex_main(uint vid [[vertex_id]]) {
    // The positions are defined to cover the NDC (Normalized Device Coordinates) range [-1, 1]
    // Our fragment shader will then map these to screen pixels.
    float4 positions[] = {
        { -1, -1, 0, 1 }, // Bottom-left
        {  3, -1, 0, 1 }, // Extra point to cover the whole screen easily
        { -1,  3, 0, 1 }  // Extra point to cover the whole screen easily
    };
    return positions[vid];
}

// Fragment shader: Runs for every pixel and determines its color.
// This is where our layered plasma effect will be calculated.
fragment half4 fragment_main(float4 pos [[position]], // The clip-space position of the pixel
                             constant Uniforms &uniforms [[buffer(0)]]) { // Our uniform data buffer
    
    // Normalize the pixel coordinates to a UV range of [0, 1] across the screen.
    // We use the screen dimensions from the shader, which are fixed for now (800x600).
    // For a truly dynamic resolution, we'd need to pass screen dimensions as uniforms.
    float2 uv = pos.xy / float2(800.0, 600.0);
    float time = uniforms.time;

    // --- Plasma Layer 1 ---
    // Classic plasma effect based on UV and time.
    float v1_l1 = sin(uv.x * 10.0 + time);
    float v2_l1 = sin((uv.y * 10.0 + sin(time * 0.5)) + time);
    float v3_l1 = sin((uv.x + uv.y) * 5.0 + time * 2.0);
    float plasma1 = (v1_l1 + v2_l1 + v3_l1) / 3.0; // Average the three values

    // --- Plasma Layer 2 ---
    // A slightly different calculation for the second layer.
    // Different frequencies (multipliers) and offsets to make it distinct.
    float v1_l2 = cos(uv.x * 12.0 + time * 0.8); // Using cos, different frequency, slightly slower time factor
    float v2_l2 = cos((uv.y * 8.0 + cos(time * 0.6)) + time * 1.2); // Using cos, different frequencies and time factors
    float v3_l2 = cos((uv.x + uv.y) * 4.0 + time * 1.5); // Using cos, different frequencies
    float plasma2 = (v1_l2 + v2_l2 + v3_l2) / 3.0; // Average the three values

    // --- Blending ---
    // We can blend the two layers. For simplicity, let's use a simple average.
    // More advanced blending could use an alpha value, or a more complex mix.
    float blended_plasma = (plasma1 + plasma2) / 2.0;

    // Convert the blended plasma value (which is roughly in [-1, 1]) to RGB colors.
    // We map the plasma value to trigonometric functions to create colors.
    // sin(PI * value) maps [-1, 1] to [-1, 1] and then we shift/scale to [0, 1].
    // The result of sin/cos is usually in [-1, 1]. Adding 1 and dividing by 2 gives [0, 1].
    // However, our plasma values are already somewhat mapped to trig functions implicitly by the input.
    // A simpler mapping from [-1, 1] to color components [0, 1] is (value + 1) / 2.
    // Let's use a simpler mapping for now: map plasma to color components directly.
    // Our plasma values are roughly in the [-1,1] range.
    // We can use sin/cos again on the plasma value to get a smooth color transition.
    
    half r = half(sin(blended_plasma * 3.14159 * 1.5)); // More pronounced color range
    half g = half(cos(blended_plasma * 3.14159 * 1.2)); // Slightly different phase
    half b = half(sin((blended_plasma + time * 0.3) * 3.14159)); // Adding time to color offsets it

    // Return the final color (RGBA).
    return half4(r, g, b, 1.0);
}