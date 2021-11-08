local lib = _3DreamEngine

function lib:newAnimation()
	local m = transform or pos and mat4:getIdentity():translate(pos) or mat4:getIdentity()
	return setmetatable({
		frames = { },
		lookup = { },
		length = 0,
	}, self.meta.animation)
end

local class = {
	link = {"clone", "animation"}
}
	
function class:finish()
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
end

--linear interpolation of position and rotatation between two frames
local function interpolateFrames(f1, f2, factor)
	return {
		position = f1.position * (1.0 - factor) + f2.position * factor,
		rotation = f1.rotation:nLerp(f2.rotation, factor),
	}
end

--returns a new animated pose at a specific time stamp
function class:getPose(time)
	assert(self, "animation is nil, is the name correct?")
	local pose = { }
	
	for joint,frames in pairs(self.frames) do
		local t = time == self.length and time or time % self.length
		
		--find two frames
		local f1 = frames[1]
		local f2 = frames[2]
		local lu = self.lookup[joint]
		for f = lu[math.ceil(t / self.length * #lu)] or 2, #frames do
			if frames[f].time >= t then
				f1 = frames[f-1]
				f2 = frames[f]
				break
			end
		end
		
		--get interpolation factor
		local diff = (f2.time - f1.time)
		local factor = diff == 0 and 0.5 or (t - f1.time) / diff
		pose[joint] = interpolateFrames(f1, f2, factor)
	end
	
	return pose
end

--blend with another pose
function class:blend(b, factor)
	local final = { }
	local keys = { }
	for name, joint in pairs(self) do
		keys[name] = true
	end
	for name, joint in pairs(b) do
		keys[name] = true
	end
	for name, _ in pairs(keys) do
		if self[name] and b[name] then
			final[name] = interpolateFrames(self[name], b[name], factor)
		else
			final[name] = self[name] or b[name]
		end
	end
end

return class