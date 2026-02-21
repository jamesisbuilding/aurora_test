#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;

out vec4 fragColor;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    // Get exact pixel coordinates
    vec2 fragCoord = FlutterFragCoord().xy;

    // Normalize coordinates
    vec2 uv = fragCoord / u_resolution;

    // Animate the noise using our u_time uniform
    vec2 noiseCoord = uv + vec2(u_time * 10.0, u_time * 13.0);

    // Generate the raw noise value (0.0 to 1.0)
    float noise = random(noiseCoord);

    // Set your intensity
    float intensity = 0.15; 
    
    // Create a dark background color
    vec3 bgColor = vec3(0.1); 
    
    // Add the scaled noise to the background
    vec3 finalColor = bgColor + (vec3(noise) * intensity);

    // Output the final pixel color (Alpha is 1.0, meaning completely solid)
    fragColor = vec4(finalColor, 1.0);
}