---
-- @author wesen
-- @copyright 2019 wesen <wesen-ac@web.de>
-- @release 0.1
-- @license MIT
--

---
-- Example script that executes all code that is shown in the README.md file
--

local startTimeStamp = os.clock()

-- 1. Include LuaORM
local API = require("src.API")


-- 2. Configure the ORM
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


-- 3. Create Models
local Model = API.Model
local fieldTypes = API.fieldTypes
local FieldType = API.FieldType

-- 3.1 Create a custom FieldType
fieldTypes.emailField = FieldType({
  luaDataType = "string",
  SQLDataType = "string",

  validator = function (_value)
    if (_value:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?")) then
      return true
    else
      return false
    end
  end
})


-- 3.2 Create the tables
local User = Model({
  name = "users",
  columns = {
    { name = "user_name", fieldType = fieldTypes.charField, maxLength = 100, unique = true },
    { name = "password", fieldType = fieldTypes.charField, maxLength = 50, unique = true },
    { name = "age", fieldType = fieldTypes.unsignedIntegerField, maxLength = 2, mustBeSet = false },
    { name = "job", fieldType = fieldTypes.charField, maxLength = 50, mustBeSet = false },
    { name = "time_create", fieldType = fieldTypes.dateTimeField, mustBeSet = false },
    { name = "email", fieldType = fieldTypes.emailField, maxLength = 100, mustBeSet = false },
  }
})

local News = Model({
  name = "news",
  columns = {
    { name = "title", fieldType = fieldTypes.charField, maxLength = 100, unique = false, mustBeSet = true, unique = true },
    { name = "text", fieldType = fieldTypes.textField, mustBeSet = false },
    { name = "create_user_id", fieldType = fieldTypes.unsignedIntegerField, isForeignKeyTo = User }
  }
})


-- 4. Queries

-- Empty the tables
News:get():delete()
User:get():delete()

-- Fill the tables with some test data rows
print("\nCreating 10 users ...")
for i = 1, 10, 1 do
  User:new({ user_name = "user_" .. i, password = "pwd_" .. i, age = (30 - i) }):save()
end

print("Creating 5 news ...")
users = User:get():limit(3):offset(1):find()

News:new({ title = "Some news", create_user_id = users[1].id }):save()
News:new({ title = "Other news", create_user_id = users[1].id }):save()
News:new({ title = "News made by someone else", create_user_id = users[2].id }):save()
News:new({ title = "New title", create_user_id = users[2].id }):save()
News:new({ title = "Final news", create_user_id = users[3].id }):save()


-- 4.1 Select
print("\nFetching all users ...")
local rows = User:get()
                 :find()
print("Found " .. rows:count() .. " users")
print("User name of first user is: " .. rows[1].user_name)

print("\nFetching first user ...")
local row = User:get()
                :findOne()
print("User name of first user is: " .. row.user_name)

-- 4.1.1 Select rules
print("\nFetching maximum user age ...")
row = User:get()
          :select():max("age")
          :findOne()
print("Maximum user age is: " .. row.MAX_age)


-- 4.1.2 Join
local news
local users

-- Notation type one
news = News:get():leftJoinUsers():find()
users = User:get():leftJoinNews():find()

-- Notation type two
news = News:get():leftJoin():table("users")
users = User:get():leftJoin():table("news")

-- Notation type three
news = News:get():join("users", "left"):find()
users = User:get():join("news", "left"):find()


-- One to many relation results (Left join with empty table rows)
print("\nFound " .. users:count() .. " users")
for i = 1, users:count(), 1 do
  print("User " .. users[i].user_name .. " has " .. users[i].news:count() .. " news")
end


-- Many to one relation results (Left join but no empty table rows)
print("\nFound " .. news:count() .. " news")
for i = 1, news:count(), 1 do
  print("News " .. news[i].title .. " was created by user ", news[i].users[1].user_name)
end


-- Many to one relation results (Right join with empty table rows)
news = News:get():rightJoinUsers():orderBy("users.id"):asc():find()

print("\nFound " .. news:count() .. " news")
for i = 1, news:count(), 1 do
  print("News " .. i .. " title is ", news[i].title, "and was created by user ", news[i].users[1].user_name)
end


-- One to many relation results (inner join)
users = User:get():innerJoinNews():find()

print("\nFound " .. users:count() .. " users with news")
for i = 1, users:count(), 1 do
  print("User with id " .. users[i].id .. " has " .. users[i].news:count() .. " news")

  for j = 1, users[i].news:count() do
    print("  Title of news #" .. j .. ": " .. users[i].news[j].title)
  end
end


-- Specifiy the columns that will be used to join the tables
news = News:get():leftJoinUsers():on("create_user_id", "users.id"):find()

print("\nFound " .. news:count() .. " news with custom join columns")


-- 4.1.3 Where

-- Notation type one
users = User:get()
            :where():column("user_name"):equals("user_1")
            :find()

-- Notation type two (only for "equals" rules)
users = User:get()
            :where({ user_name = "user_1" })
            :find()

-- Notation type three (only for "equals" rules)
users = User:get()
            :filterByUserName("user_1")
            :find()

print("\nFound " .. users:count() .. " users with the user name \"user_1\"")


-- 4.1.4 Group by

local groupedUsers

-- Notation type one
groupedUsers = User:get()
                   :groupById()
                   :find()

-- Notation type two
groupedUsers = User:get()
                   :groupBy("users.id")
                   :find()

print("\nFound " .. groupedUsers:count() .. " users grouped by id")

-- 4.1.5 Having

-- Notation type one
groupedUsers = User:get()
                   :groupById()
                   :having():column("age"):equals(20)
                   :find()

-- Notation type two
groupedUsers = User:get()
                   :groupBy("users.id")
                   :having({ age = 20 })
                   :find()

print("\nFound " .. groupedUsers:count() .. " users grouped by id and with age 20")


-- 4.1.6 Order by

local lastUser

-- Notation type one
lastUser = User:get()
               :orderByAge():desc()
               :findOne()

-- Notation type two
lastUser = User:get()
               :orderBy("age"):desc()
               :findOne()

print("\nOldest users user name is: " .. lastUser.user_name)


-- 4.1.7 Limit

local limitedUsers

limitedUsers = User:get()
                   :limit(2)
                   :find()

print("\nFound " .. limitedUsers:count() .. " users with limit 2")
print("First users user name is: " .. limitedUsers[1].user_name)

limitedUsers = User:get()
                   :limit(2)
                   :offset(2)
                   :find()

print("\nFound " .. limitedUsers:count() .. " users with limit 2 and offset 2")
print("First users user name is: " .. limitedUsers[1].user_name)


-- 4.2 Insert

local user = User:new({
  user_name = "root",
  password = "pwd"
})

print("\nUsers id before saving is:", user.id)
user:save()
print("Users id after saving is:", user.id)


-- 4.3 Update

users = User:get()
            :where():column("time_create"):isNotSet()
            :find()
print("\nBefore Update: Found " .. users:count() .. " users where time_create is not set")

print("Updating users where time_create is not set")
User:get()
    :where():column("time_create"):isNotSet()
    :update({time_create = os.time()})

users = User:get()
            :where():column("time_create"):isNotSet()
            :find()
print("After Update: Found " .. users:count() .. " users where time_create is not set")


-- 4.4 Delete

users = User:get()
            :where():column("age"):equals(20)
            :find()
print("\nBefore Delete: Found " .. users:count() .. " users with age 20")

print("Deleting users with age 20")
User:get()
    :where():column("age"):equals(20)
    :delete()

users = User:get()
            :where():column("age"):equals(20)
            :find()
print("After Delete: Found " .. users:count() .. " users with age 20")


-- 5 Using Select query results

-- 5.1 Update

-- 5.1.1 Update a single row
local user = User:get():findOne()

print("\nFirst user name before update: " .. user.user_name)

user.user_name = "a_new_user"
user:save()

print("Object user name after update: " .. user.user_name)

user = User:get():findOne()
print("First users user name after update: " .. user.user_name)


-- 5.1.2 Update multiple rows
users = User:get():limit(2):find()

print("\nFirst users age before update: " .. users[1].age)
print("Second users age before update: " .. users[2].age)

users:update({ age = 50 })

print("First object users age after update: " .. users[1].age)
print("Second object users age after update: " .. users[2].age)

users = User:get():limit(2):find()

print("First database users age after update: " .. users[1].age)
print("Second database users age after update: " .. users[2].age)


-- 5.2 Delete

print("\nFetching last user ...")
user = User:get():orderById():desc():findOne()

print("User object id before delete is:", user.id)
print("Deleting last user ...")
user:delete()
print("User object id after delete is:", user.id)

print("Fetching last user ...")
user = User:get():orderById():desc():findOne()
print("Last users id is:", user.id)


-- 5.3 Count

print("\nSelecting all users ...")
local users = User:get():find()
print("Found " .. users:count() .. " users")


local timePassed = os.clock() - startTimeStamp
print("\nExecution took " .. timePassed .. " seconds")
