local M = {}

M.getPath = of.FilePath.getAbsolutePath

M.getDirectory = of.FilePath.getEnclosingDirectory

M.getFileName = of.FilePath.getFileName

return M

-- local root = of.FilePath.getAbsolutePath(".")
--
-- function ioTest()
-- 	local dir = of.Directory(root)
-- 	dir:listDir()
-- 	for i = 0, dir:size(), 1 do
-- 		local isDir = dir:getFile(i):isDirectory()
-- 		if isDir then print('id dir: ' .. dir:getPath(i) .. tostring(isDir)) end
-- 	end
-- 	print('size ' .. dir:size())
-- end
