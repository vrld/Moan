require "moan"

local samples = {
	sin = {},
	triangle = {},
	saw = {},
	rect = {},
}
local defaults = {
	sin = {
		osc    = Moan.osc.sin,
		octave = 4,
		amp    = .6,
		next   = 'triangle',
		color  = {40, 80, 190},
	},
	triangle = {
		osc    = Moan.osc.triangle,
		octave = 5,
		amp    = .6,
		next   = 'saw',
		color  = {40, 190, 80},
	},
	saw = {
		osc    = Moan.osc.saw,
		octave = 3,
		amp    = .3,
		next   = 'rect',
		color  = {190, 190, 50},
	},
	rect = {
		osc    = Moan.osc.rect,
		octave = 2,
		amp    = .3,
		next   = 'sin',
		color  = {190, 40, 40},
	},
}
local grid = {}
for x = 1,16 do
	grid[x] = {}
end

sequencer = {}
function sequencer.load()
	love.graphics.setBackgroundColor(40,20,0)
	love.filesystem.setIdentity("moan")
end

local playcol = 1
local t = 0
local bpm = 60

function sequencer.draw()
	love.graphics.setLine(3)
	love.graphics.setColor(70,40,0,255)
	-- draw grid
	for x = 1,16 do
		love.graphics.line(x*50,0,x*50,600)
	end
	for y = 1,12 do
		love.graphics.line(0,y*50,800,y*50)
	end

	-- draw notes
	for x = 1,16 do
		local col = grid[x]
		for y = 1,12 do
			local cell = col[y]
			if cell then
				local c = defaults[cell.osc].color
				love.graphics.setColor(c[1],c[2],c[3],255)
				love.graphics.rectangle('fill', (x-1)*50+2, (y-1)*50+2, 50-4, 50-4)
			end
		end
	end

	-- playing column
	love.graphics.setColor(160,110,12,180)
	love.graphics.rectangle('fill', (playcol-1)*50+2, 0, 50-4, 600)

	love.graphics.setColor(180,130,42,255)
	love.graphics.print(string.format("BPM: %d", bpm), 700, 20)
end

function sequencer.update(dt)
	t = t + dt
	if t > 15/bpm then
		t = 0
		playcol = (playcol + 1) % 17
		if playcol == 0 then playcol = 1 end
		local col = grid[playcol]
		for y = 1,12 do
			if col[y] then
				love.audio.play(col[y].source)
			end
		end
	end
end

local function createSample(osc, pitch, amp, octave)
	local len = .5
	return Moan.newSample(Moan.compress(Moan.envelope(
		osc(Moan.pitch(pitch, octave), amp),
		Moan.osc.triangle(8),
		Moan.env.adsr(len/10, 3*len/10, 5*len/10, len/10, amp*1.2, amp))), len)
end

local pitchtable = {'b','a#','a','g#','g','f#','f','e','d#','d','c#','c'}
function sequencer.mousereleased(x,y,btn)
	local cx, cy = math.floor(x/50) + 1, math.floor(y/50) + 1
	local cell = grid[cx][cy]
	if btn == 'l' then
		if cell then -- change oscillator
			local osc = defaults[ grid[cx][cy].osc ].next
			local pitch = pitchtable[cy]
			if not samples[osc][pitch] then
				samples[osc][pitch] = createSample(defaults[osc].osc,
				pitch, defaults[osc].amp, defaults[osc].octave)
			end
			grid[cx][cy] = {
				osc = osc,
				source = love.audio.newSource(samples[osc][pitch])
			}
		else -- new tone
			local pitch = pitchtable[cy]
			local osc = 'sin'
			if not samples[osc][pitch] then
				samples[osc][pitch] = createSample(defaults[osc].osc,
							pitch, defaults[osc].amp, defaults[osc].octave)
			end
			grid[cx][cy] = {
				osc = osc,
				source = love.audio.newSource(samples[osc][pitch])
			}
		end
	elseif btn == 'r' then
		grid[cx][cy] = nil
	end
end

function sequencer.keyreleased(key)
	if key == 'q' then
		bpm = bpm + 10
	elseif key == 'a' then
		bpm = math.max(bpm - 10, 0)
	elseif key == 'c' then
		for x=1,16 do
			for y=1,12 do
				grid[x][y] = nil
			end
		end
	elseif key == 's' then
		sequencer.save()
	elseif key == 'l' then
		sequencer.load_file()
	end
end

function sequencer.serialize()
	local sin, tri, saw, rect = {}, {}, {}, {}
	for x = 1,16 do
		local s,t,a,r = 0,0,0,0
		for y = 1,12 do
			local cell = grid[x][y]
			local inc = math.pow(2, (y-1))
			if not cell then -- nothing
			elseif cell.osc == 'sin' then
				s = s + inc
			elseif cell.osc == 'triangle' then
				t = t + inc
			elseif cell.osc == 'saw' then
				a = a + inc
			elseif cell.osc == 'rect' then
				r = r + inc
			end
		end
		sin[#sin+1] = s
		tri[#tri+1] = t
		saw[#saw+1] = a
		rect[#rect+1] = r
	end
	return table.concat({table.concat(sin,","),table.concat(tri,","),table.concat(saw,","),table.concat(rect,",")}, ";")
end

function sequencer.deserialize(str)
	local tracks = {}
	for s in str:gmatch("[^;]+") do
		local t = {}
		for n in s:gmatch("%d+") do
			t[#t+1] = tonumber(n)
		end
		tracks[#tracks+1] = t
	end

	for x = 1,16 do for y = 1,12 do
		grid[x][y] = nil
	end end

	local numberToOsc = {'sin', 'triangle', 'saw', 'rect'}
	for x = 1,16 do
		for i,t in ipairs(tracks) do
			local n = t[x] or 0
			for y = 12,1,-1 do
				if n > math.pow(2,(y-2)) then
					n = n % math.pow(2,(y-2))
					local pitch = pitchtable[y]
					local osc = numberToOsc[i]
					if not samples[osc][pitch] then
						samples[osc][pitch] = createSample(defaults[osc].osc,
									pitch, defaults[osc].amp, defaults[osc].octave)
					end
					grid[x][y] = {
						osc = osc,
						source = love.audio.newSource(samples[osc][pitch])
					}
				end
			end
		end
	end
end

function sequencer.save()
	local ser = sequencer.serialize()
	print(ser)
	local f = love.filesystem.newFile("moan-sequencer.txt")
	f:open("w")
	f:write(ser)
	f:close()
end

function sequencer.load_file()
	if love.filesystem.isFile("moan-sequencer.txt") then
		for s in love.filesystem.lines("moan-sequencer.txt") do
			sequencer.deserialize(s)
		end
	end
end

function sequencer.help()
	return
	[[- Left-click on an empty box places notes
- Left-click on a note changes the oscillator (and the color)
- Right-click deletes a note
- 'c' will clear the board
- 's' will save the board
- 'l' will load a saved board
- 'q' increases BPM by 10
- 'a' decreases BPM by 10]]
end
