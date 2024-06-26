-- RoRR Randomizer v1.0.8
-- SmoothSpatula

mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end end)

mods.on_all_mods_loaded(function() 
    -- find chatconsole script
    for k, v in pairs(mods) do if type(v) == "table" and v.chatconsole then ChatConsole = v end end 
    -- add the function you want to add
    for k, v in pairs(mods) do
        if type(v) == "table" and v.randomizermod then 
            -- name in the function array, reference, usage text, command ("/example")
            -- optional fields go at the end after mandatory fields (you can avoid doing this if you know what you're doing)
            -- you can overwrite default commands by using the same name (here examplemod_examplefunc)
            ChatConsole.add_function("RoRRRandomizer_randomize", v.randomize, "r", "<y>/r")
        end 
    end
end)

-- ========== Parameters ==========

local MAX_ARTI = 14
local MAX_SKILL = 4
local is_init = false
randomizermod = true -- this lets you locate your own mod later

local params = {}

function late_init()
    params = {
        randomize_character = true,
        randomize_skills = true,
        randomize_artifacts = false,
    
        min_skill = 1, --skill 0 is no skill
        max_skill = 143, --max skill id 205, max survivor skill id 143
        nb_skill = 4, -- number of skills to roll
    
        min_arti = 1, --min artifact  is id 1
        max_arti = 14, --max artifact is id 14
        nb_arti = 4,  -- number of artifacts to roll
        skill = get_skills(1,143)
    }

    -- disable bugged/unusable skills
    params = Toml.config_update(_ENV["!guid"], params)

    local bugged_skills = {1,57,58,59,62,63,39,43,44,45,69,70,71,129,131,132,133,135,136}
    for i= 1, #bugged_skills do
        params['skill'][tostring(bugged_skills[i])].enabled = false
    end
    Toml.save_cfg(_ENV["!guid"], params)
    --[[ Sanity check
    for i = params['min_skill'] , params['max_skill'] do
        print(i.." "..params['skill'][i..''].name.."  "..tostring(params['skill'][i..''].enabled))
    end 
    ]]
    
    -- add skill enable gui
    
    gui.add_to_menu_bar(function()
        ImGui.TextColored(1, 0.5, 1, 1, "-- Enable/Disable skills --")
        for i = params['min_skill'], params['max_skill'] do
            local c = "  " 
            if params['skill'][tostring(i)].enabled then c = "v" end
            if ImGui.Button("["..c.."]  "..params['skill'][i..''].name) then
                params['skill'][i..''].enabled = not params['skill'][i..''].enabled
                Toml.save_cfg(_ENV["!guid"], params)
            end
        end
    end)

end

-- ========== Utils ==========

-- If you have a better algorithm pls let me know
function fast_rnd_pick(ar, n)
    local rnd_ar = {}
    local count = #ar
    for i = 1, n do 
        local rnd_nb = math.random(1, count)
        rnd_ar[i] = ar[rnd_nb]
        ar[rnd_nb] = ar[count]
        count = count-1
    end
    return rnd_ar
end

function get_rand_skills(n)
    local ar = {}
    local count = 0
    -- get all enabled skills
    for i = params['min_skill'], params['max_skill'] do
        if params['skill'][i..''].enabled then
            count = count+1
            ar[count] = i
        end
    end
    return fast_rnd_pick(ar, n)
end

function get_rand_artifacts(n)
    local ar = {}
    local count = 0
    -- get all artifacts
    for i = params['min_arti'], params['max_arti'] do
        count = count+1
        ar[count] = i
    end
    return fast_rnd_pick(ar, n)
end

function get_skills(min_id, max_id)
    local skills = gm.variable_global_get("class_skill")
    local tab = {}
    for i = min_id , max_id do
        -- I should be executed on the spot for doing this but lua/toml gave me no choice
        tab[i..'']= {name =  skills[i][2], enabled = true}
    end 
    return tab
end

-- ========== Command ==========

-- lets
function randomize(actor)
    set_random_char(false, true, true)
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
    local new_value, isChanged = ImGui.InputInt("Number of random artifacts", params['nb_arti'], 1, 2)
    if isChanged and new_value <= MAX_ARTI and new_value >= 0 then
        params ['nb_arti'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

-- ========== Late Init ==========

gm.post_script_hook(gm.constants.stage_load_room, function(self, other, result, args)
    if not is_init then 
        is_init = true
        late_init() end
end)

-- ========== Main ==========

-- for all players (if you're randomizing you're also randomizing your friends)
function set_random_char(rand_artifacts, rand_character, rand_skills)
    --set random artifacts
    if rand_artifacts then
        local rnd_arti = get_rand_artifacts(params['nb_arti'])
        for i = 1, params['nb_arti'] do
            local artifact = gm.variable_global_get("class_artifact")[rnd_arti[i]]
            gm.array_set(artifact, 8, true)
            print("artifact of "..tostring(artifact[2]))
            gm.chat_add_message(gm["@@NewGMLObject@@"](gm.constants.ChatMessage, "artifact of "..tostring(artifact[2])))
        end
    end
    for i = 1, #gm.CInstance.instances_active do
        local inst = gm.CInstance.instances_active[i]
        if inst.object_index == gm.constants.oP then
            --set random survivor
            if rand_character then
                local rnd_survivor = math.random(0,15)
                gm.player_set_class(inst, rnd_survivor)
            end
            --set random player skills
            if rand_skills then
                local rnd_skills = get_rand_skills(params['nb_skill'])
                for i = 1, params['nb_skill'] do
                    gm.actor_skill_set(inst, i-1, rnd_skills[i])
                    log.info("skill "..i.." : id = "..rnd_skills[i])
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
        set_random_char(params['randomize_artifacts'], params['randomize_character'], params['randomize_skills'])
    end
end)
