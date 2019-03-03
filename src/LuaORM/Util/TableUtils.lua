---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- Provides static table related util functions.
--
-- @type TableUtils
--
local TableUtils = {}


---
-- Returns whether a table contains a specific value.
--
-- @tparam table _table The table to search in
-- @tparam mixed _value The value to search for
--
-- @treturn bool True if the table contains the value, false otherwise
--
function TableUtils.tableHasValue(_table, _value)

  for _, value in pairs(_table) do
    if (value == _value) then
      return true
    end
  end

  return false

end

---
-- Returns whether a table contains a specific index.
--
-- @tparam table _table The table to search in
-- @tparam mixed _index The index to search for
--
-- @treturn bool True if the table contains the index, false otherwise
--
function TableUtils.tableHasIndex(_table, _index)

  for index, _ in pairs(_table) do
    if (index == _index) then
      return true
    end
  end

  return false

end

---
-- Merges the items of multiples tables with numeric indexes into one table.
--
-- @tparam table ... The tables to concatenate (optional number of arguments)
--
-- @treturn table The merged table
--
function TableUtils.concatenateTables(...)

  local mergeTables = {...}
  local mergedTable = {}

  local currentIndex = 1
  for _, mergeTable in ipairs(mergeTables) do
    for i = 1, #mergeTable, 1 do
      mergedTable[currentIndex] = mergeTable[i]
      currentIndex = currentIndex + 1
    end
  end

  return mergedTable

end

---
-- Returns a list of items that are present in all of the passed tables.
-- The tables must have numeric indexes.
--
-- @tparam table ... The tables to intersect (optional number of arguments)
--
-- @treturn table The intersected table
--
function TableUtils.intersectTables(...)

  local intersectTables = {...}
  local intersectedTable = {}

  local numberOfIntersectTables = #intersectTables
  for intersectTableNumber, intersectTable in ipairs(intersectTables) do
    for _, value in ipairs(intersectTable) do

      if (not TableUtils.tableHasValue(intersectedTable, value)) then

        local valueExistsInAllTables = true
        for i = intersectTableNumber, numberOfIntersectTables, 1 do
          if (not TableUtils.tableHasValue(intersectTables[i], value)) then
            valueExistsInAllTables = false
            break
          end
        end

        if (valueExistsInAllTables) then
          table.insert(intersectedTable, value)
        end

      end

    end
  end

  return intersectedTable

end


return TableUtils
