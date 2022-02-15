return function(limit)

	local M = {}
	local xs = {}

	M.push = function(x)
		table.insert(xs, x)
		if #xs > limit then table.remove(xs, 1) end
	end

	M.items = function()
		return xs
	end

	return M
end
