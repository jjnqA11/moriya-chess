shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;

	vec4 blurred = textureLod(screen_texture, uv, 3.0);

	vec3 glass_color = mix(blurred.rgb, vec3(1.0), 0.15);

	COLOR = vec4(glass_color, 0.75);
}