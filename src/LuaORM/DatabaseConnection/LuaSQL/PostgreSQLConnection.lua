---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local LuaSQLConnection = require("src/LuaORM/DatabaseConnection/LuaSQLConnection")

---
-- DatabaseConnection for luasql.postgres.
--
-- @type PostgreSQLConnection
--
local PostgreSQLConnection = {}


---
-- Defines whether this LuaSQLConnection supports the connect:escape() method
--
-- @tfield bool supportsEscapeMethod
--
PostgreSQLConnection.supportsEscapeMethod = true


-- Metamethods

---
-- PostgreSQLConnection constructor.
-- This is the __call metamethod.
--
-- @tparam mixed[] _databaseConfiguration The database configuration
--
-- @treturn PostgreSQLConnection The PostgreSQLConnection instance
--
function LuaSQLConnection:__construct(_databaseConfiguration)

  --TODO: Implement PostgreSQLDatabaseLanguage
  local instance = LuaSQLConnection(_databaseConfiguration, nil)
  setmetatable(instance, {__index = PostgreSQLConnection})

  return instance

end


-- Protected Methods

---
-- Returns the LuaSQL environment object.
--
-- @treturn Environment The LuaSQL environment object
--
function PostgreSQLConnection:getEnvironment()
  local luasql = require("luasql.postgres")
  return luasql.postgres()
end

---
-- Returns the LuaSQL connection object by using the settings to connect to the database.
--
-- @treturn Connection The LuaSQL connection object
--
function PostgreSQLConnection:getConnection()

  return self.environment:connect(
    self.settings["databaseName"],
    self.settings["userName"],
    self.settings["password"],
    self.settings["host"],
    self.settings["portNumber"]
  )

end


setmetatable(
  PostgreSQLConnection,
  {
    -- PostgreSQLConnection inherits methods and attributes from LuaSQLConnection
    __index = LuaSQLConnection,

    -- When PostgreSQLConnection() is called, call the __construct() method
    __call = PostgreSQLConnection.__construct
  }
)


return PostgreSQLConnection
