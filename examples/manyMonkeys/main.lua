--window title
love.window.setTitle("Instancing and Merging Monkey Example")

--disable vsync to properly measure FPS
love.window.setVSync(false)

--load the 3D lib
local dream = require("3DreamEngine")

--initialize engine
dream:init()

--load our base object
local monkey = dream:loadObject("examples/monkey/object")
monkey.meshes.Suzanne.material.color = { 0.4, 0.15, 0.05, 1 }

--generates a pseudorandom position
local function randomTransform()
	return mat4:getIdentity()
			   :translate(vec3(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 15)
			   :rotateX(math.random() * math.pi * 2)
			   :rotateY(math.random() * math.pi * 2)
			   :rotateZ(math.random() * math.pi * 2)
end

local function createSlow(n)
	--Create an empty object and add instances of the monkey to it
	local newMonkey = dream:newObject("merged")
	for i = 1, n do
		newMonkey.objects[i] = monkey:instance()
		newMonkey.objects[i]:setTransform(randomTransform())
	end
	return newMonkey
end

local function createInstanced(n)
	--Create a copy/clone of the monkey to keep the original clean
	local newMonkey = monkey:clone()
	
	--Replace the mesh with an instanced version
	newMonkey.meshes.Suzanne = dream:newInstancedMesh(newMonkey.meshes.Suzanne)
	
	--Since we know the size beforehand, set it directly to avoid later resizes
	newMonkey.meshes.Suzanne:resize(n)
	
	--And add instances
	for _ = 1, n do
		newMonkey.meshes.Suzanne:addInstance(randomTransform())
	end
	
	return newMonkey
end

local function createMerged(n)
	--Similar to the slow approach we create an object, fill it, but then call merge to create a new, merged object with a single mesh
	local newMonkey = dream:newObject("merged")
	for i = 1, n do
		newMonkey.objects[i] = monkey:instance()
		newMonkey.objects[i]:setTransform(randomTransform())
	end
	return newMonkey:merge()
end

local count = 1024
local mode = "slow"
local object

local function rebuild()
	math.randomseed(1)
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