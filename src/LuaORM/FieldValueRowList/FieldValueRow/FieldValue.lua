---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local API = LuaORM_API

---
-- Stores the value of a single field for a row of a specific Table.
--
-- @type FieldValue
--
local FieldValue = {}


---
-- The TableColumn for which this FieldValue stores a value
-- This is used to validate and convert values to which this FieldValue shall be set
--
-- @tfield TableColumn column
--
FieldValue.column = nil

---
-- The last value that was set by a query result
-- This is used to determine whether an UPDATE command is necessary for the field of the row
-- It is also used on the primary key value to find the data row for a delete() call
--
-- @tfield mixed lastQueryResultValue
--
FieldValue.lastQueryResultValue = nil

---
-- The value that was set by using the APIs
-- This is the value that will be used for INSERT and for UPDATE calls
--
-- @tfield mixed value
--
FieldValue.value = nil

---
-- Stores whether the value was set by using the APIs
-- This is necessary to detect whether the value was set to nil intentionally
--
-- @tfield bool isValueSet
--
FieldValue.isValueSet = nil


-- Metamethods

---
-- FieldValue constructor.
-- This is the __call metamethod.
--
-- @tparam TableColum _column The TableColumn for which this FieldValue stores a value
-- @tparam string _lastQueryResultValue The result value of the last query (optional)
--
-- @treturn FieldValue The FieldValue instance
--
function FieldValue:__construct(_column, _lastQueryResultValue)

  local instance = setmetatable({}, {__index = FieldValue})

  instance.column = _column

  if (_lastQueryResultValue == nil) then
    instance.value = _column:getDefaultValue()
  else
    instance:updateLastQueryResultValue(_lastQueryResultValue)
  end

  instance.isValueSet = false

  return instance

end


-- Getters and Setters

---
-- Returns the TableColumn for which this FieldValue stores a value.
--
-- @treturn TableColumn The TableColumn for which this FieldValue stores a value
--
function FieldValue:getColumn()
  return self.column
end

---
-- Returns the last value that was set by a query result.
--
-- @treturn mixed The last value that was set by a query result
--
function FieldValue:getLastQueryResultValue()
  return self.lastQueryResultValue
end


-- Public Methods

---
-- Changes the value of this FieldValue.
-- The value will not be changed if the new value is not valid for the TableColumn.
--
-- @tparam mixed _newValue The new value
--
function FieldValue:updateValue(_newValue)

  if (self.column:getSettings()["isPrimaryKey"] and self.column:getSettings()["autoIncrement"]) then
    API.ORM:getLogger():warn(string.format(
      "Cannot set '%s' manually: FieldValue is a auto incrementing primary key",
      self.column:getSelectAlias()
    ))
    return
  end

  if (_newValue == nil) then
    self:changeValue(nil)
  else

    if (self.column:getFieldType():validate(_newValue)) then
      self:changeValue(_newValue)
    else
      API.ORM:getLogger():warn(string.format(
        "Could not change value of '%s': Value is not valid for the TableColumn",
        self.column:getSelectAlias()
      ))
    end

  end

end

---
-- Returns the manually set value or the last query result value if no value was set.
--
-- @treturn mixed The current value of this FieldValue
--
function FieldValue:getCurrentValue()

  if (self.isValueSet) then
    return self.value
  else
    return self.lastQueryResultValue
  end

end

---
-- Returns a SQL string for the current value of this FieldValue.
--
-- @treturn string The SQL string for the current value of this FieldValue
--
function FieldValue:getSQLString()
  return self.column:getValueQueryString(self:getCurrentValue())
end

---
-- Updates the last query result value.
-- This method assumes that the value is a valid value for the TableColumn.
--
-- @tparam string _lastQueryResultValue The result value of the last query
--
function FieldValue:updateLastQueryResultValue(_lastQueryResultValue)

  if (_lastQueryResultValue == nil) then
    self:unset()
  else
    local lastQueryResultValue = self.column:getFieldType():convertValueToFieldType(_lastQueryResultValue)
    self:changeLastQueryResultValue(lastQueryResultValue)
  end

end

---
-- Replaces the last query result value with the current value.
--
function FieldValue:update()
  self:changeLastQueryResultValue(self.value)
end

---
-- Returns whether the new value differs from the last query result value.
--
-- @treturn bool True if the new value differs from the last query result value, false otherwise
--
function FieldValue:hasValueChanged()
  return (self.isValueSet and self.value ~= self.lastQueryResultValue)
end

---
-- Unsets this FieldValue's last query result value and the manual set value.
--
function FieldValue:unset()
  self:changeLastQueryResultValue(nil)
end

---
-- Returns whether this FieldValue is empty.
--
-- @treturn bool True if this FieldValue is empty, false otherwise
--
function FieldValue:isEmpty()
  return (not self.isValueSet and self.lastQueryResultValue == nil)
end


-- Private Methods

---
-- Changes the current value.
--
-- @tparam mixed _value The current value
--
function FieldValue:changeValue(_value)
  self.value = _value
  self.isValueSet = true
end

---
-- Changes the last query result value and unsets the current value.
--
-- @tparam mixed _lastQueryResultValue The last query result value
--
function FieldValue:changeLastQueryResultValue(_lastQueryResultValue)
  self.lastQueryResultValue = _lastQueryResultValue
  self.value = nil
  self.isValueSet = false
end


-- When FieldValue() is called, call the __construct() method
setmetatable(FieldValue, {__call = FieldValue.__construct})


return FieldValue
