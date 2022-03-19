local sh = setmetatable({}, {
	__index = function(_, k)
		return _3DreamEngine.lightShaders["point_shadow"][k]
	end
})

sh.func = "sampleShadowPointDynamic"

function sh:constructDefinesGlobal(dream)
	return [[
	float sampleShadowPointDynamic(vec3 lightVec, samplerCube tex) {
		float depth = length(lightVec);
		float bias = depth * 0.01 + 0.01;
		
		//direction
		vec3 n = normalize(-lightVec * vec3(1.0, -1.0, 1.0));
		
		//fetch
		vec2 r = texture(tex, n).xy;
		return min(r.x, r.y) + bias > depth ? 1.0 : 0.0;
	}
	]]
end

return sh