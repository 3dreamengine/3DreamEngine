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

--create a new glyph atlas using LÖVEs default font and size 64
local glyphAtlas = dream:newGlyphAtlas(nil, 64)

--create a text builder, which internally uses the glyph atlas
local text = dream:newTextMeshBuilder(glyphAtlas)

--as with every mesh, the text material can be modified
text:getMaterial():setRoughness(0.1)
text:getMaterial():setMetallic(1)

--simple, left align, single line text with optional transformation
text:print("Simple text", dream.mat4.getTranslate(-180, 80, 0))

--formatted, aligned (here we use originCenter, which uses the origin X as center), line wrapped text
text:printf("This text should be perfectly centered", 400, "originCenter")

--a second text builder which we use for animations. Don't create a new builder each frame, reuse and clear instead whenever possible.
local animatedText = dream:newTextMeshBuilder(glyphAtlas)
animatedText:getMaterial():setEmissionFactor(5, 5, 5)

--a helper to showcase more advanced strings
local function populateAnimatedText()
	animatedText:clear()
	animatedText:printf({
		{
			--a simple string segment
			string = "Look, a "
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
			string = "!"
		},
	}, 400, "originCenter")
end


-- SPRITES

--create a new sprite mesh using the candle texture for both albedo (we need the alpha!) and emission (since it primarily glows)
local sprite = dream:newSprite(texture, texture, false, quad)


-- SPRITE BATCH

--similar to individual sprites we can use a spriteBatch to draw several in one go. Much faster, and generally recommended whenever possible.
--the sprites always face the camera
local spriteBatch = dream:newSpriteBatch(texture, texture)


-- MESH BUILDER

--more flexible are mesh builders
local meshBuilder = dream:newMeshBuilder(sprite.material)


-- INSTANCED MESH

--less flexible than mesh builders but a bit more efficient
--unlike the sprite batch sprites do not automatically face the camera
local instancedMesh = dream:newInstancedMesh(sprite)


function love.draw()
	dream:prepare()
	
	dream:addLight(sun)
	
	local t = love.timer.getTime()
	
	
	-- FONT AND TEXT
	
	--Move the text into place and let it rotate a bit. Since fonts uses a 1 pixel per meter scale, scale it,
	populateAnimatedText()
	local transform = dream.mat4.getIdentity()
	transform = transform:translate(-1, 1, -2.25)
	transform = transform:rotateX(-0.1)
	transform = transform:rotateY(math.cos(love.timer.getTime()) * 0.5)
	transform = transform:scale(0.005)
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
	
	
	-- MESH BUILDER
	-- the same for mesh builders
	meshBuilder:clear()
	meshBuilder:addMesh(sprite, sprite:getSpriteTransform(0.5, 0, -1, math.cos(t * 3.6) * 0.25, 0.1))
	meshBuilder:addMesh(sprite, sprite:getSpriteTransform(0.6, 0, -1, math.cos(t * 3.5) * 0.25, 0.1))
	meshBuilder:addMesh(sprite, sprite:getSpriteTransform(0.7, 0, -1, math.cos(t * 3.4) * 0.25, 0.1))
	dream:draw(meshBuilder)
	
	--instead of adding whole meshes you can add individual vertices
	--we could use the addQuad() helper, which allocates 4 vertices and pre-sets 2 triangles automatically, but to showcase faces let's use the full version
	--on screen, it will be the small flame atlas in the center
	--this is just an example, the mesh builder is slower, has a higher memory footprint and less convenient for just sprites
	local vertices, indices, vertexOffset = meshBuilder:addVertices(4, 6)
	
	--two triangles
	indices[0] = vertexOffset
	indices[1] = vertexOffset + 1
	indices[2] = vertexOffset + 2
	indices[3] = vertexOffset
	indices[4] = vertexOffset + 2
	indices[5] = vertexOffset + 3
	
	--quad with size 1
	vertices[0].VertexPositionX = 0	vertices[0].VertexPositionY = 0	vertices[0].VertexPositionZ = -5
	vertices[1].VertexPositionX = 1	vertices[1].VertexPositionY = 0	vertices[1].VertexPositionZ = -5
	vertices[2].VertexPositionX = 1	vertices[2].VertexPositionY = 1	vertices[2].VertexPositionZ = -5
	vertices[3].VertexPositionY = 0	vertices[3].VertexPositionY = 1	vertices[3].VertexPositionZ = -5
	
	--full UV
	vertices[0].VertexTexCoordX = 0	vertices[0].VertexTexCoordY = 1
	vertices[1].VertexTexCoordX = 1	vertices[1].VertexTexCoordY = 1
	vertices[2].VertexTexCoordX = 1	vertices[2].VertexTexCoordY = 0
	vertices[3].VertexTexCoordX = 0	vertices[3].VertexTexCoordY = 0
	
	--point to viewer
	vertices[0].VertexNormalZ = 1
	vertices[1].VertexNormalZ = 1
	vertices[2].VertexNormalZ = 1
	vertices[3].VertexNormalZ = 1
	
	
	-- INSTANCED MESH
	
	--we reuse the transform getter of sprites here to let the sprites face the camera
	instancedMesh:clear()
	instancedMesh:addInstance(dream.classes.sprite:getSpriteTransform(-0.1, 0, -1, math.cos(t * 3.6) * 0.25, 0.1))
	instancedMesh:addInstance(dream.classes.sprite:getSpriteTransform(-0.2, 0, -1, math.cos(t * 3.5) * 0.25, 0.1))
	instancedMesh:addInstance(dream.classes.sprite:getSpriteTransform(-0.3, 0, -1, math.cos(t * 3.4) * 0.25, 0.1))
	dream:draw(instancedMesh)
	
	dream:present()
end

function love.resize()
	dream:resize()
end