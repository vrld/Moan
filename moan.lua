Moan = {}
Moan.osc = {}
Moan.env = {}

function Moan.osc.rect(f, a)
	local a = a or 1
	return function(t) return ((f*t)%1) > .5 and a or -a end
end

function Moan.osc.triangle(f, a)
	local a = a or 1
	return function(t)
		local t = ((f*t) % 1)
		return t < .5 and a * (4*t - 1) or a * (3 - 4*t)
	end
end

function Moan.osc.saw(f, a)
	local a = a or 1
	return function(t)
		local t = ((f*t) % 1)
		return a * (2*t - 1)
	end
end

function Moan.osc.sin(f, a)
	local a = a or 1
	return function(t)
		local t = ((f*t) % 1)
		return a * math.sin(2*math.pi*t)
	end
end

function Moan.osc.whitenoise()
	local a = a or 1
	return function() return a * (math.random() * 2 - 1) end
end
Moan.osc.wn = Moan.osc.whitenoise

function Moan.osc.pinknoise()
	local a = a or 1
	local last = 0
	return function()
		last = math.max(-1, math.min(1, last + math.random() * 2 - 1))
		return a * last
	end
end
Moan.osc.pn = Moan.osc.pinknoise

function Moan.env.rise(len, delay)
	local delay = delay or 0
	return function(t) return math.max(0, math.min(1, (t-delay)/len)) end
end

function Moan.env.fall(l, d)
	local delay = delay or 0
	return function(t) return math.min(1, math.max(0, 1-(t-delay)/len)) end
end

function Moan.env.risefall(attack,sustain,release)
	return function(t)
		if t > attack + sustain then
			return math.max(0, 1 - (t - sustain - attack) / release)
		end
		return math.min(1, t / rise)
	end
end

function Moan.env.adsr(attack,decay,sustain,release, peak,level)
	local peak = peak or 1
	local level = level or peak
	if level > peak then level = peak end

	return function(t)
		if t > attack + decay + sustain then -- release
			return math.max(0, level * (1 - (t - sustain - decay - attack) / release))
		elseif t > attack + decay then -- sustain
			return level
		elseif t > attack then -- decay
			return level + (peak - level) * (1 - (t - attack) / decay)
		end
		-- attack
		return peak * t / attack
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

function Moan.map(f, g)
	return function(t) return g(f(t)) end
end

function Moan.compress(f)
	return Moan.map(f, math.tanh)
end

function Moan.newSample(gen, len, samplerate, bits)
	local len = len or 1
	local samplerate = samplerate or 44100
	local bits = bits or 16
	local samples = math.floor(len * samplerate)
	local data = love.sound.newSoundData(samples, samplerate, bits, 1)
	for i = 0,samples do
		data:setSample(i, gen(i / samplerate))
	end
	return data
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
	["a"]  = 1, -- standard pitch, see Moan.base
	["a#"] = math.pow(2,1/12),
	["b"]  = math.pow(2,1/12) * math.pow(2,1/12),
}
Moan.fractions["db"] = Moan.fractions["c#"]
Moan.fractions["eb"] = Moan.fractions["c#"]
Moan.fractions["gb"] = Moan.fractions["f#"]
Moan.fractions["ab"] = Moan.fractions["g#"]
Moan.fractions["bb"] = Moan.fractions["a#"]

function Moan.base(n)
	return 440 * math.pow(2, n - 4)
end

function Moan.pitch(p, octave)
	local octave = octave or 4
	octave = Moan.base(octave)
	return Moan.fractions[p] * octave
end
