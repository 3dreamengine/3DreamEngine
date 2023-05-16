---@type Dream
local lib = _3DreamEngine

---New skeleton from a hierarchical bone structure
---@param root DreamBone
---@return DreamSkeleton
function lib:newSkeleton(root)
	return setmetatable({
		root = root,
		transforms = false,
	}, self.meta.skeleton)
end

---Contains a hierarchical bone structure and the final transformation matrices for skinning when a pose has been applied
---@class DreamSkeleton
local class = {
	links = { "skeleton" },
}

---Apply the pose to the joints
---@private
---@param bone DreamBone
---@param pose DreamPose
---@param parentTransform DreamMat4
function class:applyPoseToBone(bone, pose, parentTransform)
	if pose[bone.id] then
		local poseTransform = pose[bone.id].rotation:toMatrix()
		local pos = pose[bone.id].position
		poseTransform[4] = pos[1]
		poseTransform[8] = pos[2]
		poseTransform[12] = pos[3]
		self.transforms[bone.id] = parentTransform and (parentTransform * poseTransform) or poseTransform
	else
		self.transforms[bone.id] = parentTransform and (parentTransform * bone.transform) or bone.transform
	end
	
	for _, child in ipairs(bone.children) do
		self:applyPoseToBone(child, pose, self.transforms[bone.id])
	end
end

---Apply the pose to the skeleton
---@param pose DreamPose
function class:applyPose(pose)
	self.transforms = { }
	self:applyPoseToBone(self.root, pose, false)
end

---Get the transformation matrix for a given joint name
---@param name string
---@return DreamMat4
function class:getTransform(name)
	return self.transforms[name]
end

return class