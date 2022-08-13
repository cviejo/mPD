local GuiElement = require('gui.element')
local Stack = require('gui.stack')

local width, height = of.getWidth(), of.getHeight()

local function Dialog(options)
	local M = GuiElement(options)

	local content = Stack({orientation = 'vertical', children = M.children})

	local background = GuiElement({width = width, height = height})

	local hide = function()
		M.visible = false
	end

	content.onPressed(hide)
	background.onPressed(hide)

	M.visible = false
	M.children = {background, content}
	M.rect = content.rect
	M.setPosition = content.setPosition

	return M
end

return Dialog
