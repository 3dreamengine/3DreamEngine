local lib = _3DreamEngine

function lib:newAnimation()
	local m = transform or pos and mat4:getIdentity():translate(pos) or mat4:getIdentity()
	return setmetatable({
		frames = { },
		length = 0,
	}, self.meta.animation)
end

return {
	link = {"clone"},
}