local Button = require('ui/button')
local toggleInt = require('utils/toggle-int')

return function(id, x, y, size)
	local M = Button(id, x, y, size)
	local on = of.Image()
	local off = of.Image()

	on:load("images/outline_" .. id .. "_on_white_36dp.png");
	on:resize(size - M.padding * 2, size - M.padding * 2)

	off:load("images/outline_" .. id .. "_off_white_36dp.png");
	off:resize(size - M.padding * 2, size - M.padding * 2)

	M.value = 1

	M.init = function()
		M.img = on
	end

	M.touch = function(touch)
		local inside = M.rect:inside(touch)

		if inside then
			M.value = toggleInt(M.value)
		end

		if M.value == 1 then
			M.img = on
		else
			M.img = off
		end

		return inside
	end

	return M
end
