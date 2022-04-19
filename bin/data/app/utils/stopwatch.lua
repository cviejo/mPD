local M = {}

local mark = function()
	return os.clock() * 1000
end

M.start = function(label, threshold)
	local start = mark()

	return function()
		local diff = mark() - start

		if threshold then
			if (diff > threshold) then
				print('')
				log(red(label), diff)
				return false
			else
				return true
			end
		end

		return diff
	end
end

return M

-- Usage:
-- local finish = stopwatch.start('message', 0.25)
-- canvas.message(parsed)
-- if (not finish()) then log(msg.message, '\n') end
-- or just finish()
