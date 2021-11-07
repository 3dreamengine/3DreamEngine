--[[
#part of the 3DreamEngine by Luke100000
animations.lua - contains animation and skeletal relevant functions
--]]

local lib = _3DreamEngine

--linear interpolation of position and rotatation between two frames
local function interpolateFrames(f1, f2, factor)
	return {
		position = f1.position * (1.0 - factor) + f2.position * factor,
		rotation = f1.rotation:nLerp(f2.rotation, factor),
	}
end

--returns a new animated pose at a specific time stamp
function lib:getPose(animation, time)
	local animation = time and {{animation, time}} or animation
	local pose = { }
	
	--get frame of animation
	for i,animation in ipairs(animation) do
		local anim = animation[1]
		local time = animation[2] or 0
		local blend = animation[3] or i > 1 and 1 / i
		assert(anim, "animation is nil, is the name correct?")
		for joint,frames in pairs(anim.frames) do
			if not animation[4] or animation[4][joint] then
				local t = time == anim.length and time or time % anim.length
				
				--find two frames
				--todo slow, some sort of indexing required
				local f1 = frames[1]
				local f2 = frames[2]
				local lu = anim.lookup[joint]
				for f = lu[math.ceil(t / anim.length * #lu)] or 2, #frames do
					if frames[f].time >= t then
						f1 = frames[f-1]
						f2 = frames[f]
						break
					else
						error()
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
		skeleton = object.skeleton
	end
	
	for name,joint in pairs(skeleton) do
		local index = object.jointMapping[name]
		local transform
		if pose[name] then
			local poseTransform = pose[name].rotation:toMatrix()
			local pos = pose[name].position
			poseTransform[4] = pos[1]
			poseTransform[8] = pos[2]
			poseTransform[12] = pos[3]
			transform = parentTransform and parentTransform * poseTransform or poseTransform
		else
			transform = parentTransform
		end
		
		if index then
			if transform then
				object.boneTransforms[index] = transform * joint.inverseBindTransform
			else
				object.boneTransforms[index] = joint.inverseBindTransform
			end
		end
		
		if joint.children then
			self:applyPose(object, pose, joint.children, transform)
		end
	end
end

--all in one
function lib:setPose(object, animation, time)
	local p = self:getPose(animation, time)
	self:applyPose(object, p)
end

--apply joints to mesh data directly
function lib:applyJoints(object)
	if object.class == "object" then
		for _,m in pairs(object.meshes) do
			self:applyJoints(m)
		end
		
		--also apply to children
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

--todo outdated
function lib:getJointMat(mesh, i)
	if mesh.boneTransforms then
		local m = mat4()
		for jointNr = 1, #mesh.joints[i] do
			m = m + mesh.boneTransforms[ mesh.joints[i][jointNr] ] * mesh.weights[i][jointNr]
		end
		return m
	else
		return mat4:getIdentity()
	end
end