---@diagnostic disable: undefined-global
local module = {}
---@return table probabilities
---@return table localised_names
---@return table prototype_names
function module.get_quality_next_probability()
    local probability = {}
    local name = {}
    local prototype_name = {}
    local cur_quality = prototypes.quality["normal"]
    while cur_quality do
        table.insert(
            probability,
            cur_quality.next_probability or 0
        )
        table.insert(name, { "", "[quality=" .. cur_quality.name .. "]", cur_quality.localised_name })
        table.insert(prototype_name, cur_quality.name)
        cur_quality = cur_quality.next
    end
    return probability, name, prototype_name
end

return module
