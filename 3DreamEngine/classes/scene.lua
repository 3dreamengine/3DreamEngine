local lib = _3DreamEngine

local white = vec4(1.0, 1.0, 1.0, 1.0)

local LODsActive = true
function lib:setLODs(e)
	LODsActive = e
end
function lib:getLODs(e)
	return LODsActive
end

--harcoded distance after center transformation minus the camPos
local function getDistance(b, transform)
	local camPos = lib.cam.pos
	if camPos then
		return transform and (
			(transform[1] * b[1] + transform[2] * b[2] + transform[3] * b[3] + transform[4] - camPos[1])^2 +
			(transform[5] * b[1] + transform[6] * b[2] + transform[7] * b[3] + transform[8] - camPos[2])^2 +
			(transform[9] * b[1] + transform[10] * b[2] + transform[11] * b[3] + transform[12] - camPos[3])^2
		) or (b - camPos):lengthSquared()
	else
		return 0
	end
end

function lib:newScene()
	local m = setmetatable({ }, self.meta.scene)
	m:clear()
	return m
end

return {
	link = {"scene"},
	
	clear = function(self)
		--static tasks
		self.tasks = {
			render = {
				{}, {}, {}, {},
			},
			shadows = {
				{}, {}, {}, {},
			},
		}
	end,
	
	addObject = function(self, object, parentTransform, dynamic)
		if object.class == "object" then
			--apply transformation
			local transform
			if parentTransform then
				if object.transform then
					transform = parentTransform * object.transform
				else
					transform = parentTransform
				end
			elseif object.transform then
				transform = object.transform
			end
			
			--children
			for _,o in pairs(object.objects) do
				self:addObject(o, transform, dynamic)
			end
			
			--task
			if object.hasLOD and LODsActive then
				local dist = getDistance(object.boundingBox.center, transform)
				for _,m in pairs(object.meshes) do
					local LOD_min, LOD_max = m:getScaledLOD()
					local aDist = LOD_min and m.LOD_center and getDistance(m.boundingBox.center, transform) or dist
					if not LOD_max or aDist <= (LOD_max + 1)^2 then
						m:preload()
						if not LOD_min or aDist >= LOD_min^2 and aDist <= LOD_max^2 then
							self:add(m, transform, dynamic)
						end
					end
				end
			else
				for _,m in pairs(object.meshes) do
					m:preload()
					self:add(m, transform, dynamic)
				end
			end
		elseif object.class == "mesh" then
			--direct mesh
			self:add(object, parentTransform, dynamic)
		else
			error("object or mesh expected")
		end
	end,
	
	add = function(self, s, transform, dynamic)
		local task = setmetatable({
			transform,
			false,
			false,
			s,
			false,
			s.obj.boneTransforms,
		}, lib.meta.task)
		
		s.rID = s.rID or math.random()
		
		--insert into respective rendering queues
		local dyn = dynamic or s.dynamic
		local alpha = s.material.alpha
		local id = (dyn and 2 or 0) + (alpha and 2 or 1)
		
		--render pass
		if s.renderVisibility ~= false and s.obj.renderVisibility ~= false then
			self:addTo(task, self.tasks.render[id], s, pass, false)
		end
		
		--shadow pass
		if not alpha and (s.shadowVisibility ~= false and s.obj.shadowVisibility ~= false) and s.material.shadow ~= false then
			self:addTo(task, self.tasks.shadows[id], s, pass, true)
		end
	end,
	
	addTo = function(self, task, t, s, pass, shadow)
		local shaderID = lib:getRenderShaderID(s, pass, shadow)
		local materialID = s.material
		
		--create lists
		if not t[shaderID] then
			t[shaderID] = { }
		end
		if not t[shaderID][materialID] then
			t[shaderID][materialID] = { }
		end
		
		--task batch
		table.insert(t[shaderID][materialID], task)
	end
}