local M = {}

local grid = of.Fbo()

local scale = 2

------------------------------------------------------
M.init = function(step)
	local w = of.getWidth() * scale + step
	local h = of.getHeight() * scale + step

	grid = of.Fbo()
	grid:allocate(w, h)
	grid:beginFbo()

	of.noFill()
	of.setLineWidth(1)
	of.clear(255, 0)
	of.disableSmoothing()
	of.pushMatrix()
	of.scale(scale, scale)

	local setColor = function(value)
		if (value % (step * 10) == 0) then
			of.setColor(100, 100, 100, 200);
		else
			of.setColor(100, 100, 100, 100);
		end
	end

	for y = 0, h, step do
		setColor(y)
		of.drawLine(0, y, w, y)
	end
	for x = 0, w, step do
		setColor(x)
		of.drawLine(x, 0, x, h)
	end

	of.popMatrix()

	grid:endFbo()
end

------------------------------------------------------
M.draw = function(x, y)
	of.pushMatrix()
	of.scale(1 / scale, 1 / scale)
	grid:draw(x, y)
	of.popMatrix()
end

return M

-- -- circles
-- of.setColor(255, 255, 255, 150);
-- for i = 0, w, step do for j = 0, h, step do of.drawCircle(i, j, 1) end end

