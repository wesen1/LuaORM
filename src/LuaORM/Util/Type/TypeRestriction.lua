---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local Type = require("LuaORM/Util/Type/Type")
local unpack = unpack or table.unpack
local API = LuaORM_API

---
-- TypeRestriction interface.
--
-- @type TypeRestriction
--
local TypeRestriction = {}


---
-- Static list of validator functions.
--
-- @tfield function[] validators
--
TypeRestriction.validators = {

  -- Using a different array notation because some of the indexes are reserved keywords (e.g. function)
  ["string"] = Type.isString,
  ["number"] = Type.isNumber,
  ["integer"] = Type.isInteger,
  ["boolean"] = Type.isBoolean,
  ["function"] = Type.isFunction,
  ["table"] = Type.isTable,
  ["instanceof"] = ObjectUtils.isInstanceOf
}

---
-- Static list of converter functions.
--
-- @tfield function[] converters
--
TypeRestriction.converters = {
  ["string"] = Type.toString,
  ["number"] = Type.toNumber,
  ["integer"] = Type.toInteger,
  ["boolean"] = Type.toBoolean
}

---
-- The lua data type to which all values are restricted
-- All data types for which a validator exists can be used
--
-- @tfield string luaDataType
--
TypeRestriction.luaDataType = nil

---
-- The additional arguments that must be passed to the validator method
--
-- @tfield mixed[] additionalValidatorArguments
--
TypeRestriction.additionalValidatorArguments = {}

---
-- The additional arguments that must be passed to the converter method
--
-- @tfield mixed[] additionalConverterArguments
--
TypeRestriction.additionalConverterArguments = {}


-- Metamethods

---
-- TypeRestriction constructor.
-- This is the __call metamethod.
--
-- @tparam string _luaDataType The name of the lua data type
--
-- @treturn TypeRestriction The TypeRestriction instance
--
function TypeRestriction:__construct(_luaDataType)

  local instance = setmetatable({}, {__index = TypeRestriction})
  instance:changeLuaDataType(_luaDataType)

  return instance

end


-- Public Methods

---
-- Validates that a value matches the lua data type of this TypeRestriction.
--
-- @tparam mixed _value The value
--
-- @treturn bool True if the value matches the lua data type of this TypeRestriction, false otherwise
--
function TypeRestriction:validator(_value)
  return true
end

---
-- Converts a value to the lua data type of this TypeRestriction.
--
-- @tparam mixed _value The value
--
-- @treturn mixed The converted value
--
function TypeRestriction:converter(_value)
  return _value
end


-- Protected Methods

---
-- Returns whether a value matches this TypeRestriction's data type.
--
-- @tparam mixed _value The value
--
-- @treturn bool True if the value matches this TypeRestriction's data type, false otherwise
--
function TypeRestriction:valueMatchesLuaDataType(_value)
  return self.validator(_value, unpack(self.additionalValidatorArguments))
end

---
-- Converts a value to this TypeRestriction's lua data type.
--
-- @tparam mixed _value The value
--
-- @treturn mixed The converted value or nil if no converter for this TypeRestriction's lua data type exists
--
function TypeRestriction:convertValueToLuaDataType(_value)
  return self.converter(_value, unpack(self.additionalConverterArguments))
end


-- Private Methods

---
-- Changes the lua data type to a new type if possible.
--
-- @tparam string _luaDataType The lua data type name
--
function TypeRestriction:changeLuaDataType(_luaDataType)

  local luaDataTypeName, classPath = _luaDataType:match("^([^:]+):?(.*)$")

  if (luaDataTypeName == "any") then
    self.validator = nil
    self.converter = nil
  else

    if (self:changeValidator(luaDataTypeName, classPath)) then
      self:changeConverter(luaDataTypeName, classPath)
    else
      API.ORM:getLogger():warn("Could not change lua data type to '" .. _luaDataType .. "': No validator found for this type")
    end

  end

end

---
-- Changes the validator method based on a specified lua data type.
--
-- @tparam string _luaDataType The lua data type
-- @tparam string _classPath The require path for the class for "instanceof" (optional)
--
-- @treturn bool True if a validator was found for th lua data type, false otherwise
--
function TypeRestriction:changeValidator(_luaDataTypeName, _classPath)

  local validator = TypeRestriction.validators[_luaDataTypeName]
  if (validator) then
    self.validator = validator

    if (_luaDataTypeName == "instanceof") then
      self.additionalValidatorArguments = { _classPath }
      self.luaDataType = _classPath
    else
      self.additionalValidatorArguments = nil
      self.luaDataType = _luaDataTypeName
    end

    return true

  else
    return false
  end

end

---
-- Changes the converter method based on a specified lua data type.
-- Falls back to the default converter when no converter is found for the lua data type.
--
-- @tparam string _luaDataType The lua data type
-- @tparam string _classPath The require path for the class for "instanceof" (optional)
--
function TypeRestriction:changeConverter(_luaDataTypeName, _classPath)

  local converter = TypeRestriction.converters[_luaDataTypeName]
  if (converter) then
    self.converter = converter
  else
    self.converter = nil
  end

end


-- When TypeRestriction() is called, call the __construct() method
setmetatable(TypeRestriction, {__call = TypeRestriction.__construct})


return TypeRestriction
