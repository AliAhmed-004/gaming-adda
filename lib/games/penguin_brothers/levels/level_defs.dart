import '../penguin_logic.dart';

class LevelDef {
  const LevelDef({
    required this.name,
    required this.rows,
    this.postKeyEnemyCount = 0,
    this.hasBoss = false,
    this.bgTint,
  });

  final String name;

  /// Row strings of equal length; top row is index 0.
  final List<String> rows;
  final int postKeyEnemyCount;
  final bool hasBoss;

  /// Optional ARGB tint over background.
  final int? bgTint;

  int get width => rows.first.length;
  int get height => rows.length;
}

/// Legend:
/// `#` wall  `G` ground  `=` platform  `*` breakable  `B` barrel
/// `.` empty  `1` Donfi  `2` Turu  `C` chaser  `F` fire  `K` skittish
/// `X` exit  `S` boss  `P` fruit
const penguinLevels = <LevelDef>[
  LevelDef(
    name: 'Shipwreck Beach',
    postKeyEnemyCount: 0,
    rows: [
      '################',
      '#..............#',
      '#..............#',
      '#..............#',
      '#..............#',
      '#..1.......C...#',
      '#======..======#',
      '#..............#',
      '#......C.......#',
      '#..............#',
      '#X........P...2#',
      'GGGGGGGGGGGGGGGG',
    ],
  ),
  LevelDef(
    name: 'Barrel Bay',
    postKeyEnemyCount: 1,
    rows: [
      '################',
      '#..............#',
      '#...P..........#',
      '#....====......#',
      '#.........F....#',
      '#..1..B........#',
      '#======....====#',
      '#.........B....#',
      '#......C.......#',
      '#====......====#',
      '#X............2#',
      'GGGGGGGGGGGGGGGG',
    ],
  ),
  LevelDef(
    name: 'Crate Canyon',
    postKeyEnemyCount: 2,
    rows: [
      '################',
      '#.**.........**#',
      '#.*....K......*#',
      '#..............#',
      '#...====.====..#',
      '#.1.........B..#',
      '#====......====#',
      '#......*.......#',
      '#..K.....*..C..#',
      '#====.*....====#',
      '#X.P..........2#',
      'GGGGGGGGGGGGGGGG',
    ],
  ),
  LevelDef(
    name: 'Chaos Deck',
    postKeyEnemyCount: 3,
    rows: [
      '################',
      '#..P........P..#',
      '#....F....C....#',
      '#..====..====..#',
      '#.B..........B.#',
      '#..1..K........#',
      '#======..======#',
      '#....*....*....#',
      '#..C......F....#',
      '#====......====#',
      '#X............2#',
      'GGGGGGGGGGGGGGGG',
    ],
  ),
  LevelDef(
    name: 'King Kuda',
    hasBoss: true,
    postKeyEnemyCount: 0,
    rows: [
      '################',
      '#..............#',
      '#..............#',
      '#..............#',
      '#......S.......#',
      '#..............#',
      '#..1........B..#',
      '#======..======#',
      '#..............#',
      '#..............#',
      '#X............2#',
      'GGGGGGGGGGGGGGGG',
    ],
  ),
];

EnemyKind? enemyKindFromChar(String ch) {
  return switch (ch) {
    'C' => EnemyKind.chaser,
    'F' => EnemyKind.fireSpitter,
    'K' => EnemyKind.skittish,
    _ => null,
  };
}

TileKind? solidTileFromChar(String ch) {
  return switch (ch) {
    '#' => TileKind.wall,
    'G' => TileKind.ground,
    '=' => TileKind.platform,
    '*' => TileKind.breakable,
    _ => null,
  };
}
