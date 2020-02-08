local victory = {}

local utils = require "utils"
local gamestate = require "gamestate"
local particle = require "particle"

function victory.load()
    victory.n_particles = 250

    victory.width = love.graphics.getWidth()
    victory.height = love.graphics.getHeight()

    victory.text_font = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 20)
    victory.title_font = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 50)
    victory.title_font_back = love.graphics.newFont(
                                            "fonts/PressStart2P-Regular.ttf", 51)

    victory.title = "Well  Done!!!"
    victory.text = "'enter' go to menu"


    victory.particles = {}
    for i=1,victory.n_particles,1 do
        victory.particles[i] = particle.new()
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
    love.graphics.setColor(0, 1, 1)
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
    if key == "return" then
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
