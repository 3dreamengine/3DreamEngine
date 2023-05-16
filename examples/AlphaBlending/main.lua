--load the matrix and the 3D lib
local dream = require("3DreamEngine.init")
local vec3 = dream.vec3

love.window.setTitle("Alpha Blend Example")
love.mouse.setRelativeMode(true)

--settings
local projectDir = "examples/AlphaBlending/"

--settings
dream.canvases:setRefractions(true)
dream:setSky(love.graphics.newImage(projectDir .. "sky.hdr"), 0.25)
dream:init()

--scene
dream:loadMaterialLibrary(projectDir .. "materials")
local scene = dream:loadObject(projectDir .. "scene")

scene:print()

--light
local p = scene.positions.POS_light:getPosition()
local light = dream:newLight("point", p, vec3(1.4, 1.2, 1.0), 40.0)
local shadow = light:addNewShadow()
shadow:setStatic(true)
shadow:setSmooth(true)
light.blacklist = {[scene.objects.chandelier_glass.meshes.chandelier_glass] = true, [scene.objects.chandelier.meshes.chandelier] = true}

--a helper class
local cameraController = require("extensions/utils/cameraController")

cameraController.x = -1
cameraController.y = 0.75
cameraController.z = -1
cameraController.ry = math.pi * 0.75
dream.camera.fov = 65

function love.draw()
	--update camera
	cameraController:setCamera(dream.camera)
	
	dream:prepare()
	dream:addLight(light)
	dream:draw(scene)
	dream:present()
	
	love.graphics.print(table.concat({
		"1 to toggle refractions .. (" .. tostring(dream.canvases:getRefractions()) .. ")",
	}, "\n"), 5, 5)
end

function love.mousemoved(_, _, x, y)
	cameraController:mousemoved(x, y)
end

function love.update(dt)
	cameraController:update(dt)
	
	dream:update()
end

function love.keypressed(key)
	if key == "1" then
		dream.canvases:setRefractions(not dream.canvases:getRefractions())
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