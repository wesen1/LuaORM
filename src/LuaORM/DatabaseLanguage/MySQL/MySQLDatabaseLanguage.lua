---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local BaseDatabaseLanguage = require("LuaORM/DatabaseLanguage/BaseDatabaseLanguage")
local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local Type = require("LuaORM/Util/Type/Type")

---
-- DatabaseLanguage for MySQL.
--
-- @type MySQLDatabaseLanguage
--
local MySQLDatabaseLanguage = {}


-- Clone the base DataTypeList
MySQLDatabaseLanguage.dataTypes = ObjectUtils.clone(BaseDatabaseLanguage.dataTypes)

-- Define the data types for MySQL
MySQLDatabaseLanguage.dataTypes["string"] = "VARCHAR"
MySQLDatabaseLanguage.dataTypes["blob"] = "BLOB"
MySQLDatabaseLanguage.dataTypes["text"] = "TEXT"
MySQLDatabaseLanguage.dataTypes["number"] = "FLOAT"
MySQLDatabaseLanguage.dataTypes["integer"] = "INTEGER"
MySQLDatabaseLanguage.dataTypes["float"] = "FLOAT"
MySQLDatabaseLanguage.dataTypes["boolean"] = "BOOLEAN"

---
-- The DatabaseLanguage's representation string for a value that is not set
--
-- @tfield string valueNotSetString
--
MySQLDatabaseLanguage.valueNotSetString = "NULL"


-- Metamethods

---
-- MySQLDatabaseLanguage constructor.
-- This is the __call metamethod.
--
-- @treturn MySQLDatabaseLanguage The MySQLDatabaseLanguage instance
--
function MySQLDatabaseLanguage:__construct()

  local instance = BaseDatabaseLanguage(BaseDatabaseLanguage.databaseLanguageNames.MySQL)
  setmetatable(instance, {__index = MySQLDatabaseLanguage})

  return instance

end


-- Public Methods

---
-- Escapes a literal to insert it into a query.
--
-- @tparam mixed _value The literal
--
-- @treturn string _value The escaped literal
--
function MySQLDatabaseLanguage:escapeLiteral(_value)

  if (Type.isString(_value)) then
    return "'" .. _value .. "'"
  else
    return Type.toString(_value)
  end

end

---
-- Escapes a identifier to insert it into a query.
--
-- @tparam mixed _identifier The identifier
--
-- @treturn string The escaped identifier
--
function MySQLDatabaseLanguage:escapeIdentifier(_identifier)
  return "`" .. Type.toString(_identifier) .. "`"
end


-- Protected Methods

---
-- Checks whether a SQL data type is a integer data type that is not defined in the list of data types.
--
-- @tparam string _sqlDataType The SQL data type
--
-- @treturn bool True if the SQL data type is a integer data type that is not defined in the list of data types, false otherwise
--
function MySQLDatabaseLanguage:isNonDefaultIntegerDataType(_sqlDataType)
  return _sqlDataType:upper():match("INT")
end

---
-- Checks whether a SQL data type is a text data type that is not defined in the list of data types.
--
-- @tparam string _sqlDataType The SQL data type
--
-- @treturn bool True if the SQL data type is a text data type that is not defined in the list of data types, false otherwise
--
function MySQLDatabaseLanguage:isNonDefaultTextDataType(_sqlDataType)
  return _sqlDataType:upper():match("TEXT") or
         _sqlDataType:upper():match("CHAR") or
         _sqlDataType:upper():match("BINARY")
end


setmetatable(
  MySQLDatabaseLanguage,
  {
    -- MySQLDatabaseLanguage inherits methods and attributes from BaseDatabaseLanguage
    __index = BaseDatabaseLanguage,

    -- When MySQLDatabaseLanguage() is called, call the __construct() method
    __call = MySQLDatabaseLanguage.__construct
  }
)


return MySQLDatabaseLanguage
