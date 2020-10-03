--[[
#part of the 3DreamEngine by Luke100000
functions.lua - contains library relevant functions
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
	local anim = object.animations[animation]
	local length = object.animationLengths[animation]
	assert(anim and length, "animation is nil")
	for joint,frames in pairs(anim) do
		--general data
		local start = frames[1].time
		local t = time % length + start
		
		--find two frames
		local f1 = frames[1]
		local f2 = frames[2]
		for f = 2, #frames do
			if frames[f].time > t then
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
		local localTransform = (parentTransform or mat4:getIdentity()) * poseTransform
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
function lib:applyJoints(obj)
	for _,o in pairs(obj.objects) do
		if o.joints then
			--make a copy of vertices
			if not o.verticesOld then
				o.verticesOld = o.vertices
				o.normalsOld = o.normals
				o.vertices = { }
				o.normals = { }
			end
			
			--apply joint transforms
			for i,v in ipairs(o.verticesOld) do
				local m = mat4()
				for jointNr = 1, #o.joints[i] do
					local joint = o.jointIDs[ o.joints[i][jointNr] ]
					m = m + obj.boneTransforms[ joint ] * o.weights[i][jointNr]
				end
				
				o.vertices[i] = m * vec3(v)
				o.normals[i] = m:subm() * vec3(o.normalsOld[i])
			end
			
			--recreate mesh
			dream:createMesh(o)
		end
	end
end