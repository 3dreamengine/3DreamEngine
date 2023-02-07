local meta = { }

function meta:push(key, value)
	if self[key] then
		table.insert(self[key], value)
	else
		self[key] = { value }
	end
end

function meta:pop(key)
	if self[key] then
		local v = table.remove(self[key])
		if #self[key] == 0 then
			self[key] = nil
		end
		return v
	end
end

meta.__index = meta

return function()
	return setmetatable({ cache = {} }, meta)
end