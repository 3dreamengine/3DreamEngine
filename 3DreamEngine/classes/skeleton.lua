local lib = _3DreamEngine

function lib:newSkeleton(root)
	return setmetatable({
		root = root,
		transforms = false,
	}, self.meta.skeleton)
end

local class = {
	link = { "skeleton" },
}

--apply the pose to the joints
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

--apply the pose to the skeleton
function class:applyPose(pose)
	self.transforms = { }
	self:applyPoseToNode(self.root, pose, false)
end

function class:getTransform(name)
	return self.transforms[name]
end

return class