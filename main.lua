require "keyboard"
require "circlesynth"
require "sequencer"

Button = {}
Button.__index = Button
function Button.new(text, x,y, w,h, onclick)
    local b = {
        text = text,
        x=x, y=y,
        w=w, h=h,
        onclick = onclick,
    }

    setmetatable(b, Button)
    return b
end
function Button:draw()
    if not self.textpos then
        local font = love.graphics.getFont()
        self.textpos = {x = self.x + (self.w - font:getWidth(self.text))/2,
                        y = self.y + font:getHeight(self.text) - 3}
    end
    love.graphics.setColor(180,180,180,180)
    love.graphics.rectangle('fill', self.x,self.y,self.w,self.h)
    love.graphics.setLine(2)
    love.graphics.setColor(0,0,0,180)
    love.graphics.rectangle('line', self.x,self.y,self.w,self.h)
    love.graphics.print(self.text, self.textpos.x, self.textpos.y)
end
function Button:over_button(x,y)
    return x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h
end

local function hsv_to_rgb(h,s,v)
    local H = h/60 
    local Hi = math.floor(H)
    local f = H - Hi
    local p,q,t = v * (1 - s), v * (1 - s*f), v * (1 - s*(1-f))

    if     Hi == 5 then
        return v * 255, p * 255, q * 255
    elseif Hi == 4 then
        return t * 255, p * 255, v * 255
    elseif Hi == 3 then
        return p * 255, q * 255, v * 255
    elseif Hi == 2 then
        return p * 255, v * 255, t * 255
    elseif Hi == 1 then
        return q * 255, v * 255, p * 255
    else -- 0 or 6
        return v * 255, t * 255, p * 255
    end
end
local h = 0
local demo = {
    draw = function() 
        love.graphics.setColor(40,40,40,40)
        for x = 0,800,60 do
            for y = 0,600,20 do
                love.graphics.print("Moan", x, y)
            end
        end
    end, 
    update = function(dt) 
        h = (h + dt * 50) % 360
        love.graphics.setBackgroundColor(hsv_to_rgb(h,.1,.7))
    end
}
local buttons = {
    Button.new("keyboard",   10, 20, 120, 20, function() demo = keyboard end),
    Button.new("circles",   140, 20, 120, 20, function() demo = circlesynth end),
    Button.new("sequencer", 270, 20, 120, 20, function() demo = sequencer end),
}
function love.load()
    love.graphics.setFont(18)
end

function love.draw()
    demo.draw()
    for _,b in ipairs(buttons) do
        b:draw()
    end
end

function love.update(dt)
    demo.update(dt)
end

function love.keypressed(key)
    if demo.keypressed then
        demo.keypressed(key)
    end
end

function love.keyreleased(key)
    if demo.keyreleased then
        demo.keyreleased(key)
    end
end

function love.mousereleased(x,y,btn)
    if btn == 'l' then
        for _,b in ipairs(buttons) do
            if b:over_button(x,y) then
                b:onclick()
                demo.load()
                return
            end
        end
    end

    if demo.mousereleased then
        demo.mousereleased(x,y,btn)
    end
end
