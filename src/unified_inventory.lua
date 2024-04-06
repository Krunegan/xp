if minetest.get_modpath("unified_inventory") then
	unified_inventory.register_button("lvl_top", {
		type = "image", 
		image = "xp_top_button.png",
		tooltip = "TOP 10 Level - XP",
		hide_lite=true,
		action = function(player)
			return xp_top_gui_function(player:get_player_name())
		end,
		condition = function(player)
			return minetest.check_player_privs(player:get_player_name(), {interact=true})
		end,
	})

	unified_inventory.register_button("xp_shop", {
		type = "image", 
		image = "xp_shop_button.png",
		tooltip = "XP SHOP",
		hide_lite=true,
		action = function(player)
			return show_shop_formspec(player)
		end,
		condition = function(player)
			return minetest.check_player_privs(player:get_player_name(), {interact=true})
		end,
	})
end