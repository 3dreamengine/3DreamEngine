---@type Dream
local lib = _3DreamEngine
local vec3 = lib.vec3

---Creates a new, empty animation from a dictionary of joint names and animation frames
---@param frameTable table<string, DreamAnimationFrame[]>
---@return DreamAnimation
function lib:newAnimation(frameTable)
	local maxTime = 0
	for _, frames in pairs(frameTable) do
		maxTime = math.max(maxTime, frames[#frames].time)
	end
	
	--create lookup table for animation keyframe
	local lookup = { }
	for joint, frames in pairs(frameTable) do
		lookup[joint] = { }
		for i = 1, #frames do
			local idx = 2
			for index, frame in ipairs(frames) do
				if frame.time >= i / #frames * maxTime then
					idx = index
					break
				end
			end
			lookup[joint][i] = math.max(idx, 2)
		end
	end
	
	return setmetatable({
		frames = frameTable,
		lookup = lookup,
		length = maxTime,
	}, self.meta.animation)
end

---A animation contains transformation tracks for a set of joints
---@class DreamAnimation : DreamClonable
---@field public frames table<string, DreamAnimationFrame[]>
local class = {
	links = { "clonable", "animation" }
}

---Linear interpolation between two frames
---@param first DreamAnimationFrame
---@param second DreamAnimationFrame
---@param blend number
function class.interpolateFrames(first, second, blend)
	return {
		position = first.position * (1.0 - blend) + second.position * blend,
		rotation = first.rotation:nLerp(second.rotation, blend),
		scale = first.scale * (1.0 - blend) + second.scale * blend,
	}
end

---Returns a new animated pose at a specific time stamp
---@param time number
---@return DreamPose
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
			local factor = diff == 0 and 0.5 or (t - f1.time) / diff
			pose[joint] = self.interpolateFrames(f1, f2, factor)
		end
	end
	
	return pose
end

---Returns the length in seconds
function class:getLength()
	return self.length
end

---@private
function class:decode()
	for _, frames in pairs(self.frames) do
		for _, frame in ipairs(frames) do
			frame.position = vec3(frame.position)
			frame.rotation = lib.quat(frame.rotation)
		end
	end
end

return class