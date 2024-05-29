from abc import ABC, abstractmethod

from PIL import Image
from py_ballisticcalc import Angular

Px = int


class ReticleGen(ABC):
    @staticmethod
    @abstractmethod
    def make(click_x: Angular,
             click_y: Angular,
             zoom: float,
             min_h_step: Px, min_v_step: Px) -> Image:
        ...
