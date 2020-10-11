varying vec3 vertexPos;
varying vec3 cloudsVec;
varying vec3 starsVec;
const float brightness = 1.5;

extern vec3 sunColor;
extern float cloudsBrightness;

extern CubeImage clouds;
extern mat3 cloudsTransform;

extern CubeImage stars;
extern float starsStrength;
extern mat3 starsTransform;

extern Image rainbow;
extern float rainbowStrength;
extern float rainbowSize;
extern float rainbowThickness;
extern vec3 rainbowDir;

#ifdef PIXEL
extern float time;

vec4 effect(vec4 ambient, Image sky, vec2 tc, vec2 sc) {
	vec3 dir = normalize(vertexPos);
	vec3 col = Texel(sky, vec2(time, 0.5-dir.y*0.5)).rgb * ambient.rgb * brightness;
	
	//stars
	if (starsStrength > 0.0) {
		vec3 starsColor = Texel(stars, starsVec.xzy).rgb;
		starsColor.rgb = vec3(1.0) - exp(-starsColor.rgb * starsStrength);
		col += starsColor;
	}
	
	//rainbow
	if (rainbowStrength > 0.0) {
		float rainbowFrequency = (rainbowSize - dot(dir, rainbowDir)) * rainbowThickness;
		
		if (rainbowFrequency > 0.0 && rainbowFrequency < 1.0) {
			float brightness = clamp(dir.y * 5.0, 0.0, 1.0);
			col += Texel(rainbow, vec2(rainbowFrequency, 0.0)).rgb * brightness * rainbowStrength;
		}
	}
	
	//clouds
	float c = Texel(clouds, normalize(cloudsVec).xzy).r * cloudsBrightness;
	col = mix(col, sunColor, c);
	
	return vec4(col, 1.0);
}
#endif

#ifdef VERTEX
extern highp mat4 transformProj;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vertexPos = vertex_position.xyz;
	cloudsVec = cloudsTransform * vertex_position.xyz;
	starsVec = starsTransform * vertex_position.xyz;
	return transformProj * vec4(vertex_position.xyz, 1.0);
}
#endif