import math
from typing import List, Union, Tuple, Optional


def construct_markov_matrix_with(
    quality_bonus: Union[float, List[float]],
    production_multiplier: Optional[Union[float, List[float]]] = None,
    quality_next_probability: Optional[List[float]] = None,
) -> List[List[float]]:
    """
    构造马尔可夫矩阵

    Args:
        quality_bonus: 每个质量等级的基础奖励值
        production_multiplier: 每个质量等级的生产乘数
        quality_next_probability: 升级到下一质量等级的概率列表

    Returns:
        马尔可夫转移矩阵
    """
    if quality_next_probability is None:
        quality_next_probability = [0.1, 0.1, 0.1, 0.1, 0.0]  # 基础游戏质量参数

    matrix_size = len(quality_next_probability)
    if matrix_size < 2:
        raise ValueError("quality_next_probability must have at least 2 elements")

    if quality_bonus is None:
        raise ValueError("quality_bonus is required")

    # 处理quality_bonus参数
    if isinstance(quality_bonus, (int, float)):
        quality_bonus = [quality_bonus] * matrix_size
    elif len(quality_bonus) != matrix_size:
        raise ValueError("quality_bonus size does not match quality count")

    # 处理production_multiplier参数
    if production_multiplier is None:
        production_multiplier = 0.25  # 回收器默认返回25%的物品

    if isinstance(production_multiplier, (int, float)):
        pm_value = production_multiplier
        production_multiplier = [pm_value] * matrix_size
        production_multiplier[-1] = max(1.0, pm_value)  # 最高质量至少100%产出

    # 初始化矩阵
    matrix = [[0.0] * matrix_size for _ in range(matrix_size)]

    # 填充矩阵
    for i in range(matrix_size):
        # 保留在当前质量等级的概率
        matrix[i][i] = production_multiplier[i]

        # 升级到下一质量等级的概率
        if i < matrix_size - 1:
            upgrade_prob = quality_bonus[i] * matrix[i][i]
            matrix[i][i + 1] = upgrade_prob
            matrix[i][i] -= upgrade_prob  # 从当前等级减去升级概率

        # 处理多级升级
        for j in range(i, matrix_size - 1):
            if j > i:  # 跳过自身升级部分
                upgrade_prob = quality_next_probability[j] * matrix[i][j]
                matrix[i][j + 1] = upgrade_prob
                matrix[i][j] -= upgrade_prob

    return matrix


def construct_craft_and_recycle_matrix_with(
    craft_quality_bonus: Union[float, List[float]],
    recycle_quality_bonus: Union[float, List[float]],
    craft_production_multiplier: Optional[Union[float, List[float]]] = None,
    recycle_production_multiplier: Optional[Union[float, List[float]]] = None,
    quality_next_probability: Optional[List[float]] = None,
) -> List[List[float]]:
    """
    构造制造和回收的复合马尔可夫矩阵

    Args:
        craft_quality_bonus: 制造时的质量奖励
        recycle_quality_bonus: 回收时的质量奖励
        craft_production_multiplier: 制造生产乘数
        recycle_production_multiplier: 回收生产乘数
        quality_next_probability: 质量升级概率

    Returns:
        复合转移矩阵
    """
    if craft_production_multiplier is None:
        craft_production_multiplier = 1.0
    if recycle_production_multiplier is None:
        recycle_production_multiplier = 0.25

    # 验证生产乘数
    if isinstance(craft_production_multiplier, (int, float)) and isinstance(
        recycle_production_multiplier, (int, float)
    ):
        if craft_production_multiplier * recycle_production_multiplier > 1.0:
            raise ValueError(
                "craft_production_multiplier * recycle_production_multiplier must be <= 1.0"
            )

    # 创建制造和回收矩阵
    craft_matrix = construct_markov_matrix_with(
        craft_quality_bonus, craft_production_multiplier, quality_next_probability
    )

    recycle_matrix = construct_markov_matrix_with(
        recycle_quality_bonus, recycle_production_multiplier, quality_next_probability
    )

    # 调整回收矩阵的最后一个元素以确保稳定性
    n = len(craft_matrix) - 1
    recycle_matrix[n][n] = 1.0 / craft_matrix[n][n]

    # 返回矩阵乘积 (制造矩阵 × 回收矩阵)
    return matrix_mul(craft_matrix, recycle_matrix)


def matrix_mul(a: List[List[float]], b: List[List[float]]) -> List[List[float]]:
    """
    矩阵乘法

    Args:
        a: 左侧矩阵
        b: 右侧矩阵

    Returns:
        矩阵乘积 a × b
    """
    rows_a = len(a)
    cols_a = len(a[0])
    rows_b = len(b)
    cols_b = len(b[0])

    if cols_a != rows_b:
        raise ValueError("矩阵尺寸不兼容")

    # 初始化结果矩阵
    result = [[0.0] * cols_b for _ in range(rows_a)]

    # 计算矩阵乘积
    for i in range(rows_a):
        for j in range(cols_b):
            for k in range(cols_a):
                result[i][j] += a[i][k] * b[k][j]

    return result


def get_geometric_sum(
    matrix: List[List[float]], initial_state: Optional[List[float]] = None
) -> float:
    """
    计算几何级数和

    Args:
        matrix: 转移矩阵
        initial_state: 初始状态向量

    Returns:
        几何级数的和
    """
    n = len(matrix)
    close_to_one = lambda i: abs(matrix[i][i] - 1.0) < 1e-10

    # 处理初始状态
    if initial_state is None:
        initial_state = [1.0 if i == 0 else 0.0 for i in range(n)]

    # 识别非吸收态
    indexes = [i for i in range(n) if not close_to_one(i)]
    state = [initial_state[i] for i in indexes]

    # 如果没有非吸收态，直接返回0
    if not indexes:
        return 0.0

    # 构造子矩阵 (I - A)
    size = len(indexes)
    denom = [[0.0] * size for _ in range(size)]
    res = [[0.0] * size for _ in range(size)]

    for ri, i in enumerate(indexes):
        for rj, j in enumerate(indexes):
            denom[ri][rj] = (1.0 if i == j else 0.0) - matrix[i][j]
            res[ri][rj] = 1.0 if ri == rj else 0.0

    # 高斯-约旦消元法求逆
    for i in range(size - 1, -1, -1):
        diag = denom[i][i]
        if abs(diag) < 1e-10:
            raise ValueError("矩阵奇异，无法求逆")

        # 归一化当前行
        for j in range(size):
            denom[i][j] /= diag
            res[i][j] /= diag

        # 消去上方行
        for k in range(i - 1, -1, -1):
            factor = denom[k][i]
            for j in range(size):
                denom[k][j] -= factor * denom[i][j]
                res[k][j] -= factor * res[i][j]

    # 计算结果
    total = 0.0
    for i in range(size):
        for j in range(size):
            total += state[i] * res[i][j]

    return total


def get_final_state_of(matrix: List[List[float]]) -> List[List[float]]:
    """
    计算转移矩阵的最终状态

    Args:
        matrix: 转移矩阵

    Returns:
        收敛后的状态矩阵
    """
    n = len(matrix)

    # 初始化为单位矩阵
    result = [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]

    # 快速幂算法 (32次迭代)
    temp = [row[:] for row in matrix]  # 复制矩阵
    for _ in range(32):
        # 矩阵平方
        new_temp = [[0.0] * n for _ in range(n)]
        for i in range(n):
            for k in range(n):
                if temp[i][k]:
                    for j in range(n):
                        new_temp[i][j] += temp[i][k] * temp[k][j]
        temp = new_temp

    return temp


# 添加Lua代码中的别名
zivr = construct_markov_matrix_with
vizk_hvub = construct_craft_and_recycle_matrix_with
ublm = get_final_state_of
ig = matrix_mul
jiuu = get_geometric_sum
