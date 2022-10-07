local lib = _3DreamEngine

function lib:newAnimation()
	return setmetatable({
		frames = { },
		lookup = { },
		length = 0,
	}, self.meta.animation)
end

local class = {
	link = { "clone", "animation" }
}

function class:finish()
	local maxTime = 0
	for _, frames in pairs(self.frames) do
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
			self.lookup[joint][i] = math.max(idx, 2)
		end
	end
	
	self.length = maxTime
end

--linear interpolation of position and rotation between two frames
function class.interpolateFrames(f1, f2, factor)
	return {
		position = f1.position * (1.0 - factor) + f2.position * factor,
		rotation = f1.rotation:nLerp(f2.rotation, factor),
		--todo size?
	}
end

--returns a new animated pose at a specific time stamp
function class:getPose(time)
	local pose = lib:newPose()
	
	for joint, frames in pairs(self.frames) do
		if #frames == 0 then
			self.frames[joint] = nil
		elseif #frames == 1 then
			table.insert(frames, frames[1])
		else
			local t = time == self.length and time or time % self.length
			
			--find two frames
			local f1 = frames[1]
			local f2 = frames[2]
			local lu = self.lookup[joint]
			for f = lu and lu[math.ceil(t / self.length * #lu)] or 2, #frames do
				if frames[f].time >= t then
					f1 = frames[f - 1]
					f2 = frames[f]
					break
				end
			end
			
			--get interpolation factor
			local diff = (f2.time - f1.time)
			local factor = diff == 0 and 0.5 or (t - f1.time) / diff --todo fails sometimes
			pose[joint] = self.interpolateFrames(f1, f2, factor)
		end
	end
	
	return pose
end

function class:decode()
	for _, frames in pairs(self.frames) do
		for _, frame in ipairs(frames) do
			frame.position = vec3(frame.position)
			frame.rotation = quat(frame.rotation)
		end
	end
	self:finish()
end

return class