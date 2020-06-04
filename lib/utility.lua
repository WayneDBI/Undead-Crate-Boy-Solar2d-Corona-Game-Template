--we need a few support functions
local M = {}
local json = require("json")

function M.saveTable(t, filename)
   local path = system.pathForFile( filename, system.DocumentsDirectory)
   local file = io.open(path, "w")
   if file then
      local contents = json.encode(t)
      file:write( contents )
      io.close( file )
      return true
   else
      return false
   end
end

--simple load table function
function M.loadTable(filename)
   local path = system.pathForFile( filename, system.DocumentsDirectory)
   local contents = ""
   local myTable = {}
   local file = io.open( path, "r" )
   if file then
      local contents = file:read( "*a" )
      myTable = json.decode(contents);
      io.close( file )
      return myTable
   end
   print(filename, "file not found")
   return nil
end

function M.makeTimeStamp(dateString, mode)
    local pattern = "(%d+)%-(%d+)%-(%d+)%a(%d+)%:(%d+)%:([%d%.]+)([Z%p])(%d*)%:?(%d*)";
    local xyear, xmonth, xday, xhour, xminute, xseconds, xoffset, xoffsethour, xoffsetmin
    local monthLookup = {Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12}
    local convertedTimestamp
    local offset = 0
    if mode and mode == "ctime" then
        pattern = "%w+%s+(%w+)%s+(%d+)%s+(%d+)%:(%d+)%:(%d+)%s+(%w+)%s+(%d+)"
        local monthName, TZName
        monthName, xday, xhour, xminute, xseconds, TZName, xyear = string.match(dateString,pattern)
        xmonth = monthLookup[monthName]
        convertedTimestamp = os.time({year = xyear, month = xmonth,
        day = xday, hour = xhour, min = xminute, sec = xseconds})
    else
        xyear, xmonth, xday, xhour, xminute, xseconds, xoffset, xoffsethour, xoffsetmin = string.match(dateString,pattern)
        convertedTimestamp = os.time({year = xyear, month = xmonth,
        day = xday, hour = xhour, min = xminute, sec = xseconds})
        if xoffsetHour then
            offset = xoffsethour * 60 + xoffsetmin
            if xoffset == "-" then
                offset = offset * -1
            end
        end
    end
    return convertedTimestamp + offset
end

return M