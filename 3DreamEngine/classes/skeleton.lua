local lib = _3DreamEngine

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

function class:print(tabs)
	tabs = tabs or 0
	local indent = string.rep("  ", tabs + 1)
	local indent2 = string.rep("  ", tabs + 2)
	
	--general innformation
	print(string.rep("  ", tabs) .. self.name)
	
	--print objects
	local width = 48
	if next(self.meshes) then
		print(indent .. "meshes")
		print(indent2 .. "name " .. string.rep(" ", width-9) .. "tags LOD     V R S  vertexcount")
	end
	for _,m in pairs(self.meshes) do
		--to array
		local tags = { }
		for d,s in pairs(m.tags) do
			table.insert(tags, tostring(d))
		end
		
		--data to display
		local tags = table.concat(tags, ", "):sub(1, width)
		local min, max = m:getLOD()
		local lod = max and (min .. " - " .. max) or ""
		local visibility = (m.visible ~= false and "X" or " ") .. " " .. (m.renderVisibility ~= false and "X" or " ") .. " " .. (m.shadowVisibility ~= false and "X" or " ")
		
		--final string
		local vertexCount = (m.mesh and m.mesh.getVertexCount and m.mesh:getVertexCount() or "")
		local str = m.name .. string.rep(" ", width - #tags - #m.name) .. tags .. " " .. lod .. string.rep(" ", 8 - #lod) .. visibility .. "  " .. vertexCount
		
		--merge meshes
		print(indent2 .. str)
	end
	
	--physics
	if next(self.physics) then
		print(indent .. "physics")
		local count = { }
		for d,s in pairs(self.physics or { }) do
			print(indent2 .. tostring(s.name))
		end
	end
	
	--lights
	if next(self.lights) then
		print(indent .. "lights")
		for d,s in pairs(self.lights) do
			print(indent2 .. tostring(s.name) .. "  " .. s.brightness)
		end
	end
	
	--positions
	if next(self.positions) then
		print(indent .. "positions")
		for d,s in pairs(self.positions) do
			print(indent2 .. tostring(s.name) .. string.format("  %f, %f, %f", s.x, s.y, s.z))
		end
	end
	
	--skeleton
	if self.skeleton then
		print(indent .. "skeleton")
		local function p(s, indent)
			for i,v in pairs(s) do
				print(indent .. v.name)
				if v.children then
					p(v.children, "  " .. indent)
				end
			end
		end
		p(self.skeleton, indent2)
	end
	
	--animations
	if next(self.animations) then
		print(indent .. "animations")
		for d,s in pairs(self.animations) do
			print(indent2 .. string.format("%s: %.1f sec", d, s.length))
		end
	end
	
	--print objects
	if next(self.objects) then
		print(indent .. "objects")
		for _,o in pairs(self.objects) do
			o:print(tabs + 2)
		end
	end
end

return class