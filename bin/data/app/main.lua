require('globals')

local window = require('gui.main-window')
local ofx = require('utils.of')
local time = require('utils.time')
local parse = require('parse')
local pd = require('pd')
local classNames = require('pd-class-names')

local initAudio = function()
	local success = false

	if _G.target == 'android' then
		success = audio.init(2, 2, 44100)
	else
		success = audio.init('Pro Microphone', 'Pro Speakers', 48000)
	end

	if not success then
		print('audio init failed')
		return
	end

	setTimeout(function()
		pd.queue('pd open test2.pd', ofx.getPath('ignore.patches'))
	end, 300)
end

_G.setup = function()
	-- desktop only

	of.setVerticalSync(false) -- needed for fps > 60
	of.setWindowPosition(-200, -150)
	-- setTimeout(function()
	-- 	of.setWindowShape(900, 400);
	-- 	of.sendMessage('orientation 1')
	-- end, 3000)

	of.setLogLevel(of.LOG_VERBOSE)
	of.background(255)
	of.setFrameRate(20)
	of.enableSmoothing()
	of.enableAntiAliasing()

	setTimeout(initAudio, 200)
end

_G.draw = function()
	time.update()
	pd.flush()
	window.draw()
	-- require('utils.hud').draw()
end

_G.gotMessage = function(msg)
	local parsed = parse(msg)

	if not parsed then
		return
	end

	if (parsed.cmd == 'pd-class') then
		classNames.add(parsed.name)
	else
		window.message(parsed)
	end
end

_G.exit = window.clear
