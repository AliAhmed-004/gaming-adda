import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/casino/casino_logic.dart';

PlayingCard c(Rank rank, Suit suit) => PlayingCard(rank: rank, suit: suit);

void main() {
  group('setup', () {
    test('deals 4 hand and 4 floor cards per player', () {
      final game = CasinoGame(random: Random(42));
      game.newGame();
      expect(game.humanHand.length, 4);
      expect(game.aiHand.length, 4);
      expect(game.floor.length, 4);
      expect(game.humanPile, isEmpty);
      expect(game.deck.length, 52 - 12);
    });
  });

  group('draw and play', () {
    test('draw adds to hand and awaits play', () {
      final game = CasinoGame(random: Random(1));
      game.setStateForTest(
        deck: [c(Rank.nine, Suit.hearts)],
        humanHand: [for (var i = 0; i < 4; i++) c(Rank.two, Suit.clubs)],
        aiHand: [for (var i = 0; i < 4; i++) c(Rank.three, Suit.diamonds)],
        floor: [c(Rank.king, Suit.hearts)],
        turn: PlayerId.human,
        phase: GamePhase.playing,
      );

      expect(game.drawCard(), isTrue);
      expect(game.humanHand.length, 5);
      expect(game.phase, GamePhase.awaitingPlay);
    });

    test('select + click match collects and keeps the turn', () {
      final game = CasinoGame(random: Random(1));
      final seven = c(Rank.seven, Suit.hearts);
      game.setStateForTest(
        humanHand: [
          seven,
          c(Rank.two, Suit.clubs),
          c(Rank.three, Suit.diamonds),
          c(Rank.four, Suit.spades),
          c(Rank.five, Suit.hearts),
        ],
        aiHand: [for (var i = 0; i < 4; i++) c(Rank.ace, Suit.clubs)],
        floor: [c(Rank.seven, Suit.spades), c(Rank.king, Suit.hearts)],
        aiPile: [c(Rank.seven, Suit.clubs), c(Rank.ace, Suit.diamonds)],
        turn: PlayerId.human,
        phase: GamePhase.awaitingPlay,
      );

      game.selectHandCard(seven);
      expect(game.selectionHasMatch, isTrue);

      expect(game.collectByClickingMatch(c(Rank.seven, Suit.spades)), isTrue);
      expect(game.humanPile.length, 3);
      expect(game.floor.length, 1);
      expect(game.aiPile.length, 1);
      expect(game.humanHand.length, 4);
      // Combo: same player continues.
      expect(game.turn, PlayerId.human);
      expect(game.phase, GamePhase.playing);
    });

    test('can match against own collected cards and keep turn', () {
      final game = CasinoGame(random: Random(1));
      final seven = c(Rank.seven, Suit.hearts);
      game.setStateForTest(
        humanHand: [
          seven,
          c(Rank.two, Suit.clubs),
          c(Rank.three, Suit.diamonds),
          c(Rank.four, Suit.spades),
          c(Rank.five, Suit.hearts),
        ],
        floor: [c(Rank.king, Suit.hearts)],
        humanPile: [c(Rank.seven, Suit.spades)],
        turn: PlayerId.human,
        phase: GamePhase.awaitingPlay,
      );

      game.selectHandCard(seven);
      expect(game.selectionHasMatch, isTrue);
      expect(game.collectByClickingMatch(c(Rank.seven, Suit.spades)), isTrue);
      expect(game.humanPile.length, 2);
      expect(game.turn, PlayerId.human);
      expect(game.phase, GamePhase.playing);
    });

    test('dropping on floor ends the turn', () {
      final game = CasinoGame(random: Random(1));
      final nine = c(Rank.nine, Suit.hearts);
      game.setStateForTest(
        humanHand: [
          nine,
          c(Rank.two, Suit.clubs),
          c(Rank.three, Suit.diamonds),
          c(Rank.four, Suit.spades),
          c(Rank.five, Suit.hearts),
        ],
        aiHand: [for (var i = 0; i < 4; i++) c(Rank.ace, Suit.clubs)],
        floor: [c(Rank.king, Suit.hearts)],
        turn: PlayerId.human,
        phase: GamePhase.awaitingPlay,
      );

      game.selectHandCard(nine);
      expect(game.selectionHasMatch, isFalse);
      expect(game.placeSelectedOnFloor(), isTrue);
      expect(game.humanHand.length, 4);
      expect(game.floor.length, 2);
      expect(game.turn, PlayerId.ai);
    });

    test('cannot place on floor when selection has a match', () {
      final game = CasinoGame(random: Random(1));
      final seven = c(Rank.seven, Suit.hearts);
      game.setStateForTest(
        humanHand: [seven, c(Rank.two, Suit.clubs)],
        floor: [c(Rank.seven, Suit.spades)],
        turn: PlayerId.human,
        phase: GamePhase.awaitingPlay,
      );

      game.selectHandCard(seven);
      expect(game.placeSelectedOnFloor(), isFalse);
    });
  });

  group('game end', () {
    test('ends when deck empty at draw', () {
      final game = CasinoGame(random: Random(1));
      game.setStateForTest(
        deck: [],
        humanHand: [for (var i = 0; i < 4; i++) c(Rank.two, Suit.clubs)],
        aiHand: [for (var i = 0; i < 4; i++) c(Rank.three, Suit.diamonds)],
        floor: [c(Rank.five, Suit.spades)],
        humanPile: [for (var i = 0; i < 10; i++) c(Rank.ace, Suit.hearts)],
        aiPile: [for (var i = 0; i < 5; i++) c(Rank.king, Suit.clubs)],
        turn: PlayerId.human,
        phase: GamePhase.playing,
      );

      expect(game.drawCard(), isFalse);
      expect(game.phase, GamePhase.gameEnd);
      expect(game.winner, PlayerId.human);
    });
  });
}
