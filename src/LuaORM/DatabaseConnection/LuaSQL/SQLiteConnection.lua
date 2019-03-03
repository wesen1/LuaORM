---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local LuaSQLConnection = require("LuaORM/DatabaseConnection/LuaSQL/LuaSQLConnection")

---
-- DatabaseConnection for luasql.sqlite3.
--
-- @type SQLiteConnection
--
local SQLiteConnection = {}


---
-- Defines whether this LuaSQLConnection supports the connect:escape() method
--
-- @tfield bool supportsEscapeMethod
--
SQLiteConnection.supportsEscapeMethod = true


-- Metamethods

---
-- SQLiteConnection constructor.
-- This is the __call metamethod.
--
-- @tparam mixed[] _databaseConfiguration The database configuration
--
-- @treturn SQLiteConnection The SQLiteConnection instance
--
function SQLiteConnection:__construct(_databaseConfiguration)

  --TODO: Implement SQLiteDatabaseLanguage
  local instance = LuaSQLConnection(_databaseConfiguration, nil)
  setmetatable(instance, {__index = SQLiteConnection})

  return instance

end


-- Protected Methods

---
-- Returns the LuaSQL environment object.
--
-- @treturn Environment The LuaSQL environment object
--
-- @raise Error when the luasql.sqlite3 module cannot be loaded
--
function SQLiteConnection:getEnvironment()
  local luasql = require("luasql.sqlite3")
  return luasql.sqlite3()
end

---
-- Returns the LuaSQL connection object by using the settings to connect to the database.
--
-- @treturn Connection The LuaSQL connection object
--
function SQLiteConnection:getConnection()
  return self.environment:connect(self.settings["databaseName"])
end


setmetatable(
  SQLiteConnection,
  {
    -- SQLiteConnection inherits methods and attributes from LuaSQLConnection
    __index = LuaSQLConnection,

    -- When SQLiteConnection() is called, call the __construct() method
    __call = SQLiteConnection.__construct
  }
)


return SQLiteConnection
