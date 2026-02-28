# PowerShell script to verify all referenced assets exist in canonical locations
$assets = @(
    'assets/images/tiles/parliament.png',
    'assets/images/tiles/tile_0004.png',
    'assets/images/tiles/tile_0009.png',
    'assets/images/buildings/buildingTiles_000.png',
    'assets/images/buildings/buildingTiles_001.png',
    'assets/images/buildings/buildingTiles_002.png',
    'assets/images/buildings/buildingTiles_003.png',
    'assets/images/buildings/buildingTiles_004.png',
    'assets/images/vehicles/car_blue2.png'
)

$allExist = $true
foreach ($asset in $assets) {
    if (Test-Path $asset) {
        Write-Host "[OK] $asset"
    } else {
        Write-Host "[MISSING] $asset" -ForegroundColor Red
        $allExist = $false
    }
}

if ($allExist) {
    Write-Host "All referenced assets exist." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some assets are missing!" -ForegroundColor Red
    exit 1
}