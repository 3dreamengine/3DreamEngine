local class = {
	link = { },
}

function class:clone()
	local n = { }
	for d,s in pairs(self) do
		n[d] = s
	end
	
	--allow this material to be added somewhere else
	n.registeredAs = nil
	
	return setmetatable(n, getmetatable(self))
end

return class