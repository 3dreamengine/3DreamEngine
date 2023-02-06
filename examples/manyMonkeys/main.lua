--window title
love.window.setTitle("Instancing and Merging Monkey Example")

love.window.setVSync(false)

--load the 3D lib
local dream = require("3DreamEngine")

--initialize engine
dream:init()

--load our object (since merging is destructive we load a separate one here)
local monkey = dream:loadObject("examples/monkey/object")
local monkeyForBaking = dream:loadObject("examples/monkey/object", { cleanup = false, mesh = false })
monkey.meshes.Suzanne.material.color = { 0.4, 0.15, 0.05, 1 }
monkeyForBaking.meshes.Suzanne.material.color = { 0.4, 0.15, 0.05, 1 }

local function getPos()
	return vec3(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 15
end

local function createSlow(n)
	monkey.meshes.Suzanne.instanceMesh = nil
	math.randomseed(1)
	local newMonkey = dream:newObject("merged")
	for i = 1, n do
		newMonkey.objects[i] = monkey:clone()
		newMonkey.objects[i]:translate(getPos())
		newMonkey.objects[i]:rotateX(math.random() * math.pi * 2)
		newMonkey.objects[i]:rotateY(math.random() * math.pi * 2)
		newMonkey.objects[i]:rotateZ(math.random() * math.pi * 2)
	end
	return newMonkey
end

local function createInstanced(n)
	math.randomseed(1)
	local newMonkey = monkey:clone()
	newMonkey.meshes.Suzanne = dream:newInstancedMesh(newMonkey.meshes.Suzanne)
	newMonkey.meshes.Suzanne:resize(n)
	for _ = 1, n do
		newMonkey.meshes.Suzanne:addInstance(mat3:getIdentity(), getPos())
	end
	return newMonkey
end

local function createMerged(n)
	math.randomseed(1)
	local newMonkey = dream:newObject("merged")
	for i = 1, n do
		newMonkey.objects[i] = monkeyForBaking:clone()
		newMonkey.objects[i]:translate(getPos())
	end
	newMonkey = newMonkey:merge()
	newMonkey:clearMeshes()
	return newMonkey
end

local count = 1024
local mode = "slow"
local object

local function rebuild()
	if mode == "slow" then
		object = createSlow(count)
	elseif mode == "instances" then
		object = createInstanced(count)
	else
		object = createMerged(count)
	end
end
rebuild()

--make a sun
local sun = dream:newLight("sun")

function love.draw()
	dream:prepare()
	
	dream:addLight(sun)
	
	--add (draw) objects, apply transformations
	object:resetTransform()
	object:translate(0, 0, -15)
	object:rotateY(love.timer.getTime())
	dream:draw(object)
	
	--render
	dream:present()
	
	--explanation
	love.graphics.printf("This demo contains 3 ways of rendering the same object. The first approach is the straight forward one, with high CPU load. The second one uses instances, which are usually much faster for many objects (grass, foliage, or 500 monkeys), the third methode merges the objects. While not faster than instancing with a far greater initial build time, this approach allows you to merge different shapes too, as long as they share the same material and shader.", 100, 5, love.graphics.getWidth() - 200, "center")
	
	--instructions
	love.graphics.print("FPS: " .. love.timer.getFPS() .. "\n\nUse number keys to switch mode, use arrow keys to change number of monkeys.\n1) Slow\n2) Instances\n3) Merged (will require build time)\n\nCount: " .. count, 5, love.graphics.getHeight() - 150)
end

function love.keypressed(key)
	if key == "up" or key == "right" then
		count = count * 2
	end
	if key == "down" or key == "left" then
		if count > 1 then
			count = count / 2
		end
	end
	if key == "1" then
		mode = "slow"
	elseif key == "2" then
		mode = "instances"
	elseif key == "3" then
		mode = "merged"
	end
	rebuild()
end

function love.resize()
	dream:resize()
end