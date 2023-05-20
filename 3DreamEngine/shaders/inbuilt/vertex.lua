local sh = { }

sh.type = "vertex"

function sh:buildVertex(mat)
	return [[
	vertexPos = (transform * vec4(vertexPos, 1.0)).xyz;
	]]
end

return sh