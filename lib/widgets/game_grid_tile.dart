import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/game.dart';
import '../screens/game_detail_screen.dart';
import 'game_artwork.dart';

/// Play Store–style app entry: squircle icon + centered title underneath.
class GameStoreIcon extends StatelessWidget {
  const GameStoreIcon({
    super.key,
    required this.game,
    this.iconSize = 88,
    this.maxLabelWidth,
  });

  final Game game;
  final double iconSize;
  final double? maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final labelWidth = maxLabelWidth ?? iconSize + 8;

    return Semantics(
      button: true,
      label: '${game.title}, ${game.category}',
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GameDetailScreen(game: game),
            ),
          );
        },
        borderRadius: BorderRadius.circular(iconSize * 0.22),
        child: SizedBox(
          width: labelWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GameAppIcon(url: game.thumbnailUrl, size: iconSize),
              const SizedBox(height: 8),
              Text(
                game.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrolling row of store icons (Play Store “recommended” strip).
class GameIconStrip extends StatelessWidget {
  const GameIconStrip({
    super.key,
    required this.games,
    this.iconSize = 88,
    this.height = 130,
  });

  final List<Game> games;
  final double iconSize;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemWidth = iconSize + 8;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: games.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          return GameStoreIcon(
            game: games[index],
            iconSize: iconSize,
            maxLabelWidth: itemWidth,
          );
        },
      ),
    );
  }
}

/// Fixed grid of store icons — [columns] games per row.
class GameIconGrid extends StatelessWidget {
  const GameIconGrid({
    super.key,
    required this.games,
    this.columns = 3,
    this.iconSize = 88,
  });

  final List<Game> games;
  final int columns;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = 16.0;
          final maxW = constraints.maxWidth;
          if (!maxW.isFinite || maxW <= 0) {
            return const SizedBox.shrink();
          }
          final cellWidth =
              ((maxW - gap * (columns - 1)) / columns).clamp(0.0, maxW);
          if (cellWidth <= 0) {
            return const SizedBox.shrink();
          }
          final labelWidth = cellWidth.clamp(0.0, iconSize + 24);

          return Wrap(
            spacing: gap,
            runSpacing: 20,
            children: [
              for (final game in games)
                SizedBox(
                  width: cellWidth,
                  child: Center(
                    child: GameStoreIcon(
                      game: game,
                      iconSize: iconSize,
                      maxLabelWidth: labelWidth,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
