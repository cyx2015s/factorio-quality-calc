local module = {}

---@param player_index number
---@param var_name string
---@return any value
function module.get(player_index, var_name)
    storage.data = storage.data or {}
    storage.data[player_index] = storage.data[player_index] or {}
    return storage.data[player_index][var_name] or nil
end

---@param player_index number
---@param var_name string
---@param value any
function module.set(player_index, var_name, value)
    storage.data = storage.data or {}
    storage.data[player_index] = storage.data[player_index] or {}
    storage.data[player_index][var_name] = value
end

---@param player_index number
function module.clear_all(player_index)
    storage.data = storage.data or {}
    storage.data[player_index] = {}
end
return module
