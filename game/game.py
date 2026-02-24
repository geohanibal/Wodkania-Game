"""Main Game class for Vodkania Uprising."""
from __future__ import annotations

import math
import random
import sys
from typing import List

import pygame

from game.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT, WORLD_WIDTH, WORLD_HEIGHT,
    FPS, TILE_SIZE,
    BLACK, WHITE, RED, GREEN, BLUE, YELLOW, DARK_GRAY, GRAY,
    POLICE_SPEED, WIN_SUPPORTERS,
    EQUIP_GAS_MASK, EQUIP_BATON, EQUIP_MEGAPHONE, EQUIP_PROTECTIVE_GEAR,
    DIFFICULTY_INTERVAL, SPECIAL_FORCES_THRESHOLD, NUM_FACTIONS,
)
from game.city_map           import CityMap
from game.entities.player    import Player
from game.entities.civilian  import Civilian
from game.entities.police    import Police
from game.entities.faction   import AIFaction
from game.entities.equipment import Equipment
from game.ui.hud             import HUD


class Game:
    """Top-level game controller."""

    _INITIAL_CIVILIANS: int = 30
    _INITIAL_POLICE:    int = 3
    _INITIAL_EQUIPMENT: int = 8

    def __init__(self) -> None:
        pygame.init()
        pygame.display.set_caption("Vodkania Uprising")
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        self.clock  = pygame.time.Clock()

        # Camera offset (world coords of top-left of screen)
        self.camera_x: int = 0
        self.camera_y: int = 0

        # Game state
        self.game_over:    bool = False
        self.game_won:     bool = False
        self.over_message: str  = ""
        self.paused:       bool = False

        self.elapsed_seconds: float = 0.0
        self.difficulty:      int   = 1
        self._next_escalation: float = DIFFICULTY_INTERVAL

        # Build world
        self.city_map = CityMap()
        cx, cy = WORLD_WIDTH // 2, WORLD_HEIGHT // 2
        self.player = Player(cx, cy)

        self.civilians:  List[Civilian]  = self._spawn_civilians(self._INITIAL_CIVILIANS)
        self.police:     List[Police]    = self._spawn_police(self._INITIAL_POLICE)
        self.factions:   List[AIFaction] = self._spawn_factions(NUM_FACTIONS)
        self.equipment:  List[Equipment] = self._spawn_equipment(self._INITIAL_EQUIPMENT)

        self.hud = HUD()

        # Overlay flash state
        self._flash_timer: int = 0

        # Recruitment animation "+1" labels  [(screen_x, screen_y, ttl)]
        self._recruit_labels: List[list] = []

    # ── Spawning ────────────────────────────────────────────────────────────

    def _spawn_civilians(self, count: int) -> List[Civilian]:
        civs = []
        for _ in range(count):
            x, y = self.city_map.random_walkable_pos()
            civs.append(Civilian(x, y))
        return civs

    def _spawn_police(self, count: int, strength: int = 5) -> List[Police]:
        units = []
        cx, cy = WORLD_WIDTH // 2, WORLD_HEIGHT // 2
        for _ in range(count):
            # Spawn away from player start
            while True:
                x, y = self.city_map.random_walkable_pos()
                if math.hypot(x - cx, y - cy) > 300:
                    break
            cop = Police(x, y, strength=strength)
            wps = [self.city_map.random_walkable_pos() for _ in range(4)]
            cop.set_waypoints(wps)
            units.append(cop)
        return units

    def _spawn_factions(self, count: int) -> List[AIFaction]:
        facs = []
        cx, cy = WORLD_WIDTH // 2, WORLD_HEIGHT // 2
        for _ in range(count):
            while True:
                x, y = self.city_map.random_walkable_pos()
                if math.hypot(x - cx, y - cy) > 200:
                    break
            facs.append(AIFaction(x, y))
        return facs

    def _spawn_equipment(self, count: int) -> List[Equipment]:
        types = [
            EQUIP_GAS_MASK, EQUIP_BATON, EQUIP_MEGAPHONE, EQUIP_PROTECTIVE_GEAR,
            EQUIP_GAS_MASK, EQUIP_BATON, EQUIP_MEGAPHONE, EQUIP_PROTECTIVE_GEAR,
        ]
        items = []
        for i in range(count):
            x, y = self.city_map.random_walkable_pos()
            items.append(Equipment(types[i % len(types)], x, y))
        return items

    # ── Camera ──────────────────────────────────────────────────────────────

    def _update_camera(self) -> None:
        self.camera_x = self.player.rect.centerx - SCREEN_WIDTH  // 2
        self.camera_y = self.player.rect.centery - SCREEN_HEIGHT // 2
        self.camera_x = max(0, min(WORLD_WIDTH  - SCREEN_WIDTH,  self.camera_x))
        self.camera_y = max(0, min(WORLD_HEIGHT - SCREEN_HEIGHT, self.camera_y))

    # ── Main loop ───────────────────────────────────────────────────────────

    def run(self) -> None:
        self._show_start_screen()
        while True:
            dt = self.clock.tick(FPS)
            self._handle_events()
            if not self.game_over and not self.game_won and not self.paused:
                self._update()
            self._draw()
            pygame.display.flip()

    # ── Events ──────────────────────────────────────────────────────────────

    def _handle_events(self) -> None:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self._quit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    self._quit()

    # ── Update ──────────────────────────────────────────────────────────────

    def _update(self) -> None:
        self.elapsed_seconds += 1 / FPS

        keys = pygame.key.get_pressed()

        # Track supporters before update to detect new recruits
        before = self.player.supporters
        self.player.update(keys, self.city_map, self.civilians)
        gained = self.player.supporters - before
        if gained > 0:
            sx = self.player.rect.centerx - self.camera_x
            sy = self.player.rect.centery - self.camera_y - 20
            self._recruit_labels.append([sx, sy, 90, f"+{gained}"])

        self._update_camera()

        # Civilians
        for civ in self.civilians:
            civ.update(self.city_map)

        # Police
        police_nearby = False
        for cop in self.police:
            cop.update(self.city_map, self.player, self._spawn_backup_police)
            if cop.capture_triggered:
                self._trigger_game_over("CAPTURED! You had fewer than 10 supporters.")
                return
            dist = math.hypot(
                cop.rect.centerx - self.player.rect.centerx,
                cop.rect.centery - self.player.rect.centery,
            )
            if dist < 200:
                police_nearby = True
        self._police_nearby = police_nearby

        # Flash when police very close
        if police_nearby:
            self._flash_timer = max(self._flash_timer, 8)
        if self._flash_timer > 0:
            self._flash_timer -= 1

        # Factions
        for fac in self.factions:
            fac.update(self.city_map, self.civilians, self.player)

        # Equipment pickups
        for item in self.equipment:
            if not item.picked_up:
                dist = math.hypot(
                    item.rect.centerx - self.player.rect.centerx,
                    item.rect.centery - self.player.rect.centery,
                )
                if dist < TILE_SIZE:
                    item.picked_up = True
                    self.player.add_equipment(item.equipment_type)

        # Escalate difficulty
        if self.elapsed_seconds >= self._next_escalation:
            self._escalate()
            self._next_escalation += DIFFICULTY_INTERVAL

        # Recruit labels
        for lbl in self._recruit_labels:
            lbl[1] -= 0.5  # float up
            lbl[2] -= 1    # decrement ttl
        self._recruit_labels = [l for l in self._recruit_labels if l[2] > 0]

        # Win check
        if self.player.supporters >= WIN_SUPPORTERS:
            self.game_won = True
            self._show_end_screen("★ VICTORY! ★\nVodkania rises with you!")

    def _spawn_backup_police(self, x: int, y: int) -> None:
        strength = 5 + self.difficulty * 2
        cop = Police(x, y, strength=strength)
        wps = [self.city_map.random_walkable_pos() for _ in range(4)]
        cop.set_waypoints(wps)
        self.police.append(cop)

    def _escalate(self) -> None:
        self.difficulty += 1
        # Add a new police unit
        strength = 5 + self.difficulty * 2
        if self.player.supporters >= SPECIAL_FORCES_THRESHOLD:
            # Special forces: faster and stronger
            new_cops = self._spawn_police(1, strength=strength + 5)
            for cop in new_cops:
                cop.speed = POLICE_SPEED * 1.5
            self.police.extend(new_cops)
        else:
            self.police.extend(self._spawn_police(1, strength=strength))

    def _trigger_game_over(self, message: str) -> None:
        self.game_over    = True
        self.over_message = message
        self._show_end_screen(f"GAME OVER\n{message}")

    # ── Drawing ─────────────────────────────────────────────────────────────

    def _draw(self) -> None:
        self.screen.fill(BLACK)
        cx, cy = self.camera_x, self.camera_y

        self.city_map.draw(self.screen, cx, cy)

        # Equipment
        for item in self.equipment:
            if not item.picked_up:
                item.draw(self.screen, cx, cy)

        # Civilians
        for civ in self.civilians:
            civ.draw(self.screen, cx, cy)

        # Factions
        for fac in self.factions:
            fac.draw(self.screen, cx, cy)

        # Police
        for cop in self.police:
            cop.draw(self.screen, cx, cy)

        # Player
        self.player.draw(self.screen, cx, cy)

        # Police-nearby red flash overlay
        if self._flash_timer > 0:
            alpha = int(80 * self._flash_timer / 8)
            overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA)
            overlay.fill((220, 0, 0, alpha))
            self.screen.blit(overlay, (0, 0))

        # Recruit "+N" labels
        font = pygame.font.SysFont("monospace", 20, bold=True)
        for lbl in self._recruit_labels:
            surf = font.render(lbl[3], True, GREEN)
            self.screen.blit(surf, (int(lbl[0]), int(lbl[1])))

        # HUD
        police_nearby = getattr(self, "_police_nearby", False)
        self.hud.draw(
            self.screen,
            self.player,
            self.police,
            self.factions,
            self.civilians,
            self.difficulty,
            self.elapsed_seconds,
            police_nearby,
        )

    # ── Screen helpers ───────────────────────────────────────────────────────

    def _show_start_screen(self) -> None:
        font_title = pygame.font.SysFont("monospace", 48, bold=True)
        font_sub   = pygame.font.SysFont("monospace", 18)
        lines = [
            ("VODKANIA UPRISING", font_title, YELLOW),
            ("", font_sub, WHITE),
            ("Move:      WASD / Arrow Keys", font_sub, WHITE),
            ("Recruit:   Walk near civilians (yellow)", font_sub, YELLOW),
            ("Avoid:     Police (red) — they scatter your crowd", font_sub, RED),
            ("Collect:   Equipment diamonds for bonuses", font_sub, GREEN),
            ("Win:       Reach 50 supporters", font_sub, GREEN),
            ("Lose:      Caught by police with <10 supporters", font_sub, RED),
            ("", font_sub, WHITE),
            ("Press any key to begin…", font_sub, WHITE),
        ]
        self.screen.fill(BLACK)
        y = 60
        for text, font, color in lines:
            surf = font.render(text, True, color)
            self.screen.blit(surf, (SCREEN_WIDTH // 2 - surf.get_width() // 2, y))
            y += surf.get_height() + 8
        pygame.display.flip()
        self._wait_for_key()

    def _show_end_screen(self, message: str) -> None:
        font_large = pygame.font.SysFont("monospace", 40, bold=True)
        font_small = pygame.font.SysFont("monospace", 22)
        overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 180))
        self.screen.blit(overlay, (0, 0))

        color = YELLOW if self.game_won else RED
        y = SCREEN_HEIGHT // 2 - 80
        for line in message.split("\n"):
            surf = font_large.render(line, True, color)
            self.screen.blit(surf, (SCREEN_WIDTH // 2 - surf.get_width() // 2, y))
            y += surf.get_height() + 10

        hint = font_small.render("Press any key to exit", True, WHITE)
        self.screen.blit(hint, (SCREEN_WIDTH // 2 - hint.get_width() // 2, y + 30))
        pygame.display.flip()
        self._wait_for_key()
        self._quit()

    def _wait_for_key(self) -> None:
        while True:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self._quit()
                if event.type == pygame.KEYDOWN:
                    return
            self.clock.tick(30)

    @staticmethod
    def _quit() -> None:
        pygame.quit()
        sys.exit()
