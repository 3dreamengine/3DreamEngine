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
local font_small = love.graphics.newFont(16)

--descriptions to show on hover
local descriptions = {
	["AlphaBlending"] = "Refraction showcase",
	["camera"] = "PBR showcase",
	["Lamborghini"] = "PBR rendered Lamborghini with emission texture.",
	["Tavern"] = "PBR rendered Tavern with 9 fully soft shadowed static light sources. Toggle different features to see real time differences.",
	["monkey"] = "Good old Suzanne. Simpliest usage example.",
	["blacksmith"] = "Single room demo. PBR with 3 lightsources. Toggle different features to see real time differences.",
	["firstpersongame"] = "Not really a game, demo scene to see particle systems, outdoor lighting, daytime and rain.",
	["particlesystem"] = "Small particle system example.",
	["game"] = "Unfinished collision demo.",
	["knight"] = "MagicaVoxel demo.",
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
	local scale = math.min(1.0, (w-20) / width)
	local baseline = font:getBaseline() * scale
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.print(text, x+10, y + h - baseline - 5, 0, scale)
	love.graphics.pop()
	
	return hover
end

--load default project
function love.load()
	local default = love.filesystem.read("default")
	if default and default ~= "" then
		if default == "ShaderEditor" then
			require("ShaderEditor/main")
		elseif default == "TextureTool" then
			require("TextureTool/main")
		else
			require("examples/" .. love.filesystem.read("default") .. "/main")
		end
	end
end

function love.draw()
	for d,s in ipairs(examples) do
		--button
		local hover = button(s, 50, 50 + (d-1)*35, 200, 30)
		
		--description
		if hover and descriptions[s] then
			love.graphics.push("all")
			love.graphics.setColor(0.0, 0.0, 0.0)
			love.graphics.setFont(font_small)
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
	end
	
	--launch shader editor
	local hover = button("Shader Editor", 300, 50, 200, 30)
	if hover and mousereleased then
		require("ShaderEditor/main")
	end
	
	--launch texture tool
	local hover = button("Texture Tool", 300, 50 + 35, 200, 30)
	if hover and mousereleased then
		require("TextureTool/main")
	end
	
	mousereleased = false
end

function love.mousereleased(x, y, b)
	mousereleased = true
end