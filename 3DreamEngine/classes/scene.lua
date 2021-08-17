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
		if object.groups then
			--object
			for name,group in pairs(object.groups) do
				--apply transformation
				local transform
				if parentTransform then
					if group.transform then
						transform = parentTransform * group.transform
					else
						transform = parentTransform
					end
				elseif group.transform then
					transform = group.transform
				end
				
				--task
				if group.hasLOD and LODsActive then
					local dist = getDistance(group.boundingBox.center, transform)
					for aaa,o in ipairs(group.objects) do
						local LOD_min, LOD_max = o:getScaledLOD()
						local aDist = LOD_min and o.LOD_center and getDistance(o.boundingBox.center, transform) or dist
						if not LOD_max or aDist <= (LOD_max + 1)^2 then
							o:preload()
							if not LOD_min or aDist >= LOD_min^2 and aDist <= LOD_max^2 then
								self:add(o, transform, dynamic)
							end
						end
					end
				else
					for _,o in ipairs(group.objects) do
						o:preload()
						self:add(o, transform, dynamic)
					end
				end
			end
		else
			--direct mesh
			self:add(object, parentTransform, dynamic)
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