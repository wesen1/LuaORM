---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local SettableAttributeMembersClass= require("src/LuaORM/Util/Class/SettableAttributeMembersClass")
local SettingValue = require("src/LuaORM/Util/SettingValueList/SettingValue")
local Type = require("src/LuaORM/Util/Type/Type")

---
-- Stores a list of SettingValue's and provides methods to parse raw data into the SettingValue's.
--
-- @type SettingValueList
--
local SettingValueList = {}


---
-- The list of SettingValue's
--
-- @tfield SettingValue[] settingValues
--
SettingValueList.settingValues = {}


-- Metamethods

---
-- SettingValueList constructor.
-- This is the __call metamethod.
--
-- @tparam table ... The SettingValue configurations (optional number of arguments)
--
-- @treturn SettingValueList The SettingValueList instance
--
function SettingValueList:__construct(...)

  local instance = SettableAttributeMembersClass(SettingValueList)

  instance:initializeSettingValues({...})
  instance:enableSettableBehaviour()

  return instance

end

---
-- Sets the value of a SettingValue by the its name.
-- This is the __newindex metamethod for instances.
--
-- @tparam mixed _settingValueName The SettingValue's name
-- @tparam mixed _value The value
--
function SettingValueList:setValueForUnknownAttributeMember(_settingValueName, _value)

  local settingValue = self.settingValues[Type.toString(_settingValueName)]
  if (settingValue ~= nil) then
    settingValue:changeValue(_value)
  end

end


-- Protected

---
-- Returns the value for table indexes that were not found in the parent class and the gettable attributes.
--
-- @tparam mixed _indexName The index name
--
-- @treturn mixed The return value for the index name
--
function SettingValueList:getValueForUnknownIndex(_indexName)

  local settingValue = self.settingValues[Type.toString(_indexName)]
  if (settingValue ~= nil) then
    return settingValue:getCurrentValue()
  end

end


-- Public Methods

---
-- Parses a list of raw settings into the SettingValue's.
-- The list must be in the format { [settingName] = value, ... }.
--
-- @tparam mixed[] _settings The raw settings
--
function SettingValueList:parse(_settings)

  if (not _settings) then
    return
  end

  local settings = Type.toTable(_settings)

  for settingValueName, settingValue in pairs(self.settingValues) do

    local value = settings[settingValueName]
    if (value ~= nil) then
      settingValue:changeValue(value)
    end

  end

end

---
-- Checks whether all SettingValue's inside this SettingValueList are valid.
--
-- @treturn bool True if all SettingValue's are valid, false otherwise
--
function SettingValueList:isValid()

  for _, settingValue in pairs(self.settingValues) do
    if (not settingValue:isValid()) then
      return false
    end
  end

  return true

end


-- Private Methods

---
-- Initializes the SettingValue's.
--
-- @tparam table _settingValueConfigurations The SettingValue configurations
--
function SettingValueList:initializeSettingValues(_settingValueConfigurations)

  self.settingValues = {}

  for _, settingValueConfiguration in ipairs(_settingValueConfigurations) do

    local settingValue = SettingValue(
      settingValueConfiguration["dataType"],
      settingValueConfiguration["defaultValue"],
      settingValueConfiguration["mustBeSet"]
    )

    self.settingValues[settingValueConfiguration["name"]] = settingValue

  end

end


setmetatable(
  SettingValueList,
  {
    -- SettingValueList inherits from SettableAttributeMembersClass
    __index = SettableAttributeMembersClass,

    -- When SettingValueList() is called, call the __construct() method
    __call = SettingValueList.__construct
  }
)


return SettingValueList
