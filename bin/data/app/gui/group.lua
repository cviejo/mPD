local forEach = require('utils/functional').forEach

return function(...)
	local M = {}

	local xs = {...}

	M.touch = function(touch)
		for i = 1, #xs do
			local btn = xs[i]
			if (btn.touch(touch)) then
				return btn.id, btn.value --
			end
		end
	end

	M.draw = function()
		forEach(function(x)
			x.draw()
		end, xs)
	end

	return M
end

