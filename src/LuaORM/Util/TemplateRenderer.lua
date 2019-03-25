---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local LuaRestyTemplateEngine = require("resty/template")
local Type = require("LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- Renders templates.
-- Leading and trailing whitespace per line, empty lines and line endings are removed.
--
-- Supported tags are:
--   <br>: Creates a line break
--   <whitespace>: Creates a single whitespace
--   <whitespace:x>: Creates x whitespaces
--
-- @type TemplateRenderer
--
local TemplateRenderer = {}


-- Metamethods

---
-- TemplateRenderer constructor.
-- This is the __call metamethod.
--
-- @treturn TemplateRenderer The TemplateRenderer instance
--
function TemplateRenderer:__construct()
  local instance = setmetatable({}, {__index = TemplateRenderer})
  return instance
end


-- Public Methods

---
-- Renders a template and returns the rendered string.
--
-- @tparam string _databaseLanguageName The name of the database language
-- @tparam string _templatePath The template path relative from the database languages templates folder
-- @tparam mixed[] _templateValues The values to pass to the template
--
-- @treturn string The rendered template
--
function TemplateRenderer:renderTemplate(_databaseLanguageName, _templatePath, _templateValues)

  local templatePath = API.ORM:getTemplateRequirePath(_databaseLanguageName, _templatePath)

  -- Prepare the template
  local compiledTemplate = LuaRestyTemplateEngine.compile(templatePath)

  -- Render the template
  local renderedTemplate = compiledTemplate(_templateValues)

  -- Remove empty lines, leading and trailing whitespace per line and line breaks
  renderedTemplate = renderedTemplate:gsub(" *\n+ *", "")

  -- Remove leading whitespace from the total string
  renderedTemplate = renderedTemplate:gsub("^ +", "")

  -- Remove trailing whitespace from the total string
  renderedTemplate = renderedTemplate:gsub(" +$", "")

  -- Replace <br> tags with line breaks
  renderedTemplate = renderedTemplate:gsub(" *<br> *", "\n")

  -- Find and replace <whitespace> tags
  renderedTemplate = renderedTemplate:gsub(
    "< *whitespace[^>]*>",
    function(_whitespaceTagString)
      local numberOfWhitespaceCharacters = 1

      -- Check defined number of white space characters (the number behind "whitespace:")
      local definedNumberOfWhitespaceCharactersString = _whitespaceTagString:match(":(%d)")
      if (definedNumberOfWhitespaceCharactersString) then
        local definedNumberOfWhitespaceCharacters = Type.toInteger(definedNumberOfWhitespaceCharactersString)
        if (definedNumberOfWhitespaceCharacters > numberOfWhitespaceCharacters) then
          numberOfWhitespaceCharacters = definedNumberOfWhitespaceCharacters
        end
      end

      return string.rep(" ", numberOfWhitespaceCharacters)

    end
  )

  return renderedTemplate

end


-- When TemplateRenderer() is called, call the __construct() method
setmetatable(TemplateRenderer, {__call = TemplateRenderer.__construct})


return TemplateRenderer
