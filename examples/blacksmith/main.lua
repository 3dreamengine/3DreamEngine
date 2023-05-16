--load the 3D lib
local dream = require("3DreamEngine.init")
local vec3 = dream.vec3

love.window.setTitle("Blacksmith")
love.mouse.setRelativeMode(true)

--settings
local projectDir = "examples/blacksmith/"

--set reflection cubemap with local corrections
local r = dream:newReflection(dream.cimg:load(projectDir .. "sky.cimg"))
r:setLocal(vec3(0, 0, 0), vec3(-2, -1, -2), vec3(2, 1, 2))
dream:setDefaultReflection(r)

dream:init()

dream:loadMaterialLibrary(projectDir .. "materials")

local scene = dream:loadObject(projectDir .. "scene")
local torchObject = dream:loadObject(projectDir .. "torch")

--particle texture
local texture_candle = love.graphics.newImage(projectDir .. "materials/candle.png")
local factor = texture_candle:getHeight() / texture_candle:getWidth()
local quads = { }
for y = 1, 5 do
	for x = 1, 5 do
		table.insert(quads, love.graphics.newQuad(x - 1, (y - 1) * factor, 1, factor, 5, 5 * factor))
	end
end

local particles = { }
local lastParticleID = 0

--create new particle batch
local particleBatch = dream:newSpriteBatch(texture_candle)
particleBatch:setVertical(0.75)

--a helper class
local cameraController = require("extensions/utils/cameraController")

--create three light sources and assign shadows
---@type DreamLight[]
local lights = { }
for i = 1, 3 do
	lights[i] = dream:newLight("point", vec3(0, 0, 0), vec3(1.0, 0.75, 0.5))
	local shadow = lights[i]:addNewShadow()
	shadow:setStatic(true)
	shadow:setSmooth(true)
end

local torches = {
	torchObject:instance():translate(0, 0, -1.9):scale(0.075):rotateY(-math.pi / 2),
	torchObject:instance():translate(1.25, 0, 1.9):scale(0.075):rotateY(math.pi / 2),
	torchObject:instance():translate(-1.25, 0, 1.9):scale(0.075):rotateY(math.pi / 2),
}

local hideTooltips = false

function love.draw()
	--update camera
	cameraController:setCamera(dream.camera)
	
	dream:prepare()
	
	--torches, lights and particles
	for d, s in ipairs({
		{ 0, 0.3, -1.85 },
		{ 1.25, 0.3, 1.85 },
		{ -1.25, 0.3, 1.85 },
	}) do
		lights[d]:setPosition(s[1], s[2], s[3])
		lights[d]:setBrightness(8.0 + 4.0 * love.math.noise(love.timer.getTime() * 2))
		dream:addLight(lights[d])
		
		if math.random() < love.timer.getDelta() * 8.0 then
			particles[lastParticleID] = { s[1] + (math.random() - 0.5) * 0.1, s[2] + (math.random() - 0.5) * 0.1, s[3] + (math.random() - 0.5) * 0.1, math.random() + 1.0 }
			lastParticleID = lastParticleID + 1
		end
	end
	
	--particles
	particleBatch:clear()
	love.graphics.setColor(0, 0, 0, 1)
	for d, s in pairs(particles) do
		particleBatch:addQuad(quads[math.ceil(d + s[4] * 25) % 25 + 1], s[1], s[2], s[3], 0, s[4] * 0.075, nil, 2.0)
	end
	love.graphics.setColor(1, 1, 1)
	
	dream:draw(scene)
	
	dream:draw(particleBatch)
	
	--torches
	for _, torch in ipairs(torches) do
		dream:draw(torch)
	end
	
	dream:present()
	
	if not hideTooltips then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("U to toggle auto exposure (" .. tostring(dream.autoExposure_enabled) .. ")\nB to toggle smooth shadows", 10, 10)
	end
end

function love.mousemoved(_, _, x, y)
	cameraController:mousemoved(x, y)
end

function love.update(dt)
	--particles
	for d, s in pairs(particles) do
		s[2] = s[2] + dt * 0.25
		s[4] = s[4] - dt
		if s[4] < 0 then
			particles[d] = nil
		end
	end
	
	cameraController:update(dt)
	
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
	
	if key == "f1" then
		hideTooltips = not hideTooltips
	end
	
	if key == "u" then
		local enabled = dream:getAutoExposure()
		dream:setAutoExposure(not enabled)
		dream:init()
	end
	
	if key == "b" then
		for _, s in pairs(lights) do
			if s.shadow then
				s.shadow:setSmooth(not s.shadow:isSmooth())
			end
		end
	end
	
	if key == "f3" then
		dream:take3DScreenshot(vec3(cameraController.x, cameraController.y, cameraController.z), 128)
	end
end

function love.resize()
	dream:init()
end