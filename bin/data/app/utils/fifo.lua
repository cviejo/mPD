return function(limit)
	local M = {}
	local xs = {}

	-- @TODO inmutable
	M.push = function(x)
		table.insert(xs, inspect(x))
		if #xs > limit then
			table.remove(xs, 1)
		end
	end

	M.items = function()
		return xs
	end

	return M
end
