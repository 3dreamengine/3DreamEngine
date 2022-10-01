--load the 3D lib
local dream = require("3DreamEngine")
love.window.setTitle("Physics Demo")
love.mouse.setRelativeMode(true)

--settings
local projectDir = "examples/Physics/"

dream:init()

dream:loadMaterialLibrary(projectDir .. "materials")

local scene = dream:loadScene(projectDir .. "objects/scene")
scene:print()

--a helper class
--todo
local cameraController = require("examples/firstpersongame/cameraController")

local hideTooltips = false

local utils = require("extensions/utils")

local physics = require("extensions/physics")
local world = physics:newWorld()

scene:rotateX(-math.pi / 2)
world:add(physics:newObject(scene))

local mapMesh = utils.map.createFromWorld(world)

--our objects, a composition of a model and a collider
local objects = {  }
local function addObject(model, x, y, z, collider)
	local o = {
		model = model,
		collider = world:add(collider or physics:newObject(model), "dynamic", x, y, z) --TODO
	}
	table.insert(objects, o)
	return o
end

local crate = dream:loadObject(projectDir .. "objects/crate")
crate:resetTransform()

for i = 1, 100 do
	addObject(crate, 0, 15, 0)
end

local chicken = dream:loadObject(projectDir .. "objects/chicken", { callback = function(model)
	model:setVertexShader("bones")
end })
addObject(chicken, 0, 10, 0, physics:newCylinder(0.25, 0.5))

function love.draw()
	--update camera
	cameraController:setCamera(dream.cam)
	
	dream:prepare()
	
	dream:draw(scene)
	
	for _, o in ipairs(objects) do
		o.model:resetTransform()
		o.model:translate((o.collider[1] or o.collider):getPosition()) --TODO
		if o.model == chicken then
			chicken:applyPose(chicken.animations.Armature:getPose(love.timer.getTime()))
			chicken:rotateX(-math.pi / 2)
			chicken:scale(1 / 30)
		end
		dream:draw(o.model)
	end
	
	dream:present()
	
	--map
	utils.map.draw(vec3(cameraController.x, cameraController.y, cameraController.z), mapMesh, love.graphics.getWidth() - 10 - 200, 10, 200, 200, 10)
	
	--stats
	if not hideTooltips then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(love.timer.getFPS(), 10, 10)
	end
end

function love.mousemoved(_, _, x, y)
	cameraController:mousemoved(x, y)
end

function love.update(dt)
	cameraController:update(dt)
	
	--update resource loader
	dream:update()
	
	--update the physics
	world:update(dt)
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
	
	if key == "m" then
		mapMesh = utils.map.createFromWorld(world)
	end
end

function love.resize()
	dream:init()
end