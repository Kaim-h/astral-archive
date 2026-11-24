// Original Astral Archive shader: pixel-colony reveal or outline-first reveal.
// Inspired by the *technique* in Diego Malagrida's pocket-dots (GPL-3.0),
// independently implemented with a procedural colony front and optional
// locally generated subject-distance map. No upstream shader code copied.
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float mode;
    float screenWidth;
    float screenHeight;
    float seed;
    vec4 cropOld;
    vec4 cropNew;
    vec4 accent;
    vec4 ink;
};
layout(binding = 1) uniform sampler2D oldTexture;
layout(binding = 2) uniform sampler2D newTexture;
layout(binding = 3) uniform sampler2D subjectTexture;

float randomValue(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed * 0.021) * 43758.5453);
}
float smoothCurve(float v) { v = clamp(v, 0.0, 1.0); return v*v*(3.0-2.0*v); }

// Each 4 px cell belongs to the earliest of several expanding colonies;
// the arrival time is stable per cell while the transition is playing.
float colonyArrival(vec2 uv) {
    vec2 dims = vec2(max(screenWidth, 1.0), max(screenHeight, 1.0));
    vec2 cell = floor(uv * dims / 4.0);
    vec2 cuv = (cell + 0.5) * 4.0 / dims;
    float closest = 2.0;
    for (int i = 0; i < 8; i++) {
        float k = float(i);
        vec2 origin = vec2(randomValue(vec2(k + 1.0, 23.0)),
                           randomValue(vec2(k + 7.0, 87.0)));
        vec2 delta = (cuv - origin) * vec2(dims.x / dims.y, 1.0);
        float dist = length(delta);
        float arrival = 0.04 + randomValue(vec2(k, 71.0))*0.22
                        + dist * (0.44 + randomValue(vec2(58.0, k))*0.19);
        closest = min(closest, arrival);
    }
    float irregular = (randomValue(cell) - 0.5) * 0.09;
    return clamp(closest + irregular, 0.01, 0.985);
}
void main() {
    vec2 uv = qt_TexCoord0;
    vec2 oldUv = cropOld.xy + uv * cropOld.zw;
    vec2 nextUv = cropNew.xy + uv * cropNew.zw;
    vec3 before = texture(oldTexture, oldUv).rgb;
    vec3 after = texture(newTexture, nextUv).rgb;
    float p = clamp(progress, 0.0, 1.0);
    float arrival = colonyArrival(uv);
    float tracedLine = 0.0;

    if (mode > 0.5) {
        // Map: R is signed distance (0.5 = contour), G is angle around the
        // mask's centroid, B is subject occupancy. Generated only from local
        // user-supplied or optional rembg masks.
        vec4 field = texture(subjectTexture, nextUv);
        float dist = (field.r - 0.5) * 2.0;
        float outside = clamp(dist, 0.0, 1.0);
        float inside = clamp(-dist, 0.0, 1.0);
        float noise = (randomValue(floor(uv * vec2(screenWidth, screenHeight)/4.0)) - 0.5);
        // First trace the outline, then fill the subject from the border,
        // finally spread from its silhouette through the surrounding world.
        if (field.b > 0.5) arrival = 0.29 + inside * 0.23 + noise * 0.018;
        else arrival = 0.52 + outside * 0.42 + noise * 0.018;
        float lineDistance = abs(field.r - 0.5);
        float thinContour = 1.0 - smoothstep(0.004, 0.016, lineDistance);
        float strokeReveal = step(field.g, clamp(p / 0.28, 0.0, 1.0));
        tracedLine = thinContour * strokeReveal * (1.0 - smoothstep(0.30, 0.52, p));
    }

    float switched = step(arrival, p);
    if (p >= 0.999) switched = 1.0;
    vec3 image = mix(before, after, switched);

    if (mode < 0.5) {
        // Tiny restrained tint at the advancing pixel front, never neon.
        float front = (1.0 - smoothstep(0.0, 0.025, abs(p-arrival)));
        front *= sin(3.14159265 * p) * 0.24;
        image = mix(image, accent.rgb, front);
    } else {
        image = mix(image, ink.rgb, tracedLine * 0.85);
    }
    fragColor = vec4(image, 1.0) * qt_Opacity;
}
