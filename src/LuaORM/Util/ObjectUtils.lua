---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Type = require("src/LuaORM/Util/Type/Type")

---
-- Provides static object related util functions.
--
-- @type ObjectUtils
--
local ObjectUtils = {}


-- Public Methods

---
-- Returns a clone of an object.
--
-- This function is based on the copy3 function from tylerneylon
-- @see https://gist.github.com/tylerneylon/81333721109155b2d244
--
-- @tparam table _object The object
-- @tparam table _clonedObjects The list of already cloned sub objects
--
-- @treturn table The clone of the table
--
function ObjectUtils.clone(_object, _clonedObjects)

  -- If the object is not a table, return the raw data (number, string, bool, etc.)
  if (not Type.isTable(_object)) then
    return _object
  end


  -- Initialize the list of already cloned objects
  local clonedObjects
  if (_clonedObjects) then
    clonedObjects = _clonedObjects
  else
    clonedObjects = {}
  end

  -- If the object was already cloned in another cycle of this method, return the already cloned object
  if (clonedObjects[_object]) then
    return clonedObjects[_object]
  end


  -- Clone the object

  -- Create an empty object
  local clonedObject = {}

  -- Add the new cloned object to the list of already cloned objects
  clonedObjects[_object] = clonedObject

  -- Iterate over all properties of the object
  for propertyIndex, propertyValue in pairs(_object) do

    local clonedPropertyIndex = ObjectUtils.clone(propertyIndex, clonedObjects)
    local clonedPropertyValue = ObjectUtils.clone(propertyValue, clonedObjects)

    clonedObject[clonedPropertyIndex] = clonedPropertyValue

  end

  -- Copy the meta table of the target object
  setmetatable(clonedObject, getmetatable(_object))

  return clonedObject

end

---
-- Returns whether an object is an instance of a class or one of its subclasses.
--
-- @tparam table _object The object
-- @tparam table|string _class The class table or the class require string
--
-- @treturn bool True if the object is an instance of the class or one of its subclasses, false otherwise
--
function ObjectUtils.isInstanceOf(_object, _class)

  local class
  if (Type.isString(_class)) then
    class = require(_class)
  else
    class = _class
  end

  if (_object == class) then
    return true
  end

  -- Check the parentClass attribute
  -- This is used in classes that extend GettableAttributeMembersClass
  local parentClass = _object.parentClass
  if (parentClass ~= nil and ObjectUtils.isInstanceOf(parentClass, class)) then
    return true
  end

  -- Check the meta tables __index field
  local metaTable = getmetatable(_object)
  if (metaTable == nil) then
    return false
  else
    parentClass = metaTable.__index
    return ObjectUtils.isInstanceOf(parentClass, class)
  end

end


return ObjectUtils
