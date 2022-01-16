local utils = {
	filesystem = { },
	table = { },
	string = { },
	math = { },
}

-- FILE SYSTEM --
-- love dependency
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
--merge two tables into the first
function utils.table.merge(first, second, cycles)
	cycles = cycles or { }
	if cycles[first] then
		return first
	end
	cycles[first] = true
	for k,v in pairs(second) do
		if type(v) == "table" then
			if type(first[k]) == type(v) then
				utils.table.merge(first[k], v, cycles)
			else
				first[k] = v
			end
		else
			first[k] = v
		end
	end
	return first
end

--merge two tables into the first, but stops at the first cycle
function utils.table.mergeCycles(first, second, cycles)
	cycles = cycles or { }
	cycles[second] = true
	for k,v in pairs(second) do
		if type(v) == "table" then
			if not first[k] then
				first[k] = v
			elseif not cycles[v] then
				utils.table.mergeCycles(first[k], v)
			end
		else
			first[k] = v
		end
	end
	return first
end

--copy a table
function utils.table.copy(first_table)
	local second_table = { }
	for k,v in pairs(first_table) do
		if type(v) == "table" then
			second_table[k] = utils.table.copy(v)
		else
			second_table[k] = v
		end
	end
	return second_table
end

--copy a table, supports metatables and recursions
function utils.table.deepCopy(value, cycles)
    cycles = cycles or { }
    if type(value) == "table" then
        if cycles[value] then
            return cycles[value]
        else
            local copy = { }
            cycles[value] = copy
            for k, v in next, value do
                copy[utils.table.deepCopy(k, cycles)] = utils.table.deepCopy(v, cycles)
            end
			local meta = utils.table.deepCopy(getmetatable(value), cycles)
            return setmetatable(copy, meta)
        end
    else
        return value
    end
end

--copies a table, ignores complex objects
local valid = {
	number = true,
	string = true,
	boolean = true,
}
function utils.table.primitiveCopy(value, cycles)
    cycles = cycles or { }
    if type(value) == "table" then
        if cycles[value] then
            return cycles[value]
        else
            local copy = { }
            cycles[value] = copy
            for k, v in next, value do
				if valid[type(k)] and (valid[type(v)] or type(v) == "table") then
					copy[k] = utils.table.primitiveCopy(v, cycles)
				end
            end
            return copy
        end
    else
        return value
    end
end

--flat copy a table
function utils.table.flatCopy(first_table)
	local second_table = { }
	for k,v in pairs(first_table) do
		second_table[k] = v
	end
	return second_table
end

--print a table
function utils.table.print(t, tab)
	if not tab then
		print()
	end
	tab = tab or 0
	for d,s in pairs(t) do
		local p = string.rep(" ", tab*2) .. (next(t, d) and "├─" or "└─") .. tostring(d)
		if type(s) == "table" then
			print(p)
			utils.table.print(s, tab+1)
		else
			print(p .. " = " .. tostring(s))
		end
	end
end

--invert indices and values to produce a set
function utils.table.toSet(t)
	local n = { }
	for d,s in ipairs(t) do
		n[s] = d
	end
	return n
end

--finds a value in a table and returns its index, or false of not present
function utils.table.find(t, v)
	for d,s in pairs(t) do
		if s == v then
			return d
		end
	end
	return false
end


-- STRING --
function utils.string.split(text, sep)
	local sep, fields = sep or ":", { }
	local pattern = string.format("([^%s]+)", sep)
	text:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

--formats a value of type "bytes", "bits" or "number" with given exponent (or 1000) and decimal places (number type only)
local prefix_l = {"k", "M", "G", "T", "P", "E", "Z", "Y"}
local prefix_s = {"m", "μ", "n", "p", "f", "a", "z", "y"}
function utils.string.formatSize(value, typ, exp, decimals)
	exp = exp or 1000
	typ = typ or "number"
	
	local sign = utils.math.sign(value)
	value = math.abs(value)
	local factor = 0
	while value > exp do
		value = value / exp
		factor = factor + 1
	end
	while value < 1.0 do
		value = value * exp
		factor = factor - 1
	end
	if sign < 0 then
		value = -value
	end
	
	if typ == "bytes" then
		value = math.floor(value+0.5)
		if factor == 0 then
			return tostring(value) .. " B"
		elseif factor < 0 then
			return tostring("0 B")
		else
			return tostring(value) .. " " .. (prefix_l[factor] or "?") .. (exp == 1024 and "iB" or "B")
		end
	elseif typ == "bits" then
		value = math.floor(value+0.5)
		if factor == 0 then
			return tostring(value) .. " b"
		elseif factor < 0 then
			return tostring("0 b")
		else
			return tostring(value) .. " " .. (prefix_l[factor] or "?") .. (exp == 1024 and "ibit" or "bit")
		end
	elseif typ == "number" then
		value = utils.math.round(value, decimals or 2)
		if factor == 0 then
			return tostring(value)
		else
			return tostring(value) .. " " .. (factor > 0 and prefix_l[factor] or prefix_s[-factor] or "?")
		end
	else
		value = utils.math.round(value, decimals or 2)
		return value, factor
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


--merge utils into lua tables
for _,s in ipairs({"table", "string", "math"}) do
	setmetatable(_G[s], {__index = utils[s]})
end

return utils