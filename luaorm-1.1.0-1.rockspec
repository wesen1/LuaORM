package = "LuaORM"
version = "1.1.0-1"

description = {
  summary = "An ORM for Lua",
  detailed = [[
    LuaORM is an Object-Relational Mapping (ORM) for Lua.
    It allows you to define tables and to execute database queries with an easy to use API.
  ]],
  license = "MIT",
  homepage = "https://github.com/wesen1/LuaORM",
}

source = {
  url = "git+https://github.com/wesen1/LuaORM.git",
  tag = "v1.1.0"
}

dependencies = {
  "lua >= 5.1",
  "lua-resty-template >= 1.9-1, < 2.0"
}

build = {
  type = "command",
  install_command = "cp -r src $(LUADIR)/LuaORM"
}
