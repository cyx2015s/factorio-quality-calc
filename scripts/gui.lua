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
    return flow
end

---@param name string
---@param callback function<number, any>
function module.map_callback(name, callback)
    module[name] = callback
end

function module.on_gui_text_changed(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then
        return
    end
    local value = event.element.text
    storage_util.set(player_index, event.element.name, value)
    if module.mapping[event.element.name] then
        module.mapping[event.element.name](player_index, value)
    end
end

function module.on_gui_checked_state_changed(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then
        return
    end
    local state = event.element.state
    storage_util.set(player_index, event.element.name, state)
    if module.mapping[event.element.name] then
        module.mapping[event.element.name](player_index, state)
    end
end

return module
