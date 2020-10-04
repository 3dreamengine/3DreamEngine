local sh = { }

sh.type = "light"

sh.batchable = true

function sh:constructDefinesGlobal(dream, info)
	return [[
		extern int firstSimpleLight;
		extern int lastSimpleLight;
	]]
end

function sh:constructDefines(dream, info, ID)
	
end

function sh:constructPixelGlobal(dream, info)
	return ([[
		for (int i = firstSimpleLight; i <= lastSimpleLight; i++) {
			vec3 lightVecRaw = lightPos[i] - vertexPos;
			vec3 lightVec = normalize(lightVecRaw);
			float distance = length(lightVecRaw);
			float power = 1.0 / (0.1 + distance * distance);
			light += getLight(lightColor[i] * power, viewVec, lightVec, normal, albedo.rgb, material.x, material.y);
		}
	]])
end

function sh:constructPixel(dream, info, ID)

end

function sh:sendGlobalUniforms(dream, shader, info, lighting, lightRequirements)
	local first, last = math.huge, -1
	for d,s in ipairs(lighting) do
		if s.light_typ == "point_simple" then
			first = math.min(first, d)
			last = math.max(last, d)
		end
	end
	shader:send("firstSimpleLight", first-1)
	shader:send("lastSimpleLight", math.min(last, first + dream.max_lights - 1)-1)
end

function sh:sendUniforms(dream, shader, info, light, ID)
	
end

return sh