--[[
#part of the 3DreamEngine by Luke100000
loader.lua - loads objects
--]]

local lib = _3DreamEngine

--tags that will get recognized
lib.meshTags = {
	["PHYSICS"] = true,
	["LOD"] = true,
	["POS"] = true,
	["LINK"] = true,
	["ID"] = true,
	["RAYTRACE"] = true,
	["REFLECTION"] = true,
	["HIDE"] = true,
	["SHADOW"] = true,
}

--the default args used by the object loader
lib.defaultArgs = {
	cleanup = false,
	mesh = true,
	export3do = false,
	skip3do = false,
	particleSystems = true,
	scene = false,
	decodeBlenderNames = true,
}

--extends given arg table with default args
local function prepareArgs(args)
	if type(args) == "string" then
		error("loadObjects signature has changed, please check docu")
	end
	
	args = table.copy(args or { })
	
	for d, s in pairs(lib.defaultArgs) do
		if args[d] == nil then
			args[d] = s
		end
	end
	
	return args
end

--remove objects without vertices
local function cleanEmpties(obj)
	for d, m in pairs(obj.meshes) do
		if not m.faces or not m.vertices or m.vertices:getSize() == 0 then
			obj.meshes[d] = nil
		end
	end
end

lib.supportedFiles = {
	--todo temporary disabled
	-- "3do", --3DreamEngine object file - way faster than obj but does not keep vertex information
	"glb", --glTF binary format
	"gltf", --glTF embedded or separate
	"vox", --magicka voxel
	"obj", --obj file
	"dae", --dae file
}

--add to object library instead
function lib:loadLibrary(path, args, prefix)
	args = prepareArgs(args)
	args.loadAsLibrary = true
	
	--load
	local obj = self:loadScene(path, args)
	
	--insert into library
	for d, o in pairs(obj.objects) do
		local id = (prefix or "") .. d
		self.objectLibrary[id] = o
	end
end

function lib:registerObject(object, name)
	self.objectLibrary[name] = object
end

--loads an scene
--this is just a wrapper for loadObject with the scene flag enabled
function lib:loadScene(path, args)
	args = args and table.copy(args) or { }
	args.scene = true
	return self:loadObject(path, args)
end

--[[
Object Tags in name
A mesh/object name may contain additional tags, denoted as `TAG:VALUE_` or `TAG_`
	`POS:name` treats it as position
	`PHYSICS:type` treats it as a collider
	`LOD:level` set lod, starting at 0
	`LINK:name` replace this object with an library entry
	`RAYTRACE` treat as raytrace, puts it into
	`REFLECTION` treat as reflection (WIP)
	`REMOVE` removes, may be used for placeholder or reference objects
	`SHADOW:FALSE` disabled shadow
--]]

--[[
Loader Args
	`mesh (true)` create a mesh after loading
	`particleSystems (true)` generate particleSystems as defined in the material
	`cleanup (true)` deloads raw buffers (positions, normals, ...) after finishing loading
	`export3do (false)` loads the object as usual, then export the entire object as a 3DO file
	`animations (nil)` when using COLLADA format, split the animation into `{key = {from, to}}`, where `from` and `to` are timestamps in seconds
	`decodeBlenderNames (true)` remove the vertex objects postfix added on export, e.g. `name` instead of `name_Cube`
--]]

---LoadObject
---@param path string @ Path to object without extension
---@param args "Args"
function lib:loadObject(path, args)
	--set default args
	args = prepareArgs(args)
	
	local n = string.split(path, "/")
	local name = self:removePostfix(n[#n] or path)
	local dir = #n > 1 and table.concat(n, "/", 1, #n - 1) or ""
	
	local obj = self:newObject(name)
	obj.args = args
	obj.dir = dir
	
	self.deltonLoad:start("load " .. obj.name)
	
	--test for existing files
	local found = { }
	local newest = 0
	for _, typ in ipairs(lib.supportedFiles) do
		local info = love.filesystem.getInfo(path .. "." .. typ)
		if info then
			found[typ] = info.modtime or 0
			newest = math.max(info.modtime or 0, newest)
		end
	end
	
	--skip old 3do files
	if args.skip3do or found["3do"] and found["3do"] < newest then
		found["3do"] = nil
	end
	
	--load files
	for _, typ in ipairs(lib.supportedFiles) do
		if found[typ] then
			--load object
			self.deltonLoad:start("parser")
			local failed = self.loader[typ](self, obj, path .. "." .. typ)
			self.deltonLoad:stop()
			
			--skip further modifying and exporting if already packed as 3do
			--also skips mesh loading since it is done manually
			if typ == "3do" and not failed then
				goto skipWhen3do
				break
			end
		end
	end
	
	if not next(found) then
		error("object " .. obj.name .. " not found (" .. path .. ")")
	end
	
	
	--extract positions, physics, ...
	self:processObject(obj)
	
	:: skipWhen3do ::
	
	
	--create meshes, link library entries, ...
	for _, o in pairs(obj.objects) do
		self:finishObject(o)
	end
	self:finishObject(obj)
	
	self.deltonLoad:stop()
	
	--3do exporter
	--todo temporary disable
	if obj.args.export3do and false then
		self:export3do(obj)
		
		--doing that enforces loading the exported 3do object instead, making sure the first load behaves the same as the other ones
		args.skip3do = false
		return self:loadObject(path, args)
	end
	return obj
end

---@param name string @ the full object or mesh identifier
---@return string, table @ the actual name and the extracted tags
function lib:parseTags(name)
	name = self:removePostfix(name)
	if type(name) == "string" then
		local possibles = string.split(name, "_")
		local tags = { }
		for index, tag in ipairs(possibles) do
			local key, value = unpack(string.split(tag, ":"))
			if self.meshTags[key] then
				--tag found
				tags[key:lower()] = value or true
			elseif key:upper() == key and key:lower() ~= key then
				--this looks like a tag, but is invalid
				print(string.format("Unknown tag '%s' of object/mesh '%s'", key, name))
			else
				--cancel, the rest is the name
				return table.concat(possibles, "_", index), tags
			end
		end
		return "root", tags
	else
		return name, { }
	end
end

function lib:processObject(obj)
	for id, object in pairs(obj.objects) do
		--pase tags
		local name, tags = self:parseTags(id)
		object.name = name
		object.tags = tags
		
		--recursive
		self:processObject(object)
		
		--detect links
		if object.tags.link then
			--remove original
			obj.objects[id] = nil
			
			--store link
			table.insert(obj.links, {
				source = type(object.tags.link) == "string" and object.tags.link or object.name,
				transform = object.transform
			})
		end
		
		--extract positions
		if object.tags.pos then
			local p = self:newPosition(
					object:getPosition(),
					object:getTransform():getLossySize(),
					type(object.tags.pos) == "string" and object.tags.pos or object.name
			)
			p:setName(object.name)
			obj.positions[id] = p
			obj.objects[id] = nil
		end
		
		
		--extract reflections
		if object.tags.reflection then
			local r = self:newReflection(self.textures.skyFallback)
			r.ID = id
			
			--todo temporary disabled
			r.first = vec3(-0.5, -0.5, -0.5)
			r.second = vec3(0.5, 0.5, 0.5)
			r.center = vec3(0, 0, 0)
			
			obj.reflections[id] = r
			obj.objects[id] = nil
		end
		
		
		--LOD detection
		if object.tags.lod then
			local level = tonumber(object.tags.lod)
			assert(level, "Malformed LoD tag!")
			
			local nextLevel = math.huge
			for _, o in pairs(obj.objects) do
				local l = tonumber(o.tags.lod)
				if l and l > level and l < nextLevel then
					nextLevel = l
				end
			end
			
			--apply LOD level
			object:setLOD(level, nextLevel)
		end
		
		
		--raytrace objects are usually not meant to be rendered
		if object.tags.raytrace then
			for i, mesh in pairs(object.meshes) do
				object.raytraceMeshes[i] = self:newRaytraceMesh(mesh)
			end
			
			--remove if no longer used
			if not object.tags.lod then
				object.meshes = { }
			end
		end
		
		
		--hide
		if object.tags.hide then
			object:setVisible(false)
		end
		
		
		--visibility in the shadow pass
		if object.tags.shadow == "false" then
			object:setShadowVisibility(false)
		elseif object.tags.shadow then
			object:setRenderVisibility(false)
		end
		
		
		--extract physics
		if object.tags.physics then
			local shapeMode = type(object.tags.physics) == "string" and object.tags.physics
			for meshId, mesh in pairs(object.meshes) do
				--2.5D physics
				for i, m in ipairs(mesh:separate()) do
					object.collisionMeshes[meshId .. "_" .. i] = self:newCollisionMesh(m, shapeMode)
				end
				
				--remove if no longer used
				if not object.tags.lod then
					object.meshes = { }
				end
			end
		end
	end
	
	
	--create particle systems
	if obj.args.particleSystems then
		self:addParticleSystems(obj)
	end
	
	
	--merge objects with the same name (e.g. different level of detail, collisions, light sources of a coherent object)
	if obj.args.scene then
		for _, typ in ipairs({ "objects", "meshes", "collisionMeshes", "raytraceMeshes", "positions", "lights", "reflections", "animations" }) do
			local old = obj[typ]
			obj[typ] = { }
			
			for id, object in pairs(old) do
				--create new object
				local parent = obj.objects[object.name]
				if not parent then
					parent = self:newObject(object.name)
					parent.transform = object.transform
					obj.objects[object.name] = parent
				end
				
				--make sure to transform accordingly
				local difference = 0
				if object.transform then
					parent.transform = parent.transform or mat4.getIdentity()
					for i = 1, 16 do
						difference = math.max(difference, math.abs(object.transform[i] - parent.transform[i]))
					end
					
					if difference > 10 ^ -10 then
						print(string.format("Warning: %s (%s) has a different transform than the rest!", id, object))
						object.transform = parent:getInvertedTransform() * object.transform
					else
						object.transform = nil
					end
				end
				
				if object.position then
					object.position = parent:getInvertedTransform() * object.position
				end
				
				--add to new object
				parent[typ][id] = object
			end
		end
	end
	
	
	--calculate bounding box
	if not obj.boundingBox.initialized then
		obj:updateBoundingBox()
	end
	
	
	--split animations
	if obj.args.animations then
		local animation = obj.animations[next(obj.animations)]
		if animation then
			obj.animations = { }
			for anim, time in pairs(obj.args.animations) do
				local newFrames = { }
				for joint, frames in pairs(animation.frames) do
					newFrames[joint] = { }
					for _, frame in ipairs(frames) do
						if frame.time >= time[1] and frame.time <= time[2] then
							local f = table.flatCopy(frame)
							f.time = f.time - time[1]
							table.insert(newFrames[joint], f)
						end
					end
				end
				self:newAnimation(newFrames)
			end
		end
	end
end

function lib:finishObject(obj)
	--link objects
	for index, link in ipairs(obj.links) do
		local lo = self.objectLibrary[link.source]
		assert(lo, "Linked object " .. link.source .. " is not in the object library!")
		local o = self:newLinkedObject(lo, link.source)
		o.transform = link.transform
		obj.objects["link_" .. index] = o
	end
	
	--callback
	if obj.args.callback then
		obj.args.callback(obj)
	end
	
	--remove empty meshes
	cleanEmpties(obj)
	
	--cleaning up
	if obj.args.cleanup then
		obj:cleanup()
	end
end