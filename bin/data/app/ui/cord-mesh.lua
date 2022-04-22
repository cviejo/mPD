local vec2 = require('utils/of').vec2

return function(hexColor)
	local M = {}

	local mesh = of.Mesh()
	local index = {}

	mesh:setMode(of.PRIMITIVE_LINES)

	local function updateVertex(i, point)
		local vertex = mesh:getVertex(i)
		vertex.x = point.x
		vertex.y = point.y
		mesh:setVertex(i, vertex)
	end

	M.draw = function()
		of.setHexColor(hexColor)
		mesh:draw()
	end

	M.add = function(x)
		mesh:addVertex(vec2(x.points[1]))
		mesh:addVertex(vec2(x.points[2]))
		index[#index + 1] = x.id
	end

	M.getPoints = function(x)
		for i = 1, #index do
			if index[i] == x.tag then
				local v1 = mesh:getVertex(i * 2 - 2)
				local v2 = mesh:getVertex(i * 2 - 1)
				return {{x = v1.x, y = v1.y}, {x = v2.x, y = v2.y}}
			end
		end
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

	M.delete = function(x)
		local new = {}
		for i = 1, #index do
			if index[i] == x.tag then
				mesh:removeVertex(i * 2 - 2)
				mesh:removeVertex(i * 2 - 2)
			else
				new[#new + 1] = index[i]
			end
		end
		local found = #new ~= #index
		index = new
		return found
	end

	return M
end
