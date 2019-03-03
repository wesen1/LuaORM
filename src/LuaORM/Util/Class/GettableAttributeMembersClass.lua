---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local TableUtils = require("src/LuaORM/Util/TableUtils")
local Type = require("src/LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- Base class for classes that allow getting the values of attribute members.
-- Inheriting classes must not change the __index metamethod of the instances.
--
-- @type GettableAttributeMembersClass
--
local GettableAttributeMembersClass = {}


---
-- The names of the attributes that will be searched for members to return
--
-- @tfield string[] gettableAttributeNames
--
GettableAttributeMembersClass.gettableAttributeNames = {}

---
-- The "real" parent class of child classes
--
-- @tfield table parentClass
--
GettableAttributeMembersClass.parentClass = {}


-- Metamethods

---
-- GettableAttributeMembersClass constructor.
-- This is the __call metamethod.
--
-- @tparam table _parentClass The parent class
--
-- @treturn GettableAttributeMembersClass The GettableAttributeMembersClass instance
--
function GettableAttributeMembersClass:__construct(_parentClass)

  local instance = {}
  instance.parentClass = _parentClass

  setmetatable(instance, {__index = _parentClass.getAttributeMemberValueByName})

  return instance

end

---
-- Returns values for unknown table indexes.
-- This is the __index metamethod for instances.
--
-- @tparam mixed _attributeMemberName The attribute member name
--
-- @treturn mixed The return value for the attribute member name
--
function GettableAttributeMembersClass:getAttributeMemberValueByName(_attributeMemberName)

  -- Must check if the parent class contains the attribute to keep the original class/instance logic
  local parentClassMember = self.parentClass[_attributeMemberName]
  if (parentClassMember == nil) then

    local attribute = self:getAttributeContainingMemberWithName(_attributeMemberName)
    if (attribute == nil) then
      return self:getValueForUnknownIndex(_attributeMemberName)
    else
      return attribute[_attributeMemberName]
    end

  else
    return parentClassMember
  end

end


-- Protected Methods

---
-- Returns the value for table indexes that were not found in the parent class and the gettable attributes.
--
-- @tparam mixed _indexName The index name
--
-- @treturn mixed The return value for the index name
--
function GettableAttributeMembersClass:getValueForUnknownIndex(_indexName)
  API.logger:warn("Unknown attribute: Ignoring '" .. Type.toString(_indexName) .. "' index")
end

---
-- Returns the first gettable attribute that contains a member with a specific name.
--
-- @tparam mixed _attributeMemberName The attribute member name
--
-- @treturn mixed|nil The attribute or nil if no attribute contains a member with the specified name
--
function GettableAttributeMembersClass:getAttributeContainingMemberWithName(_attributeMemberName)

  for _, attributeName in ipairs(self.gettableAttributeNames) do

    -- Check that the instance contains the attribute to avoid a stack overflow
    if (TableUtils.tableHasIndex(self, attributeName)) then

      local attribute = self[attributeName]
      if (attribute[_attributeMemberName] ~= nil) then
        return attribute
      end

    end
  end

end


-- When GettableAttributeMembersClass() is called, call the __construct() method
setmetatable(GettableAttributeMembersClass, {__call = GettableAttributeMembersClass.__construct})


return GettableAttributeMembersClass
