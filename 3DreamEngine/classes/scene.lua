local lib = _3DreamEngine

function lib:newScene()
	local m = setmetatable({ }, self.meta.scene)
	m:clear()
	return m
end

local white = vec4(1.0, 1.0, 1.0, 1.0)
local identityMatrix = mat4:getIdentity()
local Z = vec3(0, 0, 0)

return {
	link = {"scene", "visibility"},
	
	clear = function(self)
		self.tasks = { }
		self.tasksRender = { }
		self.tasksShadows = { }
		self.tasksReflections = { }
	end,
	
	add = function(self, obj, parentTransform, col)
		col = col or white
		
		--add to scene
		for d,s in pairs(obj.objects or {obj}) do
			--apply transformation
			local transform
			if parentTransform then
				if s.transform then
					transform = parentTransform * s.transform
				else
					transform = parentTransform
				end
			elseif s.transform then
				transform = s.transform
			end
			
			--bounding box
			local pos
			if not transform then
				transform = identityMatrix
				pos = Z
			end
			
			--prepare task
			local task = setmetatable({transform, pos or false, s, col, obj, obj.boneTransforms}, lib.meta.task)
			
			--LOD
			local LOD_min = s.LOD_min or obj.LOD_min
			local LOD_max = s.LOD_max or obj.LOD_max
			local dist = LOD_min and s.LOD_center and (transform * s.LOD_center - (dream.cam.pos or vec3(0, 0, 0))):length() * 0.1
			
			--task
			if not dist or dist >= LOD_min and dist <= LOD_max then
				local visibility = s.visibility or obj.visibility
				if visibility then
					if visibility.render then
						table.insert(self.tasksRender, task)
					end
					if visibility.shadows then
						table.insert(self.tasksShadows, task)
					end
					if visibility.reflections then
						table.insert(self.tasksReflections, task)
					end
				else
					table.insert(self.tasks, task)
				end
			end
		end
	end,
}