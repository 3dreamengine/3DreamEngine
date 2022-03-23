local lib = _3DreamEngine

function lib:newEmptyBoundingBox()
	return setmetatable({
		first = vec3(math.huge, math.huge, math.huge),
		second = vec3(-math.huge, -math.huge, -math.huge),
		center = vec3(0.0, 0.0, 0.0),
		size = 0,
		initialized = false
	}, self.meta.boundingBox)
end

function lib:newBoundingBox(first, second, center, size)
	center = center or (second - first) / 2
	return setmetatable({
		first = first,
		second = second,
		center = center,
		size = size or (center - first):length() * math.sqrt(3),
		initialized = true
	}, self.meta.boundingBox)
end

local class = {
	link = {"clone", "boundingBox"},
	
	setterGetter = {
		first = "table",
		second = "table",
		center = "table",
		size = "number",
		initialized = "boolean",
	}
}

function class:decode()
	self.first = vec3(self.first)
	self.second = vec3(self.second)
	self.center = vec3(self.center)
end

function class:merge(bb)
	return lib:newBoundingBox(
		self.first:max(bb.first),
		self.second:max(bb.second),
		(self.center + bb.center) / 2
	)
end

function class:extend(margin)
	local m = vec3(margin, margin, margin)
	return lib:newBoundingBox(self.first - m, self.second + m, self.center, self.size)
end

return class