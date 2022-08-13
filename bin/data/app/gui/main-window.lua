local F = require('utils.functional')
local GuiElement = require('gui.element')
local Button = require('gui.button')
local Stack = require('gui.stack')
local theme = require('gui.theme')
local Dialog = require('gui.dialog')

local width, height, corner = of.getWidth(), of.getHeight(), theme.corner

local margin = GuiElement({width = corner, height = corner})

local row = function(...)
	return Stack({children = {...}})
end

-- bottom dock
local edit = Button('edit', {toggle = true})
local paste = Button('paste')
local copy = Button('copy')
local undo = Button('undo')
local redo = Button('redo')
local dock = Stack({children = {undo, copy, paste, edit, redo}})

-- menu
local more = Button('more_vert', {x = width - theme.button.size})
local add = Button('add')
local save = Button('save')
local settings = Button('settings')
local open = Button('open')
local menu = Dialog({children = {margin, row(add, open, margin), row(save, settings)}})

-- root
local fullscreen = Button('fullscreen', {toggle = true, on = true})
local canvas = GuiElement({width = width, height = height})
local window = GuiElement({children = {canvas, dock, fullscreen, more, menu}})

local testX = (width - dock.rect.width) / 2
local testY = height - dock.rect.height

menu.setPosition(width - menu.rect.width + corner, -(corner))
dock.setPosition(testX, testY)
dock.rect.height = dock.rect.height + corner

fullscreen.onPressed(function()
	F.forEach(function(child)
		child.visible = fullscreen.on
	end, window.children)
	fullscreen.visible = true
	menu.visible = false
end)

more.onPressed(function()
	menu.visible = true
end)

local log = F.thunkify(print)

F.forEach(function(x)
	x.onPressed(log(x.id, ' pressed'))
end, {add, save, settings, copy, undo, edit, paste})

return window

