local matrix = require("scripts.matrix")
local quality = require("scripts.quality")
local gui = require("scripts.gui")
local cache = {}

script.on_init(function(data)
    cache = {}
    cache.quality_next_probability, cache.quality_name, cache.quality_prototype_name = quality
        .get_quality_next_probability()
end)

script.on_configuration_changed(function(data)
    cache.quality_next_probability, cache.quality_name, cache.quality_prototype_name = quality
        .get_quality_next_probability()
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == "qct-main" then
        local player = game.get_player(event.player_index)
        if not player then
            return
        end
        local gui_root = player.gui.screen
        if gui_root["qct-main"] then
            gui_root["qct-main"].destroy()
        else
            local frame = gui_root.add {
                type = "frame",
                name = "qct-main",
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
                name = "qct-header",
                direction = "vertical",
            }
            frame.style.vertical_spacing = 12
            local input = frame.add {
                type = "frame",
                name = "qct-content",
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
                name = "qct-input",
                direction = "vertical",
                style = "inside_shallow_frame_with_padding"
            }
            result.add {
                type = "label",
                caption = { "qct.result-caption" },
            }
            local result = result.add {
                type = "table",
                name = "qct-result",
                column_count = 2,
                draw_horizontal_line_after_headers = true,
            }
            result.style.vertically_stretchable = true
            result.style.horizontally_stretchable = true
            for i, name in pairs(cache.quality_name) do
                local prototype_name = cache.quality_prototype_name[i]
                result.add {
                    type = "label",
                    caption = { "", "[quality=" .. prototype_name .. "]", name },
                }
                result.add {
                    type = "label",
                    name = "qct-result-" .. i,
                    caption = "0.0",
                }
            end
        end
    end
end)

script.on_event(
    defines.events.on_gui_text_changed,
    function(event)
        gui.on_gui_text_changed(event)
    end
)
