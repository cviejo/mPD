local F = require('utils.functional')
local GuiElement = require('gui.element')
local Stack = require('gui.canvas.items-stack')
local Viewport = require('gui.canvas.viewport')
local Cords = require('gui.canvas.cords')
local drawItem = require('gui.canvas.draw-item')
local grid = require('gui.canvas.grid')
local updateItem = require('gui.canvas.update-item')
local hasTag = require('utils.has-tag')
local logging = require('utils.logging')
local nearestOuletPos = require('utils.nearest-outlet-pos')
local ofx = require('utils.of')
local points = require('utils.points')
local pd = require('pd')

local map = F.map

local scaleEvent = {scale = 1, scaleBegin = 1, scaleEnd = 1, scroll = 1}

return function(id)
	pd.queue(id, 'map 1;', id, 'updatemenu;', id, 'editmode', 0)

	local M = GuiElement({id = id})

	local items = Stack()
	local cords = Cords()
	local viewport = Viewport(1)
	local editmode = 0
	local lastTouch = nil

	local touchHandler = F.curry(function(fn, touch)
		if viewport.scaling then
			return
		end
		local scaled = viewport.screenToCanvas(touch)
		local floored = {x = math.floor(scaled.x), y = math.floor(scaled.y)}
		fn(touch, scaled, floored)
	end)

	local function update(item)
		if not cords.update(item) then
			items.byTag(updateItem(item), item.tag)
		end
	end

	local function delete(item)
		if item.tag == 'all' then
			items = Stack()
			cords.clear()
		elseif not cords.delete(item) then
			items.delete(item.tag)
		end
	end

	local function move(tag, offset)
		items.byTag(function(item)
			item.points = map(points.add(offset), item.points)
		end, tag)
	end

	local function updateGrid()
		grid.adjustToViewport(viewport)
		M.updateNeeded = true
	end

	local function setScale(msg)
		if msg.cmd == 'scaleBegin' then -- dragging = vec2(lastTouch)
			pd.queue(id, 'mouseup', lastTouch.x, lastTouch.y, '1')
		end
		viewport.setScale(msg)
		updateGrid()
	end

	M.onPressed = touchHandler(function(_, scaled, floored)
		local node = mpd.getNode(floored.x, floored.y)
		local selection = mpd.selectionActive()

		if editmode == 0 and not node and not viewport.dragging then
			viewport.dragging = scaled
		elseif editmode == 1 and node and not selection then
			local iox = nearestOuletPos(node, floored.x)
			pd.queue(id, 'mouse', node.x + iox, node.y + node.height, '1 0')
		else
			pd.queue(id, 'mouse', floored.x, floored.y, '1 0')
		end

		lastTouch = floored
	end)

	M.onDragged = touchHandler(function(touch, scaled, floored)
		if viewport.dragging then
			viewport.drag(scaled)
			updateGrid()
		elseif lastTouch and not points.equals(touch, lastTouch) then
			lastTouch = floored
			pd.queue(id, 'motion', floored.x, floored.y, '0')
		end
	end)

	M.onReleased = touchHandler(function(_, __, floored)
		if viewport.dragging then
			viewport.dragging = nil
		else
			pd.queue(id, 'mouseup', floored.x, floored.y, '1')
		end
	end)

	M.message = function(msg)
		M.updateNeeded = true

		local cmd = msg.cmd

		if cmd == 'array' then
			msg.mesh = ofx.pointsToMesh(msg.points)
			msg.points = {msg.points[1]}
		elseif cmd == 'polyline' or cmd == 'polygon' then
			msg.path = ofx.pointsToPath(msg.points)
			msg.points = {msg.points[1]}
		end

		if cmd == 'coords' or cmd == 'set-text' or cmd == 'itemconfigure' then
			update(msg)
		elseif cmd == 'move' then
			move(msg.tag, msg.points[1])
		elseif cmd == 'delete' then
			delete(msg)
		elseif scaleEvent[cmd] then
			setScale(msg)
		elseif cmd == 'editmode' then
			editmode = msg.value
		elseif not msg.id then
			logging.log(logging.red('no id'), msg)
		elseif hasTag('cord', msg) then
			cords.add(msg)
		else
			items.add(msg)
		end
	end

	M.draw = function()
		of.pushMatrix()
		of.scale(viewport.scale, viewport.scale)
		of.translate(viewport.position() * -1)
		of.background(255)

		if editmode == 1 and viewport.scale >= 1 then
			of.setColor(100)
			grid.draw()
		end

		cords.draw(viewport)
		items.forEach(drawItem(viewport))

		of.fill()
		of.popMatrix()
	end

	return M
end
