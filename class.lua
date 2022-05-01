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

local Object = {}
Object.__index = Object

function Object:implement(...)
    for _, cls in pairs({ ... }) do
        for k, v in pairs(cls) do
            if self[k] == nil and type(v) == "function" then
                self[k] = v
            end
        end
    end
end

function Object:isinstance(T)
    local mt = getmetatable(self)
    while mt do
        if mt == T then
            return true
        end
        mt = getmetatable(mt)
    end
    return false
end

function Object:__tostring()
    local instance_or_class = "class"
    if rawget(self, "__index") == nil then
        instance_or_class = "instance"
    end
    local contents = { instance_or_class, "%s {\n" }
    for k, v in pairs(self) do
        if k ~= "__oop_type" then
            if k == self then
                k = "<self>"
            end
            if v == self then
                v = "<self>"
            end
            table.insert(contents, "  ");
            table.insert(contents, tostring(k))
            table.insert(contents, ": ");
            table.insert(contents, indent(tostring(v)))
            table.insert(contents, ",\n")
        end
    end
    table.insert(contents, "}\n")
    return table.concat(contents)
end

function Object:__call(...)
    local obj = setmetatable({}, self)
    -- if getters/setters enabled in class, enable them for objects also
    local self_ = rawget(self, '_')
    if self_ ~= nil then
        local temp = {}
        rawset(obj, '_', temp)
        local obj_ = temp
        for k, v in pairs(self_) do
            obj_[k] = { v[1] }
        end
    end
    if obj.constructor then
        obj:constructor(...)
    end
    return obj
end

function Object:set(props)
    assert(rawget(self, '__index') ~= nil, "Error!, watch() cannot be called on instances! Call it from the Class!")
    local name = props.name
    local default_value = props.default_value
    local getter = props.getter
    local setter = props.setter

    if name == nil or name == "_" then
        error(("invalid property name '%s' passed to Object:set()"):format(name))
        return
    end

    if self._ == nil then
        self._ = {}
        self.__index = function(self, k)
            local self_ = rawget(self, '_')
            local mt = getmetatable(self)
            if self_[k] == nil then
                return mt[k]
            end
            -- check getter exists
            local self_k = self_[k]
            local mt_ = rawget(mt, '_')
            if mt_[k] ~= nil and mt_[k][2] ~= nil then
                -- use getter
                self_k[1] = mt_[k][2]
            end
            -- return new value
            return self_k[1]
        end
        self.__newindex = function(self, k, v)
            local self_ = rawget(self, '_')
            local mt = getmetatable(self)
            if self_[k] == nil then
                return mt[k]
            end
            -- check setter exists
            local self_k = self_[k]
            local mt_ = rawget(mt, '_')
            local oldValue = self_k[1]
            if mt_[k] ~= nil and mt_[k][3] ~= nil then
                -- use setter
                self_k[1] = mt_[k][3](v, oldValue)
            else
                -- manually set
                self_k[1] = v
            end
            local newValue = self_k[1]
            -- notify watchers
            for i = 2, #self_k do
                self_k[i](newValue, oldValue)
            end
        end
    end
    local v = self._[name]
    if v == nil then
        self._[name] = { default_value, getter, setter }
    else
        self._[name][1] = default_value
        self._[name][2] = getter
        self._[name][3] = setter
    end
end

function Object:watch(name, fn)
    assert(rawget(self, '__index') == nil, "Error!, watch() cannot be called on Classes. Call it from an instance!")
    if self._[name] == nil then
        error(("Error cannot watch property '%s', because it does not exist"):format(name))
        return
    end
    table.insert(self._[name], fn)
end

function Object:unwatch(name, fn)
    assert(rawget(self, '__index') == nil, "Error!, unwatch() cannot be called on Classes. Call it from an instance!")
    if self._[name] == nil then
        error(("Error cannot unwatch property '%s', because it does not exist"):format(name))
        return
    end
    table.remove(self._[name], fn)
end

local function createClass(superClass)
    local cls = superClass or Object
    local new_class = {}
    for k, v in pairs(cls) do
        if k:sub(1, 2) == "__" then
            new_class[k] = v
        end
    end
    new_class.__index = new_class
    new_class.super = cls
    setmetatable(new_class, cls)
    return new_class
end

return createClass
