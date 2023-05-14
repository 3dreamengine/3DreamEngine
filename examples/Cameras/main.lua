-- Load the 3D lib
local dream = require("3DreamEngine/init")
local vec3 = dream.vec3

love.window.setTitle("Multiple Cameras")

-- Use a fancy sky
local sky = require("extensions/sky")
dream:setSky(sky.render)

-- Create as sun
local sun = dream:newLight("sun")

-- Initialize
dream:init()

-- Create our additional cameras
local cameras = {
	dream:newCamera(),
	dream:newCamera(),
}

-- Create our additional target frame buffers
local canvases = {
	dream:newCanvases(),
	dream:newCanvases(),
}

for _, c in ipairs(canvases) do
	-- Set to lite mode, which is faster than normal but still uses a canvas, which we need later on
	c:setMode("lite")
	
	-- 512 is the default, change to whatever you like
	c:setResolution(512)
	
	-- Init it, which creates the canvases
	c:init()
end

-- Create a dummy object
local object = dream:loadObject("examples/monkey/object")
object:translate(2, 0, -2)
object:rotateY(math.pi / 4)

-- And a floor
local cube = dream:loadObject("examples/Cameras/cube")
cube:translate(0, -2, 0)
cube:scale(10, 1, 10)

-- Create a screen-like glowing material
local function getScreenMaterial(texture)
	local mat = dream:newMaterial()
	mat:setColor(0.1, 0.1, 0.1)
	mat:setEmissionTexture(texture)
	mat:setMetallic(1.0)
	mat:setRoughness(0.75)
	return mat
end

-- Create a screen
local function createScreen(texture)
	local screen = dream:loadObject("examples/Cameras/cube")
	screen:scale(1, 0.01, 1)
	screen:setMaterial(getScreenMaterial(texture))
	return screen
end

-- Our two "screens" so we can see the results our cameras produce
local screen1 = createScreen(canvases[1].color)
local screen2 = createScreen(canvases[2].color)

screen1:translateWorld(1, -0.9, 1)
screen2:translateWorld(-1, -0.9, -1)

love.mouse.setRelativeMode(true)

--a helper class
local cameraController = require("extensions/utils/cameraController")

function love.draw()
	--update camera
	cameraController:setCamera(dream.camera)
	
	dream:prepare()
	love.graphics.setColor(1, 1, 1)
	
	--add custom light
	dream:addLight(sun)
	
	dream:draw(object)
	dream:draw(cube)
	dream:draw(screen1)
	dream:draw(screen2)
	
	dream:present(cameras[1], canvases[1])
	dream:present(cameras[2], canvases[2])
	
	dream:present()
	
	--stats
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.print(love.timer.getFPS() .. " FPS" ..
			"\ndifferent shaders: " .. dream.stats.shaderSwitches ..
			"\ndifferent materials: " .. dream.stats.materialSwitches ..
			"\ndraws: " .. dream.stats.draws, 15, 500)
end

function love.mousemoved(_, _, x, y)
	cameraController:mousemoved(x, y)
end

function love.update(dt)
	cameraController:update(dt)
	
	--update custom cameras
	local t = love.timer.getTime() * 0.1
	for i, c in ipairs(cameras) do
		c:setTransform(dream:lookAt(vec3((love.math.noise(t, 1 + i) - 0.5) * 8, 3, (love.math.noise(t, 3 + i) - 0.5) * 8), vec3(0, 0, 0)):invert())
	end
	
	dream:update()
	
	sky:setDaytime(sun, 0.0, dream)
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
	
	if key == "8" then
		dream.canvases:setMode("direct")
		dream:init()
	end
	if key == "9" then
		dream.canvases:setMode("normal")
		dream:init()
	end
end

function love.resize()
	dream:init()
end