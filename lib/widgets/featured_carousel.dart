import 'package:flutter/material.dart';

import '../models/game.dart';
import '../screens/game_detail_screen.dart';
import 'game_artwork.dart';

class FeaturedCarousel extends StatefulWidget {
  const FeaturedCarousel({
    super.key,
    required this.games,
    this.overlay,
    this.height = 176,
  });

  final List<Game> games;
  final Widget? overlay;
  final double height;

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  final _controller = PageController(viewportFraction: 1);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) {
      if (widget.overlay == null) return const SizedBox.shrink();
      return SizedBox(
        height: widget.height,
        child: Align(
          alignment: Alignment.topCenter,
          child: widget.overlay,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.games.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final game = widget.games[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => GameDetailScreen(game: game),
                        ),
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Opacity(
                          opacity: 0.42,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.brown.shade200.withValues(alpha: 0.3),
                              BlendMode.softLight,
                            ),
                            child: GameArtwork(
                              url: game.coverUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x33E5D4B0),
                                Color(0x88E5D4B0),
                                Color(0xF2E5D4B0),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (widget.overlay != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: widget.overlay!,
                ),
            ],
          ),
        ),
        if (widget.games.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.games.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: active ? 16 : 6,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF6B4E2E)
                        : const Color(0xFF8B7355).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
