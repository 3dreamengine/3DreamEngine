local examples = love.filesystem.getDirectoryItems("examples")

function love.draw()
	love.graphics.print("press number to start example", 50, 50)
	
	for d,s in ipairs(examples) do
		love.graphics.print(d .. ": " .. s, 50, 50 + d*20)
	end
end

function love.keypressed(key)
	if tonumber(key) and examples[tonumber(key)] then
		love.draw = nil
		love.keypressed = nil
		require("examples/" .. examples[tonumber(key)] .. "/main")
	end
end