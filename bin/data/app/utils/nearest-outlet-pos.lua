local iowidth = 7

return function(node, x)
	if (node.outletCount == 1) then
		return iowidth / 2
	end
	local distanceToLeft = x - node.x
	local interval = (node.width - iowidth) / (node.outletCount - 1)
	local index = math.floor((distanceToLeft + interval / 2) / interval)
	return index * interval + iowidth / 2
end

