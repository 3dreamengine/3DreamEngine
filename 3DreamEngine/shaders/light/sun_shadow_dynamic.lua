local sh = setmetatable({}, {
	__index = function(_, k)
		return _3DreamEngine.lightShaders["sun_shadow"][k]
	end
})

sh.func = "sampleShadowSunDynamic"

function sh:constructDefinesGlobal(dream)
	return [[
	float sampleShadowSunDynamic2(Image tex, vec2 shadowUV, float depth) {
		float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
		float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25) + ox;
		if (oy > 1.1) oy = 0.0;
		float ss_texelSize = 1.0 / love_ScreenSize.x;
		
		vec2 r0 = texture(tex, shadowUV + vec2(-1.5 + ox, 0.5 + oy) * ss_texelSize).xy;
		vec2 r1 = texture(tex, shadowUV + vec2(0.5 + ox, 0.5 + oy) * ss_texelSize).xy;
		vec2 r2 = texture(tex, shadowUV + vec2(-1.5 + ox, -1.5 + oy) * ss_texelSize).xy;
		vec2 r3 = texture(tex, shadowUV + vec2(0.5 + ox, -1.5 + oy) * ss_texelSize).xy;
		
		return (
			(min(r0.x, r0.y) > depth ? 0.25 : 0.0) +
			(min(r1.x, r1.y) > depth ? 0.25 : 0.0) +
			(min(r2.x, r2.y) > depth ? 0.25 : 0.0) +
			(min(r3.x, r3.y) > depth ? 0.25 : 0.0)
		);
	}
	]] .. self:constructDefinesGlobalCommon(dream)
end

return sh