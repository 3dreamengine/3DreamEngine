--[[
#part of the 3DreamEngine by Luke100000
compiler.lua - compiles shader objects to GLSL
--]]

local lib = _3DreamEngine

function lib:getShaderNodeOutputType(nodes, input)
	if input then
		local n = nodes[input.nid]
		return n.genericType or lib.shaderNodes[n.typ].outputs[input.i][2]
	else
		return false
	end
end

--create a new line
local function br(code)
	table.insert(code, "")
end

--generates code from all nodes for a given function
local function buildDefines(shader, nodes, code)
	for nid,node in pairs(nodes) do
		local dat = lib.shaderNodes[node.typ]
		if dat.defines then
			table.insert(code, "//node: " .. node.typ)
			local c = dat.defines(lib, shader, nodes, node)
			c = c:gsub("@", "var_" .. nid)
			table.insert(code, c)
			br(code)
		end
	end
end

local function buildCode(dream, shader, originalNodes, code)
	--insert sort
	local nodes = { }
	local nodesOrdered = { }
	local changes = true
	while changes do
		changes = false
		for nid,node in pairs(originalNodes) do
			if not nodes[nid] then
				--check if dependencies work
				local valid = true
				for _,input in pairs(node.inputs) do
					if not nodes[input.nid] then
						valid = false
						break
					end
				end
				
				--insert
				if valid then
					nodes[nid] = node
					table.insert(nodesOrdered, {nid, node})
					changes = true
					
					--if this node has a generic type, calculate it now
					node.genericType = nil
					local dat = dream.shaderNodes[node.typ]
					if dat.getGenericType then
						node.genericType = dat.getGenericType(dream, shader, originalNodes, node)
					end
				end
			end
		end
	end
	
	--construct 
	for _,s in ipairs(nodesOrdered) do
		local nid, node = s[1], s[2]
		
		table.insert(code, "//node: " .. node.typ)
		
		local dat = dream.shaderNodes[node.typ]
		
		--define output vars
		if not dat.unique then
			local defined = { }
			for _,out in ipairs(dat.outputs) do
				local name = out[3] or out[1]
				if not defined[name] then
					defined[name] = true
					local typ = dat.getGenericType and dat.getGenericType(dream, shader, originalNodes, node) or out[2]
					table.insert(code, typ .. " var_" .. nid .. "_" .. name .. ";")
				end
			end
		end
		
		--create code
		if not dat.global then
			table.insert(code, "{")
		end
		if dat.build then
			local c = dat.build(dream, shader, originalNodes, node)
			
			--insert input names or constants
			for i,input in ipairs(dat.inputs) do
				local connection = node.inputs[i]
				local value
				if connection then
					--var
					local n = originalNodes[connection.nid]
					local da = dream.shaderNodes[n.typ]
					local out = da.outputs[connection.i]
					local name = out[3] or out[1]
					if da.unique then
						value = (da.getVarName and da.getVarName(dream, shader, originalNodes, n, connection.i) or name) .. (out[3] and "." .. out[1] or "")
					else
						value = "var_" .. connection.nid .. "_" .. name .. (out[3] and "." .. out[1] or "")
					end
				else
					--constant
					local v = input[3]
					if type(v) == "table" then
						value = "vec" .. #v .. "(" .. string.format(#v == 2 and "%f, %f" or #v == 3 and "%f, %f, %f" or "%f, %f, %f, %f", unpack(node.values[i])) .. ")"
					else
						value = string.format("%f", node.values[i])
					end
				end
				
				c = c:gsub("@" .. input[1], value)
			end
			
			--insert output names
			for _,out in ipairs(dat.outputs) do
				local name = out[3] or out[1]
				c = c:gsub("@" .. name, "var_" .. nid .. "_" .. name)
			end
			
			c = c:gsub("@", "var_" .. nid)
			
			table.insert(code, c)
		end
		if not dat.global then
			table.insert(code, "}")
		end
		
		br(code)
	end
end

function lib:compileShader(shader)
	local defines = { }
	local pixel = { }
	local vertex = { }
	
	shader.cache = { }
	
	--defines
	table.insert(defines, "//global defines")
	buildDefines(shader, shader.pixel, defines)
	buildDefines(shader, shader.vertex, defines)
	
	--pixel shader code
	buildCode(self, shader, shader.pixel, pixel)
	
	--start of vertex shader
	buildCode(self, shader, shader.vertex, vertex)
	
	return table.concat(defines, "\n"), table.concat(pixel, "\n"), table.concat(vertex, "\n")
end