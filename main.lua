local examples = love.filesystem.getDirectoryItems("examples")

function love.load()
	if love.filesystem.getInfo("default") and love.filesystem.read("default") ~= "" then
		require("examples/" .. love.filesystem.read("default") .. "/main")
	end
end

function love.draw()
	love.graphics.print("press number to start example", 50, 50)
	
	for d,s in ipairs(examples) do
		love.graphics.print((d-1) .. ": " .. s, 50, 50 + d*20)
	end
end

function love.keypressed(key)
	if tonumber(key) and examples[tonumber(key)+1] then
		love.draw = nil
		love.keypressed = nil
		require("examples/" .. examples[tonumber(key)+1] .. "/main")
	end
end