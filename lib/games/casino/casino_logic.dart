import 'dart:math';

enum Suit { spades, hearts, diamonds, clubs }

enum Rank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
}

extension RankX on Rank {
  int get pipValue {
    switch (this) {
      case Rank.ace:
        return 1;
      case Rank.two:
        return 2;
      case Rank.three:
        return 3;
      case Rank.four:
        return 4;
      case Rank.five:
        return 5;
      case Rank.six:
        return 6;
      case Rank.seven:
        return 7;
      case Rank.eight:
        return 8;
      case Rank.nine:
        return 9;
      case Rank.ten:
      case Rank.jack:
      case Rank.queen:
      case Rank.king:
        return 10;
    }
  }

  String get label {
    switch (this) {
      case Rank.ace:
        return 'A';
      case Rank.two:
        return '2';
      case Rank.three:
        return '3';
      case Rank.four:
        return '4';
      case Rank.five:
        return '5';
      case Rank.six:
        return '6';
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
    }
  }
}

extension SuitX on Suit {
  String get symbol {
    switch (this) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
    }
  }

  bool get isRed => this == Suit.hearts || this == Suit.diamonds;
}

class PlayingCard {
  const PlayingCard({required this.rank, required this.suit});

  final Rank rank;
  final Suit suit;

  int get value => rank.pipValue;

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.rank == rank && other.suit == suit;

  @override
  int get hashCode => Object.hash(rank, suit);

  @override
  String toString() => '${rank.label}${suit.symbol}';
}

enum PlayerId { human, ai }

extension PlayerIdX on PlayerId {
  PlayerId get opponent =>
      this == PlayerId.human ? PlayerId.ai : PlayerId.human;
}

/// playing: waiting to draw at turn start
/// awaitingPlay: hand has drawn card; player selects a hand card then target
/// gameEnd: deck empty
enum GamePhase { playing, awaitingPlay, gameEnd }

class CasinoGame {
  CasinoGame({Random? random}) : _random = random ?? Random();

  final Random _random;

  late List<PlayingCard> deck;
  late List<PlayingCard> humanHand;
  late List<PlayingCard> aiHand;
  late List<PlayingCard> floor;
  late List<PlayingCard> humanPile;
  late List<PlayingCard> aiPile;

  PlayerId turn = PlayerId.human;
  GamePhase phase = GamePhase.playing;

  /// Selected hand card waiting for a floor/match click.
  PlayingCard? selectedCard;

  List<PlayingCard> handFor(PlayerId player) =>
      player == PlayerId.human ? humanHand : aiHand;

  List<PlayingCard> pileFor(PlayerId player) =>
      player == PlayerId.human ? humanPile : aiPile;

  bool get deckEmpty => deck.isEmpty;

  bool get isTie =>
      phase == GamePhase.gameEnd && humanPile.length == aiPile.length;

  PlayerId? get winner {
    if (phase != GamePhase.gameEnd) return null;
    if (humanPile.length > aiPile.length) return PlayerId.human;
    if (aiPile.length > humanPile.length) return PlayerId.ai;
    return null;
  }

  bool get hasSelection => selectedCard != null;

  bool get selectionHasMatch =>
      selectedCard != null && hasRankMatch(selectedCard!.rank);

  void newGame() {
    deck = _newShuffledDeck();
    humanHand = [];
    aiHand = [];
    floor = [];
    humanPile = [];
    aiPile = [];
    turn = PlayerId.human;
    phase = GamePhase.playing;
    selectedCard = null;
    deck.shuffle(_random);
    _dealCards(humanHand, 4);
    _dealCards(aiHand, 4);
    _dealCards(floor, 4);
  }

  void newMatch() => newGame();

  static List<PlayingCard> _newShuffledDeck() {
    return [
      for (final suit in Suit.values)
        for (final rank in Rank.values) PlayingCard(rank: rank, suit: suit),
    ];
  }

  void _dealCards(List<PlayingCard> hand, int count) {
    for (var i = 0; i < count && deck.isNotEmpty; i++) {
      hand.add(deck.removeLast());
    }
  }

  List<PlayingCard> floorCardsMatching(Rank rank) =>
      floor.where((c) => c.rank == rank).toList();

  List<PlayingCard> opponentPileCardsMatching(PlayerId player, Rank rank) =>
      pileFor(player.opponent).where((c) => c.rank == rank).toList();

  List<PlayingCard> ownPileCardsMatching(PlayerId player, Rank rank) =>
      pileFor(player).where((c) => c.rank == rank).toList();

  bool hasRankMatch(Rank rank) =>
      floorCardsMatching(rank).isNotEmpty ||
      opponentPileCardsMatching(turn, rank).isNotEmpty ||
      ownPileCardsMatching(turn, rank).isNotEmpty;

  /// Draw one card into the current player's hand. Returns false if game ended.
  bool drawCard() {
    if (phase == GamePhase.gameEnd) return false;
    if (phase != GamePhase.playing) return false;

    if (deck.isEmpty) {
      phase = GamePhase.gameEnd;
      selectedCard = null;
      return false;
    }

    handFor(turn).add(deck.removeLast());
    selectedCard = null;
    phase = GamePhase.awaitingPlay;
    return true;
  }

  void selectHandCard(PlayingCard card) {
    if (phase != GamePhase.awaitingPlay) return;
    final hand = handFor(turn);
    if (!hand.contains(card)) return;
    selectedCard = selectedCard == card ? null : card;
  }

  /// Place selected hand card on the floor (only when it has no matches).
  /// Dropping ends the turn.
  bool placeSelectedOnFloor() {
    if (phase != GamePhase.awaitingPlay || selectedCard == null) return false;
    if (selectionHasMatch) return false;

    final hand = handFor(turn);
    final card = selectedCard!;
    if (!hand.contains(card)) return false;

    hand.remove(card);
    floor.add(card);
    selectedCard = null;
    phase = GamePhase.playing;
    _endTurn();
    return true;
  }

  /// Collect by clicking a matching floor, opponent, or own-collection card.
  /// A successful match keeps the same player's turn (they draw again).
  bool collectByClickingMatch(PlayingCard target) {
    if (phase != GamePhase.awaitingPlay || selectedCard == null) return false;
    if (target.rank != selectedCard!.rank) return false;

    final onFloor = floor.contains(target);
    final onOpp = pileFor(turn.opponent).contains(target);
    final onOwn = pileFor(turn).contains(target);
    if (!onFloor && !onOpp && !onOwn) return false;

    final hand = handFor(turn);
    final card = selectedCard!;
    if (!hand.contains(card)) return false;

    hand.remove(card);
    _collectByRank(card);
    selectedCard = null;
    // Keep turn — combo continues until a card is dropped on the floor.
    phase = GamePhase.playing;
    return true;
  }

  void _collectByRank(PlayingCard played) {
    final pile = pileFor(turn);
    pile.add(played);

    final floorMatches = floorCardsMatching(played.rank);
    pile.addAll(floorMatches);
    floor.removeWhere((c) => c.rank == played.rank);

    final oppPile = pileFor(turn.opponent);
    final oppMatches = opponentPileCardsMatching(turn, played.rank);
    pile.addAll(oppMatches);
    oppPile.removeWhere((c) => c.rank == played.rank);
    // Own pile cards of this rank stay — already collected.
  }

  void _endTurn() {
    turn = turn.opponent;
  }

  void setStateForTest({
    List<PlayingCard>? deck,
    List<PlayingCard>? humanHand,
    List<PlayingCard>? aiHand,
    List<PlayingCard>? floor,
    List<PlayingCard>? humanPile,
    List<PlayingCard>? aiPile,
    PlayerId? turn,
    GamePhase? phase,
    PlayingCard? selectedCard,
  }) {
    this.deck = deck != null ? List.from(deck) : [];
    this.humanHand = humanHand != null ? List.from(humanHand) : [];
    this.aiHand = aiHand != null ? List.from(aiHand) : [];
    this.floor = floor != null ? List.from(floor) : [];
    this.humanPile = humanPile != null ? List.from(humanPile) : [];
    this.aiPile = aiPile != null ? List.from(aiPile) : [];
    if (turn != null) this.turn = turn;
    if (phase != null) this.phase = phase;
    this.selectedCard = selectedCard;
  }
}
