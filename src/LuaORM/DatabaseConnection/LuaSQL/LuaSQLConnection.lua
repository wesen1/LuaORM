---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local BaseDatabaseConnection = require("LuaORM/DatabaseConnection/BaseDatabaseConnection")
local LuaSQLCursor = require("LuaORM/DatabaseConnection/LuaSQL/LuaSQLCursor")
local Type = require("LuaORM/Util/Type/Type")

---
-- Defines attributes and methods that are shared across all LuaSQL DatabaseConnection types.
--
-- @type LuaSQLConnection
--
local LuaSQLConnection = {}


---
-- The LuaSQL environment object that is created by calling require("luasql.<sqltype>")
--
-- @tfield Environment environment
--
LuaSQLConnection.environment = nil

---
-- The LuaSQL connection object that is created by luasql:connect()
--
-- @tfield Connection connection
--
LuaSQLConnection.connection = nil

---
-- Defines whether this LuaSQLConnection supports the connect:escape() method (Must be set by child classes)
--
-- @tfield bool supportsEscapeMethod
--
LuaSQLConnection.supportsEscapeMethod = false

---
-- Stores the number of rows that were affected by the last succesful query
--
-- @tfield int numberOfRowsAffectedByLastQuery
--
LuaSQLConnection.numberOfRowsAffectedByLastQuery = nil


-- Public Methods

---
-- Initializes the database connection.
--
-- @treturn bool True if the connection was successfully initialized, false otherwise
--
-- @raise Error when the connection could not be established
--
function LuaSQLConnection:initializeConnection()

  self.environment = self:getEnvironment()

  self.connection = self:getConnection()
  if (not self.connection) then
    error("Could not connect to the database")
  end

end

---
-- Returns the number of rows that were affected by the last query.
--
-- @treturn int The number of rows that were affected by the last query
--
function LuaSQLConnection:getNumberOfRowsAffectedByLastQuery()
  return self.numberOfRowsAffectedByLastQuery
end

---
-- Escapes a string before using it in a query to avoid SQL injection.
-- Only string values can potentially inject SQL, therefore only these values should be passed to this method.
--
-- @tparam string _string The string to escape
--
-- @treturn string The escaped string
--
function LuaSQLConnection:escapeString(_string)

  -- @see https://keplerproject.github.io/luasql/manual.html for a list of
  -- database drivers that support this method
  if (self.supportsEscapeMethod) then
    return self.connection:escape(_string)
  else
    return BaseDatabaseConnection.escapeString(self, _string)
  end

end


-- Protected Methods

---
-- Executes a query and returns the result.
--
-- @tparam string _query The query
--
-- @treturn Cursor|int|nil The LuaSQL cursor or the number of affected rows or nil if there was an error
--
function LuaSQLConnection:executeQuery(_query)
  return self.connection:execute(_query)
end

---
-- Returns whether a query result is valid.
--
-- @tparam Cursor|int|nil _queryResult The raw query result
--
-- @treturn bool True if the query result is valid, false otherwise
--
function LuaSQLConnection:isQueryResultValid(_queryResult)
  return (_queryResult ~= nil)
end

---
-- Parses a raw query result and returns a Cursor to fetch the result rows.
--
-- @tparam Cursor|int _queryResult The raw query result
--
-- @treturn LuaSQLCursor The Cursor to fetch the result rows
--
function LuaSQLConnection:parseQueryResult(_queryResult)

  if (Type.isInteger(_queryResult)) then
    self.numberOfRowsAffectedByLastQuery = _queryResult
    return LuaSQLCursor()
  else
    self.numberOfRowsAffectedByLastQuery = 0
    return LuaSQLCursor(_queryResult)
  end

end


-- Protected Methods

---
-- Returns the LuaSQL environment object.
--
-- @treturn Environment The LuaSQL environment object
--
function LuaSQLConnection:getEnvironment()
end

---
-- Returns the LuaSQL connection object by using the settings to connect to the database.
--
-- @treturn Connection The LuaSQL connection object
--
function LuaSQLConnection:getConnection()
end

---
--
-- Closes the database connection
--
-- @treturn bool The result of closing the connection. True for success, false for failure.
--
function LuaSQLConnection:close()
  return self.connection:close()
end

setmetatable(
  LuaSQLConnection,
  {
    -- LuaSQLConnection inherits methods and attributes from BaseDatabaseConnection
    __index = BaseDatabaseConnection,

    -- When LuaSQLConnection() is called, call the BaseDatabaseConnection.__construct() method
    __call = BaseDatabaseConnection.__construct
  }
)


return LuaSQLConnection
