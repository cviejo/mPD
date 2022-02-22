local fn = require('utils/function')
local text = require('utils/text')
local grid = require('grid')
local safe = fn.safe

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

local hasTag = function(tag)
	return function(x)
		return (x.tags and includes(tag, x.tags))
	end
end

local findByTag = function(tag, xs)
	return find(hasTag(tag), xs)
end

local shapeEq = propEq('shape')

local cmdEq = propEq('cmd')

local function drawText(item)
	local x, y = item.points[1].x, item.points[1].y
	y = y + lineHeight / 4 - 3

	of.scale(.25, .25)
	font:drawString(item.text, x * 4, y * 4)
	of.scale(4, 4)
end

local function drawLine(item)
	local line = of.Polyline()
	of.setColor(255)
	of.fill()
	of.beginShape()
	for _, p in ipairs(item.points) do
		line:addVertex(p.x, p.y)
		of.vertex(p.x, p.y)
	end
	of.endShape()
	of.setColor(front)
	setHex(item.fill)
	of.setLineWidth(tonumber(item.width) * Scale)
	of.disableSmoothing()
	line:draw()
end

local function drawRectangle(item)
	local x, y = item.points[1].x, item.points[1].y
	local w, h = item.points[2].x - x, item.points[2].y - y
	if (item.fill) then
		setHex(item.fill)
		of.fill()
		of.drawRectangle(x, y, w, h)
	end
	of.noFill()
	of.setColor(front)
	setHex(item.outline)
	of.drawRectangle(x, y, w, h)
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

local function message(msg)
	if msg.cmd == 'coords' then
		local found = findByTag(msg.id, items)

		if found then found.points = msg.points end
	elseif msg.cmd == 'move' then
		local found = findByTag(msg.id, items)

		if found then
			local point = found.points[1]
			point.x = point.x + msg.points[1].x
			point.y = point.y + msg.points[1].y
		end
	elseif msg.cmd == 'delete' then
		items = reject(hasTag(msg.tag), items)
	elseif msg.cmd == 'configure' then
		local found = findByTag(msg.id, items)

		if found then --
			if msg.fill then found.fill = msg.fill end
			if msg.outline then found.outline = msg.outline end
		end
	else
		table.insert(items, msg)
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
		{shapeEq('line'), drawLine},
		{shapeEq('oval'), drawOval},
		{shapeEq('rectangle'), drawRectangle},
		{cmdEq('new-text'), drawText},
	})
)
-- LuaFormatter on

local function draw()
	of.pushMatrix()
	of.background(back)
	of.scale(Scale, Scale)
	of.enableAntiAliasing()
	of.enableSmoothing()
	of.enableAlphaBlending()

	if Scale >= 1 then grid.draw(-1, -1) end

	forEach(drawItem, items)

	of.disableAlphaBlending()
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
