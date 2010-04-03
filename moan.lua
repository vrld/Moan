Moan = {lastnoise = 0}

function Moan.rect(x) 
    local x = x % 1
    if x > .5 then return 1 else return -1 end
end

function Moan.triangle(x)
    local x = x % 1
    if x < .5 then return 4*x-1 else return 3-4*x end
end

function Moan.saw(x)
    local x = x % 1
    return 2*x - 1
end

function Moan.sin(x)
    return math.sin(2*math.pi*x)
end

function Moan.noise()
    return math.random() * 2 - 1
end

function Moan.pinkNoise()
    Moan.lastnoise = Moan.noise() + Moan.lastnoise
    return Moan.lastnoise
end

function Moan.signal(osc, f, a)
    local osc = osc or Moan.sin
    local f = f or 440
    local a = a or 1
    return function(t) return osc(f*t)*a end
end

function Moan.newSample(gen, len, samplerate, bits, channels)
    local len = len or 1
    local samplerate = samplerate or 44100
    local channels = channels or 1
    local bits = bits or 16
    local samples = math.floor(len * samplerate)
    local data = love.sound.newSoundData(samples, samplerate, bits, channels)
    for i = 1,samples do
        data:setSample(i, gen( i / samplerate))
    end
    return data
end

function Moan.decrease(l)
    return function(t) return math.max(1-t/l,0) end
end

function Moan.increase(l)
    return function(t) return math.min(t/l,1) end
end

function Moan.map(f, g)
    return function(t) return g(f(t)) end
end

function Moan.compress(f)
    return Moan.map(f, math.tanh)
end

function Moan.normalize(f)
    local lastmax = 1
    return function(t)
        local v = f(t)
        if v > lastmax then lastmax = v end
        return v / lastmax
    end
end

function Moan.envelope(f, ...)
    local envelopes = {...}
    return function(t) 
        local r = f(t)
        for _,g in ipairs(envelopes) do
            r = r * g(t)
        end
        return r
    end
end

Moan.fractions = {
    ["c"]  = math.pow(math.pow(2,1/12), -9),
    ["c#"] = math.pow(math.pow(2,1/12), -8),
    ["d"]  = math.pow(math.pow(2,1/12), -7),
    ["d#"] = math.pow(math.pow(2,1/12), -6),
    ["e"]  = math.pow(math.pow(2,1/12), -5),
    ["f"]  = math.pow(math.pow(2,1/12), -4),
    ["f#"] = math.pow(math.pow(2,1/12), -3),
    ["g"]  = math.pow(math.pow(2,1/12), -2),
    ["g#"] = 1 / math.pow(2,1/12),
    ["a"]  = 1,
    ["a#"] = math.pow(2,1/12),
    ["b"]  = math.pow(2,1/12) * math.pow(2,1/12),
}
Moan.fractions["db"] = Moan.fractions["c#"]
Moan.fractions["eb"] = Moan.fractions["c#"]
Moan.fractions["gb"] = Moan.fractions["f#"]
Moan.fractions["ab"] = Moan.fractions["g#"]
Moan.fractions["bb"] = Moan.fractions["a#"]

function Moan.octave(n)
    return 440 * math.pow(2, n - 4)
end

function Moan.pitch(p, octave)
    local octave = octave or 4
    octave = Moan.octave(octave)
    return Moan.fractions[p] * octave
end
