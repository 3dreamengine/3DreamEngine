local sh = setmetatable({}, {
	__index = function(_, k)
		return _3DreamEngine.lightShaders["sun_shadow"][k]
	end
})

sh.func = "sampleShadowSunSmoothDynamic"

function sh:constructDefinesGlobal(dream)
	return [[
	float sampleShadowSunSmoothDynamic2(Image tex, vec2 shadowUV, float depth) {
		float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
		float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25) + ox;
		if (oy > 1.1) oy = 0.0;
		float ss_texelSize = 1.0 / love_ScreenSize.x;
		float sharpness = 100.0;
		
		float sampleDepth = texture(tex, shadowUV).x;
		float sh = clamp(exp(sharpness * (sampleDepth - depth)), 0.0, 1.0);
		
		float r0 = texture(tex, shadowUV + vec2(-1.5 + ox, 0.5 + oy) * ss_texelSize).y;
		float r1 = texture(tex, shadowUV + vec2(0.5 + ox, 0.5 + oy) * ss_texelSize).y;
		float r2 = texture(tex, shadowUV + vec2(-1.5 + ox, -1.5 + oy) * ss_texelSize).y;
		float r3 = texture(tex, shadowUV + vec2(0.5 + ox, -1.5 + oy) * ss_texelSize).y;
		
		return sh * (
			(r0 > depth ? 0.25 : 0.0) +
			(r1 > depth ? 0.25 : 0.0) +
			(r2 > depth ? 0.25 : 0.0) +
			(r3 > depth ? 0.25 : 0.0)
		);
	}
	]] .. self:constructDefinesGlobalCommon(dream)
end

return sh