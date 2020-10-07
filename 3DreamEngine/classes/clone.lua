return {
	link = {},
	
	clone = function(self)
		local n = { }
		for d,s in pairs(self) do
			n[d] = s
		end
		return setmetatable(n, getmetatable(self))
	end,
}