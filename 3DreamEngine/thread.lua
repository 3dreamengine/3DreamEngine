channel_jobs = love.thread.getChannel("3DreamEngine_channel_jobs")
channel_results = love.thread.getChannel("3DreamEngine_channel_results")

while true do
	local msg = channel_jobs:demand()
	local file = love.filesystem.newFile(msg[3], "r")
	file:seek(msg[4])
	local byteData = love.data.newByteData(love.data.decompress("string", msg[6], file:read(msg[5])))
	channel_results:push({msg[1], msg[2], byteData})
end