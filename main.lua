require("run")

--locate example projects
local examples = love.filesystem.getDirectoryItems("examples")
for i = #examples, 1, -1 do
	if not love.filesystem.getInfo("examples/" .. examples[i] .. "/main.lua", "file") then
		table.remove(examples, i)
	end
end

--set background and font
love.graphics.setBackgroundColor(0.35, 0.35, 0.35)
local font = love.graphics.newFont(24)
local smallFont = love.graphics.newFont(16)

--descriptions to show on hover
local descriptions = {
	["AlphaBlending"] = "Refraction showcase",
	["blacksmith"] = "Single room demo. PBR with 3 light-sources. Toggle different features to see real time differences.",
	["camera"] = "PBR showcase",
	["Cameras"] = "Multiple cameras and target canvases in a minimalistic scene",
	["firstpersongame"] = "Not really a game, demo scene to see particle systems, outdoor lighting, daytime and rain.",
	["knight"] = "MagicaVoxel demo.",
	["Lamborghini"] = "PBR rendered Lamborghini with emission texture.",
	["manyMonkeys"] = "Demo on how to use instancing, object merging or buffer builders to achieve higher performance.",
	["MeshBuilders"] = "Different mesh builders, text objects, spritebatches and more.",
	["monkey"] = "Good old Suzanne. Simplest usage example.",
	["Physics"] = "A showcase of the Box2D physics wrapper.",
	["Tavern"] = "PBR rendered Tavern with fully soft shadowed static light sources, particles, and raytracing. Toggle different features to see real time differences.",
}

local mousereleased = false

--draws a button, returns true on hover
local function button(text, x, y, w, h)
	love.graphics.push("all")
	
	--checks for hover
	local hover = false
	local mx, my = love.mouse.getPosition()
	if mx > x and mx < x + w and my > y and my < y + h then
		love.graphics.setColor(0.75, 0.75, 0.75)
		hover = true
	else
		love.graphics.setColor(0.6, 0.6, 0.6)
	end
	
	--button
	love.graphics.rectangle("fill", x, y, w, h, 5)
	love.graphics.setColor(0.4, 0.4, 0.4)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", x, y, w, h, 5)
	
	--text
	love.graphics.setFont(font)
	local width = font:getWidth(text)
	local scale = math.min(1.0, (w - 20) / width)
	local baseline = font:getBaseline() * scale
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.print(text, x + 10, y + h - baseline - 5, 0, scale)
	love.graphics.pop()
	
	return hover
end

--load default project
function love.load()
	local default = love.filesystem.read("default")
	if default and default ~= "" then
		require("examples/" .. love.filesystem.read("default") .. "/main")
	end
end

function love.draw()
	local x, y = 50, 50
	for d, s in ipairs(examples) do
		--button
		local hover = button(s, x, y, 200, 30)
		
		--description
		if hover and descriptions[s] then
			love.graphics.push("all")
			love.graphics.setColor(0.0, 0.0, 0.0)
			love.graphics.setFont(smallFont)
			love.graphics.printf(descriptions[s], 330, 200, 400, "left")
			love.graphics.pop()
		end
		
		--launch
		if mousereleased and hover then
			love.draw = nil
			love.keypressed = nil
			require("examples/" .. s .. "/main")
			return
		end
		
		y = y + 35
		if y > love.graphics.getHeight() - 80 then
			y = 50
			x = x + 220
		end
	end
	
	mousereleased = false
end

function love.mousereleased(x, y, b)
	mousereleased = b == 1
end