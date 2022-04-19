return function(points)
	local path = of.Path()

	path:moveTo(points[1].x, points[1].y)

	for i = 2, #points do
		path:lineTo(points[i].x, points[i].y)
	end

	path:close()

	return path
end

