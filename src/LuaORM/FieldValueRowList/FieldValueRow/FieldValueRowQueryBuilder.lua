---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Query = require("LuaORM/Query/Query")

---
-- Handles building of queries for FieldValueRowQueryExecutor's.
--
-- @type FieldValueRowQueryBuilder
--
local FieldValueRowQueryBuilder = {}


---
-- The parent FieldValueRow
--
-- @tfield FieldValueRow parentFieldValueRow
--
FieldValueRowQueryBuilder.parentFieldValueRow = nil


-- Metamethods

---
-- FieldValueRowQueryBuilder constructor.
-- This is the __call metamethod.
--
-- @tparam FieldValueRow _parentFieldValueRow The parent FieldValueRow
--
-- @treturn FieldValueRowQueryBuilder The FieldValueRowQueryBuilder instance
--
function FieldValueRowQueryBuilder:__construct(_parentFieldValueRow)

  local instance = setmetatable({}, {__index = FieldValueRowQueryBuilder})
  instance.parentFieldValueRow = _parentFieldValueRow

  return instance

end


-- Public Methods

---
-- Returns a Query with which the parent FieldValueRow can be selected from the database.
--
-- @treturn Query The Query with which the parent FieldValueRow can be selected from the database
--
function FieldValueRowQueryBuilder:getSelectQuery()

  local primaryKeyFieldValue = self.parentFieldValueRow:getPrimaryKeyFieldValue()
  local query = Query(self.parentFieldValueRow:getParentTable(), self.parentFieldValueRow)

  if (primaryKeyFieldValue:isEmpty()) then
    self:targetParentFieldValueRowByValues(query)
  else
    self:targetParentFieldValueRowByPrimaryKey(query)
  end

  return query

end

---
-- Returns a Query with which all duplicated unique column values can be found.
--
-- @treturn Query The Query with which all duplicated unique column values can be found
--
function FieldValueRowQueryBuilder:selectRowByUniqueColumns()

  local query = Query(self.parentFieldValueRow:getParentTable(), self.parentFieldValueRow)

  for _, fieldValue in ipairs(self.parentFieldValueRow:getFieldValues()) do
    if (fieldValue:getColumn():getSettings()["unique"] == true) then
      query:where()
           :column(fieldValue:getColumn():getName())
           :equals(fieldValue:getCurrentValue())
           :OR()
    end
  end

  return query

end

---
-- Returns a Query with which the parent FieldValueRow can be inserted into the database.
--
-- @treturn Query The Query with which the parent FieldValueRow can be inserted into the database
--
function FieldValueRowQueryBuilder:getInsertQuery()
  return Query(self.parentFieldValueRow:getParentTable(), self.parentFieldValueRow)
end

---
-- Returns a Query with which the parent FieldValueRow can be updated inside the database.
--
-- @treturn Query The Query with which the parent FieldValueRow can be updated inside the database
--
function FieldValueRowQueryBuilder:getUpdateQuery()

  local query = Query(self.parentFieldValueRow:getParentTable(), self.parentFieldValueRow)
  self:targetParentFieldValueRowByPrimaryKey(query)

  return query

end

---
-- Returns a Query with which the parent FieldValueRow can be deleted from the database.
--
-- @treturn Query The Query with which the parent FieldValueRow can be deleted from the database
--
function FieldValueRowQueryBuilder:getDeleteQuery()

  local query = Query(self.parentFieldValueRow:getParentTable())
  self:targetParentFieldValueRowByPrimaryKey(query)

  return query

end


-- Private Methods

---
-- Targets the parent FieldValueRow by its primary key in a Query.
--
-- @tparam Query _query The Query
--
function FieldValueRowQueryBuilder:targetParentFieldValueRowByPrimaryKey(_query)

  local primaryKeyFieldValue = self.parentFieldValueRow:getPrimaryKeyFieldValue()

  _query:where()
        :column(primaryKeyFieldValue:getColumn():getName())
        :equals(primaryKeyFieldValue:getLastQueryResultValue())

end

---
-- Targets the parent FieldValueRow by its column values in a Query.
--
-- @tparam Query _query The Query
--
function FieldValueRowQueryBuilder:targetParentFieldValueRowByValues(_query)

  for _, fieldValue in ipairs(self.parentFieldValueRow:getNonEmptyFieldValues()) do
    if (fieldValue:getColumn():getSettings()["isPrimaryKey"] == false) then
      _query:where()
            :column(fieldValue:getColumn():getName())
            :equals(fieldValue:getCurrentValue())
            :AND()
    end
  end

end


-- When FieldValueRowQueryBuilder() is called, call the __construct() method
setmetatable(FieldValueRowQueryBuilder, {__call = FieldValueRowQueryBuilder.__construct})


return FieldValueRowQueryBuilder
