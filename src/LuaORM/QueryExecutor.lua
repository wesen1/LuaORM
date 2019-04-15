---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local FieldValueRowListBuilder = require("LuaORM/FieldValueRowList/FieldValueRowListBuilder")
local Query = require("LuaORM/Query/Query")
local API = LuaORM_API

---
-- Executes Query's and returns their results as FieldValueRowList's.
--
-- @type QueryExecutor
--
local QueryExecutor = {}


---
-- The FieldValueRowList builder
--
-- @tparam FieldValueRowListBuilder fieldValueRowListBuilder
--
QueryExecutor.fieldValueRowListBuilder = nil


-- Metamethods

---
-- QueryExecutor constructor.
-- This is the __call metamethod.
--
-- @treturn QueryExecutor The QueryExecutor instance
--
function QueryExecutor:__construct()

  local instance = setmetatable({}, {__index = QueryExecutor})
  instance.fieldValueRowListBuilder = FieldValueRowListBuilder()

  return instance

end


-- Public Methods

---
-- Executes a Query and returns its result as a FieldValueRowList if it was a SELECT query.
--
-- @tparam Query _query The query
--
-- @treturn FieldValueRowList|nil|bool The result or false if the query was not valid
--
function QueryExecutor:execute(_query)

  if (_query:isValid()) then

    local databaseConnection = API.ORM:getDatabaseConnection()

    local queryString = databaseConnection:getDatabaseLanguage():translateQuery(_query)
    local cursor = databaseConnection:execute(queryString)

    if (_query:getType() == Query.types.SELECT) then

      -- Parse the result
      return self.fieldValueRowListBuilder:parseQueryResult(
        cursor:fetchAll(), _query:getTargetTable(), _query:getUsedTables()
      )

    end

  else
    return false
  end

end


-- When QueryExecutor() is called, call the __construct method
setmetatable(QueryExecutor, {__call = QueryExecutor.__construct})


return QueryExecutor
