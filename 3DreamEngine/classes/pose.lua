local lib = _3DreamEngine

---@return DreamPose | DreamClonable
function lib:newPose()
	return setmetatable({}, self.meta.pose)
end

---@class DreamPose
local class = {
	links = { "clone", "pose" },
}

---Blend with another pose
---@param second DreamPose
---@param blend number
function class:blend(second, blend)
	local final = lib:newPose()
	local keys = { }
	for name, _ in pairs(self) do
		keys[name] = true
	end
	for name, _ in pairs(second) do
		keys[name] = true
	end
	for name, _ in pairs(keys) do
		if self[name] and second[name] then
			final[name] = lib.classes.animation.interpolateFrames(self[name], second[name], blend)
		else
			final[name] = self[name] or second[name]
		end
	end
	return final
end

return class