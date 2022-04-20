local M = {}

M.moveBy = function(p1)
	return function(p2)
		return {x = p1.x + p2.x, y = p1.y + p2.y}
	end
end

M.floorPoint = function(point)
	return {x = math.floor(point.x), y = math.floor(point.y)}
end

return M

-- M.hex = pipe(of.hexToInt, of.Color_fromHex)
-- M.isGrey = function(color)
-- 	return color.r == color.g and color.g == color.b
-- end
-- M.lt = function(p1, p2)
-- 	return p1.x < p2.x and p1.y < p2.y
-- end
-- M.gt = function(p1, p2)
-- 	return p1.x > p2.x and p1.y > p2.y
-- end

