---@diagnostic disable: undefined-global
local module = {}
function module.get_quality_next_probability()
    local ret = {}
    local cur_quality = prototypes.quality["normal"]
    while cur_quality do
        table.insert(
            ret,
            cur_quality.next_probability or 0
        )
        cur_quality = cur_quality.next
    end
    return ret
end

return module
