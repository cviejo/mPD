of.TrueTypeFont.setGlobalDpi(96)

local printScale = 2

return function(name, size)
	local font = of.TrueTypeFont()

	font:load("fonts/" .. name .. ".ttf", size * printScale - 1)

	local M = {}

	M.size = size
	M.lineHeight = size

	M.setLineHeight = function(x)
		M.lineHeight = x
		font:setLineHeight(x * printScale)
	end

	M.drawString = function(str, x, y)
		of.scale(1 / printScale, 1 / printScale)
		font:drawString(str, x * printScale, y * printScale)
		of.scale(printScale, printScale)
	end

	return M
end

