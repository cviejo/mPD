jit.off()

require('globals')

local text = require('utils/text')
local ofx = require('utils/of')
local keyEq = require('utils/string').keyEq
local Canvas = require('gui/pd/canvas')
local frame = require('gui/pd/frame')
local gui = require('gui')
local parse = require('parse')
local events = require('events')
local pd = require('pd')

local canvas = nil

local floor = math.floor

local function drawCanvas()
	if not canvas then
		return
	elseif canvas.updateNeeded then
		frame.render(canvas.draw) --
	end
	frame.draw(0, 0)
end

local function touchEvent(touch)
	local guiPressed = gui.pressed

	if (guiPressed and touch.type == 2) then
		return
	elseif (guiPressed and touch.type == 1) then
		gui.pressed = false
		return
	elseif (touch.type == 1) then
		gui.pressed = false
	elseif (touch.type == 0) then
		local id, value = gui.touch(touch)
		if (id) then
			if not canvas then
				return
			elseif id == 'edit' then
				pd.queue(canvas.id, 'editmode', value)
			elseif id == 'zoom_in' then
				canvas.message({cmd = 'scale', type = 'scale', value = 1.4})
			elseif id == 'zoom_out' then
				canvas.message({cmd = 'scale', type = 'scale', value = 0.7})
			elseif (id == 'undo' or id == 'copy' or id == 'paste') then
				pd.queue(canvas.id, id)
			elseif id == 'clear' then
				pd.delete(canvas.id)
			else
				log('pressed:', id)
			end
			return
		end
	end
	if canvas then
		canvas.touch(touch)
	end
end

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
	drawCanvas()
	gui.draw()
	of.setColor(0, 0, 0, 100)
	text.draw('fps: ' .. of.getFrameRate(), 50, 50)
	text.draw('mem: ' .. floor(collectgarbage("count")), 50, 75)
end

_G.keyPressed = function(key)
	if (keyEq('e', key)) then
		pd.queue(canvas.id, 'editmode 0')
	elseif (keyEq('l', key)) then
		loadPatch()
	elseif (keyEq('q', key)) then
		mpd.exit()
	elseif (keyEq('t', key)) then
		canvas.toggle()
	elseif (keyEq('s', key)) then
		pd.queue(canvas.id, 'menusave')
	elseif (keyEq('a', key)) then
		pd.queue(canvas.id, 'selectall')
	elseif (keyEq('v', key)) then
		pd.queue(canvas.id, 'dirty 1')
		pd.queue(canvas.id, 'vslider 0') -- bng,  toggle
	end
end

_G.gotMessage = function(msg)
	local parsed = parse(msg)

	if not parsed then
		return
	end

	if parsed.cmd == 'touch' then
		touchEvent(parsed)
	elseif parsed.cmd == 'update-end' and canvas then
		canvas.cleanup()
	elseif parsed.cmd == 'update-start' then
		-- nothing for now
	elseif parsed.cmd == 'new-canvas' then
		canvas = Canvas(parsed.canvasId, {x = 0, y = 0})
	elseif parsed.cmd == 'bind' then
		events.bind(parsed)
	elseif parsed.cmd == 'orientation' then
		log(parsed.cmd, parsed.value)
	elseif canvas then
		canvas.message(parsed)
	end
end

_G.exit = function()
	frame.clear()
	if canvas then
		pd.send(canvas.id .. 'menuclose')
	end
	-- https://github.com/cviejo/mPD/blob/main/src/libs/pd/pure-data/src/g_editor.c#L3399
end

