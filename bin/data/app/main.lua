jit.off()

require('globals')

local text = require('utils.text')
local parse = require('parse')
local window = require('gui.main-window')
local ofx = require('utils.of')
local pd = require('pd')

local loadPatch = function()
	-- pd.queue('pd open main2.pd', ofx.getPath('ignore.patches/filters')) --
	-- pd.queue('pd open sigbinops-help.pd', ofx.getPath('ignore.patches')) --
	-- pd.queue('pd open help.pd', ofx.getPath('ignore.patches')) --
	-- pd.queue('pd open test.pd', ofx.getPath('ignore.patches')) --
	-- pd.queue('pd open hsl.pd', ofx.getPath('ignore.patches')) --
	pd.queue('pd open two-objects.pd', ofx.getPath('ignore.patches')) --
end

_G.setup = function()
	of.setLogLevel(of.LOG_VERBOSE)
	of.background(255)
	of.setVerticalSync(false) -- needed for fps > 60 on desktop
	of.setFrameRate(125)
	of.enableSmoothing()
	of.enableAntiAliasing()
	of.setWindowPosition(0, 0)

	local success = false

	if _G.target == 'android' then
		success = audio.init(2, 2, 44100)
	else
		success = audio.init("Pro Microphone", "Pro Speakers", 48000)
	end

	if (success) then
		loadPatch()
	end
end

_G.draw = function()
	pd.flush()
	window.draw()
	of.setColor(0, 0, 0, 100)
	text.draw('fps: ' .. of.getFrameRate(), 50, 50)
	text.draw('mem: ' .. math.floor(collectgarbage("count")), 50, 75)
end

_G.gotMessage = function(msg)
	local parsed = parse(msg)

	if not parsed then
		return
	elseif parsed.cmd == 'touch' then
		window.touch(parsed)
	end
end

_G.exit = function()
	window.clear()
end

