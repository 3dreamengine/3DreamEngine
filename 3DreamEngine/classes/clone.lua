return {
	link = {},
	
	clone = function(self)
		local n = { }
		for d,s in pairs(self) do
			n[d] = s
		end
		
		--clone meshes too such that their parent reference works again
		print("object:clone() not done yet, parent reference obj is weird, consider removal")
		if n.objects then
			local o = n.objects
			n.objects = { }
			for d,s in pairs(o) do
				n.objects[d] = s:clone()
				n.objects[d].obj = n
			end
		end
		
		--allow this material to be added somewhere else
		n.registeredAs = nil
		
		return setmetatable(n, getmetatable(self))
	end,
}