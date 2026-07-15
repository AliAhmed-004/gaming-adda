class Game {
  const Game({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.thumbnailUrl,
    required this.coverUrl,
    required this.rating,
    required this.playUrl,
    this.featured = false,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String thumbnailUrl;
  final String coverUrl;
  final double rating;
  final String playUrl;
  final bool featured;
}
