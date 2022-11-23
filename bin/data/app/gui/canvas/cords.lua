local drawItem = require('gui.canvas.draw-item')
local cordMesh = require('gui.canvas.line-mesh')

local signal = nil
local control = nil
local selected = nil

local function setSelected(item)
	selected = {
		cmd = 'line',
		tag = item.tag,
		tags = {},
		params = {width = 2, fill = '0000ff'},
		points = control.getCord(item) or signal.getCord(item)
	}
end

local function clear()
	-- TODO
	signal = cordMesh(0x808093)
	control = cordMesh(0x323232)
end

local function update(item)
	return signal.update(item) or control.update(item)
end

local function delete(item)
	return signal.delete(item) or control.delete(item)
end

local function draw(viewport)
	of.setLineWidth(viewport.scale)
	control.draw()
	of.setLineWidth(2 * viewport.scale)
	signal.draw()

	if (selected) then
		drawItem(viewport, selected)
	end
end

local function add(item)
	if item.cmd == 'select-line' then
		setSelected(item)
	elseif item.cmd == 'unselect-line' then
		selected = nil
	elseif item.params.width == 1 then
		control.add(item)
	else
		signal.add(item)
	end
end

clear()

return {draw = draw, add = add, update = update, delete = delete, clear = clear}
