local F = require('utils.functional')
local GuiElement = require('gui.element')
local Button = require('gui.button')
local Stack = require('gui.stack')
local menu = require('gui.menu')
local theme = require('gui.theme')

local width, height = of.getWidth(), of.getHeight()

local fullscreen = Button({id = 'fullscreen', toggle = true})
local edit = Button({id = 'edit', toggle = true})
local paste = Button({id = "paste"})
local copy = Button({id = "copy"})
local undo = Button({id = "undo"})
local settings = Button({id = "more_vert", x = width - theme.button.size})

local test = Stack({children = {copy, undo, edit, paste}})
local window = GuiElement({children = {test, fullscreen, settings, menu}})

test.setPosition((width - test.rect.width) / 2, height - test.rect.height)
test.rect.height = test.rect.height + theme.corner

fullscreen.on = true
fullscreen.onPressed(function()
	F.forEach(function(child)
		child.visible = fullscreen.on
	end, window.children)
	fullscreen.visible = true
	menu.visible = false
end)

settings.onPressed(function()
	menu.visible = true
end)

return window
