local text = require('utils/text')
local fn = require('utils/function')
local safe, intersects = fn.safe, fn.intersects

local front = 0

local fontScale = 4
local font = text.makeFont("fonts/DejaVuSansMono.ttf", 9 * fontScale - 1)
-- eyeballed to match pd's dimensions
-- https://github.com/cviejo/mPD/blob/main/src/libs/pd/pure-data/src/s_main.c#L171
local lineHeight = 14 * fontScale
font:setLineHeight(lineHeight)

local setHex = safe(pipe(of.hexToInt, of.setHexColor))

local toRect = function(p1, p2)
	return p1.x, p1.y, p2.x - p1.x, p2.y - p1.y
end

local drawString = function(txt, x, y)
	of.scale(1 / fontScale, 1 / fontScale)
	of.setColor(20)
	font:drawString(txt, x * fontScale, y * fontScale)
	of.scale(fontScale, fontScale)
end

local function drawText(item)
	local x, y = item.points[1].x, item.points[1].y
	if (item.cmd == 'new-text') then
		y = y + lineHeight / fontScale - 3
	elseif (item.font) then
		y = y + item.font.size / 2
	end
	drawString(item.text, x, y)
end

local function drawRectangle(item)
	local signal = includes('signal', item.tags)
	local control = includes('control', item.tags)
	local x, y, w, h = toRect(item.points[1], item.points[2])
	if h == 1 then return end
	-- if h == 1 and includes('outlet', item.tags) then
	-- 	return of.drawLine(x, y + 1, x + w, y + 1)
	-- end
	-- if h == 1 and includes('inlet', item.tags) then
	-- 	return of.drawLine(x, y, x + w, y)
	-- end
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
	if (signal) then of.setColor(118, 118, 147) end
	of.drawRectangle(x, y, w, h)
end

local function drawLine(item)
	if (item.width > 1 and includes('cord', item.tags)) then
		of.setColor(128, 128, 147) -- purr
	elseif item.fill then
		setHex(item.fill) --
	end
	of.setLineWidth(item.width * Scale)
	local p1, p2 = item.points[1], item.points[2]
	of.enableSmoothing()
	of.enableAntiAliasing()
	of.drawLine(p1.x, p1.y, p2.x, p2.y)
end

local function drawPolyLine(item)
	local line = of.Polyline()
	local object = intersects({'obj', 'atom', 'msg'}, item.tags)
	local graph = includes('graph', item.tags)

	if object or graph then
		of.fill() --
	else
		-- log(item.message)
	end
	if object then
		of.setColor(246, 248, 248) --
	end
	if graph then
		of.setColor(255) --
	end

	of.beginShape()
	forEach(function(p)
		line:addVertex(p.x, p.y)
		of.vertex(p.x, p.y) --
	end, item.points)
	of.endShape()

	setHex(item.outline or item.fill or front)
	if (object) then
		of.setColor(204) --
	end
	of.setLineWidth(item.width * Scale)
	line:draw()
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
return pipe(
	tap(resetStyles),
	cond({
		{propEq('shape', 'line'), drawLine},
		{propEq('shape', 'polyline'), drawPolyLine},
		{propEq('shape', 'polygon'), drawPolyLine},
		{propEq('shape', 'text'), drawText},
		{propEq('shape', 'oval'), drawOval},
		{propEq('shape', 'rectangle'), drawRectangle},
		{propEq('shape', 'text'), drawText},
		{propEq('cmd', 'new-text'), drawText},
	})
)
-- LuaFormatter on

