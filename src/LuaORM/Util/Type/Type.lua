---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- Provides static methods to check and to convert value types.
--
-- @type Type
--
local Type = {}


-- Check value types

---
-- Returns whether a value is a number.
--
-- @tparam mixed _value The value
--
-- @treturn True if the value is a number, false otherwise
--
function Type.isNumber(_value)
  return (type(_value) == "number")
end

---
-- Returns whether a value is an integer value.
--
-- @tparam mixed _value The value
--
-- @treturn True if the value is an integer value, false otherwise
--
function Type.isInteger(_value)

  if (Type.isNumber(_value)) then

    local _, fractional = math.modf(_value)
    if (fractional == 0) then
      return true
    end

  end

  return false

end

---
-- Returns whether a value is a string.
--
-- @tparam mixed _value The value
--
-- @treturn True if the value is a string, false otherwise
--
function Type.isString(_value)
  return (type(_value) == "string")
end

---
-- Returns whether a value is a boolean.
--
-- @tparam mixed _value The value
--
-- @treturn True if the value is a boolean, false otherwise
--
function Type.isBoolean(_value)
  return (type(_value) == "boolean")
end

---
-- Returns whether a value is a table.
--
-- @tparam mixed _value The value
--
-- @treturn True if the value is a table, false otherwise
--
function Type.isTable(_value)
  return (type(_value) == "table")
end

---
-- Returns whether a value is a function.
--
-- @tparam mixed _value The value
--
-- @treturn True if the value is a function, false otherwise
--
function Type.isFunction(_value)
  return (type(_value) == "function")
end


-- Convert value types

---
-- Converts a value to a number.
--
-- @tparam mixed _value The value
--
-- @treturn int|float The number value of the value
--
function Type.toNumber(_value)
  return tonumber(_value)
end

---
-- Converts a value to a integer.
--
-- @tparam mixed _value The value
--
-- @treturn int The integer value of the value
--
function Type.toInteger(_value)

  local number = Type.toNumber(_value)
  local integer, _ = math.modf(number)

  return integer

end

---
-- Converts a value to a string.
--
-- @tparam mixed _value The value
--
-- @treturn string The string representation of the value
--
function Type.toString(_value)
  return tostring(_value)
end

---
-- Converts a value to a table.
--
-- @tparam mixed _value The value
--
-- @treturn table The table representation of the value
--
function Type.toTable(_value)

  if (Type.isTable(_value)) then
    return _value
  else
    return { _value }
  end

end

---
-- Converts a value to a boolean.
--
-- @tparam mixed _value The value
--
-- @treturn bool The boolean representation of the value
--
function Type.toBoolean(_value)

  if (_value) then
    return true
  else
    return false
  end

end


return Type
