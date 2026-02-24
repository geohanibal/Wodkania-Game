"""AI Faction entity."""
from __future__ import annotations

import math
import random
from typing import List, Optional, TYPE_CHECKING

import pygame

from game.constants import (
    FACTION_SPEED, FACTION_STEAL_RANGE, RECRUIT_RANGE,
    PURPLE, WHITE, WORLD_WIDTH, WORLD_HEIGHT,
)

if TYPE_CHECKING:
    from game.city_map import CityMap
    from game.entities.civilian import Civilian
    from game.entities.player import Player


_MAGENTA = (255, 0, 200)


class AIFaction(pygame.sprite.Sprite):
    """Competing AI faction that recruits civilians and challenges the player."""

    RADIUS: int = 12

    def __init__(self, world_x: int, world_y: int) -> None:
        super().__init__()
        self.image = pygame.Surface((self.RADIUS * 2, self.RADIUS * 2), pygame.SRCALPHA)
        self.rect  = self.image.get_rect(center=(world_x, world_y))

        self.supporters: int  = random.randint(3, 8)
        self.speed:      float = float(FACTION_SPEED)

        self._target_civ:    Optional["Civilian"] = None
        self._steal_acc:     float = 0.0
        self._wander_dx:     float = 0.0
        self._wander_dy:     float = 0.0
        self._wander_timer:  int   = 0

    # ── Movement ────────────────────────────────────────────────────────────

    def _move_toward(self, tx: int, ty: int, city_map: "CityMap") -> None:
        dx = tx - self.rect.centerx
        dy = ty - self.rect.centery
        dist = math.hypot(dx, dy)
        if dist < 1:
            return
        step_x = dx / dist * self.speed
        step_y = dy / dist * self.speed
        nx = max(self.RADIUS, min(WORLD_WIDTH  - self.RADIUS, self.rect.centerx + step_x))
        ny = max(self.RADIUS, min(WORLD_HEIGHT - self.RADIUS, self.rect.centery + step_y))
        if city_map.is_walkable(nx, self.rect.centery):
            self.rect.centerx = int(nx)
        if city_map.is_walkable(self.rect.centerx, ny):
            self.rect.centery = int(ny)

    def _wander(self, city_map: "CityMap") -> None:
        self._wander_timer -= 1
        if self._wander_timer <= 0:
            angle = random.uniform(0, 2 * math.pi)
            self._wander_dx = math.cos(angle)
            self._wander_dy = math.sin(angle)
            self._wander_timer = random.randint(30, 90)
        nx = self.rect.centerx + self._wander_dx * self.speed
        ny = self.rect.centery + self._wander_dy * self.speed
        nx = max(self.RADIUS, min(WORLD_WIDTH  - self.RADIUS, nx))
        ny = max(self.RADIUS, min(WORLD_HEIGHT - self.RADIUS, ny))
        if city_map.is_walkable(nx, self.rect.centery):
            self.rect.centerx = int(nx)
        if city_map.is_walkable(self.rect.centerx, ny):
            self.rect.centery = int(ny)

    # ── Update ──────────────────────────────────────────────────────────────

    def update(  # type: ignore[override]
        self,
        city_map:  "CityMap",
        civilians: List["Civilian"],
        player:    "Player",
    ) -> None:
        fx, fy = self.rect.center
        px, py = player.rect.center
        dist_to_player = math.hypot(fx - px, fy - py)

        # Decide whether to target player or civilians
        should_steal = (
            self.supporters > player.supporters * 1.5
            and dist_to_player < 400
        )

        if should_steal:
            self._move_toward(px, py, city_map)
            if dist_to_player <= FACTION_STEAL_RANGE:
                self._steal_acc += 1 / 60
                while self._steal_acc >= 1.0 and player.supporters > 0:
                    player.supporters  -= 1
                    self.supporters    += 1
                    self._steal_acc    -= 1.0
        else:
            # Recruit nearest wandering civilian
            nearest:     Optional["Civilian"] = None
            nearest_dist: float = float("inf")
            for civ in civilians:
                if civ.state == "wandering":
                    d = math.hypot(civ.rect.centerx - fx, civ.rect.centery - fy)
                    if d < nearest_dist:
                        nearest_dist = d
                        nearest = civ

            if nearest:
                self._move_toward(nearest.rect.centerx, nearest.rect.centery, city_map)
                if nearest_dist <= RECRUIT_RANGE:
                    nearest.state  = "following"
                    nearest.leader = self
                    self.supporters += 1
            else:
                self._wander(city_map)

        # Allow player to absorb faction if much stronger
        if (
            player.supporters > self.supporters * 1.5
            and dist_to_player <= FACTION_STEAL_RANGE
        ):
            absorb = max(1, self.supporters // 4)
            player.supporters  += absorb
            self.supporters    = max(0, self.supporters - absorb)

    # ── Drawing ─────────────────────────────────────────────────────────────

    def draw(self, surface: pygame.Surface, camera_x: int, camera_y: int) -> None:
        sx = self.rect.centerx - camera_x
        sy = self.rect.centery - camera_y

        # Follower circles
        visible = min(self.supporters, 12)
        if visible > 0:
            orbit_r = self.RADIUS + 8
            for i in range(visible):
                angle = 2 * math.pi * i / visible
                cx = int(sx + orbit_r * math.cos(angle))
                cy = int(sy + orbit_r * math.sin(angle))
                pygame.draw.circle(surface, _MAGENTA, (cx, cy), 4)

        pygame.draw.circle(surface, PURPLE, (sx, sy), self.RADIUS)
        pygame.draw.circle(surface, WHITE,  (sx, sy), self.RADIUS, 2)
