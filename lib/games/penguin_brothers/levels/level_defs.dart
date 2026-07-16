import '../penguin_logic.dart';

class LevelDef {
  const LevelDef({
    required this.name,
    required this.rows,
    this.postKeyEnemyCount = 0,
    this.hasBoss = false,
    this.bgTint,
    this.bgAsset = 'penguin_brothers/bg_stage.png',
    this.roundLabel,
  });

  final String name;

  /// Row strings of equal length; top row is index 0.
  final List<String> rows;
  final int postKeyEnemyCount;
  final bool hasBoss;

  /// Optional ARGB tint over background.
  final int? bgTint;

  /// Flame images path (after `images.prefix`).
  final String bgAsset;

  /// Optional arcade banner drawn near the floor (e.g. `ROUND 1-1`).
  final String? roundLabel;

  int get width => rows.first.length;
  int get height => rows.length;
}

/// Legend:
/// `#` wall  `G` ground  `=` platform  `*` breakable  `B` barrel
/// `.` empty  `1` Donfi  `2` Turu  `C` chaser  `F` fire  `K` skittish
/// `X` exit  `S` boss  `P` fruit/coin
const penguinLevels = <LevelDef>[
  // Classic Penguin Brothers Round 1-1 topology.
  LevelDef(
    name: 'Round 1-1',
    bgAsset: 'penguin_brothers/bg_round1.png',
    roundLabel: 'ROUND 1-1',
    postKeyEnemyCount: 0,
    rows: [
      // Four decks: full top beam, split mid with green soft bars, lower mid bridges, ship floor.
      '#..................#',
      '#1.................#',
      '#==================#',
      '#..................#',
      '#........P.......B.#',
      '#=======****=======#',
      '#..................#',
      '#=****========****=#',
      '#..................#',
      '#..................#',
      '#X................2#',
      'GGGGGGGGGGGGGGGGGGGG',
      'GGGGGGGGGGGGGGGGGGGG',
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
