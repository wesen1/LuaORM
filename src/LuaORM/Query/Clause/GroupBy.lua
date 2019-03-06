---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ConditionClause = require("LuaORM/Query/ConditionClause")
local Condition = require("LuaORM/Query/Condition/Condition")
local Type = require("LuaORM/Util/Type/Type")

---
-- Represents a GROUP BY clause.
--
-- @type GroupBy
--
local GroupBy = {}


---
-- The list of columns to group the result by
--
-- @tfield TableColumn[] columns
--
GroupBy.columns = {}


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
  instance.columns = {}

  return instance

end


-- Getters and Setters

---
-- Returns the GroupBy columns.
--
-- @treturn TableColumn[] The GroupBy columns
--
function GroupBy:getColumns()
  return self.columns
end


-- API

---
-- Adds a list of columns to this GROUP BY clause.
--
-- @tparam string[] _columnNames The names of the columns to group by
--
function GroupBy:groupBy(_columnNames)
  self:addColumns(Type.toTable(_columnNames))
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
-- Adds a list of columns to this GroupBy clause.
--
-- @tparam string[] _columnNames The list of column names
--
function GroupBy:addNewRule(_columnNames)
  self:groupBy(_columnNames)
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
    self:addColumns({ groupByColumnName })

    return function() end
  end

end

---
-- Returns whether this Clause is empty.
--
-- @treturn bool True if this Clause is empty, false otherwise
--
function GroupBy:isEmpty()
  return (#self.columns == 0 and self.condition == nil)
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
-- Adds columns to this GroupBy's columns.
--
-- @tparam string[] _columnNames The column names
--
function GroupBy:addColumns(_columnNames)

  local columns = self.parentQuery:getColumnsByNames(_columnNames)
  for _, column in ipairs(columns) do
    table.insert(self.columns, column)
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
