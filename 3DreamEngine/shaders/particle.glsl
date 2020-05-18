#ifdef PIXEL
uniform Image MainTex;
extern float emission;
extern Image tex_emission;

void effect() {
	love_Canvases[0] = Texel(MainTex, VaryingTexCoord.xy) + Texel(tex_emission, VaryingTexCoord.xy) * emission;
	love_Canvases[0].a = min(1.0, love_Canvases[0].a);
}
#endif

#ifdef VERTEX
extern float depth;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	return vec4((transform_projection * vertex_position).xy, depth, 1.0);
}
#endif