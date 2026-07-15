import '../models/game.dart';

const mockGames = <Game>[
  Game(
    id: 'checkers',
    title: 'Checkers',
    category: 'Strategy',
    description:
        'Classic American checkers. Capture opponents, crown kings on the far row, and outplay a built-in AI — all instant, no install.',
    thumbnailUrl: 'https://picsum.photos/seed/checkers/200/200',
    coverUrl: 'https://picsum.photos/seed/checkers-cover/800/400',
    rating: 4.9,
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
