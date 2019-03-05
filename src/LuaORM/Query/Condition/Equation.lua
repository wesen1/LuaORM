---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local Type = require("LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- Provides methods to configure a equation.
--
-- @type Equation
--
local Equation = {}


---
-- Static list of available operators to chain other equations
--
-- @tfield int[] chainOperators
--
Equation.chainOperators = {
  AND = 1,
  OR = 2
}

---
-- The chain operator id that will be used to chain this Equation to the next Equation (if there is any)
--
-- @tfield int chainOperatorToNextEquation
--
Equation.chainOperatorToNextEquation = Equation.chainOperators.AND

---
-- The equation settings
-- Using a settings table to avoid duplicate table indexes (e.g. "column" attribute and method)
--
-- @tfield mixed[] settings
--
Equation.settings = {

  ---
  -- Indicates whether the whole Equation will be negated (with a leading NOT)
  --
  -- @tfield bool NOT
  --
  NOT = false,

  ---
  -- The column that will be compared to a value (text, number, etc.)
  --
  -- @tfield TableColumn column
  --
  column = nil,


  -- Equation Type A: The column is compared to a value

  ---
  -- The operator that will be used to compare the column and the value
  -- This can be either "<", "<=", "=", ">" or ">="
  --
  -- @tfield string operator
  --
  operator = nil,

  ---
  -- The value to compare the column to
  --
  -- @tfield mixed value
  --
  value = nil,


  -- Equation Type B: The column is compared to a list of values

  ---
  -- The list of values of which one has to equal the column value
  --
  -- @tfield mixed[] inValueList
  --
  isInValueList = nil,


  -- Equation Type C: The column is compared to the "value not set" string

  ---
  -- If true this Equation will check whether the column value is not set
  --
  -- @tfield bool isNotSet
  --
  isNotSet = nil
}


-- Metamethods

---
-- Equation constructor.
-- This is the __call metamethod.
--
-- @tparam Condition _parentCondition The parent condition
--
-- @treturn Equation The Equation instance
--
function Equation:__construct(_parentCondition)

  local instance = setmetatable({}, {__index = Equation})

  instance.parentCondition = _parentCondition
  instance.settings = ObjectUtils.clone(Equation.settings)

  return instance

end


-- Getters and Setters

---
-- Returns the id of the Equation's chain operator to the next Equation.
--
-- @treturn int The id of the Equation's chain operator to the next Equation
--
function Equation:getChainOperatorToNextEquation()
  return self.chainOperatorToNextEquation
end

---
-- Returns the Equation's settings.
--
-- @treturn mixed[] The Equation's settings
--
function Equation:getSettings()
  return self.settings
end


-- API

---
-- Negates this Equation.
-- "not" is a reserved keyword, therefore the method name is "NOT" in uppercase as a workaround.
--
function Equation:NOT()
  self.settings.NOT = true
end

---
-- Sets the Equation's column.
--
-- @tparam string _columnName The name of the column
--
function Equation:column(_columnName)
  self:changeColumn(_columnName)
end


---
-- Configures a "less than x" Equation.
--
-- @tparam number _maximumValue The maximum value
--
function Equation:isLessThan(_maximumValue)
  self.settings.operator = "<"
  self:changeValue(_maximumValue)
end

---
-- Configures a "less than or equal x" Equation.
--
-- @tparam number _maximumValue The maximum value
--
function Equation:isLessThanOrEqual(_maximumValue)
  self.settings.operator = "<="
  self:changeValue(_maximumValue)
end

---
-- Configures a "greater than x" Equation.
--
-- @tparam number _minimumValue The minimum value
--
function Equation:isGreaterThan(_minimumValue)
  self.settings.operator = ">"
  self:changeValue(_minimumValue)
end

---
-- Configures a "greater than or equal x" Equation.
--
-- @tparam number _minimumValue The minimum value
--
function Equation:isGreaterThanOrEqual(_minimumValue)
  self.settings.operator = ">="
  self:changeValue(_minimumValue)
end

---
-- Configures a "equal x" Equation.
--
-- @tparam mixed _value The value
--
function Equation:equals(_value)

  if (_value == nil) then
    self:isNotSet()
  elseif (Type.isTable(_value)) then
    self:isInValueList(_value)
  else
    self.settings.operator = "="
    self:changeValue(_value)
  end

end


---
-- Makes the Equation check that the column value equals one element of a specified list of values.
--
-- @tparam mixed[] _valueList The list of values
--
function Equation:isInList(_valueList)
  self:changeValueList(_valueList)
end


---
-- Makes the Equation check whether the column is not set.
--
function Equation:isNotSet()
  self.settings.isNotSet = true
end

---
-- Finishes this Equation with the and operator and adds a new equation to the parent condition.
-- "and" is a reserved keyword, therefore the method name is "AND" in uppercase as a workaround.
--
function Equation:AND()
  self.chainOperatorToNextEquation = self.chainOperators.AND
  self.parentCondition:addNewEquation()
end

---
-- Finishes this Equation with the or operator and adds a new equation to the parent condition.
-- "or" is a reserved keyword, therefore the method name is "OR" in uppercase as a workaround.
--
function Equation:OR()
  self.chainOperatorToNextEquation = self.chainOperators.OR
  self.parentCondition:addNewEquation()
end


-- Public Methods

---
-- Returns whether this Equation is empty.
-- This is done by checking whether the settings match the default settings.
--
-- @treturn bool True if the equation is empty, false otherwise
--
function Equation:isEmpty()

  for settingName, value in pairs(self.settings) do
    if (value ~= Equation.settings[settingName]) then
      return false
    end
  end

  return true

end

---
-- Returns whether this Equation is valid.
--
-- @treturn bool True if this Equation is valid, false otherwise
--
function Equation:isValid()

  -- Check if the comparison column is set
  if (self.settings.column == nil) then
    return false
  end

  if (self.settings.operator ~= nil) then
    return self:validateComparison()
  else
    return (self.settings.isInValueList ~= nil or self.settings.isNotSet ~= nil)
  end

  return false

end


-- Private Methods

---
-- Changes the column of this Equation.
--
-- @tparam string _columnName The name of the column
--
function Equation:changeColumn(_columnName)

  local column = self.parentCondition:getParentClause():getParentQuery():getColumnByName(_columnName)
  if (column == nil) then
    API.ORM:getLogger():warn("Can not set Equation's column: Unknown column '" .. Type.toString(_columnName) .. "'")
  else
    self.settings.column = column
  end

end

---
-- Changes the value of this Equation.
--
-- @tparam mixed _value The value
--
function Equation:changeValue(_value)

  if (self.settings.column == nil) then
    API.ORM:getLogger():warn("Cannot change Equations value to '" .. Type.toString(_value) .. "': Compare column was not defined")
  else

    if (self.settings.column:getFieldType():validate(_value)) then
      self.settings.value = self.settings.column:getValueQueryString(_value)
    else
      API.ORM:getLogger():warn("Cannot change Equations value to '" .. Type.toString(_value) .. "': Value does not match the columns field type (Column Name: '" .. self.settings.column:getName() .. "')")
    end

  end

end

---
-- Changes the value list for the "in value list" Equation's.
--
-- @tparam mixed[] _valueList The value list
--
function Equation:changeValueList(_valueList)

  if (self.settings.column == nil) then
    API.ORM:getLogger():warn("Cannot change Equations value list to '" .. Type.toString(_valueList) .. "': Target column is not set")
  else

    local valueList = {}
    for _, value in ipairs(_valueList) do

      if (self.settings.column:getFieldType():validate(value)) then
        table.insert(valueList, self.settings.column:getValueQueryString(value))
      else
        API.ORM:getLogger():warn("Cannot add value '" .. Type.toString(value) .. "' to Equations value list: Value does not match the columns field type")
      end
    end

    self.settings.isInValueList = valueList

  end

end

---
-- Validates the comparison settings for this Equation.
--
-- @treturn bool True if the comparison settings for this Equation are valid, false otherwise
--
function Equation:validateComparison()

  if (self.settings.operator == "=") then
    return true
  else

    local sqlDataType = self.settings.column:getFieldType():getSettings()["SQLDataType"]
    if (API.ORM:getDatabaseConnection():getDatabaseLanguage():isNumberDataType(sqlDataType)) then
      return true
    else
      return false
    end

  end

end


-- When Equation() is called, call the __construct() method
setmetatable(Equation, {__call = Equation.__construct})


return Equation
