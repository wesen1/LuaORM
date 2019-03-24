---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local FieldValueRowQueryBuilder = require("LuaORM/FieldValueRowList/FieldValueRow/FieldValueRowQueryBuilder")
local Type = require("LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- Executes queries for a FieldValueRow.
--
-- @type FieldValueRowQueryExecutor
--
local FieldValueRowQueryExecutor = {}


---
-- The parent FieldValueRow
--
-- @tfield FieldValueRow fieldValueRow
--
FieldValueRowQueryExecutor.parentFieldValueRow = nil

---
-- The query builder
--
-- @tfield FieldValueRowQueryBuilder queryBuilder
--
FieldValueRowQueryExecutor.queryBuilder = nil


-- Metamethods

---
-- FieldValueRowQueryExecutor constructor.
-- This is the __call metamethod.
--
-- @tparam FieldValueRow _parentFieldValueRow The parent FieldValueRow
--
-- @treturn FieldValueRowQueryExecutor The FieldValueRowQueryExecutor instance
--
function FieldValueRowQueryExecutor:__construct(_parentFieldValueRow)

  local instance = setmetatable({}, {__index = FieldValueRowQueryExecutor})
  instance.parentFieldValueRow = _parentFieldValueRow
  instance.queryBuilder = FieldValueRowQueryBuilder(_parentFieldValueRow)

  return instance

end


-- API

---
-- Saves the contents of the parent FieldValueRow to the database.
--
-- @treturn bool|nil False if there was an error while saving the FieldValueRow, nil otherwise
--
function FieldValueRowQueryExecutor:save()

  if (self:isPrimaryKeySet(true)) then
    return self:update()

  else
    if (self:areNecessaryFieldValuesSet()) then

      -- Check whether there is an existing FieldValueRow with the same values
      local existingDataFieldValueRow = self.queryBuilder:getSelectQuery():findOne()
      if (existingDataFieldValueRow ~= nil and existingDataFieldValueRow ~= false) then
        self.parentFieldValueRow:copy(existingDataFieldValueRow)
      else

        -- Check the unique constraints
        if (#self.parentFieldValueRow:getParentTable():getUniqueColumns() > 0) then

          local uniqueColumnMatches = self.queryBuilder:selectRowByUniqueColumns():findOne()
          if (uniqueColumnMatches ~= nil and uniqueColumnMatches ~= false) then
            API.ORM:getLogger():warn("Cannot save FieldValueRow: A 'Unique' constraint failed")
            return false
          end

        end

        return self:insert()

      end

    else
      API.ORM:getLogger():warn("Cannot save FieldValueRow: Not all necessary columns are set")
      return false
    end
  end

end

---
-- Deletes the row with the parent FieldValueRows primary key value from the database.
--
-- @treturn bool|nil False if there was an error while deleting the FieldValueRow, nil otherwise
--
function FieldValueRowQueryExecutor:delete()

  if (not self:isPrimaryKeySet(true)) then
    API.ORM:getLogger():warn("Could not delete FieldValueRow: Primary Key field is not set")
    return false
  end

  local result = self.queryBuilder:getDeleteQuery():delete()

  if (result == false) then
    return false
  else
    self.parentFieldValueRow:getPrimaryKeyFieldValue():unset()
  end

end


-- Private Methods

---
-- Inserts the parent FieldValueRow into the database.
--
-- @treturn bool|nil False if there was an error while inserting the FieldValueRow, nil otherwise
--
function FieldValueRowQueryExecutor:insert()

  local result = self.queryBuilder:getInsertQuery():insert()

  if (result == false) then
    return false
  else

    -- Update the primary key id
    local primaryKeyFieldValue = self.parentFieldValueRow:getPrimaryKeyFieldValue()

    local primaryKeyValue = API.ORM:getDatabaseConnection():getLastInsertId()
    if (primaryKeyValue == nil) then
      primaryKeyValue = self.queryBuilder:getSelectQuery():findOne()[primaryKeyFieldValue:getColumn():getName()]
    end

    primaryKeyFieldValue:updateLastQueryResultValue(primaryKeyValue)

  end

end

---
-- Updates the FieldValueRow with a data row and executes a query to write the updates to the database.
--
-- @tparam mixed[] _dataRow The data row (optional)
--
-- @treturn bool|nil False if there was an error while updating the FieldValueRow, nil otherwise
--
function FieldValueRowQueryExecutor:update(_dataRow)

  self.parentFieldValueRow:parseUpdate(Type.toTable(_dataRow), false)

  -- Check whether the FieldValue's of the parent FieldValueRow changed
  local updatedFieldValues = {}
  for _, fieldValue in ipairs(self.parentFieldValueRow:getFieldValues()) do
    if (fieldValue:hasValueChanged()) then
      table.insert(updatedFieldValues, fieldValue)
    end
  end

  if (#updatedFieldValues > 0) then
    local result = self.queryBuilder:getUpdateQuery():update()

    if (result == false) then
      return false
    else
      for _, updatedFieldValue in ipairs(updatedFieldValues) do
        updatedFieldValue:update()
      end
    end

  end

end


-- Private Methods

---
-- Returns whether the primary key value is set in the parent FieldValueRow.
--
-- @tparam bool _usesLastQueryResult Defines whether the last query result or the current value will be used
--
-- @treturn bool True if the primary key value is set in the parent FieldValueRow, false otherwise
--
function FieldValueRowQueryExecutor:isPrimaryKeySet(_usesLastQueryResult)

  local primaryKeyFieldValue = self:getPrimaryKeyFieldValue()
  if (primaryKeyFieldValue == nil) then
    return false

  else
    if (_usesLastQueryResult) then
      return (primaryKeyFieldValue:getLastQueryResultValue() ~= nil)
    else
      return (primaryKeyFieldValue:getCurrentValue() ~= nil)
    end
  end

end

---
-- Checks whether all necessary FieldValue's except for the primary key of the parent FieldValueRow are set.
--
-- @treturn bool True if all necessary FieldValue's are set, false otherwise
--
function FieldValueRowQueryExecutor:areNecessaryFieldValuesSet()

  for i, column in ipairs(self.parentFieldValueRow:getParentTable():getColumns()) do
    if (column:getSettings()["isPrimaryKey"] == false and column:getSettings()["mustBeSet"] == true) then

      local fieldValue = self.parentFieldValueRow:getFieldValues()[i]
      if (fieldValue == nil or fieldValue:getCurrentValue() == nil) then
        return false
      end

    end
  end

  return true

end


-- When FieldValueRowQueryExecutor() is called, call the __construct() method
setmetatable(FieldValueRowQueryExecutor, {__call = FieldValueRowQueryExecutor.__construct})


return FieldValueRowQueryExecutor
