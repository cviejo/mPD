local M = {}

local x = 0
local y = 0
local grid = of.Fbo()
local printScale = 2
local square = 12
local bigSquare = square * 10

local setLineColor = function(value)
	if (value % bigSquare == 0) then
		of.setColor(100, 100, 100, 200);
	else
		of.setColor(100, 100, 100, 100);
	end
end

M.init = function()
	local w = (of.getWidth() + bigSquare) * printScale
	local h = (of.getHeight() + bigSquare) * printScale
	grid = of.Fbo()
	grid:allocate(w, h)
	grid:beginFbo()

	of.noFill()
	of.setLineWidth(1)
	of.clear(255, 0)
	of.disableSmoothing()
	of.pushMatrix()
	of.scale(printScale, printScale)

	for i = 0, h, square do
		setLineColor(i)
		of.drawLine(0, i, w, i)
	end
	for i = 0, w, square do
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

	local gx = offset.x % bigSquare
	local gy = offset.y % bigSquare
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
