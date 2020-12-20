---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local FieldValue = require("LuaORM/FieldValueRowList/FieldValueRow/FieldValue")
local API = LuaORM_API

---
-- Handles parsing of data rows for FieldValueRow's.
--
-- @type FieldValueRowDataParser
--
local FieldValueRowDataParser = {}


---
-- The parent FieldValueRow
-- This is the FieldValueRow that will receive the parsed data
--
-- @tfield FieldValueRow parentFieldValueRow
--
FieldValueRowDataParser.parentFieldValueRow = nil


-- Metamethods

---
-- FieldValueRowDataParser constructor.
-- This is the __call metamethod.
--
-- @tparam FieldValueRow _parentFieldValueRow The parent FieldValueRow
--
-- @treturn FieldValueRowDataParser The FieldValueRowDataParser instance
--
function FieldValueRowDataParser:__construct(_parentFieldValueRow)

  local instance = setmetatable({}, {__index = FieldValueRowDataParser})
  instance.parentFieldValueRow = _parentFieldValueRow

  return instance

end


-- Public Methods

---
-- Parses a single data row and replaces the FieldValue's of the FieldValueRow with the ones from the data row.
--
-- @tparam string[] _dataRow The data row
-- @tparam bool _isQueryResult Defines whether the data row is a query result or user input
--
function FieldValueRowDataParser:parse(_dataRow, _isQueryResult)
  self.parentFieldValueRow:setFieldValues(self:extractFieldValues(_dataRow, _isQueryResult))
  self:markDataRowValuesAsParsed(_dataRow, _isQueryResult)
end

---
-- Extracts and returns all field values for the columns of the parent table from a given data row.
--
-- @tparam string[] _dataRow The data row
-- @tparam bool _isQueryResult Defines whether the data row is a query result or user input
--
-- @treturn FieldValue[] The extracted FieldValue's
--
function FieldValueRowDataParser:extractFieldValues(_dataRow, _isQueryResult)

  local fieldValues = {}
  for i, column in ipairs(self.parentFieldValueRow:getParentTable():getColumns()) do

    fieldValues[i] = FieldValue(column)

    local rawData = _dataRow[self:getDataRowIndexByColumn(_dataRow, column, _isQueryResult)]
    if (rawData ~= nil) then
      if (_isQueryResult) then
        fieldValues[i]:updateLastQueryResultValue(rawData)
      else
        fieldValues[i]:updateValue(rawData)
      end
    end

  end

  return fieldValues

end

---
-- Parses the remaining data inside a list of data rows.
-- The result is saved as extra values for the parent FieldValueRow.
--
-- @tparam string[][] _dataRows The data rows
--
function FieldValueRowDataParser:parseRemainingData(_dataRows)

  local extraValues = {}
  local currentExtraValues = {}

  for _, dataRow in ipairs(_dataRows) do
    for columnName, value in pairs(dataRow) do

      if (currentExtraValues[columnName] ~= value) then

        if (extraValues[columnName] == nil) then
          extraValues[columnName] = {}
        end

        table.insert(extraValues[columnName], value)
        currentExtraValues[columnName] = value

      end

    end
  end

  for columnName, values in pairs(extraValues) do
    if (#values == 1) then
      extraValues[columnName] = values[1]
    end
  end

  self.parentFieldValueRow:setExtraValues(extraValues)

end

---
-- Parses a update data row and updates the FieldValue's with the values from the update data row.
--
-- @tparam string[] _dataRow The update data row
-- @tparam bool _isQueryResult Defines whether the data row is a query result or user input
--
function FieldValueRowDataParser:parseUpdate(_dataRow, _isQueryResult)

  for i, column in ipairs(self.parentFieldValueRow:getParentTable():getColumns()) do

    local rawData = _dataRow[self:getDataRowIndexByColumn(_dataRow, column, _isQueryResult)]
    if (rawData ~= nil) then

      -- Get the FieldValue
      local currentFieldValue = self.parentFieldValueRow:getFieldValues()[i]
      if (currentFieldValue == nil) then
        currentFieldValue = FieldValue(column)
        self.parentFieldValueRow:getFieldValues()[i] = currentFieldValue
      end

      -- Update the value
      if (_isQueryResult) then
        currentFieldValue:updateLastQueryResultValue(rawData)
      else
        currentFieldValue:updateValue(rawData)
      end

    end

  end

  self:markDataRowValuesAsParsed(_dataRow, _isQueryResult)

  if (_isQueryResult) then
    self:parseRemainingData(_dataRow)
  else
    self:checkIgnoredColumns(_dataRow)
  end

end

---
-- Returns the index of a TableColumn in a data row.
--
-- @tparam mixed[] _dataRow The data row
-- @tparam TableColumn _column The TableColumn
-- @tparam bool _isQueryResult Defines whether the data row is a query result or user input
--
-- @treturn string The index of the TableColumn's data in the data row
--
function FieldValueRowDataParser:getDataRowIndexByColumn(_dataRow, _column, _isQueryResult)

  if (_isQueryResult) then
   return _column:getSelectAlias()
  else
    return _column:getName()
  end

end

---
-- Marks the values for the parent FieldValueRow's parent table inside a data row as parsed.
-- This is done by unsetting the values.
--
-- @tparam string[] _dataRow The data row
-- @tparam bool _isQueryResult Defines whether the data row is a query result or user input
--
function FieldValueRowDataParser:markDataRowValuesAsParsed(_dataRow, _isQueryResult)
  for _, column in ipairs(self.parentFieldValueRow:getParentTable():getColumns()) do
    _dataRow[self:getDataRowIndexByColumn(_dataRow, column, _isQueryResult)] = nil
  end
end


-- Private Methods

---
-- Checks whether any of the values in a update data row were ignored.
-- Also logs a warning message if there were ignored values.
--
-- @tparam string[] _dataRow The data row
--
function FieldValueRowDataParser:checkIgnoredColumns(_dataRow)

  local ignoredColumnNames = {}
  for columnName, value in pairs(_dataRow) do
    table.insert(ignoredColumnNames, columnName)
  end

  if (#ignoredColumnNames > 0) then
    API.ORM:getLogger():warn(string.format(
      "The column(s) '%s' could not be updated: No corresponding column(s) found in parent table",
      table.concat(ignoredColumnNames)
    ))
  end

end


-- When FieldValueRowDataParser() is called, call the __construct() method
setmetatable(FieldValueRowDataParser, {__call = FieldValueRowDataParser.__construct})


return FieldValueRowDataParser
