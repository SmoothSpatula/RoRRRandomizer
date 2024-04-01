--Toml-helper

local self = {}


self.load_cfg = function(path)
    local full_path = "ReturnOfModding/config/"..path
    local succeeded, table = pcall(toml.decodeFromFile, full_path)
    if not succeeded then
        print("Error loading "..full_path)
        return nil
    end
    return table
end

self.save_cfg = function (path, table)
    local full_path = "ReturnOfModding/config/"..path
    succeeded, documentOrErrorMessage = pcall(toml.encodeToFile, table, { file = full_path, overwrite = true })
    if not succeeded then
        print(documentOrErrorMessage)
        return nil
    end
    return 0
end

return self
