local M = {}

M.getPath = of.FilePath.getAbsolutePath

M.getDirectory = of.FilePath.getEnclosingDirectory

M.getFileName = of.FilePath.getFileName

M.vec2 = function(p)
	return glm.vec3(p.x, p.y, 0)
end

M.equals = function(p1, p2)
	return p1.x == p2.x and p1.y == p2.y
end

M.toRect = function(p1, p2)
	return p1.x, p1.y, p2.x - p1.x, p2.y - p1.y
end

M.moveBy = function(p1)
	return function(p2)
		return {x = p1.x + p2.x, y = p1.y + p2.y}
	end
end

M.pointsToPath = function(points)
	local path = of.Path()

	path:moveTo(points[1].x, points[1].y)

	for i = 2, #points do
		path:lineTo(points[i].x, points[i].y)
	end

	path:close()

	return path
end

M.pointsToMesh = function(points)
	local mesh = of.Mesh()

	mesh:setMode(of.PRIMITIVE_LINES)

	forEach(function(p)
		mesh:addVertex(M.vec2(p))
	end, points)

	return mesh
end

return M

-- M.floorPoint = function(point)
-- 	return {x = math.floor(point.x), y = math.floor(point.y)}
-- end
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
