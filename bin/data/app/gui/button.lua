local GuiElement = require('gui.element')
local Font = require('utils.font')
local theme = require('gui.theme')

local font = Font('DejaVuSansMono', 6 * dpi)

local loadImage = function(name, size)
	local file = 'images/' .. name .. '.png'
	local img = of.Image(file)
	img:resize(size, size)
	return img
end

local getLabelPosition = function(label, rect)
	local bounds = font.getStringBounds(label, 0, 0)
	local x = rect.x + (rect.width - bounds.width) / 2
	local y = rect.y + (rect.height - bounds.height * 0.8)
	return { x = x, y = y }
end

local function Button(id, options)
	local M = GuiElement(options)

	M.id = id
	M.on = M.on or false
	M.size = M.size or theme.button.size
	M.rect.width = M.size or 0
	M.rect.height = M.size or 0

	local on = nil
	local off = nil
	local labelPosition = nil
	local imageSize = M.size / 2
	local padding = (M.size - imageSize) / 2

	local init = function()
		if M.label then
			labelPosition = getLabelPosition(M.label, M.rect)
		end
		if M.toggle then
			on = loadImage(M.id .. '_on', imageSize)
			off = loadImage(M.id .. '_off', imageSize)
		else
			on = loadImage(M.id, imageSize)
		end
	end

	M.onPressed(function()
		if M.toggle then
			M.on = not M.on
		end
	end)

	M.draw = function()
		of.setColor(theme.button.fg)
		if not M.toggle or M.on then
			on:draw(M.rect.x + padding, M.rect.y + padding)
		else
			off:draw(M.rect.x + padding, M.rect.y + padding)
		end

		if M.label then
			font.drawString(M.label, labelPosition.x, labelPosition.y)
		end
	end

	init()

	return M
end

return Button

