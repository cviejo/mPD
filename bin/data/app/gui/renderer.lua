local GuiElement = require('gui.element')
local Canvas = require('gui.canvas')

local width, height = of.getWidth(), of.getHeight()

local patch = nil

local callOnPatch = function(functionName)
	return function(arg)
		if patch then
			patch[functionName](arg)
		end
	end
end

local M = GuiElement({id = 'renderer', width = width, height = height})

M.onPressed(callOnPatch('onPressed'))

M.onDragged(callOnPatch('onDragged'))

M.onReleased(callOnPatch('onReleased'))

M.draw = callOnPatch('draw')

M.message = function(msg)
	if msg.cmd == 'new-canvas' and msg.canvasId then
		patch = Canvas(msg.canvasId)
	elseif patch then
		patch.message(msg)
	end
end

return M
