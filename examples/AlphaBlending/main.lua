--load the matrix and the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Alpha Blend Example")
love.mouse.setRelativeMode(true)

--settings
local projectDir = "examples/AlphaBlending/"

--settings
dream.renderSet:setRefractions(true)
dream.renderSet:setAverageAlpha(true)
dream:setDefaultShaderType("PBR")
dream:setSky(love.graphics.newImage(projectDir .. "sky.hdr"), 0.25)
dream:init()

--scene
dream:loadMaterialLibrary(projectDir .. "materials")
scene = dream:loadObject(projectDir .. "scene", "PBR")

--light
local p = scene.positions[1]
local light = dream:newLight("point", p.x, p.y, p.z, 1.4, 1.2, 1.0, 20.0)
light:addShadow(true)
light:setSmoothing(true)
light.blacklist = {[scene.objects.chandelier_glass_None] = true, [scene.objects.chandelier_WhiteGlass] = true}

--custom position and rotation
dream.cam.rx = 0.9
dream.cam.ry = 0
dream.cam.ax = 0
dream.cam.ay = 0
dream.cam.az = 0
dream.cam.x = 0.95
dream.cam.y = 0.75
dream.cam.z = 0.95
dream.cam.fov = 65

function love.draw()
	--update camera
	dream.cam:reset()
	dream.cam:translate(-dream.cam.x, -dream.cam.y, -dream.cam.z)
	dream.cam:rotateY(dream.cam.ry)
	dream.cam:rotateX(dream.cam.rx)
	
	--light (no daylight) with two custom light sources
	dream:resetLight(true)
	dream:addLight(light)
	
	dream:prepare()
	dream:draw(scene)
	dream:present()
	
	love.graphics.print(table.concat({
		"1 to toggle refractions .. (" .. tostring(dream.renderSet:getRefractions()) .. ")",
		"2 to toggle average alpha .. (" .. tostring(dream.renderSet:getAverageAlpha()) .. ")",
	}, "\n"), 5, 5)
end

function love.mousemoved(_, _, x, y)
	local speedH = 0.005
	local speedV = 0.005
	dream.cam.ry = dream.cam.ry - x * speedH
	dream.cam.rx = math.max(-math.pi/2, math.min(math.pi/2, dream.cam.rx + y * speedV))
end

function love.update(dt)
	local d = love.keyboard.isDown
	local speed = 10*dt
	
	dream.cam.x = dream.cam.x + dream.cam.ax * dt
	dream.cam.y = dream.cam.y + dream.cam.ay * dt
	dream.cam.z = dream.cam.z + dream.cam.az * dt
	
	dream.cam.ax = dream.cam.ax * (1 - dt*3)
	dream.cam.ay = dream.cam.ay * (1 - dt*3)
	dream.cam.az = dream.cam.az * (1 - dt*3)
	
	if d("w") then
		dream.cam.ax = dream.cam.ax + math.cos(-dream.cam.ry-math.pi/2) * speed
		dream.cam.az = dream.cam.az + math.sin(-dream.cam.ry-math.pi/2) * speed
	end
	if d("s") then
		dream.cam.ax = dream.cam.ax + math.cos(-dream.cam.ry+math.pi-math.pi/2) * speed
		dream.cam.az = dream.cam.az + math.sin(-dream.cam.ry+math.pi-math.pi/2) * speed
	end
	if d("a") then
		dream.cam.ax = dream.cam.ax + math.cos(-dream.cam.ry-math.pi/2-math.pi/2) * speed
		dream.cam.az = dream.cam.az + math.sin(-dream.cam.ry-math.pi/2-math.pi/2) * speed
	end
	if d("d") then
		dream.cam.ax = dream.cam.ax + math.cos(-dream.cam.ry+math.pi/2-math.pi/2) * speed
		dream.cam.az = dream.cam.az + math.sin(-dream.cam.ry+math.pi/2-math.pi/2) * speed
	end
	if d("space") then
		dream.cam.ay = dream.cam.ay + speed
	end
	if d("lshift") then
		dream.cam.ay = dream.cam.ay - speed
	end
	
	dream:update()
end

function love.keypressed(key)
	if key == "1" then
		dream.renderSet:setRefractions(not dream.renderSet:getRefractions())
		dream:init()
	end
	
	if key == "2" then
		dream.renderSet:setAverageAlpha(not dream.renderSet:getAverageAlpha())
		dream:init()
	end
	
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