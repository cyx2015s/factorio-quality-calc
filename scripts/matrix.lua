local module = {}
serpent = serpent or require("serpent")

---@param quality_bonus number|table Base quality bonus shown on the machine. You can pass a table, allowing for more flexibal calculations.
---@param production_multiplier? number|table How many percent of products are returned for each quality level. If a number is given, it is considered to be `{production_multiplier, ..., 1.0}` (It is assumed that the last quality in the upgrade chain is the most powerful). For example, you can fill `0.25` for a recycler, `0.8` for a space casino.
---@param quality_next_probability? table A list of numbers representing the probability of moving to the next quality level. The last element is actually useless, but should be provided.
---@return table matrix Represents the Markov chain for the given parameters.
---@nodiscard
function module.construct_markov_matrix_with(quality_bonus, production_multiplier, quality_next_probability)
    if quality_next_probability == nil then
        quality_next_probability = { 0.1, 0.1, 0.1, 0.1, 0 } -- base game quality stat
    end
    local matrix_size = #quality_next_probability
    if matrix_size < 2 then
        error("In construct_markov_matrix_with: quality_next_probability must have at least 2 elements.")
    end
    if quality_bonus == nil then
        error("In construct_markov_matrix_with: quality_bonus is nil, please provide a valid value.")
    end
    if type(quality_bonus) == "number" then
        quality_bonus = { quality_bonus }
        for i = 2, matrix_size do
            quality_bonus[i] = quality_bonus[1]
        end
    end
    if matrix_size ~= #quality_bonus then
        error("In construct_markov_matrix_with: quality_bonus size does not match quality count.")
    end
    if production_multiplier == nil then
        production_multiplier = 0.25 -- recycler gives 1/4 items in return
    end
    if type(production_multiplier) == "number" then
        production_multiplier = { production_multiplier }
        for i = 2, matrix_size - 1 do
            production_multiplier[i] = production_multiplier[1]
        end
        production_multiplier[matrix_size] = math.max(1.0, production_multiplier[1]) -- last quality is always at least 100% production
    end
    -- init the matrix
    local matrix = {}
    for i = 1, matrix_size do
        matrix[i] = {}
        for j = 1, matrix_size do
            matrix[i][j] = 0
        end
    end
    local sum_of_row
    for i = 1, matrix_size do
        matrix[i][i] = production_multiplier[i]                -- initial state
        if i ~= matrix_size then
            matrix[i][i + 1] = quality_bonus[i] * matrix[i][i] -- upgrade to next quality
            matrix[i][i] = matrix[i][i] - matrix[i][i + 1]     -- remove upgraded
        end
        for j = i + 1, matrix_size - 1 do
            matrix[i][j + 1] = quality_next_probability[j] * matrix[i][j] -- upgrade to next quality
            matrix[i][j] = matrix[i][j] - matrix[i][j + 1]                -- remove upgraded
        end
    end
    --[[
        state @ matrix will be the result when the Markov chain run for one step. state is a row vector.
        No actual vector-matrix operation is performed, and eign value decomposition don't care about
        whether my matrix is transposed or not.
        For me, matrix[i][j] is the probability of moving from state i to state j, which follows
        natural language order.
    ]]
    return matrix
end

---@param craft_quality_bonus number|table Base quality bonus shown on the machine for crafting. You can pass a table, allowing for more flexible calculations.
---@param recycle_quality_bonus number|table Base quality bonus shown on the machine for recycling. You can pass a table, allowing for more flexible calculations.---@param craft_production_multiplier any
---@param craft_production_multiplier? number|table How many percent of products are returned for each quality level when crafting. If a number is given, it is considered to be `{craft_production_multiplier, ..., 1.0}` (It is assumed that the last quality in the upgrade chain is the most powerful). For example, you can fill `1.5` for a electromanetic plant, `1` for assembler.
---@param recycle_production_multiplier? number|table How many percent of products are returned for each quality level when recycling. If a number is given, it is considered to be `{recycle_production_multiplier, ..., max(1.0, recycle_production_multiplier)}` (It is assumed that the last quality in the upgrade chain is the most powerful). For example, you can fill `0.25` for a recycler, `0.8` for a space casino.
---@param quality_next_probability any? table A list of numbers representing the probability of moving to the next quality level. The last element is actually useless, but should be provided.
---@return table matrix Represents the Markov chain for the given parameters.
function module.construct_craft_and_recycle_matrix_with(craft_quality_bonus, recycle_quality_bonus,
                                                        craft_production_multiplier, recycle_production_multiplier,
                                                        quality_next_probability)
    assert(
        craft_production_multiplier * recycle_production_multiplier <= 1.0,
        "In construct_craft_and_recycle_matrix_with: craft_production_multiplier * recycle_production_multiplier must be less than or equal to 1.0."
    )
    local craft_matrix = module.construct_markov_matrix_with(
        craft_quality_bonus,
        craft_production_multiplier or 1.0,
        quality_next_probability
    )
    local recycle_matrix = module.construct_markov_matrix_with(
        recycle_quality_bonus,
        recycle_production_multiplier,
        quality_next_probability
    )
    recycle_matrix[#recycle_matrix][#recycle_matrix] = 1 /
        craft_matrix[#craft_matrix]
        [#craft_matrix] -- ensure will not explode
    return module.matrix_mul(craft_matrix, recycle_matrix)
end

--- If you want to apply step a and then apply step a, just use module.matrix_mul(a, b)
---@param a table A matrix.
---@param b table Another matrix.
---@return table c The result of matrix multiplication.
function module.matrix_mul(a, b)
    local c = {}
    for i = 1, #a do
        c[i] = {}
        for j = 1, #b[1] do
            c[i][j] = 0
            for k = 1, #b do
                c[i][j] = c[i][j] + a[i][k] * b[k][j]
            end
        end
    end
    -- print(serpent.line(a) .. "\n*\n" .. serpent.line(b) .. "\n=\n" .. serpent.line(c) .. "\n")
    return c
end

---@param matrix table
---@param initial_state? table
function module.get_geometric_sum(matrix, initial_state)
    local close_to_one = function(i) return math.abs(matrix[i][i] - 1) < 1e-10 end
    local denom        = {}
    local res          = {}
    local n            = #matrix
    local indexes      = {}
    local state        = {}
    for i = 1, n do
        if not close_to_one(i) then
            indexes[#indexes + 1] = i
            state[#state + 1] = initial_state and initial_state[i] or (i == 1 and 1.0 or 0.0)
        end
    end
    if #indexes == 0 then
        -- static
        return 0
    end
    for ri, i in pairs(indexes) do
        denom[ri] = {}
        res[ri] = {}
        for rj, j in pairs(indexes) do
            denom[ri][rj] = ((i == j) and 1 or 0) - matrix[i][j] -- E - A
            res[ri][rj] = (i == j) and 1 or 0                    -- identity matrix
        end
    end
    --- state(E + matrix + matrix^2 + matrix^3 + ... matrix ^ infinity)，然后取中间的部分
    --- 实际上是 state (E - matrix)^(-1)，因为这是一个等比求和

    n = #denom -- extract the non singular part of the matrix, set new size
    --- now calculate the inverse of denom
    --- assumed that denom is a upper triangular matrix
    -- 上三角矩阵求逆（高斯-约旦消元法）
    -- 先对角归一
    for i = n, 1, -1 do
        local diag = denom[i][i]
        if diag == 0 then
            error("denom is singular, cannot invert")
        end
        for j = 1, n do
            denom[i][j] = denom[i][j] / diag
            res[i][j] = res[i][j] / diag
        end
        -- 消去上三角
        for k = i - 1, 1, -1 do
            local factor = denom[k][i]
            for j = 1, n do
                denom[k][j] = denom[k][j] - factor * denom[i][j]
                res[k][j] = res[k][j] - factor * res[i][j]
            end
        end
    end
    local count = 0
    for i = 1, n do
        for j = 1, n do
            count = count + state[i] * res[i][j]
        end
    end
    return count
end

---Return the conversion rates from each quality level to the final state quality level.
---@param matrix any
---@return table converged_matrix
function module.get_final_state_of(matrix)
    local count = {}
    for i = 1, #matrix do
        count[i] = tonumber(i == 1)
    end
    local ret = module.matrix_mul(matrix, matrix)
    for i = 1, 32 do
        -- matrix^(2^33)
        -- That should be enough to converge to a stable state.
        ret = module.matrix_mul(ret, ret)
    end
    return ret
end

function module.matrix_get(matrix, i, j)
    if matrix then
        if matrix[i] then
            if matrix[j] then
                return matrix[i][j]
            end
            return 0
        end
        return 0
    end
    return 0
end

--- zivr: 自转
module.zivr = module.construct_markov_matrix_with
--- vizk_hvub: 制造回收
module.vizk_hvub = module.construct_craft_and_recycle_matrix_with
--- ublm: 收敛
module.ublm = module.get_final_state_of
--- ig: 乘
module.ig = module.matrix_mul
--- jiuu: 级数
module.jiuu = module.get_geometric_sum
return module
