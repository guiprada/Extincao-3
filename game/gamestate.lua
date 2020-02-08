-- Guilherme Cunha Prada 2020
--------------------------------------------------------------------------------
-- kitten killing globals
local gamestate = {}

local utils = require "utils"

gamestate.states = {}

--gamestate.null_func = function() end
gamestate.null_func = nil -- poderia ser eliminada

local function assign(dest, callbacks)
    dest.load = callbacks.load or gamestate.null_func
    dest.unload = callbacks.unload or gamestate.null_func
    dest.update = callbacks.update or gamestate.null_func
    dest.draw = callbacks.draw or gamestate.null_func
    dest.keypressed = callbacks.keypressed or gamestate.null_func
    dest.keyreleased = callbacks.keyreleased or gamestate.null_func
    dest.displayrotated = callbacks.displayrotated or gamestate.null_func
    dest.errorhandler = callbacks.errorhandler or gamestate.null_func
    dest.lowmemory = callbacks.lowmemory or gamestate.null_func
    dest.quit = callbacks.quit or gamestate.null_func
    dest.run = callbacks.run or gamestate.null_func
    dest.threaderror = callbacks.threaderror or gamestate.null_func
    dest.directorydropped = callbacks.directorydropped or gamestate.null_func
    dest.filedropped = callbacks.filedropped or gamestate.null_func
    dest.focus = callbacks.focus or gamestate.null_func
    dest.mousefocus = callbacks.mousefocus or gamestate.null_func
    dest.resize = callbacks.resize or gamestate.null_func
    dest.visible = callbacks.visible or gamestate.null_func
    dest.textedited = callbacks.textedited or gamestate.null_func
    dest.textinput = callbacks.textinput or gamestate.null_func
    dest.mousemoved = callbacks.mousemoved or gamestate.null_func
    dest.mousepressed = callbacks.mousepressed or gamestate.null_func
    dest.mousereleased = callbacks.mousereleased or gamestate.null_func
    dest.wheelmoved = callbacks.wheelmoved or gamestate.null_func
    dest.gamepadaxis = callbacks.gamepadaxis or gamestate.null_func
    dest.gamepadpressed = callbacks.gamepadpressed or gamestate.null_func
    dest.gamepadreleased = callbacks.gamepadreleased or gamestate.null_func
    dest.joystickadded = callbacks.joystickadded or gamestate.null_func
    dest.joystickaxis = callbacks.joystickaxis or gamestate.null_func
    dest.joystickhat = callbacks.joystickhat or gamestate.null_func
    dest.joystickpressed = callbacks.joystickpressed or gamestate.null_func
    dest.joystickreleased = callbacks.joystickreleased or gamestate.null_func
    dest.joystickremoved = callbacks.joystickremoved or gamestate.null_func
    dest.touchmoved = callbacks.touchmoved or gamestate.null_func
    dest.touchpressed = callbacks.touchpressed or gamestate.null_func
    dest.touchreleased = callbacks.touchreleased or gamestate.null_func
end

function gamestate.register(name, callbacks)
    local new_entry = {}
    assign(new_entry, callbacks)
    gamestate.states[name] = new_entry
end

function gamestate.switch(name, args)
    if gamestate.current and gamestate.current.unload then
        gamestate.current.unload()
    end

    gamestate.current = gamestate.states[name]
    assign(love, gamestate.current)
    gamestate.current.load(args)
end

return gamestate
