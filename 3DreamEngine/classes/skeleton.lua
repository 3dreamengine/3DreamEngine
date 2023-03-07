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
function class:applyPoseToNode(node, pose, parentTransform)
	if pose[node.name] then
		local poseTransform = pose[node.name].rotation:toMatrix()
		local pos = pose[node.name].position
		poseTransform[4] = pos[1]
		poseTransform[8] = pos[2]
		poseTransform[12] = pos[3]
		self.transforms[node.name] = parentTransform and (parentTransform * poseTransform) or poseTransform
	else
		self.transforms[node.name] = parentTransform and (parentTransform * node.transform) or node.transform
	end
	
	if node.children then
		for _, child in pairs(node.children) do
			self:applyPoseToNode(child, pose, self.transforms[node.name])
		end
	end
end

---Apply the pose to the skeleton
function class:applyPose(pose)
	self.transforms = { }
	self:applyPoseToNode(self.root, pose, false)
end

---Get the transformation matrix for a given joint name
---@param name string
---@return DreamMat4
function class:getTransform(name)
	return self.transforms[name]
end

return class