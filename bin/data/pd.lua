local M = {}

local queue = ''

local joinWords = join(' ')

M.closePatch = noop

M.queue = function(...)
	queue = queue .. ';' .. joinWords({...})
end

M.flush = function()
	if (queue ~= '') then
		mpd.pdsend(queue)
		queue = ''
	end
end

M.send = function(...)
	mpd.pdsend(joinWords({...}))
end

return M

-- M.openPatch = function(dataFile)
-- 	local path = IO.getPath(dataFile)
-- 	local folder = IO.getDirectory(path):gsub("/?$", "")
-- 	local filename = IO.getFileName(path)
-- 	return mpd.openPatch(filename, folder)
-- end
