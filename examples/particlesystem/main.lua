--load the matrix and the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Particle System Example")

--settings
local projectDir = "examples/particlesystem/"

dream.sun_shadow = false

dream:init()

ground = dream:loadObject(projectDir .. "ground", {splitMaterials = true})
ground.objects["Cube.001_particleSystem_Grass_1"].material.cullMode = "none"
ground.objects["Cube.001_particleSystem_Grass_2"].material.cullMode = "none"
ground.objects["Cube.001_particleSystem_Branch_1"].material.cullMode = "none"
ground.objects["Cube.001_particleSystem_Branch_2"].material.cullMode = "none"

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
		dream.cam:translate(math.cos(time) * 1.75, -0.5, math.sin(time) * 1.75)
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