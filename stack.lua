
local Stack = nil
do
  local _base_0 = {
    push = function(self, obj)
      assert(obj, "Attempt to push nil argument to stack")
      self.count = self.count + 1
      if self.maxn and self.count > self.maxn then
        self.count = 1
        self.full = true
      end
      self.data[self.count] = obj
    end,
    pop = function(self)
      local obj = self.data[self.count]
      self.data[self.count] = nil
      self.count = self.count - 1
      if self.maxn and self.count < 1 then
        self.count = 1
      end
      return obj
    end,
    get = function(self, i)
      if self.maxn then
        if i > self.maxn or i < 1 then
          return nil
        end
        i = self.count - (i - 1)
        if i < 1 then
          i = self.maxn + i
        end
      end
      return self.data[i]
    end,
    contains = function(self, obj)
      local result = false
      local size = self.maxn or count
      for i = 1, size do
        if {
          self = get(i) == element
        } then
          return true, i
        end
      end
      return result
    end,
    bottom = function(self)
      return self.data[1]
    end,
    top = function(self)
      return self.data[self.count]
    end,
    empty = function(self)
      return self.count == 0
    end,
    size = function(self)
      if self.full then
        return self.maxn
      end
      return self.count
    end,
    __tostring = function(self)
      local res
      do
        local _accum_0 = { }
        local _len_0 = 1
        for k, v in ipairs(self.data) do
          _accum_0[_len_0] = tostring(k) .. ": " .. tostring(v)
          _len_0 = _len_0 + 1
        end
        res = _accum_0
      end
      return table.concat(res, "\n")
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, size)
      self.maxn = size
      self.data = { }
      self.count = 0
    end,
    __base = _base_0,
    __name = "Stack"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  Stack = _class_0
end
return Stack
