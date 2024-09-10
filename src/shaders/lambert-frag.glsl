#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time; 

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


vec3 random3(vec3 p)
{
    return fract(sin(vec3((dot(p, vec3(127.1f, 311.7f, 191.999f))))) * 43758.5453f);
}

float surflet3D(vec3 p, vec3 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec3 t2 = abs(p - gridPoint);
    vec3 v1 = 6.f * vec3(pow(t2[0], 5.f),
                                    pow(t2[1], 5.f),
                                    pow(t2[2], 5.f));
    vec3 v2 = 15.f * vec3(pow(t2[0], 4.f),
                                    pow(t2[1], 4.f),
                                    pow(t2[2], 4.f));
    vec3 v3 = 10.f * vec3(pow(t2[0], 3.f),
                                    pow(t2[1], 3.f),
                                    pow(t2[2], 3.f));
    vec3 t = vec3(1.f) - v1 + v2 - v3;
    // Get the random vector for the grid point (assume we wrote a function random2
    // that returns a vec2 in the range [0, 1])
    vec3 gradient = random3(gridPoint) * 2.f - vec3(1.f);
    // Get the vector from the grid point to P
    vec3 diff = p - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}

float perlinNoise3D(vec3 p) {
    float surfletSum = 0.f;
    // Iterate over the eight integer corners surrounding a 3D grid cell
    for(int dx = 0; dx <= 1; ++dx) {
        for(int dy = 0; dy <= 1; ++dy) {
            for(int dz = 0; dz <= 1; ++dz) {
                surfletSum += surflet3D(p, floor(p) + vec3(dx, dy, dz));
            }
        }
    }
    return surfletSum;
}


void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        
        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.
        
        
        vec3 addedColor = vec3(0.0, 0.08, 0.1);
        
        // Calculate Perlin noise based on the background color and apply it to the final output
        float noise = perlinNoise3D(addedColor) * u_Time * 0.02;

        // Compute the final shaded color by combining the base color, light intensity, and Perlin noise
        out_Col = vec4(diffuseColor.rgb * lightIntensity + noise + fract(mod(333.3, 123132.2)), diffuseColor.a);

        
}