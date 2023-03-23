---@type Dream
local lib = _3DreamEngine

function lib:newAnimationFrame(time, position, rotation, scale)
	local f = {
		time = time,
		position = position,
		rotation = rotation,
		scale = scale,
	}
	
	return setmetatable(f, self.meta.animationFrame)
end

---@class DreamAnimationFrame : DreamClonable
---@field public position DreamVec3
---@field public rotation DreamQuat
---@field public size number
local class = {
	links = { "animationFrame", "clonable" },
}

return class