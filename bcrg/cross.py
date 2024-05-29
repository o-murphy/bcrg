from PIL import Image
from py_ballisticcalc import Angular

from bcrg.gen import ReticleGen, Px


class CrossReticle(ReticleGen):

    @staticmethod
    def make(click_x: Angular,
             click_y: Angular,
             zoom: float,
             min_h_step: Px, min_v_step: Px) -> Image:
        ...


if __name__ == '__main__':
    CrossReticle.make(
        Angular.CmPer100M(1.42),
        Angular.CmPer100M(1.42),
        1,
        Px(3),
        Px(2),
    )