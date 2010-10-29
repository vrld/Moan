require "moan"

keyboard = {firstload = true}
function keyboard.load()
	if not keyboard.firstload then return end
	keyboard.firstload = false

	local len = .5
	local octave = 4

	local function note(n, o)
		return Moan.newSample(Moan.envelope(
			Moan.osc.saw( Moan.pitch(n, o) ),
			Moan.osc.triangle(8),
			Moan.env.adsr(len/10, 3 * len/10, 5 * len/10, len/10, .5, .4)), len, 44100, 16)
	end

	keyboard.samples = {
		["a"]  = note("c",  octave),
		["w"]  = note("c#", octave),
		["s"]  = note("d",  octave),
		["e"]  = note("d#", octave),
		["d"]  = note("e",  octave),
		["f"]  = note("f",  octave),
		["t"]  = note("f#", octave),
		["g"]  = note("g",  octave),
		["y"]  = note("g#", octave),
		["h"]  = note("a",  octave),
		["u"]  = note("a#", octave),
		["j"]  = note("b",  octave),

		["k"]  = note("c",  octave+1),
		["o"]  = note("c#", octave+1),
		["l"]  = note("d",  octave+1),
		["p"]  = note("d#", octave+1),
		[";"]  = note("e",  octave+1),
		["'"]  = note("f",  octave+1),
		["]"]  = note("f#", octave+1),
		["\\"] = note("g",  octave+1),
	}

	keyboard.keys = {}
	keyboard.drawingorder = {}
	local W, H = 66, 600
	local C1, C2 = {255,255,255,255}, {201,202,228,255}
	local function defkeys(keys, lastx)
		local lastx = lastx or (800 - 12 * W) / 2
		for _,k in pairs(keys) do
			keyboard.keys[k] = {x = lastx, y = 0, w = W, h = H, color = C1, highlight = C2}
			keyboard.drawingorder[#keyboard.drawingorder+1] = k
			lastx = lastx + W
		end
	end
	defkeys{'a','s','d','f','g','h','j','k','l',';','\'','\\'}

	H = 240
	C1, C2  = {0,0,0,255}, {33,33,68,255}
	defkeys({'w','e'},     keyboard.keys["a"].x + W/2)
	defkeys({'t','y','u'}, keyboard.keys["f"].x + W/2)
	defkeys({'o','p'},     keyboard.keys["k"].x + W/2)
	defkeys({']'},         keyboard.keys["'"].x + W/2)

	love.graphics.setBackgroundColor(0,40,0)
	love.graphics.setLine(2)
end

function keyboard.draw()
	local function color_unpack(c)
		return c[1], c[2], c[3], c[4]
	end
	for _,k in ipairs(keyboard.drawingorder) do
		local pad = keyboard.keys[k]
		local c = pad.on and pad.highlight or pad.color
		local c2 = pad.on and pad.color or pad.highlight

		love.graphics.setColor(color_unpack(c))
		love.graphics.rectangle('fill', pad.x, pad.y, pad.w, pad.h)

		love.graphics.setColor(color_unpack(c2))
		love.graphics.rectangle('line', pad.x, pad.y, pad.w, pad.h)
		love.graphics.print(k, pad.x + 10, pad.y + pad.h - 10)
	end
end

-- axel foley!
local melody = {
	{'f', .3}, {'y', .3}, {'f', .2}, {'f', .17}, {'u', .2}, {'f', .2}, {'e', .3},
	{'f', .3}, {'k', .3}, {'f', .2}, {'f', .17}, {'o', .2}, {'k', .2}, {'y', .2},
	{'f', .2}, {'k', .2}, {"'", .2}, {'f', .2}, {'e', .2}, {'e', .2}, {'g', .17}, {'f', 1},
}

--function alternate(notes)
--    local melody = {}
--    for _,k in ipairs(notes) do
--        n1 = k[1]
--        for _,n2 in ipairs(k[2]) do
--            for i = 1,5 do 
--                melody[#melody+1] = {n1, .1}
--                melody[#melody+1] = {n2, .1}
--            end
--        end
--    end
--    return melody
--end
--melody = alternate({
--    {'f', {'h','j','k','l','k','j'}}, 
--    {'d', {'h','j','k','l','k','j'}},
--    {'e', {'h','j','k','l','k','j'}},
--    {'d', {'h','j','k','l','k','j'}},
--    {'f', {'j','k','l',';','l','k'}}, 
--    {'d', {'j','k','l',';','l','k'}}, 
--    {'d', {'j','k','l',';'}}, 
--})

local mp = coroutine.create(function()
	for _,key in ipairs(melody) do
		local s = love.audio.newSource(keyboard.samples[key[1]])
		love.audio.play(s)
		keyboard.keys[key[1]].on = true
		coroutine.yield(key[2])
		keyboard.keys[key[1]].on = false
	end
end)

local t = 0
local hold = 0
function keyboard.update(dt)
	if not hold then return end
	t = t + dt
	if t > hold then
		_, hold = coroutine.resume(mp)
		t = 0
	end
end

function keyboard.keypressed(key)
	if keyboard.samples[key] then
		local s = love.audio.newSource(keyboard.samples[key])
		love.audio.play(s)
	end
	if keyboard.keys[key] then
		keyboard.keys[key].on = true
	end
end

function keyboard.keyreleased(key)
	if keyboard.keys[key] then
		keyboard.keys[key].on = false
	end
end

function keyboard.help()
	return "Press keys according to the labels (homerow and some above on US keyboards)"
end
