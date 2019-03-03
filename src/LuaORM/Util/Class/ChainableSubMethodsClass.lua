---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local GettableAttributeMembersClass = require("src/LuaORM/Util/Class/GettableAttributeMembersClass")
local Type = require("src/LuaORM/Util/Type/Type")
local unpack = unpack or table.unpack

---
-- Base class for classes that allow chaining of methods of members.
-- Inheriting classes must not change the __index metamethod of the instances.
--
-- @type ChainableSubMethodsClass
--
local ChainableSubMethodsClass = {}


-- Metamethods

---
-- Returns a function that executes code based on the index name and returns the class instance.
-- This is the __index metamethod for instances.
--
-- @tparam mixed _attributeMemberName The attribute member name
--
-- @treturn function|mixed The return value for the attribute member name
--
function ChainableSubMethodsClass:getAttributeMemberValueByName(_attributeMemberName)

  -- Check if the parent class contains a member with the attribute member name
  local member = self.parentClass[_attributeMemberName]
  local isParentClassMember = (member ~= nil)

  local methodSelf

  if (isParentClassMember) then
    methodSelf = self
  else

    -- Check if the gettable attributes contain a member with the attribute member name
    local attribute = self:getAttributeContainingMemberWithName(_attributeMemberName)
    if (attribute == nil) then
      member, methodSelf = self:getValueForUnknownIndex(_attributeMemberName)
    else
      member = attribute[_attributeMemberName]
      methodSelf = attribute
    end

  end


  if (Type.isFunction(member)) then

    -- Must return a function in order to get the arguments to pass them to the method ("...")
    return function(_self, ...)

      local returnValues = { member(methodSelf, ...) }

      if (isParentClassMember) then
        return unpack(returnValues)
      else
        return _self
      end
    end

  else
    return member
  end

end


-- Protected Methods

---
-- Returns the function for an unknown sub method.
--
-- @tparam string _methodName The method name
--
-- @treturn function|mixed The function to execute or a value to return
-- @treturn object The object that will be passed as "self" to the function
--
function ChainableSubMethodsClass:getValueForUnknownIndex(_methodName)
end


setmetatable(
  ChainableSubMethodsClass,
  {
    -- ChainableSubMethodsClass inherits from GettableAttributeMembersClass
    __index = GettableAttributeMembersClass,

    -- When ChainableSubMethodsClass() is called, call the GettableAttributeMembersClass.__construct() method
    __call = GettableAttributeMembersClass.__construct
  }
)


return ChainableSubMethodsClass
