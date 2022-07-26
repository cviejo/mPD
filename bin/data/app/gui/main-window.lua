local F = require('utils.functional')
local GuiElement = require('gui.element')
local Button = require('gui.button')
local Stack = require('gui.stack')
local theme = require('gui.theme')
local Dialog = require('gui.dialog')

local width, height = of.getWidth(), of.getHeight()

-- bottom dock
local edit = Button('edit', {toggle = true})
local paste = Button('paste')
local copy = Button('copy')
local undo = Button('undo')
local test = Stack({children = {copy, undo, edit, paste}})

-- menu
local more = Button('more_vert', {x = width - theme.button.size})
local add = Button('add')
local save = Button('save')
local settings = Button('settings')
local menu = Dialog({children = {Stack({children = {add, save}}), Stack({children = {settings}})}})

-- root
local fullscreen = Button('fullscreen', {toggle = true, on = true})
local canvas = GuiElement({width = width, height = height})
local window = GuiElement({children = {canvas, test, fullscreen, more, menu}})

local testX = (width - test.rect.width) / 2
local testY = height - test.rect.height

menu.setPosition(width - menu.rect.width, 0)
test.setPosition(testX, testY)
test.rect.height = test.rect.height + theme.corner

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

