---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local Logger = require("LuaORM/Util/Logger")
local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local QueryExecutor = require("LuaORM/QueryExecutor")
local SettingValueList = require("LuaORM/Util/SettingValueList/SettingValueList")

---
-- Wrapper class for the ORM.
-- Stores the ORM configuration and objects that are needed globally.
--
-- @type ORM
--
local ORM = {}


---
-- The connection to the database
--
-- @tfield BaseDatabaseConnection databaseConnection
--
ORM.databaseConnection = nil

---
-- The query executor
--
-- @tfield QueryExecutor queryExecutor
--
ORM.queryExecutor = nil

---
-- The logger
--
-- @tfield Logger logger
--
ORM.logger = nil

---
-- The path to the "src" directory relative from the current working directory
--
-- @tfield string sourceDirectoryPath
--
ORM.sourceDirectoryPath = nil

---
-- The ORM settings
--
-- @tfield SettingValueList settings
--
ORM.settings = SettingValueList(

  -- The connection class (e.g. MySQL/LuaSQL)
  { name = "connection", dataType = "string" }
)


-- Metamethods

---
-- ORM constructor.
-- This is the __call metamethod.
--
-- @tparam string _sourceDirectoryPath The path to the "src" directory relative from the current working directory
--
-- @treturn ORM The ORM instance
--
function ORM:__construct(_sourceDirectoryPath)

  local instance = setmetatable({}, {__index = ORM})

  instance.logger = Logger()
  instance.queryExecutor = QueryExecutor()
  instance.settings = ObjectUtils.clone(ORM.settings)
  instance.sourceDirectoryPath = _sourceDirectoryPath

  return instance

end


-- Getters and Setters

---
-- Returns the database connection.
--
-- @treturn Database The database connection
--
function ORM:getDatabaseConnection()
  return self.databaseConnection
end

---
-- Returns the logger.
--
-- @treturn Logger The logger
--
function ORM:getLogger()
  return self.logger
end

---
-- Returns the QueryExecutor.
--
-- @treturn QueryExecutor The QueryExecutor
--
function ORM:getQueryExecutor()
  return self.queryExecutor
end

---
-- Returns the ORM's settings.
--
-- @treturn SettingValueList The ORM's settings
--
function ORM:getSettings()
  return self.settings
end


-- Public Methods

---
-- Initializes the ORM.
--
-- @tparam mixed[] _settings The ORM settings
--
function ORM:initialize(_settings)

  -- Parse ORM settings
  self.settings:parse(_settings)

  -- Initialize the logger
  self.logger:configure(_settings["logger"])

  -- Initialize the DatabaseConnection
  self:initializeDatabaseConnection(_settings["database"])

end

---
-- Returns the path to a template file relative from the current working directory.
--
-- @tparam string _databaseLanguageName The name of the database language
-- @tparam string _templatePath The path to the template relative from the database language's templates base directory and without the file ending
--
-- @treturn string The path to the template file relative from the current working directory
--
function ORM:getTemplateRequirePath(_databaseLanguageName, _templatePath)

  local templatesBaseFolderPath = self.sourceDirectoryPath .. "/LuaORM/DatabaseLanguage/"
  return templatesBaseFolderPath .. _databaseLanguageName .. "/Templates/" .. _templatePath .. ".template"

end


-- Private Methods

---
-- Initializes the DatabaseConnection based on the "database" field in the settings table.
--
-- @tparam mixed[] _settings The ORM settings
--
function ORM:initializeDatabaseConnection(_settings)

  -- Create the DatabaseConnection
  local databaseConnectionClassRequirePath = string.format(
    "LuaORM/DatabaseConnection/%sConnection",
    self.settings["connection"]
  )
  local databaseConnectionClass = require(databaseConnectionClassRequirePath)
  self.databaseConnection = databaseConnectionClass(_settings)

  -- Initialize the DatabaseConnection
  self.databaseConnection:initialize()
  self.logger:info("DatabaseConnection successfully initialized")

end


-- When ORM() is called, call the __construct() method
setmetatable(ORM, {__call = ORM.__construct})


return ORM
