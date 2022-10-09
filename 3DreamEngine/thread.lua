local channel_busy = love.thread.getChannel("3DreamEngine_channel_jobs_channel_busy")
local channel_jobs = love.thread.getChannel("3DreamEngine_channel_jobs")
local channel_results = love.thread.getChannel("3DreamEngine_channel_results")

require("love.image")

--combine three image datas
local function combineImages(red, green, blue)
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
	
	return combined
end

while true do
	local msg = channel_jobs:demand()
	if msg then
		channel_busy:push(true)
		if msg.task == "image" then
			local info = love.filesystem.getInfo(msg.path)
			assert(info, "Image " .. msg.path .. " does not exist!")
			
			--load image
			local isCompressed = love.image.isCompressed(msg.path)
			local imageData = isCompressed and love.image.newCompressedData(msg.path) or love.image.newImageData(msg.path)
			channel_results:push({ "image", msg.path, imageData, isCompressed })
		elseif msg.task == "combine" then
			--todo re-add cache
			local red = type(msg.metallic) == "userdata" and msg.metallic or msg.metallic and love.image.newImageData(msg.metallic)
			local green = type(msg.roughness) == "userdata" and msg.roughness or msg.roughness and love.image.newImageData(msg.roughness)
			local blue = type(msg.AO) == "userdata" and msg.AO or msg.AO and love.image.newImageData(msg.AO)
			local combined = combineImages(red, green, blue)
			
			--send result
			channel_results:push({ "image", msg.path, combined })
		end
		channel_busy:pop()
	end
end