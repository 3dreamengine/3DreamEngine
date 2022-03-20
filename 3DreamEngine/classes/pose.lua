local lib = _3DreamEngine

function lib:newPose()
	return setmetatable({}, self.meta.pose)
end

local class = {
	link = {"clone", "pose"},
}

--blend with another pose
function class:blend(b, factor)
	local final = lib:newPose()
	local keys = { }
	for name, joint in pairs(self) do
		keys[name] = true
	end
	for name, joint in pairs(b) do
		keys[name] = true
	end
	for name, _ in pairs(keys) do
		if self[name] and b[name] then
			final[name] = lib.classes.animation.interpolateFrames(self[name], b[name], factor)
		else
			final[name] = self[name] or b[name]
		end
	end
	return final
end

return class