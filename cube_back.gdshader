shader_type spatial;

//render_mode cull_back, unshaded, depth_test_default;
render_mode cull_back, unshaded,depth_draw_opaque;


void fragment() {
    // convert normal to world space
    vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

    // snap normal to closest axis
    vec3 axis = round(world_normal);

    vec3 color;

    // top
    if (axis.y > 0.5) {
        color = vec3(1.0); // white
    }
    // right
    else if (axis.x > 0.5) {
        color = vec3(0.65); // gray
    }
    // left
    else if (axis.z > 0.5) {
        color = vec3(0.20); // dark gray
    }
    // front/back/bottom (optional)
    else {
        color = vec3(0); // medium gray fallback
    }

    ALBEDO = color;
}
//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
