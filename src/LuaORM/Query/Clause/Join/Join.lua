---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Clause = require("LuaORM/Query/Clause")
local JoinRule = require("LuaORM/Query/Clause/Join/JoinRule")
local TableUtils = require("LuaORM/Util/TableUtils")

---
-- Represents the JOIN clauses for a Query.
--
-- @type Join
--
local Join = {}


---
-- Static list of Join types
--
-- @tfield int[] types
--
Join.types = {
  INNER = 1,
  LEFT = 2,
  RIGHT = 3,
  FULL = 4
}

---
-- The default join type id
--
-- @tfield int defaultType
--
Join.defaultType = Join.types.INNER

---
-- The list of join rules
--
-- @tfield JoinRule[] joinRules
--
Join.joinRules = {}

---
-- The current JoinRule
--
-- @tfield JoinRule currentJoinRule
--
Join.currentJoinRule = nil

---
-- The names of the attributes that will be searched for sub fields to return
--
-- @tfield string[] gettableAttributeNames
--
Join.gettableAttributeNames = { "currentJoinRule" }


-- Metamethods

---
-- Join constructor.
-- This is the __call metamethod.
--
-- @tparam Query _parentQuery The parent query
--
-- @treturn Join The Join instance
--
function Join:__construct(_parentQuery)

  local instance = Clause(_parentQuery, Join)
  instance.joinRules = {}

  return instance

end


-- Getters and Setters

---
-- Returns the list of join rules.
--
-- @tparam JoinRule[] The list of join rules
--
function Join:getJoinRules()
  return self.joinRules
end


-- Public Methods

---
-- Adds a new rule to this clause.
--
function Join:addNewRule(_tableName, _joinTypeName)

  self:addJoinRule()

  if (_tableName ~= nil) then
    self.currentJoinRule:table(_tableName)
  end

  if (_joinTypeName ~= nil) then
    self.currentJoinRule:changeJoinType(_joinTypeName)
  end

end

---
-- Checks whether a method name is a dynamic function call for this Join.
--
-- @tparam string _methodName The method name to check
--
-- @treturn function|nil The generated function or nil if the method name is no dynamic function call for this Clause
--
function Join:getDynamicFunctionByMethodName(_methodName)

  -- The pattern searches for <joinType?>Join<tableName?>
  local joinTypeName, joinTableName = _methodName:match("^(.*)[jJ]oin(.*)$")
  if (joinTypeName ~= nil or joinTableName ~= nil) then

    self:addJoinRule()

    -- Set join type
    if (joinTypeName ~= nil and #joinTypeName > 0) then
      self.currentJoinRule:changeJoinType(joinTypeName)
    end

    -- Set the target join table
    if (joinTableName ~= 0 and #joinTableName > 0) then
      joinTableName = self:convertDynamicFunctionTargetName(joinTableName)
      self.currentJoinRule:table(joinTableName)
    end

    return function() end

  end

end

---
-- Returns all TableColumn's that are used by this Clause.
--
-- @treturn TableColumn[] The list of used TableColumn's
--
function Join:getUsedTableColumns()

  local usedTableColumns = {}
  for _, joinRule in ipairs(self.joinRules) do
    table.insert(usedTableColumns, joinRule:getLeftTableColumn())
    table.insert(usedTableColumns, joinRule:getRightTableColumn())
  end

  return usedTableColumns

end

---
-- Returns whether this Clause is empty.
--
-- @treturn bool True if this Clause is empty, false otherwise
--
function Join:isEmpty()
  return (#self.joinRules == 0)
end

---
-- Returns whether all JoinRule's in this Join are valid.
--
-- @treturn bool True if all JoinRule's in this Join are valid, false otherwise
--
function Join:isValid()

  for _, joinRule in ipairs(self.joinRules) do
    if (not joinRule:isValid()) then
      return false
    end
  end

  return true

end

---
-- Returns the list of joined tables.
--
-- @treturn Table[] The list of joined tables
--
function Join:getJoinedTables()

  local joinedTables = {}
  for _, joinRule in ipairs(self.joinRules) do

    local rightTableColumn = joinRule:getRightTableColumn()
    if (rightTableColumn ~= nil) then
      table.insert(joinedTables, rightTableColumn:getParentTable())
    end

  end

  return joinedTables

end

---
-- Checks whether a target join Table is already included in one of the JoinRule's of this Join.
--
-- @tparam Table _joinTable The target join Table
--
-- @treturn bool True if the table is already joined with a JoinRule, false otherwise
--
function Join:isTableAlreadyJoined(_joinTable)
  return (TableUtils.tableHasValue(self:getJoinedTables(), _joinTable))
end

---
-- Returns the first foreign key column that references a table with a specified name.
--
-- @tparam string _tableName The name of the table
--
-- @treturn TableColumn|nil The TableColumn that references a table with the name or nil if no column was found
-- @treturn bool If true the returned column is the right join column, else it is the left join column
--
function Join:getForeignKeyColumnToTableByTableName(_tableName)

  for _, queryTable in ipairs(self.parentQuery:getUsedTables()) do
    for _, relatedTable in ipairs(queryTable:getRelatedTables()) do

      if (relatedTable:getName() == _tableName) then

        if (queryTable:hasForeignKeyToTable(relatedTable)) then
          return queryTable:getForeignKeyColumnToTable(relatedTable), false
        else
          return relatedTable:getForeignKeyColumnToTable(queryTable), true
        end

      end

    end
  end

end


-- Private Methods

---
-- Adds a JoinRule to this Join clause.
--
function Join:addJoinRule()

  local joinRule = JoinRule(self, self.defaultType)

  table.insert(self.joinRules, joinRule)
  self.currentJoinRule = joinRule

end


setmetatable(
  Join,
  {
    -- Join inherits methods and attributes from Clause
    __index = Clause,

    -- When Join() is called, call the __construct() method
    __call = Join.__construct
  }
)


return Join
