import 'dart:math';

/// Wordle-style word guessing game service.
class WordleService {
  static const int maxGuesses = 6;
  static const int wordLength = 5;

  static const List<String> _wordList = [
    'ABOUT', 'ABOVE', 'ABUSE', 'ACTOR', 'ACUTE', 'ADMIT', 'ADOPT', 'ADULT',
    'AFTER', 'AGAIN', 'AGENT', 'AGREE', 'AHEAD', 'ALARM', 'ALBUM', 'ALERT',
    'ALIEN', 'ALIGN', 'ALIKE', 'ALIVE', 'ALLOW', 'ALONE', 'ALONG', 'ALTER',
    'AMONG', 'ANGEL', 'ANGER', 'ANGLE', 'ANGRY', 'APART', 'APPLE', 'APPLY',
    'ARENA', 'ARISE', 'ASIDE', 'ASSET', 'AUDIO', 'AUDIT', 'AVOID', 'AWAIT',
    'AWAKE', 'AWARD', 'AWARE', 'BADLY', 'BAKER', 'BASES', 'BASIC', 'BASIN',
    'BASIS', 'BATCH', 'BEACH', 'BEARD', 'BEAST', 'BEGIN', 'BEING', 'BELOW',
    'BENCH', 'BERRY', 'BLACK', 'BLADE', 'BLAME', 'BLANK', 'BLAST', 'BLAZE',
    'BLEED', 'BLEND', 'BLESS', 'BLIND', 'BLINK', 'BLISS', 'BLOCK', 'BLOOM',
    'BLOWN', 'BOARD', 'BOAST', 'BONUS', 'BOOST', 'BOUND', 'BRAIN', 'BRAND',
    'BRAVE', 'BREAD', 'BREAK', 'BREED', 'BRICK', 'BRIDE', 'BRIEF', 'BRING',
    'BROAD', 'BROKE', 'BROWN', 'BRUSH', 'BUILD', 'BUNCH', 'BURST', 'BUYER',
    'CABIN', 'CABLE', 'CAMEL', 'CANDY', 'CARGO', 'CARRY', 'CATCH', 'CAUSE',
    'CEDAR', 'CHAIN', 'CHAIR', 'CHALK', 'CHAOS', 'CHARM', 'CHASE', 'CHEAP',
    'CHECK', 'CHEEK', 'CHEER', 'CHESS', 'CHEST', 'CHIEF', 'CHILD', 'CHUNK',
    'CIVIC', 'CIVIL', 'CLAIM', 'CLASS', 'CLEAN', 'CLEAR', 'CLICK', 'CLIFF',
    'CLIMB', 'CLING', 'CLOCK', 'CLONE', 'CLOSE', 'CLOTH', 'CLOUD', 'COACH',
    'COAST', 'COLOR', 'COMET', 'COMIC', 'CORAL', 'COUNT', 'COURT', 'COVER',
    'CRACK', 'CRAFT', 'CRANE', 'CRASH', 'CRAZY', 'CREAM', 'CREEK', 'CRIME',
    'CROSS', 'CROWD', 'CROWN', 'CRUEL', 'CRUSH', 'CURVE', 'CYCLE', 'DAILY',
    'DANCE', 'DEALT', 'DEATH', 'DEBUT', 'DELAY', 'DELTA', 'DENSE', 'DEPOT',
    'DEPTH', 'DERBY', 'DEVIL', 'DIGIT', 'DIRTY', 'DONOR', 'DOUBT', 'DOUGH',
    'DRAFT', 'DRAIN', 'DRAMA', 'DRANK', 'DRAWN', 'DREAM', 'DRESS', 'DRIED',
    'DRIFT', 'DRILL', 'DRINK', 'DRIVE', 'DRONE', 'DROWN', 'DYING', 'EAGER',
    'EARLY', 'EARTH', 'EIGHT', 'ELECT', 'ELITE', 'EMBER', 'EMPTY', 'ENEMY',
    'ENJOY', 'ENTER', 'ENTRY', 'EQUAL', 'ERROR', 'EVENT', 'EVERY', 'EXACT',
    'EXILE', 'EXIST', 'EXTRA', 'FABLE', 'FAITH', 'FALSE', 'FANCY', 'FATAL',
    'FAULT', 'FEAST', 'FENCE', 'FEVER', 'FIBER', 'FIELD', 'FIFTH', 'FIFTY',
    'FIGHT', 'FINAL', 'FIRST', 'FIXED', 'FLAME', 'FLASH', 'FLEET', 'FLESH',
    'FLOAT', 'FLOOD', 'FLOOR', 'FLORA', 'FLOUR', 'FLUID', 'FLUSH', 'FOCAL',
    'FOCUS', 'FORCE', 'FORGE', 'FORTH', 'FORUM', 'FOUND', 'FRAME', 'FRANK',
    'FRAUD', 'FRESH', 'FRONT', 'FROST', 'FROZE', 'FRUIT', 'FULLY', 'FUNNY',
    'GIANT', 'GIVEN', 'GLASS', 'GLOBE', 'GLOOM', 'GLORY', 'GLOVE', 'GOING',
    'GRACE', 'GRAIN', 'GRAND', 'GRANT', 'GRAPH', 'GRASP', 'GRASS', 'GRAVE',
    'GREAT', 'GREEN', 'GREET', 'GRIEF', 'GRILL', 'GRIND', 'GROSS', 'GROUP',
    'GROVE', 'GROWN', 'GUARD', 'GUESS', 'GUEST', 'GUIDE', 'GUILD', 'GUILT',
    'HABIT', 'HAPPY', 'HARSH', 'HAVEN', 'HEART', 'HEAVY', 'HENCE', 'HONEY',
    'HONOR', 'HORSE', 'HOTEL', 'HOUSE', 'HUMAN', 'HUMOR', 'HURRY', 'IDEAL',
    'IMAGE', 'IMPLY', 'INDEX', 'INNER', 'INPUT', 'INTRO', 'ISSUE', 'IVORY',
    'JEWEL', 'JOINT', 'JOKER', 'JUDGE', 'JUICE', 'KNOCK', 'KNOWN', 'LABEL',
    'LABOR', 'LANCE', 'LARGE', 'LASER', 'LATER', 'LAUGH', 'LAYER', 'LEARN',
    'LEASE', 'LEAST', 'LEAVE', 'LEGAL', 'LEVEL', 'LEVER', 'LIGHT', 'LIMIT',
    'LIVER', 'LOCAL', 'LODGE', 'LOGIC', 'LOOSE', 'LOVER', 'LOWER', 'LOYAL',
    'LUNAR', 'LUNCH', 'LYING', 'MAGIC', 'MAJOR', 'MAKER', 'MANOR', 'MAPLE',
    'MARCH', 'MATCH', 'MAYOR', 'MEDIA', 'MERCY', 'MERGE', 'MERIT', 'METAL',
    'METER', 'MIGHT', 'MINOR', 'MINUS', 'MIXED', 'MODEL', 'MONEY', 'MONTH',
    'MORAL', 'MOTOR', 'MOUNT', 'MOUSE', 'MOUTH', 'MOVIE', 'MUSIC', 'NAVAL',
    'NERVE', 'NEVER', 'NIGHT', 'NOBLE', 'NOISE', 'NORTH', 'NOTED', 'NOVEL',
    'NURSE', 'OCCUR', 'OCEAN', 'OFFER', 'OFTEN', 'OLIVE', 'ONSET', 'OPERA',
    'ORBIT', 'ORDER', 'OTHER', 'OUGHT', 'OUTER', 'PAINT', 'PANEL', 'PANIC',
    'PAPER', 'PARTY', 'PASTA', 'PATCH', 'PAUSE', 'PEACE', 'PEACH', 'PEARL',
    'PEDAL', 'PENNY', 'PHASE', 'PHONE', 'PHOTO', 'PIANO', 'PIECE', 'PILOT',
    'PINCH', 'PITCH', 'PIXEL', 'PIZZA', 'PLACE', 'PLAIN', 'PLANE', 'PLANT',
    'PLATE', 'PLAZA', 'POINT', 'POLAR', 'POUND', 'POWER', 'PRESS', 'PRICE',
    'PRIDE', 'PRIME', 'PRINT', 'PRIOR', 'PRIZE', 'PROBE', 'PROOF', 'PROUD',
    'PROVE', 'PROXY', 'PULSE', 'PUNCH', 'PUPIL', 'PURSE', 'QUEEN', 'QUEST',
    'QUEUE', 'QUICK', 'QUIET', 'QUILT', 'QUOTA', 'QUOTE', 'RADAR', 'RADIO',
    'RAISE', 'RANGE', 'RAPID', 'RATIO', 'REACH', 'READY', 'REALM', 'REBEL',
    'REFER', 'REIGN', 'RELAX', 'REPLY', 'RIDER', 'RIDGE', 'RIFLE', 'RIGHT',
    'RIGID', 'RISKY', 'RIVAL', 'RIVER', 'ROBIN', 'ROBOT', 'ROCKY', 'ROUGH',
    'ROUND', 'ROUTE', 'ROYAL', 'RUGBY', 'RULER', 'RURAL', 'SAINT', 'SALAD',
    'SCALE', 'SCARE', 'SCENE', 'SCENT', 'SCOPE', 'SCORE', 'SCOUT', 'SENSE',
    'SERVE', 'SEVEN', 'SHADE', 'SHAKE', 'SHALL', 'SHAME', 'SHAPE', 'SHARE',
    'SHARK', 'SHARP', 'SHEET', 'SHELF', 'SHELL', 'SHIFT', 'SHINE', 'SHIRT',
    'SHOCK', 'SHOOT', 'SHORT', 'SHOUT', 'SIGHT', 'SINCE', 'SIXTH', 'SIXTY',
    'SKILL', 'SKULL', 'SLATE', 'SLEEP', 'SLICE', 'SLIDE', 'SLOPE', 'SMART',
    'SMELL', 'SMILE', 'SMITH', 'SMOKE', 'SNAKE', 'SOLAR', 'SOLID', 'SOLVE',
    'SORRY', 'SOUND', 'SOUTH', 'SPACE', 'SPARE', 'SPARK', 'SPEAK', 'SPEED',
    'SPELL', 'SPEND', 'SPICE', 'SPINE', 'SPLIT', 'SPOKE', 'SPORT', 'SPRAY',
    'SQUAD', 'STAFF', 'STAGE', 'STAKE', 'STALE', 'STAMP', 'STAND', 'STARE',
    'START', 'STATE', 'STEAM', 'STEEL', 'STEEP', 'STEER', 'STICK', 'STILL',
    'STOCK', 'STONE', 'STOOD', 'STORE', 'STORM', 'STORY', 'STOVE', 'STRAP',
    'STRAW', 'STRIP', 'STUCK', 'STUDY', 'STUFF', 'STYLE', 'SUGAR', 'SUITE',
    'SUPER', 'SURGE', 'SWAMP', 'SWEAR', 'SWEEP', 'SWEET', 'SWEPT', 'SWIFT',
    'SWING', 'SWORD', 'TABLE', 'TAKEN', 'TASTE', 'TEACH', 'TEETH', 'TEMPO',
    'TERMS', 'THEFT', 'THEME', 'THERE', 'THICK', 'THIEF', 'THING', 'THINK',
    'THIRD', 'THORN', 'THREE', 'THREW', 'THROW', 'THUMB', 'TIDAL', 'TIGER',
    'TIGHT', 'TIMER', 'TIRED', 'TITLE', 'TODAY', 'TOKEN', 'TOTAL', 'TOUCH',
    'TOUGH', 'TOWEL', 'TOWER', 'TOXIC', 'TRACE', 'TRACK', 'TRADE', 'TRAIL',
    'TRAIN', 'TRAIT', 'TRASH', 'TREAT', 'TREND', 'TRIAL', 'TRIBE', 'TRICK',
    'TRIED', 'TROOP', 'TRUCK', 'TRULY', 'TRUNK', 'TRUST', 'TRUTH', 'TULIP',
    'TWICE', 'TWIST', 'ULTRA', 'UNCLE', 'UNDER', 'UNION', 'UNITE', 'UNITY',
    'UNTIL', 'UPPER', 'UPSET', 'URBAN', 'USAGE', 'USUAL', 'VAGUE', 'VALID',
    'VALUE', 'VALVE', 'VAPOR', 'VAULT', 'VENUE', 'VERSE', 'VIDEO', 'VIGOR',
    'VINYL', 'VIRAL', 'VIRUS', 'VISIT', 'VITAL', 'VIVID', 'VOCAL', 'VOICE',
    'VOTER', 'WASTE', 'WATCH', 'WATER', 'WEARY', 'WEDGE', 'WEIGH', 'WEIRD',
    'WHALE', 'WHEAT', 'WHEEL', 'WHERE', 'WHICH', 'WHILE', 'WHITE', 'WHOLE',
    'WHOSE', 'WIDTH', 'WITCH', 'WOMAN', 'WORLD', 'WORRY', 'WORSE', 'WORST',
    'WORTH', 'WOULD', 'WOUND', 'WRIST', 'WRITE', 'WRONG', 'WROTE', 'YACHT',
    'YIELD', 'YOUNG', 'YOUTH', 'ZEBRA',
  ];

  static final Set<String> _validWords =
      _wordList.map((w) => w.toUpperCase()).toSet();

  String _secret = '';
  List<String> _guesses = [];
  bool _gameOver = false;
  bool _won = false;
  int _streak = 0;
  int _bestStreak = 0;
  int _gamesPlayed = 0;
  int _gamesWon = 0;

  String get secret => _secret;
  List<String> get guesses => List.unmodifiable(_guesses);
  bool get gameOver => _gameOver;
  bool get won => _won;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  int get gamesPlayed => _gamesPlayed;
  int get gamesWon => _gamesWon;
  int get remainingGuesses => maxGuesses - _guesses.length;

  WordleService() { newGame(); }

  void newGame() {
    _secret = _wordList[Random().nextInt(_wordList.length)];
    _guesses = [];
    _gameOver = false;
    _won = false;
  }

  List<LetterState>? submitGuess(String guess) {
    final g = guess.toUpperCase().trim();
    if (g.length != wordLength || !_validWords.contains(g) || _gameOver) return null;
    _guesses.add(g);
    final states = evaluate(g);
    if (g == _secret) {
      _won = true; _gameOver = true; _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      _gamesPlayed++; _gamesWon++;
    } else if (_guesses.length >= maxGuesses) {
      _gameOver = true; _streak = 0; _gamesPlayed++;
    }
    return states;
  }

  List<LetterState> evaluate(String guess) {
    final states = List.filled(wordLength, LetterState.absent);
    final sc = _secret.split(''), gc = guess.toUpperCase().split('');
    final used = List.filled(wordLength, false);
    for (int i = 0; i < wordLength; i++) {
      if (gc[i] == sc[i]) { states[i] = LetterState.correct; used[i] = true; }
    }
    for (int i = 0; i < wordLength; i++) {
      if (states[i] == LetterState.correct) continue;
      for (int j = 0; j < wordLength; j++) {
        if (!used[j] && gc[i] == sc[j]) { states[i] = LetterState.present; used[j] = true; break; }
      }
    }
    return states;
  }

  Map<String, LetterState> get keyboardStates {
    final map = <String, LetterState>{};
    for (final guess in _guesses) {
      final states = evaluate(guess);
      for (int i = 0; i < wordLength; i++) {
        final l = guess[i], c = map[l], n = states[i];
        if (c == null || n.index > c.index) map[l] = n;
      }
    }
    return map;
  }
}

enum LetterState { absent, present, correct }
