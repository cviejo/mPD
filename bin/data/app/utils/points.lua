local M = {}

M.equals = curry(function(p1, p2)
	return p1.x == p2.x and p1.y == p2.y
end)

M.toRect = curry(function(p1, p2)
	return p1.x, p1.y, p2.x - p1.x, p2.y - p1.y
end)

M.add = curry(function(p1, p2)
	return {x = p1.x + p2.x, y = p1.y + p2.y}
end)

return M
