local GuiElement = require('gui.element')
local Stack = require('gui.stack')

local function updateBackground(background)
	background.rect.width = of.getWidth()
	background.rect.height = of.getHeight()
end

local function Dialog(options)
	local M = GuiElement(options)

	local content = Stack({orientation = 'vertical', children = M.children})

	local background = GuiElement({})

	local hide = function()
		M.visible = false
	end

	content.onPressed(hide)
	background.onPressed(hide)
	updateBackground(background)

	M.visible = false
	M.children = {background, content}
	M.rect = content.rect
	M.setPosition = function(x, y)
		content.setPosition(x, y)
		updateBackground(background)
	end

	return M
end

return Dialog
