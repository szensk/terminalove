terminalove
===========
A simple console for the [LÖVE](https://love2d.org/) (version >= 0.9.0) game engine. It uses [MoonScript](https://moonscript.org), because Lua is, in my experience, too verbose for an in-game console (ala Quake).

![alt text](https://i.imgur.com/4hCMXZ0.png "example usage")

Usage
=====
```lua
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
```

Shortcuts
=========
```
Scroll wheel: scroll up or down
Shift+Left/Right: Select characters
Ctrl+A: Select entire line
Ctrl+C: Copy selection to clipboard
Ctrl+V: Paste clipboard
Ctrl+X: Cut and copy selection to clipboard
Up/Down: Repeat previous command
Esc: Close suggestions
Tab: Complete current suggestion
Ctrl+Left/Right: Move to First/Last Command
Enter: Run command as MoonScript
Shift+Enter: Run command as Lua
```
