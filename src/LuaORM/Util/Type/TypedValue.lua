---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local TypeRestriction = require("LuaORM/Util/Type/TypeRestriction")

---
-- Stores a value that must match a specific type.
--
-- @type TypedValue
--
local TypedValue = {}


---
-- The value
--
-- @tfield mixed value
--
TypedValue.value = nil


-- Metamethods

---
-- TypedValue constructor.
-- This is the __call metamethod.
--
-- @tparam string _luaDataType The name of the lua data type
--
-- @treturn TypedValue The TypedValue instance
--
function TypedValue:__construct(_luaDataType)

  local instance = TypeRestriction(_luaDataType)
  setmetatable(instance, {__index = TypedValue})

  return instance

end


-- Getters and Setters

---
-- Returns the value of this TypedValue.
--
-- @treturn mixed The value of this TypedValue
--
function TypedValue:getValue()
  return self.value
end


-- Public Methods

---
-- Changes the value of this TypedValue.
-- The value will not be changed if the new value doesn't match the data type of this TypedValue.
--
-- @tparam mixed _newValue The new value
--
function TypedValue:changeValue(_newValue)

  if (self:valueMatchesLuaDataType(_newValue)) then
    self.value = _newValue
  else
    self:handleInvalidValueChange(_newValue)
  end

end


-- Protected Methods

---
-- Handles a invalid value change call.
--
-- @tparam mixed _newValue The new value to which this TypedValue's value should be set
--
function TypedValue:handleInvalidValueChange(_newValue)
end


setmetatable(
  TypedValue,
  {
    -- TypedValue inherits methods and attributes from TypeRestriction
    __index = TypeRestriction,

    -- When TypedValue() is called, call the __construct() method
    __call = TypedValue.__construct
  }
)


return TypedValue
