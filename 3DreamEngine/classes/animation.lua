local lib = _3DreamEngine

function lib:newAnimation()
	local m = transform or pos and mat4:getIdentity():translate(pos) or mat4:getIdentity()
	return setmetatable({
		frames = { },
		lookup = { },
		length = 0,
	}, self.meta.animation)
end

return {
	link = {"clone", "animation"},
	
	finish = function(self)
		local maxTime = 0
		for joint, frames in pairs(self.frames) do
			maxTime = math.max(maxTime, frames[#frames].time)
		end
		
		--create lookup table for animation keyframe
		self.lookup = { }
		for joint, frames in pairs(self.frames) do
			self.lookup[joint] = { }
			for i = 1, #frames do
				local idx = 2
				for index, frame in ipairs(frames) do
					if frame.time >= i / #frames * maxTime then
						idx = index
						break
					end
				end
				self.lookup[joint][i] = idx
			end
		end
		
		self.length = maxTime
	end,
}