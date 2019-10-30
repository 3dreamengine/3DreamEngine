--[[
#part of the 3DreamEngine by Luke100000
bones.lua - returns transformations for each sub object based on its bones (unfinished yet)
--]]

local lib = _3DreamEngine

function lib.getBoneTransformations(self, obj)
	local bones = { }
	for d,s in pairs(obj.bones) do
		bones[d] = {
			x = 0,
			y = 0,
			z = 0,
			rotation = matrix{
				{1, 0, 0},
				{0, 1, 0},
				{0, 0, 1},
			}
		}
	end

	--move
	local todo = {obj.bones.root.mountedBy}
	while #todo > 0 do
		local old = todo
		todo = { }
		for _,sp in ipairs(old) do
			for _,d in ipairs(sp) do
				local s = obj.bones[d]
				local ms = obj.bones[s.mount]
				todo[#todo+1] = s.mountedBy
				if s.mount ~= "root" then
					--move
					local ox, oy, oz = unpack(bones[s.mount].rotation * (matrix{{s.x - ms.x, s.y - ms.y, s.z - ms.z}}^"T"))
					bones[d].x = bones[s.mount].x + ox[1]
					bones[d].y = bones[s.mount].y + oy[1]
					bones[d].z = bones[s.mount].z + oz[1]
					
					local rx, ry, rz = s.rotationX, s.rotationY, s.rotationZ
					
					--local space
					local cc = math.cos(s.initRotationX)
					local ss = math.sin(s.initRotationX)
					local rotX = matrix{
						{1, 0, 0},
						{0, cc, -ss},
						{0, ss, cc},
					}
					
					local cc = math.cos(s.initRotationY)
					local ss = math.sin(s.initRotationY)
					local rotY = matrix{
						{cc, 0, -ss},
						{0, 1, 0},
						{ss, 0, cc},
					}
					
					local localSpace = rotY * rotX
					
					--to local space
					bones[d].rotation = localSpace * bones[d].rotation
					
					
					--rotate
					local cc = math.cos(rx or 0)
					local ss = math.sin(rx or 0)
					local rotX = matrix{
						{1, 0, 0},
						{0, cc, -ss},
						{0, ss, cc},
					}
					
					local cc = math.cos(ry or 0)
					local ss = math.sin(ry or 0)
					local rotY = matrix{
						{cc, 0, -ss},
						{0, 1, 0},
						{ss, 0, cc},
					}
					
					local cc = math.cos(rz or 0)
					local ss = math.sin(rz or 0)
					local rotZ = matrix{
						{cc, ss, 0},
						{-ss, cc, 0},
						{0, 0, 1},
					}
					
					bones[d].rotation = rotX * rotY * rotZ * bones[d].rotation
					
					--back to global space
					bones[d].rotation = localSpace:transpose() * bones[d].rotation
					
					
					--add mount bone rotation
					bones[d].rotation = bones[s.mount].rotation * bones[d].rotation
				end
			end
		end
	end

	for d,s in pairs(obj.bones) do
		local b = bones[d]
		local r = b.rotation
		
		local rotate = matrix{
			{r[1][1], r[1][2], r[1][3], 0},
			{r[2][1], r[2][2], r[2][3], 0},
			{r[3][1], r[3][2], r[3][3], 0},
			{0, 0, 0, 1},
		}
		
		local center = matrix{
			{1, 0, 0, -s.x},
			{0, 1, 0, -s.y},
			{0, 0, 1, -s.z},
			{0, 0, 0, 1},
		}
		
		local translate = matrix{
			{1, 0, 0, b.x},
			{0, 1, 0, b.y},
			{0, 0, 1, b.z},
			{0, 0, 0, 1},
		}
		
		bones[d] = translate * rotate * center
	end
	
	return bones
end

return bones