---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- Stores one rule for a ORDER BY clause.
-- This includes a target list and a order type.
--
-- @type OrderByRule
--
local OrderByRule = {}


---
-- The list of targets
--
-- @tfield TableColumn[]|SelectRule[] targets
--
OrderByRule.targets = nil

---
-- The order type
--
-- @tfield int orderType
--
OrderByRule.orderType = nil

---
-- The parent OrderBy Clause
--
-- @tfield OrderBy parentOrderByClause
--
OrderByRule.parentOrderByClause = nil


-- Metamethods

---
-- OrderByRule constructor.
-- This is the __call metamethod.
--
-- @tparam OrderBy _parentOrderByClause The parent OrderBy Clause
-- @tparam TableColumn[]|SelectRule[] _targets The list of targets
-- @tparam int _orderTypeId The order type id
--
-- @treturn OrderByRule The OrderByRule instance
--
function OrderByRule:__construct(_parentOrderByClause, _targets, _orderTypeId)

  local instance = setmetatable({}, {__index = OrderByRule})

  instance.parentOrderByClause = _parentOrderByClause
  instance.targets = _targets
  instance.orderType = _orderTypeId

  return instance

end


-- Getters and Setters

---
-- Returns the columns.
--
-- @treturn TableColumn[]|SelectRule[] The list of targets
--
function OrderByRule:getTargets()
  return self.targets
end

---
-- Returns the order type.
--
-- @treturn int The order type
--
function OrderByRule:getOrderType()
  return self.orderType
end


-- API

---
-- Sets the order type of this OrderByRule to "ascending".
--
function OrderByRule:asc()
  self.orderType = self.parentOrderByClause.orderTypes.ASC
end

---
-- Sets the order type of this OrderByRule to "descending".
--
function OrderByRule:desc()
  self.orderType = self.parentOrderByClause.orderTypes.DESC
end


-- Public Methods

---
-- Returns whether this OrderByRule is valid.
--
-- @treturn bool True if this OrderByRule is valid, false otherwise
--
function OrderByRule:isValid()
  return (#self.targets > 0 and self.orderType ~= nil)
end


-- When OrderByRule() is called, call the __construct() method
setmetatable(OrderByRule, {__call = OrderByRule.__construct})


return OrderByRule
