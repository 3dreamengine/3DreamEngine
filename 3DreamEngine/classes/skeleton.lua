local lib = _3DreamEngine

local function verfiyBones(bones)
	for _, bone in pairs(bones) do
		bone.bindTransform = mat4(bone.bindTransform)
		bone.inverseBindTransform = mat4(bone.inverseBindTransform)
		
		if bone.children then
			verfiyBones(bone.children)
		end
	end
end

function lib:newSkeleton(bones, jointMapping)
	local c = 0
	local function count(n)
		c = c + 1
		if n.children then
			for _,s in pairs(t.children) do
				count(s)
			end
		end
	end
	
	verfiyBones(bones)
	
	return setmetatable({
		bones = bones,
		transforms = false,
		jointMapping = jointMapping,
		bonesCount = c,
	}, self.meta.skeleton)
end

local class = {
	link = {"clone", "skeleton"},
	
	setterGetter = {
		bonesCount = "getter",
	},
}
 
function class:tostring()
	return string.format("skeleton (%d bones)", self:getBonesCount())
end

--apply the pose to the joints
function class:applyPoseToNode(nodes, pose, parentTransform)
	for name,joint in pairs(nodes) do
		local index = self.jointMapping[name]
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
				self.transforms[index] = transform * joint.inverseBindTransform
			else
				self.transforms[index] = joint.inverseBindTransform
			end
		end
		
		if joint.children then
			self:applyPoseToNode(joint.children, pose, transform)
		end
	end
end

--apply the pose to the skeleton
function class:applyPose(pose)
	self.transforms = { }
	self:applyPoseToNode(self.bones, pose)
end

function class:getTransform(name)
	return self.transforms[self.jointMapping[name]]
end

return class