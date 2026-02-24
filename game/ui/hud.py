"""Heads-Up Display."""
from __future__ import annotations

import math
from typing import List, TYPE_CHECKING

import pygame

from game.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT,
    WORLD_WIDTH, WORLD_HEIGHT,
    WIN_SUPPORTERS, POLICE_DETECTION_BASE,
    WHITE, BLACK, RED, GREEN, YELLOW, BLUE, PURPLE, ORANGE,
    DARK_GRAY, GRAY,
)

if TYPE_CHECKING:
    from game.entities.player  import Player
    from game.entities.police  import Police
    from game.entities.faction import AIFaction
    from game.entities.civilian import Civilian


class HUD:
    """Renders all on-screen UI elements."""

    MINIMAP_W: int = 160
    MINIMAP_H: int = 100
    MINIMAP_X: int = SCREEN_WIDTH  - 170
    MINIMAP_Y: int = SCREEN_HEIGHT - 110

    def __init__(self) -> None:
        pygame.font.init()
        self._font_large  = pygame.font.SysFont("monospace", 28, bold=True)
        self._font_medium = pygame.font.SysFont("monospace", 18)
        self._font_small  = pygame.font.SysFont("monospace", 14)

    # ── Public API ──────────────────────────────────────────────────────────

    def draw(
        self,
        surface:   pygame.Surface,
        player:    "Player",
        police:    List["Police"],
        factions:  List["AIFaction"],
        civilians: List["Civilian"],
        difficulty: int,
        elapsed_seconds: float,
        police_nearby: bool,
    ) -> None:
        self._draw_supporter_count(surface, player)
        self._draw_equipment(surface, player)
        self._draw_goal(surface, player)
        self._draw_threat(surface, difficulty, police_nearby)
        self._draw_minimap(surface, player, police, factions, civilians)

    # ── Private helpers ─────────────────────────────────────────────────────

    def _draw_supporter_count(self, surface: pygame.Surface, player: "Player") -> None:
        text = f"Supporters: {player.supporters} / {WIN_SUPPORTERS}"
        surf = self._font_large.render(text, True, WHITE)
        # Shadow
        shadow = self._font_large.render(text, True, BLACK)
        surface.blit(shadow, (12, 12))
        surface.blit(surf,   (10, 10))

        # Progress bar
        bar_w = 200
        bar_h = 14
        bx, by = 10, 44
        ratio = min(player.supporters / WIN_SUPPORTERS, 1.0)
        pygame.draw.rect(surface, DARK_GRAY, (bx, by, bar_w, bar_h))
        pygame.draw.rect(surface, GREEN,     (bx, by, int(bar_w * ratio), bar_h))
        pygame.draw.rect(surface, WHITE,     (bx, by, bar_w, bar_h), 1)

    def _draw_equipment(self, surface: pygame.Surface, player: "Player") -> None:
        x, y = SCREEN_WIDTH - 10, 10
        title = self._font_small.render("Equipment:", True, YELLOW)
        surface.blit(title, (x - title.get_width(), y))
        y += 18
        if not player.equipment:
            none_surf = self._font_small.render("(none)", True, GRAY)
            surface.blit(none_surf, (x - none_surf.get_width(), y))
        for item in player.equipment:
            item_surf = self._font_small.render(f"• {item.replace('_',' ')}", True, WHITE)
            surface.blit(item_surf, (x - item_surf.get_width(), y))
            y += 16

    def _draw_goal(self, surface: pygame.Surface, player: "Player") -> None:
        remaining = WIN_SUPPORTERS - player.supporters
        if remaining > 0:
            msg = f"Recruit {remaining} more to win!  Lose if <10 when caught."
        else:
            msg = "Win condition met!"
        surf = self._font_small.render(msg, True, YELLOW)
        surface.blit(surf, (10, SCREEN_HEIGHT - 22))

    def _draw_threat(
        self,
        surface:       pygame.Surface,
        difficulty:    int,
        police_nearby: bool,
    ) -> None:
        color = RED if police_nearby else ORANGE
        text  = f"Threat Level: {difficulty}"
        surf  = self._font_medium.render(text, True, color)
        surface.blit(surf, (10, 64))

    def _draw_minimap(
        self,
        surface:   pygame.Surface,
        player:    "Player",
        police:    List["Police"],
        factions:  List["AIFaction"],
        civilians: List["Civilian"],
    ) -> None:
        mx, my = self.MINIMAP_X, self.MINIMAP_Y
        mw, mh = self.MINIMAP_W, self.MINIMAP_H

        # Background
        pygame.draw.rect(surface, BLACK,      (mx - 1, my - 1, mw + 2, mh + 2))
        pygame.draw.rect(surface, DARK_GRAY,  (mx, my, mw, mh))

        def to_mini(wx: int, wy: int):
            """Convert world coords to minimap pixel."""
            rx = int(wx / WORLD_WIDTH  * mw) + mx
            ry = int(wy / WORLD_HEIGHT * mh) + my
            return rx, ry

        # Civilians
        for civ in civilians:
            if civ.state == "wandering":
                rx, ry = to_mini(civ.rect.centerx, civ.rect.centery)
                pygame.draw.circle(surface, YELLOW, (rx, ry), 1)

        # Police
        for cop in police:
            rx, ry = to_mini(cop.rect.centerx, cop.rect.centery)
            pygame.draw.circle(surface, RED, (rx, ry), 2)

        # Factions
        for fac in factions:
            rx, ry = to_mini(fac.rect.centerx, fac.rect.centery)
            pygame.draw.circle(surface, PURPLE, (rx, ry), 2)

        # Player
        rx, ry = to_mini(player.rect.centerx, player.rect.centery)
        pygame.draw.circle(surface, BLUE, (rx, ry), 3)

        # Border
        pygame.draw.rect(surface, WHITE, (mx, my, mw, mh), 1)
        label = self._font_small.render("MAP", True, WHITE)
        surface.blit(label, (mx + 2, my + 2))
