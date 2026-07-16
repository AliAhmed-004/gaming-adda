import '../models/game.dart';

const mockGames = <Game>[
  Game(
    id: 'casino',
    title: 'Card Match',
    category: 'Card',
    description:
        'Draw from the deck and match by card number on the floor or opponent\'s collection. Play vs AI or a friend.',
    thumbnailUrl: 'assets/icons/card_match.png',
    coverUrl: 'assets/icons/card_match.png',
    rating: 4.6,
    playUrl: '',
    featured: true,
  ),
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
    id: 'stack',
    title: 'Stack',
    category: 'Action',
    description:
        'Time your taps to stack sliding blocks as high as you can. Perfect placements keep the tower wide — miss and it is game over.',
    thumbnailUrl: 'assets/icons/stack.png',
    coverUrl: 'assets/icons/stack.png',
    rating: 4.5,
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
