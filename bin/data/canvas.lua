local fn = require('utils/function')
local grid = require('grid')
local safe = fn.safe

local items = {}
local back = 255
local front = 0

grid.init(20)

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

local function drawLine(item)
	setHex(item.fill)
	of.setLineWidth(tonumber(item.width) * Scale)
	local polyline = of.Polyline()
	for _, p in ipairs(item.points) do
		polyline:addVertex(p.x, p.y) --
	end
	of.disableSmoothing()
	polyline:draw()
end

local function drawRectangle(item)
	-- if not points or #points < 2 then return end
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
		-- console.log("msg", msg);
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

local resetItem = function()
	of.noFill()
	of.setColor(front)
	of.setLineWidth(Scale)
end

-- LuaFormatter off
local drawItem = pipe(
	tap(resetItem),
	cond({
		{shapeEq('line'), drawLine},
		{shapeEq('rectangle'), drawRectangle},
		{shapeEq('oval'), drawOval},
	})
)
-- LuaFormatter on

local function draw()
	of.background(back)
	of.pushMatrix()
	of.scale(Scale, Scale)
	of.enableAlphaBlending()
	of.enableAntiAliasing()

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

