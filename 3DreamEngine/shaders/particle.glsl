#ifdef PIXEL
uniform Image MainTex;
extern float emission;
extern Image tex_emission;

void effect() {
	love_Canvases[0] = Texel(MainTex, VaryingTexCoord.xy) * VaryingColor;
#ifdef BLOOM_ENABLED
	love_Canvases[1] = Texel(tex_emission, VaryingTexCoord.xy) * emission;
#endif
}
#endif

#ifdef VERTEX
extern float depth;
extern mat4 cam;
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	return vec4((transform_projection * vertex_position).xy, depth, 1.0);
}
#endif