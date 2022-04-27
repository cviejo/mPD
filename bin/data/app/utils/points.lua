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

M.subtract = curry(function(p1, p2)
	return {x = p1.x - p2.x, y = p1.y - p2.y}
end)

-- M.inside = curry(function(rect, point)
-- 	return {x = p1.x - p2.x, y = p1.y - p2.y}
-- end)

M.inside = function(rect, point)
	local x = point.x
	local y = point.y

	-- LuaFormatter off
	return (x > rect.x and x < rect.x + rect.width and
	        y > rect.y and y < rect.y + rect.height)
	-- LuaFormatter on
end

return M
