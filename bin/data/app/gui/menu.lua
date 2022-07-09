local GuiElement = require('gui.element')
local Stack = require('gui.stack')
local Button = require('gui.button')
-- local theme = require('theme')

local width, height = of.getWidth(), of.getHeight()

local container = GuiElement({visible = false})

local hide = function()
	container.visible = false
end

-- LuaFormatter off
local rows = {
	Stack({children = {Button({id = 'add'}), Button({id = 'save'})}}),
	Stack({children = {Button({id = 'settings'})}})
}
-- LuaFormatter on
local menu = Stack({id = 'menu', orientation = 'vertical', children = rows})

local pad = GuiElement({id = 'bg', width = width, height = height})

menu.setPosition(width - menu.rect.width, menu.rect.y)

menu.onPressed(function(x)
	print('pressed', x.id)
end)

pad.onPressed(hide)

container.children = {pad, menu}

return container
