---@diagnostic disable: lowercase-global
local logging = require('utils/logging')
local inspect = require('libs/inspect')

_G.target = 'desktop'
if _G.mpd then
	_G.dpi = mpd.getDPI()
else
	_G.dpi = 1
end
_G.jit = jit
_G.mpd = mpd
_G.audio = audio
_G.of = of
_G.glm = glm
_G.swig_type = swig_type

_G.inspect = inspect
_G.logging = logging
_G.log = logging.verbose
_G.console = {log = log}
_G.red = logging.colour(31)
_G.green = logging.colour(32)
_G.blue = logging.colour(34)
_G.time = function()
	return os.clock() * 1000
end
_G.TODO = function(msg)
	print(red('TODO'), msg)
end

TODO('events/bind for externals')
TODO('big grid')
TODO("buttons don't change on press (except toggles), render them an image/vbo")
TODO('render text to image/texture?')
