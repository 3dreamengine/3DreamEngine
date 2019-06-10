local examples = love.filesystem.getDirectoryItems("examples")

function love.draw()
	love.graphics.print("press number to start example", 50, 50)
	love.graphics.print("press M to enter bone manager", 50, 300)
	
	for d,s in ipairs(examples) do
		love.graphics.print(d .. ": " .. s, 50, 50 + d*20)
	end
end

function love.keypressed(key)
	if tonumber(key) and examples[tonumber(key)] then
		require("examples/" .. examples[tonumber(key)] .. "/main")
	end
	if key == "m" then
		--this will launch the bone manager of 3DreamEngine
		--make sure no code will be executed after launch()
		--loves callbacks will be overwritten
		require("3DreamEngine").boneManager:launch("examples/bones/knight")
	end
end