local sh = { }

sh.type = "vertex"

function sh:constructDefines(dream, info)
	
end

function sh:constructPixel(dream, info)
	
end

function sh:constructVertex(dream, info)
	return [[
	vec4 pos = transform * vertex_position;
	]]
end

function sh:perShader(dream, shader, info)
	
end

function sh:perMaterial(dream, shader, info, material)
	
end

function sh:perObject(dream, shader, info, task)

end

return sh