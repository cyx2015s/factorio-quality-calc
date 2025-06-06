---@diagnostic disable: different-requires
local matrix = require("scripts.matrix")
local quality = require("scripts.quality")
local storage_util = require("scripts.storage-util")
local gui = require("scripts.gui")
local cache = {}

script.on_init(function(data)
    cache.quality_next_probability, cache.quality_name, cache.quality_prototype_name = quality
        .get_quality_next_probability()
end)

script.on_load(function(data)
    cache.quality_next_probability, cache.quality_name, cache.quality_prototype_name = quality
        .get_quality_next_probability()
end)
script.on_configuration_changed(function(data)
    cache.quality_next_probability, cache.quality_name, cache.quality_prototype_name = quality
        .get_quality_next_probability()
end)

function update_matrix_result_gui(player_index, recalc)
    local player = game.get_player(player_index)
    if not player then
        return
    end
    local craft_quality_bonus = tonumber(storage_util.get(player_index, "qct.craft-quality-bonus")) or 0
    local recycle_quality_bonus = tonumber(storage_util.get(player_index, "qct.recycle-quality-bonus")) or 0
    local craft_production_multiplier = tonumber(storage_util.get(player_index, "qct.craft-production-multiplier")) or 1
    local recycle_production_multiplier = tonumber(storage_util.get(player_index, "qct.recycle-production-multiplier")) or
        1
    local bruteforce_recycle = not not storage_util.get(player_index, "qct.bruteforce-recycle")
    local err = nil
    local loop = nil
    if not recalc then
        goto main
    end
    if (craft_quality_bonus > 1 and not bruteforce_recycle) or recycle_quality_bonus > 1 then
        err = { "qct.error-unsupported-quality-bonus" }
    end
    if ((not bruteforce_recycle) and craft_production_multiplier or 1) * recycle_production_multiplier > 1 then
        err = { "qct.error-positive-recycle" }
    end
    ---@class table
    if not err and bruteforce_recycle then
        loop = matrix.construct_markov_matrix_with(
            recycle_quality_bonus,
            recycle_production_multiplier,
            cache.quality_next_probability
        )
    elseif not err then
        loop = matrix.construct_craft_and_recycle_matrix_with(
            craft_quality_bonus,
            recycle_quality_bonus,
            craft_production_multiplier,
            recycle_production_multiplier,
            cache.quality_next_probability
        )
    end
    if loop then
        local converged_matrix = matrix.get_final_state_of(loop)
        storage_util.set(player_index, "result-converged-matrix", converged_matrix)
        local machine_count = matrix.get_geometric_sum(loop)
        storage_util.set(player_index, "result-machine-count", machine_count)
    end
    ::main::
    if player.gui.screen["qct.main"] then
        ---@class LuaGuiElement
        local result_flow = player.gui.screen["qct.main"]["qct.flow"]["qct.result"]
        local result_table = result_flow["qct.result"]
        for i = 1, #cache.quality_next_probability do
            local matrix_element = err and 0.0 or matrix.matrix_get()
            result_table.children[i * 2 + 2].caption = string.format(
                "%.2f%% (%.2f : 1)",
                matrix.matrix_get(storage_util.get(player_index, "result-converged-matrix"), i, 5) * 100,
                1.0 / (matrix.matrix_get(storage_util.get(player_index, "result-converged-matrix"), i, 5))
            )
        end
    end
end

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name ~= "qct-main" then
        return
    end
    local player = game.get_player(event.player_index)
    if not player then
        return
    end
    local gui_root = player.gui.screen
    if gui_root["qct.main"] then
        gui_root["qct.main"].destroy()
    else
        local frame = gui_root.add {
            type = "frame",
            name = "qct.main",
            caption = { "qct.caption" },
            direction = "vertical",
            auto_center = true,
        }
        frame.style.minimal_width = 400
        frame.style.minimal_height = 300
        frame.style.maximal_width = 800
        frame.style.maximal_height = 600
        frame = frame.add {
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
        gui.create_text_input_with_label(input, "qct.craft-quality-bonus")
        gui.create_text_input_with_label(input, "qct.recycle-quality-bonus")
        gui.create_text_input_with_label(input, "qct.craft-production-multiplier")
        gui.create_text_input_with_label(input, "qct.recycle-production-multiplier")

        gui.create_checkbox_with_label(input, "qct.bruteforce-recycle")
        local result = frame.add {
            type = "frame",
            name = "qct.result",
            direction = "vertical",
            style = "inside_shallow_frame_with_padding",
        }
        result.style.horizontal_align = "center"
        result.add {
            type = "label",
            caption = { "qct.result-caption" },
        }
        local result = result.add {
            type = "table",
            name = "qct.result",
            column_count = 2,
            draw_horizontal_line_after_headers = true,
            draw_vertical_lines = true,
            vertical_centering = true
        }
        result.style.vertically_stretchable = true
        result.style.horizontally_stretchable = true
        result.add {
            type = "label",
            caption = { "qct.quality-column" }
        }
        result.add {
            type = "label",
            caption = { "qct.probability-column", "[quality=" .. cache.quality_prototype_name[#cache.quality_prototype_name] .. "]" },
        }
        for i, name in pairs(cache.quality_name) do
            local prototype_name = cache.quality_prototype_name[i]
            result.add {
                type = "label",
                caption = { "", "[quality=" .. prototype_name .. "]", name },
            }
            result.add {
                type = "label",
                name = "qct.result-" .. i,
                caption = "0.0",
            }
        end
        update_matrix_result_gui(event.player_index, false)
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
            update_matrix_result_gui(event.player_index, true)
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
            update_matrix_result_gui(event.player_index, true)
        end
    end
)
