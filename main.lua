-- usage example
local terminal = require 'terminal'

function love.load()
    love.graphics.setBackgroundColor(63, 63, 63)
    --Activation Key, Width, Height, and the execution environment
    terminal('f12', 500, 250, _G)
    --If you don't want typing to be painful
    love.keyboard.setKeyRepeat(true)
end

function love.draw()
    terminal:draw()
end

function love.keypressed(key, rep)
    terminal:keypressed(key, rep)
end

function love.textinput(t)
    terminal:textinput(t)
end

function love.mousepressed (x, y, button)
    terminal:mousepressed(x,y, button)
end
