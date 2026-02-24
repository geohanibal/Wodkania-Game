"""Player entity."""
from __future__ import annotations

import math
from typing import List, TYPE_CHECKING

import pygame

from game.constants import (
    PLAYER_SPEED, PLAYER_START_SUPPORTERS, RECRUIT_RANGE,
    BLUE, GREEN, WHITE, EQUIP_MEGAPHONE, EQUIP_BATON,
    EQUIP_GAS_MASK, EQUIP_PROTECTIVE_GEAR,
    WORLD_WIDTH, WORLD_HEIGHT,
)

if TYPE_CHECKING:
    from game.city_map import CityMap
    from game.entities.civilian import Civilian


class Player(pygame.sprite.Sprite):
    """The player-controlled rebel leader."""

    RADIUS: int = 14

    def __init__(self, world_x: int, world_y: int) -> None:
        super().__init__()
        self.image = pygame.Surface((self.RADIUS * 2, self.RADIUS * 2), pygame.SRCALPHA)
        self.rect  = self.image.get_rect(center=(world_x, world_y))

        self.supporters: int = PLAYER_START_SUPPORTERS
        self.speed: int      = PLAYER_SPEED

        self.equipment: List[str] = []
        self.equipment_effects: dict = {
            "damage_reduction": 0.0,
            "recruit_speed":    1.0,
            "strength":         0,
        }

        # Used by police disperse logic
        self.disperse_cooldown: float = 0.0

    # ── Properties ──────────────────────────────────────────────────────────

    @property
    def recruit_range(self) -> int:
        bonus = 30 if EQUIP_MEGAPHONE in self.equipment else 0
        return RECRUIT_RANGE + bonus

    def get_strength(self) -> int:
        return self.supporters + self.equipment_effects["strength"]

    # ── Equipment ───────────────────────────────────────────────────────────

    def add_equipment(self, equipment_type: str) -> None:
        if equipment_type in self.equipment:
            return
        self.equipment.append(equipment_type)
        if equipment_type == EQUIP_BATON:
            self.equipment_effects["strength"] += 5
        elif equipment_type == EQUIP_GAS_MASK:
            self.equipment_effects["damage_reduction"] = max(
                self.equipment_effects["damage_reduction"], 0.5
            )
        elif equipment_type == EQUIP_PROTECTIVE_GEAR:
            self.equipment_effects["damage_reduction"] = max(
                self.equipment_effects["damage_reduction"], 0.5
            )

    # ── Movement ────────────────────────────────────────────────────────────

    def handle_input(self, keys: pygame.key.ScancodeWrapper, city_map: "CityMap") -> None:
        dx = dy = 0
        if keys[pygame.K_LEFT]  or keys[pygame.K_a]: dx -= self.speed
        if keys[pygame.K_RIGHT] or keys[pygame.K_d]: dx += self.speed
        if keys[pygame.K_UP]    or keys[pygame.K_w]: dy -= self.speed
        if keys[pygame.K_DOWN]  or keys[pygame.K_s]: dy += self.speed

        new_x = self.rect.centerx + dx
        new_y = self.rect.centery + dy

        # Clamp to world bounds
        new_x = max(self.RADIUS, min(WORLD_WIDTH  - self.RADIUS, new_x))
        new_y = max(self.RADIUS, min(WORLD_HEIGHT - self.RADIUS, new_y))

        # Check walkability for each axis independently
        if city_map.is_walkable(new_x, self.rect.centery):
            self.rect.centerx = new_x
        if city_map.is_walkable(self.rect.centerx, new_y):
            self.rect.centery = new_y

    # ── Recruiting ──────────────────────────────────────────────────────────

    def recruit_nearby(self, civilians: List["Civilian"]) -> int:
        """Recruit civilians within recruit_range. Returns number recruited."""
        recruited = 0
        rr = self.recruit_range
        px, py = self.rect.center
        for civ in civilians:
            if civ.state == "wandering":
                dx = civ.rect.centerx - px
                dy = civ.rect.centery - py
                if math.hypot(dx, dy) <= rr:
                    civ.state  = "following"
                    civ.leader = self
                    self.supporters += 1
                    recruited += 1
        return recruited

    # ── Update ──────────────────────────────────────────────────────────────

    def update(  # type: ignore[override]
        self,
        keys: pygame.key.ScancodeWrapper,
        city_map: "CityMap",
        civilians: List["Civilian"],
    ) -> None:
        self.handle_input(keys, city_map)
        self.recruit_nearby(civilians)
        if self.disperse_cooldown > 0:
            self.disperse_cooldown -= 1 / 60

    # ── Drawing ─────────────────────────────────────────────────────────────

    def draw(self, surface: pygame.Surface, camera_x: int, camera_y: int) -> None:
        sx = self.rect.centerx - camera_x
        sy = self.rect.centery - camera_y

        # Supporter crowd circles (up to 20 visible)
        visible = min(self.supporters, 20)
        if visible > 0:
            orbit_r = self.RADIUS + 10
            for i in range(visible):
                angle = (2 * math.pi * i / visible)
                cx = int(sx + orbit_r * math.cos(angle))
                cy = int(sy + orbit_r * math.sin(angle))
                pygame.draw.circle(surface, GREEN, (cx, cy), 5)

        # Player circle
        pygame.draw.circle(surface, BLUE,  (sx, sy), self.RADIUS)
        pygame.draw.circle(surface, WHITE, (sx, sy), self.RADIUS, 2)
