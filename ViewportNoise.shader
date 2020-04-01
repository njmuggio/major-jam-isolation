shader_type canvas_item;

uniform float seed;
uniform float density;
uniform float noise1;
uniform float noise2;
uniform float noise3;

float rand(vec2 coords)
{
	return fract(sin(dot(coords.xy, vec2(noise1, noise2))) * noise3);
}

void fragment()
{
	vec4 c = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgba;

	float _rand = rand(SCREEN_UV);
	if (_rand > seed - density && _rand < seed + density)
	{
		c[0] *= _rand * rand(vec2(seed, SCREEN_UV[1]));
		c[1] *= _rand * rand(vec2(seed, SCREEN_UV[0]));
		c[2] *= _rand * rand(vec2(SCREEN_UV[1], seed));
		c[3] *= density;
	}
	
	COLOR.rgba = c;
}
