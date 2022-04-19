local text = require('utils/text')
local fn = require('utils/function')
local toRect = require('utils/to-rect')
local safe, intersects, hasTag = fn.safe, fn.intersects, fn.hasTag

local front = 0
local scale = 1

local isSignal = hasTag('signal')
local isControl = hasTag('control')
local isGraph = hasTag('graph')
local isCord = hasTag('cord')

local fontScale = 4
local font = text.makeFont("fonts/DejaVuSansMono.ttf", 9 * fontScale - 1)
-- eyeballed to match pd's dimensions
-- https://github.com/cviejo/mPD/blob/main/src/libs/pd/pure-data/src/s_main.c#L171
local lineHeight = 14 * fontScale
font:setLineHeight(lineHeight)

local setHex = safe(pipe(of.hexToInt, of.setHexColor))

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
	drawString(item.value, x, y)
end

local function drawRectangle(item)
	local signal = isSignal(item)
	local control = isControl(item)
	local x, y, w, h = toRect(item.points[1], item.points[2])

	-- sliders, etc. TODO: only draw in editmode
	if h == 1 then
		return
	end

	local color = front
	local fill = ''

	if (item.params.fill and not signal and not control) then
		fill = item.params.fill
	elseif signal then
		fill = '808093'
	end

	if (control and h > 1) then
		color = '646464'
	elseif (signal) then
		color = '767693'
	elseif item.params.outline then
		color = item.params.outline
	end

	if not signal and not control and h == 2 then
		mpd.drawLine(x, y, x + w, y, color, h * scale)
	else
		mpd.drawRectangle(x, y, w, h, color, fill)
	end
end

local function drawArray(item)
	local width = item.params.width or 1
	of.setLineWidth(width * scale)
	setHex(item.params.fill or front)
	item.mesh:draw()
end

local function drawLine(item)
	local cord = isCord(item)
	local width = item.params.width or 1

	local color = front

	if (width > 1 and (cord or item.tags[1] == 'x')) then
		color = '808093'
	elseif cord then
		color = '323232'
	elseif item.params.fill then
		color = item.params.fill
	end
	local p1, p2 = item.points[1], item.points[2]
	mpd.drawLine(p1.x, p1.y, p2.x, p2.y, color, width * scale)
end

local function drawPolyLine(item)
	-- local line = of.Path()
	local graph = isGraph(item)
	local object = intersects({'obj', 'atom', 'msg'}, item.tags)
	local width = item.params.width or 1

	local fill = item.params.fill
	local outline = item.params.outline or front

	if object then
		fill = 'f6f8f8'
	end
	if object then
		outline = '8c8c8c'
	end
	if graph then
		fill = 'ffffff'
	end
	if graph then
		outline = '000000'
	end

	-- if (graph or object) and #item.points == 5 then
	-- 	local x, y, w, h = toRect(item.points[1], item.points[3])
	-- 	mpd.drawRectangle(x, y, w, h, outline, fill)
	-- 	return
	-- end
	if not item.path then
		log(red('no path'), item.message)
		return
	end

	if fill then
		item.path:setHexColor(of.hexToInt(fill))
		item.path:setFilled(true)
		item.path:draw()
	end

	-- setHex(outline or item.params.fill or front)

	-- item.path:setFilled(true)
	-- item.path:draw()

	of.setLineWidth(width * scale)
	item.path:setFilled(false)
	item.path:setStrokeHexColor(of.hexToInt(outline))
	item.path:setStrokeWidth(scale);
	item.path:draw()

end

local function drawOval(item)
	local p1, p2 = item.points[1], item.points[2]
	mpd.drawEllipse(p1.x, p1.y, p2.x, p2.y, item.params.outline or '000000',
	                item.params.fill or '')
end

local inside = function(rect, item)
	local top, left = rect.y, rect.x
	local bottom, right = top + rect.height, left + rect.width
	local p1, p2 = item.points[1], item.points[2]
	-- LuaFormatter off
	return (p1.x > left and p1.x < right and p1.y > top and p1.y < bottom) or
	       (p2.x > left and p2.x < right and p2.y > top and p2.y < bottom)
	-- LuaFormatter on
end

-- local inside = function(rect, item)
-- 	return true
-- end

return curry2(function(viewport, item)
	scale = viewport.scale

	of.noFill()
	of.setColor(front)
	of.setLineWidth(viewport.scale)

	if item.cmd == 'rectangle' and inside(viewport.rect, item) then
		drawRectangle(item)
	elseif item.cmd == 'line' and inside(viewport.rect, item) then
		drawLine(item)
	elseif item.cmd == 'polyline' or item.cmd == 'polygon' then
		drawPolyLine(item)
	elseif item.cmd == 'oval' and inside(viewport.rect, item) then
		drawOval(item)
	elseif item.cmd == 'array' then
		drawArray(item)
		-- elseif item.cmd == 'graph' then
		-- 	of.setColor(255, 255, 255, 255)
		-- 	item.fbo:draw(item.points[1].x, item.points[1].y)
		-- elseif item.cmd == 'new-text' then
		-- 	drawText(item)
	end

	-- {propEq('shape', 'text'), drawText},
	-- {propEq('cmd', 'text'), drawText},
	-- {propEq('cmd', 'new-text'), drawText},
end)
-- LuaFormatter on

-- local function drawRectangle(item)
-- 	local signal = includes('signal', item.tags)
-- 	local control = includes('control', item.tags)
-- 	local x, y, w, h = toRect(item.points[1], item.points[2])
-- 	if h == 1 then
-- 		return -- sliders, etc. TODO: only draw in editmode
-- 	end
-- 	if (item.fill and not signal and not control) then
-- 		setHex(item.fill)
-- 		of.fill()
-- 		of.drawRectangle(x, y, w, h)
-- 	end
-- 	if (signal) then
-- 		of.setColor(128, 128, 147)
-- 		of.fill()
-- 		of.drawRectangle(x, y, w, h)
-- 	end
-- 	of.noFill()
-- 	-- of.setColor(front)
-- 	-- setHex(item.outline)
-- 	-- if (control and h > 1) then of.setColor(100) end
-- 	-- if (signal) then of.setColor(118, 118, 147) end
-- 	if (control and h > 1) then
-- 		of.setColor(100)
-- 	elseif (signal) then
-- 		of.setColor(118, 118, 147)
-- 	elseif item.outline then
-- 		setHex(item.outline)
-- 	else
-- 		of.setColor(front)
-- 	end
-- 	of.drawRectangle(x, y, w, h)
-- end

