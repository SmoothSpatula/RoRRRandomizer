--Toml-helper

local self = {}
local cfg_path = "ReturnOfModding/config/"
local cfg_name = "/cfg.toml"
local create_dir_path = path.combine(
        path.get_parent(path.get_parent(_ENV["!plugins_mod_folder_path"])),
        "config",
        _ENV["!guid"]
    )

self.load_cfg = function(plugin_path)
    local full_path = cfg_path..plugin_path..cfg_name
    local succeeded, table = pcall(toml.decodeFromFile, full_path)
    if not succeeded then
        print("Error loading "..full_path)
        return nil
    end
    log.info("config file successfully loaded")
    return table
end

self.save_cfg = function (plugin_path, table)

    if gm.directory_exists(create_dir_path) ==.0 then
        log.info("Creating config directory")
        gm.directory_create(create_dir_path)
    end
    local full_path = cfg_path..plugin_path..cfg_name
    succeeded, documentOrErrorMessage = pcall(toml.encodeToFile, table, { file = full_path, overwrite = true })
    if not succeeded then
        print(documentOrErrorMessage)
        return nil
    end
    return 0
end

return self
