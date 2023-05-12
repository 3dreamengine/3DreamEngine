--load the 3D lib
local dream = require("3DreamEngine.init")

--a helper class
local cameraController = require("extensions/utils/cameraController")

--use the sky extension
local sky = require("extensions.sky.init")
dream:setSky(sky.render)

local vec3 = dream.vec3
local mat4 = dream.mat4

love.window.setTitle("Voxels")
love.mouse.setRelativeMode(true)

dream:init()

--sun object
local sun = dream:newLight("sun")
sun:addNewShadow()
sun:getShadow():setLazy(true)
sky:setSunOffset(0.5, 0.0)
sky:setDaytime(sun, 0.4)

--lamp
local point = dream:newLight("point")

local game = require("examples.Voxel.game"):new(cameraController)

function love.draw()
	--update camera
	cameraController:setCamera(dream.camera)
	
	dream:prepare()
	
	dream:addLight(sun)
	
	point:setPosition(cameraController.x, cameraController.y, cameraController.z)
	dream:addLight(point)
	
	game:draw()
	
	dream:present()
	
	--cursor
	local cx = love.graphics.getWidth() / 2
	local cy = love.graphics.getHeight() / 2
	local size = 4
	love.graphics.line(cx - size, cy, cx + size, cy)
	love.graphics.line(cx, cy - size, cx, cy + size)
	
	love.graphics.print(love.timer.getFPS() .. "\n" .. math.floor(dream.stats.vertices / 1000) .. "k vertices" .. "\n" .. math.floor(dream.stats.draws) .. " chunks", 5, 5)
end

function love.mousepressed(x, y, button)
	game:mousepressed(x, y, button)
end

function love.mousemoved(_, _, x, y)
	cameraController:mousemoved(x, y)
end

function love.update(dt)
	cameraController:update(dt, 100)
	
	--update resource loader
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
end

function love.resize()
	dream:init()
end