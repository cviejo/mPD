local grid = require('grid')
local each = require('libs/fun').each
local fn = require('utils/function')
local gfx = require('utils/graphics')
local drawItem = require('./draw-item')
local findByTag, filterByTag = fn.findByTag, fn.filterByTag
local hasTag = fn.hasTag
local moveBy = gfx.moveBy

local M = {}
local items = {}
local back = 255

grid.init(8)

local viewport = of.Rectangle()
local width = of.getWidth()
local height = of.getHeight()

local startScale = 2

viewport:set(0, 0, width / startScale, height / startScale)

local function updateItem(update, item)
	if not item then return end
	if update.width then item.width = update.width end
	if update.fill then item.fill = update.fill end
	if update.outline then item.outline = update.outline end
	if update.text then item.text = update.text end
	if update.points then item.points = update.points end
end

local function screenToCanvas(p)
	return {x = p.x / Scale + viewport.x, y = p.y / Scale + viewport.y};
end

local function scale(msg)
	local before = screenToCanvas(msg)
	if msg.type == 'scroll' then
		Scale = Scale + msg.value * 0.1
	elseif msg.type == 'scale' then
		Scale = Scale * msg.value
	end
	Scale = clamp(0.5, 6, Scale)
	local after = screenToCanvas(msg)
	viewport:setX(viewport.x + before.x - after.x)
	viewport:setY(viewport.y + before.y - after.y)
	if viewport.x < 0 then viewport:setX(0) end
	if viewport.y < 0 then viewport:setY(0) end
end

M.message = function(msg)
	local cmd, tag, points = msg.cmd, msg.tag, msg.points

	if cmd == 'coords' or cmd == 'set-text' or cmd == 'configure' then
		updateItem(msg, findByTag(tag, items))
	elseif cmd == 'delete' then
		items = reject(hasTag(tag), items)
	elseif cmd == 'scale' then
		scale(msg)
	elseif cmd == 'move' then
		forEach(function(x)
			x.points = map(moveBy(points[1]), x.points)
		end, filterByTag(tag, items))
	else
		table.insert(items, msg)
	end
end

M.draw = function()
	of.pushMatrix()
	of.scale(Scale, Scale)
	of.translate(viewport:getPosition() * -1)

	of.background(back)
	of.enableAntiAliasing()
	of.enableSmoothing()

	of.setColor(255)
	if Scale >= 1 then grid.draw(-1, -1) end

	each(drawItem, items)

	of.popMatrix()
end

M.items = function()
	return items
end

return M

-- useful if we invert colors
-- local color = g.hex(item.fill)
-- -- if (g.isGrey(color)) then color:invert() end
-- of.setColor(color)
