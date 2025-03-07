local F = require('utils.functional')
local GuiElement = require('gui.element')
local Button = require('gui.button')
local Stack = require('gui.stack')
local theme = require('gui.theme')
local Dialog = require('gui.dialog')
local renderer = require('gui.renderer')
local onPressHandler = require('gui.on-press')
local grid = require('gui.canvas.grid')

local onPress = F.thunkify(onPressHandler)

local row = function(...)
	return Stack({ children = { ... } })
end

local dock = row(Button('undo'), Button('copy'), Button('paste'), Button('clear'),
                 Button('edit', { toggle = true }), Button('redo'))

local LabelButton = function(id, options)
	return Button(id, F.merge({ label = F.toUpper(id) }, options or {}))
end

-- menu
local menuItemSize = { size = theme.button.size * 1.4 }
local more = Button('more-vert')
local layers = Button('layers')
local add = LabelButton('add', menuItemSize)
local save = LabelButton('save', menuItemSize)
local settings = LabelButton('settings', menuItemSize)
local open = LabelButton('open', menuItemSize)
local menu = Dialog({ children = { row(add, open), row(save, settings) } })

-- root
local fullscreen = Button('fullscreen', { toggle = true, on = true })
local window = GuiElement({ children = { renderer, dock, fullscreen, more, layers, menu } })

local arrange = function()
	local center = of.getWindowRect():getCenter()

	menu.setPosition(center.x - menu.rect.width / 2, center.y - menu.rect.height / 2)
	dock.setPosition(center.x - dock.rect.width / 2, of.getHeight() - dock.rect.height)

	more.rect.x = of.getWidth() - theme.button.size
	layers.rect.x = (of.getWidth() - layers.rect.width) / 2
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

window.message = function(msg)
	if msg.cmd == 'touch' then
		window.touch(msg)
	elseif msg.cmd == 'orientation' then
		grid.init()
		arrange()
		setTimeout(arrange, 300) -- timeout fixes some artifacts when rearranging
	else
		renderer.message(msg)
	end
end

F.forEach(function(x)
	x.onPressed(onPress(x))
end, F.concat(dock.children, { add, save, settings }))

arrange()

return window
