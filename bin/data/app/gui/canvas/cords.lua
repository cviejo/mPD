local S = require('utils.string')
local drawItem = require('gui.canvas.draw-item')
local cordMesh = require('gui.canvas.line-mesh')

local signal = nil
local control = nil
local selected = nil

-- it's a bit odd to handle selected lines separately, but couldn't
-- get mesh:addColor to work as needed
local function setSelected(item)
	selected = {
		cmd = 'line',
		tag = item.tag,
		params = {width = 2, fill = '0000ff', tags = {}},
		points = control.getPoints(item) or signal.getPoints(item)
	}
end

local function clear()
	-- TODO
	selected = nil
	signal = cordMesh(0x808093)
	control = cordMesh(0x323232)
end

local function update(item)
	if (S.head(item.tag) ~= 'l') then
		return false
	elseif item.params and item.params.fill == '0000ff' then
		setSelected(item)
		return true
	elseif item.params and item.params.fill == '000000' then
		selected = nil
		return true
	end

	return signal.update(item) or control.update(item)
end

local function delete(item)
	selected = nil
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
