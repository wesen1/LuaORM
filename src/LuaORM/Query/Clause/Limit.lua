---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Clause = require("LuaORM/Query/Clause")
local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local Type = require("LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- Represents a LIMIT clause.
--
-- @type Limit
--
local Limit = {}


---
-- The limit settings
-- Using a settings table to avoid duplicate indexes (e.g. "offset" attribute and method name)
--
-- @type int[] settings
--
Limit.settings = {

  ---
  -- The maximum number of data rows to fetch
  --
  -- @tfield int limit
  --
  limit = nil,

  ---
  -- The offset
  --
  -- @tfield int offset
  --
  offset = nil
}


-- Metamethods

---
-- Limit constructor.
-- This is the __call metamethod.
--
-- @tparam Query _parentQuery The parent query
--
-- @treturn Limit The Limit instance
--
function Limit:__construct(_parentQuery)

  local instance = Clause(_parentQuery, Limit)
  instance.settings = ObjectUtils.clone(Limit.settings)

  return instance

end


-- Getters and Setters

---
-- Returns the settings of the LIMIT clause.
--
-- @treturn table The settings of this Limit clause
--
function Limit:getSettings()
  return self.settings
end


-- API

---
-- Sets the limit of this Limit clause.
--
-- @tparam int _limit The maximum number of data rows to fetch
--
function Limit:limit(_limit)

  if (Type.isInteger(_limit)) then
    self.settings.limit = _limit
  else
    API.ORM:getLogger():warn("Invalid query limit specified: '" .. Type.toString(_limit) .. "'")
  end

end

---
-- Sets the offset.
--
-- @tparam int _offset The offset
--
function Limit:offset(_offset)

  if (Type.isInteger(_offset)) then
    self.settings.offset = _offset
  else
    API.ORM:getLogger():warn("Invalid query offset specified: '" .. Type.toString(_offset) .. "'")
  end

end


-- Public Methods

---
-- Sets the limit of this Limit clause and updates the parent Query's current clause.
--
-- @tparam int _limit The limit
--
function Limit:addNewRule(_limit)
  self:limit(_limit)
  self.parentQuery:setCurrentClause(self)
end

---
-- Returns whether this Clause is empty.
--
-- @treturn bool True if this Clause is empty, false otherwise
--
function Limit:isEmpty()
  return (self.settings.limit == nil and self.settings.offset == nil)
end

---
-- Returns whether this Clause is valid.
--
-- @treturn bool True if this Clause is valid, false otherwise
--
function Limit:isValid()
  return (self.settings.limit ~= nil)
end

---
-- Checks whether a method name is a dynamic function call for this Clause.
--
-- @tparam string _methodName The method name to check
--
-- @treturn function|nil The generated function or nil if the method name is no dynamic function call for this Clause
--
function Limit:getDynamicFunctionByMethodName(_methodName)

  -- Allow the use of offset() without a previous limit() call
  -- This is done for the case that findOne() is used to finish the query
  if (_methodName == "offset") then

    return function(_self, _offset)
      self:offset(_offset)
    end

  end

end


setmetatable(
  Limit,
  {
    -- Limit inherits methods and attributes from Clause
    __index = Clause,

    -- When Limit() is called, call the __construct() method
    __call = Limit.__construct
  }
)


return Limit
