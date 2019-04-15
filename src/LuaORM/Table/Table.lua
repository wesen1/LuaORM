---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

local ObjectUtils = require("LuaORM/Util/ObjectUtils")
local TableColumn = require("LuaORM/Table/TableColumn")
local TableUtils = require("LuaORM/Util/TableUtils")
local Type = require("LuaORM/Util/Type/Type")
local API = LuaORM_API

---
-- Represents a database table.
--
-- @type Table
--
local Table = {}


---
-- The name of the database table
--
-- @tfield string name
--
Table.name = nil

---
-- The list of columns
--
-- @tfield TableColumn[] columns
--
Table.columns = nil

---
-- The relations of this Table to other Table's
--
-- @tfield Table[][] relations
--
Table.relations = {
  oneToMany = {},
  oneToOne = {},
  manyToOne = {}
}


-- Metamethods

---
-- Table constructor.
-- This is the __call metamethod.
--
-- @tparam mixed[] _settings The Table's settings
--
-- @treturn Table The Table instance
--
function Table:__construct(_settings)

  local instance = setmetatable({}, {__index = Table})

  instance.name = Type.toString(_settings["name"])

  instance.columns = {}
  instance:createTableColumns(_settings["columns"])

  instance.relations = ObjectUtils.clone(Table.relations)
  instance:initializeRelations()

  return instance

end


-- Getters and Setters

---
-- Returns the name of the table.
--
-- @treturn string The name of the table
--
function Table:getName()
  return self.name
end

---
-- Returns the columns of the table.
--
-- @treturn TableColumn[] The list of columns
--
function Table:getColumns()
  return self.columns
end


-- Public Methods

---
-- Returns the primary key column of this Table.
--
-- @treturn TableColumn|nil The primary key column or nil if no primary key column exists
--
function Table:getPrimaryKeyColumn()

  for _, column in ipairs(self.columns) do
    if (column:getSettings()["isPrimaryKey"] == true) then
      return column
    end
  end

end

---
-- Returns the foreign key columns of this table.
--
-- @treturn TableColumn[] The foreign key columns
--
function Table:getForeignKeyColumns()

  local foreignKeyColumns = {}
  for _, column in ipairs(self.columns) do
    if (column:getSettings()["isForeignKeyTo"] ~= nil) then
      table.insert(foreignKeyColumns, column)
    end
  end

  return foreignKeyColumns

end

---
-- Returns the foreign key column that refers a specific Table.
--
-- @tparam Table _table The target Table
--
-- @treturn TableColumn|nil The foreign key column to the target Table or nil if no foreign key refers the target Table
--
function Table:getForeignKeyColumnToTable(_table)

  for _, foreignKeyColumn in ipairs(self:getForeignKeyColumns()) do
    if (foreignKeyColumn.settings["isForeignKeyTo"] == _table) then
      return foreignKeyColumn
    end
  end

end

---
-- Returns whether this Table has a foreign key to a specific Table.
--
-- @tparam Table _table The target Table
--
-- @treturn bool True if this Table has a foreign key to the target Table, false otherwise
--
function Table:hasForeignKeyToTable(_table)
  return (self:getForeignKeyColumnToTable(_table) ~= nil)
end

---
-- Adds a table relation to another Table to this Table.
--
-- @tparam Table _table The related Table
-- @tparam string The relation type ("oneToMany", "manyToOne" or "oneToOne")
--
function Table:addTableRelation(_table, _relationType)
  table.insert(self.relations[_relationType], _table)
end

---
-- Returns all Table's to that this Table is related.
--
-- @treturn Table[] The related tables
--
function Table:getRelatedTables()
  return TableUtils.concatenateTables(
    self.relations["oneToMany"], self.relations["oneToOne"], self.relations["manyToOne"]
  )
end

---
-- Returns all unique columns of this Table.
--
-- @treturn TableColumn[] The unique columns
--
function Table:getUniqueColumns()

  local uniqueColumns = {}
  for _, column in ipairs(self.columns) do
    if (column:getSettings()["unique"] == true) then
      table.insert(uniqueColumns, column)
    end
  end

  return uniqueColumns

end

---
-- Returns whether this Table contains a specific column.
--
-- @tparam TableColumn _column The column
--
-- @treturn bool True if this Table contains the column, false otherwise
--
function Table:hasColumn(_column)
  return (TableUtils.tableHasValue(self.columns, _column))
end

---
-- Returns a TableColumn of this table by it's name.
--
-- @tparam string _columnName The column name
--
-- @treturn TableColum|nil The TableColumn or nil if no TableColumn with that name exists
--
function Table:getColumnByName(_columnName)
  for _, column in ipairs(self.columns) do
    if (column:getName() == _columnName) then
      return column
    end
  end
end

---
-- Returns a TableColumn of this Table by it's select alias.
--
-- @tparam string _selectAlias The select alias
--
-- @treturn TableColumn|nil The TableColumn or nil if no TableColumn with that select alias exists
--
function Table:getColumnBySelectAlias(_selectAlias)
  for _, column in ipairs(self.columns) do
    if (column:getSelectAlias() == _selectAlias) then
      return column
    end
  end
end

---
-- Checks and returns whether this Table is valid.
--
-- @treturn bool True if the table is valid, false otherwise
--
function Table:validate()

  if (self.name:match("%.")) then
    API.ORM:getLogger():fatal("Table names may not contain dots")
    return false
  end

  for _, column in ipairs(self.columns) do
    column:validate()
  end

  return self:validateNumberOfPrimayKeys()

end


-- Private Methods

---
-- Creates the Table's TableColumn's from an array of column settings lists.
--
-- @tparam mixed[][] _columnSettingsLists The column settings lists
--
function Table:createTableColumns(_columnSettingsLists)

  self.columns = {}
  for i, columnSettingsList in ipairs(_columnSettingsLists) do

    if (columnSettingsList["isForeignKeyTo"] ~= nil) then
      columnSettingsList["isForeignKeyTo"] = columnSettingsList["isForeignKeyTo"]:getTargetTable()
    end

    local columnName = Type.toString(columnSettingsList["name"])
    self.columns[i] = TableColumn(self, columnName, columnSettingsList)

  end

end

---
-- Initializes the Table's relations to other Table's.
--
function Table:initializeRelations()

  for _, foreignKeyColumn in ipairs(self:getForeignKeyColumns()) do

    local relatedTable = foreignKeyColumn.settings["isForeignKeyTo"]

    if (relatedTable:hasForeignKeyToTable(self)) then
      table.insert(self.relations["oneToOne"], relatedTable)
      relatedTable:addTableRelation(self, "oneToOne")
    else
      table.insert(self.relations["manyToOne"], relatedTable)
      relatedTable:addTableRelation(self, "oneToMany")
    end

  end

end

---
-- Checks whether there is exactly one primary key field in this Table.
-- As a side effect, this also confirms that there is at least one column in this Table.
--
-- @treturn bool True if the number of primary keys is valid, false otherwise
--
function Table:validateNumberOfPrimayKeys()

  local numberOfPrimaryKeyColumns = 0
  for _, column in ipairs(self.columns) do
    if (column:getSettings()["isPrimaryKey"] == true) then
      numberOfPrimaryKeyColumns = numberOfPrimaryKeyColumns + 1
    end
  end


  if (numberOfPrimaryKeyColumns == 1) then
    return true

  elseif (numberOfPrimaryKeyColumns == 0) then

    -- Auto create "id" column
    local primaryKeyColumn = TableColumn(
      self,
      "id",
      { fieldType = API.fieldTypes.unsignedIntegerField, isPrimaryKey = true, autoIncrement = true }
    )
    self.columns = TableUtils.concatenateTables({ primaryKeyColumn }, self.columns)

    API.ORM:getLogger():info(string.format(
      "No primary key defined for table '%s'. Adding primary key column 'id'", self.name
    ))

    return true

  else

    API.ORM:getLogger():fatal(string.format(
      "Invalid number of primary key columns in table '%s': There must be exactly 1 primary key column per table",
      self.name
    ))

    return false
  end

end


-- When Table() is called, call the __construct() method
setmetatable(Table, {__call = Table.__construct})


return Table
