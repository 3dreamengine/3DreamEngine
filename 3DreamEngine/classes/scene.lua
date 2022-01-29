local lib = _3DreamEngine

function lib:newScene()
	local m = setmetatable({ }, self.meta.scene)
	m:clear()
	return m
end

local function getPos(object, transform)
	local bb = object.boundingBox
	if transform then
		local a = bb.center
		return vec3(
			transform[1] * a[1] + transform[2] * a[2] + transform[3] * a[3] + transform[4],
			transform[5] * a[1] + transform[6] * a[2] + transform[7] * a[3] + transform[8],
			transform[9] * a[1] + transform[10] * a[2] + transform[11] * a[3] + transform[12])
	else
		return bb.center
	end
end

local function getSize(object, transform)
	local scale = transform and math.sqrt(math.max(
		(transform[1]^2 + transform[5]^2 + transform[9]^2),
		(transform[2]^2 + transform[6]^2 + transform[10]^2),
		(transform[3]^2 + transform[7]^2 + transform[11]^2)
	)) or 1
	
	return object.boundingBox.size * scale
end

local function isWithingLOD(LOD_min, LOD_max, pos, size)
	local camPos = lib.cam.pos
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

local class = {
	link = {"scene"},
}

function class:clear()
	--static tasks
	self.tasks = {
		render = {
			{
				{}, {}
			},
			{
				{}, {}
			},
		},
		shadows = {
			{
				{}, {}
			},
			{
				{}, {}
			},
		},
	}
end

function class:preload()
	--todo
end

function class:addObject(object, parentTransform, dynamic, boneTransforms, reflection)
	if object.dynamic ~= nil then
		dynamic = object.dynamic
	end
	
	--pass down some additional data
	boneTransforms = object.skeleton and object.skeleton.transforms or boneTransforms
	reflection = object.reflection or reflection
	
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
	
	--handle LOD
	if object.LOD_min or object.LOD_max then
		local LOD_min = object.LOD_min or -math.huge
		local LOD_max = object.LOD_max or math.huge
		local pos = getPos(object, transform)
		local size = getSize(object, transform)
		if not isWithingLOD(LOD_min, LOD_max, pos, size) then
			return
		end
	end
	
	--children
	for _,o in pairs(object.objects) do
		self:addObject(o, transform, dynamic, boneTransforms, reflection)
	end
	
	--meshes
	for _,m in pairs(object.meshes) do
		self:addMesh(m, transform, dynamic, boneTransforms, reflection)
	end
end

function class:addMesh(mesh, transform, dynamic, boneTransforms, reflection)
	local pos = getPos(mesh, transform)
	local size = getSize(mesh, transform)
	
	--handle LOD
	if mesh.LOD_min or mesh.LOD_max then
		local LOD_min = mesh.LOD_min or -math.huge
		local LOD_max = mesh.LOD_max or math.huge
		local found, preload = isWithingLOD(LOD_min, LOD_max, pos, size)
		if preload then
			mesh:preload()
		end
		if not found then
			return
		end
	end
	
	--create task object
	local task = setmetatable({
		mesh,
		transform,
		pos,
		size,
		false,
		boneTransforms,
		reflection,
	}, lib.meta.task)
	
	mesh.rID = mesh.rID or math.random()
	
	--insert into respective rendering queues
	local dyn = dynamic and 1 or 2
	local alpha = mesh.material.alpha and 1 or 2
	
	--render pass
	if mesh.renderVisibility then
		local shaderID = lib:getRenderShaderID(task, pass, false)
		self:addTo(task, self.tasks.render[dyn][alpha], shaderID, mesh.material)
	end
	
	--shadow pass
	if alpha == 2 and mesh.shadowVisibility and mesh.material.shadow ~= false then
		local shaderID = lib:getRenderShaderID(task, pass, true)
		self:addTo(task, self.tasks.shadows[dyn][alpha], shaderID, mesh.material)
	end
end

function class:addTo(task, tasks, shaderID, material)
	--create lists
	if not tasks[shaderID] then
		tasks[shaderID] = { }
	end
	if not tasks[shaderID][material] then
		tasks[shaderID][material] = { }
	end
	
	--task batch
	table.insert(tasks[shaderID][material], task)
end

return class