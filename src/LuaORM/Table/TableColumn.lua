---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local SettingValueList = require("LuaORM/Util/SettingValueList/SettingValueList")
local Type = require("LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- Represents a column of a database table.
--
-- @type TableColumn
--
local TableColumn = {}


---
-- The FieldType of the TableColumn
--
-- @tfield FieldType fieldType
--
TableColumn.fieldType = nil

---
-- The parent Table
--
-- @tfield Table parentTable
--
TableColumn.parentTable = nil

---
-- The TableColumn's name in the database
--
-- @tfield string name
--
TableColumn.name = nil

---
-- The TableColumn's settings
--
-- @tfield SettingValueList settings
--
TableColumn.settings = SettingValueList(

  -- Defines whether the column is a primary key
  { name = "isPrimaryKey", dataType = "boolean", defaultValue = false },

  -- Defines whether the values of this column are automatically incremented
  { name = "autoIncrement", dataType = "boolean", defaultValue = false },

  -- Defines whether this column is a foreign key to a specific table
  { name = "isForeignKeyTo", dataType = "instanceof:LuaORM/Table/Table", mustBeSet = false },


  -- Defines if the column must always have a value
  { name = "mustBeSet", dataType = "boolean", defaultValue = true },

  -- Defines if the column values must be unique
  { name = "unique", dataType = "boolean", defaultValue = false },

  -- The number of available bytes per value (affects number of symbols, maximum integer size, etc.)
  { name = "maxLength", dataType = "integer", mustBeSet = false },

  -- If true text values will be escaped in order to prevent SQL injection
  { name = "escapeValue", dataType = "boolean", defaultValue = false },


  -- Default value if the value is not set (May be a function)
  { name = "defaultValue", dataType = "any", mustBeSet = false }
)


-- Metamethods

---
-- TableColumn constructor.
-- This is the __call metamethod.
--
-- @tparam Table _parentTable The parent Table
-- @tparam string _name The column name
-- @tparam mixed[] _settings The TableColumn's settings
--
-- @treturn TableColumn The TableColumn instance
--
function TableColumn:__construct(_parentTable, _name, _settings)

  local instance = setmetatable({}, {__index = TableColumn})

  instance.parentTable = _parentTable
  instance.fieldType = _settings["fieldType"]
  instance.name = _name

  instance.settings = ObjectUtils.clone(TableColumn.settings)
  instance.settings:parse(_settings)

  return instance

end


-- Getters and Setters

---
-- Returns the parent Table.
--
-- @treturn Table The parent Table
--
function TableColumn:getParentTable()
  return self.parentTable
end

---
-- Returns the TableColumn's settings.
--
-- @treturn SettingValueList The TableColumn's settings
--
function TableColumn:getSettings()
  return self.settings
end

---
-- Returns the TableColumn's FieldType.
--
-- @treturn FieldType The TableColumn's FieldType
--
function TableColumn:getFieldType()
  return self.fieldType
end

---
-- Returns the TableColumn's name.
--
-- @treturn string The TableColumn's name
--
function TableColumn:getName()
  return self.name
end


-- Public Methods

---
-- Returns the SQL data type of this TableColumn.
--
-- @treturn string The SQL data type of this TableColumn
--
function TableColumn:getSQLDataType()
  return self.fieldType:getSQLDataType(API.ORM:getDatabaseConnection())
end

---
-- Returns the "maxLength" setting of this TableColumn.
--
-- @tparam BaseDatabaseLanguage _databaseLanguage The DatabaseLanguage
--
-- @treturn int The "maxLength" setting of this TableColumn
--
function TableColumn:getMaxLength(_databaseLanguage)

  local dataTypeName = self:getFieldType():getSettings()["SQLDataType"]
  local dataType = _databaseLanguage.dataTypes[dataTypeName]
  if (dataType ~= nil and dataType:getSettings()["maxLength"] ~= nil) then
    return dataType:getSettings()["maxLength"]
  else
    return self.settings["maxLength"]
  end

end

---
-- Returns the name for the column that will be used as a alias in SELECT queries.
--
-- @treturn string The SELECT query alias for this TableColumn
--
function TableColumn:getSelectAlias()
  return self.parentTable:getName() .. "." .. self.name
end

---
-- Returns the default value for this TableColumn.
--
-- @treturn mixed The default value for this TableColumn
--
function TableColumn:getDefaultValue()

  local defaultValue = self.settings["defaultValue"]
  if (Type.isFunction(defaultValue)) then
    return defaultValue()
  else
    return defaultValue
  end

end

---
-- Returns the query string for a value of this column.
--
-- @tparam mixed _value The value
--
-- @treturn The query string for a value of this column
--
function TableColumn:getValueQueryString(_value)

  local value = _value
  if (self.settings["escapeValue"] == true) then
    value = API.ORM:getDatabaseConnection():escapeString(value)
  end

  return self.fieldType:convertValueToSQLString(API.ORM:getDatabaseConnection(), value)

end

---
-- Checks if this TableColumn's settings are valid and corrects the settings if necessary.
--
function TableColumn:validate()

  local databaseLanguage = API.ORM:getDatabaseConnection():getDatabaseLanguage()

  self:validateMaxLengthSetting(databaseLanguage)
  self:validateAutoIncrementSetting()
  self:validateEscapeValueSetting()
end


-- Private Methods

---
-- Validates the "maxLength" setting.
--
-- @tparam BaseDatabaseLanguage _databaseLanguage The DatabaseLanguage
--
function TableColumn:validateMaxLengthSetting(_databaseLanguage)

  local maxLength = self.settings["maxLength"]
  if (maxLength ~= nil and maxLength == self:getMaxLength(_databaseLanguage)) then
    if (maxLength < 1) then
      self.settings["maxLength"] = nil
      API.ORM:getLogger():warn(string.format(
        "The maximum length may not be smaller than 1 (Column '%s')",
        self:getSelectAlias()
      ))
    end
  end

end

---
-- Validates the "autoIncrement" setting.
--
function TableColumn:validateAutoIncrementSetting()

  if (self.settings["autoIncrement"] == true) then

    local sqlDataType = self.fieldType:getSettings()["SQLDataType"]
    local databaseLanguage = API.ORM:getDatabaseConnection():getDatabaseLanguage()

    if (not databaseLanguage:isIntegerDataType(sqlDataType)) then
      self.settings["autoIncrement"] = false
      API.ORM:getLogger():warn(string.format(
        "Disabling autoIncrement option: FieldType must be a INTEGER FieldType (Column '%s')",
        self:getSelectAlias()
      ))
    end

  end

end

---
-- Validates the "escapeValue" setting.
--
function TableColumn:validateEscapeValueSetting()

  if (self.settings["escapeValue"] == true) then

    local sqlDataType = self.fieldType:getSettings()["SQLDataType"]
    local databaseLanguage = API.ORM:getDatabaseConnection():getDatabaseLanguage()

    if (not databaseLanguage:isTextDataType(sqlDataType)) then
      self.settings["escapeValue"] = false
      API.ORM:getLogger():warn(string.format(
        "Disabling escapeValue option: FieldType must be a text FieldType (Column '%s')",
        self:getSelectAlias()
      ))
    end

  end

end


-- When TableColum() is called, call the __construct() method
setmetatable(TableColumn, {__call = TableColumn.__construct})


return TableColumn
