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

	M.getStringBounds = function(str, x, y)
		-- of.scale(1 / printScale, 1 / printScale)
		local rect = font:getStringBoundingBox(str, x or 0, y or 0)
		return {
			x = rect.x / printScale,
			y = rect.y / printScale,
			width = rect.width / printScale,
			height = rect.height / printScale
		}
	end

	return M
end

