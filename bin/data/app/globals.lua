---@diagnostic disable: lowercase-global
local logging = require('utils.logging')
local F = require('utils.functional')
local inspect = require('libs.inspect')

_G.Target = 'desktop'
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

-- adding explictly to the global table works better with the linter
_G.curry = F.curry
_G.each = F.forEach
_G.forEach = F.forEach
_G.map = F.map
_G.pipe = F.pipe
_G.noop = F.noop

_G.join = F.join
_G.unapply = F.unapply
_G.tryCatch = F.tryCatch
_G.clamp = F.clamp

TODO('remove lamda?')
TODO('selected lines mesh')
TODO('big grid')
TODO('events/bind for externals')
TODO("buttons don't change on press (except toggles), render them an image/vbo")
TODO('the whole lastTouch,dragging = loc thing and scaleBegin when edimode = 1')
TODO('render text to image/texture?')
TODO('overwrite object outline when selected (blue)')
