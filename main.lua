-- RoRR Randomizer v1.0.1
-- SmoothSpatula

Toml = require("tomlHelper")

-- ========== Parameters ==========

local max_artis = 14
local max_skills = 4

local default_params = {
    randomize_character = true,
    randomize_skills = true,
    randomize_artifacts = true,

    min_skill = 1, --skill 0 is no skill
    max_skill = 142, --max skill id 205, max survivor skill id 142
    nb_skill = 4, -- number of skills to roll

    min_arti = 1, --min artifact  is id 1
    max_arti = 14, --max artifact is id 14
    nb_arti = 4 -- number of artifacts to roll
}

local params = Toml.load_cfg(_ENV["!guid"])

if not params then
   Toml.save_cfg(_ENV["!guid"], default_params)
   params = default_params
end

-- ========== ImGui ==========

-- turn on/off 
gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Random character", params['randomize_character'])
    if clicked then
        params['randomize_character'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)
gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Random skills", params['randomize_skills'])
    if clicked then
        params['randomize_skills'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)
gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Random artifacts", params['randomize_artifacts'])
    if clicked then
        params['randomize_artifacts'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

-- set values
--[[ still buggy
gui.add_to_menu_bar(function()
    local new_value, isChanged = ImGui.InputInt("Number of random skills", params['nb_skill'], 1, 2, 0)
    if isChanged and new_value<=max_skills and new_value >= 0 then
        params ['nb_skill'] = new_value
        Toml.save_cfg(_ENV["!guid"].."/cfg.toml", params)
    end
end)
]]
gui.add_to_menu_bar(function()
    local new_value, isChanged = ImGui.InputInt("Set of random artifacts", params['nb_arti'], 1, 2, 0)
    if isChanged and new_value<=max_artis and new_value >= 0 then
        params ['nb_arti'] = new_value
        Toml.save_cfg(_ENV["!guid"].."/cfg.toml", params)
    end
end)

-- ========== Utils ==========

function array_shuffle(x)
	for i = #x, 2, -1 do
		local j = math.random(i)
		x[i], x[j] = x[j], x[i]
	end
end

-- create random_array
function get_rand_list(min_id, max_id, n)
    local ar = {}
    for i = 1, max_id-min_id+1 do 
      ar[i] = i+min_id-1
    end
    array_shuffle(ar)
    return ar
end

-- ========== Main ==========

-- for all players (if you're randomizing you're also randomizing your friends)
function set_random_char()
    for i = 1, #gm.CInstance.instances_active do
        local inst = gm.CInstance.instances_active[i]
        if inst.object_index == gm.constants.oP then
            --set random survivor
            if params['randomize_character'] then
                local rnd_survivor = math.random(1,15)
                gm.player_set_class(inst, rnd_survivor)
            end
            --set random player skills
            if params['randomize_skills'] then
                local rnd_skills = get_rand_list(params['min_skill'], params['max_skill'], params['nb_skill'])
                for i = 1, params['nb_skill'] do
                    gm.actor_skill_set(inst, i-1, rnd_skills[i])
                end
            end
            --set random artifacts
            if params['randomize_artifacts'] then
                local rnd_arti = get_rand_list(params['min_arti'], params['max_arti'], params['nb_arti'])
                for i = 1, params['nb_arti'] do
                    local artifact = gm.variable_global_get("class_artifact")[rnd_arti[i]]
                    gm.array_set(artifact, 8, true)
                    gm.chat_add_message(gm["@@NewGMLObject@@"](gm.constants.ChatMessage, tostring(artifact[2])))
                end
            end
        end
    end
end

-- useful I assure you
local new_game = false
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    new_game = true
end)

-- randomize char when you land for the first time
gm.post_script_hook(gm.constants.actor_phy_on_landed, function(self, other, result, args)
    if new_game then
        new_game = false
        set_random_char()
    end
end)
