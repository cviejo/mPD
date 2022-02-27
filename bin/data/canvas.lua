local grid = require('grid')
local each = require('libs/fun').each
local text = require('utils/text')
local f = require('utils/function')
local gfx = require('utils/graphics')
local findByTag, filterByTag = f.findByTag, f.filterByTag
local hasTag, safe, intersects = f.hasTag, f.safe, f.intersects
local moveBy = gfx.moveBy

local items = {}
local back = 255
local front = 0

grid.init(8)

local font = text.makeFont("fonts/DejaVuSansMono.ttf", 35)

-- eyeballed to match pd's dimensions
-- https://github.com/cviejo/mPD/blob/main/src/libs/pd/pure-data/src/s_main.c#L171
local lineHeight = 14 * 4
font:setLineHeight(lineHeight)

local setHex = safe(pipe(of.hexToInt, of.setHexColor))

local isObject = pipe(prop('tags'), intersects({'obj', 'atom', 'msg'}))

local purr = true

local function drawText(item)
	local x, y = item.points[1].x, item.points[1].y
	y = y + lineHeight / 4 - 3

	of.scale(.25, .25)
	of.setColor(20) -- purr
	font:drawString(item.text, x * 4, y * 4)
	of.scale(4, 4)
end

local function drawLine(item)
	local line = of.Polyline()
	local cord = includes('cord', item.tags)
	local width = tonumber(item.width)

	if (#item.points == 2) then
		of.enableSmoothing()
		of.setColor(front)
		setHex(item.fill)
		if (width > 1 and cord) then
			of.setColor(128, 128, 147) -- purr
		end
		of.setLineWidth(item.width * Scale)
		local p1, p2 = item.points[1], item.points[2]
		of.drawLine(p1.x, p1.y, p2.x, p2.y)
		return
	end

	if (purr and isObject(item)) then
		of.setColor(246, 248, 248)
	else
		of.setColor(255)
	end
	of.fill()
	of.beginShape()
	for _, p in ipairs(item.points) do
		line:addVertex(p.x, p.y)
		of.vertex(p.x, p.y)
	end
	of.endShape()
	of.setColor(front)
	setHex(item.fill)
	if (isObject(item)) then of.setColor(204) end
	if (cord) then of.setColor(88, 101, 86) end
	if (cord and item.width > 1) then of.setColor(128, 128, 147) end
	of.setLineWidth(item.width * Scale)
	of.disableSmoothing()
	line:draw()
end

local function drawRectangle(item)
	local x, y = item.points[1].x, item.points[1].y
	local w, h = item.points[2].x - x, item.points[2].y - y
	local signal = includes('signal', item.tags)
	local control = includes('control', item.tags)
	if (item.fill and not signal and not control) then
		setHex(item.fill)
		of.fill()
		of.drawRectangle(x, y, w, h)
	end
	if (signal) then
		of.setColor(128, 128, 147)
		of.fill()
		of.drawRectangle(x, y, w, h)
	end
	of.noFill()
	of.setColor(front)
	setHex(item.outline)
	if (control and h > 1) then of.setColor(100) end
	-- if (io and h > 1) then of.setColor(100) end
	if (signal) then of.setColor(118, 118, 147) end
	of.drawRectangle(x, y, w, h)
	-- of.scale(.25, .25)
	-- font:drawString(inspect(R.tail(item.tags)), item.points[1].x * 4,
	--                 item.points[1].y * 4)
	-- of.scale(4, 4)
end

local function drawOval(item)
	local points = item.points
	local x, y = points[1].x, points[1].y
	local dx, dy = points[2].x - x, points[2].y - y
	of.drawEllipse(x + dx / 2, y + dy / 2, dx, dy)
	if (item.fill) then
		setHex(item.fill)
		of.fill()
		of.drawEllipse(x + dx / 2, y + dy / 2, dx, dy)
	end
end

local resetStyles = function()
	of.noFill()
	of.setColor(front)
	of.setLineWidth(Scale)
end

-- LuaFormatter off
local drawItem = pipe(
	tap(resetStyles),
	cond({
		{propEq('shape', 'line'), drawLine},
		{propEq('shape', 'oval'), drawOval},
		{propEq('shape', 'rectangle'), drawRectangle},
		{propEq('cmd', 'new-text'), drawText},
	})
)
-- LuaFormatter on

local function updateItem(update, item)
	if not item then return end
	if update.width then item.width = update.width end
	if update.fill then item.fill = update.fill end
	if update.outline then item.outline = update.outline end
	if update.text then item.text = update.text end
	if update.points then item.points = update.points end
end

local function message(msg)
	local cmd, tag = msg.cmd, msg.tag
	if cmd == 'coords' or cmd == 'set-text' or cmd == 'configure' then
		updateItem(msg, findByTag(tag, items))
	elseif msg.cmd == 'delete' then
		items = reject(hasTag(tag), items)
	elseif msg.cmd == 'move' then
		forEach(function(x)
			x.points = map(moveBy(msg.points[1]), x.points)
		end, filterByTag(tag, items))
	else
		table.insert(items, msg)
	end
end

local function draw()
	of.pushMatrix()
	of.background(back)
	of.scale(Scale, Scale)
	of.enableAntiAliasing()
	of.enableSmoothing()

	if Scale >= 1 then grid.draw(-1, -1) end

	each(drawItem, items)

	of.popMatrix()
end

return {
	draw = draw,
	message = message,
	items = function()
		return items
	end
}

-- useful if we invert colors
-- local color = g.hex(item.fill)
-- -- if (g.isGrey(color)) then color:invert() end
-- of.setColor(color)
