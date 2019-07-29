channel_jobs = love.thread.getChannel("3DreamEngine_channel_jobs")
channel_results = love.thread.getChannel("3DreamEngine_channel_results")

require("love.image")

while true do
	local msg = channel_jobs:demand()
	if msg[3] then
		--load 3do mesh
		local file = love.filesystem.newFile(msg[3], "r")
		file:seek(msg[4])
		local byteData = love.data.newByteData(love.data.decompress("string", msg[6], file:read(msg[5])))
		channel_results:push({msg[1], msg[2], byteData})
	else
		--load image
		local imageData = love.image.newImageData(msg[2])
		channel_results:push({msg[1], imageData})
	end
end