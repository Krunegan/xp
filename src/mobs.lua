-- Overrides the `on_die` functions of all Mobs Redo monsters and gives the player XP.
-- To discuss: XP assisting.

local mobs = {
    -- Mobs Monsters
    {id = "mobs_monster:dirt_monster", name = "Dirt Monster"},
    {id = "mobs_monster:dungeon_master", name = "Dungeon Master"},
    {id = "mobs_monster:oerkki", name = "Oerkki"},
    {id = "mobs_monster:sand_monster", name = "Sand Monster"},
    {id = "mobs_monster:stone_monster", name = "Stone Monster"},
    {id = "mobs_monster:tree_monster", name = "Tree Monster"},
    {id = "mobs_monster:lava_flan", name = "Lava Flan"},
    {id = "mobs_monster:mese_monster", name = "Mese Monster"},
    {id = "mobs_monster:spider", name = "Spider"},
    {id = "mobs_monster:land_guard", name = "Land Guard"},
    {id = "mobs_monster:fire_spirit", name = "Fire Spirit"},
    -- Spawners mobs
    {id = "spawners_mobs:balrog", name = "Balrog"},
    {id = "spawners_mobs:bunny_evil", name = "Bunny Evil"},
    {id = "spawners_mobs:mummy", name = "Mummy"},
    {id = "spawners_mobs:uruk_hai", name = "Uruk Hai"},
    {id = "mobs_bat:bat", name = "Bat"},
    -- Mobs Sharks
    {id = "mobs_sharks:shark_lg", name = "Shark Large"},
    {id = "mobs_sharks:shark_md", name = "Shark Medium"},
    {id = "mobs_sharks:shark_sm", name = "Shark Small"},
    -- Mobs Skeleton
    {id = "mobs_skeletons:skeleton", name = "Skeleton"},
    {id = "mobs_skeletons:skeleton_archer", name = "Archer Skeleton"},
    {id = "mobs_skeletons:skeleton_archer_dark", name = "Dark Archer Skeleton"},
    -- Mobs Ghost
    {id = "mobs_ghost_redo:ghost", name = "Ghost"},
    -- Zombies4Test
    {id = "walkingzombie:walkingzombie", name = "Walking Zombie"},
    {id = "minerzombie:minerzombie", name = "Miner Zombie"},
    {id = "survivorzombie:survivorzombie", name = "Survivor Zombie"},
    {id = "lumberjackzombie:lumberjackzombie", name = "Lumberjack Zombie"},
    {id = "doctorzombie:doctorzombie", name = "Doctor Zombie"},
    {id = "runner:runner", name = "Runner Zombie"},
    {id = "crawlerzombie:crawlerzombie", name = "Crawler Zombie"},
    {id = "spitterzombie:spitterzombie", name = "Spitter Zombie"},
    {id = "tankzombie:tankzombie", name = "Tank Zombie"},
}

local xp_amounts = {
    -- Mobs Monsters
    ["mobs_monster:dirt_monster"] = 7,
    ["mobs_monster:dungeon_master"] = 40,
    ["mobs_monster:oerkki"] = 12,
    ["mobs_monster:sand_monster"] = 7,
    ["mobs_monster:stone_monster"] = 5,
    ["mobs_monster:tree_monster"] = 5,
    ["mobs_monster:lava_flan"] = 12,
    ["mobs_monster:mese_monster"] = 3,
    ["mobs_monster:spider"] = 6,
    ["mobs_monster:land_guard"] = 15,
    ["mobs_monster:fire_spirit"] = 10,
    -- Spawners mobs
    ["spawners_mobs:balrog"] = 500,
    ["spawners_mobs:bunny_evil"] = 5,
    ["spawners_mobs:mummy"] = 14,
    ["spawners_mobs:uruk_hai"] = 14,
    ["mobs_bat:bat"] = 14,
    -- Mobs Sharks
    ["mobs_sharks:shark_lg"] = 14,
    ["mobs_sharks:shark_md"] = 7,
    ["mobs_sharks:shark_sm"] = 3,
    -- Mobs Skeleton
    ["mobs_skeletons:skeleton"] = 5,
    ["mobs_skeletons:skeleton_archer"] = 7,
    ["mobs_skeletons:skeleton_archer_dark"] = 9,
    -- Mobs Ghost
    ["mobs_ghost_redo:ghost"] = 5,
    -- Zombies4Test
    ["walkingzombie:walkingzombie"] = 7,
    ["minerzombie:minerzombie"] = 7,
    ["survivorzombie:survivorzombie"] = 7,
    ["lumberjackzombie:lumberjackzombie"] = 4,
    ["doctorzombie:doctorzombie"] = 4,
    ["runner:runner"] = 7,
    ["crawlerzombie:crawlerzombie"] = 3,
    ["spitterzombie:spitterzombie"] = 45,
    ["tankzombie:tankzombie"] = 100,
}

minetest.register_on_mods_loaded(function()
    for _, mob in ipairs(mobs) do
        local registered_entity = minetest.registered_entities[mob.id]
        if registered_entity then
            local old_on_die = registered_entity.on_die
            registered_entity.on_die = function(self, pos)
                local player = self.cause_of_death and self.cause_of_death.puncher
                if player and player:is_player() then
                    local player_name = player:get_player_name()
                    local mob_name = mob.name or ""
                    local mob_xp_amount = xp_amounts[mob.id] or 5
                    minetest.chat_send_player(player_name, "*** Server: you've killed a ".. minetest.colorize("orange", mob_name).." and earned ".. minetest.colorize("#1fe600", mob_xp_amount) .. " XP!")
                    xp.add_xp(player, mob_xp_amount)
                end

                if old_on_die then
                    return old_on_die(self, pos)
                end
            end
        end
    end
end)
