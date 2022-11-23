local M = {}

local x = 0
local y = 0
local grid = of.Fbo()
local printScale = 2

local setLineColor = function(value)
	if (value % (M.step * 10) == 0) then
		of.setColor(100, 100, 100, 200);
	else
		of.setColor(100, 100, 100, 100);
	end
end

M.step = 12

M.init = function()
	local w = of.getWidth() * printScale + M.step
	local h = of.getHeight() * printScale + M.step

	grid = of.Fbo()
	grid:allocate(w, h)
	grid:beginFbo()

	of.noFill()
	of.setLineWidth(1)
	of.clear(255, 0)
	of.disableSmoothing()
	of.pushMatrix()
	of.scale(printScale, printScale)

	for i = 0, h, M.step do
		setLineColor(i)
		of.drawLine(0, i, w, i)
	end
	for i = 0, w, M.step do
		setLineColor(i)
		of.drawLine(i, 0, i, h)
	end

	of.popMatrix()

	of.setColor(255, 0, 0)
	of.setLineWidth(10)
	of.drawLine(w, 0, h, w)

	grid:endFbo()
	of.enableSmoothing()
end

M.adjustToViewport = function(viewport)
	local offset = viewport.position()
	local gx = offset.x % (M.step * 10)
	local gy = offset.y % (M.step * 10)

	x = (offset.x - gx) * printScale
	y = (offset.y - gy) * printScale
end

M.draw = function()
	of.scale(1 / printScale, 1 / printScale)
	grid:draw(x, y)
	of.scale(printScale, printScale)
end

M.init()

return M

-- -- circles
-- of.setColor(255, 255, 255, 150);
-- for i = 0, w, step do for j = 0, h, step do of.drawCircle(i, j, 1) end end
