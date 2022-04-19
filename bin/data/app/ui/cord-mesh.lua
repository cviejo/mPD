local vec2 = require('utils/vec2')

return function()
	local M = {}

	local mesh = of.Mesh()
	local index = {}

	mesh:setMode(of.PRIMITIVE_LINES)

	M.draw = function()
		mesh:draw()
	end

	M.add = function(x)
		mesh:addVertex(vec2(x.points[1]))
		mesh:addVertex(vec2(x.points[2]))

		index[#index + 1] = x.id
	end

	M.delete = function(x)
		local tmp = {}
		local found = false

		for i = 1, #index do
			if index[i] == x.tag then
				mesh:removeVertex(i * 2 - 2)
				mesh:removeVertex(i * 2 - 2)
				found = true
			else
				tmp[#tmp + 1] = index[i]
			end
		end

		if found then
			index = tmp
		end

		return found
	end

	local updateVertex = function(i, point)
		local vertex = mesh:getVertex(i)
		vertex.x = point.x
		vertex.y = point.y
		mesh:setVertex(i, vertex)
	end

	M.update = function(x)
		for i = 1, #index do
			if index[i] == x.tag and x.points then
				updateVertex(i * 2 - 2, x.points[1])
				updateVertex(i * 2 - 1, x.points[2])
				return true
			end
		end

		return false
	end

	return M
end

-- local printVertex = function(i)
-- 	local x = mesh:getVertex(i - 1)
-- 	log(i, x.x, x.y)
-- end
-- local printVertices = function()
-- 	print '--------------------------'
-- 	for i = 1, #index do
-- 		printVertex(i * 2 - 1)
-- 		printVertex(i * 2)
-- 	end
-- 	print 'out'
-- 	printVertex(#index * 2 + 1)
-- end

