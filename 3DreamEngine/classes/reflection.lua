local lib = _3DreamEngine

function lib:newReflection(static, res, noRoughness)
	assert(not res or self.reflectionsSet.direct, "Custom reflection resolutions are too expensive unless direct render on them has been enabled.")
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
	
	return setmetatable({
		canvas = canvas,
		image = image,
		static = static or false,
		done = { },
		priority = priority or 1.0,
		lastUpdate = 0,
		pos = pos,
		levels = false,
		frameSkip = 0,
		roughness = not noRoughness,
		id = math.random(), --used for the job render
	}, self.meta.reflection)
end

return {
	link = {"reflection"},
	
	setterGetter = {
		frameSkip = "number",
		roughness = "boolean",
	},
	
	refresh = function(self)
		self.done = { }
	end,
	
	setLocal = function(self, pos, first, second)
		self.pos = pos
		self.first = first
		self.second = second
	end,
	getLocal = function(self)
		return self.pos, self.first, self.second
	end,
}