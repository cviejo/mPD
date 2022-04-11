local M = {}

local queue = ''

local joinWords = join(' ')

M.queue = function(...)
	mpd.pdsend(joinWords({...}))
	-- queue = queue .. ';' .. joinWords({...})
end

M.flush = function()
	if (queue == '') then return end
	mpd.pdsend(queue)
	queue = ''
end

M.send = pipe(unapply(joinWords), mpd.pdsend)

M.delete = function(canvasId)
	M.queue(canvasId, 'key 1 8 0 1 0;', canvasId, 'key 0 8 0 1 0')
end

return M
