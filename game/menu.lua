-- Guilherme Cunha Prada 2020

menu = {}

local utils = require "utils"
local gamestate = require "gamestate"
local Particle = require "Particle"
local levels = require "levels"
local settings = require "settings"

local width = love.graphics.getWidth()
local height = love.graphics.getHeight()

function menu.load()
    -- initialize
    menu.n_particles = settings.menu_n_particles

    menu.text_font = love.graphics.newFont( settings.font,
                                            settings.font_size_small)
    menu.title_font = love.graphics.newFont(    settings.font,
                                                settings.font_size_big)
    menu.title_font_back = love.graphics.newFont(    settings.font,
                                                settings.font_size_big + 1)

    menu.title = settings.menu_title

    menu.text = settings.menu_text

    -- create particles
    menu.particles = {}
    for i=1,menu.n_particles,1 do
        menu.particles[i] = Particle:new()
    end
end

function menu.draw()
    --particles
    for i=1,menu.n_particles,1 do
        menu.particles[i]:draw()
    end

    --title
    love.graphics.setColor(1, 1, 0)
    love.graphics.printf(   menu.title,
                            menu.title_font_back, 0, height/4, width, "center" )
    love.graphics.setColor(0, 1, 1)
    love.graphics.printf(   menu.title,
                            menu.title_font, 0, 2+ height/4, width, "center" )

    --text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(   menu.text,
                            menu.text_font, 0, 3*height/4, width, "center")

    --fps
    love.graphics.setColor(1, 0, 0)
    love.graphics.printf(love.timer.getFPS(), 0, height-32, width, "right")

end

function menu.update(dt)
    for i=1,menu.n_particles,1 do
        menu.particles[i]:update(dt)
    end
end

function menu.keypressed(key, scancode, isrepeat)
    if key == "a" then
        gamestate.switch("game", levels[1])
    elseif key == "return" then
        gamestate.switch("game", levels[2])
    elseif key == "escape" then
        love.event.quit(0)
    end
end

function menu.unload()
    menu.text_font = nil
    menu.title_font = nil
    menu.title_font_back = nil
    menu.title = nil
    menu.text = nil
	menu.particles = nil
end


return menu
