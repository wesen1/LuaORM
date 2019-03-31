---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local DataTypeList = require("LuaORM/DatabaseLanguage/DataTypeList")
local Query = require("LuaORM/Query/Query")
local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local SelectRule = require("LuaORM/Query/Clause/Select/SelectRule")
local TableColumn = require("LuaORM/Table/TableColumn")
local TableUtils = require("LuaORM/Util/TableUtils")
local TemplateRenderer = require("LuaORM/Util/TemplateRenderer")

---
-- Base class for DatabaseLanguages.
--
-- The tasks of a DatabaseLanguage are:
--   * Translating Query objects to database language specific commands
--   * Escaping literals and identifiers
--   * Providing SQL data types for TableColumn's
--
-- @type BaseDatabaseLanguage
--
local BaseDatabaseLanguage = {}


---
-- The template renderer that is used to render query templates
--
-- @tfield TemplateRenderer templateRenderer
--
BaseDatabaseLanguage.templateRenderer = nil

---
-- Static list of database language names
--
-- @tfield int[] databaseLanguageNames
--
BaseDatabaseLanguage.databaseLanguageNames = {
  MySQL = 0,
  SQLite = 1,
  PostgreSQL = 2,
  Oracle = 3
}

---
-- The database language name id of this DatabaseLanguage
--
-- @tfield int databaseLanguageNameId
--
BaseDatabaseLanguage.databaseLanguageNameId = nil

---
-- The list of available data types
-- At least the "string" data type must be defined by all inheriting classes
--
-- @tfield DataTypeList dataTypes
--
BaseDatabaseLanguage.dataTypes = DataTypeList({
  {name = "string"},
  {name = "blob", defaultsTo = "string"},
  {name = "text", defaultsTo = "blob"},
  {name = "number", defaultsTo = "string"},
  {name = "integer", defaultsTo = "number"},
  {name = "float", defaultsTo = "number"},
  {name = "boolean", defaultsTo = "integer", maxLength = 1},
  {name = "unsignedInteger", defaultsTo = "integer", isUnsigned = true}
})

---
-- The DatabaseLanguage's representation string for a value that is not set (e.g. "NULL" in MySQL)
--
-- @tfield string valueNotSetString
--
BaseDatabaseLanguage.valueNotSetString = nil


-- Metamethods

---
-- BaseDatabaseLanguage constructor.
-- This is the __call metamethod.
--
-- @tparam int _databaseLanguageNameId The id of the database language name
--
-- @treturn BaseDatabaseLanguage The BaseDatabaseLanguage instance
--
function BaseDatabaseLanguage:__construct(_databaseLanguageNameId)

  local instance = setmetatable({}, {__index = BaseDatabaseLanguage})
  instance.databaseLanguageNameId = _databaseLanguageNameId
  instance.templateRenderer = TemplateRenderer()

  return instance

end


-- Getters and Setters

---
-- Returns the list of data types.
--
-- @treturn DataTypeList The list of data types
--
function BaseDatabaseLanguage:getDataTypes()
  return self.dataTypes
end

---
-- Returns the DatabaseLanguage's representation string for a value that is not set.
--
-- @treturn string The DatabaseLanguage's representation string for a value that is not set
--
function BaseDatabaseLanguage:getValueNotSetString()
  return self.valueNotSetString
end


-- Public Methods

---
-- Returns the DatabaseLanguage's name.
--
-- @treturn string The DatabaseLanguage's name
--
function BaseDatabaseLanguage:getDatabaseLanguageName()

  for databaseLanguageName, databaseLanguageNameId in pairs(BaseDatabaseLanguage.databaseLanguageNames) do
    if (databaseLanguageNameId == self.databaseLanguageNameId) then
      return databaseLanguageName
    end
  end

end


---
-- Checks whether a SQL data type is a integer data type.
--
-- @tparam string _sqlDataType The SQL data type
--
-- @treturn bool True if the SQL data type is a integer data type, false otherwise
--
function BaseDatabaseLanguage:isIntegerDataType(_sqlDataType)

  local dataType = self.dataTypes[_sqlDataType]
  if (dataType == nil) then
    return self:isNonDefaultIntegerDataType(_sqlDataType)
  else
    return self:isDefaultDataTypeInList(_sqlDataType, dataType, { "integer", "unsignedInteger" })
  end

end

---
-- Checks whether a SQL data type is a number data type.
--
-- @tparam string _sqlDataType The SQL data type
--
-- @treturn bool True if the SQL data type is a number data type, false otherwise
--
function BaseDatabaseLanguage:isNumberDataType(_sqlDataType)

  if (self:isIntegerDataType(_sqlDataType)) then
    return true
  else

    local dataType = self.dataTypes[_sqlDataType]
    if (dataType == nil) then
      return self:isNonDefaultNumberDataType(_sqlDataType)
    else
      return self:isDefaultDataTypeInList(_sqlDataType, dataType, { "float", "number" })
    end

  end

end

---
-- Checks whether a SQL data type is a text data type.
--
-- @tparam string _sqlDataType The SQL data type
--
-- @treturn bool True if the SQL data type is a text data type, false otherwise
--
function BaseDatabaseLanguage:isTextDataType(_sqlDataType)

  local dataType = self.dataTypes[_sqlDataType]
  if (dataType == nil) then
    return self:isNonDefaultTextDataType(_sqlDataType)
  else
    return self:isDefaultDataTypeInList(_sqlDataType, dataType, { "string", "text" })
  end

end


---
-- Translates a query object to a database specific statement.
--
-- @tparam Query _query The query object
--
-- @treturn string The SQL command to execute the query with a specific database language
--
function BaseDatabaseLanguage:translateQuery(_query)

  local query = self:convertIncompatibleClauses(_query)
  local templateValues = { query = query, language = self }

  if (query:getType() == Query.types.CREATE) then
    return self.templateRenderer:renderTemplate(self:getDatabaseLanguageName(), "CreateTable", templateValues)
  elseif (query:getType() == Query.types.SELECT) then
    return self.templateRenderer:renderTemplate(self:getDatabaseLanguageName(), "Select", templateValues)
  elseif (query:getType() == Query.types.INSERT) then
    return self.templateRenderer:renderTemplate(self:getDatabaseLanguageName(), "Insert", templateValues)
  elseif (query:getType() == Query.types.UPDATE) then
    return self.templateRenderer:renderTemplate(self:getDatabaseLanguageName(), "Update", templateValues)
  elseif (query:getType() == Query.types.DELETE) then
    return self.templateRenderer:renderTemplate(self:getDatabaseLanguageName(), "Delete", templateValues)
  end

end

---
-- Escapes a literal to insert it into a query (e.g. adds single colons around a string in MySQL).
--
-- @tparam mixed _literal The literal value
--
-- @treturn string The escaped literal value
--
function BaseDatabaseLanguage:escapeLiteral(_literal)
  return _literal
end

---
-- Escapes a identifier to insert it into a query (e.g. adds backticks to a identifier in MySQL).
--
-- @tparam mixed _identifier The identifier
--
-- @treturn string The escaped identifier
--
function BaseDatabaseLanguage:escapeIdentifier(_identifier)
  return _identifier
end

---
-- Returns a identifier for a target.
--
-- @tparam TableColumn|SelectRule _target The target
--
-- @treturn string The identifier for the target
--
function BaseDatabaseLanguage:getTargetIdentifier(_target)

  if (ObjectUtils.isInstanceOf(_target, TableColumn)) then
    local templateValues = { column = _target, language = self }
    return self.templateRenderer:renderTemplate(
      self:getDatabaseLanguageName(), "Generic/TableColumn", templateValues
    )

  elseif (ObjectUtils.isInstanceOf(_target, SelectRule)) then
    return self:escapeIdentifier(_target:getSelectAlias())
  end

end


-- Protected Methods

---
-- Checks whether a SQL data type is a integer data type that is not defined in the list of data types.
--
-- @tparam string _sqlDataType The SQL data type
--
-- @treturn bool True if the SQL data type is a integer data type that is not defined in the list of data types, false otherwise
--
function BaseDatabaseLanguage:isNonDefaultIntegerDataType(_sqlDataType)
  return false
end

---
-- Checks whether a SQL data type is a number data type that is not defined in the list of data types.
--
-- @tparam string _sqlDataType The SQL data type
--
-- @treturn bool True if the SQL data type is a number data type that is not defined in the list of data types, false otherwise
--
function BaseDatabaseLanguage:isNonDefaultNumberDataType(_sqlDataType)
  return false
end

---
-- Checks whether a SQL data type is a text data type that is not defined in the list of data types.
--
-- @tparam string _sqlDataType The SQL data type
--
-- @treturn bool True if the SQL data type is a text data type that is not defined in the list of data types, false otherwise
--
function BaseDatabaseLanguage:isNonDefaultTextDataType(_sqlDataType)
  return false
end

---
-- Converts the clauses that are incompatible with the DatabaseLanguage (e.g. OUTER JOIN in MySQL).
--
-- @tparam Query _query The query object
--
-- @treturn Query The query object with converted incompatible clauses
--
function BaseDatabaseLanguage:convertIncompatibleClauses(_query)
  return _query
end


-- Private Methods

---
-- Checks whether a default data type is contained in a list of allowed default data types.
--
-- @tparam string _dataTypeName The name of the default data type
-- @tparam DataType _dataType The data type
-- @tparam string[] _allowedDataTypes The names of the allowed data types
--
-- @treturn bool True if the default data type is contained in the list of allowed data types, false otherwise
--
function BaseDatabaseLanguage:isDefaultDataTypeInList(_dataTypeName, _dataType, _allowedDataTypes)

  local comparisonDataTypeName
  if (_dataType:getType() == nil) then
    comparisonDataTypeName = _dataType:getSettings()["defaultsTo"]
  else
    comparisonDataTypeName = _dataTypeName
  end

  return (TableUtils.tableHasValue(_allowedDataTypes, comparisonDataTypeName))

end


-- When BaseDatabaseLanguage() is called, call the __construct() method
setmetatable(BaseDatabaseLanguage, {__call = BaseDatabaseLanguage.__construct})


return BaseDatabaseLanguage
