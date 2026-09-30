shader_type canvas_item;

//uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
//uniform float outline_size = 1.0;
//
//void fragment() {
	//vec4 color = texture(TEXTURE, UV);
//
	//float alpha = color.a;
//
	//float left = texture(TEXTURE, UV + vec2(-outline_size * TEXTURE_PIXEL_SIZE.x, 0.0)).a;
	//float right = texture(TEXTURE, UV + vec2(outline_size * TEXTURE_PIXEL_SIZE.x, 0.0)).a;
	//float up = texture(TEXTURE, UV + vec2(0.0, -outline_size * TEXTURE_PIXEL_SIZE.y)).a;
	//float down = texture(TEXTURE, UV + vec2(0.0, outline_size * TEXTURE_PIXEL_SIZE.y)).a;
//
	//float surrounding_alpha = max(max(left, right), max(up, down));
//
	//if (alpha == 0.0 && surrounding_alpha > 0.0) {
		//COLOR = outline_color;
	//} else {
		//COLOR = color;
	//}
//}