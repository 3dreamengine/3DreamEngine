---@class Utils
local utils = { }

function utils:iterateCubesOnLine(ray_start, ray_end, callback)
	local current_index = { }
	local end_index = { }
	local step = { }
	local delta = { }
	local tMax = { }
	
	local direction = (ray_end - ray_start):normalize()
	local t1 = (ray_end - ray_start):length()
	
	for i = 1, 3 do
		current_index[i] = math.floor(ray_start[i])
		end_index[i] = math.floor(ray_end[i])
		if direction[i] > 0.0 then
			step[i] = 1
			delta[i] = 1 / direction[i]
			tMax[i] = (current_index[i] + 1 - ray_start[i]) / direction[i]
		elseif direction[i] < 0.0 then
			step[i] = -1
			delta[i] = -1 / direction[i]
			tMax[i] = (current_index[i] - ray_start[i]) / direction[i]
		else
			step[i] = 0
			delta[i] = t1
			tMax[i] = t1
		end
	end
	
	while current_index[1] ~= end_index[1] or current_index[2] ~= end_index[2] or current_index[3] ~= end_index[3] do
		if tMax[1] < tMax[2] and tMax[1] < tMax[3] then
			-- X-axis traversal.
			current_index[1] = current_index[1] + step[1]
			tMax[1] = tMax[1] + delta[1]
		elseif tMax[2] < tMax[3] then
			-- Y-axis traversal.
			current_index[2] = current_index[2] + step[2]
			tMax[2] = tMax[2] + delta[2]
		else
			-- Z-axis traversal.
			current_index[3] = current_index[3] + step[3]
			tMax[3] = tMax[3] + delta[3]
		end
		
		if callback(current_index[1], current_index[2], current_index[3]) then
			return
		end
	end
end

local segments = { }
local maxRadius = 30
for x = -maxRadius, maxRadius do
	for y = -maxRadius, maxRadius do
		for z = -maxRadius, maxRadius do
			table.insert(segments, { x, y, z, x ^ 2 + y ^ 2 + z ^ 2 })
		end
	end
end
table.sort(segments, function(a, b) return a[4] < b[4] end)

function utils:traverseSphere(x0, y0, z0, radius)
	local i = 0
	local r2 = radius ^ 2
	return function()
		i = i + 1
		local s = segments[i]
		if s[4] < r2 then
			return s[1] + x0, s[2] + y0, s[3] + z0
		end
	end
end

return utils