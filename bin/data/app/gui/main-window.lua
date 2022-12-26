local F = require('utils.functional')
local GuiElement = require('gui.element')
local Button = require('gui.button')
local Stack = require('gui.stack')
local theme = require('gui.theme')
local Dialog = require('gui.dialog')
local renderer = require('gui.renderer')
local pd = require('pd')

local row = function(...)
	return Stack({children = {...}})
end

-- dock
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
local menu = Dialog({children = {row(add, open), row(save, settings)}})

-- root
local fullscreen = Button('fullscreen', {toggle = true, on = true})
local window = GuiElement({children = {renderer, dock, fullscreen, more, layers, menu}})

local arrange = function()
	local center = of.getWindowRect():getCenter()

	menu.setPosition(center.x - menu.rect.width / 2, center.y - menu.rect.height / 2)
	dock.setPosition(center.x - dock.rect.width / 2, of.getHeight() - dock.rect.height)

	more.rect.x = of.getWidth() - theme.button.size
	layers.rect.x = (of.getWidth() - layers.rect.width) / 2
end

local onCanvasAction = F.thunkify(function(btn)
	if renderer.patch then
		local patchId = renderer.patch.id

		if btn.id == 'edit' then
			pd.queue(patchId, 'editmode', (btn.on and '1' or '0'))
		elseif (btn.id == 'redo' or btn.id == 'undo' or btn.id == 'copy' or btn.id == 'paste') then
			pd.queue(patchId, btn.id)
		elseif btn.id == 'clear' then
			pd.delete(patchId)
		end
	end
end)

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
		arrange()
		setTimeout(arrange, 300) -- timeout fixes some artifacts when rearranging
	else
		renderer.message(msg)
	end
end

F.forEach(function(x)
	x.onPressed(onCanvasAction(x))
end, dock.children)

arrange()

return window

-- F.forEach(function(x)
-- 	x.onPressed(function()
-- 		menu.visible = false -- maybe do this only on menu.children.onPressed
-- 		local message = "gui pressed " .. x.id .. ' ' .. print("message: " .. message)
-- 		of.sendMessage(message)
-- 	end)
-- end, {add, save, settings, copy, undo, redo, clear, edit, paste})

