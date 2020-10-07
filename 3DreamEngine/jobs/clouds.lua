local job = { }
local lib = _3DreamEngine

job.cost = 1

--random numbers with seed
local randoms = { }
local function random(i)
	randoms[i] = randoms[i] or math.random()
	return randoms[i]
end

local spritebatch
local quads = { }
for x = 0, 3 do
	for y = 0, 3 do
		quads[#quads+1] = love.graphics.newQuad(x, y, 1, 1, 4, 4)
	end
end

--add a cloud to the spritebatch, performs out of bounds check
local function addCloud(q, x, y, r, sz, ...)
	if x > -sz*0.5 and x < 1+sz*0.5 and y > -sz*0.5 and y < 1+sz*0.5 then
		spritebatch:add(q, x, y, r, sz, ...)
	end
end

function job:init()
	spritebatch = love.graphics.newSpriteBatch(lib.textures.clouds)
end

function job:queue(times, operations)
	operations[#operations+1] = {"clouds", 1.0}
end

function job:execute(times)
	local size = lib.weather_rain^2 * 1.2 + 0.1
	local amount = 32
	
	--add clouds
	spritebatch:clear()
	for i = 1, amount do
		local q = quads[i % 16 + 1]
		local sz = random(i)*0.5 + love.math.noise(i, love.timer.getTime() * 0.01)*0.5
		local x, y = (random(i + 0.5) + love.timer.getTime() * 0.01 * (1.0 + random(i * 1/8)*0.2)) % 1, random(i + 0.25)
		local r = random(i + 0.125) * math.pi * 2
		local brightness = 0.5 + random(i + 1 / 16)
		
		spritebatch:setColor(brightness, brightness, brightness)
		addCloud(q, x-0.5, y-0.5, r, sz * size, nilm, 0.5, 0.5)
		addCloud(q, x+0.5, y-0.5, r, sz * size, nilm, 0.5, 0.5)
		addCloud(q, x-0.5, y+0.5, r, sz * size, nilm, 0.5, 0.5)
		addCloud(q, x+0.5, y+0.5, r, sz * size, nilm, 0.5, 0.5)
	end
	
	--render
	love.graphics.push("all")
	love.graphics.setCanvas(lib.cloudCanvas)
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.setBlendMode("screen", "premultiplied")
	love.graphics.scale(lib.cloudCanvas:getWidth())
	love.graphics.draw(spritebatch)
	love.graphics.pop()
end

return job