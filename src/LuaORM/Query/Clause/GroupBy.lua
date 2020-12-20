---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ConditionClause = require("LuaORM/Query/ConditionClause")
local Condition = require("LuaORM/Query/Condition/Condition")
local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local TableColumn = require("LuaORM/Table/TableColumn")
local TableUtils = require("LuaORM/Util/TableUtils")
local Type = require("LuaORM/Util/Type/Type")

---
-- Represents a GROUP BY clause.
--
-- @type GroupBy
--
local GroupBy = {}


---
-- The list of targets to group the query result by
--
-- @tfield TableColumn[]|SelectRule[] targets
--
GroupBy.targets = nil

---
-- The HAVING condition
--
-- @tfield Condition condition
--
GroupBy.condition = nil


-- Metamethods

---
-- GroupBy constructor.
-- This is the __call metamethod.
--
-- @tparam Query _parentQuery The parent query
--
-- @treturn GroupBy The GroupBy instance
--
function GroupBy:__construct(_parentQuery)

  local instance = ConditionClause(_parentQuery, GroupBy)
  instance.targets = {}

  return instance

end


-- Getters and Setters

---
-- Returns the GroupBy targets.
--
-- @treturn TableColumn[]|SelectRule[] The GroupBy targets
--
function GroupBy:getTargets()
  return self.targets
end


-- API

---
-- Adds a list of targets to this GROUP BY clause.
--
-- @tparam string[] _targetNames The names of the targets to group the query results by
--
function GroupBy:groupBy(_targetNames)
  self:addTargets(Type.toTable(_targetNames))
end

---
-- Sets the condition of the GROUP BY clause.
--
-- @tparam mixed|nil _conditionSettings The list of condition settings (optional)
--
function GroupBy:having(_conditionSettings)
  self.condition = Condition(self)

  if (Type.isTable(_conditionSettings)) then
    self.condition:parseConditionSettings(_conditionSettings)
  end
end


-- Public Methods

---
-- Adds a list of targets to this GroupBy clause.
--
-- @tparam string[] _targetNames The target names
--
function GroupBy:addNewRule(_targetNames)
  self:groupBy(_targetNames)
  self.parentQuery:setCurrentClause(self)
end

---
-- Checks whether a method name is a dynamic function call for this Clause ("groupBy<columnName>").
--
-- @tparam string _methodName The method name to check
--
-- @treturn function|nil The generated function or nil if the method name is no dynamic function call for this Clause
--
function GroupBy:getDynamicFunctionByMethodName(_methodName)

  local groupByColumnName = _methodName:match("^groupBy(.+)$")
  if (groupByColumnName ~= nil) then

    groupByColumnName = self:convertDynamicFunctionTargetName(groupByColumnName)
    self:addTargets({ groupByColumnName })

    return function() end
  end

end

---
-- Returns all TableColumn's that are used by this Clause.
--
-- @treturn TableColumn[] The list of used TableColumn's
--
function GroupBy:getUsedTableColumns()

  local usedTableColumns = {}
  for _, target in ipairs(self.targets) do
    if (ObjectUtils.isInstanceOf(target, TableColumn)) then
      table.insert(usedTableColumns, target)
    end
  end

  if (self.condition ~= nil) then
    usedTableColumns = TableUtils.concatenateTables(usedTableColumns, self.condition:getUsedTableColumns())
  end

  return usedTableColumns

end

---
-- Returns whether this Clause is empty.
--
-- @treturn bool True if this Clause is empty, false otherwise
--
function GroupBy:isEmpty()
  return (#self.targets == 0 and self.condition == nil)
end

---
-- Returns whether the GROUP BY clause is valid.
--
-- @treturn bool True if the GROUP BY clause is valid, false otherwise
--
function GroupBy:isValid()

  if (self:isEmpty()) then
    return false
  else
    return (self.condition == nil or self.condition:isEmpty() or self.condition:isValid())
  end

end


-- Private Methods

---
-- Adds targets to group the query results by.
--
-- @tparam string[] _targetNames The target names
--
function GroupBy:addTargets(_targetNames)

  local targets = self.parentQuery:getTargetsByNames(_targetNames)
  for _, target in ipairs(targets) do
    table.insert(self.targets, target)
  end

end


setmetatable(
  GroupBy,
  {
    -- GroupBy inherits methods and attributes from ConditionClause
    __index = ConditionClause,

    -- When GroupBy() is called, call the __construct() method
    __call = GroupBy.__construct
  }
)


return GroupBy
