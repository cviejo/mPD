local M = {}

local mask = of.Fbo()
local background = of.Fbo()
-- these have to be bigger to avoid pixelation when scaling
local fboWidth, fboHeight, fboEdge = 250, 75, 18

mask:allocate(fboWidth, fboHeight)
mask:beginFbo()
of.clear(0, 0)
of.drawRectRounded(0, 0, fboWidth, fboHeight, fboEdge)
mask:endFbo()

background:allocate(fboWidth, fboHeight)
background:getTexture():setAlphaMask(mask:getTexture())
background:beginFbo()
of.backgroundGradient(of.Color(150), of.Color(90), of.GRADIENT_LINEAR)
background:endFbo()

M.draw = function(x, y, w, h)
	background:draw(x, y, w, h)
end

return M

