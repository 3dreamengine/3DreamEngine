varying float height;

#ifdef PIXEL
uniform Image MainTex;

void effect() {
	float brightness = 4.0 * clamp(height * 10.0, 0.0, 1.0);
	love_Canvases[0] = Texel(MainTex, VaryingTexCoord.xy) * VaryingColor * vec4(brightness, brightness, brightness, 1.0);
	love_Canvases[1] = vec4(0.0, 0.0, 0.0, 0.0);
}
#endif

#ifdef VERTEX
uniform mat4 transformProj;

uniform vec3 InstanceCenter;

uniform vec3 up;
uniform vec3 right;

vec4 position(mat4 transform_projection, vec4 VertexPosition) {
	vec3 vPos = InstanceCenter + (right * VertexPosition.x + up * VertexPosition.y);
	height = vPos.y;
	return transformProj * vec4(vPos, 1.0);
}
#endif