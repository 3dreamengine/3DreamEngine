--[[
#saveTable.lua
by Luke100000
version 1.5

encodes lua tables
supports numbers, strings and boolean as index or value
supports sub-tables
supports binary values in strings at the cost of performance

decodes itself with high performance using loadstring

supports fancy table output as a third argument

#changelog
#v1.5
now detects alphanumeric variable key to shorten the output

#v1.4
*added 'safe' fancyOutput, which won't escape dangerous characters. Usable when the user knows that the table does not contain such stuff
*added usePerLineFormating, formats flat tables more fancy (fancyOutput only)

#v1.3
*improved binary encoding for bytes over 128, doubles output size for binary strings
*added function to use old binary encoding

#v1.2
*added fancy layout, can be activated by setting the third argument given to true

#v1.1
*adding local var type_ to remove unneccessary type calls
*improving the binary string encoding using %q
	--> improved performance of string-encode by over 100%
*removed recognition of key=value instead of ["key"]=value of strings
	--> 3 byte more memory usage for every string-index
--]]

local table_insert = table.insert
local table_temp = table.temp
local string_format
local string_format_ = string.format

local mime = require("mime")

local base64 = {
	base64_encode = mime.encode("base64"),
	encode = function(self, d)
		local r = #d % 3
		if r == 0 then
			d = "3==" .. d
		elseif r == 1 then
			d = "2=" .. d
		else
			d = "1" .. d
		end
		return self.base64_encode(d)
	end,
	base64_decode = mime.decode("base64"),
	decode = function(self, d)
		local r = self.base64_decode(d)
		local f = r:sub(1, 1)
		if f == "3" then
			return r:sub(4)
		elseif f == "2" then
			return r:sub(3)
		else
			return r:sub(2)
		end
	end,
}


function table.save(t, noReturn, fancyOutput, flatEncoding, usePerLineFormating, useSpaceInsteadOfTabs)
	table.temp = noReturn and {"{"} or {"return {"}
	table_temp = table.temp
	
	--choses type of encoding, flatEncoding will encode only bytes over 127 and line breaks
	if not flatEncoding then
		string_format = function(s) return string_format_("%q", s) end
	else
		if fancyOutput == "safe" then
			string_format = function(s)
				s = string.gsub(s, "[\128-\255]", function(n) return "\\" .. string.byte(n) end)
				s = string.gsub(s, "\n", "\\n")
				if not string.find(s, '"') then
					s = '"' .. s .. '"'
				elseif not string.find(s, "'") then
					s = "'" .. s .. "'"
				else
					for i = 1, #s do
						if not string.find(s, "[" .. string.rep("=", i) .. "[") and not string.find(s, "]" .. string.rep("=", i) .. "]") then
							s = "[" .. string.rep("=", i) .. "[" .. s .. "]" .. string.rep("=", i) .. "]"
							break
						end
					end
				end
				return s
			end
		else
			string_format = function(s) return string.gsub(string.gsub(string_format_("%q", s), "[\128-\255]", function(n) return "\\" .. string.byte(n) end), "[\10]", function(n) return string.byte(n) end) end
		end
	end
	
	if fancyOutput then
		table_temp[1] = table_temp[1]  .. "\n"
		table.saveFancy_(t, 0, usePerLineFormating, useSpaceInsteadOfTabs)
	else
		table.save_(t)
	end
	table_insert(table_temp, "}")
	
	local s = table.concat(table_temp):gsub(",}", "}")
	return s
end

--smallest output
function table.save_(t)
	local lastIndex = #table_temp
	if table.isArray(t) then
		for d,s in ipairs(t) do
			local type_ = type(s)
			if type_ == "table" then
				table_insert(table_temp, "{")
				table.save_(s)
				table_insert(table_temp, "},")
			elseif type_ == "string" then
				table_insert(table_temp, string_format(s) .. ",")
			elseif type_ == "number" then
				table_insert(table_temp, s .. ",")
			elseif type_ == "boolean" then
				table_insert(table_temp, tostring(s) .. ",")
			end
		end
	else
		for d,s in pairs(t) do
			local valid = true
			local f
			local type_ = type(d)
			if type_ == "number" then
				f = "[" .. d .. "]="
			elseif type_ == "string" then
				if not d:match("%W") and not d:sub(1, 1):match("%d") then
					f = d .. "="
				else
					f = "[" .. string_format(d) .. "]="
				end
			else
				valid = false
			end
			
			if valid then
				local type_ = type(s)
				if type_ == "table" then
					table_insert(table_temp, f)
					table_insert(table_temp, "{")
					table.save_(s)
					table_insert(table_temp, "},")
					valid = false
				elseif type_ == "string" then
					f = f .. string_format(s) .. ","
				elseif type_ == "number" then
					f = f .. s .. ","
				elseif type_ == "boolean" then
					f = f .. tostring(s) .. ","
				else
					valid = false
				end
			end
			
			if valid then
				table_insert(table_temp, f)
			end
		end
	end
	
	if lastIndex ~= #table_temp then
		table_temp[#table_temp] = table_temp[#table_temp]:sub(1, #table_temp[#table_temp]-1)
	end
end

--fancy output
function table.saveFancy_(t, loop_, usePerLineFormating, useSpaceInsteadOfTabs, newLine)
	if type(newLine) == "number" then
		newLine = newLine - 1
		if newLine <= 0 then
			newLine = nil
		end
	end
	
	local lastIndex = #table_temp
	if table.isArray(t) then
		for d,s in ipairs(t) do
			local type_ = type(s)
			if type_ == "table" then
				table_insert(table_temp, "{" .. ((newLine == true or type(newLine) == "number" and newLine > 1) and ("\n" .. string.rep(useSpaceInsteadOfTabs and "  " or "	", loop_+1)) or ""))
				table.saveFancy_(s, loop_+1, usePerLineFormating, useSpaceInsteadOfTabs, newLine or (usePerLineFormating and usePerLineFormating[t]))
				table_insert(table_temp, "}, ")
			elseif type_ == "string" then
				table_insert(table_temp, string_format(s) .. ", ")
			elseif type_ == "number" then
				table_insert(table_temp, s .. ", ")
			elseif type_ == "boolean" then
				table_insert(table_temp, tostring(s) .. ", ")
			end
			if newLine or usePerLineFormating and usePerLineFormating[t] then
				table_insert(table_temp, "\n" .. string.rep(useSpaceInsteadOfTabs and "  " or "	", loop_))
			end
		end
	else
		for d,s in pairs(t) do
			local valid = true
			local f = string.rep(useSpaceInsteadOfTabs and "  " or "	", loop_)
			local type_ = type(d)
			if type_ == "number" then
				f = f .. "[" .. d .. "] = "
			elseif type_ == "string" then
				f = f .. "[" .. string_format(d) .. "] = "
			else
				valid = false
			end
			
			if valid then
				local type_ = type(s)
				if type_ == "table" then
					table_insert(table_temp, f)
					table_insert(table_temp, "{")
					table_insert(table_temp, "\n")
					table.saveFancy_(s, loop_+1, usePerLineFormating, useSpaceInsteadOfTabs)
					table_insert(table_temp, "\n" .. string.rep("  ", loop_) .. "}, \n")
					valid = false
				elseif type_ == "string" then
					f = f .. string_format(s) .. ", "
				elseif type_ == "number" then
					f = f .. s .. ","
				elseif type_ == "boolean" then
					f = f .. tostring(s) .. ", "
				else
					valid = false
				end
			end
			
			if valid then
				table_insert(table_temp, f .. "\n")
			end
		end
	end
	
	if lastIndex ~= #table_temp then
		table_temp[#table_temp] = table_temp[#table_temp]:sub(1, #table_temp[#table_temp]-1)
	end
end

function table.load(ts)
	local ok, msg = loadstring(ts:sub(1, 6) == "return" and ts or ("return " .. ts))
	if not ok then
		error(msg)
	else
		return ok()
	end
end

--provided by kikito at stackoverflow
function table.isArray(t)
	local i = 0
	for _ in pairs(t) do
		i = i + 1
		if t[i] == nil then return false end
	end
	return true
end