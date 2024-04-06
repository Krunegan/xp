local shop_items = {}
local current_page = 1
local max_seller_name_length = 10
local mod_storage = minetest.get_mod_storage()
local shop_file = minetest.get_worldpath() .. "/shop_data.txt"

local function load_shop_data()
    local file = io.open(shop_file, "r")
    if file then
        local data = file:read("*a")
        io.close(file)
        shop_items = minetest.deserialize(data) or {}
    end
end

local function save_shop_data()
    local file = io.open(shop_file, "w")
    if file then
        file:write(minetest.serialize(shop_items))
        io.close(file)
    end
end

load_shop_data()
local max_items_per_player = 12

minetest.register_chatcommand("sell", {
    params = "<price>",
    description = "Sell the item in hand to the shop",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            local wielded_itemstack = player:get_wielded_item()
            local item_name = wielded_itemstack:get_name()
            local item_count = wielded_itemstack:get_count()
            if item_name ~= "air" and item_count > 0 then
                local price = tonumber(param)
                if price and price > 0 and price <= 4999 then
                    local seller_is_buyer = false
                    if xp.xp[name] then
                        seller_is_buyer = true
                    end
                    local num_items_sold_by_player = 0
                    for _, item in ipairs(shop_items) do
                        if item.seller == name then
                            num_items_sold_by_player = num_items_sold_by_player + 1
                        end
                    end
                    if num_items_sold_by_player < max_items_per_player then
                        table.insert(shop_items, {name = item_name, amount = item_count, price = price, seller = name, seller_is_buyer = seller_is_buyer})
                        save_shop_data()
                        wielded_itemstack:clear()
                        player:set_wielded_item(wielded_itemstack)
                        minetest.chat_send_player(name, minetest.colorize("#89bf00", "*** XP SHOP: Item: " .. item_name .. " | Amount: x" .. item_count .. " | Price: " .. price .. " XP, item successfully added to the shop."))
                    else
                        minetest.chat_send_player(name, "*** XP SHOP: You have reached the maximum limit of items you can sell.")
                    end
                else
                    minetest.chat_send_player(name, "*** XP SHOP: Invalid price. Price must be between 1 and 4999 XP. Usage: /sell <price>")
                end
            else
                minetest.chat_send_player(name, "*** XP SHOP: Hold a valid item in your hand to sell.")
            end
        end
    end,
})

function truncate_string(str, max_length)
    if #str > max_length then
        return string.sub(str, 1, max_length) .. "..."
    else
        return str
    end
end

function show_shop_formspec(player)
    local player_name = player:get_player_name()
    local formspec = "size[11,8]"..
        "bgcolor[#080808BB;true]" ..
        "background9[0,0;11,8;xp_shop_bg.png;true]"
    local items_per_row = 4
    local row_height = 2.5
    local items_per_page = items_per_row * 3
    local start_index = (current_page - 1) * items_per_page + 1
    local end_index = math.min(current_page * items_per_page, #shop_items)
    for index = start_index, end_index do
        local item = shop_items[index]
        local itemdef = minetest.registered_items[item.name]
        if itemdef then
            local relative_index = index - start_index
            local col_index = relative_index % items_per_row
            local row_index = math.floor(relative_index / items_per_row)
            local x_position = 0 + col_index * 3
            local y_position = 0 + row_index * row_height
            local button_label = "Buy"
            local button_txt_color = "#49f500"
            local button_color = "xp_bg.png"
            if item.seller == player_name then
                button_label = "Delete"
                button_txt_color = "#ff1c1c"
                -- button_color = "xp_button_red.png"
            end
            formspec = formspec ..
                "item_image[" .. x_position .. "," .. y_position .. ";1,1;" .. itemdef.name .. "]" ..
                -- "label[" .. (x_position) .. "," .. (y_position + 1.1) .. ";" .. item.name .. "]" ..
                "label[" .. (x_position + 1) .. "," .. (y_position + 0.27) .. ";-" .. item.price .. "XP]" ..
                "label[" .. (x_position + 0.55) .. "," .. (y_position + 0.55) .. ";x" .. item.amount .. "]" ..
                "label[" .. (x_position) .. "," .. (y_position + 1) .. ";Seller: " .. truncate_string(item.seller, max_seller_name_length) .. "]"..
                "image_button[" .. (x_position) .. "," .. (y_position + 1.5) .. ";1.5,0.8;" .. button_color .. ";" .. "buy_" .. index .. ";" .. minetest.colorize(button_txt_color, button_label) .. "]"
        else
            minetest.log("warning", "Item definition not found for " .. item.name)
        end
    end
    local total_pages = math.ceil(#shop_items / items_per_page)
    local buyer_xp = xp.xp[player_name] or 0
    formspec = formspec ..
        "label[0,7.65;Page: " .. current_page .. "/" .. total_pages .. "]" ..
        "label[2,7.65;Items: " .. #shop_items .. "]".. 
        "label[4,7.65;Your XP: " .. buyer_xp .. "]" 

    if current_page > 1 then
        formspec = formspec .. "image_button[7,7.6;2,0.8;xp_bg.png;prev_page;<==]"
    end
    if end_index < #shop_items then
        formspec = formspec .. "image_button[9,7.6;2,0.8;xp_bg.png;next_page;==>]"
    end
    minetest.show_formspec(player_name, "shop", formspec)
end

local pending_transactions = {}
local transactions_file = minetest.get_worldpath() .. "/transactions_data.txt"

local function load_pending_transactions()
    local file = io.open(transactions_file, "r")
    if file then
        local data = file:read("*a")
        io.close(file)
        pending_transactions = minetest.deserialize(data) or {}
    end
end

local function save_pending_transactions()
    local file = io.open(transactions_file, "w")
    if file then
        file:write(minetest.serialize(pending_transactions))
        io.close(file)
    end
end

load_pending_transactions()

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "shop" then
        local player_name = player:get_player_name()
		if fields.quit then
            return
        end
        if fields.prev_page then
            current_page = math.max(current_page - 1, 1)
        elseif fields.next_page then
            current_page = current_page + 1
        else
            for index, item in ipairs(shop_items) do
                local buy_button = "buy_" .. index
                if fields[buy_button] then
                    local buyer_xp = xp.xp[player_name] or 0
                    local seller_name = item.seller                    
                    if buyer_xp >= item.price or player_name == seller_name then
                        xp.xp[player_name] = buyer_xp - item.price
                        mod_storage:set_int(player_name .. "_xp", xp.xp[player_name])
                        local seller_name = item.seller
                        local seller_player = minetest.get_player_by_name(seller_name)
                        if seller_player then
							xp.xp[seller_name] = (xp.xp[seller_name] or 0) + item.price
							mod_storage:set_int(seller_name .. "_xp", xp.xp[seller_name])
							if player_name ~= seller_name then
                                minetest.chat_send_player(seller_name, "*** XP SHOP: "..minetest.colorize("#01B5F7", seller_name) .. ", you received " .. minetest.colorize("green", item.price) .. " XP for your recent sales!")
                            end
                            local seller_player = minetest.get_player_by_name(seller_name)
							if seller_player then
								xp.update_hud(seller_player, xp.level[seller_name], xp.xp[seller_name])
							end
                        else
                            table.insert(pending_transactions, {seller = seller_name, xp = item.price})
                            save_pending_transactions()
                        end
                        local buyer_inv = player:get_inventory()
                        buyer_inv:add_item("main", ItemStack(item.name .. " " .. item.amount))
                        table.remove(shop_items, index)
                        save_shop_data()
                        xp.update_hud(player, xp.level[player_name], xp.xp[player_name])
                        if player_name ~= seller_name then
                            minetest.chat_send_player(player_name, minetest.colorize("#259400", "*** XP SHOP: you have successfully purchased " .. item.name .. " x" .. item.amount ..", -"..item.price.." XP!"))
                        else
                            minetest.chat_send_player(player_name, minetest.colorize("orange", "*** XP SHOP: you have successfully removed " .. item.name .. " x" .. item.amount .." from the XP shop!"))
                        end
                    else
                        minetest.chat_send_player(player_name, minetest.colorize("red", "*** XP SHOP: Not enough XP to purchase " .. item.name))
                    end
                    show_shop_formspec(player)
                end
            end
        end
        show_shop_formspec(player)
    end
end)

minetest.register_on_joinplayer(function(player)
    local seller_name = player:get_player_name()
    local received_xp = 0
    for i = #pending_transactions, 1, -1 do
        local transaction = pending_transactions[i]
        if transaction.seller == seller_name then
            xp.xp[seller_name] = (xp.xp[seller_name] or 0) + transaction.xp
            mod_storage:set_int(seller_name .. "_xp", xp.xp[seller_name])
            received_xp = received_xp + transaction.xp
            table.remove(pending_transactions, i)
        end
    end
    save_pending_transactions()
    if received_xp > 0 then
        minetest.chat_send_player(seller_name, "*** XP SHOP: "..minetest.colorize("#01B5F7", seller_name) .. ", you received " .. minetest.colorize("green", received_xp) .. " XP for your recent sales!")
        local player = minetest.get_player_by_name(seller_name)
        if player then
            xp.update_hud(player, xp.level[seller_name], xp.xp[seller_name])
        end
    end
end)

minetest.register_chatcommand("shop", {
    params = "",
    description = "Open the XP shop",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            show_shop_formspec(player)
        end
    end,
})