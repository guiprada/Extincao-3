-- Guilherme Cunha Prada 2020
--------------------------------------------------------------------------------

local gamestate = require "gamestate"
local settings = require "settings"

function love.load()
    love.window.setMode(settings.screen_width or 0,
                        settings.screen_height or 0,
                        {   fullscreen=settings.fullscreen,
                            resizable=false, vsync=true })
    -- register the states with the gamestate library
    gamestate.register("menu", require "menu")
    gamestate.register("game", require "game")
    gamestate.register("victory", require "victory")
    -- go to state menu
    gamestate.switch("menu")
    --print("logging")
end
