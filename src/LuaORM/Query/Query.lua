---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ChainableSubMethodsClass = require("LuaORM/Util/Class/ChainableSubMethodsClass")
local GroupBy = require("LuaORM/Query/Clause/GroupBy")
local Join = require("LuaORM/Query/Clause/Join/Join")
local Limit = require("LuaORM/Query/Clause/Limit")
local OrderBy = require("LuaORM/Query/Clause/OrderBy/OrderBy")
local Select = require("LuaORM/Query/Clause/Select/Select")
local TableUtils = require("LuaORM/Util/TableUtils")
local Type = require("LuaORM/Util/Type/Type")
local Where = require("LuaORM/Query/Clause/Where")
local API = LuaORM_API

---
-- Represents the contents of a query (database language independent).
-- Query's are used to create the database queries for Models and for FieldValueRow(List)'s.
--
-- @type Query
--
local Query = {}


---
-- Static list of query types
--
-- @tfield int[] types
--
Query.types = {
  CREATE = 1,
  SELECT = 2,
  INSERT = 3,
  UPDATE = 4,
  DELETE = 5
}

---
-- The query type id of this Query
--
-- @tfield int type
--
Query.type = nil

---
-- List of clauses
--
-- @type Clause[] clauses
--
Query.clauses = {

  ---
  -- The SELECT rule(s)
  --
  -- @tfield Select select
  --
  ["select"] = nil,

  ---
  -- The JOIN clause(s)
  --
  -- @tfield Join join
  --
  ["join"] = nil,

  ---
  -- The WHERE clause
  --
  -- @tfield Where where
  --
  ["where"] = nil,

  ---
  -- The GROUP BY clause
  --
  -- @tfield GroupBy groupBy
  --
  ["groupBy"] = nil,

  ---
  -- The ORDER BY clause
  --
  -- @tfield OrderBy orderBy
  --
  ["orderBy"] = nil,

  ---
  -- The LIMIT clause
  --
  -- @tfield Limit limit
  --
  ["limit"] = nil
}

---
-- The current clause
-- This is used to detmerine available function calls
--
-- @tfield Clause currentClause
--
Query.currentClause = nil

---
-- The target Table of the query
-- This is the table of the model class or FieldValueRow that created the query
--
-- @tfield Table targetTable
--
Query.targetTable = nil

---
-- The FieldValueRow whose FieldValue's will be used for UPDATE and INSERT queries
--
-- @tfield FieldValueRow fieldValueRow
--
Query.fieldValueRow = nil

---
-- The names of the attributes that will be searched for sub fields to return
--
-- @tfield string[] gettableAttributeNames
--
Query.gettableAttributeNames = { "currentClause" }


-- Metamethods

---
-- Query constructor.
-- This is the __call metamethod.
--
-- @tparam Table _targetTable The target Table
-- @tparam FieldValueRow _fieldValueRow The initial FieldValueRow for INSERT and UPDATE queries
--
-- @treturn Query The Query instance
--
function Query:__construct(_targetTable, _fieldValueRow)

  local instance = ChainableSubMethodsClass(Query)

  instance.targetTable = _targetTable
  instance.fieldValueRow = _fieldValueRow

  instance:initializeClauses()

  return instance

end


-- Getters and Setters

---
-- Returns the query type.
--
-- @treturn int The query type
--
function Query:getType()
  return self.type
end

---
-- Returns the target Table.
--
-- @treturn Table The target Table
--
function Query:getTargetTable()
  return self.targetTable
end

---
-- Returns the query clauses.
--
-- @treturn Clause[] The query clauses
--
function Query:getClauses()
  return self.clauses
end

---
-- Returns the FieldValueRow for INSERT and UPDATE queries.
--
-- @treturn FieldValueRow The FieldValueRow for INSERT and UPDATE queries
--
function Query:getFieldValueRow()
  return self.fieldValueRow
end

---
-- Sets the current Clause of this Query.
--
-- @tparam Clause _clause The new current Clause of this Query
--
function Query:setCurrentClause(_clause)
  self.currentClause = _clause
end


-- API

-- Finish the Query

---
-- Executes this Query as a "CREATE" query for the target Table.
--
function Query:create()
  self.type = self.types.CREATE
  self:execute()
end

---
-- Executes this Query as a "SELECT" query.
--
-- @treturn FieldValueRowList The resulting FieldValueRowList
--
function Query:find()
  self.type = self.types.SELECT
  return self:execute()
end

---
-- Executes this Query as a "SELECT" query and returns the first result row.
--
-- @treturn FieldValueRow|nil The first result row or nil if there are no result rows
--
function Query:findOne()
  local result = self:limit(1):find()
  if (result ~= false and result:count() > 0) then
    return result[1]
  end
end

---
-- Executes this Query as a "INSERT" query.
--
-- @tparam string[] _dataRow The data row in the format { [columnName] = value, ... }
--
function Query:insert(_dataRow)

  self.type = self.types.INSERT
  self.fieldValueRow:parseUpdate(Type.toTable(_dataRow), false)

  self:execute()

end

---
-- Sets the Query type of this query to "UPDATE".
--
-- @tparam string[] _dataRow The data row in the format { [columnName] = value, ... }
--
-- @treturn FieldValueRowList|nil The FieldValueRowList or nil if there is no result
--
function Query:update(_dataRow)

  self.type = Query.types.UPDATE
  self.fieldValueRow:parseUpdate(Type.toTable(_dataRow), false)

  return self:execute()

end

---
-- Executes this Query as a "DELETE" query.
--
function Query:delete()
  self.type = self.types.DELETE
  self:execute()
end


-- Public Methods

---
-- Returns whether all clauses of this Query are valid.
--
-- @treturn bool True if all clauses are valid, false otherwise
--
function Query:isValid()

  for clauseName, clause in pairs(self.clauses) do
    if (not clause:isEmpty() and not clause:isValid()) then
      API.ORM:getLogger():error("Cannot execute query: '" .. clauseName .. "' clause is invalid")
      return false
    end
  end

  return true

end

---
-- Returns a list of all tables that are used in this query.
--
-- @treturn Table[] The list of all tables that are used in this query
--
function Query:getUsedTables()
  return TableUtils.concatenateTables({ self.targetTable }, self.clauses.join:getJoinedTables())
end

---
-- Returns a column by name from the tables that are currently used in this query.
--
-- @tparam string _columnName The column name
--
-- @treturn TableColumn|nil The table column or nil if no table column with that name exists in this Query
--
function Query:getColumnByName(_columnName)

  for _, usedTable in ipairs(self:getUsedTables()) do

    local usedTableColumn = usedTable:getColumnByName(_columnName)
    if (usedTableColumn == nil) then
      usedTableColumn = usedTable:getColumnBySelectAlias(_columnName)
    end

    if (usedTableColumn ~= nil) then
      return usedTableColumn
    end

  end

end

---
-- Returns a TableColumn or SelectRule of this Query.
--
-- @tparam string _targetName The target name
--
-- @treturn TableColumn|SelectRule|nil The target or nil if no target with that name exists in this Query
--
function Query:getTargetByName(_targetName)

  local column = self:getColumnByName(_targetName)
  if (column == nil) then
    return self.clauses.select:getSelectRuleBySelectAlias(_targetName)
  else
    return column
  end

end

---
-- Returns a list of targets from a list of target names.
--
-- @tparam string[] _targetNames The list of target names
--
-- @treturn TableColumn|SelectRule[] The list of targets
--
function Query:getTargetsByNames(_targetNames)

  local targets = {}
  for _, targetName in ipairs(_targetNames) do

    local target = self:getTargetByName(targetName)
    if (target == nil) then
      API.ORM:getLogger():warn("Could not find target '" .. targetName .. "' in this Query")
    else
      table.insert(targets, target)
    end

  end

  return targets

end


-- Private Methods

---
-- Initializes the clauses of this Query.
--
function Query:initializeClauses()

  self.clauses = {
    ["select"] = Select(self),
    ["join"] = Join(self),
    ["where"] = Where(self),
    ["groupBy"] = GroupBy(self),
    ["orderBy"] = OrderBy(self),
    ["limit"] = Limit(self)
  }

end

---
-- Executes this Query and returns the result.
--
-- @treturn FieldValueRowList|bool|nil The FieldValueRowList or false if there was an error or nil if this Query is no "SELECT" query
--
function Query:execute()
  return API.ORM:getQueryExecutor():execute(self)
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
function Query:getValueForUnknownIndex(_methodName)

  -- Check whether the method name matches a Clause name
  for clauseName, clause in pairs(self.clauses) do
    if (clauseName == _methodName) then
      self.currentClause = clause
      return clause.addNewRule, clause
    end
  end

  -- Check whether one of the clauses provides a method with the target method name
  for _, clause in pairs(self.clauses) do

    local childFunction = clause:getDynamicFunctionByMethodName(_methodName)
    if (childFunction ~= nil) then
      self.currentClause = clause
      return childFunction, clause
    end

  end

end


setmetatable(
  Query,
  {
    -- Query inherits methods and attributes from ChainableSubMethodsClass
    __index = ChainableSubMethodsClass,

    -- When Query() is called, call the __construct() method
    __call = Query.__construct
  }
)


return Query
