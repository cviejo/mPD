local points = require('utils/points')
local merge = require('utils/functional').merge
local Font = require('utils/font')
local toggleInt = require('utils/toggle-int')

local font = Font("DejaVuSansMono", 6 * dpi)

local withDefaults = merge({
	x = 0,
	y = 0,
	size = 47 * dpi,
	color = of.Color(255),
	value = 1
})

local function loadImage(name, size)
	local img = of.Image("images/outline_" .. name .. "_white_36dp.png")
	img:resize(size, size)
	return img
end

local function getLabelPosition(label, rect)
	if label then
		local bounds = font.getStringBounds(label, 0, 0)
		return {
			x = rect.x + (rect.width - bounds.width) / 2,
			y = rect.y + (rect.height - bounds.height * 0.8)
		}
	end
end

local function makeButton(opts)
	local M = withDefaults(opts)

	local rect = of.Rectangle(M.x, M.y, M.size, M.size)
	local on = nil
	local off = nil
	local imageSize = M.size / 2
	local padding = (M.size - imageSize) / 2
	local labelPosition = getLabelPosition(M.label, rect)

	if M.toggle then
		on = loadImage(M.id .. '_on', imageSize)
		off = loadImage(M.id .. '_off', imageSize)
	else
		on = loadImage(M.id, imageSize)
	end

	M.touch = function(touch)
		local hit = points.inside(rect, touch)
		if M.toggle and hit then
			M.value = toggleInt(M.value)
		end
		return hit
	end

	M.draw = function()
		of.setColor(M.color)
		if not M.toggle or M.value == 1 then
			on:draw(M.x + padding, M.y + padding)
		else
			off:draw(M.x + padding, M.y + padding)
		end

		if M.label then
			font.drawString(M.label, labelPosition.x, labelPosition.y)
		end
	end

	return M
end

local M = {}

M.Button = function(id, x, y)
	return makeButton({id = id, x = x, y = y})
end

M.ToggleButton = function(id, x, y)
	return makeButton({id = id, x = x, y = y, toggle = true})
end

M.LabeledButton = function(id, x, y, size)
	return makeButton({
		id = id,
		x = x,
		y = y,
		size = size,
		label = string.upper(id)
	})
end

return M
