require("3DreamEngine")

--load the matrix and the 3D lib
matrix = require("3DreamEngine/matrix")
l3d = require("3DreamEngine")

--settings
love.window.setTitle( "Monkey Example" )
l3d.flat = true
l3d.objectDir = ""
l3d.pathToNoiseTex = "noise.png"

l3d.AO_enabled = true		--ambient occlusion?
l3d.AO_quality = 24		--samples per pixel (8-32 recommended)
l3d.AO_quality_smooth = 1	--smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
l3d.AO_resolution = 0.5		--resolution factor

l3d:init()

monkey = l3d:loadObject("object")

function love.draw()
	l3d:prepare()

	l3d:draw(monkey, 0, 0, -2, 1, 1, 1, 0, love.timer.getTime())

	l3d:present()
end
