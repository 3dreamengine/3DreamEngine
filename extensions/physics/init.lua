---@class PhysicsExtension
local p = { }
_G._PhysicsExtension = p

local root = (...):find("init") and string.match((...), "(.*[/\\])") or ((...) .. "/")

require(root .. "shapes/capsule")
require(root .. "shapes/cylinder")
require(root .. "shapes/mesh")
require(root .. "shapes/object")

require(root .. "world")
require(root .. "collider")

return p