"""City map generation and rendering."""
from __future__ import annotations

import random
from typing import List, Tuple

import pygame

from game.constants import (
    TILE_SIZE, WORLD_WIDTH, WORLD_HEIGHT,
    DARK_GRAY, GRAY, BLACK,
)

# Tile type constants
TILE_ROAD     = 0
TILE_BUILDING = 1


class CityMap:
    """Procedurally generated top-down city grid."""

    def __init__(self) -> None:
        self.cols: int = WORLD_WIDTH  // TILE_SIZE   # 100
        self.rows: int = WORLD_HEIGHT // TILE_SIZE   # 100
        self.grid: List[List[int]] = []
        self._generate()

    # ── Generation ──────────────────────────────────────────────────────────

    def _generate(self) -> None:
        """Build a city grid with road strips and building blocks."""
        # Start with all buildings
        self.grid = [
            [TILE_BUILDING for _ in range(self.cols)]
            for _ in range(self.rows)
        ]

        road_interval = 7   # a road strip every 7 tiles
        road_width    = 3   # road strips are 3 tiles wide

        # Carve horizontal road strips
        row = 0
        while row < self.rows:
            for dr in range(road_width):
                r = row + dr
                if r < self.rows:
                    for c in range(self.cols):
                        self.grid[r][c] = TILE_ROAD
            row += road_interval

        # Carve vertical road strips
        col = 0
        while col < self.cols:
            for dc in range(road_width):
                c = col + dc
                if c < self.cols:
                    for r in range(self.rows):
                        self.grid[r][c] = TILE_ROAD
            col += road_interval

        # Randomly remove some building blocks to create open plazas
        rng = random.Random(42)
        block_size = road_interval - road_width  # interior block size
        r = road_width
        while r + block_size <= self.rows:
            c = road_width
            while c + block_size <= self.cols:
                if rng.random() < 0.15:  # 15 % chance of open plaza
                    for br in range(block_size):
                        for bc in range(block_size):
                            self.grid[r + br][c + bc] = TILE_ROAD
                c += road_interval
            r += road_interval

        # Guarantee a clear area around the world center (spawn point)
        cx = self.cols // 2
        cy = self.rows // 2
        for dr in range(-2, 3):
            for dc in range(-2, 3):
                nr, nc = cy + dr, cx + dc
                if 0 <= nr < self.rows and 0 <= nc < self.cols:
                    self.grid[nr][nc] = TILE_ROAD

    # ── Queries ─────────────────────────────────────────────────────────────

    def is_walkable(self, world_x: float, world_y: float) -> bool:
        """Return True if the world-space point lands on a road tile."""
        col = int(world_x) // TILE_SIZE
        row = int(world_y) // TILE_SIZE
        if col < 0 or col >= self.cols or row < 0 or row >= self.rows:
            return False
        return self.grid[row][col] == TILE_ROAD

    def random_walkable_pos(self) -> Tuple[int, int]:
        """Return a random walkable world-space (x, y) position."""
        while True:
            col = random.randint(0, self.cols - 1)
            row = random.randint(0, self.rows - 1)
            if self.grid[row][col] == TILE_ROAD:
                x = col * TILE_SIZE + TILE_SIZE // 2
                y = row * TILE_SIZE + TILE_SIZE // 2
                return x, y

    # ── Rendering ───────────────────────────────────────────────────────────

    def draw(self, surface: pygame.Surface, camera_x: int, camera_y: int) -> None:
        """Draw only the tiles visible in the current camera view."""
        screen_w = surface.get_width()
        screen_h = surface.get_height()

        col_start = max(0, camera_x // TILE_SIZE)
        col_end   = min(self.cols, (camera_x + screen_w) // TILE_SIZE + 2)
        row_start = max(0, camera_y // TILE_SIZE)
        row_end   = min(self.rows, (camera_y + screen_h) // TILE_SIZE + 2)

        for row in range(row_start, row_end):
            for col in range(col_start, col_end):
                tile = self.grid[row][col]
                sx = col * TILE_SIZE - camera_x
                sy = row * TILE_SIZE - camera_y
                rect = pygame.Rect(sx, sy, TILE_SIZE, TILE_SIZE)

                if tile == TILE_ROAD:
                    pygame.draw.rect(surface, DARK_GRAY, rect)
                else:
                    pygame.draw.rect(surface, GRAY, rect)
                    # Darker border for buildings
                    pygame.draw.rect(surface, BLACK, rect, 1)
