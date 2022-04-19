return function(id, x, y, size)
	local M = {}

	M.id = id
	M.enabled = true
	M.rect = of.Rectangle(x, y, size, size)
	M.padding = 12 * dpi
	M.img = of.Image()

	M.init = function()
		M.img:load("images/outline_" .. id .. "_white_36dp.png");
		M.img:resize(size - M.padding * 2, size - M.padding * 2)
	end

	M.touch = function(touch)
		return M.rect:inside(touch)
	end

	M.draw = function()
		if M.enabled then
			of.setColor(255)
		else
			of.setColor(120)
		end

		M.img:draw(x + M.padding, y + M.padding)
	end

	return M
end
