varying vec3 vertexPos;
varying vec3 starsVec;

uniform CubeImage stars;
uniform float starsStrength;
uniform mat3 starsTransform;

uniform Image rainbow;
uniform float rainbowStrength;
uniform float rainbowSize;
uniform float rainbowThickness;
uniform vec3 rainbowDir;

#ifdef PIXEL
uniform float time;

uniform Image MainTex;

void effect() {
	vec3 dir = normalize(vertexPos);
	vec3 col = Texel(MainTex, vec2(time, 0.5-dir.y*0.5)).rgb * VaryingColor.rgb;
	
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
	
	love_Canvases[0] = vec4(col, 1.0);
	love_Canvases[1] = vec4(65504.0, 0.0, 0.0, 1.0);
}
#endif

#ifdef VERTEX
uniform highp mat4 transformProj;

vec4 position(mat4 transform_projection, vec4 VertexPosition) {
	vertexPos = VertexPosition.xyz;
	starsVec = starsTransform * VertexPosition.xyz;
	return transformProj * vec4(VertexPosition.xyz, 1.0);
}
#endif