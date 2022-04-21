local Button = require('ui/button')
local ToggleButton = require('ui/toggle-button')

local M = {}

M.size = 47 * dpi

local width = of.getWidth()
local height = of.getHeight()
local corner = 5 * dpi
local separator = dpi

local menuH = M.size * 6
local menuY = (height - menuH) * 0.60

local lowY = height - M.size
local rightX = width - M.size

local copy = Button('copy', rightX, menuY, M.size)
local paste = Button('paste', rightX, menuY + M.size, M.size)
local clear = Button('clear', rightX, menuY + M.size * 2, M.size)
local undo = Button('undo', rightX, menuY + M.size * 3, M.size)
local zoomIn = Button('zoom_in', rightX, menuY + M.size * 4, M.size)
local zoomOut = Button('zoom_out', rightX, menuY + M.size * 5, M.size)
local edit = ToggleButton('edit', width / 2 - M.size / 2, lowY, M.size)

local buttons = {zoomIn, zoomOut, copy, paste, clear, undo, edit}

forEach(function(x)
	x.init()
end, buttons)

local drawFrame = function()
	of.setColor(36, 38, 39)
	of.fill()
	of.drawRectRounded(width / 2 - M.size / 2, lowY, M.size, M.size + corner,
	                   corner)
	of.drawRectRounded(rightX, menuY, M.size + corner, menuH, corner)
end

M.touch = function(touch)
	for i = 1, #buttons do
		local btn = buttons[i]
		if (btn.touch(touch)) then
			return btn.id, btn.value --
		end
	end
end

M.draw = function()
	drawFrame()
	forEach(function(x)
		x.draw()
	end, buttons)
	of.setColor(75)
	of.drawRectangle(rightX + corner, menuY + M.size * 4, M.size, separator)
end

return M
