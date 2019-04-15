---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local FieldValueRow = require("LuaORM/FieldValueRowList/FieldValueRow/FieldValueRow")
local Query = require("LuaORM/Query/Query")
local Table = require("LuaORM/Table/Table")
local Type = require("LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- The API to access the database tables.
-- There is one Model instance per database table.
--
-- @type Model
--
local Model = {}


---
-- The target table of the Model
--
-- @tfield Table targetTable
--
Model.targetTable = nil


-- Metamethods

---
-- Model constructor.
-- This is the __call metamethod.
--
-- @tparam mixed[] _tableConfiguration The table configuration of this Model's table
--
-- @treturn Model The Model instance
--
function Model:__construct(_tableConfiguration)

  local instance = setmetatable({}, {__index = Model})
  instance.targetTable = Table(_tableConfiguration)
  instance:createTable()

  return instance

end


-- Getters and Setters

---
-- Returns the target Table of this Model.
--
-- @treturn Table The target Table of this Model
--
function Model:getTargetTable()
  return self.targetTable
end


-- API

---
-- Creates and returns a new FieldValueRow for this Model's target table.
--
-- @tparam mixed[] _dataRow The dataRow
--
-- @treturn FieldValueRow The FieldValueRow
--
function Model:new(_dataRow)

  local fieldValueRow = FieldValueRow(self.targetTable)
  fieldValueRow:parse(Type.toTable(_dataRow), false)

  return fieldValueRow

end

---
-- Returns a new Query for this Model's target Table.
--
-- @treturn Query The Query
--
function Model:get()
  return Query(self.targetTable, FieldValueRow(self.targetTable))
end


-- Private Methods

---
-- Creates the target Table in the database.
--
function Model:createTable()

  if (self.targetTable:validate()) then
    API.ORM:getLogger():info("Creating table '" .. self.targetTable:getName() .. "'")
    Query(self.targetTable, FieldValueRow(self.targetTable)):create()
  end

end


-- When Model() is called, call the __construct() method
setmetatable(Model, {__call = Model.__construct})


return Model
