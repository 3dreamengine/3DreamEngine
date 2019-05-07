--[[
#3de - 3Dream Bones - bones
transforms a multi-mesh object and bounds it to the skeleton

#bone name | root bone | end xyz position |optional xyz start position, default to 0 0 0 (end pos of root bone)
--]]

_3DreamEngine.loader["3db"] = function(self, obj, name, path)
	local mat
	for l in (love.filesystem.getInfo(self.objectDir .. name .. ".3db") and love.filesystem.lines(self.objectDir .. name .. ".3db") or love.filesystem.lines(name .. ".3db")) do
		if l:sub(1, 1) ~= "#" then
			
		end
	end
end