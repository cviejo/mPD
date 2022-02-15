local M = {}

local grid = of.Fbo()

------------------------------------------------------
M.init = function(step)
	local w = of.getWidth() + step
	local h = of.getHeight() + step

	grid:allocate(w, h)
	grid:beginFbo()

	of.clear(255, 0);
	of.setColor(255, 255, 255, 150);
	for i = 0, w, step do for j = 0, h, step do of.drawCircle(i, j, 1) end end

	grid:endFbo()
end

------------------------------------------------------
M.draw = function(x, y)
	grid:draw(x, y)
end

return M

