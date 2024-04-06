local mod_storage = minetest.get_mod_storage()
local file_path = minetest.get_worldpath() .. "/forbidden_tools.txt"
forbidden_tools = {}

local function load_forbidden_tools()
	local file = io.open(file_path, "r")
	if file then
		forbidden_tools = {}
		for line in file:lines() do
			table.insert(forbidden_tools, line)
		end
		file:close()
	end
end

local function save_forbidden_tools()
	local file = io.open(file_path, "w")
	if file then
		for _, tool in ipairs(forbidden_tools) do
			file:write(tool .. "\n")
		end
		file:close()
	end
end

load_forbidden_tools()
print("[XP MOD - FILE] forbidden_tools loaded")
minetest.register_on_shutdown(save_forbidden_tools)

function update_nametag(player)
    local name = player:get_player_name()
    local level = xp.level[name]
    local currentRank
    for _, rank in ipairs(xp.ranks) do
        if level >= rank.range[1] and level <= rank.range[2] then
            currentRank = rank
            break
        end
    end
    player:set_nametag_attributes({
        text = minetest.colorize(currentRank.color, currentRank.name) .. minetest.colorize("#FDFBFB", "\n[") .. minetest.colorize("#FFFFFF", name) .. minetest.colorize("#FDFBFB", "]")
    })
end

function add_xp_function(name, param)
	local params = param:split(" ")
	if #params ~= 2 then
		minetest.chat_send_player(name, "*** Server - [XP Command Error]: Invalid Arguments. Usage: /xp_add <player_name> <amount>")
		return
	end
	local playername = params[1]
	local player = minetest.get_player_by_name(playername)
	if not player then
		minetest.chat_send_player(name, "*** Server - [XP Command Error]: "..playername.." is not online.")
		return
	end
	local xp_to_add = tonumber(params[2])
	if not xp_to_add or xp_to_add < 1 then
		minetest.chat_send_player(name, "*** Server - [XP Command Error]: Insert a valid or positive amount.")
		return
	end
	xp.add_xp(player, xp_to_add)
	minetest.chat_send_player(name, "*** Server: You added "..minetest.colorize("yellow", "+"..xp_to_add).." XP to "..playername.."!")
end

function remove_xp_function(name, param)
	local params = param:split(" ")
	if #params ~= 2 then
		minetest.chat_send_player(name, "*** Server - [XP Command Error]: Invalid Arguments. Usage: /xp_remove <player_name> <amount>")
		return
	end
	local playername = params[1]
	local player = minetest.get_player_by_name(playername)
	if not player then
		minetest.chat_send_player(name, "*** Server - [XP Command Error]: "..playername.." is not online.")
		return
	end
	local xp_to_remove = tonumber(params[2])
	if not xp_to_remove or xp_to_remove < 1 then
		minetest.chat_send_player(name,  "*** Server - [XP Command Error]: Insert a valid or positive amount.")
		return
	end
	local current_xp = xp.xp[playername]
	if xp_to_remove > current_xp then
		xp_to_remove = current_xp
		xp.xp[playername] = 0
	else
		xp.xp[playername] = current_xp - xp_to_remove
	end
	mod_storage:set_int(playername.."_xp", xp.xp[playername])
    xp.update_hud(player, xp.level[playername], xp.xp[playername])
	minetest.chat_send_player(name, "*** Server: You removed "..minetest.colorize("yellow", "-"..xp_to_remove).." XP from "..minetest.colorize("#FFA500", playername).."!")
end

function set_level_function(name, param)
	local params = param:split(" ")
	if #params ~= 2 then
		minetest.chat_send_player(name, "*** Server - [XP Command Error]: Invalid Arguments. Usage: /xp_set_level <player_name> <level>")
		return
	end
	local playername = params[1]
	local player = minetest.get_player_by_name(playername)
	if not player then
		minetest.chat_send_player(name, "*** Server - [XP Command Error]: "..playername.." is not online.")
		return
	end
	local level = tonumber(params[2])
	if level == nil then
		minetest.chat_send_player(name, "*** Server - [XP MOD Error]: Invalid level")
		return
	end
	if level < 1 or level > 999 then
	  minetest.chat_send_player(name, "*** Server - [XP MOD Error]: Level must be between 1 and 999")
	  return
	end
	xp.level[playername] = level
	mod_storage:set_int(playername .. "_level", level)
	if player then
	  player:set_nametag_attributes({ text = minetest.colorize("#00FFD8", "Level: ") .. minetest.colorize("#FFF300", level) .. minetest.colorize("#FDFBFB", "\n[") .. minetest.colorize("#78FF00", playername) .. minetest.colorize("#FDFBFB", "]") })
	end
    xp.update_hud(player, xp.level[playername], xp.xp[playername])
	update_nametag(player)
	minetest.chat_send_player(name, "*** Server: You have set "..minetest.colorize("orange", playername).."'s level at "..level.."!")
end

function level_up_function(name, param)
    local params = param:split(" ")
    if #params ~= 1 then
        minetest.chat_send_player(name, "*** Server - [XP Command Error]: Invalid Arguments. Usage: /level_up <player_name>")
        return
    end    
    local playername = params[1]
    local player = minetest.get_player_by_name(playername)
    if not player then
        minetest.chat_send_player(name, "*** Server - [XP Command Error]: "..playername.." is not online.")
        return
    end
    local level = xp.level[playername]
    local xp_needed = xp.levelfunc(level) - xp.xp[playername] 
    xp.add_xp(player, xp_needed)
	minetest.chat_send_player(name, "*** Server: You have leveled up "..minetest.colorize("orange", playername).." to "..minetest.colorize("yellow", (level+1)).."!")
end

function level_down_function(name, param)
	local params = param:split(" ")
	if #params ~= 1 then
		minetest.chat_send_player(name, "*** Server - [XP Command Error]: Invalid Arguments. Usage: /level_down <player_name>")
		return
	end
	local playername = params[1]
	local player = minetest.get_player_by_name(playername)
	if not player then
		minetest.chat_send_player(name, "*** Server - [XP Command Error]: "..playername.." is not online.")
		return
	end
	local level = xp.level[playername]
	if level < 2 then
		minetest.chat_send_player(name, "*** Server - [XP Command Error]: "..playername.." is already at the lowest level.")
		return
	end
	local new_level = level - 1
	local new_xp = xp.levelfunc(new_level) - xp.levelfunc(new_level - 1)
	xp.level[playername] = new_level
	xp.xp[playername] = new_xp
    mod_storage:set_int(playername.."_level", new_level)
	mod_storage:set_int(playername.."_xp", new_xp)
    xp.update_hud(player, new_level, new_xp)
	update_nametag(player)
	minetest.chat_send_player(name, "*** Server: You have set a lower level to "..minetest.colorize("red", playername).."! Current level: "..minetest.colorize("yellow", new_level).." - Current XP: " ..minetest.colorize("yellow", new_xp))
end

function xp_reset_function(name, param)
    local params = param:split(" ")
    if #params ~= 1 then
        minetest.chat_send_player(name, "*** Server - [XP Command Error]: Invalid Arguments. Usage: /xp_reset <player_name>")
        return
    end
    local playername = params[1]
    local player = minetest.get_player_by_name(playername)
    if not player then
        minetest.chat_send_player(name, "*** Server - [XP Command Error]: "..playername.." is not online.")
        return
    end
    xp.level[playername] = 1
    mod_storage:set_int(playername.."_level", 1)
    xp.xp[playername] = 0
    mod_storage:set_int(playername.."_xp", 0)
    xp.update_hud(player, 1, 0)
	update_nametag(player)
	minetest.chat_send_player(name, "*** Server: You have resetted the XP/Level of "..minetest.colorize("red", playername).."!")
end

function xp_top_list_function(name)
	local output = "*** Server: XP Top 10:\n"
	local top = {}
	for _, player in ipairs(minetest.get_connected_players()) do
		local playername = player:get_player_name()
		local level = mod_storage:get_int(playername.."_level")
		if level > 0 then
			top[#top+1] = {name = playername, level = level}
		end
	end
	table.sort(top, function(a, b) return a.level > b.level end)
	local limit = math.min(#top, 10)
	for i = 1, limit do
		output = output..i..". "..top[i].name.." (Level: "..top[i].level..")\n"
	end
	minetest.chat_send_player(name, output)
end

function xp_top_gui_function(show_back_button, back_btn_pos)
	if show_back_button == nil then
		show_back_button = false
	end

	if back_btn_pos == nil then
		back_btn_pos = { x = 5.2, y = 7.6 }
	end

	local players = {}
	for _, player in ipairs(minetest.get_connected_players()) do
		local player_name = player:get_player_name()
		local player_xp = xp.xp[player_name] or 0
		local player_level = xp.level[player_name] or 1
		table.insert(players, {name = player_name, xp = player_xp, level = player_level})
	end
	table.sort(players, function(a, b)
		if a.xp == b.xp then
			return a.level > b.level
		else
			return a.xp > b.xp
		end
	end)
	local formspec = "size[8,8]"
	formspec = formspec .. "label[0,0;" .. minetest.colorize("#01B5F7", "TOP 10").." | Level - XP of online players" .. "]"
		.. "box[-0.1,-0.1;8,0.7;black]"
		.. "background9[-0.350,-0.35;8.650,8.850;xp_shop_bg.png;true]"

	if show_back_button then
		formspec = formspec .. "button[" .. back_btn_pos.x .. "," .. back_btn_pos.y .. ";3,0.8;xp_top_exit;Back]"
	end

	for i, player in ipairs(players) do
		if i <= 10 then
			local player_name = player.name
			local player_xp = player.xp
			local player_level = player.level
			local player_text = i .. ". ".. minetest.colorize("#01B5F7", player_name) .. "  (" .. minetest.colorize("orange", "Level " .. player_level) .. ", " .. minetest.colorize("yellow", player_xp .. " XP") .. ")"
			local y = 0.9 + (i - 1) * 0.5
			formspec = formspec .. "label[0," .. y .. ";" .. player_text .. "]"
				.. "box[-0.1,".. y ..";8,0.45;#030303]"
		end
	end

	return formspec
end

minetest.register_privilege("xp_manager", {
	description = "Manage players XP",
	give_to_singleplayer = false,
	give_to_admin = true
})

minetest.register_chatcommand("xp",{
	description = "Show the XP and level of the specified player (or your own XP if no player is specified)",
	params = "<player_name>",
	privs = {
		interact = true
	},
	func = function(name, param)
		if param == "" then
			param = name
		end
		local level = mod_storage:get_int(param.."_level")
		local XP = mod_storage:get_int(param.."_xp")
		minetest.chat_send_player(name, "*** Server: ".. param.." - "..minetest.colorize("yellow","Total XP: "..XP)..", "..minetest.colorize("orange","Level: "..level))
	end,
})

minetest.register_chatcommand("xp_add", {
	params = "<player_name> <amount>",
	description = "Adds XP to the specified player",
	privs = {
		xp_manager = true
	},
	func = add_xp_function,
})

minetest.register_chatcommand("xp_remove", {
	params = "<player_name> <amount>",
	description = "Remove XP to the specified player",
	privs = {
		xp_manager = true
	},
	func = remove_xp_function,
})

minetest.register_chatcommand("xp_set_level", {
	params = "<player_name> <level>",
	description = "Set level to the specified player",
	privs = {
		xp_manager = true
	},
	func = set_level_function,
})

minetest.register_chatcommand("xp_levelup", {
	params = "<player_name>",
	description = "Level up to specified player",
	privs = {
		xp_manager = true
	},
	func = level_up_function,
})

minetest.register_chatcommand("xp_leveldown", {
	params = "<player_name>",
	description = "Level down to specified player",
	privs = {
		xp_manager = true
	},
	func = level_down_function,
})

minetest.register_chatcommand("xp_top", {
	description = "EXP/Level TOP list (GUI)",
	privs = {
		interact = true
	},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player:is_player() ~= true then
            return false
        end

		minetest.show_formspec(name, "xp:top", xp_top_gui_function())
	end,
})

minetest.register_chatcommand("xp_top_list", {
	description = "EXP/Level TOP list",
	privs = {
		interact = true
	},
	func = xp_top_list_function,
})

minetest.register_chatcommand("xp_reset", {
	params = "<player_name>",
	description = "Reset Level/XP to specified player",
	privs = {
		xp_manager = true
	},
	func = xp_reset_function,
})

minetest.register_chatcommand("xp_add_ft", {
	params = "<modname:toolname>",
	description = "Add a tool to the list of forbidden tools",
	privs = {
		xp_manager = true
	},
	func = function(name, param)
		local mod, tool = param:match("([%w_]+):([%w_]+)")
		if mod and tool then
			local forbidden_tool = mod .. ":" .. tool
			for _, ft in ipairs(forbidden_tools) do
				if ft == forbidden_tool then
					return false, "*** Server: Tool already exists in the forbidden tool list."
				end
			end

			if minetest.registered_items[forbidden_tool] == nil then
				return false, "*** Server: The specified tool does not exist."
			end

			table.insert(forbidden_tools, forbidden_tool)
			save_forbidden_tools()
			return true, "*** Server: "..minetest.colorize("#01B5F7", name).." has added "..minetest.colorize("red", forbidden_tool).." to the forbidden tool list."
		else
			return false, "*** Server: Incorrect format. Use the format <modname:toolname>"
		end
	end,
})

minetest.register_chatcommand("xp_remove_ft", {
	params = "<modname:toolname>",
	description = "Remove a tool from the list of forbidden tools",
	privs = {
		xp_manager = true
	},
	func = function(name, param)
		local mod, tool = param:match("([%w_]+):([%w_]+)")
		if mod and tool then
			local forbidden_tool = mod .. ":" .. tool
			for i, ft in ipairs(forbidden_tools) do
				if ft == forbidden_tool then
					table.remove(forbidden_tools, i)
					save_forbidden_tools()
					return true, "*** Server: "..minetest.colorize("#01B5F7", name).." has removed "..minetest.colorize("green", forbidden_tool).." from the forbidden tool list."
				end
			end
			return false, "*** Server: The tool is not in the forbidden tool list: " .. forbidden_tool
		else
			return false, "*** Server: Incorrect format. Use the format <modname:toolname>"
		end
	end,
})

minetest.register_chatcommand("xp_show_ft", {
    params = "",
    description = "Show list of forbidden tools",
    privs = {
		xp_manager = true
	},
    func = function(name, param)
        if #forbidden_tools == 0 then
            return false, "The forbidden tool list is empty."
        end

        local tools_list = "Forbidden tool list:\n"
        for _, tool in ipairs(forbidden_tools) do
            tools_list = tools_list .. tool .. "\n"
        end
        return true, tools_list
    end,
})