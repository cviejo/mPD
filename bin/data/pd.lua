local M = {}

local queue = ''

local joinWords = join(' ')

M.closePatch = noop

M.queue = function(...)
	queue = queue .. ';' .. joinWords({...})
end

M.flush = function()
	if (queue == '') then return end

	mpd.pdsend(queue)
	queue = ''
end

M.send = function(...)
	mpd.pdsend(joinWords({...}))
end

M.delete = function(canvasId)
	M.queue(canvasId, 'key 1 8 0 1 0;', canvasId, 'key 0 8 0 1 0')
end

return M

-- M.openPatch = function(dataFile)
-- 	local path = IO.getPath(dataFile)
-- 	local folder = IO.getDirectory(path):gsub("/?$", "")
-- 	local filename = IO.getFileName(path)
-- 	return mpd.openPatch(filename, folder)
-- end
