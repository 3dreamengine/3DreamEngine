--[[
#glTF
--]]

local lib = _3DreamEngine

local cache = { }
local rootObject
local file
local binary
local directory

local function cached(func, node)
	local id = tostring(node) .. tostring(func)
	if cache[id] then
		return cache[id]
	end
	cache[id] = func(node)
	return cache[id]
end

local accessorDataTypes = {
	[5120] = "signed char",
	[5121] = "unsigned char",
	[5122] = "signed short",
	[5123] = "unsigned short",
	[5125] = "unsigned int",
	[5126] = "float",
}

local function loadBuffer(node)
	if not node.uri then
		return binary
	elseif node.uri:sub(1, 5) == "data:" then
		local f = node.uri:find("base64")
		return lib.base64.decode(node.uri:sub(f + 7)) --todo
	else
		return love.filesystem.read(directory .. node.uri)
	end
end

local function loadBufferView(node)
	return {
		buffer = cached(loadBuffer, file.buffers[node.buffer + 1]),
		byteOffset = node.byteOffset or 0,
		byteLength = node.byteLength,
		byteStride = node.byteStride or 1,
	}
end

local function loadAccessor(node)
	if node.bufferView then
		local bufferView = cached(loadBufferView, file.bufferViews[node.bufferView + 1])
		
		assert(bufferView.byteStride == 1, "Stride not supported yet.")
		
		if node.sparse then
			print("Sparse Buffers are not supported yet.")
		end
		
		local type = node.type:lower()
		local dataType = accessorDataTypes[node.componentType]
		
		local offset = bufferView.byteOffset + (node.byteOffset or 0)
		local str = bufferView.buffer:sub(offset + 1, offset + bufferView.byteLength)
		return lib:bufferFromString(type, dataType, str)
	end
end

local function loadTransform(node)
	if node.matrix then
		return mat4(node.matrix)
	else
		local T = node.translation and mat4.getTranslate(node.translation) or mat4.getIdentity()
		local R = node.rotation and quat(node.rotation):toMatrix() or mat4.getIdentity()
		local S = node.scale and mat4.getScale(node.scale) or mat4.getIdentity()
		return T * R * S
	end
end

local function loadImage(node)
	if node.uri then
		return love.image.newImageData(directory .. node.uri)
	elseif node.bufferView then
		local bufferView = cached(loadBufferView, file.bufferViews[node.bufferView + 1])
		local str = bufferView.buffer:sub(bufferView.byteOffset + 1, bufferView.byteOffset + bufferView.byteLength)
		return love.image.newImageData(love.data.newByteData(str))
	end
end

local lookup = {
	[9728] = "nearest",
	[9729] = "linear",
	[9984] = "nearest",
	[9985] = "linear",
	[9986] = "nearest",
	[9987] = "linear",
}

local function loadSampler(node)
	return {
		minFilter = node and lookup[node.minFilter] or "linear",
		magFilter = node and lookup[node.magFilter] or "linear",
	}
end

local function loadTexture(node)
	if not love.graphics then
		return nil
	end
	
	if node then
		local image = cached(loadImage, file.images[node.source + 1])
		local sampler = node.sampler and cached(loadSampler, file.images[node.sampler + 1]) or loadSampler()
		local texture = love.graphics.newImage(image)
		texture:setFilter(sampler.minFilter, sampler.magFilter)
		return texture, image
	end
end

local function loadMaterial(node)
	if lib.materialLibrary[node.name] then
		return lib.materialLibrary[node.name]
	end
	
	local material = lib:newMaterial(node.name)
	
	local metallicRoughness, occlusionTexture
	
	if node.pbrMetallicRoughness then
		if node.pbrMetallicRoughness.baseColorTexture then
			local tex, _ = loadTexture(file.textures[node.pbrMetallicRoughness.baseColorTexture.index + 1])
			material:setAlbedoTexture(tex)
		end
		
		if node.pbrMetallicRoughness.metallicRoughnessTexture then
			_, metallicRoughness = loadTexture(file.textures[node.pbrMetallicRoughness.metallicRoughnessTexture.index + 1])
		end
	end
	
	if node.normalTexture then
		material:setNormalTexture(loadTexture(file.textures[node.normalTexture.index + 1]))
	end
	if node.occlusionTexture then
		_, occlusionTexture = loadTexture(file.textures[node.occlusionTexture.index + 1])
	end
	if node.emissiveTexture then
		material:setEmissionTexture(loadTexture(file.textures[node.emissiveTexture.index + 1]))
		material:setEmission(1, 1, 1)
	end
	
	--combine textures
	if metallicRoughness or occlusionTexture then
		material:setMaterialTexture(lib:combineTextures(metallicRoughness, metallicRoughness, occlusionTexture))
	end
	
	if node.pbrMetallicRoughness then
		material:setColor(unpack(node.pbrMetallicRoughness.baseColorFactor or { 1, 1, 1, 1 }))
		material:setMetallic(node.pbrMetallicRoughness.metallicFactor or 1)
		material:setRoughness(node.pbrMetallicRoughness.roughnessFactor or 1)
	else
		material:setColor(1, 1, 1, 1)
		material:setMetallic(1)
		material:setRoughness(1)
	end
	
	material:setEmission(unpack(node.emissiveFactor or { 0, 0, 0 }))
	
	--material:setAlphaMode(material.alphaMode or "OPAQUE") --todo
	material:setAlphaCutoff(node.alphaCutoff or 0.5)
	material:setCullMode(material.doubleSided and "none" or "back")
	
	return material
end

local meshDrawModes = {
	[0] = "points",
	[4] = "triangles",
	[5] = "strip",
	[6] = "fan",
}

local attributesMapping = {
	POSITION = "vertices",
	NORMAL = "normals",
	TANGENT = "tangents",
	TEXCOORD_0 = "texCoords",
	TEXCOORD_1 = "texCoords2",
	TEXCOORD_2 = "texCoords3",
	TEXCOORD_3 = "texCoords4",
	COLOR_0 = "colors",
	COLOR_1 = "colors2",
	COLOR_2 = "colors3",
	COLOR_3 = "colors4",
	JOINTS_0 = "joints",
	WEIGHTS_0 = "weights",
}

local function loadPrimitive(node)
	local mode = node.mode or 4
	
	if meshDrawModes[mode] then
		local material = node.material and cached(loadMaterial, file.materials[node.material + 1]) or lib:newMaterial()
		local mesh = lib:newMesh("mesh", material)
		
		mesh.meshDrawMode = meshDrawModes[mode]
		for attribute, attributes in pairs(node.attributes) do
			mesh[attributesMapping[attribute] or attribute] = cached(loadAccessor, file.accessors[attributes + 1])
		end
		
		if node.indices then
			mesh.indices = cached(loadAccessor, file.accessors[node.indices + 1])
			mesh.faces = lib:newDynamicBuffer()
			for i = 0, mesh.indices:getSize() - 1, 3 do
				mesh.faces:append({
					mesh.indices:get(i + 1) + 1,
					mesh.indices:get(i + 2) + 1,
					mesh.indices:get(i + 3) + 1,
				})
			end
		end
		
		return mesh
	end
end

local function loadMeshes(node)
	local meshes = { }
	for _, primitive in ipairs(node.primitives) do
		local mesh = cached(loadPrimitive, primitive)
		if mesh then
			table.insert(meshes, mesh)
		end
	end
	return meshes
end

local function loadBone(node)
	--todo class
	local bone = {
		name = node.name,
		transform = loadTransform(node),
	}
	
	if node.children then
		bone.children = { }
		for _, child in pairs(node.children) do
			local cb = cached(loadBone, file.nodes[child + 1])
			bone.children[cb.name] = cb
		end
	end
	
	return bone
end

local function loadSkin(node)
	--as per specification the root can not be the child of anyone
	local childrenTable = { }
	local jointNames = { }
	for _, joint in ipairs(node.joints) do
		local children = file.nodes[joint + 1].children
		if children then
			for _, child in ipairs(children) do
				childrenTable[child] = true
			end
		end
		table.insert(jointNames, file.nodes[joint + 1].name)
	end
	
	local root
	for _, joint in ipairs(node.joints) do
		if not childrenTable[joint] then
			root = joint
			break
		end
	end
	
	return {
		inverseBindMatrices = cached(loadAccessor, file.accessors[node.inverseBindMatrices + 1]):toArray(),
		jointNames = jointNames,
		skeleton = lib:newSkeleton(cached(loadBone, file.nodes[root + 1]))
	}
end

local function loadObject(node)
	local object = lib:newObject(node.name)
	local empty = true
	
	object.transform = loadTransform(node)
	
	--children
	if node.children then
		for _, child in ipairs(node.children) do
			local o = cached(loadObject, file.nodes[child + 1])
			if o then
				object.objects[o.name] = o
				empty = false
			end
		end
	end
	
	--meshes
	if node.mesh then
		object.meshes = cached(loadMeshes, file.meshes[node.mesh + 1])
		empty = false
		
		--skin and skeleton
		if node.skin then
			local skin = cached(loadSkin, file.skins[node.skin + 1])
			for _, mesh in ipairs(object.meshes) do
				mesh.inverseBindMatrices = skin.inverseBindMatrices
				mesh.jointNames = skin.jointNames
				mesh:setSkeleton(skin.skeleton)
				rootObject.mainSkeleton = rootObject.mainSkeleton or skin.skeleton
			end
		end
	end
	
	--camera
	if node.camera then
		--todo
		empty = false
	end
	
	return not empty and object
end

local function loadSkeletalSampler(node)
	return {
		times = cached(loadAccessor, file.accessors[node.input + 1]):toArray(),
		values = cached(loadAccessor, file.accessors[node.output + 1]):toArray(),
		interpolation = node.interpolation
	}
end

return function(self, obj, path, header, blob)
	file = header or self.json.decode(love.filesystem.read(path))
	binary = blob
	rootObject = obj
	directory = path:match("(.*[/\\])")
	
	--load scenes
	if file.scenes then
		for _, scene in ipairs(file.scenes) do
			for _, node in ipairs(scene.nodes) do
				local o = cached(loadObject, file.nodes[node + 1])
				if o then
					obj.objects[o.name] = o
				end
			end
		end
	end
	
	--load animations
	if file.animations then
		for aid, animation in ipairs(file.animations) do
			local targets = { }
			for _, channel in ipairs(animation.channels) do
				local name = file.nodes[channel.target.node + 1].name
				targets[name] = targets[name] or { }
				targets[name][channel.target.path] = cached(loadSkeletalSampler, animation.samplers[channel.sampler + 1])
			end
			
			local frames = { }
			for node, target in pairs(targets) do
				frames[node] = { }
				for i, time in ipairs(target[next(target)].times) do
					table.insert(frames[node], { --todo class
						time = time,
						rotation = target["rotation"] and quat(target["rotation"].values[i]) or quat(0, 0, 0, 1),
						position = target["translation"] and target["translation"].values[i] or vec3(0, 0, 0),
						scale = target["scale"] and target["scale"].values[i] or vec3(1, 1, 1),
					})
				end
			end
			
			obj.animations[animation.name or aid] = lib:newAnimation(frames)
		end
	end
	
	file = false
	rootObject = false
	cache = { }
end