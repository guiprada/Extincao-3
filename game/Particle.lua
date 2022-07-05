-- Guilherme Cunha Prada 2020

local Particle = {}

local width = love.graphics.getWidth()
local height = love.graphics.getHeight()

local PARTICLE_MAX_DURATION = 2
local PARTICLE_MIN_DURATION = 0.6
local PARTICLE_MAX_SIZE = 5

function Particle:new(camera, o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.max_size = love.math.random(1,PARTICLE_MAX_SIZE)

	o.camera = camera or nil -- it can be nil

	o:reset()
	return o
end

function Particle:reset()
	self.timer = love.math.random(PARTICLE_MIN_DURATION, PARTICLE_MAX_DURATION)
	self.max_timer = self.timer

	local drift_x = 0

	if (self.camera) then
		drift_x = -self.camera.x
	end

	self.x = drift_x + love.math.random( 1, width)
	self.y =  love.math.random(1, height)

	self.color_r = love.math.random()
	self.color_g = love.math.random()
	self.color_b = love.math.random()
	self.color_a = 1
end

function Particle:update( dt )
	if self.timer > 0 then
		self.timer = self.timer - dt
	else
		self:reset()
	end
end

function Particle:draw()
	local decay = (self.timer/self.max_timer)
	love.graphics.setColor(	self.color_r,
							self.color_b,
							self.color_b,
							self.color_a * decay)
	love.graphics.circle('fill', self.x, self.y, self.max_size * decay)
end

return Particle
