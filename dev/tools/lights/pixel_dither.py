"""Shared by the light scripts: falloff stepped through a few levels with a 4x4 Bayer
dither, phased by world pixel so overlapping lights share one grid.

A light texture is pixel exact only at one texel per game pixel: Godot samples light
textures with a linear filter, which would blur bigger texels. So every light texture is
made at its drawn size, and its PointLight2D has scale 1 and texture_scale 1, placed so the
texture's top-left corner lands on a whole pixel.
"""

import math

LEVELS = 7
BAYER_4X4 = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


def stepped(value: float, world_x: int, world_y: int, levels: int = LEVELS) -> float:
    """`value` (0..1) on `levels` steps, dithered at world pixel (world_x, world_y)."""
    threshold = (BAYER_4X4[(world_y % 4) * 4 + (world_x % 4)] + 0.5) / 16.0
    return max(0.0, min(1.0, math.floor(value * levels + threshold) / levels))
