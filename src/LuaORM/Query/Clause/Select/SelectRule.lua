---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local TableColumn = require("LuaORM/Table/TableColumn")
local TableUtils = require("LuaORM/Util/TableUtils")
local Type = require("LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- Base class for SelectRule types.
-- SelectRule's store one rule for an additional SELECT column.
-- This includes a target, a SQL function and additional function arguments.
--
-- @type SelectRule
--
local SelectRule = {}


---
-- The names of the API methods that this SelectRule type provides
--
-- @tfield string[] providedApiMethods
--
SelectRule.providedApiMethods = {}

---
-- The list of available SQL functions
-- The items must be in the format
--    [sqlFunctionName] = {
--      validate = function,
--      convert = function,
--      targetParameterNumber = int,
--      hasNumberDataType = bool
--    }
--
-- @tfield table[] sqlFunctions
--
SelectRule.sqlFunctions = {}

---
-- The target
--
-- @tfield TableColumn|SelectRule target
--
SelectRule.target = nil

---
-- The SQL function of this SelectRule
-- This can be either one of the predefined sql function types (table) or a custom one (string)
--
-- @tfield table|string sqlFunction
--
SelectRule.sqlFunction = nil

---
-- The additional SQL function arguments
--
-- @tfield mixed[] additionalFunctionArguments
--
SelectRule.additionalFunctionArguments = {}

---
-- The parent Select Clause
--
-- @tfield Select parentSelectClause
--
SelectRule.parentSelectClause = nil


-- Metamethods

---
-- SelectRule constructor.
-- This is the __call metamethod.
--
-- @tparam Select _parentSelectClause The parent Select Clause
-- @tparam string _targetName The target name
-- @tparam table|string _sqlFunction The sql function
-- @tparam mixed[] _additionalSqlFunctionArguments The additional sql function arguments (optional)
--
-- @treturn SelectRule The SelectRule instance
--
function SelectRule:__construct(_parentSelectClause, _target, _sqlFunction, _additionalSqlFunctionArguments)

  local instance = setmetatable({}, {__index = SelectRule})

  instance.parentSelectClause = _parentSelectClause
  instance.target = _target
  instance.sqlFunction = _sqlFunction

  if (_additionalSqlFunctionArguments ~= nil) then
    instance.additionalFunctionArguments = self:escapeAdditionalSqlFunctionArguments(_additionalSqlFunctionArguments)
  end

  return instance

end


-- Getters and Setters

---
-- Returns the target.
--
-- @treturn TableColumn|SelectRule The target
--
function SelectRule:getTarget()
  return self.target
end

---
-- Returns the SQL function.
--
-- @treturn table|string The SQL function
--
function SelectRule:getSqlFunction()
  return self.sqlFunction
end


-- Public Methods

---
-- Returns whether this SelectRule type provides a specific API method.
--
-- @tparam string _methodName The name of the API method
--
-- @treturn bool True if this SelectRule type provides that API method, false otherwise
--
function SelectRule:providesApiMethod(_methodName)
  return TableUtils.tableHasValue(self.providedApiMethods, _methodName)
end

---
-- Returns whether this SelectRule is valid.
--
-- @treturn bool True if this SelectRule is valid, false otherwise
--
function SelectRule:isValid()
  return (self.target ~= nil and self:getSqlFunctionName() ~= nil)
end

---
-- Returns the name of this SelectRule's SQL function.
--
-- @treturn string|nil The name of this SelectRule's SQL function or nil if no SQL function was configured yet
--
function SelectRule:getSqlFunctionName()

  if (Type.isTable(self.sqlFunction)) then

    for sqlFunctionName, sqlFunction in pairs(self.sqlFunctions) do
      if (sqlFunction == self.sqlFunction) then
        return sqlFunctionName
      end
    end

  elseif (Type.isString(self.sqlFunction)) then
    return self.sqlFunction
  end

end

---
-- Returns the select alias for this SelectRule.
--
-- @treturn string The select alias for this SelectRule
--
function SelectRule:getSelectAlias()

  local sqlFunctionName = self:getSqlFunctionName()
  local selectAlias

  if (ObjectUtils.isInstanceOf(self.target, TableColumn)) then

    selectAlias = self.target:getName()
    if (not self.parentSelectClause:isColumnNameUnique(self.target:getName())) then
      selectAlias = self.target:getParentTable():getName() .. "_" .. selectAlias
    end

  elseif (ObjectUtils.isInstanceOf(self.target, SelectRule)) then
    selectAlias = self.target:getSelectAlias()
  end

  return sqlFunctionName .. "_" .. selectAlias

end

---
-- Validates that a value is of the same type as the result of this SelectRule.
--
-- @tparam mixed _value The value
--
-- @treturn bool True if the value is of the same type as the result of this SelectRule, false otherwise
--
function SelectRule:validateValue(_value)

  if (Type.isTable(self.sqlFunction) and self.sqlFunction.validate ~= nil) then
    return self.sqlFunction.validate(_value)
  else
    return self.target:validateValue(_value)
  end

end

---
-- Returns the parameters/arguments for the sql function.
--
-- @treturn string[] The parameters for the sql function
--
function SelectRule:getSqlFunctionParameters()

  local targetParameterNumber = self:getTargetParameterNumber()
  local numberOfAddtionalArguments = #self.additionalFunctionArguments

  local parametersBeforeTarget = TableUtils.slice(self.additionalFunctionArguments, 1, targetParameterNumber - 1)
  local parametersAfterTarget = TableUtils.slice(self.additionalFunctionArguments, targetParameterNumber, numberOfAddtionalArguments)

  local databaseLanguage = API.ORM:getDatabaseConnection():getDatabaseLanguage()
  for i = numberOfAddtionalArguments, targetParameterNumber - 2, 1 do
    table.insert(parametersAfterTarget, databaseLanguage:getValueNotSetString())
  end

  return TableUtils.concatenateTables(
    parametersBeforeTarget, { databaseLanguage:getTargetIdentifier(self.target) }, parametersAfterTarget
  )

end

---
-- Returns the query string for a value to compare to this SelectRule's result.
--
-- @tparam mixed _value The value
--
-- @treturn string The query string for a value to compare to this SelectRule's result
--
function SelectRule:getValueQueryString(_value)

  if (Type.isTable(self.sqlFunction) and self.sqlFunction.convert ~= nil) then

    local databaseLanguage = API.ORM:getDatabaseConnection():getDatabaseLanguage()

    if (_value == nil) then
      return databaseLanguage:getValueNotSetString()
    else
      local value = self.sqlFunction.convert(_value)
      return databaseLanguage:escapeLiteral(value)
    end

  else
    return self.target:getValueQueryString(_value)
  end

end

---
-- Returns whether the result of this SelectRule has a number data type.
--
-- @treturn bool True if this SelectRule has a number data type, false otherwise
--
function SelectRule:hasNumberDataType()

  if (Type.isTable(self.sqlFunction)) then
    return (self.sqlFunction.hasNumberDataType == true)
  else
    return self.target:hasNumberDataType()
  end

end

---
-- Returns whether the result of this SelectRule has a text data type.
--
-- @treturn bool True if this SelectRule has a text data type, false otherwise
--
function SelectRule:hasTextDataType()

  if (Type.isTable(self.sqlFunction)) then
    return (self.sqlFunction.hasTextDataType == true)
  else
    return self.target:hasTextDataType()
  end

end


-- Private Methods

---
-- Returns the parameter number of the target in the sql function.
--
-- @treturn int The paramter number of the target
--
function SelectRule:getTargetParameterNumber()

  if (Type.isTable(self.sqlFunction) and self.sqlFunction.targetParameterNumber ~= nil) then
    return self.sqlFunction.targetParameterNumber
  else
    return 1
  end

end

---
-- Escapes a list of literals and returns the result.
--
-- @tparam mixed[] _additionalSqlFunctionArguments The list of literals
--
-- @treturn string[] The escaped list of literals
--
function SelectRule:escapeAdditionalSqlFunctionArguments(_additionalSqlFunctionArguments)

  local escapedArguments = {}
  local databaseLanguage = API.ORM:getDatabaseConnection():getDatabaseLanguage()

  for _, argument in ipairs(_additionalSqlFunctionArguments) do
    table.insert(escapedArguments, databaseLanguage:escapeLiteral(argument))
  end

  return escapedArguments

end


-- When SelectRule() is called, call the __construct() method
setmetatable(SelectRule, {__call = SelectRule.__construct})


return SelectRule
