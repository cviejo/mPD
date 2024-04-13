local F = require('utils.functional')
local getTouchTypes = require('utils.get-touch-types')
local capitalize = require('utils.capitalize')

local find, reverse, curry2 = F.find, F.reverse, F.curry2

local drawChild = function(x)
	if x.visible then
		x.draw()
	end
end

local addEvent = function(event, M)
	local listeners = {}

	M['on' .. capitalize(event)] = function(x)
		listeners[#listeners + 1] = x
	end
	M['notify' .. capitalize(event)] = function(x)
		for i = 1, #listeners do
			listeners[i](x)
		end
	end
end

local touchTest = curry2(function(touch, child)
	return child.visible and child.touch(touch)
end)

local function GuiElement(options)
	local M = {}

	M.id = 'id not set'
	M.children = {}
	M.rect = of.Rectangle(0, 0, 0, 0)
	M.visible = true
	M.pressed = false
	M.draw = F.noop
	M.clear = F.noop

	F.assign(M, options or {})
	F.assign(M.rect, F.pick({ 'x', 'y', 'width', 'height' }, M))

	addEvent('pressed', M)
	addEvent('released', M)
	addEvent('dragged', M)

	local activeElement = nil

	local inside = function(touch)
		if #M.children == 0 and M.rect:inside(touch.x, touch.y) then
			M.notifyPressed(touch)
			return M
		else
			activeElement = find(touchTest(touch), reverse(M.children))
			return activeElement
		end
	end

	M.touch = function(touch)
		local touchDown, touchUp, touchMoved = getTouchTypes(touch)

		if activeElement and touchUp then
			activeElement.notifyReleased(touch)
			activeElement = nil
		elseif activeElement and touchMoved then
			activeElement.notifyDragged(touch)
		elseif touchDown then
			return inside(touch)
		end
	end

	M.drawChildren = function()
		F.forEach(drawChild, M.children)
	end

	M.draw = M.drawChildren

	return M
end

return GuiElement

