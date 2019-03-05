---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ChainableSubMethodsClass = require("LuaORM/Util/Class/ChainableSubMethodsClass")
local Equation = require("LuaORM/Query/Condition/Equation")
local Type = require("LuaORM/Util/Type/Type")

---
-- Represents a condition.
-- A condition is a list of equations.
--
-- @type Condition
--
local Condition = {}


---
-- The parent clause
--
-- @tfield Clause parentClause
--
Condition.parentClause = nil

---
-- The list of equations
--
-- @tfield Equation[] equations
--
Condition.equations = nil

---
-- The current equation
--
-- @tfield Equation currentEquation
--
Condition.currentEquation = nil


-- Metamethods

---
-- Condition constructor.
-- This is the __call metamethod.
--
-- @tparam Clause _parentClause The parent clause
--
-- @treturn Condition The Condition instance
--
function Condition:__construct(_parentClause)

  local instance = ChainableSubMethodsClass(Condition)
  instance.parentClause = _parentClause
  instance.equations = {}
  instance.currentEquation = Equation(instance)

  return instance

end


-- Getters and Setters

---
-- Returns the parent clause.
--
-- @treturn Clause The parent clause
--
function Condition:getParentClause()
  return self.parentClause
end

---
-- Returns the Equation's of this Condition.
--
-- @treturn Equation[] The Equation's of this Condition
--
function Condition:getEquations()
  return self.equations
end

---
-- Returns the Condition's current Equation.
--
-- @treturn Equation|nil The current Equation or nil if there is no Equation yet
--
function Condition:getCurrentEquation()
  return self.currentEquation
end


-- Public Methods

---
-- Adds a new empty Equation to this Condition.
--
function Condition:addNewEquation()

  local equation = Equation(self)

  self.currentEquation = equation
  table.insert(self.equations, equation)

end

---
-- Returns all Equations of this Condition that are not empty.
--
-- @treturn Equation[] The Equations that are not empty
--
function Condition:getNonEmptyEquations()

  local equations = {}
  for _, equation in ipairs(self.equations) do
    if (not equation:isEmpty()) then
      table.insert(equations, equation)
    end
  end

  return equations

end

---
-- Returns whether this Condition is empty.
--
-- @treturn bool True if this Condition is empty, false otherwise
--
function Condition:isEmpty()
  return (#self:getNonEmptyEquations() == 0)
end

---
-- Returns whether this Condition is valid.
--
-- @treturn bool True if this Condition is valid, false otherwise
--
function Condition:isValid()

  if (self:isEmpty()) then
    return false

  else

    -- Check whether the equations are valid
    for _, equation in ipairs(self:getNonEmptyEquations()) do
      if (not equation:isValid()) then
        return false
      end
    end

    return true

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
function Condition:getValueForUnknownIndex(_methodName)

  if (self.currentEquation == nil) then
    self:addNewEquation()
  end

  local currentEquationFunction = self.currentEquation[_methodName]
  if (currentEquationFunction ~= nil and Type.isFunction(currentEquationFunction)) then
    return currentEquationFunction, self.currentEquation
  end

end


setmetatable(
  Condition,
  {
    -- Condition inherits methods and attributes from ChainableSubMethodsClass
    __index = ChainableSubMethodsClass,

    -- When Condition() is called, call the __construct() method
    __call = Condition.__construct
  }
)


return Condition
