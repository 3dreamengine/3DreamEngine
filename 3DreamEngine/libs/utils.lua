local utils = {
	filesystem = { },
	table = { },
	string = { },
	math = { },
}

function utils.printTable(t, tab)
	if not tab then
		print()
	end
	tab = tab or 0
	local count = 0
	for d,s in pairs(t) do
		count = count + 1
	end
	for d,s in pairs(t) do
		count = count - 1
		if type(s) == "table" then
			print(string.rep(" ", tab*2) .. (count == 0 and "└─" or "├─") .. tostring(d))
			utils.printTable(s, tab+1)
		else
			print(string.rep(" ", tab*2) .. (count == 0 and "└─" or "├─") .. tostring(d) .. " = " .. tostring(s))
		end
	end
end

-- FILE SYSTEM --
--recursively delete files
function utils.filesystem.removeRecursive(item)
    if love.filesystem.getInfo(item, "directory") then
        for _, child in pairs(love.filesystem.getDirectoryItems(item)) do
            utils.filesystem.removeRecursive(item .. '/' .. child)
        end
    end
    love.filesystem.remove(item)
end

function utils.filesystem.getSize(item)
	if love.filesystem.getInfo(item, "directory") then
		local size = 0
        for _, child in pairs(love.filesystem.getDirectoryItems(item)) do
            size = size + utils.filesystem.getSize(item .. '/' .. child)
        end
		return size
	else
		local i = love.filesystem.getInfo(item)
		return i and i.size or 0
	end
end

-- TABLE --
function utils.table.merge(first_table, second_table)
	for k,v in pairs(second_table) do
		if type(v) == "table" then
			if not first_table[k] then first_table[k] = { } end
			table.merge(first_table[k], v)
		else
			first_table[k] = v
		end
	end
	return first_table
end

function utils.table.copy(first_table)
	local second_table = { }
	for k,v in pairs(first_table) do
		if type(v) == "table" then
			second_table[k] = table.copy(v)
		else
			second_table[k] = v
		end
	end
	return second_table
end

local primitives = {["boolean"] = true, ["string"] = true, ["number"] = true}
function table.copyPrimitive(first_table)
	local second_table = { }
	for k,v in pairs(first_table) do
		if primitives[type(k)] then
			if type(v) == "table" then
				second_table[k] = table.copyPrimitive(v)
			elseif primitives[type(v)] then
				second_table[k] = v
			end
		end
	end
	return second_table
end

--invert indices and values to produce a set
function table.toSet(t)
	local n = { }
	for d,s in ipairs(t) do
		n[s] = d
	end
	return n
end

function table.find(t)
	for d,s in ipairs(t) do
		if s == t then
			return true
		end
	end
	return false
end

--http://lua-users.org/wiki/CopyTable
--supports metatables and recursions
function table.deepCopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


-- STRING --
function utils.string.split(text, sep)
	local sep, fields = sep or ":", { }
	local pattern = string.format("([^%s]+)", sep)
	text:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

local prefix_l = {"k", "M", "G", "T", "P", "E", "Z", "Y"}
local prefix_s = {"m", "μ", "n", "p", "f", "a", "z", "y"}
function utils.string.formatSize(size, decimals, typ, exp)
	exp = exp or 1000
	typ = typ or "number"
	factor = 0
	
	while size > exp do
		size = size / exp
		factor = factor + 1
	end
	
	while size < 1.0 do
		size = size * exp
		factor = factor - 1
	end
	
	if typ == "bytes" then
		size = math.floor(size+0.5)
		if factor == 0 then
			return tostring(size) .. " B"
		elseif factor < 0 then
			return tostring("0 B")
		else
			return tostring(size) .. " " .. (prefix_l[factor] or "?") .. (exp == 1024 and "iB" or "B")
		end
	elseif typ == "bits" then
		size = math.floor(size+0.5)
		if factor == 0 then
			return tostring(size) .. " b"
		elseif factor < 0 then
			return tostring("0 b")
		else
			return tostring(size) .. " " .. (prefix_l[factor] or "?") .. (exp == 1024 and "ibit" or "bit")
		end
	elseif typ == "number" then
		size = utils.math.round(size, decimals or 2)
		if factor == 0 then
			return tostring(size)
		else
			return tostring(size) .. " " .. (factor > 0 and prefix_l[factor] or prefix_s[-factor] or "?")
		end
	else
		size = utils.math.round(size, decimals or 2)
		return size, factor
	end
end


-- MATH --
function utils.math.round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function utils.math.mix(a, b, f)
	return a * (1.0 - f) + b * f 
end

function utils.math.clamp(v, a, b)
	return math.max(math.min(v, b or 1.0), a or 0.0)
end

function utils.math.sign(v)
	return v > 0 and 1 or v < 0 and -1 or 0
end


--merge utils into lua tables if wanted
if true then
	for d,s in ipairs({"table", "string", "math"}) do
		setmetatable(_G[s], {__index = utils[s]})
	end
end

return utils