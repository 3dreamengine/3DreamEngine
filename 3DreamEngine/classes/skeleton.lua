local lib = _3DreamEngine

local function verfiyBones(bones)
	for _, bone in pairs(bones) do
		bone.transform = bone.transform and mat4(bone.transform)
		if bone.children then
			verfiyBones(bone.children)
		end
	end
end

function lib:newSkeleton(bones)
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
		if pose[name] then
			local poseTransform = pose[name].rotation:toMatrix()
			local pos = pose[name].position
			poseTransform[4] = pos[1]
			poseTransform[8] = pos[2]
			poseTransform[12] = pos[3]
			self.transforms[name] = parentTransform and parentTransform * poseTransform or poseTransform
		else
			self.transforms[name] = parentTransform and (parentTransform * joint.transform) or joint.transform
		end
		
		if joint.children then
			self:applyPoseToNode(joint.children, pose, self.transforms[name])
		end
	end
end

--apply the pose to the skeleton
function class:applyPose(pose)
	self.transforms = { }
	self:applyPoseToNode(self.bones, pose, false)
end

function class:getTransform(name)
	return self.transforms[name]
end

return class