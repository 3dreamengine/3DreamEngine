channel_jobs_priority = love.thread.getChannel("3DreamEngine_channel_jobs_priority")
channel_jobs = love.thread.getChannel("3DreamEngine_channel_jobs")
channel_results = love.thread.getChannel("3DreamEngine_channel_results")

require("love.image")

while true do
	local msg = channel_jobs_priority:demand(1/10) or channel_jobs:pop()
	if msg then
		if msg[1] == "3do" then
			--load 3do mesh
			local file = love.filesystem.newFile(msg[4], "r")
			file:seek(msg[5])
			local byteData = love.data.newByteData(love.data.decompress("string", msg[7], file:read(msg[6])))
			channel_results:push({"3do", msg[2], msg[3], byteData})
		elseif msg[1] == "image" then
			--load image
			local imageData = love.image.newImageData(msg[2])
			channel_results:push({"image", msg[2], imageData})
		end
	end
end