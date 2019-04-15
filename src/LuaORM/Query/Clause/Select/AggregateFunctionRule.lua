---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local SelectRule = require("LuaORM/Query/Clause/Select/SelectRule")
local Type = require("LuaORM/Util/Type/Type")

---
-- Provides aggregate functions for additional SELECT columns.
--
-- @type AggregateFunctionRule
--
local AggregateFunctionRule = {}


---
-- The names of the API methods that this SelectRule type provides
--
-- @tfield string[] providedApiMethods
--
AggregateFunctionRule.providedApiMethods = { "min", "max", "count", "sum" }

---
-- The list of available SQL functions
--
-- @tfield table[] sqlFunctions
--
AggregateFunctionRule.sqlFunctions = {
  MIN = { validate = Type.isNumber, convert = Type.toNumber, hasNumberDataType = true },
  MAX = { validate = Type.isNumber, convert = Type.toNumber, hasNumberDataType = true },
  COUNT = { validate = Type.isInteger, convert = Type.toInteger, hasNumberDataType = true },
  SUM = { validate = Type.isNumber, convert = Type.toNumber, hasNumberDataType = true }
}


-- Metamethods

---
-- AggregateFunctionRule constructor.
-- This is the __call metamethod.
--
-- @tparam Select _parentSelectClause The parent Select Clause
-- @tparam string _targetName The target name
-- @tparam table|string _sqlFunction The sql function
-- @tparam mixed[] _additionalSqlFunctionArguments The additional sql function arguments (optional)
--
-- @treturn AggregateFunctionRule The AggregateFunctionRule instance
--
function AggregateFunctionRule:__construct(_parentSelectClause, _target, _sqlFunction, _additionalSqlFunctionArguments)

  local instance = SelectRule(_parentSelectClause, _target, _sqlFunction, _additionalSqlFunctionArguments)
  setmetatable(instance, {__index = AggregateFunctionRule})

  return instance

end


-- API

---
-- Selects the minimum value of a target.
--
-- @tparam Select _selectClause The Select clause to add the rule to
-- @tparam string _targetName The target name
--
function AggregateFunctionRule.min(_selectClause, _targetName)
  _selectClause:addNewRule(
    Type.toString(_targetName), AggregateFunctionRule.sqlFunctions.MIN, nil, AggregateFunctionRule
  )
end

---
-- Selects the maximum value of a targe.
--
-- @tparam Select _selectClause The Select clause to add the rule to
-- @tparam string _targetName The target name
--
function AggregateFunctionRule.max(_selectClause, _targetName)
  _selectClause:addNewRule(
    Type.toString(_targetName), AggregateFunctionRule.sqlFunctions.MAX, nil, AggregateFunctionRule
  )
end

---
-- Selects the number of columns in which the field for a specified target is set.
--
-- @tparam Select _selectClause The Select clause to add the rule to
-- @tparam string _targetName The target name
--
function AggregateFunctionRule.count(_selectClause, _targetName)
  _selectClause:addNewRule(
    Type.toString(_targetName), AggregateFunctionRule.sqlFunctions.COUNT, nil, AggregateFunctionRule
  )
end

---
-- Selects the sum of all values in a target column.
--
-- @tparam Select _selectClause The Select clause to add the rule to
-- @tparam string _targetName The target name
--
function AggregateFunctionRule.sum(_selectClause, _targetName)
  _selectClause:addNewRule(
    Type.toString(_targetName), AggregateFunctionRule.sqlFunctions.SUM, nil, AggregateFunctionRule
  )
end


setmetatable(
  AggregateFunctionRule,
  {
    -- AggregateFunctionRule inherits methods and attributes from SelectRule
    __index = SelectRule,

    -- When AggregateFunctionRule() is called, call the __construct() method
    __call = AggregateFunctionRule.__construct
  }
)


return AggregateFunctionRule
