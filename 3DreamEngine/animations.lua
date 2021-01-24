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
function lib:getPose(object, time, animation)
	local pose = { }
	
	--create rest pose
	for name,_ in pairs(object.joints) do
		pose[name] =  {
			position = vec3(0, 0, 0),
			rotation = quat(1, 0, 0, 0),
		}
	end
	
	--get frame of animation
	local anim = object.animations[animation or "default"]
	local length = object.animationLengths[animation or "default"]
	assert(anim and length, "animation is nil")
	for joint,frames in pairs(anim) do
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
		pose[joint] = interpolateFrames(f1, f2, factor)
	end
	
	return pose
end

--apply the pose to the joints
local identity = mat4:getIdentity()
function lib:applyPose(object, pose, skeleton, parentTransform)
	if not skeleton then
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
function lib:setPose(object, time, first, second, blend)
	local p = self:getPose(object, time, first)
	if second then
		local p2 = self:getPose(object, time, second)
		for joint,frame in pairs(p) do
			p[joint] = interpolateFrames(frame, p2[joint], math.clamp(blend, 0.0, 1.0))
		end
	end
	self:applyPose(object, p)
end

--apply joints to mesh data directly
function lib:applyJoints(object)
	if object.class == "object" then
		for _,o in pairs(object.objects) do
			self:applyJoints(o)
		end
	elseif object.class == "subObject" then
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
		error("object or subObject expected")
	end
end

function lib:getJointMat(o, i)
	local m = mat4()
	local obj = o.obj
	for jointNr = 1, #o.joints[i] do
		local joint = o.jointIDs[ o.joints[i][jointNr] ]
		m = m + obj.boneTransforms[ joint ] * o.weights[i][jointNr]
	end
	return m
end