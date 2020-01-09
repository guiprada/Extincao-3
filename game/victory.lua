local utils = require "utils"
local gamestate = require "gamestate"
local particle = require "particle"

local N_PARTICLES = 250

local victory = {}

local width = love.graphics.getWidth()
local height = love.graphics.getHeight()

victory.text_font = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 20)
victory.title_font = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 50)
victory.title_font_back = love.graphics.newFont(
                                        "fonts/PressStart2P-Regular.ttf", 51)

victory.title = [[
Well  Done!!!
]]
victory.text = [[
'enter' go to menu
]]

function victory.load()
    victory.particles = {}
    for i=1,N_PARTICLES,1 do
        victory.particles[i] = particle.new()
    end
end

function victory.draw()
    --particles
    for i=1,N_PARTICLES,1 do
        victory.particles[i]:draw()
    end

    --title
    love.graphics.setColor(1, 1, 0)
    love.graphics.printf(   victory.title,
                            victory.title_font_back, 0, height/4, width, "center" )
    love.graphics.setColor(0, 1, 1)
    love.graphics.printf(   victory.title,
                            victory.title_font, 0, 2+ height/4, width, "center" )

    --text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(   victory.text,
                            victory.text_font, 0, 3*height/4, width, "center")

    --fps
    love.graphics.setColor(1, 0, 0)
    love.graphics.printf(love.timer.getFPS(), 0, height-32, width, "right")


end

function victory.update(dt)
    for i=1,N_PARTICLES,1 do
        victory.particles[i]:update(dt)
    end
end

function victory.keypressed(key, scancode, isrepeat)
    if key == "return" then
        gamestate.switch("menu")
    end
end

return victory
