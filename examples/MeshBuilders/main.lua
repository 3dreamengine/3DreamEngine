--window title
love.window.setTitle("Mesh Builder, Particles, and Text")

--disable vsync to properly measure FPS
love.window.setVSync(1)

--load the 3D lib
local dream = require("3DreamEngine.init")

--load extensions
local sky = require("extensions/sky")
dream:setSky(sky.render)

--initialize engine
dream:init()


-- ASSETS

--load an example object
local monkey = dream:loadObject("examples/monkey/object")
local material = monkey.meshes.Suzanne.material
material.color = { 0.4, 0.15, 0.05, 1 }

--make a sun
local sun = dream:newLight("sun")

--an example texture and a quad
local texture = love.graphics.newImage("examples/Tavern/candle.png")
local quad = love.graphics.newQuad(0, 0, 1, 960 / 400, 5, 5 * 960 / 400)


-- FONT AND TEXT

--create a new glyph atlas using LÖVEs default font and size 32
local glyphAtlas = dream:newGlyphAtlas(nil, 32)

--create a text builder, which internally uses the glyph atlas
local text = dream:newTextMeshBuilder(glyphAtlas)

--simple, left align, single line text with optional transformation
text:print("Simple text", dream.mat4.getTranslate(-90, 40, 0))

--formatted, aligned (here we use originCenter, which uses the origin X as center), line wrapped text
text:printf("This text should be perfectly centered", 200, "originCenter")

--a second text builder which we use for animations. Don't create a new builder each frame, reuse and clear instead whenever possible.
local animatedText = dream:newTextMeshBuilder(glyphAtlas)

--a helper to showcase more advanced strings
local function populateAnimatedText()
	animatedText:clear()
	animatedText:printf({
		{
			--a simple string segment
			string = "Look, a ",
		},
		{
			--and a bit more advanced string segment with a material
			string = "RAINBOW",
			color = {
				love.math.noise(love.timer.getTime(), 1),
				love.math.noise(love.timer.getTime(), 2),
				love.math.noise(love.timer.getTime(), 3),
				1,
			},
			metallic = 1.0,
			emission = 1.0,
		},
		{
			string = "!",
		},
	}, 200, "originCenter")
end


-- SPRITES

--create a new sprite mesh using the candle texture for both albedo (we need the alpha!) and emission (since it primarily glows)
local sprite = dream:newSprite(texture, texture, false, quad)

--as every mesh, we can modify the material. E.g., since we do not really have transparency, switch to discard mode instead.
sprite:getMaterial():setDiscard()


-- SPRITE BATCH

--similar to individual sprites we can use a spriteBatch to draw several in one go. Much faster, and generally recommended whenever possible.
local spriteBatch = dream:newSpriteBatch(texture, texture)

function love.draw()
	dream:prepare()
	
	dream:addLight(sun)
	
	local t = love.timer.getTime()
	
	
	-- FONT AND TEXT
	
	--Move the text into place and let it rotate a bit. Since fonts uses a 1 pixel per meter scale, scale it,
	populateAnimatedText()
	local transform = dream.mat4.getIdentity()
	transform = transform:translate(-1, 1, -2.25)
	transform = transform:rotateY(math.cos(love.timer.getTime()) * 0.5)
	transform = transform:scale(0.01)
	dream:draw(text, transform)
	transform = dream.mat4.getTranslate(2, 0, 0) * transform
	dream:draw(animatedText, transform)
	
	
	-- SPRITES
	-- sprites are meshes, thus are added to the render queue as other meshes
	-- we use the sprites transform getter to generate a camera facing transform at given position, z rotation and scale
	dream:draw(sprite, sprite:getSpriteTransform(-1.0, 0, -1, math.cos(t * 3.6) * 0.25, 0.1))
	dream:draw(sprite, sprite:getSpriteTransform(-1.1, 0, -1, math.cos(t * 3.5) * 0.25, 0.1))
	dream:draw(sprite, sprite:getSpriteTransform(-1.2, 0, -1, math.cos(t * 3.4) * 0.25, 0.1))
	
	
	-- SPRITE BATCH
	-- the same for spritebatches
	spriteBatch:clear()
	spriteBatch:addQuad(quad, 1.0, 0, -1, math.cos(t * 3.6) * 0.25, 0.1)
	spriteBatch:addQuad(quad, 1.1, 0, -1, math.cos(t * 3.5) * 0.25, 0.1)
	spriteBatch:addQuad(quad, 1.2, 0, -1, math.cos(t * 3.4) * 0.25, 0.1)
	dream:draw(spriteBatch)
	
	dream:present()
end

function love.resize()
	dream:resize()
end