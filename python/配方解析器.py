from typing import Self
import numpy as np

# 普通, 精良, 稀有, 史诗, 传说
基础游戏次级概率 = [0.1, 0.1, 0.1, 0.1, 0.0]


def 构造基础品质转移矩阵(
    品质等级: int | float | list[int | float] = 0,
    次级概率: None | list[float | int] = None,
):
    if 次级概率 is None:
        次级概率 = 基础游戏次级概率

    if isinstance(品质等级, (int, float)):
        品质等级 = [品质等级] * len(次级概率)

    n = len(次级概率)
    ret = np.eye(n)
    for i in range(n):
        for j in range(i + 1, n):
            转移比例 = 品质等级 if j == i + 1 else 次级概率[j - 1]
            ret[i, j] = 转移比例 * ret[i, j - 1]
            ret[i, j - 1] -= 转移比例 * ret[i, j - 1]
    for i in range(n):
        for j in range(i, n):
            if ret[i, j] < 0:
                ret[i, j + 1] += ret[i, j]
                ret[i, j] = 0
    return ret


class 材料类:
    def __init__(self, name: str):
        self.name = name

    def __eq__(self, value: Self):
        return self.name == value.name


class 物品类(材料类):
    def __eq__(self, value: 材料类):
        return super().__eq__(value) and isinstance(value, 物品类)


class 流体类(材料类):
    def __eq__(self, value: 材料类):
        return super().__eq__(value) and isinstance(value, 流体类)


class 原料类:
    def __init__(self, 材料: 材料类, 数量: float | int, 品质: int | float = 0):
        if 数量 <= 0:
            raise ValueError("数量必须大于0")
        if not isinstance(材料, 材料类):
            raise ValueError("材料必须是材料类的实例")
        self.材料 = 材料
        self.数量 = 数量


class 配方类:
    def __init__(self, 输入: list[原料类], 输出: list[原料类]):
        self.输入 = 输入
        self.输出 = 输出


class 循环系统:
    def __init__(self, 配方: 配方类, 初始状态: list[原料类]) -> None:
        pass


np.set_printoptions(formatter={"float": "{:0.4f}".format})

熔融铁 = 流体类("熔融铁")
管道 = 物品类("管道")
地下管道 = 物品类("地下管道")
铁板 = 物品类("铁板")

铸造管道 = 配方类(
    [
        原料类(熔融铁, 20),
    ],
    [
        原料类(管道, 2),
    ],
)

铸造地下管道 = 配方类(
    [
        原料类(熔融铁, 50),
        原料类(管道, 10),
    ],
    [
        原料类(地下管道, 2),
    ],
)

回收地下管道 = 配方类(
    [
        原料类(地下管道, 1),
    ],
    [
        原料类(管道, 1.25),
        原料类(铁板, 0.625),
    ],
)

管道配方 = 配方类(
    [
        原料类(铁板, 1),
    ],
    [
        原料类(管道, 1),
    ],
)
