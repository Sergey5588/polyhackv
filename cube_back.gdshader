shader_type spatial;

render_mode cull_back, unshaded, depth_draw_always;

uniform bool hide_z = false;
uniform bool hide_x = false;
uniform bool hide_y = false;

uniform vec3 mixColor = vec3(1.0);

void fragment() {

    // Convert normal to world space
    vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

    // Get positive alignment weights for each axis
    float x_weight = max(world_normal.x, 0.0);
    float y_weight = max(world_normal.y, 0.0);
    float z_weight = max(world_normal.z, 0.0);

    // Normalize weights so they blend nicely
    float total = x_weight + y_weight + z_weight + 0.0001;
    x_weight /= total;
    y_weight /= total;
    z_weight /= total;

    // Define axis colors
    vec3 x_color = vec3(0.65);  // right
    vec3 y_color = vec3(1.0);   // top
    vec3 z_color = vec3(0.20);  // left/front

    // Blend colors smoothly
    vec3 color = 
        x_color * x_weight +
        y_color * y_weight +
        z_color * z_weight;

    ALBEDO = color * mixColor;

    // Optional hiding with smooth fade instead of hard cutoff
    float alpha = 1.0;

    if (hide_x) alpha *= 1.0 - x_weight;
    if (hide_y) alpha *= 1.0 - y_weight;
    if (hide_z) alpha *= 1.0 - z_weight;

    ALPHA = alpha;
}