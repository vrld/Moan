require "moan"
require "vector"

local Circle = {}
Circle.__index = Circle
Circle.colortable = {
    [Moan.rect]     = {200,  0,  0,200},
    [Moan.saw]      = {200,150,  0,200},
    [Moan.triangle] = {  0,200,  0,200},
    [Moan.sin]      = {  0,  0,200,200},
}
Circle.nextosc = {
    [Moan.rect]     = Moan.sin,
    [Moan.saw]      = Moan.rect,
    [Moan.triangle] = Moan.saw,
    [Moan.sin]      = Moan.triangle,
}
function Circle.new(c)
    local osc = c.osc or Moan.sin
    local t = {
        pos = c.pos or vector.new(400, 300),
        color = Circle.colortable[osc],
        radius = c.radius or 10,
        osc = osc,
        sources = {},
    }
    setmetatable(t, Circle)
    t:newsample()
    return t
end
function Circle:newsample()
    local len = self.radius / 20
    local amp = self.pos.y / 1200 + .0001
    self.sample = Moan.newSample(Moan.compress(Moan.envelope(
            Moan.signal(self.osc, self.pos.x + 20, amp),
            Moan.signal(self.triangle, 8),
            Moan.decrease(len),
            Moan.increase(.05))), len + .05)
end
function Circle:nextsample()
    self.osc = Circle.nextosc[self.osc]
    self.color = Circle.colortable[self.osc]
    self:newsample()
end
function Circle:play()
    local s = love.audio.newSource(self.sample)
    self.sources[s] = s
    love.audio.play(s)
end
function Circle:mousehovers(m)
    local d = (m - self.pos):len2()
    return d < self.radius*self.radius
end
function Circle:stop()
    for k,s in pairs(self.sources) do
        love.audio.stop(s)
        self.sources[k] = nil
    end
end

circlesynth = {
    circles = {},
    waves = {},
    wavecount = 0,
    selected_circle = nil,
}

function circlesynth.load()
    love.graphics.setBackgroundColor(255,255,255)
end

function circlesynth.draw()
    love.graphics.setLine(1)
    for _,c in pairs(circlesynth.circles) do
        love.graphics.setColor(c.color[1],c.color[2],c.color[3],c.color[4])
        if c == circlesynth.selected_circle then
            local r = (c.pos - vector.new(love.mouse.getPosition())):len()
            love.graphics.circle('line', c.pos.x, c.pos.y, r, 16)
            love.graphics.print(tostring(r), c.pos.x + r, c.pos.y + r)
            love.graphics.setColor(c.color[1],c.color[2],c.color[3],c.color[4] / 2)
            love.graphics.circle('fill', c.pos.x, c.pos.y, r, 16)
        else
            love.graphics.circle('fill', c.pos.x, c.pos.y, c.radius, 16) 
        end

        for _,s in pairs(c.sources) do
            if s:isStopped() then
                c.sources[s] = nil
            end
        end
    end

    love.graphics.setLine(2)
    for _,w in pairs(circlesynth.waves) do
        love.graphics.setColor(0,0,0,50 * (1 - w.radius / 800))
        love.graphics.circle('fill', w.pos.x, w.pos.y, w.radius, 16)
    end
end

local function inlist(list, elem)
    for _,i in pairs(list) do
        if i == elem then return true end
    end
    return false
end
function circlesynth.update(dt)
    for k,w in pairs(circlesynth.waves) do
        local r2 = w.radius * w.radius
        for _,c in pairs(circlesynth.circles) do
            local d2 = (c.pos - w.pos):len2()
            if d2 < r2 and not inlist(w.played, c) then
                c:play()
                w.played[c] = c
                if math.random() > .5 and circlesynth.wavecount < 4 then
                    circlesynth.waves[#circlesynth.waves+1] = {pos = c.pos, radius = 1, played = {c}}
                    circlesynth.wavecount = circlesynth.wavecount + 1
                end
            end
        end
        w.radius = w.radius * 1.01 + 40 * dt
        if w.radius > 800 then 
            circlesynth.waves[k] = nil
            circlesynth.wavecount = circlesynth.wavecount - 1
        end
    end
end

function circlesynth.mousereleased(x,y,btn)
    local mousep = vector.new(x,y)
    if btn == 'l' then
        if circlesynth.selected_circle then
            circlesynth.selected_circle.radius = (circlesynth.selected_circle.pos - vector.new(love.mouse.getPosition())):len()
            circlesynth.selected_circle:newsample()
            circlesynth.selected_circle = nil
            return
        end
        for _,c in pairs(circlesynth.circles) do
            if c:mousehovers(mousep) then
                c:nextsample()
                return
            end
        end
        circlesynth.circles[#circlesynth.circles+1] = Circle.new{pos=vector.new(x,y)}
    elseif btn == 'r' then
        if circlesynth.selected_circle then
            circlesynth.selected_circle = nil
            return
        end
        for _,c in pairs(circlesynth.circles) do
            if c:mousehovers(mousep) then
                circlesynth.selected_circle = c
                return
            end
        end
    elseif btn == 'm' then
        for k,c in pairs(circlesynth.circles) do
            if c:mousehovers(mousep) then
                circlesynth.circles[k]:stop()
                circlesynth.circles[k] = nil
                return
            end
        end
        circlesynth.waves[#circlesynth.waves+1] = {pos = mousep, radius = 1, played = {}}
        circlesynth.wavecount = circlesynth.wavecount + 1
    end
end

function circlesynth.keyreleased(key)
    if key == 'c' then
        for k,c in pairs(circlesynth.circles) do
            circlesynth.circles[k] = nil
        end
        for k,w in pairs(circlesynth.waves) do
            circlesynth.waves[k] = nil
        end
    elseif key == 'w' then
        circlesynth.waves[#circlesynth.waves+1] = {pos = vector.new(400,300), radius = 1, played = {}}
        circlesynth.wavecount = circlesynth.wavecount + 1   
    end
end
