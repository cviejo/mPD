local F = require('utils.functional')
-- local S = require('utils.string')
local GuiElement = require('gui.element')
local Button = require('gui.button')
local Stack = require('gui.stack')
local theme = require('gui.theme')
local Dialog = require('gui.dialog')
local renderer = require('gui.renderer')

local corner = theme.corner

local margin = GuiElement({width = corner, height = corner})

local row = function(...)
	return Stack({children = {...}})
end

-- bottom dock
local edit = Button('edit', {toggle = true})
local paste = Button('paste')
local clear = Button('clear')
local copy = Button('copy')
local undo = Button('undo')
local redo = Button('redo')
local dock = Stack({children = {undo, copy, paste, clear, edit, redo}})

-- menu
local menuItemSize = {size = theme.button.size * 1.2}
local more = Button('more_vert')
local layers = Button('layers')
local add = Button('add', menuItemSize)
local save = Button('save', menuItemSize)
local settings = Button('settings', menuItemSize)
local open = Button('open', menuItemSize)
local menu = Dialog({children = {margin, row(add, open, margin), row(save, settings)}})

-- root
local fullscreen = Button('fullscreen', {toggle = true, on = true})
local window = GuiElement({children = {renderer, dock, fullscreen, more, layers, menu}})

local function arrange()
	local width, height = of.getWidth(), of.getHeight()
	local testX = (width - dock.rect.width) / 2
	local testY = height - dock.rect.height

	menu.setPosition(width - menu.rect.width + corner, -(corner))
	dock.setPosition(testX, testY)
	dock.rect.height = dock.rect.height + corner

	more.rect.x = width - theme.button.size
	layers.rect.x = (width - layers.rect.width) / 2
end

window.message = function(msg)
	if msg.cmd == 'touch' then
		window.touch(msg)
	elseif msg.cmd == 'orientation' then
		arrange()
		setTimeout(arrange, 300) -- timeout fixes some artifacts when rearranging
	else
		renderer.message(msg)
		-- renderer
	end
end

fullscreen.onPressed(function()
	F.forEach(function(child)
		child.visible = fullscreen.on
	end, window.children)
	fullscreen.visible = true
	renderer.visible = true
	menu.visible = false
end)

more.onPressed(function()
	menu.visible = true
end)

arrange()

F.forEach(function(x)
	x.onPressed(function()
		menu.visible = false -- maybe do this only on menu.children.onPressed
		local message = "gui pressed " .. x.id .. ' ' .. (x.on and '1' or '0')
		print("message: " .. message)
		of.sendMessage(message)
	end)
end, {add, save, settings, copy, undo, redo, clear, edit, paste})

return window

