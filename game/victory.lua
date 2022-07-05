-- Guilherme Cunha Prada 2020

local victory = {}

local utils = require "utils"
local gamestate = require "gamestate"
local Particle = require "Particle"
local settings = require "settings"

function victory.load()
	victory.n_particles = 25000

	victory.width = love.graphics.getWidth()
	victory.height = love.graphics.getHeight()

	victory.text_font = love.graphics.newFont(  settings.font,
												settings.font_size_small)
	victory.title_font = love.graphics.newFont( settings.font,
												settings.font_size_big)
	victory.title_font_back = love.graphics.newFont(settings.font,
													settings.font_size_big + 1)

	victory.title = settings.victory_title
	victory.text = settings.victory_text


	victory.particles = {}
	for i=1,victory.n_particles,1 do
		victory.particles[i] = Particle:new()
	end
end

function victory.draw()
	--particles
	for i=1,victory.n_particles,1 do
		victory.particles[i]:draw()
	end

	--title
	love.graphics.setColor(1, 1, 0)
	love.graphics.printf(   victory.title,
							victory.title_font_back,
							0,
							victory.height/4,
							victory.width,
							"center" )
	love.graphics.setColor(0, 1, 0.5)
	love.graphics.printf(   victory.title,
							victory.title_font,
							0,
							2+ victory.height/4,
							victory.width,
							"center" )

	--text
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(   victory.text,
							victory.text_font,
							0,
							3*victory.height/4,
							victory.width, "center")

	--fps
	love.graphics.setColor(1, 0, 0)
	love.graphics.printf(   love.timer.getFPS(),
							0, victory.height-32,
							victory.width,
							"right")

end

function victory.update(dt)
	for i=1,victory.n_particles,1 do
		victory.particles[i]:update(dt)
	end
end

function victory.keypressed(key, scancode, isrepeat)
	if key == "return" or key == "escape" then
		gamestate.switch("menu")
	end
end

function victory.unload()
	victory.text_font = nil
	victory.title_font = nil
	victory.title_font_back = nil
	victory.title = nil
	victory.text = nil
	victory.particles = nil
end

return victory
