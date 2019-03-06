---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Clause = require("LuaORM/Query/Clause")

---
-- Base class for clauses that contain a Condition and allow chaining of Condition methods.
--
-- @type ConditionClause
--
local ConditionClause = {}


---
-- The condition
--
-- @tfield Condition condition
--
ConditionClause.condition = nil

---
-- The names of the attributes that will be searched for sub fields to return
--
-- @tfield string[] gettableAttributeNames
--
ConditionClause.gettableAttributeNames = { "condition" }


-- Getters and Setters

---
-- Returns the condition.
--
-- @treturn Condition The condition
--
function ConditionClause:getCondition()
  return self.condition
end


setmetatable(
  ConditionClause,
  {
    -- ConditionClause inherits methods and attributes from Clause
    __index = Clause,

    -- When ConditionClause() is called, call the Clause.__construct() method
    __call = Clause.__construct
  }
)


return ConditionClause
