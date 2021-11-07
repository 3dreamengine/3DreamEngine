local lib = _3DreamEngine

function lib:newReflection(static, res, noRoughness)
	assert(not res or self.reflectionsSet.mode ~= "direct", "Custom reflection resolutions are too expensive unless direct render on them has been enabled.")
	res = res or self.reflectionsSet.resolution
	
	local canvas, image
	if type(static) == "userdata" then
		--use loaded cubemap
		image = static
		static = true
	else
		--create new canvas
		canvas = love.graphics.newCanvas(res, res, {format = self.reflections_format, readable = true, msaa = 0, type = "cube", mipmaps = noRoughness and "none" or "manual"})
	end
	
	local priority, pos
	return setmetatable({
		canvas = canvas,
		image = image,
		static = static or false,
		done = false,
		pos = false,
		first = false,
		second = false,
		levels = false,
		roughness = not noRoughness,
		id = math.random(), --used for the job render
	}, self.meta.reflection)
end

local class = {
	link = {"reflection"},
	
	setterGetter = {
		roughness = "boolean",
	},
}

function class:refresh()
	self.done = false
end

function class:setLocal(pos, first, second)
	self.pos = pos
	self.first = first
	self.second = second
end
function class:getLocal()
	return self.pos, self.first, self.second
end

return class