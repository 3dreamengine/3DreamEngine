local sh = setmetatable({}, {
	__index = function(_, k)
		return _3DreamEngine.lightShaders["point_shadow"][k]
	end
})

sh.func = "sampleShadowPointSmooth"

function sh:constructDefinesGlobal(dream)
	return [[
	float sampleShadowPointSmooth(vec3 lightVec, samplerCube tex) {
		float sharpness = 10.0;
		
		float depth = length(lightVec);
		float bias = depth * 0.01 + 0.01;
		
		//direction
		vec3 n = normalize(-lightVec * vec3(1.0, -1.0, 1.0));
		
		//fetch
		float sampleDepth = texture(tex, n).x;
		return clamp(exp(sharpness * (sampleDepth - depth)), 0.0, 1.0);
	}
	]]
end

return sh