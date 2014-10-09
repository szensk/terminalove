-- terminal.moon
Moon    = require 'moonscript.base'
Stack   = require 'stack'
Fuzzy   = require 'fuzzy'
Version = {name: 'terminalove', number: '1.0.0'}

terminal = nil
sandbox  = nil
blink    = 1
lasttime = 0
verbose  = false
redraw   = false
canvas   = nil
selection = { start: -1, end: -1, set: false }
clipboard = ""

sortSelection = ->
  if selection.end < selection.start
    selection.end, selection.start = selection.start, selection.end

clearSelection = ->
  selection.start, selection.end = -1, -1

isSelection = ->
  selection.start ~= -1 and selection.end ~= -1

snipSelection = (curtext, insert) ->
  tmp = curtext\sub(1, selection.start) .. insert
  return #tmp, tmp .. curtext\sub(selection.end + 1)

-- Suggestions
words = {} --[k for k,v in pairs _G]
lastinput = nil
lastsuggestions = nil
res = nil
font  = love.graphics.getFont!

sortOnScore = (a,b) ->
  return a.score > b.score

drawSuggestions = =>
  -- we don't care if the word is < 3 characters long
  if #@textin < @suggestlength
    @suggest = false
    return
  -- if the input is the same we just redraw it
  -- otherwise we rescore every suggestion
  if lastinput ~= @textin
    @suggest = true
    res = {}
    for i, v in ipairs words
      score = Fuzzy(v, @textin)
      if score > 0 and v ~= @textin
        res[#res+1] = {score: score, word: v}

    table.sort(res, sortOnScore)
    res = [v.word for i, v in ipairs res]
    lastsuggestions = table.concat(res, "\n")

  -- bail if suggestions were cancelled by ESC
  if not @suggest then return

  -- draw suggestion box
  love.graphics.setColor(@bgcolor)
  love.graphics.rectangle("fill", @x, @height, @width, @fonth * #res)
  if @cursugg > 0 -- draw selection box
    love.graphics.setColor(@inputcolor)
    love.graphics.rectangle("fill", @x, @height + @fonth * (@cursugg - 1), @width, @fonth)
  --print suggestions
  love.graphics.setColor(@fontcolor)
  love.graphics.printf(lastsuggestions, @x + font\getWidth(@ps) + 2, @height, @width, 'left')

  lastinput = @textin

bgr, bgg, bgb, bga = 0, 0, 0, 0
clearCanvas = (canvas, bgcolor) ->
  bgr, bgg, bgb, bga = love.graphics.getBackgroundColor!
  love.graphics.setCanvas(canvas)
  love.graphics.setBackgroundColor(bgcolor)
  love.graphics.clear()

resetCanvas = () ->
  love.graphics.setCanvas!
  love.graphics.setBackgroundColor(bgr, bgg, bgb, bga)

getSandbox = () ->
  if not sandbox
    -- initial sandbox
    sandbox = {
      print: (...) ->
        t = {...}
        out = [tostring(v) for i, v in ipairs t]
        terminal\write(table.concat(out, '  '))
      clear: () ->
        terminal\clear!
      quit: () ->
        love.quit(true)
        love.event.push('quit')
      kill: () ->
        os.exit(-1)
      write: (s) ->
        terminal\write(s)
      version: () ->
        terminal\write "/#{Version.name} #{Version.number}"
      lua: () ->
        terminal\write "#{jit.version} with Love #{string.format('%d.%d.%d', love.getVersion!)}"
      help: ->
        terminal\write "/#{Version.name} #{Version.number} console:"
        terminal\write "` expands to 'print '"
        terminal\write "| expands to 'in pairs '"
        for k,v in pairs sandbox do terminal\write "command: #{k}"
      shortcuts: ->
        terminal\write "Shift+Left/Right: Select\nCtrl+A: Select All\nCtrl+C: Copy\nCtrl+V: Paste"
        terminal\write "Ctrl+X: Cut\nUp/Down: Repeat Command History\nEsc: Close Suggestions"
        terminal\write "Tab: Complete Suggestion\nCtrl+Left/Right: Move to First/Last Command"
        terminal\write "Enter: Enter as MoonScript\nShift+Enter: Enter as Lua"
    }
    setmetatable sandbox, __index: terminal.index
  return sandbox

terminal = {
  x: 0
  y: 0
  ps: '> '
  width:  500
  height: 250
  textin: ""
  lines:  {}
  cursor: 0
  startline: 1
  focus:   false
  visible: false
  fonth: font\getHeight!
  blinktime: 1.0
  history: Stack(100)
  curhist: 0 -- index for up/down command repeat
  suggest: false -- if currently offer suggestions
  suggestlength: 3 -- #chars before suggestions appear
  cursugg: 0 --current suggestion index
  -- colors
  bgcolor:     {23, 23, 23, 192}
  fontcolor:   {243, 243, 243}
  inputcolor:  {53, 53, 53, 192}
  cursorcolor: {243, 243, 243}
  errorcolor:  {237, 24, 38}
  index: _G

  resize: (@width=500, @height=250) =>
    canvas = love.graphics.newCanvas(@width, @height - @fonth)
    clearCanvas(canvas, @bgcolor)
    resetCanvas!

  addWords: (t) =>
    for k,v in pairs t do
      words[#words + 1] = k

  draw: () =>
    if @visible
      line_h = @height - @fonth
      r,g,b,a = love.graphics.getColor()
      if redraw -- redraw the text
        clearCanvas(canvas, @bgcolor)
        y, i = 0, @startline
        while y <= (line_h) and i <= #@lines
          line = @lines[i]
          if type(line) == 'table'
            love.graphics.setColor(line.color)
            line = tostring(line[1])
          else
            love.graphics.setColor(@fontcolor)
          love.graphics.printf(line, @x + 1, @y + y, @width, "left")
          y += @fonth
          i += 1
        resetCanvas!
      love.graphics.setColor(r,g,b,a)
      love.graphics.draw(canvas, @x, @y)
      redraw = false

      --input box
      love.graphics.setColor(@inputcolor)
      love.graphics.rectangle("fill", @x, line_h, @width, @fonth)
      -- selection box
      input = @ps .. @textin
      if selection.end - selection.start > 0
        if selection.end > #@textin
          selection.end = #@textin
        sel = input\sub(1, selection.start+2)
        selx = 1 + font\getWidth(sel)
        selw = font\getWidth(@textin\sub(selection.start+1, selection.end))
        love.graphics.setColor(107, 142, 192)
        love.graphics.rectangle("fill", selx, line_h +1, selw + 2, @fonth - 1)
      -- prompt and current input
      love.graphics.setColor(@fontcolor)
      love.graphics.print(input, 2, line_h)
      -- suggestion box
      drawSuggestions(@)

      -- cursor blink
      br = @cursorcolor[1] * blink
      bg = @cursorcolor[2] * blink
      bb = @cursorcolor[3] * blink
      love.graphics.setColor(br,bg,bb)
      curtime = love.timer.getTime!
      blink -= (curtime - lasttime)/@blinktime
      lasttime = curtime
      if blink < 0 then blink = 1

      -- cursor
      sub = input\sub(1, @cursor+2)
      cursorx = 2 + font\getWidth(sub)
      love.graphics.rectangle("fill", cursorx, line_h + 1, 2, @fonth - 1)

      --restore color
      love.graphics.setColor(r, g, b, a)

  evaluate: (t, nosandbox, lua) =>
    -- laziness
    fn = nil
    ldstring = lua and loadstring or Moon.loadstring
    if type(t) == 'string'
      t = t\gsub('`', 'print ')\gsub('|', ' in pairs ')
      t = t\gsub('%$', 'for k,v in pairs ')
      fn, err = ldstring(t)
      if not fn
        return @error(err\gsub('\n', ' ')\gsub('%[%d+%] >>', ''))
    elseif type(t) == 'function'
      fn = t

    if not nosandbox
      setfenv(fn, getSandbox!)
    status, err = pcall(fn)
    if not status
      @error(err\gsub(".*:%d+:", "error: "))
    else if err
      if type(err) == 'function'
        @evaluate(err, true)
      else
        @write(err)

  clear: () =>
    @lines = {}
    @startline = 1
    @cursor = 0
    @cursugg = 0
    redraw = true

  sandbox: () -> getSandbox!

  close: () -> nil
  flush: () -> nil

  error: (t) =>
    @write {t, color: @errorcolor }

  write: (t) =>
    if type(t) == 'table' and not t.color
      for k,v in pairs t
        @write "  #{tostring(k)}: #{tostring(v)}"
    elseif type(t) == 'table' and t.color
      @lines[#@lines+1] = t
    else
      redraw = true
      rem = nil
      -- make sure it is a string
      t = tostring(t)
      -- break new lines into multiple prints
      start, last = t\find('\n')
      if start then
        rem = t\sub(last + 1)
        t = t\sub(1, start - 1)
      @lines[#@lines+1] = t
      --write the remainder after the new line, if any
      if rem then @write(rem)
    -- move the start line down one if it doesn't fit
    if @startline + 1 <= #@lines - math.floor((@height - @fonth)/@fonth)
      @startline += 1

  inputline: (lua) =>
    @write(@textin)
    @evaluate(@textin, nil, lua)
    @cursor = 0
    if @history\get(1) != @textin
      @history\push(@textin)
    @curhist = 0
    @textin = ""
    @cursugg = 0

  textinput: (t, grapher) =>
    if @focus
      if isSelection!
        @cursor, @textin = snipSelection(@textin, t)
      else
        if @cursor >= #@textin
          @textin ..= t
        else
          @textin = @textin\sub(1, @cursor) .. t .. @textin\sub(@cursor + 1)
        @cursor += 1
      clearSelection!
      if #@textin >= @suggestlength then @suggest = true

  mousepressed: (x, y, button) =>
    if not @focus then return
    if x <= @width and y < @height
      if button == "wu"
        if @startline - 1 >= 1
          @startline -= 1
          redraw = true
      elseif button == "wd"
        if @startline + 1 <= #@lines - math.floor((@height - @fonth)/@fonth)
          @startline += 1
          redraw = true

  keypressed: (key, rep) =>
    if key == 'f12'
      @visible = not @visible
      @focus = not @focus
      blink, lasttime = 1, 0
    if not @focus then return

    ctrlDown = love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')
    shiftdown = love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
    if key == "up" or key == "down"
      if @suggest and #res > 0
        @cursugg += key == "up" and -1 or 1
        if @cursugg < 0 then @cursugg = #res
        if @cursugg > #res then @cursugg = 0
        return
      @curhist += key == "up" and 1 or -1
      if @curhist > @history\size!
        @curhist = @history\size!
      if @curhist < 1
        @curhist = 1
      newtxt = @history\get(@curhist) or @textin
      @textin = newtxt
      @cursor = #@textin
      clearSelection!
    elseif key == "tab" -- complete current suggestion
      if @suggest and res[1]
        if @cursugg == 0 then @cursugg = 1
        @textin = res[@cursugg]
        @cursor = #@textin
        @cursugg = 0
        clearSelection!
    elseif key == "right" or key == "left" --move cursor right
      dir = key == "right" and 1 or -1
      @cursor += dir
      if @cursor > #@textin
        @cursor = #@textin
      if @cursor < 0
        @cursor = 0
      if shiftdown
        if selection.start == -1
          selection.start = @cursor - dir
        if selection.end == -1
          selection.end = @cursor - dir
        if dir > 0
          selection.end = @cursor
        else
          selection.start = @cursor
        sortSelection!
      elseif ctrlDown
        if @history\size! > 0
          @curhist = dir == -1 and @history\size! or 1
          @textin = @history\get(@curhist) or @textin
          @cursor = #@textin
          clearSelection!
      else
        clearSelection!
    elseif key == "escape"
      @suggest = false
      clearSelection!
    elseif key == "backspace" or key == "delete" -- remove character before or after character
      if isSelection! -- replace selection
        @cursor = selection.start
        @textin = @textin\sub(1, selection.start) .. @textin\sub(selection.end + 1)
        clearSelection!
        return

      l = key == "backspace" and 1 or 0
      r = key == "delete" and 2 or 1

      len = @textin\len!
      if @cursor < len
        @textin = @textin\sub(1, @cursor - l) .. @textin\sub(@cursor + r)
      elseif @cursor >= len
        @textin = @textin\sub(1, @cursor - l)
      if key == "backspace" then @cursor -= 1
      if @cursor < 0
        @cursor = 0
    elseif key == "return" or key == "kpenter"
      @suggest = false
      clearSelection!
      @inputline(shiftdown)
    elseif key == "a" and ctrlDown -- select all
      selection.start = 0
      selection.end = #@textin
      @cursor = #@textin
    elseif (key == "c" or key == "x") and ctrlDown -- copy or cut
      if not isSelection! return -- bail if no selection
      clipboard = @textin\sub(selection.start+1, selection.end)
      if key == "x"
        @cursor = selection.start
        @textin = @textin\sub(1, selection.start) .. @textin\sub(selection.end + 1)
        clearSelection!
    elseif key == "v" and ctrlDown -- paste
      if isSelection! -- paste over current selection
        @cursor, @textin = snipSelection(@textin, clipboard)
      else -- no selection? just paste at the current cursor
        @textin = @textin\sub(1, @cursor) .. clipboard .. @textin\sub(@cursor + 1)
        @cursor += #clipboard
      clearSelection!
}

setmetatable(terminal, {
  __call: (width, height, index) =>
    @resize(width, height)
    @index = index
    @addWords(index)
    @addWords(getSandbox!)
    return @
})
