--load the matrix and the 3D lib
local dream = require("3DreamEngine")
love.window.setTitle("Lamborghini Example")

--settings
local projectDir = "examples/Lamborghini/"

dream:setSky(love.graphics.newImage(projectDir .. "garage.hdr"))

dream.cam.fov = 70

dream:init()

--objects
local car = dream:loadObject(projectDir .. "Lamborghini Aventador")
local socket = dream:loadObject(projectDir .. "socket")

--sun object
local sun = dream:newLight("sun")
sun:addShadow()
sun:setDirection(-1, 1, 1)

function love.draw()
	dream:resetLight()
	dream:addLight(sun)
	
	dream:prepare()
	
	--draw the car
	car:reset()
	car:scale(0.1)
	car:rotateY(love.mouse.isDown(1) and (-2.25-(love.mouse.getX()/love.graphics.getWidth()-0.5)*4.0) or love.timer.getTime()*0.5)
	car:translate(0, -1.1225, -3.5)
	dream:draw(car)
	
	--draw the socket
	dream:draw(socket, 0, -1, -4.5, 4, 0.25, 4)
	
	--render
	dream:present()
end

function love.update(dt)
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
		dream:init()
	end
end

function love.resize()
	dream:init()
end