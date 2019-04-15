---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Clause = require("LuaORM/Query/Clause")
local OrderByRule = require("LuaORM/Query/Clause/OrderBy/OrderByRule")
local Type = require("LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- Represents a ORDER BY clause.
--
-- @type OrderBy
--
local OrderBy = {}


---
-- Static list of order types
--
-- @tfield int[] orderTypes
--
OrderBy.orderTypes = {
  ASC = 1,
  DESC = 2
}

---
-- The default order type
--
-- @tfield int defaulOrderType
--
OrderBy.defaulOrderType = OrderBy.orderTypes.ASC

---
-- The list of OrderByRule's
--
-- @tfield OrderByRule[] rules
--
OrderBy.rules = nil

---
-- The current OrderByRule
--
-- @tfield OrderByRule currentRule
--
OrderBy.currentRule = nil

---
-- The names of the attributes that will be searched for sub fields to return
--
-- @tfield string[] gettableAttributeNames
--
OrderBy.gettableAttributeNames = { "currentRule" }


-- Metamethods

---
-- OrderBy constructor.
-- This is the __call metamethod.
--
-- @tparam Query _parentQuery The parent query
--
-- @treturn OrderBy The OrderBy instance
--
function OrderBy:__construct(_parentQuery)

  local instance = Clause(_parentQuery, OrderBy)
  instance.rules = {}

  return instance

end


-- Getters and Setters

---
-- Returns the OrderByRule's of this OrderBy clause.
--
-- @treturn OrderByRule[] The OrderByRule's of this OrderBy clause
--
function OrderBy:getRules()
  return self.rules
end


-- Public Methods

---
-- Adds a new rule to this OrderBy clause.
--
-- @tparam string[] _targetNames The list of target names
--
function OrderBy:addNewRule(_targetNames)
  self:addRule(Type.toTable(_targetNames))
  self.parentQuery:setCurrentClause(self)
end

---
-- Checks whether a method name is a dynamic function call for this Clause ("orderBy<columnName>").
--
-- @tparam string _methodName The method name to check
--
-- @treturn function|nil The generated function or nil if the method name is no dynamic function call for this Clause
--
function OrderBy:getDynamicFunctionByMethodName(_methodName)

  local orderByColumnName = _methodName:match("^orderBy(.+)$")
  if (orderByColumnName ~= nil) then

    orderByColumnName = self:convertDynamicFunctionTargetName(orderByColumnName)
    self:addRule({ orderByColumnName })

    return function() end
  end

end

---
-- Returns whether this Clause is empty.
--
-- @treturn bool True if this Clause is empty, false otherwise
--
function OrderBy:isEmpty()
  return (#self.rules == 0)
end

---
-- Returns whether this Clause is valid.
--
-- @treturn bool True if this Clause is valid, false otherwise
--
function OrderBy:isValid()

  for _, rule in ipairs(self.rules) do
    if (not rule:isValid()) then
      return false
    end
  end

  return true

end


-- Private Methods

---
-- Adds a new OrderByRule to this OrderBy clause.
--
-- @tparam string[] _targetNames The list of target names
--
function OrderBy:addRule(_targetNames)

  local targets = self.parentQuery:getTargetsByNames(_targetNames)
  if (#targets == 0) then
    API.ORM:getLogger():warn("Cannot add order by rule: List of columns is empty")
  else
    self.currentRule = OrderByRule(self, targets, self.defaulOrderType)
    table.insert(self.rules, self.currentRule)
  end

end


setmetatable(
  OrderBy,
  {
    -- OrderBy inherits methods and attributes from Clause
    __index = Clause,

    -- When OrderBy() is called, call the __construct() method
    __call = OrderBy.__construct
  }
)


return OrderBy
