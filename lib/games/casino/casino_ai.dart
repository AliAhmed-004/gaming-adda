import 'dart:math';

import 'casino_logic.dart';

class CasinoAi {
  CasinoAi({Random? random}) : _random = random ?? Random();

  final Random _random;

  int _matchGain(CasinoGame game, Rank rank) {
    return game.floorCardsMatching(rank).length +
        game.opponentPileCardsMatching(PlayerId.ai, rank).length +
        // Own-pile match only adds the hand card (gain 1 if own already has rank).
        (game.ownPileCardsMatching(PlayerId.ai, rank).isNotEmpty ? 1 : 0);
  }

  /// Prefer a hand card that matches floor, opponent, or own collection.
  PlayingCard? choosePlayCard(CasinoGame game) {
    if (game.phase != GamePhase.awaitingPlay) return null;
    if (game.turn != PlayerId.ai) return null;

    final hand = game.aiHand;
    if (hand.isEmpty) return null;

    final matches = hand.where((c) => game.hasRankMatch(c.rank)).toList();
    if (matches.isNotEmpty) {
      matches.sort(
        (a, b) => _matchGain(game, b.rank).compareTo(_matchGain(game, a.rank)),
      );
      final bestGain = _matchGain(game, matches.first.rank);
      final top = matches
          .where((c) => _matchGain(game, c.rank) == bestGain)
          .toList();
      return top[_random.nextInt(top.length)];
    }

    final floorRanks = game.floor.map((c) => c.rank).toSet();
    final oppRanks = game.pileFor(PlayerId.human).map((c) => c.rank).toSet();
    final avoidRanks = {...floorRanks, ...oppRanks};

    final safe = hand.where((c) => !avoidRanks.contains(c.rank)).toList();
    final pool = safe.isNotEmpty ? safe : hand;
    pool.sort((a, b) => a.value.compareTo(b.value));
    final best = pool.first.value;
    final top = pool.where((c) => c.value == best).toList();
    return top[_random.nextInt(top.length)];
  }

  /// After selecting a matching card, pick any matching target to click.
  PlayingCard? chooseMatchTarget(CasinoGame game) {
    if (game.selectedCard == null) return null;
    final rank = game.selectedCard!.rank;
    final floor = game.floorCardsMatching(rank);
    if (floor.isNotEmpty) return floor.first;
    final opp = game.opponentPileCardsMatching(PlayerId.ai, rank);
    if (opp.isNotEmpty) return opp.first;
    final own = game.ownPileCardsMatching(PlayerId.ai, rank);
    if (own.isNotEmpty) return own.first;
    return null;
  }
}
