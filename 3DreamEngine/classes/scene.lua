local lib = _3DreamEngine

local white = vec4(1.0, 1.0, 1.0, 1.0)

function lib:newScene()
	local m = setmetatable({ }, self.meta.scene)
	m:clear()
	return m
end

return {
	link = {"scene", "visibility"},
	
	clear = function(self)
		--static tasks
		self.tasks = {
			{ --static
				all = { },
				render = { },
				shadows = { },
				reflections = { },
			},
			{ --dynamic
				all = { },
				render = { },
				shadows = { },
				reflections = { },
			},
		}
	end,
	
	add = function(self, object, parentTransform, col, dynamic)
		col = col or white
		local camPos = dream.cam.pos or vec3(0, 0, 0)
		
		--add to scene
		for d,s in pairs(object.objects or {object}) do
			local obj = s.obj or object
			
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
			
			--LOD
			local LOD_min, LOD_max = s:getScaledLOD()
			local dist
			if LOD_min then
				--harcoded distance after LOD_center transformation minus the camPos
				local b = s.LOD_center
				dist = math.sqrt(
					(transform[1] * b[1] + transform[2] * b[2] + transform[3] * b[3] + transform[4] - camPos[1])^2 +
					(transform[5] * b[1] + transform[6] * b[2] + transform[7] * b[3] + transform[8] - camPos[2])^2 +
					(transform[9] * b[1] + transform[10] * b[2] + transform[11] * b[3] + transform[12] - camPos[3])^2
				)
			end
			
			--task
			if not dist or dist >= LOD_min and dist <= LOD_max then
				--prepare task
				local task = setmetatable({s, col, obj, false, transform, false, obj.boneTransforms}, lib.meta.task)
				
				--insert into respective rendering queues
				local visibility = s.visibility or obj.visibility
				local dyn = (dynamic or s.dynamic) and 2 or 1
				if visibility then
					if visibility.render then
						table.insert(self.tasks[dyn].render, task)
					end
					if visibility.shadows then
						table.insert(self.tasks[dyn].shadows, task)
					end
					if visibility.reflections then
						table.insert(self.tasks[dyn].reflections, task)
					end
				else
					table.insert(self.tasks[dyn].all, task)
				end
			end
		end
	end,
}