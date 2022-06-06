local pd = require('pd')
local hasTag = require('utils/has-tag')

local M = {}

-- todo, change this to a dictionary of arrays for different events
local listeners = {}

local pointInside = function(x, p1, p2)
	return p1.x < x.x and p1.y < x.y and p2.x > x.x and p2.y > x.y
end

local hitTest = function(point)
	return function(item)
		local points = item.points
		return points and #points == 2 and pointInside(point, points[1], points[2])
	end
end

M.event = function(e, items)
	if (e.type == of.TouchEventArgs_up) then

		local found = find(function(listener)
			local testMatch = both(hasTag(listener.tag), hitTest(e))

			return find(testMatch, items)
		end, listeners)

		if found then
			pd.queue(found.callback)
		end
	end
end

M.bind = function(x)
	table.insert(listeners, x)
end

M.unbind = function(target)
	-- todo, on delete
end

return M;
