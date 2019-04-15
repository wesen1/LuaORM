---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local SettingValueList = require("LuaORM/Util/SettingValueList/SettingValueList")

---
-- Represents a SQL data type for TableColumn's.
--
-- @type DataType
--
local DataType = {}


---
-- The parent DataTypeList
--
-- @tfield DataTypeList parentDataTypeList
--
DataType.parentDataTypeList = nil

---
-- The data type name (e.g. VARCHAR, INTEGER, etc.)
--
-- @tfield string type
--
DataType.type = nil

---
-- Additional settings for the data type
--
-- @type SettingValueList settings
--
DataType.settings = SettingValueList(

  ---
  -- The number of available bytes per value (affects number of symbols, maximum integer size, etc.)
  -- This will overwrite the setting of the TableColumn that uses a FieldType with this DataType
  --
  { name = "maxLength", dataType = "integer", mustBeSet = false },

  ---
  -- The name of the data type that will be used as a replacement for this DataType if the type attribute is not set
  --
  { name = "defaultsTo", dataType = "string", mustBeSet = false },

  ---
  -- Defines whether this data type is unsigned (only valid for number data types)
  --
  { name = "isUnsigned", dataType = "boolean", defaultValue = false }
)


-- Metamethods

---
-- DataType constructor.
-- This is the __call metamethod.
--
-- @tparam DataTypeList _parentDataTypeList The parent data type list
-- @tparam mixed[] _settings The data type settings
--
-- @treturn DataType The DataType instance
--
function DataType:__construct(_parentDataTypeList, _settings)

  local instance = setmetatable({}, {__index = DataType})

  instance.parentDataTypeList = _parentDataTypeList
  instance.settings = ObjectUtils.clone(DataType.settings)
  instance.settings:parse(_settings)

  return instance

end


-- Getters and Setters

---
-- Returns the SQL data type name of this DataType.
--
-- @treturn string The SQL data type name of this DataType
--
function DataType:getType()
  return self.type
end

---
-- Sets the SQL data type name of this DataType.
--
-- @tparam string _type The SQL data type name of this DataType
--
function DataType:setType(_type)
  self.type = _type
end

---
-- Returns the settings of this DataType.
--
-- @treturn SettingValueList The settings of this DataType
--
function DataType:getSettings()
  return self.settings
end


-- Public Methods

---
-- Resolves and returns the real SQL type name of this DataType.
-- If no type name is set the type name of the "defaultsTo" DataType will be used.
--
-- @treturn string|nil The real SQL type name of this DataType or nil if no DataType is configured
--
function DataType:getRealType()

  if (self.type == nil) then
    if (self.settings["defaultsTo"] ~= nil) then
      return self.parentDataTypeList[self.settings["defaultsTo"]]:getRealType()
    end

  else
    return self.type
  end

end


-- When DataType() is called, call the __construct() method
setmetatable(DataType, {__call = DataType.__construct})


return DataType
