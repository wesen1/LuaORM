---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local FieldValueRowDataParser = require("LuaORM/FieldValueRowList/FieldValueRow/FieldValueRowDataParser")
local FieldValueRowQueryExecutor = require("LuaORM/FieldValueRowList/FieldValueRow/FieldValueRowQueryExecutor")
local SettableAttributeMembersClass = require("LuaORM/Util/Class/SettableAttributeMembersClass")
local API = LuaORM_API

---
-- Stores the values of a row of a specific table.
-- FieldValueRow's are used as containers for query result rows and for update, query and insert values.
--
-- @type FieldValueRow
--
local FieldValueRow = {}


---
-- The list of field values
--
-- @tfield FieldValue fieldValues
--
FieldValueRow.fieldValues = {}

---
-- The parent Table of this FieldValueRow
--
-- @tfield Table parentTable
--
FieldValueRow.parentTable = nil

---
-- The list of foreign key FieldValueRowList's
--
-- @tfield FieldValueRowList[] foreignKeyFieldValueRowLists
--
FieldValueRow.foreignKeyFieldValueRowLists = {}

---
-- The list of extra query result values that do not belong to any query table
-- This list is in the format { [queryResultColumnName] = { value, ... }, ... }
--
-- @tfield string[] extraValues
--
FieldValueRow.extraValues = {}

---
-- The data parser
--
-- @tfield FieldValueRowDataParser dataParser
--
FieldValueRow.dataParser = nil

---
-- The query executor
--
-- @tfield FieldValueRowQueryExecutor queryExecutor
--
FieldValueRow.queryExecutor = nil

---
-- The names of the attributes that will be searched for sub fields to return
--
-- @tfield string[] gettableAttributeNames
--
FieldValueRow.gettableAttributeNames = { "dataParser", "queryExecutor" }


-- Metamethods

---
-- FieldValueRow constructor.
-- This is the __call metamethod.
--
-- @tparam Table _parentTable The parent Table
-- @tparam FieldValueRowList[] _foreignKeyFieldValueRowLists The list of foreign key FieldValueRowList's (optional)
--
-- @treturn FieldValueRow The FieldValueRow instance
--
function FieldValueRow:__construct(_parentTable, _foreignKeyFieldValueRowLists)

  local instance = SettableAttributeMembersClass(FieldValueRow)

  instance.parentTable = _parentTable
  instance.dataParser = FieldValueRowDataParser(instance)
  instance.queryExecutor = FieldValueRowQueryExecutor(instance)
  instance.fieldValues = {}
  instance.extraValues = {}

  if (_foreignKeyFieldValueRowLists == nil) then
    instance.foreignKeyFieldValueRowLists = {}
  else
    instance.foreignKeyFieldValueRowLists = _foreignKeyFieldValueRowLists
  end

  instance:enableSettableBehaviour()

  return instance

end

---
-- Sets the value of a FieldValue which is addressed by its TableColumn's name.
-- This is the __newindex metamethod for instances.
--
-- @tparam string _columnName The column name
-- @tparam mixed _value The value
--
function FieldValueRow:setValueForUnknownAttributeMember(_columnName, _value)
  self:parseUpdate({ [_columnName] = _value})
end


-- Getters and Setters

---
-- Returns this FieldValueRow's parent Table.
--
-- @treturn Table The parent Table
--
function FieldValueRow:getParentTable()
  return self.parentTable
end

---
-- Returns the FieldValue's of this FieldValueRow.
--
-- @treturn FieldValue[] The FieldValue's of this FieldValueRow
--
function FieldValueRow:getFieldValues()
  return self.fieldValues
end

---
-- Sets the FieldValue's of this FieldValueRow.
--
-- @tparam FieldValue[] _fieldValues The list of FieldValue's
--
function FieldValueRow:setFieldValues(_fieldValues)
  self.fieldValues = _fieldValues
end

---
-- Sets the foreign key FieldValueRowList's of this FieldValueRow.
--
-- @tparam FieldValueRowList[] _foreignKeyFieldValueRowLists The foreign key FieldValueRowList's
--
function FieldValueRow:setForeignKeyFieldValueRowLists(_foreignKeyFieldValueRowLists)
  self.foreignKeyFieldValueRowLists = _foreignKeyFieldValueRowLists
end

---
-- Sets the extra values of this FieldValueRow.
--
-- @tparam mixed[][] _extraValues The list of extra values
--
function FieldValueRow:setExtraValues(_extraValues)
  self.extraValues = _extraValues
end


-- Public Methods

---
-- Replaces the contents of this FieldValueRow with the ones of another FieldValueRow.
--
-- @tparam FieldValueRow _fieldValueRow The other FieldValueRow
--
function FieldValueRow:copy(_fieldValueRow)

  self.parentTable = _fieldValueRow.parentTable
  self.fieldValues = _fieldValueRow.fieldValues
  self.foreignKeyFieldValueRowLists = _fieldValueRow.foreignKeyFieldValueRowLists
  self.extraValues = _fieldValueRow.extraValues

end

---
-- Returns whether this FieldValueRow matches the contents of a data row.
-- This is done by checking if the primary key values match.
--
-- @tparam string[] _dataRow The data row
-- @tparam bool _isQueryResult Defines whether the data row is a query result or user input
--
-- @treturn bool True if this FieldValueRow matches the data rows contents, false otherwise
--
function FieldValueRow:matches(_dataRow, _isQueryResult)

  local primaryKeyFieldValue = self:getPrimaryKeyFieldValue()

  -- Find and convert the data rows primary key value
  local primaryKeyColumn = primaryKeyFieldValue:getColumn()
  local primaryKeyColumnIndex = self.dataParser:getDataRowIndexByColumn(_dataRow, primaryKeyColumn, _isQueryResult)
  local rawDataRowPrimaryKeyValue = _dataRow[primaryKeyColumnIndex]
  local dataRowPrimaryKeyValue = primaryKeyColumn:getFieldType():convertValueToFieldType(rawDataRowPrimaryKeyValue)

  if (primaryKeyFieldValue:getLastQueryResultValue() == dataRowPrimaryKeyValue) then
    self.dataParser:markDataRowValuesAsParsed(_dataRow, _isQueryResult)
    return true
  else
    return false
  end

end

---
-- Returns all FieldValues of this FieldValueRow that are not empty.
--
-- @treturn FieldValue[] The list of FieldValue's that are not empty
--
function FieldValueRow:getNonEmptyFieldValues()

  local nonEmptyFieldValues = {}
  for _, fieldValue in pairs(self.fieldValues) do
    if (not fieldValue:isEmpty()) then
      table.insert(nonEmptyFieldValues, fieldValue)
    end
  end

  return nonEmptyFieldValues

end

---
-- Returns the primary key FieldValue.
--
-- @treturn FieldValue The primary key FieldValue
--
function FieldValueRow:getPrimaryKeyFieldValue()
  local primaryKeyColumn = self.parentTable:getPrimaryKeyColumn()
  return self:getFieldValueByColumn(primaryKeyColumn)
end

---
-- Returns a FieldValue by its TableColumn.
--
-- @tparam TableColumn _column The column
--
-- @treturn FieldValue|nil The FieldValue for the TableColumn or nil if no FieldValue for the TableColumn exists
--
function FieldValueRow:getFieldValueByColumn(_column)

  for _, fieldValue in ipairs(self.fieldValues) do
    if (fieldValue:getColumn() == _column) then
      return fieldValue
    end
  end

end


-- Protected Methods

---
-- Returns the value for table indexes that were not found in the parent class and the gettable attributes.
--
-- @tparam mixed _indexName The index name
--
-- @treturn mixed The return value for the index name
--
function FieldValueRow:getValueForUnknownIndex(_indexName)

  -- Check the parent table
  local column = self.parentTable:getColumnByName(_indexName)
  if (column ~= nil) then
    local fieldValue = self:getFieldValueByColumn(column)
    if (fieldValue) then
      return fieldValue:getCurrentValue()
    end

  else

    -- Check the foreign key FieldValueRowLists
    for foreignTable, fieldValueRowList in pairs(self.foreignKeyFieldValueRowLists) do
      if (foreignTable:getName() == _indexName) then
        return fieldValueRowList
      end
    end

    -- Check the extra values
    if (self.extraValues[_indexName] == nil) then
      API.ORM:getLogger():warn("Could not find value for column '" .. _indexName .. "'")
    else
      return self.extraValues[_indexName]
    end

  end

end


setmetatable(
  FieldValueRow,
  {
    -- FieldValueRow inherits from SettableAttributeMembersClass
    __index = SettableAttributeMembersClass,

    -- When FieldValueRow() is called, call the __construct() method
    __call = FieldValueRow.__construct
  }
)


return FieldValueRow
