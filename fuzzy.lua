-- luafuzz.lua
-- public domain by szensk
-- buggy reimplementation of https://github.com/garybernhardt/selecta

local mmin, unpack = math.min, unpack

-- returns indexes of character within string (str)
local function find_chars(str, first_char)
  local i = 0
  local res = {}
  while i do
    i = str:find(first_char, i + 1, true)
    res[#res + 1] = i
  end
  return res
end

-- returns last index of pattern within string (str) starting after first index (index)
local function find_end(str, index, query)
  local last = index
  for i=2, #query do
    last = str:find(query:sub(i,i), index + 1, true) --or last
    if not last then return nil end
  end
  return last
end

-- returns length of match within str
local function compute_match_len(str, query)
  local first_char = query:sub(1,1)
  local first_indexes = find_chars(str, first_char)
  local res = {}
  -- find last indexes
  for i, index in ipairs(first_indexes) do
    local last_index = find_end(str, index, query)
    if last_index then
      res[#res + 1] = last_index - index 
    end
  end

  if #res == 0 then return nil end
  return mmin(unpack(res)) --crash if #matches is over MAXSTACK (defined at compile time)
end

-- usage: local fuzzy = require 'fuzzy'; 
--        fuzzy("map.tmx", "tm") --> 0.28571428571429
-- returns score (normalized 0..1?) of string
local function score(str, query)
  if #query == 0 then return 1 end
  if #str == 0 then return 0 end

  str = str:lower()
  local match_len = compute_match_len(str, query)
  if not match_len or match_len == 0 then return 0 end

  local score = #query / match_len
  return score / #str
end

return score
