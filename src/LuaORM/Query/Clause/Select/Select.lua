---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local AggregateFunctionRule = require("LuaORM/Query/Clause/Select/AggregateFunctionRule")
local Clause = require("LuaORM/Query/Clause")
local SelectRule = require("LuaORM/Query/Clause/Select/SelectRule")
local API = LuaORM_API

---
-- Provides methods to select additional columns.
--
-- @type Select
--
local Select = {}


---
-- The list of SelectRule classes
--
-- @tfield class[] ruleTypes
--
Select.ruleTypes = { AggregateFunctionRule }

---
-- The list of select rules
--
-- @tfield SelectRule[] rules
--
Select.rules = nil


-- Metamethods

---
-- Select constructor.
-- This is the __call metamethod.
--
-- @tparam Query _parentQuery The parent query
--
-- @treturn Select The Select instance
--
function Select:__construct(_parentQuery)

  local instance = Clause(_parentQuery, Select)
  instance.rules = {}

  return instance

end


-- Getters and Setters

---
-- Returns the SelectRules's of this Select clause.
--
-- @treturn SelectRule[] The SelectRule's of this Select clause
--
function Select:getRules()
  return self.rules
end


-- Public Methods

---
-- Adds a new SelectRule to this Select clause.
--
-- @tparam string _targetName The target name
-- @tparam table|string _sqlFunction The aggregate function
-- @tparam mixed[] _additionalSqlFunctionArguments The additional sql function arguments (optional)
-- @tparam SelectRule The SelectRule class to use to build the SelectRule (optional)
--
function Select:addNewRule(_targetName, _sqlFunction, _additionalSqlFunctionArguments, _selectRuleClass)

  if (_targetName ~= nil and _sqlFunction ~= nil) then
    self:parseRule(_targetName, _sqlFunction, _additionalSqlFunctionArguments, _selectRuleClass)
  end

  self.parentQuery:setCurrentClause(self)

end

---
-- Returns whether this Clause is empty.
--
-- @treturn bool True if this Clause is empty, false otherwise
--
function Select:isEmpty()
  return (#self.rules == 0)
end

---
-- Returns whether this Clause is valid.
--
-- @treturn bool True if this Clause is valid, false otherwise
--
function Select:isValid()

  for _, rule in ipairs(self.rules) do
    if (not rule:isValid()) then
      return false
    end
  end

  return true

end

---
-- Returns a SelectRule by it's select alias.
--
-- @tparam string _selectAlias The select alias of the SelectRule
--
-- @treturn SelectRule|nil The SelectRule or nil if no SelectRule with that select alias exists
--
function Select:getSelectRuleBySelectAlias(_selectAlias)

  for _, selectRule in ipairs(self.rules) do
    if (selectRule:getSelectAlias() == _selectAlias) then
      return selectRule
    end
  end

end


-- Private Methods

---
-- Adds a new SelectRule to this Select clause.
--
-- @tparam string _targetName The target name
-- @tparam table|string _sqlFunction The sql function
-- @tparam mixed[] _additionalSqlFunctionArguments The additional sql function arguments (optional)
-- @tparam SelectRule The SelectRule class to use to build the SelectRule (optional)
--
function Select:parseRule(_targetName, _sqlFunction, _additionalSqlFunctionArguments, _selectRuleClass)

  local target = self.parentQuery:getTargetByName(_targetName)
  if (target == nil) then
    API.ORM:getLogger():warn("Cannot add select rule: Could not find target '" .. _targetName .. "'")
  else

    if (self:hasSelectRule(target, _sqlFunction)) then
      API.ORM:getLogger():warn("Cannot add select rule: Rule already exists in query")
    else

      local selectRuleClass = _selectRuleClass
      if (selectRuleClass == nil) then
        selectRuleClass = SelectRule
      end

      local selectRule = selectRuleClass(self, target, _sqlFunction, _additionalSqlFunctionArguments)
      table.insert(self.rules, selectRule)
    end

  end

end

---
-- Returns whether this Select clause already contains a specific SelectRule.
--
-- @tparam TableColumn|SelectRule _target The select rule target
-- @tparam int _aggregateFunctionId THe id of the aggregate function
--
-- @treturn bool True if this Select clause already contains the SelectRule, false otherwise
--
function Select:hasSelectRule(_target, _aggregateFunctionId)

  for _, selectRule in ipairs(self.rules) do
    if (selectRule:getTarget() == _target and selectRule:getAggregateFunction() == _aggregateFunctionId) then
      return true
    end
  end

  return false

end

---
-- Returns whether a TableColumn's name is unique in the parent query.
--
-- @tparam string _columnName The column name
--
-- @treturn bool True if the TableColumn's name is unique in the parent query, false otherwise
--
function Select:isColumnNameUnique(_columnName)

  local columnNameOccurredOnce = false
  for _, usedTable in ipairs(self:getParentQuery():getUsedTables()) do
    for _, column in ipairs(usedTable:getColumns()) do

      if (column:getName() == _columnName) then

        if (columnNameOccurredOnce) then
          return false
        else
          columnNameOccurredOnce = true
        end

      end
    end
  end

  return true

end


-- Protected Methods

---
-- Returns the function for an unknown sub method.
--
-- @tparam string _methodName The method name
--
-- @treturn function|mixed The function to execute or a value to return
-- @treturn object The object that will be passed as "self" to the function
--
function Select:getValueForUnknownIndex(_methodName)

  for _, ruleType in ipairs(self.ruleTypes) do
    if (ruleType:providesApiMethod(_methodName)) then
      return ruleType[_methodName], self
    end
  end

end


setmetatable(
  Select,
  {
    -- Select inherits methods and attributes from Clause
    __index = Clause,

    -- When Select() is called, call the __construct() method
    __call = Select.__construct
  }
)


return Select
