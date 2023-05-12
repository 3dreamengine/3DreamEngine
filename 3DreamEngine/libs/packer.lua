--[[
Iteratively packs rectangles on a larger rectangle.

--Creates a 256 by 256 canvas
local packer = require("packer")(256, 256)

--Place a sprite, will return false if no fitting space has been found
local x, y = packer(64, 64)
--]]

local function findChunk(space, w, h)
	if space.children then
		for i, c in ipairs(space.children) do
			if c.w >= w and c.h >= h then
				if c.children then
					local x, y = findChunk(c, w, h)
					if x then
						if #c.children == 0 then
							table.remove(space.children, i)
						elseif #c.children == 1 then
							space.children[i] = c
						end
						return x, y
					end
				elseif c.w == w and c.h == h then
					table.remove(space.children, i)
					return c.x, c.y
				else
					local x, y = c.x, c.y
					
					if c.w == w then
						c.y = c.y + h
						c.h = c.h - h
					elseif c.h == h then
						c.x = c.x + w
						c.w = c.w - w
					elseif c.w - w > c.h - h then
						c.children = {
							{
								x = c.x,
								y = c.y + h,
								w = w,
								h = c.h - h,
							}, {
								x = c.x + w,
								y = c.y,
								w = c.w - w,
								h = c.h,
							}
						}
					else
						c.children = {
							{
								x = c.x + w,
								y = c.y,
								w = c.w - w,
								h = h,
							}, {
								x = c.x,
								y = c.y + h,
								w = c.w,
								h = c.h - h,
							}
						}
					end
					
					return x, y
				end
			end
		end
	end
	return false, false
end

local function extend(self, width, height)
	self.width = self.width + width
	self.height = self.height + height
	
	if width > 0 then
		table.insert(self.children, {
			x = self.width - width,
			y = 0,
			w = width,
			h = self.height
		})
	end
	
	if height > 0 then
		table.insert(self.children, {
			x = 0,
			y = self.height - height,
			w = self.width,
			h = height
		})
	end
end

local meta = {
	__call = findChunk,
	__index = {
		extend = extend
	}
}

return function(width, height)
	return setmetatable({
		width = width,
		height = height,
		children = {
			{
				x = 0,
				y = 0,
				w = width,
				h = height,
			}
		}
	}, meta)
end