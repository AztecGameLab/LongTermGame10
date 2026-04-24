// https://godotshaders.com/shader/desaturation-shader/
shader_type canvas_item;

uniform float saturation = 1.0;

void fragment() {
    COLOR.rgb = mix(vec3(dot(COLOR.rgb, vec3(0.299, 0.587, 0.114))), COLOR.rgb, saturation) * (saturation * 0.75 + 0.25);
}