local sh = { }

sh.type = "light"

sh.batchable = true

function sh:constructDefinesGlobal(dream, info)
	return [[
		extern int point_simple_count;
		
		extern vec3 point_simple_pos[]] .. dream.max_lights .. [[];
		extern vec3 point_simple_color[]] .. dream.max_lights .. [[];
	]]
end

function sh:constructDefines(dream, info, ID)
	
end

function sh:constructPixelGlobal(dream, info)
	return ([[
		for (int i = 0; i < pint_simple_count; i++) {
			vec3 lightVecRaw = point_simple_pos[i] - vertexPos;
			vec3 lightVec = normalize(lightVecRaw);
			float distance = length(lightVecRaw);
			float power = 1.0 / (0.1 + distance * distance);
			light += getLight(point_simple_color[i] * power, viewVec, lightVec, normal, albedo.rgb, material.x, material.y);
		}
	]])
end

function sh:constructPixel(dream, info, ID)

end

function sh:sendGlobalUniforms(dream, shader, info, count)
	local colors = { }
	local pos = {}
	for d,s in ipairs(lighting) do
		if s.light_typ == "point_simple" then
			colors[#colors+1] = {s.r * s.brightness, s.g * s.brightness, s.b * s.brightness}
			pos[#pos+1] = {s.x, s.y, s.z}
		end
	end
	shader:send("point_simple_count", count)
	shader:send("point_simple_pos", pos)
	shader:send("point_simple_color", colors)
end

function sh:sendUniforms(dream, shader, info, light, ID)
	
end

return sh