---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local SettingValueList = require("LuaORM/Util/SettingValueList/SettingValueList")
local Type = require("LuaORM/Util/Type/Type")
local TypeRestriction = require("LuaORM/Util/Type/TypeRestriction")

---
-- Stores the FieldType configuration for a TableColumn.
-- This includes:
-- * The data type in the database
-- * The data type in lua
-- * Custom formats to convert values to before inserting them into a SQL query
-- * Custom formats to convert query result values to
--
-- @type FieldType
--
local FieldType = {}


---
-- The FieldType's settings
--
-- @tfield SettingValueList settings
--
FieldType.settings = SettingValueList(

  -- The SQL data type (Must be a type that is compatible with the used database or one of the default data types)
  { name = "SQLDataType", dataType = "string", defaultValue = "string" },

  -- Converts input values before they are further processed
  -- Parameters: value, Return: Converted value
  { name = "convert", dataType = "function", mustBeSet = false },

  -- Validates that a value matches this FieldType
  -- Parameters: value, Return: true/false
  { name = "validator", dataType = "function", mustBeSet = false },

  -- Adds additional parameters to a escaped literal value of this FieldType (e.g. BINARY in MySQL)
  -- Parameters: escapedLiteral, Return: The modified escaped literal
  { name = "as", dataType = "function", mustBeSet = false },

  -- The function that converts a query result value of this FieldType to a lua data type
  -- Parameters: value, Return: The modified value
  { name = "to", dataType = "function", mustBeSet = false }
)


-- Metamethods

---
-- FieldType constructor.
-- This is the __call metamethod.
--
-- @tparam mixed[] _settings The settings
--
-- @treturn FieldType The FieldType instance
--
function FieldType:__construct(_settings)

  local instance = TypeRestriction(_settings["luaDataType"])
  setmetatable(instance, {__index = FieldType})

  instance.settings = ObjectUtils.clone(FieldType.settings)
  instance.settings:parse(_settings)

  return instance

end


-- Getters and Setters

---
-- Returns the FieldType's settings.
--
-- @treturn SettingValueList The FieldType's settings
--
function FieldType:getSettings()
  return self.settings
end


-- Public Methods

---
-- Returns the SQL data type of this FieldType.
--
-- @tparam BaseDatabaseConnection _databaseConnection The database connection
--
-- @treturn string The SQL data type
--
function FieldType:getSQLDataType(_databaseConnection)

  local databaseLanguage = _databaseConnection:getDatabaseLanguage()

  local dataType = databaseLanguage:getDataTypes()[self.settings["SQLDataType"]]
  if (dataType == nil) then
    -- Assume that the set SQLDataType is a custom data type
    return self.settings["SQLDataType"]
  else
    return dataType:getRealType()
  end

end

---
-- Returns whether this FieldType is unsigned.
--
-- @tparam BaseDatabaseLanguage _databaseLanguage The DatabaseLanguage
--
-- @treturn bool True if this FieldType is unsigned, false otherwise
--
function FieldType:isUnsigned(_databaseLanguage)

  local dataType = _databaseLanguage.dataTypes[self.settings["SQLDataType"]]
  if (dataType ~= nil) then
    return Type.toBoolean(dataType:getSettings()["isUnsigned"])
  end

end

---
-- Returns whether a value is valid for this FieldType.
--
-- @tparam mixed _value The value to check
--
-- @treturn bool True if the value is valid for this FieldType, false otherwise
--
function FieldType:validate(_value)

  local value = self:convertValueBeforeProcessing(_value)
  if (self:valueMatchesLuaDataType(value)) then

    if (self.settings["validator"] == nil) then
      return true
    else
      return self.settings["validator"](value)
    end

  else
    return false
  end

end

---
-- Converts a value to a string that can be inserted into a SQL query (Lua value to SQL string).
--
-- @tparam DatabaseConnection _databaseConnection The database connection
-- @tparam mixed _value The value
--
-- @treturn string The string that can be inserted into a SQL query
--
function FieldType:convertValueToSQLString(_databaseConnection, _value)

  local value
  if (self:validate(_value)) then

    value = self:convertValueBeforeProcessing(_value)
    local escapedValue = _databaseConnection:getDatabaseLanguage():escapeLiteral(value)
    local stringValue = Type.toString(escapedValue)

    if (self.settings["as"] == nil) then
      value = stringValue
    else
      value = self.settings["as"](stringValue)
    end

  end

  if (value == nil) then
    value = _databaseConnection:getDatabaseLanguage():getValueNotSetString()
  end

  return value

end

---
-- Converts a value that was fetched from the database to this FieldType's data typ (SQL Result to Lua).
-- This is necessary because every value from the database is returned as a string by LuaSQL.
--
-- @tparam string _value The value that was fetched from the database
--
-- @treturn mixed The converted value for this FieldType's data type
--
function FieldType:convertValueToFieldType(_value)

  local value = self:convertValueBeforeProcessing(_value)

  -- Convert the value to the lua data type
  value = self:convertValueToLuaDataType(value)

  -- Convert the value with the correct lua data type to a custom format
  if (self.settings["to"] == nil) then
    return value
  else
    return self.settings["to"](value)
  end

end


-- Private Methods

---
-- Converts a input value before further processing it.
--
-- @tparam mixed _value The value
--
-- @treturn mixed _value The converted value
--
function FieldType:convertValueBeforeProcessing(_value)

  if (self.settings["convert"] == nil) then
    return _value
  else
    return self.settings["convert"](_value)
  end

end


setmetatable(
  FieldType,
  {
    -- FieldType inherits methods and attributes from TypeRestriction
    __index = TypeRestriction,

    -- When FieldType() is called, call the __construct() method
    __call = FieldType.__construct
  }
)


return FieldType
