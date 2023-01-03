local S = require('utils.string')
local drawItem = require('gui.canvas.draw-item')
local cordMesh = require('gui.canvas.line-mesh')

return function()
	local M = {}

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

	M.clear = function()
		selected = nil
		signal = cordMesh(0x808093)
		control = cordMesh(0x323232)
	end

	M.update = function(item)
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

	M.delete = function(item)
		selected = nil
		return signal.delete(item) or control.delete(item)
	end

	M.draw = function(viewport)
		of.setLineWidth(viewport.scale)
		control.draw()
		of.setLineWidth(2 * viewport.scale)
		signal.draw()

		if (selected) then
			drawItem(viewport, selected)
		end
	end

	M.add = function(item)
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

	M.clear()

	return M
end
