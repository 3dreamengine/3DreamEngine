local lib = _3DreamEngine

function lib:newScene()
	return setmetatable({
		tasks = { },
	}, self.meta.scene)
end

local white = vec4(1.0, 1.0, 1.0, 1.0)
local identityMatrix = mat4:getIdentity()
local Z = vec3(0, 0, 0)

return {
	link = {"scene", "visibility"},
	
	clear = function(self)
		self.tasks = { }
		self.ID = 0
	end,
	
	add = function(self, obj, parentTransform, col)
		col = col or white
		
		--add to scene
		local id = self.ID
		for d,s in pairs(obj.objects or {obj}) do
			if not s.disabled then
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
				
				--add
				id = id + 1
				self.tasks[id] = setmetatable({transform, pos or false, s, col, obj, obj.boneTransforms}, lib.meta.task)
			end
		end
		self.ID = id
	end,
}