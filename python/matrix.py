import numpy as np
from typing import Union, List, Tuple, Dict, Optional, Any


class MarkovChain:
    """模拟Lua模块功能的Python类，用于处理马尔可夫链矩阵运算"""

    @staticmethod
    def print_mat(matrix: np.ndarray) -> str:
        """格式化打印矩阵为字符串"""
        ret = ""
        for i in range(matrix.shape[0]):
            row = [f"{x:.4f}" for x in matrix[i]]
            ret += ", ".join(row) + "\n"
        return ret

    @staticmethod
    def construct_markov_matrix_with(
        quality_bonus: Union[float, List[float]],
        production_multiplier: Optional[Union[float, List[float]]] = None,
        quality_next_probability: Optional[List[float]] = None,
    ) -> np.ndarray:
        """构建马尔可夫转移矩阵"""
        # 设置默认概率值
        if quality_next_probability is None:
            quality_next_probability = [0.1, 0.1, 0.1, 0.1, 0]
        n = len(quality_next_probability)

        if n < 2:
            raise ValueError("quality_next_probability must have at least 2 elements")

        if quality_bonus is None:
            raise ValueError("quality_bonus cannot be None")

        # 处理quality_bonus参数
        if isinstance(quality_bonus, (int, float)):
            quality_bonus = [float(quality_bonus)] * n
        elif len(quality_bonus) != n:
            raise ValueError("quality_bonus size does not match quality count")

        # 处理production_multiplier参数
        if production_multiplier is None:
            production_multiplier = 0.25

        if isinstance(production_multiplier, (int, float)):
            base_val = float(production_multiplier)
            production_multiplier = [base_val] * (n - 1) + [max(1.0, base_val)]
        elif len(production_multiplier) != n:
            raise ValueError("production_multiplier size does not match quality count")

        # 初始化矩阵
        matrix = np.zeros((n, n))

        # 构建转移矩阵
        for i in range(n):
            # 自环概率
            matrix[i, i] = production_multiplier[i]

            # 升级到下一品质的概率
            if i < n - 1:
                upgrade_prob = quality_bonus[i] * matrix[i, i]
                matrix[i, i + 1] = upgrade_prob
                matrix[i, i] -= upgrade_prob

            # 处理多级升级
            for j in range(i + 1, n - 1):
                next_upgrade = quality_next_probability[j] * matrix[i, j]
                matrix[i, j + 1] = next_upgrade
                matrix[i, j] -= next_upgrade

        # 处理负概率（借位修正）
        for i in range(n):
            for j in range(n):
                if matrix[i, j] < 0:
                    delta = -matrix[i, j]
                    matrix[i, j] = 0
                    if j < n - 1:
                        matrix[i, j + 1] -= delta

        return matrix

    @staticmethod
    def matrix_mul(a: np.ndarray, b: np.ndarray) -> np.ndarray:
        """矩阵乘法"""
        return a @ b

    @staticmethod
    def matrix_empty(n: int) -> np.ndarray:
        """创建零矩阵"""
        return np.zeros((n, n))

    @staticmethod
    def get_geometric_sum(
        matrix: np.ndarray,
        initial_state: Optional[List[float]] = None,
        return_raw: bool = False,
    ) -> Union[float, np.ndarray]:
        """计算几何级数和（状态转移的期望次数）"""
        n = matrix.shape[0]

        # 识别非吸收状态
        non_absorb_idx = [i for i in range(n) if abs(matrix[i, i] - 1.0) >= 1e-10]
        k = len(non_absorb_idx)

        if k == 0:
            return 0.0 if not return_raw else np.zeros(n)

        # 设置初始状态
        if initial_state is None:
            state = np.zeros(n)
            state[0] = 1.0
        else:
            state = np.array(initial_state)

        # 提取非吸收状态对应的子矩阵
        Q = matrix[np.ix_(non_absorb_idx, non_absorb_idx)]
        I = np.eye(k)
        R = np.linalg.inv(I - Q)

        # 计算期望访问次数
        if not return_raw:
            non_absorb_state = state[non_absorb_idx]
            return np.sum(non_absorb_state @ R)
        else:
            full_result = np.zeros(n)
            non_absorb_result = state[non_absorb_idx] @ R
            for idx, val in zip(non_absorb_idx, non_absorb_result):
                full_result[idx] = val
            return full_result

    @staticmethod
    def get_final_state_of(matrix: np.ndarray) -> np.ndarray:
        """计算稳态分布（通过矩阵幂次收敛）"""
        result = np.copy(matrix)
        for _ in range(32):  # 2^32次幂近似
            result = result @ result
        return result

    # 函数别名（保持与Lua代码兼容）
    zivr_juvf = construct_markov_matrix_with
    ig = matrix_mul
    jiuu = get_geometric_sum
    ublm = get_final_state_of

    @staticmethod
    def recycle_result(
        quality_bonus: Union[float, List[float]],
        production_multiplier: Union[float, List[float]],
        quality_next_probability: List[float],
    ) -> Tuple[np.ndarray, float]:
        """回收结果的全功能封装"""
        matrix = MarkovChain.zivr_juvf(
            quality_bonus, production_multiplier, quality_next_probability
        )
        converged = MarkovChain.ublm(matrix)
        expected = MarkovChain.jiuu(matrix)
        return converged, expected

    @staticmethod
    def craft_recycle_result(
        craft_quality_bonus: Union[float, List[float]],
        recycle_quality_bonus: Union[float, List[float]],
        craft_production_multiplier: Union[float, List[float]],
        recycle_production_multiplier: Union[float, List[float]],
        quality_next_probability: Optional[List[float]] = None,
        initial_state: Optional[List[float]] = None,
    ) -> Tuple[np.ndarray, np.ndarray]:
        """处理制造-回收联合过程的马尔可夫链"""
        if quality_next_probability is None:
            quality_next_probability = [0.1, 0.1, 0.1, 0.1, 0]
        n = len(quality_next_probability)

        # 创建制造矩阵
        craft_mat = MarkovChain.zivr_juvf(
            craft_quality_bonus, craft_production_multiplier, quality_next_probability
        )

        # 创建完整制造转移矩阵（2n x 2n）
        full_craft = np.zeros((2 * n, 2 * n))
        full_craft[:n, n : 2 * n] = craft_mat  # 右上角
        full_craft[n : 2 * n, n : 2 * n] = np.eye(n)  # 右下角单位矩阵

        # 创建回收矩阵
        recycle_mat = MarkovChain.zivr_juvf(
            recycle_quality_bonus,
            recycle_production_multiplier,
            quality_next_probability,
        )

        # 创建完整回收转移矩阵（2n x 2n）
        full_recycle = np.eye(2 * n)  # 初始化为单位矩阵
        full_recycle[n : 2 * n, :n] = recycle_mat[:n, :]  # 左下角

        # 组合制造和回收过程
        full_mat = MarkovChain.ig(full_craft, full_recycle)

        # 计算收敛状态和期望访问次数
        converged = MarkovChain.ublm(full_mat)
        accumulated = MarkovChain.jiuu(full_mat, initial_state, True)

        return converged, accumulated

    # 别名定义
    zivr = recycle_result
    vizk_hvub = craft_recycle_result


# 模块导出
module = MarkovChain()
