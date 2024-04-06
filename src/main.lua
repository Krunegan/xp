--[[

The MIT License (MIT)
Copyright (C) 2023 Flay Krunegan

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

]]

xp = {}
xp.values = {}

local lane = minetest.get_modpath('xp')

dofile(lane.."/src/values.lua")
dofile(lane.."/src/items.lua")
dofile(lane.."/src/ranks.lua")
dofile(lane.."/src/mobs.lua")

xp.level = {}
xp.xp = {}
xp.status = {}
xp.huds = {}
xp.huds2 = {}
xp.bg = {}
xp.bar = {}
xp.bar_bg = {}

local mod_storage = minetest.get_mod_storage()

function xp.levelfunc(level)
	return (math.floor(1^level)+4999)
end

function xp.get_rank_name(level)
    for _, rank in ipairs(xp.ranks) do
        if level >= rank.range[1] and level <= rank.range[2] then
            return rank.name
        end
    end
    return nil
end

function xp.add_xp(player, XP)
    local name = player:get_player_name()
    XP = xp.xp[name] + XP
    local level = xp.level[name]
    local temp = level
    local previousRank = xp.get_rank_name(level)
    if (xp.levelfunc(level) - XP) < 1 then
        XP = XP - xp.levelfunc(level)
        level = level + 1
        xp.level[name] = level
        mod_storage:set_int(name .. "_level", level)
        if xp.values[level] then
            local reward = xp.values[level]
            minetest.chat_send_player(name, "*** Server: You've reached level " .. minetest.colorize("yellow", level) .. " and received " .. reward[2] .. "x " .. reward[1])
            local leftover = player:get_inventory():add_item("main", ItemStack(reward[1] .. " " .. reward[2]))
            if not leftover:is_empty() then
                local pos = player:get_pos()
                minetest.add_item(pos, leftover)
                minetest.chat_send_player(name, minetest.colorize("red", "*** Server: Your inventory is full. The reward has been dropped on the ground."))
            end
        end
    end
    if temp ~= level then
        minetest.chat_send_all("*** Server: " .. minetest.colorize("#01B5F7", name) .. " has reached level " .. minetest.colorize("orange", level) .. ", " .. minetest.colorize("#1fe600", "Congratulations!"))
        if minetest.get_modpath("relay_mod") then
			sendToDiscord("***+Server:+" .. name .. "+has+reached+level+" .. level .. ",+Congratulations!")
		end
		local currentRank
        for _, rank in ipairs(xp.ranks) do
            if level >= rank.range[1] and level <= rank.range[2] then
                currentRank = rank
                break
            end
        end
        if previousRank ~= currentRank.name then
            minetest.chat_send_all("*** Server: " .. minetest.colorize("#01B5F7", name) .. " has reached the rank " .. minetest.colorize(currentRank.color, currentRank.name) .. "!")
            player:set_nametag_attributes({
                text = minetest.colorize(currentRank.color, currentRank.name) .. minetest.colorize("#FDFBFB", "\n[") .. minetest.colorize("#FFFFFF", name) .. minetest.colorize("#FDFBFB", "]")
            })
        end
        local reward = xp.get_reward(level)
        if reward and minetest.registered_items[reward.name] then
            minetest.chat_send_player(name, "*** Server: You've reached level " ..
                minetest.colorize("#01B5F7", level) .. " and received " ..
                minetest.colorize("orange", reward.name) .. minetest.colorize("yellow", " x" .. reward.count))

            local leftover = player:get_inventory():add_item("main", ItemStack(reward.name .. " " .. reward.count))
            if not leftover:is_empty() then
                local pos = player:get_pos()
                minetest.add_item(pos, leftover)
                minetest.chat_send_player(name, minetest.colorize("red", "*** Server: Your inventory is full. The reward has been dropped on the ground."))
            end
        end
    end
    xp.xp[name] = XP
    mod_storage:set_int(name .. "_xp", XP)
    xp.update_hud(player, level, XP)
end


function xp.lose_xp(player)
    local player_name = player:get_player_name()
	local level = xp.level[player_name]
    local XP = xp.xp[player_name]
    local lostXP = math.floor(XP * 0.1)
    xp.xp[player_name] = XP - lostXP
    mod_storage:set_int(player_name.."_xp", xp.xp[player_name])
	xp.update_hud(player,level, xp.xp[player_name])
	minetest.chat_send_player(player_name, minetest.colorize("#FF0000", "*** Server: You have lost " ..lostXP.." xp!" ))
end

local default_hud_scale = 2.45
local default_hud_size = {x = 145, y = 10}
local default_hud_offset = {x = 0, y = 30}
local default_hudbar_position = {x = 0.6845, y = -0.030}
local default_hudbar_bg_position = {x = 0.6845, y = -0.019}
local default_huds2_position = {x = 0.958, y = -0.001}
local default_huds_position = {x = 0.885, y = -0.001}
local config_file = minetest.get_worldpath() .. "/xp_hud.conf"
local hud_configurations = {}

local function load_hud_configs()
	local file = io.open(config_file, "r")
	if file then
		local data = file:read("*a")
		io.close(file)
		hud_configurations = minetest.deserialize(data) or {}
	end
end

local function save_hud_configs()
	local file = io.open(config_file, "w")
	if file then
		file:write(minetest.serialize(hud_configurations))
		io.close(file)
	end
end

load_hud_configs()

minetest.register_chatcommand("xp_hud", {
	params = "<1|2|off>",
	description = "Change the HUD configuration",
	func = function(name, param)
		if param == "1" then
			hud_configurations[name] = {
				scale = 2.9,
				size = {x = 145, y = 10},
				offset = {x = 0, y = 30},
				huds_position = {x = 0.885, y = -0.001},
				huds2_position = {x = 0.958, y = -0.001},
				hudbar_position = {x = 0.6845, y = -0.030},
				hudbar_bg_position = {x = 0.6845, y = -0.019}
			}
			minetest.chat_send_player(name, "*** Server: XP HUD configuration set to PC")
			local player = minetest.get_player_by_name(name)
			if player then
				xp.update_hud(player, xp.level[name], xp.xp[name])
			end
		elseif param == "2" then
			hud_configurations[name] = {
				scale = 2.9,
				size = {x = 145, y = 10},
				offset = {x = 0, y = 30},
				huds_position = {x = 0.865, y = -0.001},
				huds2_position = {x = 0.938, y = -0.001},
				hudbar_position = {x = 0.5925, y = -0.0445},
				hudbar_bg_position = {x = 0.5925, y = -0.029}
			}
			minetest.chat_send_player(name, "*** Server: XP HUD configuration set to Phone")
			local player = minetest.get_player_by_name(name)
			if player then
				xp.update_hud(player, xp.level[name], xp.xp[name])
			end
		elseif param == "off" then
			hud_configurations[name] = nil
			minetest.chat_send_player(name, "*** Server: XP HUD configuration disabled")
			local player = minetest.get_player_by_name(name)
			if player then
				xp.remove_hud(player)
			end
		else
			minetest.chat_send_player(name, "Invalid parameter. Usage: /xp_hud <1|2|off>")
		end
	end,
})

function xp.update_hud(player, level, XP)
	local name = player:get_player_name()
	local perc = XP / xp.levelfunc(level)
	local hud_xp = "XP: "..string.format("%04d", XP).."/"..(xp.levelfunc(level))
	local hud_level = "Level: "..level

	if hud_configurations[name] == nil then
		xp.remove_hud(player)
		return
	end

	if xp.huds[name] then
		player:hud_change(xp.huds[name], "text", hud_xp)
		player:hud_change(xp.huds2[name], "text", hud_level)

		if xp.bar[name] and xp.bar_bg[name] then
			local config = hud_configurations[name] or {}
			local scale = config.scale or default_hud_scale
			local size = config.size or default_hud_size
			local offset = config.offset or default_hud_offset
			local huds_position = config.huds_position or default_huds_position
			local huds2_position = config.huds2_position or default_huds2_position
			local hudbar_position = config.hudbar_position or default_hudbar_position
			local hudbar_bg_position = config.hudbar_bg_position or default_hudbar_bg_position

			player:hud_change(xp.bar[name], "offset", offset)
			player:hud_change(xp.bar[name], "scale", {x = scale * perc, y = 2.5})
			player:hud_change(xp.bar_bg[name], "offset", offset)
			player:hud_change(xp.bar_bg[name], "scale", {x = scale, y = 3})
			player:hud_change(xp.huds[name], "offset", offset)
			player:hud_change(xp.huds2[name], "offset", offset)
			player:hud_change(xp.huds[name], "position", huds_position)
			player:hud_change(xp.huds2[name], "position", huds2_position)
			player:hud_change(xp.bar[name], "position", hudbar_position)
			player:hud_change(xp.bar_bg[name], "position", hudbar_bg_position)
		end
	else
		local config = hud_configurations[name] or {}
		local scale = config.scale or default_hud_scale
		local size = config.size or default_hud_size
		local offset = config.offset or default_hud_offset
		local huds_position = config.huds_position or default_huds_position
		local huds2_position = config.huds2_position or default_huds2_position
		local hudbar_position = config.hudbar_position or default_hudbar_position
		local hudbar_bg_position = config.hudbar_bg_position or default_hudbar_bg_position

		xp.bar[name] = player:hud_add({
			hud_elem_type = "image",
			position = hudbar_position,
			offset = offset,
			scale = {x = scale * perc, y = 2.5},
			alignment = {x = 1, y = 0.33},
			direction = 2,
			text = "xp_bar_fg.png"
		})
		xp.bar_bg[name] = player:hud_add({
			hud_elem_type = "image",
			position = hudbar_bg_position,
			offset = offset,
			scale = {x = scale, y = 2.9},
			alignment = {x = 1, y = 0.33},
			direction = 2,
			text = "xp_bar_bg.png"
		})

		xp.huds2[name] = player:hud_add({
			hud_elem_type = "text",
			position = huds2_position,
			offset = offset,
			scale = {x = 100, y = 100},
			text = hud_level,
			number = 0xFFFFFF,
			alignment = {x = 0.3, y = 0.5},
			direction = 2,
		})
		xp.huds[name] = player:hud_add({
			hud_elem_type = "text",
			position = huds_position,
			offset = offset,
			scale = {x = 100, y = 100},
			text = hud_xp,
			number = 0xFFFFFF,
			alignment = {x = 0.3, y = 0.5},
			direction = 2,
		})
	end
end

function xp.remove_hud(player)
	local name = player:get_player_name()
	if xp.bar[name] then
		player:hud_remove(xp.bar[name])
		xp.bar[name] = nil
	end
	if xp.bar_bg[name] then
		player:hud_remove(xp.bar_bg[name])
		xp.bar_bg[name] = nil
	end
	if xp.huds[name] then
		player:hud_remove(xp.huds[name])
		xp.huds[name] = nil
	end
	if xp.huds2[name] then
		player:hud_remove(xp.huds2[name])
		xp.huds2[name] = nil
	end
end

minetest.register_on_shutdown(save_hud_configs)
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    local level = mod_storage:get_int(name .. "_level")
    local XP = mod_storage:get_int(name .. "_xp")
    if level == 0 then
        level = 1
        mod_storage:set_int(name .. "_level", level)
    end
    if XP == 0 then
        XP = 0
        mod_storage:set_int(name .. "_xp", XP)
    end
    xp.level[name] = level
    xp.xp[name] = XP
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
    xp.update_hud(player, level, XP)
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	xp.huds[name] = nil
	xp.level[name] = nil
	xp.xp[name] = nil
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
	local XP = xp.values[oldnode.name]
	if digger then
		if digger:is_player() ~= true then return end
		local name = digger:get_player_name()
		local itemstack = digger:get_wielded_item()
		for _, tool in ipairs(forbidden_tools) do
			if tool == itemstack:get_name() then
				return
			end
		end
		if XP and name and xp.level[name] then
			XP = XP * (math.ceil(xp.level[name] / 30))
			xp.add_xp(digger, XP)
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if not xp.xp[name] then
		xp.xp[name] = 0
	end
	if not xp.level[name] then
		xp.level[name] = 1
	end
	if not xp.status[name] then
		xp.status[name] = "alive"
	end
end)

minetest.register_on_dieplayer(function(player)
	local name = player:get_player_name()
	if xp.status[name] == "alive" then
		xp.status[name] = "dead"
		xp.lose_xp(player)
	end
end)

minetest.register_on_respawnplayer(function(player)
	local name = player:get_player_name()
	xp.status[name] = "alive"
end)

minetest.register_on_punchplayer(function(player, hitter, _, _, _, damage)
	if not (hitter and hitter:is_player()) then
		return 
	end
	local hp = player:get_hp()
	if hp - damage > 0 or hp <= 0 then
		return
	end
	local hitter_name = hitter:get_player_name()
	local player_name = player:get_player_name()
	local level = xp.level[player_name]
	local level2 = xp.level[hitter_name]
    local XP = xp.xp[player_name]
    local XP2 = xp.xp[hitter_name]
    local xpChange = math.floor(XP * 0.1)
    xp.xp[hitter_name] = XP2 + xpChange
    mod_storage:set_int(hitter_name.."_xp", xp.xp[hitter_name])
	minetest.chat_send_all("*** Server: "..minetest.colorize("#01B5F7", hitter_name).." killed to "..minetest.colorize("orange", player_name).." and got ".. minetest.colorize("#00ff00", xpChange).." XP!")
    minetest.chat_send_player(hitter_name, minetest.colorize("#00FF00", "*** Server: You have got " ..xpChange.." xp!" ))
	xp.update_hud(hitter, level2, XP2)
end)