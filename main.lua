class_commons = true
class      = require 'hump.class'
Timer      = require 'hump.timer'
vector     = require 'hump.vector'
Camera     = require 'hump.camera'
GS         = require 'hump.gamestate'
Collider   = require 'HardonCollider'
Interrupt  = require 'interrupt'
anim8      = require 'anim8'
require 'slam'

do
	local vm = getmetatable(vector())

	function vm.floor(v)
		return vector(math.floor(v.x), math.floor(v.y))
	end

	function vm.round(v)
		return vector(math.floor(v.x+.5), math.floor(v.y+.5))
	end

	function vm.minCoord(v)
		return math.min(v.x, v.y)
	end
end

function GS.transition(to, length, ...)
	length = length or 1

	local fade_color, sw, t = {0,0,0,0}, GS.switch, 0
	local continue = Interrupt{
		__base = GS,
		draw = function(draw)
			draw()
			color = {love.graphics.getColor()}
			love.graphics.setColor(fade_color)
			love.graphics.rectangle('fill', 0,0,
				love.graphics.getWidth(), love.graphics.getHeight())
			love.graphics.setColor(color)
		end,
		update = function(up, dt)
			up(dt)
			t = t + dt
			local s = t/length
			fade_color[4] = math.min(255, math.max(0, s < .5 and 2*s*255 or (2 - 2*s) * 255))
		end,
		-- disable switching states while in transition
		switch = function() end,
		transition = function() end,
	}

	local args = {...}
	Timer.add(length / 2, function() sw(to, unpack(args)) end)
	Timer.add(length, continue)
end

-- minimum frame rate
local up = GS.update
GS.update = function(dt)
	if love.keyboard.isDown('1') then dt = dt / 10 end
	return up(math.min(dt, 1/30))
end

local function Proxy(f)
	return setmetatable({}, {__index = function(t,k)
		local v = f(k)
		t[k] = v
		return v
	end})
end

-- shallow copy of the table
function table.copy(t)
	local r = {}
	for k,v in pairs(t) do r[k] = v end
	return r
end

State = Proxy(function(path) return require('states.' .. path) end)
Image = Proxy(function(path)
	local i = love.graphics.newImage('img/'..path..'.png')
	i:setFilter('nearest', 'nearest')
	return i
end)
Font  = Proxy(function(arg)
	if tonumber(arg) then
		return love.graphics.newFont(arg)
	end
	return Proxy(function(size) return love.graphics.newFont('font/'..arg..'.ttf', size) end)
end)
Sound = {
	static = Proxy(function(path) return love.audio.newSource('snd/'..path..'.ogg', 'static') end),
	stream = Proxy(function(path) return love.audio.newSource('snd/'..path..'.ogg', 'stream') end)
}

function Set(t)
	local s = {}
	for _,k in ipairs(t) do
		s[k] = k
	end
	return pairs(s)
end

function you_lose()
	GS.switch(State['you-lose'])
end

DONE = {false, false, false}
function love.quit()
	local f = love.filesystem.newFile('status.lua')
	f:open('w')
	local t = DONE
	for i = 1,#t do t[i] = tostring(t[i]) end
	f:write("return {" .. table.concat(t, ',') .. "}")
end

function love.load()
	require 'bitmaps'

	if love.filesystem.exists('status.lua') then
		DONE = assert(love.filesystem.load('status.lua')())
	end

	-- make the menu sounds
	local len = 0.1
	local attack, release = 0.1 * len, 0.9 * len

	local switch = love.sound.newSoundData(len * 44100, 44100, 16, 1)
	local select = love.sound.newSoundData(len * 44100, 44100, 16, 1)
	for i = 0,len*44100 do
		local t, sample = i / 44100, 0
		local env = t < attack and (t/attack)^4 or (1 - (t-attack)/(release-attack))^4

		sample = math.sin(t * 1100 * math.pi * 2) * .75
		sample = sample + math.sin(t * 1000 * math.pi * 2) * .5
		sample = sample * env * .15
		switch:setSample(i, sample)

		sample = math.sin(t * 300 * math.pi * 2) * .75
		sample = sample + math.sin(t * 200 * math.pi * 2) * .5
		sample = sample * env * .2
		select:setSample(i, sample)
	end
	Sound.static.select = love.audio.newSource(select, 'static')
	Sound.static.switch = love.audio.newSource(switch, 'static')

	-- tasty after effects
	local W, H = love.graphics.getWidth(), love.graphics.getHeight()
	if love.graphics.isSupported('npot', 'canvas', 'pixeleffect') then
		local canvas = love.graphics.newCanvas()

		local blur = [[extern vec2 o;
		vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
		{
			return Texel(tex, tc - 3.*o) *   1.0 / 64.0
				 + Texel(tex, tc - 2.*o) *   6.0 / 64.0
				 + Texel(tex, tc -    o) *  15.0 / 64.0
				 + Texel(tex, tc       ) * (20.0 / 64.0 + .2)
				 + Texel(tex, tc +    o) *  15.0 / 64.0
				 + Texel(tex, tc + 2.*o) *   6.0 / 64.0
				 + Texel(tex, tc + 3.*o) *   1.0 / 64.0;
		}]]
		local blur_horiz = love.graphics.newPixelEffect(blur)
		local blur_vert  = love.graphics.newPixelEffect(blur)
		blur_horiz:send('o', {1/W,  0})
		blur_vert:send('o',  {0, 1/H})

		local rest_effect = love.graphics.newPixelEffect[[extern number t;
		float rand(vec2 co)
		{
			return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
		}
		vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
		{
			float distort = mod(tc.y+t*.2,1.) - .5;
			distort *= -1000. * distort;
			distort = exp(distort) * .002;
			tc.x += distort;

			// make it hipster
			float grain = rand(vec2(t,t*.2)+tc);
			vec2 d = (tc -vec2(.5));
			float vignette = mix(1. - length(d), 1., .6);
			return mix(Texel(tex,tc), vec4(grain), .1) * vignette * vec4(1.,.99,.9,1.);
		}
		]]

		local effects = {
			[State.invaders] = love.graphics.newPixelEffect[[
			vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
			{
				// green tint
				float white = mix(smoothstep(.2,.32, tc.y), 1., .65);
				color = Texel(tex, tc) * vec4(white, 1., white, 1.);

				// gamma "correction"
				color.rgb = pow(color.rgb, vec3(.8));
				return color;
			}]],
			[State.manpac] = love.graphics.newPixelEffect[[
			vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
			{
				// gamma "correction"
				color = Texel(tex, tc);
				color.rgb = pow(color.rgb, vec3(.7));
				return color;
			}
			]],
			[State.canabalt] = love.graphics.newPixelEffect[[
			vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
			{
				color = Texel(tex, tc);
				color.rgb *= vec3(.9,.9,1.1);
				return color;
			}
			]],
		}

		local t = 0
		local draw = GS.draw
		function GS.draw()
			t = t + love.timer.getDelta()
			canvas:clear()
			love.graphics.setPixelEffect()
			love.graphics.setCanvas(canvas)
			love.graphics.setColor(255,255,255)
			love.graphics.draw(Image.bg_gradient,0,0)
			draw()

			love.graphics.setPixelEffect(blur_vert)
			love.graphics.draw(canvas)

			love.graphics.setPixelEffect(blur_horiz)
			love.graphics.draw(canvas)

			local E = effects[GS.current()]
			if E then
				love.graphics.setPixelEffect(E)
				love.graphics.draw(canvas)
			end

			love.graphics.setCanvas()
			rest_effect:send('t', t)
			love.graphics.setPixelEffect(rest_effect)

			love.graphics.draw(canvas)
			love.graphics.setPixelEffect()
		end
	else -- no pixel effects :(
		local vignette = love.image.newImageData(W,H)
		vignette:mapPixel(function(x,y)
			x,y = x / W - .5, y / H - .5
			local a = 200 * math.max(0, math.min(1, (x*x + y*y)^.7 * .6 + .4))
			return a,a,a,a
		end)
		vignette = love.graphics.newImage(vignette)

		local noise = love.image.newImageData(512,512)
		noise:mapPixel(function() local a = math.random(0,255) * .3 return a,a,a,a end)
		noise = love.graphics.newImage(noise)
		noise:setWrap('repeat', 'repeat')
		local noise_quad = love.graphics.newQuad(0,0, 2*W,2*H, 512,512)

		local draw = GS.draw
		function GS.draw()
			love.graphics.setBlendMode('alpha')
			love.graphics.setColor(255,255,255)
			love.graphics.draw(Image.bg_gradient,0,0)
			draw()
			love.graphics.setBlendMode('additive')
			love.graphics.setColor(255,255,255,40)
			love.graphics.rectangle('fill', 0,0,W,H)

			love.graphics.setColor(255,255,255)
			love.graphics.setBlendMode('subtractive')
			love.graphics.drawq(noise, noise_quad, 0,0,0,1,1, math.random(0,W), math.random(0,H))
			love.graphics.draw(vignette, 0,0)

			if GS.current() == State.invaders then
				love.graphics.setBlendMode('multiplicative')
				love.graphics.setColor(100,255,100)
				love.graphics.rectangle('fill', 0,H*.75,W,H*.25)
				love.graphics.setBlendMode('alpha')
			end
		end
	end

	GS.registerEvents()
	GS.switch(State.splash)
	--GS.switch(State.menu)
	--GS.switch(State.manpac)
	--GS.switch(State.invaders)
	--GS.switch(State.canabalt)
	--GS.switch(State.selection)
end

function love.update(dt)
	Timer.update(dt)
end

function love.keypressed(key)
	local c = GS.current()
	if not (c == State.manpac or c == State.canabalt or c == State.invaders) then
		return
	end
	if key == 'escape' then
		local continue
		continue = Interrupt{
			draw = function(draw)
				local W = love.graphics.getWidth()
				local H = love.graphics.getHeight()
				draw()
				love.graphics.setColor(0,0,0,200)
				love.graphics.rectangle('fill', 0,0,W,H)

				love.graphics.setColor(255,255,255)
				love.graphics.setFont(Font.slkscr[70])
				love.graphics.printf("PAUSE", 0,H/2-50,W, 'center')
				love.graphics.setFont(Font.slkscr[30])
				love.graphics.printf("escape to go to menu", 0,H/2+30,W, 'center')
				love.graphics.printf("space to continue", 0,H/2+70,W, 'center')
			end, update = function() end,
			keypressed = function(_,key)
				if key == 'escape' then
					GS.switch(State.menu)
					continue()
				elseif key == ' ' then
					continue()
				end
			end,
		}
	end
end
