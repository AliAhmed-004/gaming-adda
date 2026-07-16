import '../models/game.dart';

const mockGames = <Game>[
  Game(
    id: 'checkers',
    title: 'Checkers',
    category: 'Strategy',
    description:
        'Classic American checkers. Capture opponents, crown kings on the far row, and outplay a built-in AI — all instant, no install.',
    thumbnailUrl: 'assets/icons/checkers.png',
    coverUrl: 'assets/icons/checkers.png',
    rating: 4.9,
    playUrl: '',
    featured: true,
  ),
  Game(
    id: 'ludo',
    title: 'Ludo',
    category: 'Family',
    description:
        'Classic Ludo for 2–4 players. Roll the die, race four tokens home, capture rivals on the path — hotseat or vs computer.',
    thumbnailUrl: 'assets/icons/ludo.png',
    coverUrl: 'assets/icons/ludo.png',
    rating: 4.8,
    playUrl: '',
    featured: true,
  ),
  Game(
    id: 'penguin_brothers',
    title: 'Penguin Brothers',
    category: 'Action',
    description:
        'Throw bombs, clear adorable enemies, grab the key, and escape each stage. Play solo or with a plucky AI partner.',
    thumbnailUrl: 'assets/icons/penguin_brothers.png',
    coverUrl: 'assets/icons/penguin_brothers.png',
    rating: 4.7,
    playUrl: '',
    featured: true,
  ),
];

List<String> get mockCategories {
  final categories = mockGames.map((g) => g.category).toSet().toList()..sort();
  return ['All', ...categories];
}

List<Game> get featuredGames =>
    mockGames.where((g) => g.featured).toList(growable: false);
