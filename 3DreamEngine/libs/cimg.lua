--[[
#Complex Image Loader and Exporter
Exports and Imports ImageData, Canvases and Textures with any format and shape (2d, cube, volume, array, ...)

#Copyright 2020 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#file format
header
4 bytes magic word (CIMG)
1 byte version
1 byte shape
1 byte format
1 byte mipmaps
2 bytes image width: first byte * 256 + second byte
2 bytes image height
2 bytes image depth/layers
10 byte additional settings

data
data always in order, layer 1 to n, face 1 to 6, repeat for each mipmap level if present
data is lz4 HC compressed
4 byte length
length byte data
...
--]]

local shapes = {"2d", "cube", "volume", "array"}
local formats = {"normal", "r8", "rg8", "rgba8", "srgba8", "r16", "rg16", "rgba16", "r16f", "rg16f", "rgba16f", "r32f", "rg32f", "rgba32f", "rgba4", "rgb5a1", "rgb565", "rgb10a2", "rg11b10f"}
local filters = {"nearest", "linear"}
local wraps = {"clamp", "repeat", "mirroredrepeat", "clampzero"}

local shapeID = { }
for d,s in ipairs(shapes) do
	shapeID[s] = d
end

local formatID = { }
for d,s in ipairs(formats) do
	formatID[s] = d
end

local filterID = { }
for d,s in ipairs(filters) do
	filterID[s] = d
end

local wrapID = { }
for d,s in ipairs(wraps) do
	wrapID[s] = d
end

local cimg = { }

local function importData(data, i)
	local a, b, c, d = data:byte(i, i+3)
	local length = a * 256^3 + b * 256^2 + c * 256 + d
	local dat = love.data.decompress("string", "lz4", data:sub(i+4, i+3+length))
	return dat, i + 4 + length
end

function cimg:load(path)
	local data = path:sub(1, 4) == "CIMG" and path or love.filesystem.read(path)
	
	--validate file
	local magic = data:sub(1, 4)
	assert(magic == "CIMG", "invalid CIMG file!")
	
	--parse header
	local version = data:byte(5)
	local typ = shapes[data:byte(6)]
	local pixelFormat = formats[data:byte(7)]
	local mipmapCount = data:byte(8)
	local width = data:byte(9) * 256 + data:byte(10)
	local height = data:byte(11) * 256 + data:byte(12)
	local depth = data:byte(13) * 256 + data:byte(14)
	local filterMin, filterMag = filters[data:byte(15)], filters[data:byte(16)]
	local mipmapFilterMin, mipmapFilterMag = filters[data:byte(17)], filters[data:byte(18)]
	local wrapHoriz, wrapVert, wrapDepth = wraps[data:byte(19)], wraps[data:byte(20)], wraps[data:byte(21)]
	
	--extract data
	local index = 25
	local dat, img
	if typ == "2d" then
		local imgs = { }
		for i = 1, mipmapCount do
			dat, index = importData(data, index)
			
			local f = 0.5 ^ (i-1)
			imgs[#imgs+1] = love.image.newImageData(math.ceil(width * f), math.ceil(height * f), pixelFormat, dat)
		end
		img = love.graphics.newImage(imgs[1], {mipmaps = imgs[2] and {unpack(imgs, 2)}})
	elseif typ == "cube" then
		local imgs = { }
		for face = 1, 6 do
			imgs[face] = { }
		end
		
		for i = 1, mipmapCount do
			local f = 0.5 ^ (i-1)
			for face = 1, 6 do
				dat, index = importData(data, index)
				if mipmapCount == 1 then
					imgs[face] = love.image.newImageData(math.ceil(width * f), math.ceil(height * f), pixelFormat, dat)
				else
					imgs[face][i] = love.image.newImageData(math.ceil(width * f), math.ceil(height * f), pixelFormat, dat)
				end
			end
		end
		
		img = love.graphics.newCubeImage(imgs)
	elseif typ == "volume" then
		local imgs = { }
		for i = 1, mipmapCount do
			local f = 0.5 ^ (i-1)
			imgs[i] = { }
			for z = 1, math.ceil(depth * f) do
				dat, index = importData(data, index)
				imgs[i][z] = love.image.newImageData(math.ceil(width * f), math.ceil(height * f), pixelFormat, dat)
			end
		end
		
		if mipmapCount == 1 then
			img = love.graphics.newVolumeImage(imgs[1])
		else
			error("Mipmaps in volume images are buggy!")
			img = love.graphics.newVolumeImage(imgs)
		end
	elseif typ == "array" then
		local imgs = { }
		for z = 1, depth do
			imgs[z] = { }
		end
		
		for i = 1, mipmapCount do
			local f = 0.5 ^ (i-1)
			for z = 1, depth do
				dat, index = importData(data, index)
				if mipmapCount == 1 then
					imgs[z] = love.image.newImageData(math.ceil(width * f), math.ceil(height * f), pixelFormat, dat)
				else
					imgs[z][i] = love.image.newImageData(math.ceil(width * f), math.ceil(height * f), pixelFormat, dat)
				end
			end
		end
		
		img = love.graphics.newArrayImage(imgs)
	else
		error("unknown type")
	end
	
	--set optional settings
	img:setFilter(filterMin, filterMag)
	img:setMipmapFilter(mipmapFilterMin, mipmapFilterMag)
	img:setWrap(wrapHoriz, wrapVert, wrapDepth)
	
	return img
end

function cimg:newVolumeImage(path)
	local f = self:loadFile(path)
	local bs = f.size^2*4
	
	local layers = { }
	for i = 1, f.height do
		layers[i] = love.image.newImageData(f.size, f.size, "rgba8", love.data.newByteData(f.data:sub((i-1) * bs + 1, i * bs)))
	end
	
	return love.graphics.newVolumeImage(layers)
end

local exportData = function(dat)
	local compressed = love.data.compress("string", "lz4", dat, 9)
	local s = #compressed
	return string.char(math.floor(s / 16777216), math.floor(s / 65536) % 256, math.floor(s / 256) % 256, s % 256) .. compressed
end

function cimg:export(canvas, path)
	assert(canvas:typeOf("Canvas"), "Only canvases can be exported")
	
	--fetch settings
	local typ = canvas:getTextureType()
	local width, height = canvas:getDimensions()
	local layers = canvas:getLayerCount()
	local depth = canvas:getDepth()
	local pixelFormat = canvas:getFormat()
	local mipmapCount = canvas:getMipmapCount()
	local filterMin, filterMag = canvas:getFilter()
	local mipmapFilterMin, mipmapFilterMag = canvas:getMipmapFilter()
	local wrapHoriz, wrapVert, wrapDepth = canvas:getWrap()
	local z = math.max(layers, depth)
	
	--header
	local dat = {
		"CIMG",
		string.char(1, shapeID[typ] or 0, formatID[pixelFormat], mipmapCount),
		string.char(math.floor(width / 256), width % 256),
		string.char(math.floor(height / 256), height % 256),
		string.char(math.floor(z / 256), z % 256),
		string.char(filterID[filterMin] or 0, filterID[filterMag] or 0),
		string.char(filterID[mipmapFilterMin] or 0, filterID[mipmapFilterMag] or 0),
		string.char(wrapID[wrapHoriz] or 0, wrapID[wrapVert] or 0, wrapID[wrapDepth] or 0),
		string.char(0, 0, 0),
	}
	
	--data
	if typ == "2d" then
		for i = 1, mipmapCount do
			local f = 0.5 ^ (i-1)
			local str = canvas:newImageData(1, i, 0, 0, math.ceil(width * f), math.ceil(height * f)):getString()
			dat[#dat+1] = exportData(str)
		end
	elseif typ == "cube" then
		for i = 1, mipmapCount do
			local f = 0.5 ^ (i-1)
			for face = 1, 6 do
				local str = canvas:newImageData(face, i, 0, 0, math.ceil(width * f), math.ceil(height * f)):getString()
				dat[#dat+1] = exportData(str)
			end
		end
	elseif typ == "volume" then
		for i = 1, mipmapCount do
			local f = 0.5 ^ (i-1)
			for layer = 1, z * f do
				local str = canvas:newImageData(layer, i, 0, 0, math.ceil(width * f), math.ceil(height * f)):getString()
				dat[#dat+1] = exportData(str)
			end
		end
	elseif typ == "array" then
		for i = 1, mipmapCount do
			local f = 0.5 ^ (i-1)
			for layer = 1, z do
				local str = canvas:newImageData(layer, i, 0, 0, math.ceil(width * f), math.ceil(height * f)):getString()
				dat[#dat+1] = exportData(str)
			end
		end
	else
		error("unknown type")
	end
	
	--concat and save/return
	local str = table.concat(dat)
	if path then
		love.filesystem.write(path, str)
	else
		return str
	end
end

return cimg