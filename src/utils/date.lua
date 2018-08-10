-- Date class
local utils = require('utils')

local time_keys = {Y = "year", M = "month", D = "day", h = "hour", m = "min", s = "sec"}

local function from_date(datestring, order) -- order is a table with elements defined, defalt YMDhms (Year, Month, Day, Hours, Minutes, Seconds)
   local now = os.date("*t") -- used for defaults (missing elements) if necessary
   local elements = {datestring:match("(%d*)%D*(%d*)%D*(%d*)%D*(%d*)%D*(%d*)%D*(%d*)")}
   utils.reveal("elements:"..table.concat(elements, " "))
   order = order or "YMDhms" -- set how we will interpret those numbers, their order
   local new_time = {}
   for i = 1, #order, 1 do
      local o = order:sub(i, i)
      local k = time_keys[o]
      new_time[k] = elements[i]
   end
   
   if tonumber(new_time.year) < 100 then new_time.year = new_time.year + 2000 end
   local rval = os.time(new_time)
   return os.time(new_time)
end

local function Date(initializer, order) -- order is the order the time elements appear in the string YMDhms is typical
   local self = {}
   
   self.epoch = os.time()
   self.string_format="%Y/%m/%d %H:%M:%S"

   intializer = initializer or os.time()
   
   if type(initializer) == 'number' then
     self.epoch = initializer
   else
      self.epoch = from_date(initializer, order)
   end

   setmetatable(
      self,
      {
	 __tostring = function()
	    return os.date(self.string_format, self.epoch)
	 end
      }
   )
   
   return self
end

--local x = Date(os.time())
--print("DATE:"..tostring(x))

return {
   new = Date
}


