local Moon = require('moonscript.base')
local Stack = require('stack')
local Fuzzy = require('fuzzy')
local Version = {
  name = 'terminalove',
  number = '1.0.0'
}
local terminal = nil
local sandbox = nil
local blink = 1
local lasttime = 0
local verbose = false
local redraw = false
local canvas = nil
local selection = {
  start = -1,
  ["end"] = -1,
  set = false
}
local clipboard = ""
local sortSelection
sortSelection = function()
  if selection["end"] < selection.start then
    selection["end"], selection.start = selection.start, selection["end"]
  end
end
local clearSelection
clearSelection = function()
  selection.start, selection["end"] = -1, -1
end
local isSelection
isSelection = function()
  return selection.start ~= -1 and selection["end"] ~= -1
end
local snipSelection
snipSelection = function(curtext, insert)
  local tmp = curtext:sub(1, selection.start) .. insert
  return #tmp, tmp .. curtext:sub(selection["end"] + 1)
end
local words = { }
local lastinput = nil
local lastsuggestions = nil
local res = nil
local font = love.graphics.getFont()
local sortOnScore
sortOnScore = function(a, b)
  return a.score > b.score
end
local drawSuggestions
drawSuggestions = function(self)
  if #self.textin < self.suggestlength then
    self.suggest = false
    return 
  end
  if lastinput ~= self.textin then
    self.suggest = true
    res = { }
    for i, v in ipairs(words) do
      local score = Fuzzy(v, self.textin)
      if score > 0 and v ~= self.textin then
        res[#res + 1] = {
          score = score,
          word = v
        }
      end
    end
    table.sort(res, sortOnScore)
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i, v in ipairs(res) do
        _accum_0[_len_0] = v.word
        _len_0 = _len_0 + 1
      end
      res = _accum_0
    end
    lastsuggestions = table.concat(res, "\n")
  end
  if not self.suggest then
    return 
  end
  love.graphics.setColor(self.bgcolor)
  love.graphics.rectangle("fill", self.x, self.height, self.width, self.fonth * #res)
  if self.cursugg > 0 then
    love.graphics.setColor(self.inputcolor)
    love.graphics.rectangle("fill", self.x, self.height + self.fonth * (self.cursugg - 1), self.width, self.fonth)
  end
  love.graphics.setColor(self.fontcolor)
  love.graphics.printf(lastsuggestions, self.x + font:getWidth(self.ps) + 2, self.height, self.width, 'left')
  lastinput = self.textin
end
local bgr, bgg, bgb, bga = 0, 0, 0, 0
local clearCanvas
clearCanvas = function(canvas, bgcolor)
  bgr, bgg, bgb, bga = love.graphics.getBackgroundColor()
  love.graphics.setCanvas(canvas)
  love.graphics.setBackgroundColor(bgcolor)
  return love.graphics.clear()
end
local resetCanvas
resetCanvas = function()
  love.graphics.setCanvas()
  return love.graphics.setBackgroundColor(bgr, bgg, bgb, bga)
end
local getSandbox
getSandbox = function()
  if not sandbox then
    sandbox = {
      print = function(...)
        local t = {
          ...
        }
        local out
        do
          local _accum_0 = { }
          local _len_0 = 1
          for i, v in ipairs(t) do
            _accum_0[_len_0] = tostring(v)
            _len_0 = _len_0 + 1
          end
          out = _accum_0
        end
        return terminal:write(table.concat(out, '  '))
      end,
      clear = function()
        return terminal:clear()
      end,
      quit = function()
        love.quit(true)
        return love.event.push('quit')
      end,
      kill = function()
        return os.exit(-1)
      end,
      write = function(s)
        return terminal:write(s)
      end,
      version = function()
        return terminal:write("/" .. tostring(Version.name) .. " " .. tostring(Version.number))
      end,
      lua = function()
        return terminal:write(tostring(jit.version) .. " with Love " .. tostring(string.format('%d.%d.%d', love.getVersion())))
      end,
      help = function()
        terminal:write("/" .. tostring(Version.name) .. " " .. tostring(Version.number) .. " console:")
        terminal:write("` expands to 'print '")
        terminal:write("| expands to 'in pairs '")
        for k, v in pairs(sandbox) do
          terminal:write("command: " .. tostring(k))
        end
      end,
      shortcuts = function()
        terminal:write("Shift+Left/Right: Select\nCtrl+A: Select All\nCtrl+C: Copy\nCtrl+V: Paste")
        terminal:write("Ctrl+X: Cut\nUp/Down: Repeat Command History\nEsc: Close Suggestions")
        terminal:write("Tab: Complete Suggestion\nCtrl+Left/Right: Move to First/Last Command")
        return terminal:write("Enter: Enter as MoonScript\nShift+Enter: Enter as Lua")
      end
    }
    setmetatable(sandbox, {
      __index = terminal.index
    })
  end
  return sandbox
end
terminal = {
  x = 0,
  y = 0,
  ps = '> ',
  activation = 'f12',
  width = 500,
  height = 250,
  textin = "",
  lines = { },
  cursor = 0,
  startline = 1,
  focus = false,
  visible = false,
  fonth = font:getHeight(),
  blinktime = 1.0,
  history = Stack(100),
  curhist = 0,
  suggest = false,
  suggestlength = 3,
  cursugg = 0,
  bgcolor = {
    23,
    23,
    23,
    192
  },
  fontcolor = {
    243,
    243,
    243
  },
  inputcolor = {
    53,
    53,
    53,
    192
  },
  cursorcolor = {
    243,
    243,
    243
  },
  errorcolor = {
    237,
    24,
    38
  },
  index = _G,
  resize = function(self, width, height)
    if width == nil then
      width = 500
    end
    if height == nil then
      height = 250
    end
    self.width, self.height = width, height
    canvas = love.graphics.newCanvas(self.width, self.height - self.fonth)
    clearCanvas(canvas, self.bgcolor)
    return resetCanvas()
  end,
  addWords = function(self, t)
    for k, v in pairs(t) do
      words[#words + 1] = k
    end
  end,
  draw = function(self)
    if self.visible then
      local line_h = self.height - self.fonth
      local r, g, b, a = love.graphics.getColor()
      if redraw then
        clearCanvas(canvas, self.bgcolor)
        local y, i = 0, self.startline
        while y <= (line_h) and i <= #self.lines do
          local line = self.lines[i]
          if type(line) == 'table' then
            love.graphics.setColor(line.color)
            line = tostring(line[1])
          else
            love.graphics.setColor(self.fontcolor)
          end
          love.graphics.printf(line, self.x + 1, self.y + y, self.width, "left")
          y = y + self.fonth
          i = i + 1
        end
        resetCanvas()
      end
      love.graphics.setColor(r, g, b, a)
      love.graphics.draw(canvas, self.x, self.y)
      redraw = false
      love.graphics.setColor(self.inputcolor)
      love.graphics.rectangle("fill", self.x, line_h, self.width, self.fonth)
      local input = self.ps .. self.textin
      if selection["end"] - selection.start > 0 then
        if selection["end"] > #self.textin then
          selection["end"] = #self.textin
        end
        local sel = input:sub(1, selection.start + 2)
        local selx = 1 + font:getWidth(sel)
        local selw = font:getWidth(self.textin:sub(selection.start + 1, selection["end"]))
        love.graphics.setColor(107, 142, 192)
        love.graphics.rectangle("fill", selx, line_h + 1, selw + 2, self.fonth - 1)
      end
      love.graphics.setColor(self.fontcolor)
      love.graphics.print(input, 2, line_h)
      drawSuggestions(self)
      local br = self.cursorcolor[1] * blink
      local bg = self.cursorcolor[2] * blink
      local bb = self.cursorcolor[3] * blink
      love.graphics.setColor(br, bg, bb)
      local curtime = love.timer.getTime()
      blink = blink - ((curtime - lasttime) / self.blinktime)
      lasttime = curtime
      if blink < 0 then
        blink = 1
      end
      local sub = input:sub(1, self.cursor + 2)
      local cursorx = 2 + font:getWidth(sub)
      love.graphics.rectangle("fill", cursorx, line_h + 1, 2, self.fonth - 1)
      return love.graphics.setColor(r, g, b, a)
    end
  end,
  evaluate = function(self, t, nosandbox, lua)
    local fn = nil
    local ldstring = lua and loadstring or Moon.loadstring
    if type(t) == 'string' then
      t = t:gsub('`', 'print '):gsub('|', ' in pairs ')
      t = t:gsub('%$', 'for k,v in pairs ')
      local err
      fn, err = ldstring(t)
      if not fn then
        return self:error(err:gsub('\n', ' '):gsub('%[%d+%] >>', ''))
      end
    elseif type(t) == 'function' then
      fn = t
    end
    if not nosandbox then
      setfenv(fn, getSandbox())
    end
    local status, err = pcall(fn)
    if not status then
      return self:error(err:gsub(".*:%d+:", "error: "))
    else
      if err then
        if type(err) == 'function' then
          return self:evaluate(err, true)
        else
          return self:write(err)
        end
      end
    end
  end,
  clear = function(self)
    self.lines = { }
    self.startline = 1
    self.cursor = 0
    self.cursugg = 0
    redraw = true
  end,
  sandbox = function()
    return getSandbox()
  end,
  close = function()
    return nil
  end,
  flush = function()
    return nil
  end,
  error = function(self, t)
    return self:write({
      t,
      color = self.errorcolor
    })
  end,
  write = function(self, t)
    if type(t) == 'table' and not t.color then
      for k, v in pairs(t) do
        self:write("  " .. tostring(tostring(k)) .. ": " .. tostring(tostring(v)))
      end
    elseif type(t) == 'table' and t.color then
      self.lines[#self.lines + 1] = t
    else
      redraw = true
      local rem = nil
      t = tostring(t)
      local start, last = t:find('\n')
      if start then
        rem = t:sub(last + 1)
        t = t:sub(1, start - 1)
      end
      self.lines[#self.lines + 1] = t
      if rem then
        self:write(rem)
      end
    end
    if self.startline + 1 <= #self.lines - math.floor((self.height - self.fonth) / self.fonth) then
      self.startline = self.startline + 1
    end
  end,
  inputline = function(self, lua)
    self:write(self.textin)
    self:evaluate(self.textin, nil, lua)
    self.cursor = 0
    if self.history:get(1) ~= self.textin then
      self.history:push(self.textin)
    end
    self.curhist = 0
    self.textin = ""
    self.cursugg = 0
  end,
  textinput = function(self, t, grapher)
    if self.focus then
      if isSelection() then
        self.cursor, self.textin = snipSelection(self.textin, t)
      else
        if self.cursor >= #self.textin then
          self.textin = self.textin .. t
        else
          self.textin = self.textin:sub(1, self.cursor) .. t .. self.textin:sub(self.cursor + 1)
        end
        self.cursor = self.cursor + 1
      end
      clearSelection()
      if #self.textin >= self.suggestlength then
        self.suggest = true
      end
    end
  end,
  mousepressed = function(self, x, y, button)
    if not self.focus then
      return 
    end
    if x <= self.width and y < self.height then
      if button == "wu" then
        if self.startline - 1 >= 1 then
          self.startline = self.startline - 1
          redraw = true
        end
      elseif button == "wd" then
        if self.startline + 1 <= #self.lines - math.floor((self.height - self.fonth) / self.fonth) then
          self.startline = self.startline + 1
          redraw = true
        end
      end
    end
  end,
  keypressed = function(self, key, rep)
    if key == self.activation then
      self.visible = not self.visible
      self.focus = not self.focus
      blink, lasttime = 1, 0
    end
    if not self.focus then
      return 
    end
    local ctrlDown = love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')
    local shiftdown = love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
    if key == "up" or key == "down" then
      if self.suggest and #res > 0 then
        self.cursugg = self.cursugg + (key == "up" and -1 or 1)
        if self.cursugg < 0 then
          self.cursugg = #res
        end
        if self.cursugg > #res then
          self.cursugg = 0
        end
        return 
      end
      self.curhist = self.curhist + (key == "up" and 1 or -1)
      if self.curhist > self.history:size() then
        self.curhist = self.history:size()
      end
      if self.curhist < 1 then
        self.curhist = 1
      end
      local newtxt = self.history:get(self.curhist) or self.textin
      self.textin = newtxt
      self.cursor = #self.textin
      return clearSelection()
    elseif key == "tab" then
      if self.suggest and res[1] then
        if self.cursugg == 0 then
          self.cursugg = 1
        end
        self.textin = res[self.cursugg]
        self.cursor = #self.textin
        self.cursugg = 0
        return clearSelection()
      end
    elseif key == "right" or key == "left" then
      local dir = key == "right" and 1 or -1
      self.cursor = self.cursor + dir
      if self.cursor > #self.textin then
        self.cursor = #self.textin
      end
      if self.cursor < 0 then
        self.cursor = 0
      end
      if shiftdown then
        if selection.start == -1 then
          selection.start = self.cursor - dir
        end
        if selection["end"] == -1 then
          selection["end"] = self.cursor - dir
        end
        if dir > 0 then
          selection["end"] = self.cursor
        else
          selection.start = self.cursor
        end
        return sortSelection()
      elseif ctrlDown then
        if self.history:size() > 0 then
          self.curhist = dir == -1 and self.history:size() or 1
          self.textin = self.history:get(self.curhist) or self.textin
          self.cursor = #self.textin
          return clearSelection()
        end
      else
        return clearSelection()
      end
    elseif key == "escape" then
      self.suggest = false
      return clearSelection()
    elseif key == "backspace" or key == "delete" then
      if isSelection() then
        self.cursor = selection.start
        self.textin = self.textin:sub(1, selection.start) .. self.textin:sub(selection["end"] + 1)
        clearSelection()
        return 
      end
      local l = key == "backspace" and 1 or 0
      local r = key == "delete" and 2 or 1
      local len = self.textin:len()
      if self.cursor < len then
        self.textin = self.textin:sub(1, self.cursor - l) .. self.textin:sub(self.cursor + r)
      elseif self.cursor >= len then
        self.textin = self.textin:sub(1, self.cursor - l)
      end
      if key == "backspace" then
        self.cursor = self.cursor - 1
      end
      if self.cursor < 0 then
        self.cursor = 0
      end
    elseif key == "return" or key == "kpenter" then
      self.suggest = false
      clearSelection()
      return self:inputline(shiftdown)
    elseif key == "a" and ctrlDown then
      selection.start = 0
      selection["end"] = #self.textin
      self.cursor = #self.textin
    elseif (key == "c" or key == "x") and ctrlDown then
      if not isSelection() then
        return 
      end
      clipboard = self.textin:sub(selection.start + 1, selection["end"])
      if key == "x" then
        self.cursor = selection.start
        self.textin = self.textin:sub(1, selection.start) .. self.textin:sub(selection["end"] + 1)
        return clearSelection()
      end
    elseif key == "v" and ctrlDown then
      if isSelection() then
        self.cursor, self.textin = snipSelection(self.textin, clipboard)
      else
        self.textin = self.textin:sub(1, self.cursor) .. clipboard .. self.textin:sub(self.cursor + 1)
        self.cursor = self.cursor + #clipboard
      end
      return clearSelection()
    end
  end
}
return setmetatable(terminal, {
  __call = function(self, activation, width, height, index)
    self.activation = activation or self.activation
    self:resize(width, height)
    self.index = index
    self:addWords(index)
    self:addWords(getSandbox())
    return self
  end
})
