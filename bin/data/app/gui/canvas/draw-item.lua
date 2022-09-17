local F = require('utils.functional')
local Font = require('utils.font')
local hasTag = require('utils.has-tag')
local toRect = require('utils.points').toRect
local logging = require('utils.logging')

local pipe, curry, safe, intersects = F.pipe, F.curry, F.safe, F.intersects
local complement = F.complement

local scale = 1
local front = 0
local font = Font("DejaVuSansMono", 9)

local setHex = safe(pipe(of.hexToInt, of.setHexColor))

font.setLineHeight(14)

local function drawText(item)
	local params, points = item.params, item.points
	local x, y = points[1].x, points[1].y

	setHex((params and params.fill) or '141414')

	if (params and params.font) then
		y = y + params.font / 3
		local fontScale = (params.font - 2) / font.size
		of.pushMatrix()
		of.translate(x, y)
		of.scale(fontScale, fontScale)
		font.drawString(params.text, 0, 0)
		of.popMatrix()
	else
		y = y + font.lineHeight - 3
		font.drawString(params.text, x, y)
	end
end

local function drawOval(item)
	local p1, p2 = item.points[1], item.points[2]
	mpd.drawEllipse(p1.x, p1.y, p2.x, p2.y, item.params.outline or '000000', item.params.fill or '')
end

local function drawLine(item)
	if hasTag('commentbar', item) then
		return
	end

	local width = item.params.width or 1
	local color = item.params.fill or front
	if (item.params.tags[1] == 'x') then
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
	local signal = hasTag('signal', item)
	local control = hasTag('control', item)
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

local function drawPolyLine(item)
	local graph = hasTag('graph', item)
	local object = intersects({'obj', 'atom', 'msg'}, item.params.tags)
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
		-- logging.log(logging.red('no path'), item.message)
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

local pointOutside = function(rect, point)
	local right, bottom = rect.x + rect.width, rect.y + rect.height
	return point.x > right or point.y > bottom
end

local pointInside = complement(pointOutside)

local outside = function(rect, item)
	local p1, p2 = item.points[1], item.points[2]
	local top, left = rect.y, rect.x
	local right, bottom = left + rect.width, top + rect.height
	-- LuaFormatter off
	return (p1.y < top and p2.y < top) or
		    (p1.y > bottom and p2.y > bottom) or
	       (p1.x > right and p2.x > right) or
	       (p1.x < left and p2.x < left)
	-- LuaFormatter on
end

return curry(function(viewport, item)
	scale = viewport.scale

	local cmd, rect = item.cmd, viewport.rect

	of.noFill()
	of.setColor(front)
	of.setLineWidth(viewport.scale)

	if cmd == 'rectangle' and not outside(rect, item) then
		drawRectangle(item)
	elseif cmd == 'line' and not outside(rect, item) then
		drawLine(item)
	elseif (cmd == 'polyline' or cmd == 'polygon') and pointInside(rect, item.points[1]) then
		drawPolyLine(item)
	elseif cmd == 'oval' and not outside(rect, item) then
		drawOval(item)
	elseif cmd == 'array' and not pointOutside(rect, item.points[1]) then
		drawArray(item)
	elseif cmd == 'text' and not pointOutside(rect, item.points[1]) then
		drawText(item)
	end
end)
-- LuaFormatter on
--
-- elseif item.cmd == 'graph' then
-- 	of.setColor(255, 255, 255, 255)
-- 	item.fbo:draw(item.points[1].x, item.points[1].y)
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

