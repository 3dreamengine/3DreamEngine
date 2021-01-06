local lib = _3DreamEngine

function lib:newGroup()
	local g = {
		boundingBox = lib:newBoundaryBox(),
		objects = { },
		hasLOD = false,
	}
	
	return setmetatable(g, self.meta.group)
end

return {
	link = {"clone", "transform", "group"},
	
	add = function(self, o)
		if o.LOD_min then
			self.hasLOD = true
		end
		table.insert(self.objects, o)
	end,
	
	updateBoundingBox = function(self)
		local center = vec3(0, 0, 0)
		local centerCount = 1
		for d,o in pairs(obj.objects) do
			center = center + o.boundingBox.center
			centerCount = centerCount + 1
		end
		self.boundingBox.center = center / centerCount
	end
}