// // #include <flutter/runtime_effect.glsl>

// // uniform vec2 u_resolution;
// // uniform float u_time;

// // out vec4 fragColor;

// // float random(vec2 st) {
// //     return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
// // }

// // void main() {
// //     // Get exact pixel coordinates
// //     vec2 fragCoord = FlutterFragCoord().xy;
    
// //     // Normalize coordinates
// //     vec2 uv = fragCoord / u_resolution;
    
// //     // Animate the noise using our u_time uniform
// //     vec2 noiseCoord = uv + vec2(u_time * 10.0, u_time * 13.0);
    
// //     // Generate the raw noise value (0.0 to 1.0)
// //     float noise = random(noiseCoord);

// //     // Your intensity
// //     float intensity = 0.15; 
    
// //     // Pure black grain (0.0, 0.0, 0.0) 
// //     vec3 grainColor = vec3(0.0); 

// //     // Set transparency based on noise and intensity
// //     float alpha = noise * intensity;

// //     // Output transparent grain. 
// //     // Notice the pre-multiplied alpha: (grainColor * alpha)
// //     fragColor = vec4(grainColor * alpha, alpha);
// // }

// #include <flutter/runtime_effect.glsl>

// uniform vec2 u_resolution;
// uniform float u_time;

// out vec4 fragColor;

// float random(vec2 st) {
//     return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
// }

// void main() {
//     // Get exact pixel coordinates
//     vec2 fragCoord = FlutterFragCoord().xy;
    
//     // NEW: Define the grain size (how chunky you want it in pixels)
//     // 1.0 is default fine grain. 3.0 or 4.0 gives a great coarse film look.
//     float grainSize = 5.0; 
    
//     // Pixelate the coordinates by snapping them into larger blocks
//     vec2 blockCoord = floor(fragCoord / grainSize);
    
//     // Animate the noise based on the rigid block coordinate, not the exact pixel.
//     // We multiply time by a larger number to ensure the blocks change fast enough.
//     vec2 noiseCoord = blockCoord + floor(vec2(u_time * 30.0, u_time * 40.0));
    
//     // Generate the raw noise value (0.0 to 1.0)
//     float noise = random(noiseCoord);

//     // Your intensity
//     float intensity = 0.15; 
    
//     // Pure black grain (0.0, 0.0, 0.0) 
//     vec3 grainColor = vec3(0.0); 

//     // Set transparency based on noise and intensity
//     float alpha = noise * intensity;

//     // Output transparent grain. 
//     // Notice the pre-multiplied alpha: (grainColor * alpha)
//     fragColor = vec4(grainColor * alpha, alpha);
// }

#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;

out vec4 fragColor;

// FIXED: We now pass time directly into the hash function.
// Adding 'time' inside the sin() forces the hash to completely scramble every frame.
float random(vec2 st, float time) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233)) + time) * 43758.5453123);
}

void main() {
    // Get exact pixel coordinates
    vec2 fragCoord = FlutterFragCoord().xy;
    
    // The grain size (how chunky you want it in pixels)
    float grainSize = 4.0; 
    
    // Snap the coordinates into our chunky grid
    vec2 blockCoord = floor(fragCoord / grainSize);
    
    // Generate a completely new random value per frame.
    // We multiply u_time to ensure it scrambles fast enough between frames.
    float noise = random(blockCoord, u_time * 10.0);

    // NEW: The "Peppered" effect.
    // By raising the noise to a power, we make the specks sparser and punchier.
    // Change this to 1.0 for standard static, or up to 4.0 for very sparse specks.
    noise = pow(noise, 3.0);

    // Your intensity
    float intensity = 0.15; 
    
    // Pure black grain (0.0, 0.0, 0.0) 
    vec3 grainColor = vec3(0.0, 1.0, 1.0); 

    // Set transparency based on noise and intensity
    float alpha = noise * intensity;

    // Output transparent grain. 
    fragColor = vec4(grainColor * alpha, alpha);
}