require('globals')
local text = require('utils/text')
local file = require('utils/io')
local s = require('utils/string')
local pd = require('pd')
local frame = require('ui/frame')
local docks = require('ui/docks')
local Canvas = require('ui/canvas')
local parse = require('parse')
local events = require('events')

local canvas = nil

function setup()
	of.setLogLevel(of.LOG_NOTICE)
	of.background(255)
	of.setVerticalSync(false) -- needed for fps > 60 on desktop
	of.setFrameRate(125)
	of.enableSmoothing()
	of.enableAntiAliasing()

	local success = false

	if Target == 'android' then
		success = audio.init(2, 2, 44100)
	else
		success = audio.init("Pro Microphone", "Pro Speakers", 48000)
	end

	if (success) then
		pd.queue('pd open test.pd', file.getPath('ignore.patches')) --
		-- pd.queue('pd open main.pd', file.getPath('ignore.patches/filters')) --
	end
end

local function drawCanvas()
	if not canvas then
		return
	end

	if canvas.updateNeeded then
		frame.render(canvas.draw) --
	elseif canvas then
		canvas.items.cleanup()
	end
	frame.draw(0, 0)
end

function draw()
	pd.flush()

	drawCanvas()
	docks.draw()

	of.setColor(0, 0, 0, 100)
	text.draw('fps: ' .. of.getFrameRate(), 50, 50)
end

local function touchEvent(touch)
	if (touch.type == of.TouchEventArgs_down) then
		local id, value = docks.touch(touch)
		if (id) then
			-- handle non canvas here
			if not canvas then
				return
			end

			if id == 'edit' then
				pd.queue(canvas.id, 'editmode', value)
			elseif id == 'zoom_in' then
				canvas.message({cmd = 'scale', value = 1.4})
			elseif id == 'zoom_out' then
				canvas.message({cmd = 'scale', value = 0.7})
			elseif (id == 'undo' or id == 'copy' or id == 'paste') then
				pd.queue(canvas.id, id)
			elseif id == 'clear' then
				pd.delete(canvas.id)
			end
			return
		end
	end
	if canvas then
		canvas.touch(touch)
	end
end

function keyPressed(key)
	if (s.keyEq('e', key)) then
		pd.queue(canvas.id, 'editmode 0')
	elseif (s.keyEq('q', key)) then
		mpd.exit()
	elseif (s.keyEq('s', key)) then
		pd.queue(canvas.id, 'menusave')
	elseif (s.keyEq('a', key)) then
		pd.queue(canvas.id, 'selectall')
	elseif (s.keyEq('v', key)) then
		pd.queue(canvas.id, 'dirty 1')
		pd.queue(canvas.id, 'vslider 0') -- bng,  toggle
	end
end

function gotMessage(msg)
	local parsed = parse(msg)

	if not parsed then
		return
	end

	if parsed.cmd == 'new-canvas' then
		canvas = Canvas(parsed.canvasId, 0, 0) -- docks.size)
		pd.queue(canvas.id, 'map 1')
		pd.queue(canvas.id, 'query-editmode')
		pd.queue(canvas.id, 'updatemenu')
		pd.queue(canvas.id, 'editmode', 1)
	elseif parsed.cmd == 'bind' then
		events.bind(parsed)
	elseif canvas then
		canvas.message(parsed)
	end
end

function exit()
	frame.clear()
	if canvas then
		pd.send(canvas.id, 'menuclose')
	end
	-- https://github.com/cviejo/mPD/blob/main/src/libs/pd/pure-data/src/g_editor.c#L3399
end

touchMoved = tryCatch(touchEvent, logging.error)
