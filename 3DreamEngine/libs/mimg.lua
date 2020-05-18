--[[
#Multi Image Loader
#Copyright 2020 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#file format
4 bytes magic word (MIMG)
2 bytes image size: first byte * 256 + second byte
2 bytes image height: in case of 0 its the same as size
4 bytes image format, currently only rgb8 supported
4 bytes unused
size^2*4 bytes first chunk
...
--]]

local mimg = { }

function mimg:loadFile(path)
	local data = love.filesystem.read(path)
	
	local magic = data:sub(1, 4)
	assert(magic == "MIMG", "invalid MIMG file!")
	
	local size = string.byte(data:sub(5, 5)) * 256 + string.byte(data:sub(6, 6))
	local height = string.byte(data:sub(7, 7)) * 256 + string.byte(data:sub(8, 8))
	
	local form = data:sub(9, 12)
	assert(form == "rgb8", "MIMG format not supported!")
	
	if height == 0 then
		height = size
	end
	
	return {
		size = size,
		height = height,
		data = love.data.decompress("string", "lz4", data:sub(17)),
	}
end

function mimg:newVolumeImage(path)
	local f = self:loadFile(path)
	local bs = f.size^2*4
	
	local layers = { }
	for i = 1, f.height do
		layers[i] = love.image.newImageData(f.size, f.size, "rgba8", love.data.newByteData(f.data:sub((i-1) * bs + 1, i * bs)))
	end
	
	return love.graphics.newVolumeImage(layers)
end

return mimg