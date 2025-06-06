local matrix = require("scripts.matrix")
local quality = require("scripts.quality")

script.on_init(function()
    game.print(serpent.line(quality.get_quality_next_probability()))
    game.print(serpent.line(1 /
        matrix.get_final_state_of(matrix.matrix_mul(matrix.construct_markov_matrix_with(0.025 * 5, 1.5),
            matrix.construct_markov_matrix_with(0.025 * 4, { 0.25, 0.25, 0.25, 0.25, 1 / 1.5 })))[1][5]))
end)

remote.add_interface(
    "qct",
    {
        construct_markov_matrix_with = matrix.construct_markov_matrix_with,
        get_final_state_of = matrix.get_final_state_of,
        construct_craft_and_recycle_matrix_with = matrix.construct_craft_and_recycle_matrix_with,
        get_quality_next_probability = quality.get_quality_next_probability
    }
)
