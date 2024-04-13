local F = require('utils.functional')
local GuiElement = require('gui.element')
local theme = require('gui.theme')

local reduce, map, path, max, add, assign = F.reduce, F.map, F.path, F.max, F.add, F.assign

local findMax = reduce(max, 0)
local accum = reduce(add, 0)
local getHeights = map(path({ 'rect', 'height' }))
local getWidths = map(path({ 'rect', 'width' }))

local setPosition = function(x, y, child)
	if child.setPosition then
		child.setPosition(x, y)
	else
		assign(child.rect, { x = x, y = y })
	end
end

local arrangeChildren = function(orientation, rect, children)
	local x, y = rect.x, rect.y
	if orientation == 'vertical' then
		rect.width = findMax(getWidths(children))
		rect.height = accum(getHeights(children))
		reduce(function(acc, child)
			setPosition(x, acc, child)
			return acc + child.rect.height
		end, y, children)
	else
		rect.width = accum(getWidths(children))
		rect.height = findMax(getHeights(children))
		reduce(function(acc, child)
			setPosition(acc, y, child)
			return acc + child.rect.width
		end, x, children)
	end
end

local function Stack(options)
	local M = GuiElement(options)

	M.update = function()
		arrangeChildren(M.orientation, M.rect, M.children)
	end

	M.setPosition = function(x, y)
		M.rect.x = x
		M.rect.y = y
		M.update()
	end

	M.draw = function()
		of.setColor(theme.bg)
		of.drawRectRounded(M.rect, theme.corner)
		M.drawChildren()
	end

	M.update()

	return M
end

return Stack
