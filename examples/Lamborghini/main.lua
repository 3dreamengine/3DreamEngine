local dream = require("3DreamEngine.init")
love.window.setTitle("Lamborghini Example")

--settings
dream:setSky(love.graphics.newImage("examples/Lamborghini/garage.hdr"))
dream.camera.fov = 70
dream:init()

--materials
dream:loadMaterialLibrary("examples/Lamborghini/materials")

--objects
local car = dream:loadObject("examples/Lamborghini/Lamborghini Aventador")
local socket = dream:loadObject("examples/Lamborghini/socket")

--sun object
local sun = dream:newLight("sun")
sun:addNewShadow()
sun:setDirection(-1, 1, 1)

function love.draw()
	dream:prepare()
	dream:addLight(sun)
	
	--draw the car
	car:resetTransform()
	car:translate(0, -1.1225, -3.5)
	car:rotateY(love.mouse.isDown(1) and (-2.25-(love.mouse.getX()/love.graphics.getWidth()-0.5)*4.0) or love.timer.getTime()*0.5)
	car:scale(0.1)
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
	dream:resize()
end