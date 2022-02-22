local sh = setmetatable({}, {
	__index = function(_, k)
		return _3DreamEngine.lightShaders["sun_shadow"][k]
	end
})

sh.func = "sampleShadowSunSmooth"

function sh:constructDefinesGlobal(dream)
	return [[
	float sampleShadowSunSmooth2(Image tex, vec2 shadowUV, float depth) {
		float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
		float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25) + ox;
		if (oy > 1.1) oy = 0.0;
		float ss_texelSize = 1.0 / love_ScreenSize.x;
		float sharpness = 100.0;
		
		float sampleDepth = texture(tex, shadowUV).x;
		return clamp(exp(sharpness * (sampleDepth - depth)), 0.0, 1.0);
	}
	]] .. self:constructDefinesGlobalCommon(dream)
end

return sh