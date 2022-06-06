local M = {}

local frame = of.Fbo()

frame:allocate(of.getWidth() * 2, of.getHeight() * 2)

M.render = function(fn)
	frame:beginFbo()
	of.enableAlphaBlending()
	fn()
	of.disableAlphaBlending()
	frame:endFbo()
end

M.draw = function(x, y)
	of.setColor(255, 255, 255, 255)
	frame:draw(x, y)
end

M.clear = function()
	frame:clear()
end

return M
