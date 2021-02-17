--load the matrix and the 3D lib
local dream = require("3DreamEngine")
love.window.setTitle("Particle System Example")

--settings
local projectDir = "examples/particlesystem/"

dream.sun_shadow = false
dream.cam.fov = 45

dream:init()

local ground = dream:loadObject(projectDir .. "ground", {splitMaterials = true})

function love.draw()
	dream:resetLight()
	
	dream:prepare()
	
	love.graphics.setColor(1, 1, 1)
	dream:draw(ground)
	
	dream:present()
end

function love.update(dt)
	local time = love.timer.getTime() * 0.05
	
	if not love.keyboard.isDown("space") then
		dream.cam:reset()
		dream.cam:translate(math.cos(time) * 2.5, -0.5, math.sin(time) * 2.5)
		dream.cam:rotateY(-math.pi/2-time)
	end
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