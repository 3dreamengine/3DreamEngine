local class = {
	link = { },
}

function class:clone()
	local n = { }
	
	for d,s in pairs(self) do
		if type(s) == "table" and type(s.clone) == "function" then
			n[d] = s:clone()
		else
			n[d] = s
		end
	end
	
	return setmetatable(n, getmetatable(self))
end

return class