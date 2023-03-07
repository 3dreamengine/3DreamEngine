--load the 3D lib
local dream = require("3DreamEngine.init")
local vec3 = dream.vec3

love.window.setTitle("First Person Game")
love.mouse.setRelativeMode(true)

--settings
dream:init()
dream:setFogHeight(0.0, 150.0)

--load extensions
local sky = require("extensions/sky")
dream:setSky(sky.render)

--sun
local sun = dream:newLight("sun")
sun:addNewShadow()

--load all materials
dream:loadMaterialLibrary("examples/firstpersongame/materials")

--load object
local scene = dream:loadObject("examples/firstpersongame/objects/scene")

--a helper class
local cameraController = require("extensions/utils/cameraController")

cameraController.x = 8
cameraController.y = 10
cameraController.z = 2

local time = 0
local rain = 0.0
local isRaining = false
local mist = 0.0
local rainbow = 0.0
local animateTime = true
local hideTooltips = false

function love.draw()
	--update camera
	cameraController:setCamera(dream.camera)
	
	--update light
	dream:prepare()
	dream:addLight(sun)
	if love.mouse.isDown(1) then
		dream:addNewLight("point", vec3(cameraController.x + dream.camera.normal.x, cameraController.y + dream.camera.normal.y, cameraController.z + dream.camera.normal.z), vec3(1.0, 0.75, 0.1), 5.0 + love.math.noise(love.timer.getTime()*2))
	end
	
	dream:draw(scene)
	
	dream:present()
	
	if not hideTooltips then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("R to toggle rain (" .. tostring(isRaining) .. ")\nT to toggle daytime animation (" .. tostring(animateTime) .. ")\nU to toggle auto exposure (" .. tostring(dream.autoExposure_enabled) .. ")", 10, 10)
	end
end

function love.mousemoved(_, _, x, y)
	cameraController:mousemoved(x, y)
end

--collision not implemented yet
local function collide(x, y, w, h)
	return false
end

function love.update(dt)
	--daytime
	if animateTime then
		time = time + dt * 0.02
	end
	sky:setDaytime(sun, time)
	
	--weather
	if isRaining then
		rain = math.min(1, rain + dt * 0.25)
		mist = math.min(1, mist + dt * 0.1)
		rainbow = math.min(1, mist + dt * 0.1)
	else
		rain = math.max(0, rain - dt * 0.25)
		mist = math.max(0, mist - dt * 0.05)
		rainbow = math.max(0, mist - dt * 0.01)
	end
	sky:setSkyColor(rain)
	sky:setRainbow(math.max(0, rainbow - rain))
	dream:setFog(0.05 * mist, sky.skyColor, 1.0)
	
	cameraController:update(dt)
	
	--load world, then if done load high res textures
	dream:update()
end

function love.keypressed(key)
	--screenshots!
	if key == "f2" then
		dream:takeScreenshot()
	end

	--fullscreen
	if key == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
	
	if key == "f1" then
		hideTooltips = not hideTooltips
	end
	
	if key == "r" then
		isRaining = not isRaining
	end
	
	if key == "t" then
		animateTime = not animateTime
	end
	
	if key == "u" then
		local enabled = dream:getAutoExposure()
		dream:setAutoExposure(not enabled)
		dream:init()
	end
end

function love.resize()
	dream:init()
end