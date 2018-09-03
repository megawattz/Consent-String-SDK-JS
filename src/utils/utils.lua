-- Generally useful functions

local function iftrue(check, iftrue, iffalse)
   if check then
      return iftrue
   end
   return iffalse
end

local function find(t, item)
   for k, v in pairs(t) do
      if v == item then
	 return k
      end
   end
   return nil
end

local function tostringbase(n, b)
   n = math.floor(n)
   b = b or 10
   if b == 10 then return tostring(n) end
   local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
   local t = {}
   local sign = ""
   if n < 0 then
      sign = "-"
      n = -n
   end
   repeat
      local d = (n % b) + 1
      n = math.floor(n / b)
      table.insert(t, 1, digits:sub(d,d))
   until n == 0
   return sign .. table.concat(t,"")
end

local DebugLevel = 5

local function get_location(upstack) -- get a location up the stack (not very useful to display Debug.set as the location)
   upstack = upstack or 3
   local debug_info = debug.getinfo(upstack)
   if debug_info == nil then return "unknown" end
   local fullpath = debug_info["short_src"]
   local file = fullpath:match("[^/]+$")
   return string.format("%s:%d", file, debug_info["linedefined"])
end      
   
local function reveal(message, priority)
   priority = priority or 5
   if priority > DebugLevel then return end
   print(string.format("%s\t%s", get_location(), message))
end

-- convert data to string. If a table is passed, recurse down until
-- all elements are stringable. How a complex structure is displayed
-- is controlled by options, a table with values:
-- inner: separate key from values with this
-- outer: separate key/value pairs with this
-- entry: indicate entering a nested table with this
-- exit: indicate closing a nested table with this
-- indent: indent nested structures this many spaces
-- limit: do not recurse more than this many levels
-- example: as_string(person, {inner=": ", outer="\n"
-- level is an internal value used for recursion.

local function as_string(value, options, level)
   options = options or {}
   if options.limit and level > options.limit then return end
   options.quotes = options.quotes or true
   level = level or 1
   local rval = ""
   if type(value) == "table" then
      rval = options.entry or '{\n'
      for key, val in pairs(value) do
	 if options.quotes and type(key) == "string" then
	    key = '"'..key..'"'
	 end
	 rval = rval..key..(options.inner or ' = ')..as_string(val, options, level+1)..(options.outer or ",\n")
      end
      rval = rval:gsub((options.outer or ",\n")..'$', "") -- remove excess terminating delimiter
      local indent = string.rep(" ", (options.indent or 2))
      rval = rval:gsub("\n", "\n"..indent) -- any newlines need indentation
      rval = rval..(options.exit or '\n}')
   else
      rval = value
      if options.quotes and type(rval) == "string" then
	 rval = ('"'..rval..'"')
      end
      rval = tostring(rval)
      rval = rval:gsub((options.outer or ",\n")..'$', "") -- remove excess terminating delimiter
   end
   return rval
end

local function see(value)
   if DebugLevel < 5 then return value end
   return value
end

function vardata(variable)
   local rval = {
      ['type'] = type(variable),
      value = as_string(variable),
      size = variable:len() or "n/a"
   }
   return as_string(rval)
end

local function sprintf(fmt, ...)
   return string.format(fmt, unpack(arg))
end

local function reduce(t, func, start)
   local acc = start or ''
   for index, value in ipairs(t) do
      acc = func(acc, value, index, t)
   end
   return acc
end

return {
   iftrue = iftrue,
   as_string = as_string,
   tostringbase = tostringbase,
   reduce = reduce,
   vardata = vardata,
   find = find,
   see = see,
   sprintf = sprintf,
   reveal = reveal
}


