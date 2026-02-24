"""Equipment pickup entity."""
from __future__ import annotations

from typing import Tuple

import pygame

from game.constants import (
    EQUIP_GAS_MASK, EQUIP_BATON, EQUIP_MEGAPHONE, EQUIP_PROTECTIVE_GEAR,
    CYAN, ORANGE, YELLOW, GREEN, WHITE,
)

# Map equipment type → (color, description)
_EQUIP_META: dict = {
    EQUIP_GAS_MASK:        (CYAN,   "Gas Mask: −50% disperse"),
    EQUIP_BATON:           (ORANGE, "Baton: +5 strength"),
    EQUIP_MEGAPHONE:       (YELLOW, "Megaphone: +30 recruit range"),
    EQUIP_PROTECTIVE_GEAR: (GREEN,  "Prot. Gear: −50% supporter loss"),
}


class Equipment(pygame.sprite.Sprite):
    """A collectible equipment item on the map."""

    SIZE: int = 14

    def __init__(self, equipment_type: str, world_x: int, world_y: int) -> None:
        super().__init__()
        self.equipment_type: str = equipment_type
        self.image = pygame.Surface((self.SIZE * 2, self.SIZE * 2), pygame.SRCALPHA)
        self.rect  = self.image.get_rect(center=(world_x, world_y))

        meta = _EQUIP_META.get(equipment_type, (WHITE, equipment_type))
        self.color:       Tuple[int, int, int] = meta[0]
        self.description: str                  = meta[1]

        self.picked_up: bool = False

    # ── Drawing ─────────────────────────────────────────────────────────────

    def draw(self, surface: pygame.Surface, camera_x: int, camera_y: int) -> None:
        if self.picked_up:
            return
        sx = self.rect.centerx - camera_x
        sy = self.rect.centery - camera_y
        s  = self.SIZE
        # Draw as a diamond
        points = [
            (sx,     sy - s),
            (sx + s, sy),
            (sx,     sy + s),
            (sx - s, sy),
        ]
        pygame.draw.polygon(surface, self.color,  points)
        pygame.draw.polygon(surface, WHITE,        points, 2)
