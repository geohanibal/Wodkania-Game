import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final generator = WorldSpritePackGenerator();
  generator.generate();
}

class WorldSpritePackGenerator {
  static const int tile = 64;

  final Directory outDir = Directory('assets/images/generated_sprite_pack');
  final Directory objectsDir =
      Directory('assets/images/generated_sprite_pack/objects');
  final Directory charactersDir =
      Directory('assets/images/generated_sprite_pack/characters');

  final List<_SpriteMeta> _sprites = <_SpriteMeta>[];

  void generate() {
    _ensureDirs();

    final entries = <_SpriteEntry>[
      _SpriteEntry('tree_oak_top', 'objects', _drawTreeOakTop),
      _SpriteEntry('tree_oak_side', 'objects', _drawTreeOakSide),
      _SpriteEntry('tree_pine_top', 'objects', _drawTreePineTop),
      _SpriteEntry('bush_round_top', 'objects', _drawBushTop),
      _SpriteEntry('car_sedan_top', 'objects', _drawCarSedanTop),
      _SpriteEntry('car_sedan_side', 'objects', _drawCarSedanSide),
      _SpriteEntry('car_police_top', 'objects', _drawCarPoliceTop),
      _SpriteEntry('car_van_side', 'objects', _drawVanSide),
      _SpriteEntry('car_ambulance_top', 'objects', _drawAmbulanceTop),
      _SpriteEntry(
          'sidewalk_straight_top', 'objects', _drawSidewalkStraightTop,),
      _SpriteEntry('sidewalk_corner_top', 'objects', _drawSidewalkCornerTop),
      _SpriteEntry('crosswalk_top', 'objects', _drawCrosswalkTop),
      _SpriteEntry('road_straight_top', 'objects', _drawRoadStraightTop),
      _SpriteEntry(
          'building_apartment_top', 'objects', _drawBuildingApartmentTop,),
      _SpriteEntry(
          'building_apartment_side', 'objects', _drawBuildingApartmentSide,),
      _SpriteEntry('building_office_top', 'objects', _drawBuildingOfficeTop),
      _SpriteEntry('building_police_station_top', 'objects',
          _drawBuildingPoliceStationTop,),
      _SpriteEntry('bench_top', 'objects', _drawBenchTop),
      _SpriteEntry('bus_stop_top', 'objects', _drawBusStopTop),
      _SpriteEntry('barricade_top', 'objects', _drawBarricadeTop),
      _SpriteEntry('street_lamp_top', 'objects', _drawStreetLampTop),
      _SpriteEntry('traffic_cone_top', 'objects', _drawTrafficConeTop),
      _SpriteEntry('trash_bin_top', 'objects', _drawTrashBinTop),
      _SpriteEntry('civilian_front', 'characters',
          (i) => _drawPerson(i, PersonKind.civilian, View.front),),
      _SpriteEntry('civilian_left', 'characters',
          (i) => _drawPerson(i, PersonKind.civilian, View.left),),
      _SpriteEntry('civilian_right', 'characters',
          (i) => _drawPerson(i, PersonKind.civilian, View.right),),
      _SpriteEntry('civilian_back', 'characters',
          (i) => _drawPerson(i, PersonKind.civilian, View.back),),
      _SpriteEntry('civilian_top', 'characters',
          (i) => _drawPerson(i, PersonKind.civilian, View.top),),
      _SpriteEntry('police_front', 'characters',
          (i) => _drawPerson(i, PersonKind.police, View.front),),
      _SpriteEntry('police_left', 'characters',
          (i) => _drawPerson(i, PersonKind.police, View.left),),
      _SpriteEntry('police_right', 'characters',
          (i) => _drawPerson(i, PersonKind.police, View.right),),
      _SpriteEntry('police_back', 'characters',
          (i) => _drawPerson(i, PersonKind.police, View.back),),
      _SpriteEntry('police_top', 'characters',
          (i) => _drawPerson(i, PersonKind.police, View.top),),
      _SpriteEntry('swat_front', 'characters',
          (i) => _drawPerson(i, PersonKind.swat, View.front),),
      _SpriteEntry('swat_left', 'characters',
          (i) => _drawPerson(i, PersonKind.swat, View.left),),
      _SpriteEntry('swat_right', 'characters',
          (i) => _drawPerson(i, PersonKind.swat, View.right),),
      _SpriteEntry('swat_back', 'characters',
          (i) => _drawPerson(i, PersonKind.swat, View.back),),
      _SpriteEntry('swat_top', 'characters',
          (i) => _drawPerson(i, PersonKind.swat, View.top),),
    ];

    for (final entry in entries) {
      final image = _blank();
      entry.draw(image);
      final filePath = entry.kind == 'objects'
          ? 'assets/images/generated_sprite_pack/objects/${entry.name}.png'
          : 'assets/images/generated_sprite_pack/characters/${entry.name}.png';
      File(filePath).writeAsBytesSync(img.encodePng(image));
      _sprites
          .add(_SpriteMeta(name: entry.name, kind: entry.kind, file: filePath));
    }

    _writeSpriteSheet();
    _writeManifest();

    stdout.writeln('Generated ${_sprites.length} sprites in ${outDir.path}');
  }

  void _ensureDirs() {
    outDir.createSync(recursive: true);
    objectsDir.createSync(recursive: true);
    charactersDir.createSync(recursive: true);
  }

  img.Image _blank() => img.Image(width: tile, height: tile, numChannels: 4);

  void _writeSpriteSheet() {
    const columns = 8;
    final rows = (_sprites.length / columns).ceil();
    final sheet =
        img.Image(width: columns * tile, height: rows * tile, numChannels: 4);

    final frames = <String, Map<String, int>>{};

    for (var i = 0; i < _sprites.length; i++) {
      final x = (i % columns) * tile;
      final y = (i ~/ columns) * tile;
      final sprite = img.decodePng(File(_sprites[i].file).readAsBytesSync())!;
      img.compositeImage(sheet, sprite, dstX: x, dstY: y);
      frames[_sprites[i].name] = <String, int>{
        'x': x,
        'y': y,
        'w': tile,
        'h': tile,
      };
      _sprites[i] = _sprites[i].copyWith(x: x, y: y, w: tile, h: tile);
    }

    File('${outDir.path}/all_spritesheet.png')
        .writeAsBytesSync(img.encodePng(sheet));
    File('${outDir.path}/all_spritesheet.frames.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(frames),
    );
  }

  void _writeManifest() {
    final manifest = <String, dynamic>{
      'tile_size': tile,
      'count': _sprites.length,
      'root': outDir.path.replaceAll(r'\', '/'),
      'files': _sprites
          .map((s) => <String, dynamic>{
                'name': s.name,
                'kind': s.kind,
                'file': s.file.replaceAll(r'\', '/'),
                'sheet': <String, int>{'x': s.x, 'y': s.y, 'w': s.w, 'h': s.h},
              },)
          .toList(),
      'for_copilot':
          'Use all_spritesheet.png + all_spritesheet.frames.json for atlas lookups, or individual PNGs by file name.',
    };

    File('${outDir.path}/manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
  }

  void _drawTreeOakTop(img.Image i) {
    _rect(i, 30, 38, 4, 14, C.brownDark);
    _circle(i, 32, 24, 17, C.leaf);
    _circle(i, 24, 26, 10, C.leafLight);
    _circle(i, 40, 28, 9, C.leafDark);
  }

  void _drawTreeOakSide(img.Image i) {
    _rect(i, 28, 26, 8, 26, C.brownDark);
    _rect(i, 24, 34, 16, 10, C.brown);
    _circle(i, 32, 20, 14, C.leaf);
    _circle(i, 20, 24, 8, C.leafLight);
    _circle(i, 44, 24, 8, C.leafDark);
  }

  void _drawTreePineTop(img.Image i) {
    _rect(i, 30, 42, 4, 10, C.brownDark);
    _triangle(i, 32, 10, 14, C.pine);
    _triangle(i, 32, 18, 12, C.pineLight);
    _triangle(i, 32, 26, 10, C.pine);
  }

  void _drawBushTop(img.Image i) {
    _circle(i, 24, 34, 10, C.leaf);
    _circle(i, 36, 34, 10, C.leafLight);
    _circle(i, 30, 28, 10, C.leafDark);
  }

  void _drawCarSedanTop(img.Image i) {
    _rounded(i, 16, 18, 32, 28, C.carBlue, 6);
    _rounded(i, 20, 22, 24, 12, C.windowBlue, 4);
    _rect(i, 18, 16, 28, 2, C.outline);
    _wheelTop(i);
  }

  void _drawCarSedanSide(img.Image i) {
    _rounded(i, 10, 24, 44, 18, C.carBlue, 5);
    _rounded(i, 16, 18, 24, 10, C.windowBlue, 3);
    _rect(i, 14, 40, 10, 4, C.wheel);
    _rect(i, 40, 40, 10, 4, C.wheel);
  }

  void _drawCarPoliceTop(img.Image i) {
    _rounded(i, 16, 18, 32, 28, C.policeBlue, 6);
    _rounded(i, 20, 22, 24, 12, C.windowBlue, 4);
    _rect(i, 30, 14, 4, 4, C.red);
    _rect(i, 34, 14, 4, 4, C.blue);
    _rect(i, 16, 31, 32, 2, C.white);
    _wheelTop(i);
  }

  void _drawVanSide(img.Image i) {
    _rounded(i, 8, 22, 48, 22, C.gray2, 4);
    _rounded(i, 14, 24, 18, 8, C.windowBlue, 3);
    _rounded(i, 34, 24, 12, 8, C.windowBlue, 3);
    _rect(i, 12, 42, 10, 4, C.wheel);
    _rect(i, 42, 42, 10, 4, C.wheel);
  }

  void _drawAmbulanceTop(img.Image i) {
    _rounded(i, 14, 16, 36, 30, C.white, 6);
    _rounded(i, 20, 22, 24, 10, C.windowBlue, 4);
    _rect(i, 30, 14, 4, 4, C.red);
    _rect(i, 30, 28, 4, 10, C.red);
    _rect(i, 26, 32, 12, 4, C.red);
    _wheelTop(i);
  }

  void _drawSidewalkStraightTop(img.Image i) {
    _rect(i, 0, 0, 64, 64, C.concrete);
    for (var y = 0; y < 64; y += 8) {
      _rect(i, 0, y, 64, 1, C.concreteLine);
    }
    _rect(i, 0, 58, 64, 2, C.outlineSoft);
  }

  void _drawSidewalkCornerTop(img.Image i) {
    _rect(i, 0, 0, 64, 64, C.concrete);
    _rect(i, 0, 0, 34, 34, C.concreteLight);
    _rect(i, 32, 0, 2, 34, C.concreteLine);
    _rect(i, 0, 32, 34, 2, C.concreteLine);
  }

  void _drawCrosswalkTop(img.Image i) {
    _rect(i, 0, 0, 64, 64, C.road);
    for (var x = 6; x < 64; x += 10) {
      _rect(i, x, 18, 6, 28, C.white);
    }
  }

  void _drawRoadStraightTop(img.Image i) {
    _rect(i, 0, 0, 64, 64, C.road);
    for (var y = 0; y < 64; y += 10) {
      _rect(i, 31, y + 2, 2, 5, C.roadLine);
    }
    _rect(i, 4, 0, 2, 64, C.concreteLine);
    _rect(i, 58, 0, 2, 64, C.concreteLine);
  }

  void _drawBuildingApartmentTop(img.Image i) {
    _rect(i, 8, 8, 48, 48, C.building);
    for (var y = 14; y < 52; y += 10) {
      for (var x = 14; x < 50; x += 10) {
        _rect(i, x, y, 6, 6, C.windowBlue);
      }
    }
    _rect(i, 26, 44, 12, 12, C.door);
  }

  void _drawBuildingApartmentSide(img.Image i) {
    _rect(i, 10, 14, 44, 42, C.building);
    _rect(i, 10, 10, 44, 6, C.roof);
    for (var y = 20; y < 48; y += 10) {
      _rect(i, 16, y, 8, 6, C.windowBlue);
      _rect(i, 30, y, 8, 6, C.windowBlue);
      _rect(i, 44, y, 6, 6, C.windowBlueDark);
    }
    _rect(i, 28, 42, 10, 14, C.door);
  }

  void _drawBuildingOfficeTop(img.Image i) {
    _rect(i, 6, 8, 52, 48, C.office);
    _rect(i, 6, 8, 52, 6, C.roof);
    for (var y = 16; y < 50; y += 8) {
      for (var x = 10; x < 56; x += 8) {
        _rect(i, x, y, 5, 5, C.windowBlue);
      }
    }
  }

  void _drawBuildingPoliceStationTop(img.Image i) {
    _rect(i, 8, 10, 48, 46, C.office);
    _rect(i, 8, 10, 48, 6, C.policeBlue);
    _rect(i, 26, 18, 12, 6, C.white);
    _rect(i, 30, 16, 4, 10, C.policeBlue);
    _rect(i, 18, 30, 28, 18, C.windowBlue);
    _rect(i, 28, 46, 8, 10, C.door);
  }

  void _drawBenchTop(img.Image i) {
    _rect(i, 14, 28, 36, 6, C.wood);
    _rect(i, 14, 38, 36, 6, C.woodDark);
    _rect(i, 18, 44, 4, 8, C.metal);
    _rect(i, 42, 44, 4, 8, C.metal);
  }

  void _drawBusStopTop(img.Image i) {
    _rect(i, 8, 20, 48, 6, C.roof);
    _rect(i, 10, 26, 44, 20, C.glass);
    _rect(i, 12, 46, 4, 10, C.metal);
    _rect(i, 48, 46, 4, 10, C.metal);
    _rect(i, 20, 34, 18, 4, C.wood);
  }

  void _drawBarricadeTop(img.Image i) {
    _rect(i, 10, 26, 44, 14, C.barricade);
    for (var x = 10; x < 54; x += 10) {
      _line(i, x, 40, x + 8, 26, C.barricadeStripe);
    }
    _rect(i, 14, 40, 4, 10, C.metal);
    _rect(i, 46, 40, 4, 10, C.metal);
  }

  void _drawStreetLampTop(img.Image i) {
    _rect(i, 30, 14, 4, 34, C.metal);
    _circle(i, 32, 12, 6, C.light);
    _rect(i, 22, 48, 20, 8, C.metalDark);
  }

  void _drawTrafficConeTop(img.Image i) {
    _triangle(i, 32, 16, 12, C.orange);
    _rect(i, 24, 32, 16, 4, C.white);
    _rect(i, 20, 38, 24, 8, C.orangeDark);
  }

  void _drawTrashBinTop(img.Image i) {
    _rounded(i, 20, 16, 24, 34, C.binGreen, 4);
    _rect(i, 18, 14, 28, 4, C.binGreenDark);
    _rect(i, 26, 26, 12, 14, C.binGreenDark);
  }

  void _drawPerson(img.Image i, PersonKind kind, View view) {
    final p = switch (kind) {
      PersonKind.civilian => const _PersonPalette(
          head: C.skin,
          body: C.civilianBody,
          legs: C.civilianLegs,
          accent: C.civilianAccent,
          helmet: C.civilianHair,
        ),
      PersonKind.police => const _PersonPalette(
          head: C.skin,
          body: C.policeBody,
          legs: C.policeLegs,
          accent: C.policeAccent,
          helmet: C.policeCap,
        ),
      PersonKind.swat => const _PersonPalette(
          head: C.skinDark,
          body: C.swatBody,
          legs: C.swatLegs,
          accent: C.swatAccent,
          helmet: C.swatHelmet,
        ),
    };

    switch (view) {
      case View.front:
        _drawPersonFront(i, p, kind);
      case View.left:
        _drawPersonSide(i, p, kind, true);
      case View.right:
        _drawPersonSide(i, p, kind, false);
      case View.back:
        _drawPersonBack(i, p, kind);
      case View.top:
        _drawPersonTop(i, p, kind);
    }
  }

  void _drawPersonFront(img.Image i, _PersonPalette p, PersonKind kind) {
    _circle(i, 32, 16, 8, p.head);
    _rect(i, 26, 22, 12, 4, p.helmet);
    _rect(i, 22, 26, 20, 18, p.body);
    _rect(i, 18, 28, 4, 14, p.body);
    _rect(i, 42, 28, 4, 14, p.body);
    _rect(i, 24, 44, 6, 14, p.legs);
    _rect(i, 34, 44, 6, 14, p.legs);
    _rect(i, 22, 58, 10, 4, C.boot);
    _rect(i, 32, 58, 10, 4, C.boot);
    _rect(i, 30, 32, 4, 8, p.accent);
    if (kind != PersonKind.civilian) {
      _rect(i, 38, 36, 8, 3, C.weapon);
    }
  }

  void _drawPersonSide(
      img.Image i, _PersonPalette p, PersonKind kind, bool left,) {
    final faceX = left ? 29 : 35;
    _circle(i, 32, 16, 8, p.head);
    _rect(i, 26, 22, 12, 4, p.helmet);
    _rect(i, 24, 26, 16, 18, p.body);
    _rect(i, left ? 20 : 40, 30, 4, 12, p.body);
    _rect(i, 26, 44, 6, 14, p.legs);
    _rect(i, 34, 44, 6, 14, p.legs);
    _rect(i, 24, 58, 10, 4, C.boot);
    _rect(i, 34, 58, 10, 4, C.boot);
    _rect(i, faceX, 16, 2, 2, C.outline);
    _rect(i, 30, 32, 4, 8, p.accent);
    if (kind != PersonKind.civilian) {
      _rect(i, left ? 14 : 42, 35, 10, 3, C.weapon);
    }
  }

  void _drawPersonBack(img.Image i, _PersonPalette p, PersonKind kind) {
    _circle(i, 32, 16, 8, p.head);
    _rect(i, 26, 22, 12, 4, p.helmet);
    _rect(i, 22, 26, 20, 18, p.body);
    _rect(i, 18, 28, 4, 14, p.body);
    _rect(i, 42, 28, 4, 14, p.body);
    _rect(i, 24, 44, 6, 14, p.legs);
    _rect(i, 34, 44, 6, 14, p.legs);
    _rect(i, 22, 58, 10, 4, C.boot);
    _rect(i, 32, 58, 10, 4, C.boot);
    _rect(i, 26, 32, 12, 8, p.accent);
    if (kind != PersonKind.civilian) {
      _rect(i, 40, 35, 8, 3, C.weapon);
    }
  }

  void _drawPersonTop(img.Image i, _PersonPalette p, PersonKind kind) {
    _circle(i, 32, 18, 9, p.helmet);
    _rect(i, 22, 26, 20, 20, p.body);
    _rect(i, 18, 30, 4, 12, p.body);
    _rect(i, 42, 30, 4, 12, p.body);
    _rect(i, 24, 46, 6, 12, p.legs);
    _rect(i, 34, 46, 6, 12, p.legs);
    _rect(i, 22, 58, 10, 4, C.boot);
    _rect(i, 32, 58, 10, 4, C.boot);
    _rect(i, 30, 30, 4, 8, p.accent);
    if (kind != PersonKind.civilian) {
      _rect(i, 40, 34, 8, 3, C.weapon);
    }
  }

  void _wheelTop(img.Image i) {
    _rect(i, 12, 20, 4, 8, C.wheel);
    _rect(i, 48, 20, 4, 8, C.wheel);
    _rect(i, 12, 36, 4, 8, C.wheel);
    _rect(i, 48, 36, 4, 8, C.wheel);
  }

  void _set(img.Image i, int x, int y, int c) {
    if (x < 0 || y < 0 || x >= i.width || y >= i.height) return;
    i.setPixelRgba(
        x, y, (c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF, (c >> 24) & 0xFF,);
  }

  void _rect(img.Image i, int x, int y, int w, int h, int c) {
    for (var yy = y; yy < y + h; yy++) {
      for (var xx = x; xx < x + w; xx++) {
        _set(i, xx, yy, c);
      }
    }
  }

  void _rounded(img.Image i, int x, int y, int w, int h, int c, int r) {
    _rect(i, x + r, y, w - (r * 2), h, c);
    _rect(i, x, y + r, w, h - (r * 2), c);
    _circle(i, x + r, y + r, r, c);
    _circle(i, x + w - r - 1, y + r, r, c);
    _circle(i, x + r, y + h - r - 1, r, c);
    _circle(i, x + w - r - 1, y + h - r - 1, r, c);
  }

  void _circle(img.Image i, int cx, int cy, int r, int c) {
    for (var y = -r; y <= r; y++) {
      for (var x = -r; x <= r; x++) {
        if ((x * x) + (y * y) <= r * r) {
          _set(i, cx + x, cy + y, c);
        }
      }
    }
  }

  void _triangle(img.Image i, int cx, int topY, int halfWidth, int c) {
    final height = halfWidth * 2;
    for (var y = 0; y < height; y++) {
      final span = ((y / height) * halfWidth).toInt();
      for (var x = -span; x <= span; x++) {
        _set(i, cx + x, topY + y, c);
      }
    }
  }

  void _line(img.Image i, int x0, int y0, int x1, int y1, int c) {
    var x = x0;
    var y = y0;
    final dx = (x1 - x0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final dy = -(y1 - y0).abs();
    final sy = y0 < y1 ? 1 : -1;
    var err = dx + dy;

    while (true) {
      _set(i, x, y, c);
      if (x == x1 && y == y1) break;
      final e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y += sy;
      }
    }
  }
}

class C {
  static const int white = 0xFFFFFFFF;
  static const int black = 0xFF0A0A0A;
  static const int outline = 0xFF1F1F1F;
  static const int outlineSoft = 0xFF666666;

  static const int leaf = 0xFF4F9F3D;
  static const int leafLight = 0xFF74BC5D;
  static const int leafDark = 0xFF2F6D24;
  static const int pine = 0xFF2E7A34;
  static const int pineLight = 0xFF409D47;

  static const int brown = 0xFF8D5B3C;
  static const int brownDark = 0xFF5E3A24;
  static const int wood = 0xFFA87648;
  static const int woodDark = 0xFF7D5534;

  static const int carBlue = 0xFF386FAE;
  static const int policeBlue = 0xFF2F4C8B;
  static const int windowBlue = 0xFF9AD4F5;
  static const int windowBlueDark = 0xFF6FA7C9;
  static const int wheel = 0xFF1C1C1C;

  static const int red = 0xFFE5473A;
  static const int blue = 0xFF3B6DE0;
  static const int orange = 0xFFEE8B2E;
  static const int orangeDark = 0xFFC6681F;

  static const int gray2 = 0xFFB5BBC6;
  static const int concrete = 0xFFBFC4C8;
  static const int concreteLight = 0xFFD2D6DA;
  static const int concreteLine = 0xFF92979C;
  static const int road = 0xFF4B5057;
  static const int roadLine = 0xFFE8C65B;

  static const int building = 0xFFC7A88D;
  static const int office = 0xFF9CA3AD;
  static const int roof = 0xFF5A636F;
  static const int door = 0xFF5B4738;

  static const int glass = 0xFF8EC6DD;
  static const int metal = 0xFF7F8790;
  static const int metalDark = 0xFF5D646D;
  static const int barricade = 0xFFDDBB70;
  static const int barricadeStripe = 0xFFBE6C35;
  static const int light = 0xFFFFE391;

  static const int binGreen = 0xFF4A7D4E;
  static const int binGreenDark = 0xFF2D5B33;

  static const int skin = 0xFFD9A77A;
  static const int skinDark = 0xFFB88356;
  static const int boot = 0xFF1E2024;
  static const int weapon = 0xFF3E3F44;

  static const int civilianBody = 0xFF6882A4;
  static const int civilianLegs = 0xFF3A4F70;
  static const int civilianAccent = 0xFFE7E8EA;
  static const int civilianHair = 0xFF5F3A2B;

  static const int policeBody = 0xFF314C85;
  static const int policeLegs = 0xFF22345C;
  static const int policeAccent = 0xFFBFD5FF;
  static const int policeCap = 0xFF1E2F58;

  static const int swatBody = 0xFF3D444B;
  static const int swatLegs = 0xFF2A2F35;
  static const int swatAccent = 0xFF98A6B5;
  static const int swatHelmet = 0xFF1B1E23;
}

class _SpriteEntry {
  const _SpriteEntry(this.name, this.kind, this.draw);

  final String name;
  final String kind;
  final void Function(img.Image image) draw;
}

class _SpriteMeta {
  const _SpriteMeta({
    required this.name,
    required this.kind,
    required this.file,
    this.x = 0,
    this.y = 0,
    this.w = 0,
    this.h = 0,
  });

  final String name;
  final String kind;
  final String file;
  final int x;
  final int y;
  final int w;
  final int h;

  _SpriteMeta copyWith({int? x, int? y, int? w, int? h}) {
    return _SpriteMeta(
      name: name,
      kind: kind,
      file: file,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
    );
  }
}

class _PersonPalette {
  const _PersonPalette({
    required this.head,
    required this.body,
    required this.legs,
    required this.accent,
    required this.helmet,
  });

  final int head;
  final int body;
  final int legs;
  final int accent;
  final int helmet;
}

enum PersonKind {
  civilian,
  police,
  swat,
}

enum View {
  front,
  left,
  right,
  back,
  top,
}
