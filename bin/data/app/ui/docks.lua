local Button = require('ui/button').Button
local ToggleButton = require('ui/button').ToggleButton
local Group = require('ui/group')
local menu = require('ui/menu')

local size = 47 * dpi
local corner = 5 * dpi

local width = of.getWidth()
local menuH = size * 6
local menuY = (of.getHeight() - menuH) * 0.60
local lowY = of.getHeight() - size
local rightX = width - size

local dark = of.Color(36, 38, 39)

local more = Button('more_vert', rightX, lowY)
local fullscreen = ToggleButton('fullscreen', 0, 0)

more.color = dark
fullscreen.color = dark

local function rightY(pos)
	return menuY + pos * size
end

local group = Group(Button('copy', rightX, rightY(0)),
                    Button('paste', rightX, rightY(1)),
                    Button('clear', rightX, rightY(2)),
                    Button('undo', rightX, rightY(3)),
                    Button('zoom_in', rightX, rightY(4)),
                    Button('zoom_out', rightX, rightY(5)),
                    ToggleButton('edit', width / 2 - size / 2, lowY),
                    fullscreen, more)

local clickTest = function(event)
	if fullscreen.value == 0 then
		return fullscreen.touch(event)
	elseif menu.active then
		menu.active = false
		return menu.touch(event) or 'nothing'
	end

	local id, value = group.touch(event)

	menu.active = id == 'more_vert'

	return id, value
end

local M = {}

M.pressed = false

M.touch = function(event)
	local id, value = clickTest(event)

	M.pressed = id ~= nil

	return id, value
end

M.draw = function()
	if fullscreen.value == 0 then
		fullscreen.draw()
		return
	end

	of.setColor(dark)
	of.fill()
	of.drawRectRounded(width / 2 - size / 2, lowY, size, size + corner, corner)
	of.drawRectRounded(rightX, menuY, size + corner, menuH, corner)
	group.draw()
	menu.draw()
	of.setColor(75)
	of.drawRectangle(rightX + corner, rightY(4), size, dpi)
end

return M
