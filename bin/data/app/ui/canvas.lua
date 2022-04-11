local grid = require('ui/grid')
local drawItem = require('ui/draw-item')
local each = require('libs/fun').each
local fn = require('utils/function')
local gfx = require('utils/graphics')
local s = require('utils/string')
local text = require('utils/text')
local fifo = require('utils/fifo')
local stopwatch = require('utils/stopwatch')
local createViewport = require('ui.viewport')
local pd = require('pd')
local events = require('events')
local findByTag, filterByTag = fn.findByTag, fn.filterByTag
local rejectByTag = fn.rejectByTag
local moveBy = gfx.moveBy

local back = 255
local iowidth = 7
local gridStep = 12
local trace = fifo(30)
local width = of.getWidth()
local height = of.getHeight()

grid.init(gridStep)

local function updateItem(update, item)
	if not item then return end
	if update.points then item.points = update.points end
	if update.value then item.value = update.value end
	if update.params then
		if not item.params then
			item.params = update.params
		else
			for key, value in pairs(update.params) do item.params[key] = value end
		end
	end
end

local toggleInt = function(x)
	if (x == 0) then
		return 1
	else
		return 0
	end
end

local function getX(node, x)
	if (node.outletCount == 1) then
		return iowidth / 2 --
	end
	local bla = x - node.x
	local d = (node.width - iowidth) / (node.outletCount - 1)
	local index = math.floor((bla + d / 2) / d)
	return index * d + iowidth / 2
end

return function(id)
	local M = {id = id, updateNeeded = true}
	local items = {}
	local viewport = createViewport(2)
	local editmode = 0

	local dragging = nil
	local touchDown = nil
	local lastTouch = nil

	M.touch = function(touch)
		local loc = viewport.screenToCanvas(touch)

		touch.x = math.floor(loc.x)
		touch.y = math.floor(loc.y)

		events.event(touch, items)

		if (touch.type == of.TouchEventArgs_down) then
			local selection = mpd.selectionActive()
			local node = mpd.getNode(touch.x, touch.y)
			--
			-- if editmode == 1 and node and node.outletCount > 0 and not selection then
			-- 	local x = getX(node, touch.x)
			-- 	pd.queue(id, 'mouse', node.x + x, node.y + node.height, '1 0')
			-- elseif editmode == 0 and not node then
			if editmode == 0 and not node then
				dragging = loc
			else
				pd.queue(id, 'mouse', touch.x, touch.y, '1 0')
			end
			touchDown = touch
			lastTouch = touch
		elseif (touch.type == of.TouchEventArgs_up) then
			dragging = nil
			touchDown = nil
			pd.queue(id, 'mouseup', touch.x, touch.y, '1')
		elseif (touch.type == of.TouchEventArgs_move) then
			if dragging then
				viewport.move(dragging - loc)
				M.updateNeeded = true
			elseif touch.x ~= lastTouch.x or touch.y ~= lastTouch.y then
				lastTouch = touch
				pd.queue(id, 'motion', touch.x, touch.y, '0')
			end
		elseif (touch.type == of.TouchEventArgs_doubleTap) then
			editmode = toggleInt(editmode)
			pd.queue(id, 'editmode', editmode)
		end
	end

	M.draw = function()
		local scale = viewport.scale

		of.pushMatrix()
		of.scale(scale, scale)
		of.translate(viewport.position() * -1)
		of.background(back)
		of.enableAntiAliasing()
		of.enableSmoothing()

		of.setColor(100)
		if scale >= 1 then grid.draw(0, 0) end
		of.setLineWidth(scale * 1.5)
		of.noFill()
		of.drawRectangle(0, 0, width + gridStep, height + gridStep)

		-- mpd.drawItems(scale)

		local finish = stopwatch.start('draw', 9)
		each(drawItem(viewport), items)
		finish()

		of.popMatrix()

		text.draw(s.joinLines(trace.items()), 50, 120)

		M.updateNeeded = false
	end

	M.message = function(msg)
		local finish = stopwatch.start('message', 0.15)
		local cmd, tag, points = msg.cmd, msg.tag, msg.points

		if cmd == 'coords' or cmd == 'set-text' or cmd == 'itemconfigure' then
			local match = findByTag(tag, items)
			if match then updateItem(msg, match) end
		elseif cmd == 'delete' then
			items = rejectByTag(tag, items)
		elseif cmd == 'scaleBegin' then
			pd.queue(id, 'mouseup', touchDown.x, touchDown.y, '1')
		elseif cmd == 'scale' then
			viewport.setScale(msg)
		elseif cmd == 'editmode' then
			editmode = msg.value
		elseif cmd == 'move' then
			forEach(function(x)
				x.points = map(moveBy(points[1]), x.points)
			end, filterByTag(tag, items))
		else
			items[#items + 1] = msg
		end

		M.updateNeeded = true

		if (not finish()) then log(msg.message, '\n') end
	end

	M.items = function()
		return items
	end

	return M
end

-- elseif cmd == 'rectangle' and includes('array', msg.tags) then
-- 	g.fbo:beginFbo()
-- 	of.setColor(0)
-- 	local x, y, w, h = toRect(msg.points[1], msg.points[2])
-- 	of.drawRectangle(x - g.points[1].x, y - g.points[1].y, w, h)
-- 	g.fbo:endFbo()
-- else
-- if cmd == 'polyline' and includes('graph', msg.tags) then
-- 	initGraph(msg) --
-- end
-- items[#items + 1] = msg
-- if value:sub(1, 4) == 'plot' then
-- 	console.log("value", value);
-- 	-- g.fbo:beginFbo()
-- 	-- g.fbo:endFbo()
-- 	local fbo = g.fbo
--
-- 	fbo:beginFbo()
-- 	of.enableAlphaBlending()
-- 	of.clear(255, 0)
-- 	of.background(255)
-- 	of.disableAlphaBlending()
-- 	fbo:endFbo()
--
-- else
-- local g = nil
-- local initGraph = function(item)
-- 	g = item
-- 	item.cmd = 'graph'
-- 	local fbo = of.Fbo()
-- 	local x, y, w, h = toRect(item.points[1], item.points[3])
-- 	fbo:allocate(w, h)
-- 	fbo:beginFbo()
-- 	of.enableAlphaBlending()
-- 	of.clear(255, 0)
-- 	of.background(255)
-- 	of.disableAlphaBlending()
-- 	fbo:endFbo()
-- 	item.fbo = fbo
-- end
-- useful if we invert colors
-- local color = g.hex(item.fill)
-- -- if (g.isGrey(color)) then color:invert() end
-- of.setColor(color)
--
-- local prev = nil
-- if msg.type == 'scaleEnd' then
-- 	prev = nil
-- 	return
-- end
-- if prev then
-- 	local curr = of.Vec2f(msg.x, msg.y) / Scale
-- 	local o = (curr - prev) * 0.7
-- 	viewport = viewport - o:vec2()
-- end
-- prev = of.Vec2f(msg.x, msg.y) / Scale

