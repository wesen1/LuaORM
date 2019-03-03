---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local BaseCursor = require("src/LuaORM/DatabaseConnection/BaseCursor")

---
-- Cursor for LuaSQL cursors.
--
-- @type LuaSQLCursor
--
local LuaSQLCursor = {}


---
-- The LuaSQL cursor object that was recieved as a query result
--
-- @tfield Cursor cursor
--
LuaSQLCursor.cursor = nil


-- Metamethods

---
-- LuaSQLCursor constructor.
-- This is the __call metamethod.
--
-- @tparam Cursor _cursor The LuaSQL cursor object (optional)
--
-- @treturn LuaSQLCursor The LuaSQLCursor instance
--
function LuaSQLCursor:__construct(_cursor)

  local instance = setmetatable({}, {__index = LuaSQLCursor})

  if (_cursor ~= nil) then
    instance.cursor = _cursor
  end

  return instance

end


-- Public Methods

---
-- Fetches and returns the next row from the cursor.
-- The row must be converted to the format {[resultColumnName] = value, ...}.
--
-- @treturn string[] The next row
--
function LuaSQLCursor:fetch()
  if (self.cursor ~= nil) then
    return self.cursor:fetch({}, "a")
  end
end

---
-- Closes the cursor.
--
function LuaSQLCursor:close()
  if (self.cursor ~= nil) then
    self.cursor:close()
  end
end


setmetatable(
  LuaSQLCursor,
  {
    -- LuaSQLCursor inherits methods and attributes from BaseCursor
    __index = BaseCursor,

    -- When LuaSQLCursor() is called, call the __construct() method
    __call = LuaSQLCursor.__construct
  }
)


return LuaSQLCursor
