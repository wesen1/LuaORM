---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ChainableSubMethodsClass = require("LuaORM/Util/Class/ChainableSubMethodsClass")

---
-- Represents a query clause (Where, OrderBy, GroupBy, etc.).
--
-- @type Clause
--
local Clause = {}


---
-- The parent Query
--
-- @tfield Query parentQuery
--
Clause.parentQuery = nil


-- Metamethods

---
-- Clause constructor.
-- This is the __call metamethod.
--
-- @tparam Query _parentQuery The parent Query
-- @tparam Clause _instanceParentClass The parent class for instances
--
-- @treturn Clause The Clause instance
--
function Clause:__construct(_parentQuery, _instanceParentClass)

  local instanceParentClass = _instanceParentClass
  if (not instanceParentClass) then
    instanceParentClass = Clause
  end
  local instance = ChainableSubMethodsClass(instanceParentClass)

  instance.parentQuery = _parentQuery

  return instance

end


--- Getters and Setters

---
-- Returns the Clause's parent Query.
--
-- @treturn Query The Clause's parent Query
--
function Clause:getParentQuery()
  return self.parentQuery
end


-- Public Methods

---
-- Adds a new rule to this clause.
--
function Clause:addNewRule()
end

---
-- Returns a dynamic function for this Clause based on a method name.
-- Examples are filterBy<columnName>, join<tableName>, etc.
--
-- @tparam string _methodName The method name
--
-- @treturn function|nil The generated function or nil if the method name is no dynamic function call for this Clause
--
function Clause:getDynamicFunctionByMethodName(_methodName)
end

---
-- Returns whether this Clause is empty.
--
-- @treturn bool True if this Clause is empty, false otherwise
--
function Clause:isEmpty()
  return true
end

---
-- Returns whether this Clause is valid.
--
-- @treturn bool True if this Clause is valid, false otherwise
--
function Clause:isValid()
  return true
end


setmetatable(
  Clause,
  {
    -- Clause inherits from ChainableSubMethodsClass
    __index = ChainableSubMethodsClass,

    -- When Clause() is called, call the __construct() method
    __call = Clause.__construct
  }
)

return Clause
