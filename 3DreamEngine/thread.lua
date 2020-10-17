channel_jobs_priority = love.thread.getChannel("3DreamEngine_channel_jobs_priority")
channel_jobs = love.thread.getChannel("3DreamEngine_channel_jobs")
channel_results = love.thread.getChannel("3DreamEngine_channel_results")

require("love.image")

--generate a thumbnail, 8 times smaller
local function generateThumbnail(path, imageData, info)
	local thumbPath = "thumbs/" .. path
	local ext = thumbPath:match("^.+(%..+)$") or ""
	thumbPath = thumbPath:sub(1, #thumbPath - #ext) .. "_thumb.tga"
	
	local info_thumb = love.filesystem.getInfo(thumbPath)
	if not info_thumb or (info.modtime or 0) > (info and info_thumb.modtime or 0) then
		print("generating thumbnail for " .. path)
		local factor = 8
		local skip = 2
		
		local w, h = imageData:getDimensions()
		local nw = math.floor(w / factor)
		local nh = math.floor(h / factor)
		local thumb = love.image.newImageData(nw, nh, imageData:getFormat())
		
		for x = 0, nw-1 do
			for y = 0, nh-1 do
				local r, g, b, a = 0, 0, 0, 0
				local c = 0
				for x2 = 0, factor-1, skip do
					for y2 = 0, factor-1, skip do
						local nr, ng, nb, na = imageData:getPixel(x * factor + x2, y * factor + y2)
						r = r + nr
						g = g + ng
						b = b + nb
						a = a + na
						c = c + 1
					end
				end
				thumb:setPixel(x, y, r / c, g / c, b / c, a / c)
			end
		end
		
		love.filesystem.createDirectory(thumbPath:match("(.*[/\\])"))
		thumb:encode("tga", thumbPath)
	end
end

--combine three image datas
local function combineImages(red, green, blue, exportFormat, exportPath)
	local combined = red or green or blue
	
	--pixel mapper
	local function combine(x, y, oldR, oldG, oldB)
		local r, g, b = 1.0, 1.0, 1.0
		
		if combined == red then
			r = oldR
		elseif red then
			r, _, _ = red:getPixel(x, y)
		end
		
		if combined == green then
			g = oldG
		elseif green then
			_, g, _ = green:getPixel(x, y)
		end
		
		if combined == blue then
			b = oldB
		elseif blue then
			_, _, b = blue:getPixel(x, y)
		end
		
		return r, g, b, 1.0
	end
	
	--apply and encode
	combined:mapPixel(combine)
	combined:encode(exportFormat, exportPath)
	
	return combined
end

while true do
	local msg = channel_jobs_priority:demand(1/10) or channel_jobs:pop()
	if msg then
		if msg[1] == "3do" then
			--load 3do mesh
			local file = love.filesystem.newFile(msg[3], "r")
			file:seek(msg[4])
			local byteData = love.data.newByteData(love.data.decompress("string", msg[6], file:read(msg[5])))
			channel_results:push({"3do", msg[2], msg[4], byteData})
		elseif msg[1] == "image" then
			local info = love.filesystem.getInfo(msg[2])
			assert(info, "Image " .. msg[2] .. " does not exist!")
			
			--load image
			local isCompressed = love.image.isCompressed(msg[2])
			local imageData = isCompressed and love.image.newCompressedData(msg[2]) or love.image.newImageData(msg[2])
			channel_results:push({"image", msg[2], imageData, isCompressed})
			
			--generate thumbnail
			if msg[3] and not isCompressed then
				generateThumbnail(msg[2], imageData, info)
			end
		elseif msg[1] == "combine" then
			local exportFormat = "tga"
			local dir = "combined"
			local exportPath = dir .. "/" .. msg[2] .. "." .. exportFormat
			
			--check if cache is up to date
			local combined
			local info = love.filesystem.getInfo(exportPath)
			if info then
				local info1 = msg[3] and love.filesystem.getInfo(msg[3])
				local info2 = msg[4] and love.filesystem.getInfo(msg[4])
				local info3 = msg[5] and love.filesystem.getInfo(msg[5])
				if (not info1 or (info.modtime or 0) > (info1.modtime or 0)) and (not info2 or (info.modtime or 0) > (info2.modtime or 0)) and (not info3 or (info.modtime or 0) > (info3.modtime or 0)) then
					combined = love.image.newImageData(exportPath)
				end
			end
			
			--cache is outdated, combine
			if not combined then
				print("Requested generation of " .. msg[2] .. "." .. exportFormat .. ". Texture will be exported to save directory, subdirectory " .. dir)
				love.filesystem.createDirectory(dir .. "/" .. (msg[2]:match("(.*[/\\])") or ""))
				
				local red = msg[3] and love.image.newImageData(msg[3])
				local green = msg[4] and love.image.newImageData(msg[4])
				local blue = msg[5] and love.image.newImageData(msg[5])
				combined = combineImages(red, green, blue, exportFormat, exportPath)
			end
			
			--send result
			channel_results:push({"image", msg[2], combined})
			
			--generate thumbnail for next time
			generateThumbnail(msg[2], combined, info or love.filesystem.getInfo(exportPath))
		end
	end
end