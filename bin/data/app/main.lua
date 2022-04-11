require('globals')
local text = require('utils/text')
local file = require('utils/io')
local s = require('utils/string')
local pd = require('pd')
local frame = require('ui/frame')
local Canvas = require('ui/canvas')
local parse = require('parse')
local events = require('events')

Target = 'desktop'

local canvas = nil

function setup()
	log(jit.version)

	of.background(255)
	of.setVerticalSync(false) -- needed for fps > 60 on desktop
	of.setFrameRate(25)
	of.enableSmoothing()
	of.enableAntiAliasing()

	local success = false

	if Target == 'android' then
		success = audio.init(2, 2, 44100)
	else
		success = audio.init("Pro Microphone", "Pro Speakers", 48000)
	end

	if (success) then
		pd.queue('pd open ignore.patches/play.pd', file.getPath('.')) --
	end
end

local counts = {}

function draw()
	-- pd.flush()

	if not canvas then return end

	if _dev then
		canvas.draw()
	else
		if canvas.updateNeeded then
			frame.render(canvas.draw) --
		end
		frame.draw(0, 0)
	end

	of.setColor(0, 0, 0, 100)
	text.draw('fps: ' .. of.getFrameRate(), 50, 50)
	text.draw('counts: ' .. inspect(counts), 50, 100)
	-- text.draw('Target: ' .. Target, 50, 100)
	-- counts = {}
end

local function touchEvent(touch)
	if canvas then canvas.touch(touch) end
end

function keyPressed(key)
	if (s.keyEq('e', key)) then
		pd.queue(canvas.id, 'editmode 0') --
	elseif (s.keyEq('q', key)) then
		of.exit(0)
	elseif (s.keyEq('s', key)) then
		pd.queue(canvas.id, 'menusave') --
	elseif (s.keyEq('a', key)) then
		pd.queue(canvas.id, 'selectall') --
	elseif (s.keyEq('w', key)) then
		pd.queue(canvas.id, 'editmode 1') --
	elseif (s.keyEq('x', key)) then
		pd.delete(canvas.id) --
	elseif (s.keyEq('u', key)) then
		pd.queue(canvas.id, 'undo') --
	elseif (s.keyEq('t', key)) then
		_dev = not _dev
	end
end

function gotMessage(msg)
	if _dev then print(msg) end
	local parsed = parse(msg)

	if not parsed then return end

	local count = counts[parsed.cmd] or 0
	counts[parsed.cmd] = count + 1

	if parsed.cmd == 'new-canvas' then
		canvas = Canvas(parsed.canvasId)
		pd.queue(canvas.id, 'map 1')
		pd.queue(canvas.id, 'query-editmode')
		pd.queue(canvas.id, 'updatemenu')
		pd.queue(canvas.id, 'editmode', 0)
	elseif parsed.cmd == 'bind' then
		events.bind(parsed)
	elseif canvas then
		canvas.message(parsed)
	end
end

function exit()
	frame.clear()
	if canvas then pd.queue(canvas.id, 'menuclose') end
	-- https://github.com/cviejo/mPD/blob/main/src/libs/pd/pure-data/src/g_editor.c#L3399
end

touchMoved = touchEvent
