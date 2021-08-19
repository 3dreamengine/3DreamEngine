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
	local scale = transform and math.max(
		(transform[1]^2 + transform[5]^2 + transform[9]^2),
		(transform[2]^2 + transform[6]^2 + transform[10]^2),
		(transform[3]^2 + transform[7]^2 + transform[11]^2)
	) or 1
	
	return math.sqrt(3 * (object.boundingBox.size * scale)^2)
end

local function isWithingLOD(LOD_max, LOD_min, pos, size)
	local dist = (pos - camPos):lengthSquared() / lib.LODDistance - size^2
	if dist <= (LOD_max + 1)^2 then
		m:preload()
		return (not LOD_min or dist >= LOD_min^2) and dist <= LOD_max^2
	else
		return false
	end
end

return {
	link = {"scene"},
	
	clear = function(self)
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
	end,
	
	preload = function(self)
		--todo
	end,
	
	addObject = function(self, object, parentTransform, dynamic)
		
		if object.dynamic ~= nil then
			dynamic = object.dynamic
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
			self:addObject(o, transform, dynamic)
		end
		
		--meshes
		for _,m in pairs(object.meshes) do
			self:addMesh(m, transform, dynamic)
		end
	end,
	
	addMesh = function(self, mesh, transform, dynamic)
		local pos = getPos(mesh, transform)
		local size = getSize(mesh, transform)
		
		--handle LOD
		if mesh.LOD_min or mesh.LOD_max then
			local LOD_min = mesh.LOD_min or -math.huge
			local LOD_max = mesh.LOD_max or math.huge
			if not isWithingLOD(LOD_min, LOD_max, pos, size) then
				return
			end
		end
		
		local task = setmetatable({
			mesh,
			transform,
			pos,
			size,
		}, lib.meta.task)
		
		mesh.rID = mesh.rID or math.random()
		
		--insert into respective rendering queues
		local dyn = dynamic and 1 or 2
		local alpha = mesh.material.alpha and 1 or 2
		
		--render pass
		if mesh.renderVisibility ~= false then
			local shaderID = lib:getRenderShaderID(mesh, pass, false)
			self:addTo(task, self.tasks.render[dyn][alpha], shaderID, mesh.material)
		end
		
		--shadow pass
		if not alpha and mesh.shadowVisibility ~= false and mesh.material.shadow ~= false then
			local shaderID = lib:getRenderShaderID(mesh, pass, true)
			self:addTo(task, self.tasks.shadows[dyn][alpha], shaderID, mesh.material)
		end
	end,
	
	addTo = function(self, task, tasks, shaderID, material)
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
}