local vec2 = require('utils.of').vec2

local function updateVertex(index, point, mesh)
	local vertex = mesh:getVertex(index)
	vertex.x = point.x
	vertex.y = point.y
	mesh:setVertex(index, vertex)
end

return function(hexColor)
	local M = {}

	local ids = {}
	local mesh = of.Mesh()

	mesh:setMode(of.PRIMITIVE_LINES)

	M.draw = function()
		of.setHexColor(hexColor)
		mesh:draw()
	end

	M.add = function(x)
		mesh:addVertex(vec2(x.points[1]))
		mesh:addVertex(vec2(x.points[2]))
		ids[#ids + 1] = x.id
	end

	M.getPoints = function(x)
		for i = 1, #ids do
			if ids[i] == x.tag then
				local a = mesh:getVertex(i * 2 - 2)
				local b = mesh:getVertex(i * 2 - 1)
				return {{x = a.x, y = a.y}, {x = b.x, y = b.y}}
			end
		end
	end

	M.update = function(x)
		for i = 1, #ids do
			if ids[i] == x.tag and x.points then
				updateVertex(i * 2 - 2, x.points[1], mesh)
				updateVertex(i * 2 - 1, x.points[2], mesh)
				return true
			end
		end
		return false
	end

	M.delete = function(x)
		local new = {}
		for i = 1, #ids do
			if ids[i] == x.tag then
				mesh:removeVertex(i * 2 - 2)
				mesh:removeVertex(i * 2 - 2)
			else
				new[#new + 1] = ids[i]
			end
		end
		local found = #new ~= #ids
		ids = new
		return found
	end

	return M
end
