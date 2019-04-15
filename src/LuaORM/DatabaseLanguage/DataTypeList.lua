---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local DataType = require("LuaORM/DatabaseLanguage/DataType")
local SettableAttributeMembersClass = require("LuaORM/Util/Class/SettableAttributeMembersClass")

---
-- Represents a list of available data types.
--
-- @type DataTypeList
--
local DataTypeList = {}


---
-- The list of DataType's
--
-- @tfield DataType[] dataTypes
--
DataTypeList.dataTypes = {}

---
-- The names of the attributes that will be searched for sub fields to return
--
-- @tfield string[] gettableAttributeNames
--
DataTypeList.gettableAttributeNames = { "dataTypes" }


-- Metamethods

---
-- DataTypeList constructor.
-- This is the __call metamethod.
--
-- @tparam mixed[][] _dataTypesSettings The list of DataType settings
--
-- @treturn DataTypeList The DataTypeList instance
--
function DataTypeList:__construct(_dataTypesSettings)

  local instance = SettableAttributeMembersClass(DataTypeList)

  instance.dataTypes = {}
  instance:initializeDataTypes(_dataTypesSettings)

  instance:enableSettableBehaviour()

  return instance

end


-- Protected Methods

---
-- Sets the SQL data type for a specific DataType.
--
-- @tparam string _dataTypeName The name of the DataType
-- @tparam string _type The SQL data type
--
function DataTypeList:setValueForUnknownAttributeMember(_dataTypeName, _type)

  local dataType = self.dataTypes[_dataTypeName]
  if (dataType ~= nil) then
    dataType:setType(_type)
  end

end


-- Private Methods

---
-- Initalizes the list of DataType's based on a list of DataType settings.
--
-- @tparam mixed[][] _dataTypesSettings The list of DataType settings
--
function DataTypeList:initializeDataTypes(_dataTypesSettings)
  for _, dataTypeSettings in ipairs(_dataTypesSettings) do
    self.dataTypes[dataTypeSettings["name"]] = DataType(self, dataTypeSettings)
  end
end


setmetatable(
  DataTypeList,
  {
    -- DataTypeList inherits methods and attributes from SettableAttributeMembersClass
    __index = SettableAttributeMembersClass,

    -- When DataTypeList() is called, call the __construct() method
    __call = DataTypeList.__construct
  }
)


return DataTypeList
