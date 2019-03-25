---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local SettingValueList = require("LuaORM/Util/SettingValueList/SettingValueList")
local Type = require("LuaORM/Util/Type/Type")

---
-- Provides methods to log messages.
--
-- @type Logger
--
local Logger = {}


---
-- The Logger's settings.
--
-- @tfield SettingValueList settings
--
Logger.settings = SettingValueList(

  -- Defines whether log messages will be shown
  { name = "isEnabled", dataType = "boolean", defaultValue = false },

  -- Defines whether debug log messages will be shown (including SQL queries)
  { name = "isDebugEnabled", dataType = "boolean", defaultValue = false }
)


-- Metamethods

---
-- Logger constructor.
-- This is the __call metamethod.
--
-- @treturn Logger The Logger instance
--
function Logger:__construct()

  local instance = setmetatable({}, {__index = Logger})
  instance.settings = ObjectUtils.clone(Logger.settings)

  return instance

end


-- Public Methods

---
-- Configures the Logger.
--
-- @tparam mixed[] _settings The settings
--
function Logger:configure(_settings)
  self.settings:parse(_settings)
end


---
-- Logs a debug message.
--
-- @tparam string _message The message
--
function Logger:debug(_message)
  if (self.settings["isDebugEnabled"]) then
    self:print("[LuaORM:Debug] " .. Type.toString(_message))
  end
end

---
-- Logs a SQL query.
--
-- @tparam string _sql The SQL query
--
function Logger:sql(_sql)
  self:debug(_sql)
end

---
-- Logs a info message.
--
-- @tparam string _message The message
--
function Logger:info(_message)
  self:print("[LuaORM:Info] " .. Type.toString(_message))
end

---
-- Logs a warning message.
--
-- @tparam string _message The message
--
function Logger:warn(_message)
  self:print("[LuaORM:Warning] " .. Type.toString(_message))
end

---
-- Logs a error message.
--
-- @tparam string _message The message
--
function Logger:error(_message)
  self:print("[LuaORM:Error] " .. Type.toString(_message))
end

---
-- Logs a fatal message.
--
-- @tparam string _message The message
--
function Logger:fatal(_message)
  self:print("[LuaORM:Fatal] " .. Type.toString(_message))
end


-- Private Methods

---
-- Prints a log message if the Logger is enabled.
--
-- @tparam string _message The message
--
function Logger:print(_message)
  if (self.settings["isEnabled"]) then
    print(_message)
  end
end


-- When Logger() is called, call the __construct() method
setmetatable(Logger, {__call = Logger.__construct})


return Logger
