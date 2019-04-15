---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Type = require("LuaORM/Util/Type/Type")
local TypedValue = require("LuaORM/Util/Type/TypedValue")
local API = LuaORM_API

---
-- Stores a single settings value.
--
-- @type SettingValue
--
local SettingValue = {}


---
-- The default value
--
-- @tfield mixed defaultValue
--
SettingValue.defaultValue = nil

---
-- Defines whether the SettingValue must be set
--
-- @tfield bool mustBeSet
--
SettingValue.mustBeSet = true


-- Metamethods

---
-- SettingValue constructor.
-- This is the __call metamethod.
--
-- @tparam string _dataType The lua data type of the SettingValue
-- @tparam mixed _defaultValue The default value for the SettingValue
-- @tparam bool _mustBeSet Defines whether the SettingValue must be set
--
-- @treturn SettingValue The SettingValue instance
--
function SettingValue:__construct(_dataType, _defaultValue, _mustBeSet)

  local instance = TypedValue(_dataType)
  setmetatable(instance, {__index = SettingValue})

  instance.mustBeSet = _mustBeSet

  if (_defaultValue ~= nil and instance:valueMatchesLuaDataType(_defaultValue)) then
    instance.defaultValue = _defaultValue
  end

  return instance

end


-- Public Methods

---
-- Returns the current value of this SettingValue.
--
-- @treturn mixed|nil The current value or nil if no value and no default value is set
--
function SettingValue:getCurrentValue()

  if (self.value == nil) then
    return self.defaultValue
  else
    return self.value
  end

end

---
-- Returns whether the current value of this SettingValue is valid.
--
-- @treturn bool True if the current value of this SettingValue is valid, false otherwise
--
function SettingValue:isValid()

  if (self.mustBeSet == true and self:getCurrentValue() == nil) then
    return false
  else
    return true
  end

end


-- Protected Methods

---
-- Handles a invalid value change call.
--
-- @tparam mixed _newValue The new value to which this SettingValue's value should be set
--
function SettingValue:handleInvalidValueChange(_newValue)

  if (_newValue == nil) then
    self.value = nil
  else
    API.ORM:getLogger():warn(string.format(
      "Invalid value specified for SettingValue '%s': '%s', falling back to default value '%s'",
      Type.toString(self.name),
      Type.toString(_newValue),
      Type.toString(self.defaultValue)
    ))
  end

end


setmetatable(
  SettingValue,
  {
    -- SettingValue inherits methods and attributes from TypedValue
    __index = TypedValue,

    -- When SettingValue() is called, call the __construct() method
    __call = SettingValue.__construct
  }
)


return SettingValue
