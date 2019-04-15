---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Type = require("LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- Represents a JOIN rule of a Join clause.
--
-- @type JoinRule
--
local JoinRule = {}


---
-- The parent Join clause
--
-- @tfield Join parentJoin
--
JoinRule.parentJoin = nil

---
-- The join type id
--
-- @tfield int joinType
--
JoinRule.joinType = nil

---
-- The left table column
--
-- @tfield TableColumn leftTableColumn
--
JoinRule.leftTableColumn = nil

---
-- The right table column
--
-- @tfield TableColumn rightTableColumn
--
JoinRule.rightTableColumn = nil


-- Metamethods

---
-- JoinRule constructor.
-- This is the __call metamethod.
--
-- @tparam Join _parentJoin The parent join
-- @tparam int _joinTypeId The join type id
--
-- @treturn JoinRule The JoinRule instance
--
function JoinRule:__construct(_parentJoin, _joinTypeId)

  local instance = setmetatable({}, {__index = JoinRule})

  instance.parentJoin = _parentJoin
  instance.joinType = _joinTypeId

  return instance

end


-- Getters and Setters

---
-- Returns the join type id.
--
-- @treturn int The join type id
--
function JoinRule:getJoinType()
  return self.joinType
end

---
-- Returns the left table column.
--
-- @treturn TableColumn The left table column
--
function JoinRule:getLeftTableColumn()
  return self.leftTableColumn
end

---
-- Returns the right table column.
--
-- @treturn TableColumn The right table column
--
function JoinRule:getRightTableColumn()
  return self.rightTableColumn
end


-- API

---
-- Sets the JoinRule's table.
-- Also sets the default values for the left and right table column.
--
-- @tparam string _tableName The table name
--
function JoinRule:table(_tableName)

  local tableName = Type.toString(_tableName)
  local foreignKeyColumn, isRightTableColumn = self.parentJoin:getForeignKeyColumnToTableByTableName(tableName)
  if (foreignKeyColumn == nil) then
    API.ORM:getLogger():warn("Cannot join '" .. tableName .. "': No foreign key found that references that table")

  else

    local leftTableColumn
    local rightTableColumn
    local joinTable = foreignKeyColumn:getSettings()["isForeignKeyTo"]

    if (isRightTableColumn) then
      leftTableColumn = joinTable:getPrimaryKeyColumn()
      rightTableColumn = foreignKeyColumn
    else
      leftTableColumn = foreignKeyColumn
      rightTableColumn = joinTable:getPrimaryKeyColumn()
    end

    -- Check if the target table is already joined
    if (self.parentJoin:isTableAlreadyJoined(rightTableColumn:getParentTable())) then
      API.ORM:getLogger():warn("Cannot join '" .. tableName .. "': Table was already joined in another join rule")
    else
      self.leftTableColumn = leftTableColumn
      self.rightTableColumn = rightTableColumn
    end

  end

end

---
-- Changes the left and right table columns.
--
-- @tparam string _leftColumnName The name of the left TableColumn
-- @tparam string _rightColumnName The name of the right TableColumn
--
function JoinRule:on(_leftColumnName, _rightColumnName)
  self:changeLeftTableColumn(Type.toString(_leftColumnName))
  self:changeRightTableColumn(Type.toString(_rightColumnName))
end


-- Public Methods

---
-- Changes the JoinRule's join type.
--
-- @tparam string _joinTypeName The join type name
--
function JoinRule:changeJoinType(_joinTypeName)

  local joinTypeId = self.parentJoin.types[string.upper(_joinTypeName)]
  if (joinTypeId == nil) then
    API.ORM:getLogger():warn("Cannot change Join type: Invalid join type '" .. Type.toString(_joinTypeName) .. "'")
  else
    self.joinType = joinTypeId
  end

end

---
-- Returns whether this JoinRule is valid.
--
-- @treturn bool True if this JoinRule is valid, false otherwise
--
function JoinRule:isValid()
  return (self.joinType ~= nil and self.leftTableColumn ~= nil and self.rightTableColumn ~= nil)
end


-- Private Methods

---
-- Changes the left table column of this JoinRule.
--
-- @tparam string _leftTableColumnName The name of the new left table column
--
function JoinRule:changeLeftTableColumn(_leftTableColumnName)

  local leftTableColumnError
  if (self.rightTableColumn == nil) then
    leftTableColumnError = "Join target table not set"

  else

    local leftTableColumn = self.parentJoin:getParentQuery():getColumnByName(_leftTableColumnName)
    if (leftTableColumn == nil) then
      leftTableColumnError = "Column not found"

    else
      if (leftTableColumn:getSettings()["isForeignKeyTo"] ~= self.rightTableColumn:getParentTable()) then
        leftTableColumnError = "Column does not reference Join's target table"
      else
        self.leftTableColumn = leftTableColumn
      end
    end

  end

  if (leftTableColumnError) then
    API.ORM:getLogger():warn("Cannot change Join's left column to '" .. _leftTableColumnName .. "': " .. leftTableColumnError)
  end

end

---
-- Changes the right table column of this JoinRule.
--
-- @tparam string _rightTableColumnName The name of the new right table column
--
function JoinRule:changeRightTableColumn(_rightTableColumnName)

  local rightTableColumnError
  if (self.rightTableColumn == nil) then
    rightTableColumnError = "Join target table not set"

  else

    local rightTableColumn = self.rightTableColumn:getParentTable():getColumnByName(_rightTableColumnName)
    if (rightTableColumn == nil) then
      rightTableColumn = self.rightTableColumn:getParentTable():getColumnBySelectAlias(_rightTableColumnName)
    end

    if (rightTableColumn == nil) then
      rightTableColumnError = "Column not found in JOIN's target table"
    else
      self.rightTableColumn = rightTableColumn
    end

  end

  if (rightTableColumnError) then
    API.ORM:getLogger():warn("Cannot change Join's right column to '" .. _rightTableColumnName .. "': " .. rightTableColumnError)
  end

end


-- When JoinRule() is called, call the __construct() method
setmetatable(JoinRule, {__call = JoinRule.__construct})


return JoinRule
