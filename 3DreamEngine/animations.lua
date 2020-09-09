--[[
#part of the 3DreamEngine by Luke100000
functions.lua - contains library relevant functions
--]]

local lib = _3DreamEngine

--helper function to interpolate and set the pose
local function animToPose(a, time, pose)
	assert(a, "animation is nil")
	for d,s in pairs(a) do
		if s.frames then
			local lf = s.frames[#s.frames]
			local t = time % lf.time
			local frames = {lf, lf}
			for f = 1, #s.frames do
				if s.frames[f].time > t then
					frames = {s.frames[f-1] or s.frames[1], s.frames[f]}
					break
				end
			end
			
			--get interpolation factor
			local diff = (frames[2].time - frames[1].time)
			local factor = diff == 0 and 0 or (t - frames[1].time) / diff
			
			local position = frames[1].position * (1.0 - factor) + frames[2].position * factor
			local rotation = frames[1].rotation:nLerp(frames[2].rotation, factor)
			
			pose[s.joint] = {
				position = position,
				rotation = rotation,
			}
		else
			animToPose(s, time, pose)
		end
	end
end

--returns a new animated pose at a specific time stamp
function lib:getPose(object, time)
	local pose = { }
	
	--create rest pose
	for name,_ in pairs(object.joints) do
		pose[name] =  {
			position = vec3(0, 0, 0),
			rotation = quat(1, 0, 0, 0),
		}
	end
	
	--get frame of animation
	animToPose(object.animations, time, pose)
	
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
function lib:setPose(object, time)
	self:applyPose(object, self:getPose(object, time))
end

--apply 
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