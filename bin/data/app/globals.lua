---@diagnostic disable: lowercase-global
local logging = require('utils.logging')
local inspect = require('libs.inspect')

_G.target = 'desktop'
_G.dpi = not _G.mpd and 1 or mpd.getDPI()
_G.jit = jit
_G.mpd = mpd
_G.audio = audio
_G.of = of
_G.glm = glm
_G.inspect = inspect
_G.logging = logging
_G.log = logging.verbose
_G.TODO = function(msg)
	print(logging.red('TODO'), msg)
end

if of then
	of.setLogLevel(of.LOG_VERBOSE)
end

-- TODO('events/bind for externals')
-- TODO('big grid')
-- TODO("buttons don't change on press (except toggles), render them an image/vbo")
-- TODO('render text to image/texture?')
