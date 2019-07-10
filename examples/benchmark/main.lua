--load the matrix and the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Benchmark")

--settings
dream.objectDir = "examples/benchmark/"

dream.AO_enabled = true      --ambient occlusion?
dream.AO_strength = 0.75     --blend strength
dream.AO_quality = 24        --samples per pixel (8-32 recommended)
dream.AO_quality_smooth = 2  --smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
dream.AO_resolution = 0.75   --resolution factor

dream.near = 1.0
dream.far = 50
dream.nameEncoder = "none"

dream:init()

dream.showLightSources = false

love.graphics.setBackgroundColor(0.8, 0.8, 0.8)

amounts = { }
amounts[#amounts+1] = 32
amounts[#amounts+1] = 128
amounts[#amounts+1] = 1024
amounts[#amounts+1] = 1024*8

benchmarks = { }
index = 0
for _, mode in ipairs({"flat", "texture", "specular"}) do
	for _, mesh in ipairs({12, 48, 192, 768, 3072, 12288}) do
		for i = 0, 3 do
			for d,s in ipairs(amounts) do
				benchmarks[#benchmarks+1] = {mesh = mesh, amount = s, amountIndex = d, mode = mode, lights = i == 0 and 0 or 4^i, index = index}
			end
			index = index + 1
		end
	end
end

for d,s in ipairs(benchmarks) do
	s.time = 0
	s.name = s.mode .. " " .. s.mesh .. " with " .. s.lights .. " lights"
end

currBenchmark = 0
timer = 5

lastTime = 0
time = 0
time_samples = 0
firstIngore = 0

love.window.setMode(800, 600, {vsync = false})

function love.draw()
	dream.color_ambient = {0.1, 0.1, 0.1, 0.1}
	dream.color_sun = {1, 1, 1, 1}
	
	--benchmark
	love.graphics.setColor(1, 1, 1)
	local b = benchmarks[currBenchmark]
	if b then
		dream.lighting_max = b.lights
		dream:resetLight(true)
		for i = 1, b.lights do
			dream:addLight((love.math.noise(-i, love.timer.getTime()*0.1)-0.5)*25, (love.math.noise(-i-100, love.timer.getTime()*0.1)-0.5)*25, (love.math.noise(-i-200, love.timer.getTime()*0.1)-0.5)*25-30, math.random(), math.random(), math.random(), math.random()*2+1)
		end
		
		dream:prepare()
		
		for i = 1, b.amount do
			dream:draw(mesh, (love.math.noise(i, love.timer.getTime()*0.1)-0.5)*25, (love.math.noise(i+100, love.timer.getTime()*0.1)-0.5)*25, (love.math.noise(i+200, love.timer.getTime()*0.1)-0.5)*25-30)
		end
		
		local ok = pcall(function()
			dream:present()
		end)
		if not ok then
			dream.drawTable = { }
			dream:present()
			
			b.time = -1
			timer = 0
		end
	end
	
	love.graphics.print(math.floor(timer*10)/10 .. " sec until next test", 5, 5)
	love.graphics.print(love.timer.getFPS() .. " FPS", 5, 30)
	
	firstIngore = firstIngore - 1
	if firstIngore < 0 then
		time = time + (love.timer.getTime() - lastTime)
		time_samples = time_samples + 1
	end
	lastTime = love.timer.getTime()
end

function love.update(dt)
	timer = timer - dt
	if timer < 0 and time_samples >= 10 then
		timer = 1
		firstIngore = 3
		
		local b = benchmarks[currBenchmark]
		if b then
			b.time = time / time_samples
			if b.time > 0.1 then
				for d,s in ipairs(benchmarks) do
					if s.mesh == b.mesh and s.mode == b.mode and s.lights == b.lights then
						s.time = s.time == 0 and -1 or s.time
					end
				end
			end
		end
		
		time = 0
		time_samples = 0
		currBenchmark = currBenchmark + 1
		
		local b = benchmarks[currBenchmark]
		if b then
			if b.time < 0 then
				timer = -1
				time_samples = 10
				love.update(dt)
			else
				if b.mode == "flat" then
					mesh = dream:loadObject(b.mesh, {forceTextured = false})
				elseif b.mode == "texture" then
					mesh = dream:loadObject(b.mesh, {forceTextured = true})
					mesh.materials.Material.tex_diffuse = love.graphics.newImage(dream.objectDir .. "diffuse.png")
				elseif b.mode == "normal" then
					mesh = dream:loadObject(b.mesh, {forceTextured = true})
					mesh.materials.Material.tex_diffuse = love.graphics.newImage(dream.objectDir .. "diffuse.png")
					mesh.materials.Material.tex_normal = love.graphics.newImage(dream.objectDir .. "normal.png")
				elseif b.mode == "specular" then
					mesh = dream:loadObject(b.mesh, {forceTextured = true})
					mesh.materials.Material.tex_diffuse = love.graphics.newImage(dream.objectDir .. "diffuse.png")
					mesh.materials.Material.tex_normal = love.graphics.newImage(dream.objectDir .. "normal.png")
					mesh.materials.Material.tex_specular = love.graphics.newImage(dream.objectDir .. "specular.png")
				end
			end
		else
			function to(t, s)
				t = tostring(t)
				return t .. string.rep(" ", s-#t)
			end
			local results = { }
			results[#results+1] = to("name", 48)
			for d,s in ipairs(amounts) do
				results[#results+1] = to(s .. "x", 8)
			end
			
			for d,s in ipairs(benchmarks) do
				if s.amountIndex == 1 then
					results[#results+1] = "\n"
					results[#results+1] = to(s.name, 48)
				end
				
				results[#results+1] = to(math.floor(1/s.time+0.5), 8)
			end
			love.filesystem.write("results.txt", table.concat(results, ""))
			love.system.openURL(love.filesystem.getSaveDirectory() .. "/results.txt")
			os.exit()
		end
	end
end