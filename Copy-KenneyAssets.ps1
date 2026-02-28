# Copy-KenneyAssets.ps1
# PowerShell script to copy only the required Kenney PNG assets into your project asset folders and regenerate manifest.json

$srcRoot = "C:\Users\49172\Desktop\New folder"
$dstRoot = "C:\Users\49172\Desktop\wodkania-game\Wodkania-Game\assets"

function Copy-PNGs($src, $dst, $filter = $null) {
    if (!(Test-Path $src)) { return }
    $files = Get-ChildItem -Path $src -Recurse -Include *.png
    foreach ($file in $files) {
        if ($filter -and -not (& $filter $file)) { continue }
        $relPath = $file.FullName.Substring($src.Length).TrimStart('\','/')
        $target = Join-Path $dst $relPath
        $targetDir = Split-Path $target -Parent
        if (!(Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir | Out-Null }
        Copy-Item $file.FullName $target -Force
    }
}

# Tiles
Copy-PNGs "$srcRoot\kenney_rpg-urban-pack\Tiles" "$dstRoot\tiles"
Copy-PNGs "$srcRoot\kenney_rpg-urban-pack\Tilemap" "$dstRoot\tiles"
Copy-PNGs "$srcRoot\kenney_roguelike-modern-city\Tiles" "$dstRoot\tiles"
Copy-PNGs "$srcRoot\kenney_roguelike-modern-city\Tilemap" "$dstRoot\tiles"

# Buildings (top-down only, exclude isometric)
# No explicit top-down buildings pack in provided assets, so this is skipped.

# Vehicles (top-down only)
Copy-PNGs "$srcRoot\kenney_rpg-urban-pack\Tiles" "$dstRoot\vehicles" { param($f) $f.Name -match "car|vehicle|truck|bus|ambulance|taxi" }
Copy-PNGs "$srcRoot\kenney_roguelike-modern-city\Tiles" "$dstRoot\vehicles" { param($f) $f.Name -match "car|vehicle|truck|bus|ambulance|taxi" }

# Characters (4-direction only)
$charSrc = "$srcRoot\kenney_modular-characters\PNG"
if (Test-Path $charSrc) {
    $dirs = Get-ChildItem $charSrc -Directory
    foreach ($dir in $dirs) {
        if ($dir.Name -match "4dir|4direction|four|direction") {
            Copy-PNGs $dir.FullName "$dstRoot\characters"
        }
    }
}

# Remove isometric, side-view, large, UI/demo images (cleanup pass)
$excludePatterns = @("isometric", "side", "ui", "demo", "large", "preview", "sheet", "vector", "spritesheet")
Get-ChildItem $dstRoot -Recurse -Include *.png | Where-Object {
    $name = $_.FullName.ToLower()
    foreach ($pat in $excludePatterns) { if ($name -like "*$pat*") { return $true } }
    return $false
} | Remove-Item -Force

# Regenerate manifest.json
$manifest = @{}
foreach ($cat in "tiles","buildings","vehicles","characters","props","environment") {
    $catPath = Join-Path $dstRoot $cat
    if (Test-Path $catPath) {
        $files = Get-ChildItem $catPath -Recurse -Include *.png | ForEach-Object {
            $_.FullName.Substring($dstRoot.Length+1).Replace('\','/')
        }
        $manifest[$cat] = $files
    }
}
$manifestPath = Join-Path $dstRoot "manifest.json"
$manifest | ConvertTo-Json -Depth 5 | Set-Content $manifestPath -Encoding UTF8

Write-Host "Asset copy and manifest regeneration complete."