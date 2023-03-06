local dream = require("3DreamEngine.init")

do
	local material = dream:newMaterial("Material")
	material:setColor(0.5, 0.5, 0.5)
	material:setRoughness(0.8)
	dream:registerMaterial(material)
end

do
	local material = dream:newMaterial("Crate")
	material:setColor(120 / 255, 81 / 255, 36 / 255)
	material:setRoughness(0.8)
	dream:registerMaterial(material)
end

do
	local material = dream:newMaterial("Chicken")
	material:setColor(0.75, 0.75, 0.75)
	material:setRoughness(0.5)
	material:setMetallic(1.0)
	dream:registerMaterial(material)
end