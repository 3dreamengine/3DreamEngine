vec4 gammaCorrectedTexel(Image image, vec2 tc) {
#ifdef GAMMA_CORRECTION
	vec4 c = Texel(image, tc);
	c.rgb = pow(c.rgb, vec3(2.2));
	return c;
#else
	return Texel(image, tc);
#endif
}

vec4 gammaCorrectedTexel(Image image, vec2 tc, float mm) {
#ifdef GAMMA_CORRECTION
	vec4 c = textureLod(image, tc, mm);
	c.rgb = pow(c.rgb, vec3(2.2));
	return c;
#else
	return textureLod(image, tc, mm);
#endif
}

vec4 gammaCorrectedTexel(samplerCube image, vec3 tc, float mm) {
#ifdef GAMMA_CORRECTION
	vec4 c = textureLod(image, tc, mm);
	c.rgb = pow(c.rgb, vec3(2.2));
	return c;
#else
	return textureLod(image, tc, mm);
#endif
}