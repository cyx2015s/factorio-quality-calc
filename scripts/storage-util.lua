local module = {}

---@param player_index number
---@param var_name string
---@param default? any the value to return when variable is not set
---@return any value
function module.get(player_index, var_name, default)
    storage.data = storage.data or {}
    storage.data[player_index] = storage.data[player_index] or {}
    local value = storage.data[player_index][var_name]
    if value ~= nil then
        return value
    end
    return default
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
