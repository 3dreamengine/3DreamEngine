--[[
#part of the 3DreamEngine by Luke100000
animations.lua - contains animation and skeletal relevant functions
--]]

local lib = _3DreamEngine

--interpolate position and rotatation between two frames
local function interpolateFrames(f1, f2, factor)
	return {
		position = f1.position * (1.0 - factor) + f2.position * factor,
		rotation = f1.rotation:nLerp(f2.rotation, factor),
	}
end

--returns a new animated pose at a specific time stamp
function lib:getPose(object, animation, time)
	local pose = { }
	
	--create rest pose
	for name,_ in pairs(object.joints) do
		pose[name] =  {
			position = vec3(0, 0, 0),
			rotation = quat(1, 0, 0, 0),
		}
	end
	
	--type on animation input
	local inputType
	if type(animation) == "table" then
		if animation[1] then
			inputType = "simple"
		else
			inputType = "complex"
		end
	else
		inputType = "single"
	end
	
	--get frame of animation
	for i,animation in ipairs(type(animation) == "table" and animation or {{animation, time}}) do
		local anim = object.animations[animation[1]]
		local length = object.animationLengths[animation[1]]
		local time = animation[2] or 0
		local blend = animation[3] or i > 1 and 1 / i
		assert(anim and length, "animation is nil, is the name correct?")
		
		for joint,frames in pairs(anim) do
			if not animation[4] or animation[4][joint] then
				--general data
				local start = frames[1].time
				local t = (time == length and time or time % length) + start
				
				--find two frames
				local f1 = frames[1]
				local f2 = frames[2]
				for f = 2, #frames do
					if frames[f].time >= t then
						f1 = frames[f-1]
						f2 = frames[f]
						break
					end
				end
				
				--get interpolation factor
				local diff = (f2.time - f1.time)
				local factor = diff == 0 and 0.5 or (t - f1.time) / diff
				local f = interpolateFrames(f1, f2, factor)
				if blend then
					pose[joint] = interpolateFrames(pose[joint], f, blend)
				else
					pose[joint] = f
				end
			end
		end
	end
	
	return pose
end

--apply the pose to the joints
local identity = mat4:getIdentity()
function lib:applyPose(object, pose, skeleton, parentTransform)
	if not skeleton then
		assert(object.skeleton, "object requires a skeleton")
		object.boneTransforms = { }
		for name,_ in pairs(object.joints) do
			object.boneTransforms[name] = identity
		end
	end
	
	for name,joint in pairs(skeleton or object.skeleton) do
		local poseTransform = mat4:getTranslate(pose[name].position) * pose[name].rotation:toMatrix()
		local localTransform = parentTransform and parentTransform * poseTransform or poseTransform
		object.boneTransforms[name] = localTransform * joint.inverseBindTransform
		
		if joint.children then
			self:applyPose(object, pose, joint.children, localTransform)
		end
	end
end

--all in one
function lib:setPose(object, animation, time)
	local p = self:getPose(object, animation, time)
	self:applyPose(object, p)
end

--apply joints to mesh data directly
function lib:applyJoints(object)
	if object.class == "object" then
		for _,o in pairs(object.objects) do
			self:applyJoints(o)
		end
	elseif object.class == "mesh" then
		if object.joints then
			--make a copy of vertices
			if not object.verticesOld then
				object.verticesOld = object.vertices
				object.normalsOld = object.normals
				object.vertices = { }
				object.normals = { }
			end
			
			--apply joint transforms
			for i,v in ipairs(object.verticesOld) do
				local m = lib:getJointMat(object, i)
				object.vertices[i] = m * vec3(v)
				object.normals[i] = m:subm() * vec3(object.normalsOld[i])
			end
		end
	else
		error("object or mesh expected")
	end
end

function lib:getJointMat(o, i)
	local obj = o.obj
	if obj.boneTransforms then
		local m = mat4()
		for jointNr = 1, #o.joints[i] do
			local joint = o.jointIDs[ o.joints[i][jointNr] ]
			m = m + obj.boneTransforms[ joint ] * o.weights[i][jointNr]
		end
		return m
	else
		return mat4:getIdentity()
	end
end