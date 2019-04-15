---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- The API for users of this library.
-- This is the file that is returned when require("LuaORM") is called.
--

if (LuaORM_API == nil) then

  -- Initialize LuaORM

  -- Find the path to the directory in which this file is located relative from the current working directory
  local relativeFilePath = debug.getinfo(1).short_src
  local sourceDirectoryPath = relativeFilePath:gsub("/?[^%/]+.lua$", "")

  local requirePath = ...
  if (requirePath ~= "API") then

    -- Add a new path to package.path to the directory in which this file is located
    -- This is done to be able to require classes with paths relative from the src directory
    -- If the requirePath is "API" there is already a path in package.path that allows this
    package.path = package.path .. ";" .. sourceDirectoryPath .. "/?.lua"

  end

  LuaORM_API = {}

  -- API to configure the ORM
  local ORM = require("LuaORM/ORM")
  LuaORM_API.ORM = ORM(sourceDirectoryPath)

  -- API to create own Model's
  LuaORM_API.Model = require("LuaORM/Model")
  LuaORM_API.FieldType = require("LuaORM/Table/FieldType")
  LuaORM_API.fieldTypes = require("DefaultFieldTypes")

end


return LuaORM_API
