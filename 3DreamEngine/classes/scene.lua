local lib = _3DreamEngine

function lib:newScene()
	return setmetatable({
		tasks = { },
	}, self.meta.scene)
end

local white = vec4(1.0, 1.0, 1.0, 1.0)
local identityMatrix = mat4:getIdentity()

return {
	link = {"scene", "visibility"},
	
	clear = function(self)
		self.tasks = { }
	end,
	
	add = function(self, obj, parentTransform, col)
		--add to scene
		for d,s in pairs(obj.objects or {obj}) do
			if s.mesh and not s.disabled then
				--apply transformation
				local transform
				if parentTransform then
					if s.transform then
						transform = parentTransform * s.transform
					else
						transform = parentTransform
					end
				else
					if s.transform then
						transform = s.transform
					else
						transform = identityMatrix
					end
				end
				
				--get required shader
				s.shader = lib:getShaderInfo(s, obj)
				
				--bounding box
				local pos
				local bb = s.boundingBox
				if bb then
					--mat4 * vec3 multiplication, for performance reasons hardcoded
					local a = bb.center
					pos = vec3(transform[1] * a[1] + transform[2] * a[2] + transform[3] * a[3] + transform[4],
						transform[5] * a[1] + transform[6] * a[2] + transform[7] * a[3] + transform[8],
						transform[9] * a[1] + transform[10] * a[2] + transform[11] * a[3] + transform[12])
				else
					pos = vec3(transform[4], transform[8], transform[12])
				end
				
				--add
				table.insert(self.tasks, {
					transform = transform, --transformation matrix, can be nil
					pos = pos,             --bounding box center position of object
					s = s,                 --drawable object
					color = col or white,  --color, will affect color/albedo input
					obj = obj,             --the object container used to store general informations (reflections, ...)
					boneTransforms = obj.boneTransforms,
				})
			end
		end
	end,
}