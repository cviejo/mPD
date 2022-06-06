local LabeledButton = require('gui/button').LabeledButton
local Group = require('gui/group')
local theme = require('theme')

local M = {}

local size = 60 * dpi
local lowY = of.getHeight() - size * 2
local rightX = of.getWidth() - size * 2
local corner = 5 * dpi

local function column(pos)
	return rightX + pos * size
end

local function row(pos)
	return lowY + pos * size
end

local group = Group(LabeledButton('add', column(0), row(0), size),
                    LabeledButton('open', column(1), row(0), size),
                    LabeledButton('save', column(0), row(1), size),
                    LabeledButton('settings', column(1), row(1), size))

local drawFrame = function()
	of.setColor(theme.gui.background)
	of.fill()
	of.drawRectRounded(rightX, lowY, size * 2 + corner, size * 2 + corner, corner)
end

M.active = false

M.touch = group.touch

M.draw = function()
	if M.active then
		drawFrame()
		group.draw()
	end
end

return M
