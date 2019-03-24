---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local GettableAttributeMembersClass = require("LuaORM/Util/Class/GettableAttributeMembersClass")

---
-- Stores a list of FieldValueRow's for a specific table.
-- FieldValueRowList's are used as containers for query results.
--
-- @type FieldValueRowList
--
local FieldValueRowList = {}


---
-- The list of FieldValueRow's
--
-- @tfield FieldValueRow[] fieldValueRows
--
FieldValueRowList.fieldValueRows = nil

---
-- The names of the attributes that will be searched for sub fields to return
--
-- @tfield string[] gettableAttributeNames
--
FieldValueRowList.gettableAttributeNames = { "fieldValueRows" }


-- Metamethods

---
-- FieldValueRowList constructor.
-- This is the __call metamethod.
--
-- @treturn FieldValueRowList The FieldValueRowList instance
--
function FieldValueRowList:__construct()

  local instance = GettableAttributeMembersClass(FieldValueRowList)
  instance.fieldValueRows = {}

  return instance

end


-- API

---
-- Returns the number of FieldValueRow's inside this FieldValueRowList.
--
-- @treturn int The number of FieldValueRow's inside this FieldValueRowList
--
function FieldValueRowList:count()
  return #self.fieldValueRows
end

---
-- Deletes all FieldValueRow's inside this FieldValueRowList from the database.
--
function FieldValueRowList:delete()

  local fieldValueRows = {}
  for _, fieldValueRow in ipairs(self.fieldValueRows) do
    if (not fieldValueRow:delete()) then
      table.insert(fieldValueRows, fieldValueRow)
    end
  end

  self.fieldValueRows = fieldValueRows

end

---
-- Updates all FieldValueRow's inside the database in which at least one FieldValue was changed.
--
-- @tparam mixed[] _dataRow The values to set for each of the FieldValueRow's (optional)
--
function FieldValueRowList:update(_dataRow)
  for _, fieldValueRow in ipairs(self.fieldValueRows) do
    fieldValueRow:update(_dataRow)
  end
end


-- Public Methods

---
-- Adds a FieldValueRow to this FieldValueRowList.
--
-- @tparam FieldValueRow _fieldValueRow The FieldValueRow to add
--
function FieldValueRowList:addFieldValueRow(_fieldValueRow)
  table.insert(self.fieldValueRows, _fieldValueRow)
end


setmetatable(
  FieldValueRowList,
  {
    -- FieldValueRowList inherits methods and attributes from GettableAttributeMembersClass
    __index = GettableAttributeMembersClass,

    -- When FieldValueRowList() is called, call the __construct() method
    __call = FieldValueRowList.__construct
  }
)


return FieldValueRowList
