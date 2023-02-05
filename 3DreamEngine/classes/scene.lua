local lib = _3DreamEngine

---@return DreamScene
function lib:newScene(shadowPass, dynamic, alpha, cam, blacklist, frustumCheck, noSmallObjects, canvases, light, isSun)
	local m = setmetatable({ }, self.meta.scene)
	
	m.tasks = { }
	
	m.shadowPass = shadowPass
	m.dynamic = dynamic
	m.alpha = alpha
	m.cam = cam
	m.blacklist = blacklist or { }
	m.frustumCheck = frustumCheck
	m.noSmallObjects = noSmallObjects
	m.canvases = canvases
	m.light = light
	m.isSun = isSun
	
	--setting specific identifier
	m.settingsIdentifier = self:getGlobalSettingsIdentifier(alpha, canvases, shadowPass, isSun)
	
	return m
end

local function getPosition(object, transform)
	if transform then
		local a = object.boundingBox.center
		return vec3(
				transform[1] * a[1] + transform[2] * a[2] + transform[3] * a[3] + transform[4],
				transform[5] * a[1] + transform[6] * a[2] + transform[7] * a[3] + transform[8],
				transform[9] * a[1] + transform[10] * a[2] + transform[11] * a[3] + transform[12])
	else
		return object.boundingBox.center
	end
end

local function getSize(object, transform)
	return object.boundingBox.size * (transform and transform:getLossySize() or 1)
end

local function isWithingLOD(LOD_min, LOD_max, pos, size)
	local camPos = lib.camera.position
	if camPos then
		local dist = math.max(((pos - camPos):length() - size) * lib.LODFactor, 0)
		if dist <= LOD_max + 1 then
			return dist >= LOD_min and dist <= LOD_max, true
		else
			return false, false
		end
	else
		return true, true
	end
end

---@class DreamScene
local class = {
	links = { "scene" },
}

function class:preload()
	--todo
end

function class:withinFrustum(object, task)
	return not self.frustumCheck or not object.boundingBox.initialized or lib:inFrustum(self.cam, task:getPosition(), task:getSize(), object.rID)
end

function class:add(object)
	self:addObject(object, false, false)
end

function class:addObject(object, parentTransform, dynamic)
	if self.blacklist[object] then
		return
	end
	
	if object.dynamic ~= nil then
		dynamic = object.dynamic
	end
	
	--wrong dynamic layer
	if self.dynamic ~= nil and self.dynamic ~= dynamic then
		return
	end
	
	--apply transformation
	local transform
	if parentTransform then
		if object.transform then
			transform = parentTransform * object.transform
		else
			transform = parentTransform
		end
	else
		transform = object.transform
	end
	
	--store final world transform for potential later use cases
	object.globalTransform = transform
	
	--handle LOD
	--todo lod should be mesh-related, with it's parent object as distance metric, pass a lazy distance metric
	if object.LOD_min or object.LOD_max then
		local pos = getPosition(object, transform)
		local size = getSize(object, transform)
		local LOD_min = object.LOD_min or -math.huge
		local LOD_max = object.LOD_max or math.huge
		local found, preload = isWithingLOD(LOD_min, LOD_max, pos, size)
		if preload then
			object:preload()
		end
		if not found then
			return
		end
	end
	
	--children
	for _, o in pairs(object.objects) do
		self:addObject(o, transform, dynamic)
	end
	
	--meshes
	for _, m in pairs(object.meshes) do
		--todo profiling: 80%
		self:addMesh(m, transform, object.reflection)
	end
end

function class:addMesh(mesh, transform, reflection)
	if self.blacklist[mesh] then
		return
	end
	
	--not visible
	if self.shadowPass then
		if mesh.material.alpha or not mesh.shadowVisibility or mesh.material.shadow == false then
			return
		end
	else
		if not mesh.renderVisibility then
			return
		end
	end
	
	--todo cache
	local pos = getPosition(mesh, transform)
	local size = getSize(mesh, transform)
	
	--create task object
	local task = setmetatable({
		mesh,
		transform,
		pos,
		size,
		false,
		reflection,
	}, lib.meta.task)
	
	--todo
	mesh.rID = mesh.rID or math.random()
	
	--wrong alpha
	if (self.alpha and true) ~= (mesh.material.alpha and true) then
		return
	end
	
	--too small for this shadow type
	--todo still mesh, especially because the size is known here theoretically
	if self.noSmallObjects and mesh.farShadowVisibility ~= false then
		return
	end
	
	--not visible from current perspective
	if not self:withinFrustum(mesh, task) then
		return false
	end
	
	--todo here custom reflections (closest globe or default) and lights can be used
	
	--add to list
	local shader = lib:getRenderShader(task, self.settingsIdentifier, self.alpha, self.canvases, self.light, self.shadowPass, self.isSun)
	self:addTo(task, shader, mesh.material)
end

function class:addTo(task, shader, material)
	task:setShader(shader)
	
	if self.alpha then
		table.insert(self.tasks, task)
	else
		--create lists
		if not self.tasks[shader] then
			self.tasks[shader] = { [material] = { task } }
		elseif not self.tasks[shader][material] then
			self.tasks[shader][material] = { task }
		else
			table.insert(self.tasks[shader][material], task)
		end
	end
end

--sorting function for the alpha pass
local function sortFunction(a, b)
	return a:getDistance() > b:getDistance()
end

function class:getIterator()
	if self.alpha then
		for _, task in ipairs(self.tasks) do
			local dist = (task:getPosition() - self.cam.position):lengthSquared()
			task:setDistance(dist)
		end
		
		table.sort(self.tasks, sortFunction)
		
		local i = 0
		return function()
			i = i + 1
			return self.tasks[i]
		end
	else
		local co = coroutine.create(function()
			for _, shaderGroup in pairs(self.tasks) do
				for _, materialGroup in pairs(shaderGroup) do
					for _, task in pairs(materialGroup) do
						coroutine.yield(task)
					end
				end
			end
		end)
		
		return function()
			local ok, task = coroutine.resume(co)
			if ok then
				return task
			end
		end
	end
end

return class