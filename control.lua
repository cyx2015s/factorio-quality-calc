---@diagnostic disable: different-requires
local matrix = require("scripts.matrix")
local quality = require("scripts.quality")
local storage_util = require("scripts.storage-util")
local gui = require("scripts.gui")
local cache = {}

function on_init_or_changed(give_prompt_values)
    cache.quality_next_probability, cache.quality_name, cache.quality_prototype_name = quality
        .get_quality_next_probability()
    cache.quality_count = #cache.quality_next_probability
    for _, player in pairs(game.players) do
        if player.gui.screen["qct.main"] then
            player.gui.screen["qct.main"].destroy()
        end
        storage_util.set(player.index, "qct.quality-to", cache.quality_count)
        storage_util.set(player.index, "qct.quality-from", 1)
        if give_prompt_values then
            storage_util.set(player.index, "qct.craft-production-multiplier", 1.5)
            storage_util.set(player.index, "qct.recycle-production-multiplier", 0.25)
            storage_util.set(player.index, "qct.craft-quality-bonus", 0.31)
            storage_util.set(player.index, "qct.recycle-quality-bonus", 0.248)
        end
        update_result_gui(player.index, true)
    end
end

script.on_init(function()
    on_init_or_changed(true)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end
    storage_util.set(event.player_index, "qct.quality-to", cache.quality_count)
    storage_util.set(event.player_index, "qct.quality-from", 1)
    storage_util.set(event.player_index, "qct.craft-production-multiplier", 1.5)
    storage_util.set(event.player_index, "qct.recycle-production-multiplier", 0.25)
    storage_util.set(event.player_index, "qct.craft-quality-bonus", 0.31)
    storage_util.set(event.player_index, "qct.recycle-quality-bonus", 0.248)
    update_result_gui(player.index, true)
end)

script.on_load(function(data)
    cache.quality_next_probability, cache.quality_name, cache.quality_prototype_name = quality
        .get_quality_next_probability()
    cache.quality_count = #cache.quality_next_probability
end)

script.on_configuration_changed(
    on_init_or_changed
)

function update_result_gui(player_index, recalc)
    local player = game.get_player(player_index)
    if not player then
        return
    end
    local root_gui = player.gui.screen
    local craft_quality_bonus = tonumber(storage_util.get(player_index, "qct.craft-quality-bonus")) or 0
    local recycle_quality_bonus = tonumber(storage_util.get(player_index, "qct.recycle-quality-bonus")) or 0
    local craft_production_multiplier = tonumber(storage_util.get(player_index, "qct.craft-production-multiplier")) or 1
    local recycle_production_multiplier = tonumber(storage_util.get(player_index, "qct.recycle-production-multiplier")) or
        1
    local bruteforce_recycle = not not storage_util.get(player_index, "qct.bruteforce-recycle")
    local err = nil
    local loop = nil
    if (craft_quality_bonus > 1 and not bruteforce_recycle) or recycle_quality_bonus > 1 then
        err = { "qct.error-unsupported-quality-bonus" }
    end
    if (not bruteforce_recycle) and craft_production_multiplier == 0 or recycle_production_multiplier == 0 then
        err = { "qct.error-zero-production" }
    end
    if ((not bruteforce_recycle) and craft_production_multiplier or 1) * recycle_production_multiplier > 1 then
        err = { "qct.error-positive-recycle" }
    end
    local converged_matrix
    local accumulative_machines
    if recalc then
        if not err and bruteforce_recycle then
            converged_matrix, accumulative_machines = matrix.recycle_result(recycle_quality_bonus,
                recycle_production_multiplier,
                cache.quality_next_probability)
        elseif not err then
            converged_matrix, accumulative_machines = matrix.craft_recycle_result(
                craft_quality_bonus,
                recycle_quality_bonus,
                craft_production_multiplier,
                recycle_production_multiplier,
                cache.quality_next_probability
            )
        end
        storage_util.set(player_index, "qct.result-converged-matrix", converged_matrix)
        storage_util.set(player_index, "qct.result-accumulative-machines", accumulative_machines)
    else
        converged_matrix = storage_util.get(player_index, "qct.result-converged-matrix")
        accumulative_machines = storage_util.get(player_index, "qct.result-accumulative-machines")
    end
    if not root_gui["qct.main"] then
        return
    end
    local craft_gui = root_gui["qct.main"]["qct.flow"]["qct.input"]["qct.craft"]
    if storage_util.get(player_index, "qct.bruteforce-recycle") then
        craft_gui.visible = false
    else
        craft_gui.visible = true
    end
    local result_frame = root_gui["qct.main"]["qct.flow"]["qct.result"]
    if result_frame["qct.result"] then
        result_frame["qct.result"].destroy()
    end
    local result_flow = result_frame.add {
        type = "flow",
        name = "qct.result",
        direction = "vertical",
    }
    result_flow.style.vertical_spacing = 8
    if err then
        result_flow.add {
            type = "label",
            caption = err,
            style = "red_label",
        }
    else
        local from_index = storage_util.get(player_index, "qct.quality-from") or 1
        local to_index = storage_util.get(player_index, "qct.quality-to") or 1
        if bruteforce_recycle then
            local prob = matrix.matrix_get(converged_matrix, from_index, to_index)
            result_flow.add {
                type = "label",
                caption = { "qct.bruteforce-conversion-result", string.format("%.2f%%", prob * 100), string.format("%.2f", 1 / prob) },
            }
        else
            local prob = matrix.matrix_get(converged_matrix, from_index, to_index + cache.quality_count) or 0
            result_flow.add {
                type = "label",
                caption = { "qct.ingredient-product-conversion-result", string.format("%.2f%%", prob * 100), string.format("%.2f", 1 / prob) },
            }
            local prob = matrix.matrix_get(converged_matrix, from_index + cache.quality_count,
                to_index + cache.quality_count) or 0
            result_flow.add {
                type = "label",
                caption = { "qct.product-product-conversion-result", string.format("%.2f%%", prob * 100), string.format("%.2f", 1 / prob) },
            }
        end
    end
end

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name ~= "qct-main" then
        return
    end
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then
        return
    end
    local gui_root = player.gui.screen
    if gui_root["qct.main"] then
        gui_root["qct.main"].destroy()
    else
        local main = gui_root.add {
            type = "frame",
            name = "qct.main",
            caption = { "qct.caption" },
            direction = "vertical",
            auto_center = true,
        }
        main.style.minimal_width = 400
        main.style.minimal_height = 300
        main.style.maximal_width = 800
        main.style.maximal_height = 600
        local frame = main.add {
            type = "flow",
            name = "qct.flow",
            direction = "vertical",
        }
        frame.style.vertical_spacing = 12
        local input = frame.add {
            type = "frame",
            name = "qct.input",
            direction = "vertical",
            style = "inside_shallow_frame_with_padding"
        }
        input.style.vertically_stretchable = true
        input.style.horizontally_stretchable = true
        input.style.minimal_height = 128
        local bruteforce_toggle = input.add { type = "flow", direction = "horizontal" }

        gui.create_checkbox_with_label(
            bruteforce_toggle,
            "qct.bruteforce-recycle",
            { "qct.bruteforce-recycle" },
            { "qct.bruteforce-recycle-description" }
        )
        gui.create_building_configuration(input, "qct.recycle", { "qct.recycle-caption" })
        gui.create_building_configuration(input, "qct.craft", { "qct.craft-caption" })
        local result = frame.add {
            type = "frame",
            name = "qct.result",
            direction = "vertical",
            style = "inside_shallow_frame_with_padding",
        }
        result.style.minimal_height = 128
        local quality_selecting = result.add {
            type = "flow",
            direction = "horizontal",
        }
        quality_selecting.style.horizontal_align = "center"
        quality_selecting.style.vertical_align = "center"
        quality_selecting.style.horizontally_stretchable = true
        gui.create_dropdown(
            quality_selecting,
            "qct.quality-from",
            cache.quality_name
        )
        quality_selecting.add {
            type = "label",
            caption = { "qct.quality-arrow" }
        }
        gui.create_dropdown(
            quality_selecting,
            "qct.quality-to",
            cache.quality_name
        ).visible = false
        storage_util.set(player_index, "qct.quality-to", cache.quality_count) -- todo
        quality_selecting.add {
            type = "label",
            caption = cache.quality_name[cache.quality_count],
        }
        update_result_gui(event.player_index, false)
        main.location = {
            (player.display_resolution.width - 600) / 2,
            (player.display_resolution.height - 450) / 2
        }
    end
end)

script.on_event(
    defines.events.on_gui_text_changed,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end
        if gui.on_gui_text_changed(event) then
            update_result_gui(event.player_index, true)
        end
    end
)

script.on_event(
    defines.events.on_gui_checked_state_changed,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end
        if gui.on_gui_checked_state_changed(event) then
            update_result_gui(event.player_index, true)
        end
    end
)

script.on_event(defines.events.on_gui_selection_state_changed,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end
        if gui.on_gui_selection_state_changed(event) then
            update_result_gui(event.player_index, true)
        end
    end
)
