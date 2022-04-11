local screenWidth = of.getWidth()
local screenHeight = of.getHeight()

return function(scale)
	local M = {}

	M.scale = scale

	M.rect = of.Rectangle(0, 0, screenWidth / M.scale, screenHeight / M.scale)

	M.move = function(offset)
		M.rect = M.rect + offset:vec2()
		return M.rect
	end

	M.screenToCanvas = function(point)
		local x = point.x / M.scale + M.rect.x
		local y = point.y / M.scale + M.rect.y
		return of.Vec2f(x, y)
	end

	M.setScale = function(msg)
		local before = M.screenToCanvas(msg)
		if msg.type == 'scroll' then
			M.scale = M.scale + msg.value * 0.1
		elseif msg.type == 'scale' then
			M.scale = M.scale * msg.value
		end
		M.scale = clamp(0.5, 7, M.scale)
		local offset = before - M.screenToCanvas(msg)

		M.move(offset)

		M.rect:setSize(screenWidth / M.scale, screenHeight / M.scale)
	end

	M.position = function()
		return M.rect:getPosition()
	end

	return M
end
