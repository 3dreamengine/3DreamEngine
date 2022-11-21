local function uint32(a, b, c, d)
	return a + b * 256 + c * 256 ^ 2 + d * 256 ^ 3
end

return function(self, obj, path)
	local file = love.filesystem.read(path)
	local magic = uint32(file:byte(1, 4))
	local version = uint32(file:byte(5, 8))
	local length = uint32(file:byte(9, 12))
	
	assert(magic == 0x46546C67, "Invalid GLB file.")
	
	local index = 13
	local chunkLength = uint32(file:byte(index, index + 3))
	local chunkType = uint32(file:byte(index + 4, index + 7))
	assert(chunkType == 0x4E4F534A)
	local json = self.json.decode(file:sub(index + 8, index + 7 + chunkLength))
	
	index = index + chunkLength + 8
	local binary
	if index < length then
		local binaryChunkLength = uint32(file:byte(index, index + 3))
		local binaryChunkType = uint32(file:byte(index + 4, index + 7))
		assert(binaryChunkType == 0x004E4942)
		binary = file:sub(index + 8, index + 7 + binaryChunkLength)
	end
	
	return self.loader.gltf(self, obj, path, json, binary)
end