LuaORM
======

LuaORM is an Object-Relational Mapping (ORM) for Lua. <br />
It is based on [4DaysORM](https://github.com/itdxer/4DaysORM). <br />
Some of the APIs are inspired by [Propel](https://github.com/propelorm/Propel)


Usage
-----

### Include LuaORM ###

You can include LuaORM by using `require "<path to LuaORM directory>/src/API"`. <br />
If you installed LuaORM with luarocks you can include it with `require "LuaORM.API"`. <br />
The returned object has the following fields:

| Field Name | Description                                      |
|------------|--------------------------------------------------|
| FieldType  | The FieldType class to define custom FieldType's |
| Model      | The Model class to create Table's and Query's    |
| ORM        | The ORM instance to configure the ORM            |
| fieldTypes | The list of default FieldType's                  |

### Configure the ORM ###

Call `API.ORM:initialize(options)` to initialize the ORM. <br />

```lua
API.ORM:initialize({
  connection = "LuaSQL/MySQL",
  database = {
    databaseName = "orm_test",
    host = "127.0.0.1",
    portNumber = 3306,
    userName = "root",
    password = "root"
  },
  logger = { isEnabled = true, isDebugEnabled = false }
})
```

You can then close the connection with `API.ORM:close()`

```lua
API.ORM:close()
```

#### connection ####

| Option     | Description                          | Default Value | Example        |
|------------|--------------------------------------|---------------|----------------|
| connection | Defines the DatabaseConnection class | -             | "LuaSQL/MySQL" |

Available connection types are:

* LuaSQL/MySQL
* LuaSQL/SQLite (not supported yet)
* LuaSQL/PostgreSQL (not supported yet)

#### database ####

| Option       | Description                                                        | Default Value | Example     |
|--------------|--------------------------------------------------------------------|---------------|-------------|
| databaseName | The path to the database file (SQLite) or the name of the database | -             | "db_1"      |
| host         | The address (IP, URL, hostname) of the database server             | -             | "127.0.0.1" |
| portNumber   | The port number of the database on the server                      | -             | 3306        |
| userName     | The name of the database user                                      | -             | "user"      |
| password     | The password of the database user                                  | -             | "pwd"       |
|              |                                                                    |               |             |

#### logger ####

| Option         | Description                                                              | Default Value |
|----------------|--------------------------------------------------------------------------|---------------|
| isEnabled      | Defines whether log messages will be shown                               | false         |
| isDebugEnabled | Defines whether debug log messages will be shown (including SQL queries) | false         |


### Create Models ###

After initializing the ORM you can start creating the models for your tables. <br />
A table contains one or more table columns and must contain exactly one primary key column. <br />
If no primary key column is defined, a "id" column will be automatically added to the table.

```lua
local Model = API.Model
local fieldTypes = API.fieldTypes

local User = Model({
  name = "users",
  columns = {
    { name = "user_name", fieldType = fieldTypes.charField, maxLength = 100, unique = true },
    { name = "password", fieldType = fieldTypes.charField, maxLength = 50, unique = true },
    { name = "age", fieldType = fieldTypes.unsignedIntegerField, maxLength = 2, mustBeSet = false },
    { name = "job", fieldType = fieldTypes.charField, maxLength = 50, mustBeSet = false },
    { name = "time_create", fieldType = fieldTypes.dateTimeField, mustBeSet = false }
  }
})
```

| Option  | Description              | Default Value |
|---------|--------------------------|---------------|
| name    | The name of the table    | -             |
| columns | The columns of the table | -             |


#### Table columns ####

Each table column has at least a name and a field type.
The available options per table column are:

| Option         | Description                                                             | Default Value |
|----------------|-------------------------------------------------------------------------|---------------|
| name           | The name of the table column                                            | -             |
| fieldType      | The field type of the column                                            | -             |
| isPrimaryKey   | Defines whether the column is a primary key                             | false         |
| autoIncrement  | Defines whether the values of this column are automatically incremented | false         |
| isForeignKeyTo | Defines the table that is referenced by this column                     | -             |
| mustBeSet      | Defines if the column must always have a value                          | true          |
| unique         | Defines if the column values must be unique                             | false         |
| maxLength      | The number of available bytes per value                                 | -             |
| escapeValue    | If true text values will be escaped in order to prevent SQL injection   | false         |
| defaultValue   | Default value if the value is not set (May be a function)               |               |


##### Field types #####

Field types define which kind of data can be stored in the column. They also control how data from the database will be converted. <br />
The default field types are:

| Field type name      | Description                                            |
|----------------------|--------------------------------------------------------|
| integerField         | Stores integer values                                  |
| unsignedIntegerField | Stores unsigned integer values                         |
| charField            | Stores a variable number of characters                 |
| textField            | Stores text                                            |
| booleanField         | Stores a boolean value (true or false)                 |
| dateTimeField        | Stores a date (Internally uses the `os.date` function) |

You can also create custom field types and overwrite default field types by editing the `API.fieldTypes` table. <br />
To create a new FieldType use `API.FieldType(options)`. The available options are:

| Option      | Description                                                              | Default Value |
|-------------|--------------------------------------------------------------------------|---------------|
| luaDataType | The lua data type for the field type values                              | -             |
| SQLDataType | The SQL data type (either the id of a predefined one or a custom string) | string        |
| convert     | Function that converts input values before they are further processed    | -             |
| validator   | Function that validates that a value matches this FieldType              | -             |
| as          | Function that adds additional parameters to a escaped literal value      | -             |
| to          | Function that converts a query result value to a lua data type           | -             |

The available lua data types are:

* string
* number
* integer
* boolean

The available SQL data types are:

* string
* blob
* text
* number
* integer
* float
* boolean
* unsignedInteger


### Create queries ###

After creating the models you can use them to insert or fetch data from the database.


#### Select ####

You can use Select queries to select specific rows from a table. <br />
Call `get()` to get a new query, then call `find()` to get all rows of that table.

```lua
local rows = User:get()
                 :find()
print(rows[1].user_name)
```

Use `findOne()` to return only the first row.

```lua
local row = User:get()
                :findOne()
print(row.user_name)
```

You can access the values of each data row by accessing the data row index with the corresponding column name.


##### Select rules #####

By default all columns of the query tables are selected by the queries. <br />
You can use Select rules to additionally select table columns with SQL functions.

```lua
local row = User:get()
                :select():max("age")
                :findOne()
print(row.MAX_age)
```

Available select rule methods are:

| Method name | Alias                 | Description                                      |
|-------------|-----------------------|--------------------------------------------------|
| min         | MIN\_\<column name>   | Selects the minimum value of a column            |
| max         | MAX\_\<column name>   | Selects the maximum value of a column            |
| count       | COUNT\_\<column name> | Selects the number of rows where a column is set |
| sum         | SUM\_\<column name>   | Selects the sum of values in a column            |


##### Join #####

Use join rules if you want to select the data from multiple tables at once. <br />
In order to use joins one of the tables in the query must have a relation to the target join table.
Note: The foreign key field type must match the field type of the referenced tables primary key (auto primary keys have the field type "unsignedIntegerField").

So let's create a "news" table that references the "users" table

```lua
local News = Model({
  name = "news",
  columns = {
    { name = "title", fieldType = fieldTypes.charField, maxLength = 100, unique = false, mustBeSet = true, unique = true },
    { name = "text", fieldType = fieldTypes.textField, mustBeSet = false },
    { name = "create_user_id", fieldType = fieldTypes.unsignedIntegerField, isForeignKeyTo = User }
  }
})
```

Now you can join the "news" table to a "User" query or vice versa.

```lua
-- Notation type one
News:get():leftJoinUsers():find()
User:get():leftJoinNews():find()

-- Notation type two
News:get():leftJoin():table("users")
User:get():leftJoin():table("news")

-- Notation type three
News:get():join("users", "left"):find()
User:get():join("news", "left"):find()


-- Specifiy the columns that will be used to join the tables
News:get():leftJoinUsers():on("user_id", "users.id")
```

The data rows of the joined table can be found by accessing the index with the corresponding table name, e.g. `rows.news` returns all related "news" entries of one "user" row.

Available join types are:

* leftJoin(\<table name>) / "left"
* rightJoin(\<table name>) / "right"
* innerJoin(\<table name>) / "inner"
* fullJoin(\<table name>) / "full" (not supported yet)


Note that the column and table names for the methods are converted as follows:

1. The first letter is converted to uppercase (e.g. "user_name" => "User_name")
2. Underscores are removed and the letters following a underscore are converted to uppercase (e.g. "User_name" => "UserName")


##### Where #####

You can use Where rules to filter the result rows.

```lua

-- Notation type one
User:get()
    :where():column("user_name"):equals("root")
    :find()

-- Notation type two (only for "equals" rules)
User:get()
    :where({ user_name = "root" })
    :find()

-- Notation type three (only for "equals" rules)
User:get()
    :filterByUserName("root")
    :find()
```

The following methods are available to configure Where rules:

| Method name                  | Description                                   |
|------------------------------|-----------------------------------------------|
| NOT()                        | Find all rows that do not match the rule      |
| column(string)               | Set which column shall be compared to a value |
| isLessThan(number)           | column value < number                         |
| isLessThanOrEqual(number)    | column value <= number                        |
| isGreaterThan(number)        | column value > number                         |
| isGreaterThanOrEqual(number) | column value >= number                        |
| equals(any)                  | column value = any                            |
| equalsColumn(string)         | column value = \<other column's value>        |
| isLike(string)               | column value = pattern                        |
| isInList(table)              | table contains column's value                 |
| isNotSet()                   | Checks whether the column is not set          |
| AND()                        | Appends the next rule with the "AND" operator |
| OR()                         | Appends the next rule with the "OR" operator  |


##### Group by #####

You can use "Group by" clauses to group multiple rows into one based on specific columns. <br />
This can be useful when using aggregate functions in the select rules.

```lua
-- Notation type one
User:get()
    :groupById()
    :find()

-- Notation type two
User:get()
    :groupBy("users.id")
    :find()
```

You can also use `having()` to filter the grouped rows.

```lua
-- Notation type one
User:get()
    :groupById()
    :having():column("age"):equals(20)
    :find()

-- Notation type two
User:get()
    :groupBy("users.id")
    :having({ age = 20 })
    :find()
```

Having can only be used after calling `groupBy()`. It provides the same methods like `where()`.


##### Order by #####

You can sort the result rows by their column values.

```lua
-- Notation type one
User:get()
    :orderByAge():desc()
    :findOne()

-- Notation type two
User:get()
    :orderBy("age"):desc()
    :findOne()
```

Available methods are:

| Method name | Description                                                                         |
|-------------|-------------------------------------------------------------------------------------|
| asc         | Order the result rows from lowest to highest ("ascending") by the specifeid column  |
| desc        | Order the result rows from highest to lowest ("descending") by the specified column |


##### Limit #####

You can use a Limit clause to limit the number of returned rows.

```lua
User:get()
    :limit(2)
    :find()
```

You can also specifiy a offset to skip the first \<x> result rows.

```lua
User:get()
    :limit(2)
    :offset(2)
    :find()
```


#### Insert ####

```lua
local user = User:new({
  user_name = "root",
  password = "pwd"
})

user:save()

print(user.id)
```

Use the `new()` method to create a new data row for one of your models. <br />
The values are in the format { [column name] = value} <br />
When you finished editing the row call `save()` to add the row to the database. The new row now has a id that you can get by fetching the `id` index.


#### Update ####

You can also update multiple data rows at once by creating a query.

```lua
User:get()
    :where():column("time_create"):isNotSet()
    :update({ time_create = os.time() })
```


#### Delete ####

You can use a Delete query to delete rows from the tables.

```lua
User:get()
    :where():column("time_create"):isNotSet()
    :delete()
```


### Using Select query results ###

Select query results provide methods to execute queries. <br />
The following queries are supported:


#### Update ####

##### Update a single row #####

You can update data rows that you created yourself or that you fetched from the database.
Simply change the values of the row by editing the indexes with the names of the rows columns.
Then `save` the row to update the row in the database.

```lua
local user = User:get():findOne()

user.user_name = "a_new_user"
user:save()
```

##### Update multiple rows #####

You can also update multiple rows at once by using the `update` method.

```lua
local users = User:get():limit(2):find()

users:update({ age = 50 })
```


#### Delete ####

You can delete data rows from the database by calling the `delete()` method.

```lua
local user = User:get():findOne()

user:delete()
```


#### Count ####

You can count the number of rows with the `count()` method.

```lua
local users = User:get():find()

print(users:count())
```
