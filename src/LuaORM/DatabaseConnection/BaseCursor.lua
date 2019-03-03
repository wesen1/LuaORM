---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- Represents a query result cursor.
--
-- @type BaseCursor
--
local BaseCursor = {}


-- Public Methods

---
-- Fetches and returns the next row from the cursor.
-- The row must be converted to the format {[resultColumnName] = value, ...}.
--
-- @treturn string[]|nil The next row or nil if there are no more rows
--
function BaseCursor:fetch()
end

---
-- Closes the cursor.
--
function BaseCursor:close()
end

---
-- Fetches and returns all rows of the cursor.
--
-- @treturn string[][] The list of result rows
--
function BaseCursor:fetchAll()

  local resultRows = {}

  local currentRowNumber = 1
  local row = self:fetch()

  while (row ~= nil) do
    resultRows[currentRowNumber] = row
    currentRowNumber = currentRowNumber + 1

    row = self:fetch()
  end

  self:close()

  return resultRows

end


return BaseCursor
