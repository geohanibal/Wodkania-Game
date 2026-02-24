"""Civilian entity."""
from __future__ import annotations

import math
import random
from typing import Optional, TYPE_CHECKING

import pygame

from game.constants import (
    CIVILIAN_SPEED, CIVILIAN_WANDER_RANGE, TILE_SIZE,
    YELLOW, WORLD_WIDTH, WORLD_HEIGHT,
)

if TYPE_CHECKING:
    from game.city_map import CityMap


class Civilian(pygame.sprite.Sprite):
    """A wandering civilian who can be recruited."""

    RADIUS: int = 6

    def __init__(self, world_x: int, world_y: int) -> None:
        super().__init__()
        self.image = pygame.Surface((self.RADIUS * 2, self.RADIUS * 2), pygame.SRCALPHA)
        self.rect  = self.image.get_rect(center=(world_x, world_y))

        self.state:  str             = "wandering"
        self.leader: Optional[object] = None  # Player or AIFaction

        # Wander state
        self._wander_dx: float = 0.0
        self._wander_dy: float = 0.0
        self._wander_timer: int = 0

    # ── Movement helpers ────────────────────────────────────────────────────

    def _pick_wander_dir(self) -> None:
        angle = random.uniform(0, 2 * math.pi)
        self._wander_dx = math.cos(angle)
        self._wander_dy = math.sin(angle)
        self._wander_timer = random.randint(30, 90)

    def _move(self, dx: float, dy: float, city_map: "CityMap") -> None:
        nx = self.rect.centerx + dx
        ny = self.rect.centery + dy
        nx = max(self.RADIUS, min(WORLD_WIDTH  - self.RADIUS, nx))
        ny = max(self.RADIUS, min(WORLD_HEIGHT - self.RADIUS, ny))
        if city_map.is_walkable(nx, self.rect.centery):
            self.rect.centerx = int(nx)
        if city_map.is_walkable(self.rect.centerx, ny):
            self.rect.centery = int(ny)

    # ── Update ──────────────────────────────────────────────────────────────

    def update(self, city_map: "CityMap") -> None:  # type: ignore[override]
        if self.state == "wandering":
            self._wander_timer -= 1
            if self._wander_timer <= 0:
                self._pick_wander_dir()
            self._move(
                self._wander_dx * CIVILIAN_SPEED,
                self._wander_dy * CIVILIAN_SPEED,
                city_map,
            )

        elif self.state == "following" and self.leader is not None:
            lx, ly = self.leader.rect.center
            dx = lx - self.rect.centerx
            dy = ly - self.rect.centery
            dist = math.hypot(dx, dy)
            # Maintain a loose orbit distance
            if dist > TILE_SIZE * 2:
                speed = CIVILIAN_SPEED * 1.5
                self._move(dx / dist * speed, dy / dist * speed, city_map)

    # ── Drawing ─────────────────────────────────────────────────────────────

    def draw(self, surface: pygame.Surface, camera_x: int, camera_y: int) -> None:
        sx = self.rect.centerx - camera_x
        sy = self.rect.centery - camera_y
        pygame.draw.circle(surface, YELLOW, (sx, sy), self.RADIUS)
