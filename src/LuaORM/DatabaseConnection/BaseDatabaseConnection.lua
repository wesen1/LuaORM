---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local SettingValueList = require("LuaORM/Util/SettingValueList/SettingValueList")
local API = LuaORM_API

---
-- Represents the connection to the database.
-- This class provides methods to connect to a database and to execute SQL statements.
--
-- @type BaseDatabaseConnection
--
local BaseDatabaseConnection = {}


---
-- The DatabaseLanguage that must be used for this DatabaseConnection
--
-- @tfield BaseDatabaseLanguage databaseLanguage
--
BaseDatabaseConnection.databaseLanguage = nil

--
-- The database connection configuration
--
-- @tfield SettingValueList settings
--
BaseDatabaseConnection.settings = SettingValueList(

  -- The path to the database file (SQLite) or the name of the database
  { name = "databaseName", dataType = "string" },

  -- The address (IP, URL, hostname) of the database server
  { name = "host", dataType = "string", mustBeSet = false },

  -- The port number of the database on the server
  { name = "portNumber", dataType = "integer", mustBeSet = false },

  -- The name of the database user
  { name = "userName", dataType = "string", mustBeSet = false },

  -- The password of the database user
  { name = "password", dataType = "string", mustBeSet = false }
)


-- Metamethods

---
-- BaseDatabaseConnection constructor.
-- This is the __call metamethod.
--
-- @tparam mixed[] _databaseConfiguration The database configuration
-- @tparam DatabaseLanguage _databaseLanguage The DatabaseLanguage for this DatabaseConnection
--
-- @treturn BaseDatabaseConnection The BaseDatabaseConnection instance
--
-- @raise Error when no database language is defined
--
function BaseDatabaseConnection:__construct(_databaseConfiguration, _databaseLanguage)

  local instance = setmetatable({}, {__index = BaseDatabaseConnection})

  if (_databaseLanguage == nil) then
    error("No database language defined for this DatabaseConnection")
  end

  instance.databaseLanguage = _databaseLanguage

  instance.settings = ObjectUtils.clone(BaseDatabaseConnection.settings)
  instance.settings:parse(_databaseConfiguration)

  return instance

end


-- Getters and Setters

---
-- Returns the DatabaseLanguage of this DatabaseConnection.
--
-- @treturn DatabaseLanguage The DatabaseLanguage of this DatabaseConnection
--
function BaseDatabaseConnection:getDatabaseLanguage()
  return self.databaseLanguage
end


-- Public Methods

---
-- Initializes the database connection.
--
function BaseDatabaseConnection:initialize()

  if (self.settings:isValid()) then
    return self:initializeConnection()
  else
    error("Could not initialize connection: DatabaseConnection settings are not valid")
  end

end

---
-- Executes a query string and returns a Cursor to fetch the result rows.
--
-- @tparam string _queryString The query string
--
-- @treturn BaseCursor The Cursor to fetch the result rows
--
-- @raise Error when the query string could not be executed
--
function BaseDatabaseConnection:execute(_queryString)

  API.ORM:getLogger():sql(_queryString)

  local queryResult = self:executeQuery(_queryString)
  if (self:isQueryResultValid(queryResult)) then
    return self:parseQueryResult(queryResult)
  else
    error("Could not execute query: '" .. _queryString .. "'")
  end

end

---
-- Returns the id of the last inserted record.
-- This method will return nil if that functionality is not available.
--
-- @treturn int|nil The id of the last inserted record or nil if there is no last inserted record
--
function BaseDatabaseConnection:getLastInsertId()
  return nil
end

---
-- Returns the number of rows that were affected by the last query.
-- This method will return nil if that functionality is not available.
--
-- @treturn int The number of rows that were affected by the last query
--
function BaseDatabaseConnection:getNumberOfRowsAffectedByLastQuery()
  return nil
end

---
-- Escapes a string before using it in a query to avoid SQL injection.
-- Only string values can potentially inject SQL, therefore only these values should be passed to this method.
--
-- @tparam string _string The string to escape
--
-- @treturn string The escaped string
--
function BaseDatabaseConnection:escapeString(_string)
  API.ORM:getLogger():warn("This database connection does not support string escaping")
  return _string
end


-- Protected Methods

---
-- Initializes the connection to the database.
--
function BaseDatabaseConnection:initializeConnection()
end

---
-- Executes a query and returns the raw result.
--
-- @tparam string _query The query
--
-- @treturn mixed The raw result of the query
--
function BaseDatabaseConnection:executeQuery(_query)
end

---
-- Returns whether a query result is valid.
--
-- @tparam mixed _queryResult The raw query result
--
-- @treturn bool True if the query result is valid, false otherwise
--
function BaseDatabaseConnection:isQueryResultValid(_queryResult)
end

---
-- Parses a raw query result and returns a Cursor to fetch the result rows.
--
-- @tparam mixed _queryResult The raw query result
--
-- @treturn BaseCursor The Cursor to fetch the result rows
--
function BaseDatabaseConnection:parseQueryResult(_queryResult)
end


-- When BaseDatabaseConnection() is called, call the __construct() method
setmetatable(BaseDatabaseConnection, {__call = BaseDatabaseConnection.__construct})


return BaseDatabaseConnection
