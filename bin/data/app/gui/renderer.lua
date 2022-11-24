local GuiElement = require('gui.element')
local Canvas = require('gui.canvas')

local width, height = of.getWidth(), of.getHeight()

local M = GuiElement({id = 'renderer', width = width, height = height})

local callOnPatch = function(functionName)
	return function(arg)
		if M.patch then
			M.patch[functionName](arg)
		end
	end
end

M.patch = nil

M.onPressed(callOnPatch('onPressed'))

M.onDragged(callOnPatch('onDragged'))

M.onReleased(callOnPatch('onReleased'))

M.draw = callOnPatch('draw')

M.message = function(msg)
	if msg.cmd == 'new-canvas' and msg.canvasId then
		M.patch = Canvas(msg.canvasId)
	elseif M.patch then
		M.patch.message(msg)
	end
end

return M
