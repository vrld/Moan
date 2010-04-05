require "moan"

local samples = {
    sin = {},
    triangle = {},
    saw = {},
    rect = {},
}
local defaults = {
    sin = {
        osc    = Moan.sin,
        octave = 4,
        amp    = .6,
        next   = 'triangle',
        color  = {140, 90, 12},
    },
    triangle = {
        osc    = Moan.triangle,
        octave = 5,
        amp    = .6,
        next   = 'saw',
        color  = {190, 150, 12},
    },
    saw = {
        osc    = Moan.saw,
        octave = 3,
        amp    = .1,
        next   = 'rect',
        color  = {140, 40, 0},
    },
    rect = {
        osc    = Moan.rect,
        octave = 2,
        amp    = .1,
        next   = 'sin',
        color  = {160, 0, 0},
    },
}
local grid = {}
for x = 1,16 do
    grid[x] = {}
end

sequencer = {}
function sequencer.load()
    love.graphics.setBackgroundColor(40,20,0)
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
    return Moan.newSample(Moan.compress(Moan.envelope(
                    Moan.signal(osc, Moan.pitch(pitch, octave), amp), 
                    Moan.signal(Moan.triangle, 8),
                    Moan.decrease(.5),
                    Moan.increase(.02))), .5, 44100, 16)
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
    if key == 'a' then
        bpm = bpm + 10
    elseif key == 's' then
        bpm = bpm - 10
    elseif key == 'c' then
        for x=1,16 do
            for y=1,12 do
                grid[x][y] = nil
            end
        end
    end
end

function sequencer.help()
    return 
[[- Left-click on an empty box places notes
- Left-click on a note changes the oscillator (and the color)
- Right-click deletes a note
- 'c' will clear the board
- 'a' increases BPM by 10
- 's' decreases BPM by 10]]
end
