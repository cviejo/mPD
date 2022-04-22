local Font = require('utils/font')
local fn = require('utils.functional')
local points = require('utils/points')
local safe, intersects, hasTag = fn.safe, fn.intersects, fn.hasTag

local front = 0
local scale = 1

-- only used once, remove
local isSignal = hasTag('signal')
local isControl = hasTag('control')
local isGraph = hasTag('graph')

local setHex = safe(pipe(of.hexToInt, of.setHexColor))

local font = Font("DejaVuSansMono", 9)

font.setLineHeight(14)

local function drawText(item)
	local x, y = item.points[1].x, item.points[1].y
	setHex((item.params and item.params.fill) or '141414')
	if (item.params and item.params.fontsize) then
		y = y + item.params.fontsize / 3
		local fontScale = (item.params.fontsize - 2) / font.size
		of.pushMatrix()
		of.translate(x, y)
		of.scale(fontScale, fontScale)
		font.drawString(item.value, 0, 0)
		of.popMatrix()
	else
		y = y + font.lineHeight - 3
		font.drawString(item.value, x, y)
	end
end

local function drawOval(item)
	local p1, p2 = item.points[1], item.points[2]
	mpd.drawEllipse(p1.x, p1.y, p2.x, p2.y, item.params.outline or '000000',
	                item.params.fill or '')
end

local function drawLine(item)
	local width = item.params.width or 1
	local color = item.params.fill or front
	if (item.tags[1] == 'x') then
		color = '808093'
	end
	local p1, p2 = item.points[1], item.points[2]
	mpd.drawLine(p1.x, p1.y, p2.x, p2.y, color, width * scale)
end

local function drawArray(item)
	local width = item.params.width or 1
	of.setLineWidth(width * scale)
	setHex(item.params.fill or front)
	item.mesh:draw()
end

local function drawRectangle(item)
	local signal = isSignal(item)
	local control = isControl(item)
	local x, y, w, h = points.toRect(item.points[1], item.points[2])

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

local function drawPolyLine(item)
	local graph = isGraph(item)
	local object = intersects({'obj', 'atom', 'msg'}, item.tags)
	local width = item.params.width or 1

	local fill = item.params.fill
	local outline = item.params.outline or front

	if object then
		fill = 'f6f8f8'
		outline = '8c8c8c'
	elseif graph then
		fill = 'ffffff'
		outline = '000000'
	end
	if item.params.fill == '0000ff' then
		outline = item.params.fill
	end

	if not item.path then
		log(red('no path'), item.message)
		return
	elseif fill then
		item.path:setHexColor(of.hexToInt(fill))
		item.path:setFilled(true)
		item.path:draw()
	end

	of.setLineWidth(width * scale)
	item.path:setFilled(false)
	item.path:setStrokeHexColor(of.hexToInt(outline))
	item.path:setStrokeWidth(scale);
	item.path:draw()
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

return curry(function(viewport, item)
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
	elseif item.cmd == 'new-text' then
		drawText(item)
		-- elseif item.cmd == 'graph' then
		-- 	of.setColor(255, 255, 255, 255)
		-- 	item.fbo:draw(item.points[1].x, item.points[1].y)
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

