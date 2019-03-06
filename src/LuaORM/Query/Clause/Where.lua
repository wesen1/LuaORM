---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ConditionClause = require("LuaORM/Query/ConditionClause")
local Condition = require("LuaORM/Query/Condition/Condition")
local Type = require("LuaORM/Util/Type/Type")

---
-- Represents a WHERE clause.
--
-- @type Where
--
local Where = {}


-- Metamethods

---
-- Where constructor.
-- This is the __call metamethod.
--
-- @tparam Query _parentQuery The parent query
--
-- @treturn Where The Where instance
--
function Where:__construct(_parentQuery)

  local instance = ConditionClause(_parentQuery, Where)
  instance.condition = Condition(instance)

  return instance

end


-- Public Methods

---
-- Adds a equation to this Where clause.
--
-- @tparam mixed|nil _conditionSettings The list of condition settings (optional)
--
function Where:addNewRule(_conditionSettings)

  self.condition:addNewEquation()
  self.parentQuery:setCurrentClause(self)

  if (Type.isTable(_conditionSettings)) then
    self.condition:parseConditionSettings(_conditionSettings)
  end

end

---
-- Checks whether a method name is a dynamic function call for this Clause ("filterBy<columnName>").
--
-- @tparam string _methodName The method name to check
--
-- @treturn function|nil The generated function or nil if the method name is no dynamic function call for this Clause
--
function Where:getDynamicFunctionByMethodName(_methodName)

  local filterByColumnName = _methodName:match("^filterBy(.+)$")
  if (filterByColumnName ~= nil) then

    filterByColumnName = self:convertDynamicFunctionTargetName(filterByColumnName)

    return function(_self, _value)
      self.condition:AND():column(filterByColumnName):equals(_value)
    end

  end

end

---
-- Returns whether this Clause is empty.
--
-- @treturn bool True if this Clause is empty, false otherwise
--
function Where:isEmpty()
  return self.condition:isEmpty()
end

---
-- Returns whether this Where clause is valid.
--
-- @treturn bool True if this Where clause is valid, false otherwise
--
function Where:isValid()
  return self.condition:isValid()
end


setmetatable(
  Where,
  {
    -- Where inherits methods and attributes from ConditionClause
    __index = ConditionClause,

    -- When Where() is called, call the __construct() method
    __call = Where.__construct
  }
)


return Where
