local job = { }
local lib = _3DreamEngine

job.cost = 1

function job:init()
	if lib.autoExposure_enabled then
		lib.canvas_exposure = love.graphics.newCanvas(lib.autoExposure_resolution, lib.autoExposure_resolution, {format = "r16f", readable = true, msaa = 0, mipmaps = "auto"})
		lib.canvas_exposure_fetch = love.graphics.newCanvas(1, 1, {format = "r16f", readable = true, msaa = 0, mipmaps = "none"})
		
		lib.canvas_exposure:setFilter("linear")
		lib.canvas_exposure:setMipmapFilter("linear")
		
		love.graphics.setCanvas(lib.canvas_exposure_fetch)
		love.graphics.clear(1, 1, 1)
		love.graphics.setCanvas()
	end
end

function job:queue(times, operations)
	local t = love.timer.getTime()
	if lib.autoExposure_enabled and (t - (times["autoExposure"] or 0)) > lib.autoExposure_interval then
		operations[#operations+1] = {"autoExposure", 0.25}
	end
end

function job:execute(times, delta)
	love.graphics.push("all")
	love.graphics.reset()
	
	--vignette and downscale
	local c = lib.canvas_exposure
	love.graphics.setCanvas(c)
	love.graphics.setShader(lib.shaders.autoExposure)
	lib.shaders.autoExposure:send("targetBrightness", lib.autoExposure_targetBrightness)
	love.graphics.draw(lib.canvases.color, 0, 0, 0, c:getWidth() / lib.canvases.width, c:getHeight() / lib.canvases.height)
	love.graphics.setShader()
	
	--fetch
	local f = lib.autoExposure_adaptionSpeed * math.sqrt(lib.autoExposure_interval)
	love.graphics.setBlendMode("alpha")
	love.graphics.setCanvas(lib.canvas_exposure_fetch)
	love.graphics.setColor(1, 0, 0, f)
	love.graphics.draw(lib.canvas_exposure, 0, 0, 0, 1 / lib.autoExposure_resolution)
	love.graphics.pop()
end

return job