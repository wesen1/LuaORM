---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Type = require("LuaORM/Util/Type/Type")
local FieldType = require("LuaORM/Table/FieldType")

---
-- Stores the list of default FieldType's.
--
-- @type FieldType[]
--
local defaultFieldTypes = {}

defaultFieldTypes.integerField = FieldType({
  luaDataType = "integer",
  SQLDataType = "integer"
})

defaultFieldTypes.unsignedIntegerField = FieldType({
  luaDataType = "integer",
  SQLDataType = "unsignedInteger",
})

defaultFieldTypes.charField = FieldType({
  luaDataType = "string",
  SQLDataType = "string",
})

defaultFieldTypes.textField = FieldType({
  luaDataType = "string",
  SQLDataType = "text"
})

defaultFieldTypes.booleanField = FieldType({
  luaDataType = "boolean",
  SQLDataType = "boolean"
})

defaultFieldTypes.dateTimeField = FieldType({
  luaDataType = "integer",
  SQLDataType = "unsignedInteger",
  convert = function(_value)
              -- Check if the value is a result of os.date("*t")
              if (Type.isTable(_value) and _value["isdst"] ~= nil) then
                return os.time(_value)
              else
                return _value
              end
            end,
  to = function (value)
         return os.date("*t", value)
       end
})


return defaultFieldTypes
