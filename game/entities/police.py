"""Police entity."""
from __future__ import annotations

import math
import random
from typing import Callable, List, Optional, TYPE_CHECKING

import pygame

from game.constants import (
    POLICE_SPEED, POLICE_DETECTION_BASE, POLICE_CAPTURE_RANGE,
    RED, WHITE, WORLD_WIDTH, WORLD_HEIGHT, EQUIP_GAS_MASK, EQUIP_PROTECTIVE_GEAR,
)

if TYPE_CHECKING:
    from game.city_map import CityMap
    from game.entities.player import Player


class Police(pygame.sprite.Sprite):
    """Police unit that patrols, chases and disperses the player's crowd."""

    RADIUS: int = 12
    DISPERSE_RANGE: int = 80
    DISPERSE_RATE:  float = 1.0 / 60  # supporters lost per frame (≈1/sec)

    def __init__(self, world_x: int, world_y: int, strength: int = 5) -> None:
        super().__init__()
        self.image = pygame.Surface((self.RADIUS * 2, self.RADIUS * 2), pygame.SRCALPHA)
        self.rect  = self.image.get_rect(center=(world_x, world_y))

        self.strength: int   = strength
        self.speed:    float = float(POLICE_SPEED)
        self.state:    str   = "patrolling"

        # Patrol waypoints
        self._waypoints: List[tuple[int, int]] = []
        self._wp_index:  int = 0

        # Capture signal (set True to trigger game over in game.py)
        self.capture_triggered: bool = False

        # Accumulator for fractional supporter loss
        self._disperse_acc: float = 0.0

        # Backup timer (frames)
        self._backup_timer: int = random.randint(1200, 2400)

    # ── Waypoints ───────────────────────────────────────────────────────────

    def set_waypoints(self, waypoints: List[tuple[int, int]]) -> None:
        self._waypoints = waypoints
        self._wp_index  = 0

    # ── Movement helpers ────────────────────────────────────────────────────

    def _move_toward(self, tx: int, ty: int, city_map: "CityMap") -> None:
        dx = tx - self.rect.centerx
        dy = ty - self.rect.centery
        dist = math.hypot(dx, dy)
        if dist < 1:
            return
        step_x = dx / dist * self.speed
        step_y = dy / dist * self.speed

        nx = self.rect.centerx + step_x
        ny = self.rect.centery + step_y
        nx = max(self.RADIUS, min(WORLD_WIDTH  - self.RADIUS, nx))
        ny = max(self.RADIUS, min(WORLD_HEIGHT - self.RADIUS, ny))

        if city_map.is_walkable(nx, self.rect.centery):
            self.rect.centerx = int(nx)
        if city_map.is_walkable(self.rect.centerx, ny):
            self.rect.centery = int(ny)

    # ── Detection ───────────────────────────────────────────────────────────

    def detection_radius(self, player_supporters: int) -> float:
        return POLICE_DETECTION_BASE + player_supporters * 2

    # ── Update ──────────────────────────────────────────────────────────────

    def update(  # type: ignore[override]
        self,
        city_map:  "CityMap",
        player:    "Player",
        spawn_backup_cb: Optional[Callable[[int, int], None]] = None,
    ) -> None:
        px, py = player.rect.center
        dist_to_player = math.hypot(
            self.rect.centerx - px, self.rect.centery - py
        )

        det_r = self.detection_radius(player.supporters)

        # State transitions
        if dist_to_player <= det_r:
            self.state = "chasing"
        elif self.state == "chasing" and dist_to_player > det_r * 1.5:
            self.state = "patrolling"

        # Behaviours
        if self.state == "patrolling":
            self._patrol(city_map)
        elif self.state == "chasing":
            self._chase(city_map, px, py, player)

        # Disperse (even while chasing)
        if dist_to_player <= self.DISPERSE_RANGE:
            self._do_disperse(player)

        # Backup timer
        self._backup_timer -= 1
        if self._backup_timer <= 0 and spawn_backup_cb:
            spawn_backup_cb(self.rect.centerx, self.rect.centery)
            self._backup_timer = random.randint(1800, 3600)

    def _patrol(self, city_map: "CityMap") -> None:
        if not self._waypoints:
            return
        tx, ty = self._waypoints[self._wp_index]
        self._move_toward(tx, ty, city_map)
        if math.hypot(self.rect.centerx - tx, self.rect.centery - ty) < self.speed * 2:
            self._wp_index = (self._wp_index + 1) % len(self._waypoints)

    def _chase(self, city_map: "CityMap", px: int, py: int, player: "Player") -> None:
        self._move_toward(px, py, city_map)
        dist = math.hypot(self.rect.centerx - px, self.rect.centery - py)
        if dist <= POLICE_CAPTURE_RANGE:
            if player.supporters < 10:
                self.capture_triggered = True
            else:
                self.state = "dispersing"

    def _do_disperse(self, player: "Player") -> None:
        rate = self.DISPERSE_RATE
        # Gas mask halves the rate
        if EQUIP_GAS_MASK in player.equipment:
            rate *= 0.5
        # Protective gear also halves the rate
        if EQUIP_PROTECTIVE_GEAR in player.equipment:
            rate *= 0.5
        self._disperse_acc += rate
        while self._disperse_acc >= 1.0 and player.supporters > 0:
            player.supporters  -= 1
            self._disperse_acc -= 1.0

    # ── Drawing ─────────────────────────────────────────────────────────────

    def draw(self, surface: pygame.Surface, camera_x: int, camera_y: int) -> None:
        sx = self.rect.centerx - camera_x
        sy = self.rect.centery - camera_y
        pygame.draw.circle(surface, RED,   (sx, sy), self.RADIUS)
        # White badge dot
        pygame.draw.circle(surface, WHITE, (sx, sy), 4)
        pygame.draw.circle(surface, RED,   (sx, sy), self.RADIUS, 2)
