import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/casino/casino_ai.dart';
import 'package:gaming_adda/games/casino/casino_logic.dart';

PlayingCard c(Rank rank, Suit suit) => PlayingCard(rank: rank, suit: suit);

void main() {
  test('AI prefers a matching hand card when available', () {
    final game = CasinoGame(random: Random(1));
    game.setStateForTest(
      aiHand: [
        c(Rank.king, Suit.hearts),
        c(Rank.three, Suit.diamonds),
        c(Rank.four, Suit.spades),
        c(Rank.five, Suit.clubs),
        c(Rank.two, Suit.hearts),
      ],
      floor: [c(Rank.king, Suit.spades)],
      turn: PlayerId.ai,
      phase: GamePhase.awaitingPlay,
    );

    final ai = CasinoAi(random: Random(1));
    final choice = ai.choosePlayCard(game)!;
    expect(choice.rank, Rank.king);
  });

  test('AI match target can come from own pile', () {
    final game = CasinoGame(random: Random(1));
    final king = c(Rank.king, Suit.hearts);
    game.setStateForTest(
      aiHand: [king, c(Rank.two, Suit.clubs)],
      floor: [c(Rank.three, Suit.spades)],
      aiPile: [c(Rank.king, Suit.spades)],
      turn: PlayerId.ai,
      phase: GamePhase.awaitingPlay,
      selectedCard: king,
    );

    final ai = CasinoAi(random: Random(1));
    final target = ai.chooseMatchTarget(game);
    expect(target, isNotNull);
    expect(target!.rank, Rank.king);
  });
}
