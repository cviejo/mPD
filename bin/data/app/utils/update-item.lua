local pointsToPath = require('utils.points-to-path')

return function(update)
	return function(item)

		if not item then
			return
		end

		if update.points then
			if update.cmd == 'coords' and item.path then
				item.path = pointsToPath(update.points)
			else
				item.points = update.points
			end
		end

		if update.value then
			item.value = update.value
		end

		if update.params then
			if not item.params then
				item.params = update.params
			else
				for key, value in pairs(update.params) do
					item.params[key] = value
				end
			end
		end
	end
end
