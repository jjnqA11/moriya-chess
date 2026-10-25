shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0);
uniform float thickness : hint_range(0.01, 0.5) = 0.1;    // độ dày lõi (tỉ lệ chiều cao)
uniform float glow_width : hint_range(0.02, 0.5) = 0.18;  // độ rộng quầng sáng
uniform float glow_strength : hint_range(0.0, 1.0) = 0.5;
uniform float taper_power : hint_range(0.1, 2.0) = 0.6;   // nhỏ thì nhọn chậm, lớn thì nhọn gắt

void fragment() {
	float taper = pow(sin(UV.x * PI), taper_power);   // 0 ở hai đầu, 1 ở giữa
	float d = abs(UV.y - 0.5);
	float half_t = thickness * 0.5 * taper;
	float core = 1.0 - smoothstep(half_t, half_t + 0.015, d);
	float glow = exp(-(d * d) / (glow_width * glow_width)) * taper * glow_strength;
	COLOR = vec4(line_color.rgb, max(core, glow));
}