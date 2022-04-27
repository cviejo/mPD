local grid = require('ui/grid')
local text = require('utils/text')
local drawItem = require('ui/draw-item')
local s = require('utils/string')
local fifo = require('utils/fifo')
local points = require('utils/points')
local cordMesh = require('ui/cord-mesh')
local stack = require('utils/stack')
local createViewport = require('ui/viewport')
local withViewport = require('ui/with-viewport')
local updateItem = require('utils.update-item')
local ofx = require('utils/of')
local pd = require('pd')
local events = require('events')

local back = 255
local iowidth = 7
local trace = fifo(30)

local function getOutletX(node, x)
	if (node.outletCount == 1) then
		return iowidth / 2
	end
	local distanceToLeft = x - node.x
	local interval = (node.width - iowidth) / (node.outletCount - 1)
	local index = math.floor((distanceToLeft + interval / 2) / interval)
	return index * interval + iowidth / 2
end

local function init(canvasId)
	pd.queue(canvasId, 'map 1')
	pd.queue(canvasId, 'query-editmode')
	pd.queue(canvasId, 'updatemenu')
	pd.queue(canvasId, 'editmode', 1)
end

local function createCords()
	return {
		signal = cordMesh(0x808093),
		control = cordMesh(0x323232),
		selected = nil
	}
end

return function(id, position)
	local M = {id = id, updateNeeded = true, items = stack()}

	local editmode = 0
	local cords = createCords()
	local viewport = createViewport(2)
	local lastTouch = nil

	init(id)

	local function reset()
		cords = createCords()
		M.items = stack()
	end

	-- LuaFormatter off
	local function update(item)
		if cords.signal.update(item) then return end
		if cords.control.update(item) then return end
		M.items.byTag(updateItem(item), item.tag)
	end

	local function delete(item)
		cords.selected = nil
		if cords.signal.delete(item) then return end
		if cords.control.delete(item) then return end
		M.items.delete(item.tag)
	end
	-- LuaFormatter on
	local function move(tag, offset)
		M.items.byTag(function(item)
			item.points = map(points.add(offset), item.points)
		end, tag)
	end

	local function selectedCord(msg)
		return {
			cmd = 'line',
			tag = msg.tag,
			tags = {},
			params = {width = 2, fill = '0000ff'},
			points = cords.control.getPoints(msg) or cords.signal.getPoints(msg)
		}
	end

	local function updateGrid()
		grid.adjustToViewport(viewport)
		M.updateNeeded = true
	end

	local function setScale(msg)
		if msg.type == 'scaleBegin' then -- dragging = vec2(lastTouch)
			pd.queue(id, 'mouseup', lastTouch.x, lastTouch.y, '1')
		end
		viewport.setScale(msg)
		updateGrid()
	end

	M.touch = function(touch)
		if viewport.scaling then
			return
		end

		-- take a look into this, should probably land here already offsetted
		local loc = viewport.screenToCanvas(points.subtract(touch, position))
		local x = math.floor(loc.x)
		local y = math.floor(loc.y)

		local touchDown = touch.type == 0 -- of.TouchEventArgs_down
		local touchUp = touch.type == 1 -- of.TouchEventArgs_up
		local touchMoved = touch.type == 2 -- of.TouchEventArgs_move

		-- events.event(touch, items)

		if viewport.dragging and touchUp then
			viewport.dragging = nil
		elseif viewport.dragging and touchMoved then
			viewport.drag(loc)
			updateGrid()
		elseif touchUp then
			pd.queue(id, 'mouseup', x, y, '1')
		elseif touchMoved and lastTouch and not points.equals(touch, lastTouch) then
			lastTouch = {x = x, y = y}
			pd.queue(id, 'motion', x, y, '0')
		elseif touchDown then
			local node = mpd.getNode(x, y)
			local selection = mpd.selectionActive()

			if editmode == 0 and not node and not viewport.dragging then
				viewport.dragging = loc
			elseif editmode == 1 and node and not selection then
				local iox = getOutletX(node, x)
				pd.queue(id, 'mouse', node.x + iox, node.y + node.height, '1 0')
			else
				pd.queue(id, 'mouse', x, y, '1 0')
			end

			lastTouch = {x = x, y = y}
		end
	end

	M.draw = withViewport(function(scale)
		of.translate(position.x / scale, position.y / scale)
		of.background(back)

		if editmode == 1 and scale >= 1 then
			of.setColor(100)
			grid.draw()
		end

		of.setLineWidth(scale)
		cords.control.draw()
		of.setLineWidth(2 * scale)
		cords.signal.draw()
		if (cords.selected) then
			drawItem(viewport, cords.selected)
		end

		M.items.forEach(drawItem(viewport))

		text.draw(s.joinLines(trace.items()), 50, 120)

		M.updateNeeded = false
	end, viewport)

	M.message = function(msg)
		M.updateNeeded = true

		if msg.cmd == 'array' then
			msg.mesh = ofx.pointsToMesh(msg.points)
			msg.points = {}
		elseif msg.cmd == 'polyline' or msg.cmd == 'polygon' then
			msg.path = ofx.pointsToPath(msg.points)
			msg.points = {}
		elseif msg.cmd == 'select-line' then
			cords.selected = selectedCord(msg)
			return
		elseif msg.cmd == 'unselect-line' then
			cords.selected = nil
			return
		end

		if msg.cmd == 'coords' or msg.cmd == 'set-text' or msg.cmd == 'itemconfigure' then
			update(msg)
		elseif msg.cmd == 'delete' then
			if msg.tag == 'all' then
				reset()
			else
				delete(msg)
			end
		elseif msg.cmd == 'scale' then
			setScale(msg)
		elseif msg.cmd == 'editmode' then
			editmode = msg.value
		elseif msg.cmd == 'move' then
			move(msg.tag, msg.points[1])
		elseif not msg.id then
			log(red("no id"))
			log(msg.message)
		elseif msg.cord and msg.params.width == 1 then
			cords.control.add(msg)
		elseif msg.cord then
			cords.signal.add(msg)
		else
			M.items.add(msg)
		end
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
-- 	fbo:beginFbo()
-- 	of.enableAlphaBlending()
-- 	of.clear(255, 0)
-- 	of.background(255)
-- 	of.disableAlphaBlending()
-- 	fbo:endFbo()
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

