local channel_busy = love.thread.getChannel("3DreamEngine_channel_jobs_channel_busy")
local channel_jobs = love.thread.getChannel("3DreamEngine_channel_jobs")
local channel_results = love.thread.getChannel("3DreamEngine_channel_results")

require("love.image")

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
	local msg = channel_jobs:demand()
	if msg then
		channel_busy:push(true)
		if msg[1] == "image" then
			local info = love.filesystem.getInfo(msg[2])
			assert(info, "Image " .. msg[2] .. " does not exist!")
			
			--load image
			local isCompressed = love.image.isCompressed(msg[2])
			local imageData = isCompressed and love.image.newCompressedData(msg[2]) or love.image.newImageData(msg[2])
			channel_results:push({"image", msg[2], imageData, isCompressed})
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
		end
		channel_busy:pop()
	end
end