--[[
#dae - COLLADA
--]]

return function(self, obj, path)
	local xml2lua = require(self.root .. "/libs/xml2lua/xml2lua")
	local handler = require(self.root .. "/libs/xml2lua/tree"):new()
	handler.options.noreduce = {
		["geometry"] = true,
		["source"] = true,
		["input"] = true,
	}
	
	--load file
	local file = love.filesystem.read(path)
	
	--parse
	xml2lua.parser(handler):parse(file)
	
	local root = handler.root.COLLADA
	local geometry = root.library_geometries.geometry
	
	for d,s in pairs(geometry) do
		local o = self:newSubObject(s._attr.name, obj, self:newMaterial())
		obj.objects[o.name] = o
		
		--parse sources
		local sources = { }
		for i,v in pairs(s.mesh.source) do
			local t = { } 
			for w in v.float_array[1]:gmatch("%S+") do t[#t+1] = tonumber(w) end
			sources[v._attr.id]= t
		end
		if s.mesh.vertices then
			sources[s.mesh.vertices._attr.id] = sources[s.mesh.vertices.input[1]._attr.source:sub(2)]
		end
		
		--translation table
		local translate = {
			["VERTEX"] = "vertices",
			["NORMAL"] = "normals",
			["TEXCOORD"] = "texCoords",
			["COLOR"] = "colors",
		}
		
		--parse vertices
		local list = s.mesh.triangles or s.mesh.polylist
		
		--ids of source components per vertex
		local ids = { }
		for w in list.p:gmatch("%S+") do ids[#ids+1] = tonumber(w) end
		
		local fields = #list.input
		for d,s in ipairs(list.input) do
			local f = translate[s._attr.semantic]
			if f then
				for i = 1, #ids / fields do
					local id = ids[(i-1)*fields + tonumber(s._attr.offset) + 1]
					local s = sources[s._attr.source:sub(2)]
					if f == "texCoords" then
						o[f][i] = {
							s[id*2+1],
							s[id*2+2],
						}
					elseif f == "colors" then
						o[f][i] = {
							s[id*4+1],
							s[id*4+2],
							s[id*4+3],
							s[id*4+4],
						}
					else
						o[f][i] = {
							s[id*3+1],
							s[id*3+2],
							s[id*3+3],
						}
					end
				end
			end
		end
		
		--vertex count per polygon
		local vcount = { }
		if list.vcount then
			for w in list.vcount:gmatch("%S+") do vcount[#vcount+1] = tonumber(w) end
		end
		
		--parse polygons
		local count = list._attr.count
		local i = 1
		for face = 1, count do
			local verts = vcount[face] or 3
			if verts == 3 then
				--tris
				o.faces[#o.faces+1] = {i, i+1, i+2}
			else
				--triangulates, fan style
				for f = 1, verts-2 do
					o.faces[#o.faces+1] = {i, i+f, i+f+1}
				end
			end
			i = i + verts
		end
	end
end