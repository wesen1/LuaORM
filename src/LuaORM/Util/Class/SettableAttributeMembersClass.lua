---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local GettableAttributeMembersClass = require("LuaORM/Util/Class/GettableAttributeMembersClass")

---
-- Base class for classes that allow setting and getting the values of attribute members.
-- Inheriting classes must not overwrite the __index or __newindex metamethod of the instances.
--
-- @type SettableAttributeMembersClass
--
local SettableAttributeMembersClass = {}


---
-- The names of the attributes that are searched for members to set
--
-- @tfield string[] settableAttributeNames
--
SettableAttributeMembersClass.settableAttributeNames = {}


-- Metamethods

---
-- Sets the value of a attribute member by its name.
-- This is the __newindex metamethod for instances.
--
-- @tparam string _attributeMemberName The name of the attribute member
-- @tparam mixed _value The value to set the attribute member to
--
function SettableAttributeMembersClass:setAttributeMemberValueByName(_attributeMemberName, _value)

  for _, attributeName in ipairs(self.settableAttributeNames) do
    if (self[attributeName][_attributeMemberName] ~= nil) then
      self:setAttributeMemberValue(attributeName, _attributeMemberName, _value)
      return
    end
  end

  self:setValueForUnknownAttributeMember(_attributeMemberName, _value)

end


-- Protected Methods

---
-- Enables the settable behaviour.
--
function SettableAttributeMembersClass:enableSettableBehaviour()
  getmetatable(self).__newindex = self.parentClass.setAttributeMemberValueByName
end

---
-- Disables the settable behaviour.
--
function SettableAttributeMembersClass:disableSettableBehaviour()
  getmetatable(self).__newindex = nil
end

---
-- Sets the value for a specific attribute member.
--
-- @tparam string _attributeName The name of the attribute that contains the attribute member
-- @tparam mixed _attributeMemberName The name of the attribute member
-- @tparam mixed _value The value to set the attribute member to
--
function SettableAttributeMembersClass:setAttributeMemberValue(_attributeName, _attributeMemberName, _value)
end

---
-- Sets the value for a attribute member that was not found in the list of settable attributes.
--
-- @tparam string _attributeMemberName The name of the attribute member
-- @tparam mixed _value The value to set the attribute member to
--
function SettableAttributeMembersClass:setValueForUnknownAttributeMember(_attributeMemberName, _value)
end


setmetatable(
  SettableAttributeMembersClass,
  {
    -- SettableAttributeMembersClass inherits from GettableAttributeMembersClass
    __index = GettableAttributeMembersClass,

    -- When SettableAttributeMembersClass() is called, call the GettableAttributeMembersClass.__construct() method
    __call = GettableAttributeMembersClass.__construct
  }
)


return SettableAttributeMembersClass
