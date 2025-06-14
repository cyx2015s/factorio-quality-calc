---@diagnostic disable: different-requires
local storage_util = require("storage-util")

local module = {}
module.mapping = {}



---Create a text input that automatically restores data from storage.
---@param parent LuaGuiElement
---@param name string
function module.create_text_input(parent, name)
    created = parent.add {
        type = "textfield",
        name = name,
        text = storage_util.get(parent.player_index, name),
        lose_focus_on_confirm = true,
        numeric = true,
        allow_decimal = true,
        allow_negative = false,
    }
    created.style.maximal_width = 96
    return created
end

---@param parent LuaGuiElement
---@param name string
---@param label string|LocalisedString
---@return unknown
function module.create_text_input_with_label(parent, name, label)
    label = label or { name }
    local flow = parent.add {
        type = "flow",
        direction = "horizontal",
    }
    flow.style.horizontally_stretchable = true
    flow.add {
        type = "label",
        caption = label,
    }
    local pusher = flow.add {
        type = "empty-widget",
    }
    pusher.style.horizontally_stretchable = true
    module.create_text_input(flow, name)
    flow.style.minimal_height = 32
    flow.style.vertical_align = "center"
    return flow
end

---@param parent LuaGuiElement
---@param name string
function module.create_checkbox(parent, name)
    created = parent.add {
        type = "checkbox",
        name = name,
        state = storage_util.get(parent.player_index, name) or false,
    }
end

---@param parent LuaGuiElement
---@param name string
---@param label string|LocalisedString
---@param description string|LocalisedString
function module.create_checkbox_with_label(parent, name, label, description)
    label = label or { name }
    local flow = parent.add {
        type = "flow",
        direction = "horizontal",
    }
    flow.style.horizontally_stretchable = true
    flow.add {
        type = "label",
        caption = label,
    }
    local pusher = flow.add {
        type = "empty-widget",
    }
    pusher.style.horizontally_stretchable = true
    module.create_checkbox(flow, name)
    flow.style.minimal_height = 32
    flow.style.vertical_align = "center"
    return flow
end

---@param parent LuaGuiElement
---@param name string
---@param items LocalisedString[]
---@return LuaGuiElement
function module.create_dropdown(parent, name, items)
    created = parent.add {
        type = "drop-down",
        name = name,
        items = items,
        selected_index = storage_util.get(parent.player_index, name) or 1,
    }
    return created
end
---@param name string
---@param callback function <EventData>
function module.map_callback(name, callback)
    module.mapping[name] = callback
end

---@param event EventData.on_gui_text_changed
---@return boolean recalc whether to recalc
function module.on_gui_text_changed(event)
    if not event.element.name:match("^qct%.") then
        return false
    end
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then
        return false
    end
    local value = event.element.text
    if #value > 16 then
        --- cap it at 16 characters
        value = value:sub(1, 16)
        event.element.text = value
    end
    storage_util.set(player_index, event.element.name, value)
    if module.mapping[event.element.name] then
        module.mapping[event.element.name](event)
    end
    return true
end

---@param event EventData.on_gui_checked_state_changed
---@return boolean recalc whether to recalc
function module.on_gui_checked_state_changed(event)
    if not event.element.name:match("^qct%.") then
        return false
    end
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then
        return false
    end
    local state = event.element.state
    storage_util.set(player_index, event.element.name, state)
    if module.mapping[event.element.name] then
        module.mapping[event.element.name](event)
    end
    return true
end

---@param event EventData.on_gui_selection_state_changed
---@return boolean recalc whether to recalc
function module.on_gui_selection_state_changed(event)
    if not event.element.name:match("^qct%.") then
        return false
    end
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then
        return false
    end
    local selected_index = event.element.selected_index
    storage_util.set(player_index, event.element.name, selected_index)
    if module.mapping[event.element.name] then
        module.mapping[event.element.name](event)
    end
    return true
end

---@param parent LuaGuiElement
---@param name string
---@param label LocalisedString
---@param id? number
---@return LuaGuiElement
function module.create_building_configuration(parent, name, label, id)
    local flow = parent.add {
        type = "flow",
        name = name,
        direction = "horizontal",
        caption = label,
    }
    flow.style.horizontally_stretchable = true
    flow.style.vertical_align = "center"
    flow.style.minimal_height = 32
    local text_label = flow.add {
        type = "label",
        caption = label
    }
    -- text_label.style.horizontally_stretchable = true
    local internal_flow = flow.add {
        type = "flow",
        direction = "horizontal"
    }
    internal_flow.style.horizontally_stretchable = true
    internal_flow.style.vertical_align = "center"
    internal_flow.style.horizontal_align = "right"
    internal_flow.add {
        type = "label",
        caption = "[item=quality-module-3]",
    }
    local internal_name = name .. "-quality-bonus"
    if id ~= nil then
        internal_name = name .. "-quality-bonus-" .. id
    end
    module.create_text_input(internal_flow, internal_name)
    internal_flow.add {
        type = "label",
        caption = "[item=productivity-module-3]",
    }

    internal_name = name .. "-production-multiplier"
    if id ~= nil then
        internal_name = name .. "-production-multiplier-" .. id
    end
    module.create_text_input(internal_flow, internal_name)
    return flow
end
---@param event EventData.on_gui_click
function module.on_gui_click(event)
    if not event.element.valid then
        return
    end
    if not event.element.name:match("^qct%.") then
        return
    end
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then
        return
    end
    if module.mapping[event.element.name] then
        module.mapping[event.element.name](event)
    end
end

return module
