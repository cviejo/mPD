local clamp = require('utils.functional').clamp

local screenWidth = of.getWidth()
local screenHeight = of.getHeight()

local centerX = screenWidth / 2
local centerY = screenHeight / 2

return function(initialScale)
	local M = {}

	M.scaling = false
	M.dragging = nil -- a bit nasty, acts as both value and bool/flag
	M.scale = initialScale

	M.rect = of.Rectangle(0, 0, screenWidth / M.scale, screenHeight / M.scale)

	M.move = function(offset)
		M.rect = M.rect + offset:vec2()
		return M.rect
	end

	M.drag = function(point)
		if (M.dragging) then
			M.move(M.dragging - point)
		end
	end

	M.screenToCanvas = function(point)
		local x = (point.x or centerX) / M.scale + M.rect.x
		local y = (point.y or centerY) / M.scale + M.rect.y
		return of.Vec2f(x, y)
	end

	M.setScale = function(msg)
		local before = M.screenToCanvas(msg)

		if msg.cmd == 'scaleBegin' then
			M.scaling = true
			M.dragging = before
		elseif msg.cmd == 'scaleEnd' then
			M.scaling = false
			M.dragging = nil
			return
		elseif msg.cmd == 'scroll' then
			M.scale = M.scale + msg.value * 0.1
		elseif msg.cmd == 'scale' and msg.value then
			M.scale = M.scale * msg.value
		end

		M.scale = clamp(0.75, 7, M.scale)
		M.move(before - M.screenToCanvas(msg))
		M.drag(before)
		M.rect:setSize(screenWidth / M.scale, screenHeight / M.scale)
	end

	M.position = function()
		return M.rect:getPosition()
	end

	return M
end
