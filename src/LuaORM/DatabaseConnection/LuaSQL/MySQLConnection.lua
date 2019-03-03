---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local LuaSQLConnection = require("LuaORM/DatabaseConnection/LuaSQL/LuaSQLConnection")
local MySQLDatabaseLanguage = require("LuaORM/DatabaseLanguage/MySQL/MySQLDatabaseLanguage")

---
-- DatabaseConnection for luasql.mysql.
--
-- @type MySQLConnection
--
local MySQLConnection = {}


---
-- Defines whether this LuaSQLConnection supports the connect:escape() method
--
-- @tfield bool supportsEscapeMethod
--
MySQLConnection.supportsEscapeMethod = true


-- Metamethods

---
-- MySQLConnection constructor.
-- This is the __call metamethod.
--
-- @tparam mixed[] _databaseConfiguration The database configuration
--
-- @treturn MySQLConnection The MySQLConnection instance
--
function MySQLConnection:__construct(_databaseConfiguration)

  local instance = LuaSQLConnection(_databaseConfiguration, MySQLDatabaseLanguage())
  setmetatable(instance, {__index = MySQLConnection})

  return instance

end


-- Protected Methods

---
-- Returns the LuaSQL environment object.
--
-- @treturn Environment The LuaSQL environment object
--
-- @raise Error when the luasql.mysql module cannot be loaded
--
function MySQLConnection:getEnvironment()
  local luasql = require("luasql.mysql")
  return luasql.mysql()
end

---
-- Returns the LuaSQL connection object by using the settings to connect to the database.
--
-- @treturn Connection The LuaSQL connection object
--
function MySQLConnection:getConnection()

  return self.environment:connect(
    self.settings["databaseName"],
    self.settings["userName"],
    self.settings["password"],
    self.settings["host"],
    self.settings["portNumber"]
  )

end


setmetatable(
  MySQLConnection,
  {
    -- MySQLConnection inherits methods and attributes from LuaSQLConnection
    __index = LuaSQLConnection,

    -- When MySQLConnection() is called, call the __construct() method
    __call = MySQLConnection.__construct
  }
)


return MySQLConnection
