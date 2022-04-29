
return function(superClass)

    local function indent(str)
        local lines = {}
        local lineno = 1
        for s in str:gmatch("[^\r\n]+") do
            if lineno > 1 then
                table.insert(lines, "\n  ")
            end
            table.insert(lines, s)
            lineno = lineno + 1
        end
        return table.concat(lines)
    end

    local function copyTable(table, destination)
        local table = table or {}
        local result = destination or {}

        for k, v in pairs(table) do
            if not result[k] then
                if type(v) == "table" and k ~= "__index" and k ~= "__newindex" then
                    result[k] = copyTable(v)
                else
                    result[k] = v
                end
            end
        end

        return result
    end

    local function addmetatable(obj)
        obj._ = obj._ or {}

        local mt = {}

        mt.__tostring = function(self)
            local contents = { (self.__oop_type or "class") .. " {\n" }
            for k, v in pairs(self) do
                if k ~= "__oop_type" then
                    if k == self then
                        k = "<self>"
                    end
                    if v == self then
                        v = "<self>"
                    end
                    table.insert(contents, "  ")
                    table.insert(contents, tostring(k))
                    table.insert(contents, ": ")
                    table.insert(contents, indent(tostring(v)))

                    table.insert(contents, ",\n")
                end
            end
            table.insert(contents, "}\n")
            return table.concat(contents)
        end

        -- create new objects directly, like o = Object()
        mt.__call = function(self, ...)
            local x = {}
            copyTable(self, x)
            addmetatable(x)
            x.__oop_type = "object"
            if x.constructor then
                x:constructor(...)
            end
            return x
        end

        -- allow for getters and setters
        mt.__index = function(table, key)
            local val = rawget(table._, key)
            if val and type(val) == "table" and (val.get ~= nil or val.value ~= nil) then
                if val.get then
                    if type(val.get) == "function" then
                        return val.get(table, val.value)
                    else
                        return val.get
                    end
                elseif val.value then
                    return val.value
                end
            else
                return val
            end
        end

        mt.__newindex = function(table, key, value)
            local val = rawget(table._, key)
            if val and type(val) == "table" and ((val.set ~= nil and val._ == nil) or val.value ~= nil) then
                local v = value
                if val.set then
                    if type(val.set) == "function" then
                        v = val.set(table, value, val.value)
                    else
                        v = val.set
                    end
                end
                val.value = v
                if val and val.afterSet then val.afterSet(table, v) end
            else
                table._[key] = value
            end
        end
        setmetatable(obj, mt)
        return obj
    end

    if superClass then
        local obj = obj or {}

        copyTable(superClass, obj)
        obj.super = superClass

        return addmetatable(obj)
    end

    Class = { __oop_type = "class" }

    -- default (empty) constructor
    function Class:constructor(...) end

    -- set properties outside the constructor or other functions
    function Class:set(prop, value)
        if not value and type(prop) == "table" then
            for k, v in pairs(prop) do
                rawset(self._, k, v)
            end
        else
            rawset(self._, prop, value)
        end
    end

    -- create an instance of an object with constructor parameters
    return addmetatable(Class)
end
