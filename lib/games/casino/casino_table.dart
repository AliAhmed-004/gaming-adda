import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'casino_card.dart';
import 'casino_logic.dart';
import 'casino_theme.dart';

class CasinoTable extends StatelessWidget {
  const CasinoTable({
    super.key,
    required this.humanHand,
    required this.humanLabel,
    required this.humanCollected,
    required this.aiCollected,
    required this.game,
    required this.selectedCard,
    required this.canInteract,
    required this.onHandCardTap,
    required this.onMatchTargetTap,
    required this.onFloorTap,
    this.deckCount = 0,
  });

  final List<PlayingCard> humanHand;
  final String humanLabel;
  final List<PlayingCard> humanCollected;
  final List<PlayingCard> aiCollected;
  final CasinoGame game;
  final PlayingCard? selectedCard;
  final bool canInteract;
  final int deckCount;
  final ValueChanged<PlayingCard> onHandCardTap;
  final ValueChanged<PlayingCard> onMatchTargetTap;
  final VoidCallback onFloorTap;

  Rank? get _matchRank =>
      selectedCard != null && game.hasRankMatch(selectedCard!.rank)
      ? selectedCard!.rank
      : null;

  bool get _awaitingFloorPlace =>
      selectedCard != null && !game.hasRankMatch(selectedCard!.rank);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CollectedColumn(
                  label: 'AI',
                  cards: aiCollected,
                  matchRank: _matchRank,
                  interactive: canInteract && _matchRank != null,
                  onMatchTap: onMatchTargetTap,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _DeckPile(count: deckCount),
                    const SizedBox(height: 4),
                    Expanded(
                      child: _FloorArea(
                        floor: game.floor,
                        matchRank: _matchRank,
                        awaitingFloorPlace: _awaitingFloorPlace,
                        interactive: canInteract,
                        onMatchTap: onMatchTargetTap,
                        onFloorTap: onFloorTap,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CollectedColumn(
                  label: 'You',
                  cards: humanCollected,
                  matchRank: _matchRank,
                  interactive: canInteract && _matchRank != null,
                  onMatchTap: onMatchTargetTap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _HandRow(
          label: humanLabel,
          cards: humanHand,
          interactive: canInteract,
          selectedCard: selectedCard,
          onCardTap: onHandCardTap,
        ),
      ],
    );
  }
}

class _CollectedColumn extends StatelessWidget {
  const _CollectedColumn({
    required this.label,
    required this.cards,
    this.matchRank,
    this.interactive = false,
    this.onMatchTap,
  });

  final String label;
  final List<PlayingCard> cards;
  final Rank? matchRank;
  final bool interactive;
  final ValueChanged<PlayingCard>? onMatchTap;

  static const _miniW = 36.0;
  static const _miniH = 50.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          Text(
            '${cards.length}',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Text(
                      '—',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 3,
                          childAspectRatio: _miniW / (_miniH + 8),
                        ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final isMatch =
                          matchRank != null && card.rank == matchRank;
                      return PlayingCardView(
                        card: card,
                        width: _miniW,
                        height: _miniH,
                        rankOnly: false,
                        highlighted: isMatch,
                        floating: isMatch,
                        onTap: interactive && isMatch
                            ? () => onMatchTap?.call(card)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeckPile extends StatelessWidget {
  const _DeckPile({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Deck',
          style: GoogleFonts.nunito(
            fontSize: 10,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const PlayingCardView(faceUp: false, width: 44, height: 62),
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HandRow extends StatelessWidget {
  const _HandRow({
    required this.label,
    required this.cards,
    this.interactive = false,
    this.selectedCard,
    this.onCardTap,
  });

  final String label;
  final List<PlayingCard> cards;
  final bool interactive;
  final PlayingCard? selectedCard;
  final ValueChanged<PlayingCard>? onCardTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 82,
          child: _FaceUpHand(
            cards: cards,
            interactive: interactive,
            selectedCard: selectedCard,
            onCardTap: onCardTap,
          ),
        ),
      ],
    );
  }
}

class _FaceUpHand extends StatelessWidget {
  const _FaceUpHand({
    required this.cards,
    required this.interactive,
    this.selectedCard,
    this.onCardTap,
  });

  final List<PlayingCard> cards;
  final bool interactive;
  final PlayingCard? selectedCard;
  final ValueChanged<PlayingCard>? onCardTap;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Center(
        child: Text(
          'No cards',
          style: GoogleFonts.nunito(color: Colors.white38, fontSize: 11),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final card in cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: PlayingCardView(
                  card: card,
                  width: 44,
                  height: 62,
                  rankOnly: false,
                  selected: selectedCard == card,
                  onTap: interactive ? () => onCardTap?.call(card) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloorArea extends StatelessWidget {
  const _FloorArea({
    required this.floor,
    required this.awaitingFloorPlace,
    required this.interactive,
    required this.onMatchTap,
    required this.onFloorTap,
    this.matchRank,
  });

  final List<PlayingCard> floor;
  final Rank? matchRank;
  final bool awaitingFloorPlace;
  final bool interactive;
  final ValueChanged<PlayingCard> onMatchTap;
  final VoidCallback onFloorTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: interactive && awaitingFloorPlace ? onFloorTap : null,
      child: AnimatedContainer(
        duration: CasinoTheme.uiAnimationDuration,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CasinoTheme.feltGreen, CasinoTheme.feltDark],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: awaitingFloorPlace && interactive
                ? CasinoTheme.selectedBorder
                : Colors.white12,
            width: awaitingFloorPlace && interactive ? 2 : 1,
          ),
        ),
        child: floor.isEmpty
            ? Center(
                child: Text(
                  awaitingFloorPlace ? 'Tap floor to place' : 'Floor',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    color: awaitingFloorPlace
                        ? CasinoTheme.selectedBorder
                        : Colors.white24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 48,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 6,
                  childAspectRatio: 44 / 70,
                ),
                itemCount: floor.length,
                itemBuilder: (context, index) {
                  final card = floor[index];
                  final isMatch = matchRank != null && card.rank == matchRank;
                  return PlayingCardView(
                    card: card,
                    width: 44,
                    height: 62,
                    rankOnly: false,
                    highlighted: isMatch,
                    floating: isMatch,
                    onTap: interactive && isMatch
                        ? () => onMatchTap(card)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}
