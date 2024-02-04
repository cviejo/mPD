require('globals')

local window = require('gui.main-window')
local ofx = require('utils.of')
local time = require('utils.time')
local parse = require('parse')
local pd = require('pd')

local w, h = nil, nil

_G.setup = function()
	w, h = of.getWidth(), of.getHeight()
	of.setLogLevel(of.LOG_VERBOSE)
	of.background(255)
	of.setVerticalSync(false) -- needed for fps > 60 on desktop
	of.setFrameRate(20)
	of.enableSmoothing()
	of.enableAntiAliasing()
	-- of.setWindowPosition(1200, 300) -- just for desktop
	of.setWindowPosition(-200, -150) -- just for desktop

	setTimeout(function()
		local success = false

		if _G.target == 'android' then
			success = audio.init(2, 2, 44100)
		else
			success = audio.init('Pro Microphone', 'Pro Speakers', 48000)
		end

		if (success) then
			pd.queue('pd open test2.pd', ofx.getPath('ignore.patches'))
		end
	end, 300)
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
	elseif parsed.cmd == 'update-start' or parsed.cmd == 'update-end' then
		-- not implemented
		return
	else
		window.message(parsed)
	end
end

_G.exit = window.clear
