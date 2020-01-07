-- Guilherme Cunha Prada 2019
--------------------------------------------------------------------------------
-- not quite game, not quite lab
-- kitten killing globals

local gamestate = require "gamestate"

function love.load()
    -- register the states with the gamestate library
    gamestate.register("menu", require "menu")
    gamestate.register("game", require "game")
    -- go to state menu
    gamestate.switch("menu")
    --print("logging")
end
