--------------------------------------------------------------------------------
-- Network throughput meter widget.
--
-- @author Sherif Mowafy
--------------------------------------------------------------------------------

local textbox = require("wibox.widget.textbox")
local timer = require("gears.timer")
local awful = require("awful")

local networkmeter = {}

networkmeter.mt = {}

local unitTable = { "B", "kB", "mB", "gB" }

-- UTF-8 characters for arrows
local arrowDown = string.char(0xe2, 0x86, 0x93)
local arrowUp = string.char(0xe2, 0x86, 0x91)

------------------------------------------
--- Helper functions start

-- Returns the nth element in an iterator, returns nil if it doesn't exist
function nthElement(iter, n)
  local tmp
  repeat
    tmp = iter()
    if not tmp then
      return nil
    end
    n = n - 1
  until n == 0
  return tmp
end

-- Returns the iterator after removing n elements, returns nil if it has less than n elements
function skipNElements(iter, n)
  while n > 0 do
    if iter() == nil then
      return nil
    end
    n = n - 1
  end
  return iter
end

-- Builds a list from the iterator elements
function buildArrayFromIterator(iter)
  local res = {}
  for elem in iter do
    table.insert(res, elem)
  end
  return res
end

-- Returns a list of token indices in a given string after tokenizing it using the given delimiters
function tokenIndices(targetString, targetToken, delims)
  local res = {}
  local columnCount = 1

  local tokenizerIterator = string.gmatch(targetString, "[^"..delims.."]+")
  for token in tokenizerIterator do
    local matchTargetToken = string.gmatch(token, ".*"..targetToken..".*")()
    if matchTargetToken then
      table.insert(res, columnCount)
    end
    columnCount = columnCount + 1
  end

  return res
end

--- Helper functions end
------------------------------------------


function getThroughput()
  local devFileIterator = io.lines("/proc/net/dev")

  local receivedBytes = 0
  local transmittedBytes = 0


  devFileIterator = skipNElements(devFileIterator, 1) -- skip 1st line

  local columnsStr = devFileIterator()

  local columnNumbers = tokenIndices(columnsStr, "bytes", "|%s")

  for elem in devFileIterator do
    local bytesValIter = string.gmatch(elem, "[%S]+")
    local bytesValArr = buildArrayFromIterator(bytesValIter)

    receivedBytes = receivedBytes + math.abs(bytesValArr[columnNumbers[1]] or 0)

    transmittedBytes = transmittedBytes + math.abs(bytesValArr[columnNumbers[2]] or 0)
  end

  return receivedBytes, transmittedBytes
end

function unitDetection(byteCount, down)
  local unitIndex = 1

  while byteCount > 1024 and unitIndex <= #unitTable do
    unitIndex = unitIndex + 1
    byteCount = byteCount / 1024
  end

  byteCount = byteCount - (byteCount % 0.01)

  local arrow = arrowUp

  if down then
    arrow = arrowDown
  end

  return byteCount.." "..unitTable[unitIndex].."/sec "..arrow
end

function diffAbs(a, b)
  a = a or 0
  b = b or 0

  return math.abs(a - b)
end

function networkmeter.new()
  local w = textbox()
  local t

  w._private.recv_curr = 0
  w._private.trans_curr = 0

  function w._private.update_cb()
    local recv_throughput, trans_throughput = getThroughput()
    local recv_diff = diffAbs(recv_throughput, w._private.recv_curr)
    local trans_diff = diffAbs(trans_throughput, w._private.trans_curr)

    local receiveString = unitDetection(recv_diff, true)
    local transmitString = unitDetection(trans_diff, false)
    
    w:set_markup(receiveString.." "..transmitString)

    w._private.recv_curr = recv_throughput
    w._private.trans_curr = trans_throughput

    t:again()

    return true
  end


  t = timer.weak_start_new(1, w._private.update_cb)
  t:start()

  return w
end

networkmeter.mt.__call = function(...)
  return networkmeter.new()
end

return setmetatable(networkmeter, networkmeter.mt)

