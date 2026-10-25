shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur : hint_range(0.0, 5.0) = 0.5;
uniform float darken : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec3 col = textureLod(screen_tex, SCREEN_UV, blur).rgb;
	COLOR = vec4(col * (1.0 - darken), 1.0);
}