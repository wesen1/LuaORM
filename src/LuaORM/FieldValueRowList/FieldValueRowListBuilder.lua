---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local FieldValueRow = require("LuaORM/FieldValueRowList/FieldValueRow/FieldValueRow")
local FieldValueRowList = require("LuaORM/FieldValueRowList/FieldValueRowList")
local TableUtils = require("LuaORM/Util/TableUtils")

---
-- Handles generating of FieldValueRowList's from query results.
-- The query results must be in the format { { [columnName] = value }, ... }.
--
-- @type FieldValueRowListBuilder
--
local FieldValueRowListBuilder = {}


-- Metamethods

---
-- FieldValueRowListBuilder constructor.
-- This is the __call metamethod.
--
-- @treturn FieldValueRowListBuilder The FieldValueRowListBuilder instance
--
function FieldValueRowListBuilder:__construct()
  local instance = setmetatable({}, {__index = FieldValueRowListBuilder})
  return instance
end


-- Public Methods

---
-- Converts a list of data rows to FieldValueRow's and returns the result as a FieldValueRowList.
--
-- @tparam string[][] _dataRows The data rows
-- @tparam Table _targetTable The Table whose FieldValueRowList shall be returned
-- @tparam Table[] _queryTables All tables that were used in the query to retrieve the data rows
--
-- @treturn FieldValueRowList The FieldValueRowList for the target table
--
function FieldValueRowListBuilder:parseQueryResult(_dataRows, _targetTable, _queryTables)

  local targetTableFieldValueRowList = FieldValueRowList()
  local includedRelatedTables = self:getIncludedRelatedTables(_queryTables)

  local currentFieldValueRows = {}
  local currentSubTableFieldValueRowLists = {}
  local dataRowsForTargetTableFieldValueRow = {}

  local remainingDataWasParsed
  for dataRowNumber, dataRow in ipairs(_dataRows) do

    remainingDataWasParsed = false
    for _, queryTable in ipairs(_queryTables) do

      if (currentFieldValueRows[queryTable] == nil or not currentFieldValueRows[queryTable]:matches(dataRow, true)) then

        -- Complete the current field value row for the query table
        if (currentFieldValueRows[queryTable] ~= nil) then

          -- Parse the remaining data
          if (queryTable == _targetTable) then
            currentFieldValueRows[_targetTable]:parseRemainingData(dataRowsForTargetTableFieldValueRow)
            dataRowsForTargetTableFieldValueRow = {}
            remainingDataWasParsed = true
          end

          -- Fill empty sub FieldValueRowList's with the current FieldValueRow for the list's target Table
          self:addFieldValueRowsToEmptyLists(currentSubTableFieldValueRowLists[queryTable], currentFieldValueRows)

        end


        -- Create a new FieldValueRow for the query Table
        local fieldValueRow = FieldValueRow(queryTable)
        fieldValueRow:parse(dataRow, true)

        -- Add the new FieldValueRow to all sub FieldValueRowList's whose main table is the current query table
        for _, subTableFieldValueRowLists in pairs(currentSubTableFieldValueRowLists) do
          if (subTableFieldValueRowLists[queryTable] ~= nil) then
            subTableFieldValueRowLists[queryTable]:addFieldValueRow(fieldValueRow)
          end
        end

        -- Add the FieldValueRow to the target Table's FieldValueRowList if necessary
        if (queryTable == _targetTable) then
          targetTableFieldValueRowList:addFieldValueRow(fieldValueRow)
        end

        -- Create a new set of sub FieldValueRowList's for the new FieldValueRow
        currentSubTableFieldValueRowLists[queryTable] = self:generateEmptySubFieldValueRowLists(includedRelatedTables[queryTable])
        fieldValueRow:setForeignKeyFieldValueRowLists(currentSubTableFieldValueRowLists[queryTable])

        currentFieldValueRows[queryTable] = fieldValueRow

      end

    end

    table.insert(dataRowsForTargetTableFieldValueRow, dataRow)

  end

  if (remainingDataWasParsed == false) then
    currentFieldValueRows[_targetTable]:parseRemainingData(dataRowsForTargetTableFieldValueRow)
  end

  for _, subTableFieldValueRowLists in pairs(currentSubTableFieldValueRowLists) do
    self:addFieldValueRowsToEmptyLists(subTableFieldValueRowLists, currentFieldValueRows)
  end


  return targetTableFieldValueRowList

end


-- Private Methods

---
-- Returns the list of included related tables for all query Table's.
--
-- @tparam Table[] _queryTables The list of query Table's
--
-- @treturn Table[][] The list of related Table's per query Table that are included in the list of query Table's
--
function FieldValueRowListBuilder:getIncludedRelatedTables(_queryTables)

  local includedForeignTables = {}
  for _, queryTable in ipairs(_queryTables) do
    includedForeignTables[queryTable] = TableUtils.intersectTables(queryTable:getRelatedTables(), _queryTables)
  end

  return includedForeignTables

end

---
-- Generates a list of empty FieldValueRowList's for a list of Table's.
--
-- @tparam Table[] _targetTables The list of target Table's
--
-- @treturn FieldValueRowList[] The list of FieldValueRowList's
--
function FieldValueRowListBuilder:generateEmptySubFieldValueRowLists(_targetTables)

  local fieldValueRowLists = {}
  for _, targetTable in ipairs(_targetTables) do
    fieldValueRowLists[targetTable] = FieldValueRowList()
  end

  return fieldValueRowLists

end

---
-- Adds all corresponding FieldValueRow's to empty sub FieldValueRowLists.
-- This is necessary for 1:n relations between the query result Table's.
--
-- @tparam FieldValueRowList[] _fieldValueRowLists The sub FieldValueRowList's
-- @tparam FieldValueRow[] _currentFieldValueRows The current FieldValueRow's per query table
--
function FieldValueRowListBuilder:addFieldValueRowsToEmptyLists(_fieldValueRowLists, _currentFieldValueRows)

  for targetTable, fieldValueRowList in pairs(_fieldValueRowLists) do

    if (fieldValueRowList:count() == 0) then
      local fieldValueRow = _currentFieldValueRows[targetTable]
      if (fieldValueRow ~= nil) then
        fieldValueRowList:addFieldValueRow(fieldValueRow)
      end
    end

  end

end


-- When FieldValueRowListBuilder() is called, call the __construct() method
setmetatable(FieldValueRowListBuilder, {__call = FieldValueRowListBuilder.__construct})


return FieldValueRowListBuilder
