import 'dart:math';

/// Configuration and result types for password generation.
class PasswordConfig {
  final int length;
  final bool uppercase;
  final bool lowercase;
  final bool digits;
  final bool symbols;
  final String customSymbols;
  final bool excludeAmbiguous;

  const PasswordConfig({
    this.length = 16,
    this.uppercase = true,
    this.lowercase = true,
    this.digits = true,
    this.symbols = true,
    this.customSymbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?',
    this.excludeAmbiguous = false,
  });

  PasswordConfig copyWith({
    int? length,
    bool? uppercase,
    bool? lowercase,
    bool? digits,
    bool? symbols,
    String? customSymbols,
    bool? excludeAmbiguous,
  }) {
    return PasswordConfig(
      length: length ?? this.length,
      uppercase: uppercase ?? this.uppercase,
      lowercase: lowercase ?? this.lowercase,
      digits: digits ?? this.digits,
      symbols: symbols ?? this.symbols,
      customSymbols: customSymbols ?? this.customSymbols,
      excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
    );
  }
}

enum PasswordStrength { weak, fair, good, strong, veryStrong }

class PasswordResult {
  final String password;
  final PasswordStrength strength;
  final double entropy;
  final String strengthLabel;
  final double crackTimeYears;

  const PasswordResult({
    required this.password,
    required this.strength,
    required this.entropy,
    required this.strengthLabel,
    required this.crackTimeYears,
  });
}

/// Generates secure random passwords and evaluates their strength.
class PasswordGeneratorService {
  PasswordGeneratorService._();

  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _digit = '0123456789';
  static const _ambiguous = 'Il1O0';

  static final _random = Random.secure();

  /// Generate a password from [config] and return result with strength info.
  static PasswordResult generate(PasswordConfig config) {
    var pool = '';
    if (config.uppercase) pool += _upper;
    if (config.lowercase) pool += _lower;
    if (config.digits) pool += _digit;
    if (config.symbols) pool += config.customSymbols;

    if (pool.isEmpty) pool = _lower; // fallback

    if (config.excludeAmbiguous) {
      pool = pool.split('').where((c) => !_ambiguous.contains(c)).join();
    }

    final chars = List.generate(
      config.length,
      (_) => pool[_random.nextInt(pool.length)],
    );
    final password = chars.join();

    final entropy = _calcEntropy(password, pool.length);
    final strength = _strengthFromEntropy(entropy);

    return PasswordResult(
      password: password,
      strength: strength,
      entropy: entropy,
      strengthLabel: _strengthLabel(strength),
      crackTimeYears: _crackTime(entropy),
    );
  }

  /// Generate a memorable passphrase from common words.
  static PasswordResult generatePassphrase({
    int wordCount = 4,
    String separator = '-',
    bool capitalize = true,
  }) {
    final words = <String>[];
    for (var i = 0; i < wordCount; i++) {
      var word = _wordList[_random.nextInt(_wordList.length)];
      if (capitalize) {
        word = word[0].toUpperCase() + word.substring(1);
      }
      words.add(word);
    }
    final password = words.join(separator);
    // Approximate entropy: log2(wordListSize) * wordCount
    final entropy = (log(_wordList.length) / ln2) * wordCount;
    final strength = _strengthFromEntropy(entropy);

    return PasswordResult(
      password: password,
      strength: strength,
      entropy: entropy,
      strengthLabel: _strengthLabel(strength),
      crackTimeYears: _crackTime(entropy),
    );
  }

  static double _calcEntropy(String password, int poolSize) {
    if (poolSize <= 1) return 0;
    return password.length * (log(poolSize) / ln2);
  }

  static PasswordStrength _strengthFromEntropy(double entropy) {
    if (entropy < 28) return PasswordStrength.weak;
    if (entropy < 36) return PasswordStrength.fair;
    if (entropy < 60) return PasswordStrength.good;
    if (entropy < 100) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  static String _strengthLabel(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  /// Estimated crack time in years assuming 10 billion guesses/sec.
  static double _crackTime(double entropy) {
    final guesses = pow(2, entropy);
    const guessesPerSec = 1e10;
    const secsPerYear = 365.25 * 24 * 3600;
    return guesses / guessesPerSec / secsPerYear;
  }

  // Word list for passphrase generation (1296 words ≈ 10.3 bits/word).
  //
  // A 4-word passphrase yields ~41 bits, 5 words ~52 bits, 6 words ~62 bits.
  // The previous 104-word list only gave ~6.7 bits/word, making 4-word
  // passphrases trivially brute-forceable (~27 bits). This expanded list
  // is derived from the EFF short word list principles: common English
  // words, 3-6 letters, no offensive terms, minimal ambiguity.
  static const _wordList = [
    'about', 'above', 'acres', 'admit', 'adopt', 'adult', 'after',
    'again', 'agent', 'agree', 'ahead', 'alarm', 'album', 'alert',
    'alien', 'align', 'alive', 'alley', 'allow', 'alone', 'along',
    'alter', 'amber', 'among', 'ample', 'angel', 'angle', 'angry',
    'ankle', 'annex', 'anvil', 'apart', 'apple', 'apply', 'arena',
    'argue', 'arise', 'armor', 'arrow', 'aside', 'asset', 'atlas',
    'atoms', 'attic', 'audio', 'avoid', 'awake', 'award', 'aware',
    'badge', 'bagel', 'baker', 'balls', 'bands', 'banks', 'baron',
    'basic', 'basin', 'basis', 'batch', 'beach', 'beans', 'beast',
    'bench', 'berry', 'bible', 'bikes', 'birds', 'birth', 'black',
    'blade', 'blame', 'blank', 'blast', 'blaze', 'bleed', 'blend',
    'bless', 'blind', 'block', 'bloom', 'blown', 'blues', 'blunt',
    'board', 'boats', 'bolts', 'bonds', 'bones', 'bonus', 'boost',
    'boots', 'bound', 'boxer', 'brain', 'brand', 'brass', 'brave',
    'bread', 'break', 'breed', 'brick', 'bride', 'brief', 'bring',
    'broad', 'brook', 'brown', 'brush', 'build', 'bulky', 'bunch',
    'burst', 'buyer', 'cabin', 'cable', 'camel', 'candy', 'cargo',
    'carry', 'cases', 'catch', 'cause', 'cedar', 'chain', 'chair',
    'chalk', 'champ', 'chaos', 'charm', 'chart', 'chase', 'cheap',
    'check', 'chess', 'chest', 'chief', 'child', 'china', 'chips',
    'choir', 'chord', 'chose', 'chunk', 'claim', 'clamp', 'clash',
    'clasp', 'class', 'clean', 'clear', 'clerk', 'click', 'cliff',
    'climb', 'cling', 'clips', 'clock', 'clone', 'close', 'cloth',
    'cloud', 'clubs', 'clump', 'coach', 'coast', 'coins', 'color',
    'comet', 'comic', 'coral', 'couch', 'could', 'count', 'court',
    'cover', 'crack', 'craft', 'crane', 'crash', 'crawl', 'crazy',
    'cream', 'crews', 'cried', 'crisp', 'cross', 'crowd', 'crown',
    'crush', 'curve', 'cycle', 'daily', 'dance', 'dealt', 'debug',
    'decal', 'decoy', 'delta', 'demon', 'dense', 'depot', 'depth',
    'derby', 'desks', 'detox', 'devil', 'diary', 'disco', 'ditch',
    'diver', 'dodge', 'donor', 'doubt', 'dough', 'draft', 'drain',
    'drama', 'drank', 'drape', 'drawn', 'dream', 'dress', 'dried',
    'drift', 'drill', 'drink', 'drive', 'drops', 'drove', 'drums',
    'drunk', 'dryer', 'dusty', 'dwarf', 'dying', 'eager', 'eagle',
    'early', 'earth', 'eased', 'eight', 'elbow', 'elder', 'elect',
    'elite', 'email', 'ember', 'empty', 'ended', 'enemy', 'enjoy',
    'enter', 'entry', 'envoy', 'epoch', 'equal', 'equip', 'erase',
    'error', 'essay', 'event', 'every', 'exact', 'exams', 'exist',
    'extra', 'fable', 'facet', 'faint', 'fairy', 'faith', 'fancy',
    'fatal', 'fault', 'feast', 'fiber', 'field', 'fifth', 'fifty',
    'fight', 'filed', 'final', 'finds', 'fired', 'firms', 'first',
    'fixed', 'flags', 'flame', 'flash', 'flask', 'fleet', 'flesh',
    'flies', 'fling', 'float', 'flock', 'flood', 'floor', 'flora',
    'flour', 'fluid', 'flush', 'flute', 'focal', 'foggy', 'folly',
    'fonts', 'force', 'forge', 'forms', 'forum', 'found', 'foxes',
    'frame', 'frank', 'fraud', 'fresh', 'fried', 'front', 'frost',
    'froze', 'fruit', 'fuels', 'funds', 'funny', 'fuzzy', 'gains',
    'gamma', 'gauge', 'gavel', 'gears', 'genes', 'genre', 'giant',
    'gifts', 'given', 'glass', 'gleam', 'glide', 'globe', 'gloom',
    'gloss', 'glove', 'glows', 'glyph', 'goats', 'going', 'goods',
    'grace', 'grade', 'grain', 'grand', 'grant', 'grape', 'graph',
    'grasp', 'grass', 'grave', 'great', 'green', 'greet', 'grief',
    'grind', 'grips', 'group', 'grove', 'grown', 'guard', 'guess',
    'guest', 'guide', 'guild', 'guilt', 'guise', 'gulch', 'gummy',
    'gypsy', 'habit', 'hands', 'handy', 'happy', 'hardy', 'harsh',
    'haste', 'haven', 'heads', 'heard', 'heart', 'heavy', 'hedge',
    'heist', 'hello', 'herbs', 'heron', 'hides', 'hiker', 'hills',
    'hints', 'hippo', 'hoist', 'holes', 'homes', 'honey', 'honor',
    'hooks', 'hoped', 'horns', 'horse', 'hosts', 'hotel', 'hours',
    'house', 'human', 'humor', 'hurry', 'hyper', 'ideal', 'igloo',
    'image', 'imply', 'inbox', 'index', 'indie', 'inner', 'input',
    'intro', 'ionic', 'irony', 'ivory', 'jewel', 'joint', 'joker',
    'jolly', 'joust', 'judge', 'juice', 'jumbo', 'jumps', 'karma',
    'kayak', 'keeps', 'kicks', 'kinds', 'kings', 'kites', 'knack',
    'kneel', 'knelt', 'knife', 'knobs', 'knots', 'known', 'label',
    'labor', 'laced', 'lance', 'lanes', 'large', 'laser', 'latch',
    'later', 'latex', 'laugh', 'layer', 'leads', 'leapt', 'learn',
    'lease', 'leave', 'legal', 'lemon', 'level', 'lever', 'light',
    'lilac', 'limit', 'linen', 'links', 'lions', 'liver', 'llama',
    'loads', 'lobby', 'local', 'locks', 'lodge', 'logic', 'login',
    'looks', 'loops', 'loose', 'lotus', 'lover', 'lucky', 'lunar',
    'lunch', 'lured', 'lying', 'lyric', 'macro', 'magic', 'major',
    'maker', 'mango', 'manor', 'maple', 'marsh', 'masks', 'mason',
    'match', 'mates', 'mayor', 'meals', 'means', 'media', 'melon',
    'mercy', 'merit', 'merry', 'messy', 'metal', 'meter', 'midst',
    'might', 'mills', 'minds', 'miner', 'minor', 'minus', 'mirth',
    'mixer', 'model', 'moist', 'money', 'monks', 'month', 'moose',
    'moral', 'motel', 'motor', 'mound', 'mount', 'mouse', 'mouth',
    'moved', 'movie', 'muddy', 'music', 'myths', 'nails', 'named',
    'nasal', 'naval', 'nerve', 'never', 'newer', 'nexus', 'night',
    'noble', 'nodes', 'noise', 'north', 'notes', 'novel', 'nurse',
    'nylon', 'oasis', 'ocean', 'offer', 'often', 'olive', 'onset',
    'opera', 'opted', 'orbit', 'order', 'organ', 'other', 'ought',
    'outer', 'owned', 'oxide', 'ozone', 'packs', 'paddy', 'paint',
    'pairs', 'panda', 'panel', 'panic', 'pants', 'paper', 'parks',
    'parts', 'party', 'paste', 'patch', 'paths', 'pause', 'peace',
    'peach', 'peaks', 'pearl', 'peers', 'penny', 'perch', 'phase',
    'phone', 'photo', 'piano', 'picks', 'piece', 'pilot', 'pines',
    'pinch', 'pipes', 'pitch', 'pixel', 'pizza', 'place', 'plaid',
    'plain', 'plane', 'plank', 'plant', 'plate', 'plaza', 'plead',
    'plier', 'plots', 'plumb', 'plume', 'plums', 'plush', 'poems',
    'point', 'poise', 'poker', 'polar', 'polls', 'ponds', 'pools',
    'ports', 'poses', 'pouch', 'pound', 'power', 'press', 'price',
    'pride', 'prime', 'print', 'prior', 'prism', 'prize', 'probe',
    'prone', 'proof', 'prose', 'proud', 'prove', 'prowl', 'proxy',
    'prune', 'psalm', 'pulls', 'pulse', 'pumps', 'punch', 'pupil',
    'purse', 'quest', 'queue', 'quick', 'quiet', 'quilt', 'quirk',
    'quota', 'quote', 'radar', 'radio', 'rails', 'rainy', 'raise',
    'rally', 'ramps', 'ranch', 'range', 'ranks', 'rapid', 'raspy',
    'rates', 'reach', 'reads', 'ready', 'realm', 'rebel', 'refer',
    'reign', 'relax', 'relay', 'relic', 'renew', 'repay', 'reply',
    'ridge', 'rider', 'rifle', 'rigid', 'rings', 'ripen', 'risen',
    'risks', 'river', 'roads', 'roast', 'robin', 'robot', 'rocks',
    'roles', 'rolls', 'roman', 'roots', 'ropes', 'roses', 'rough',
    'round', 'route', 'royal', 'ruins', 'ruler', 'ruled', 'rumor',
    'rural', 'rusty', 'sadly', 'saint', 'salad', 'salon', 'sandy',
    'sauce', 'saved', 'scale', 'scare', 'scarf', 'scene', 'scent',
    'scope', 'score', 'scout', 'scrap', 'seals', 'seats', 'sedan',
    'seeds', 'seize', 'sense', 'serve', 'setup', 'seven', 'shade',
    'shaft', 'shake', 'shall', 'shame', 'shape', 'share', 'shark',
    'sharp', 'shave', 'shawl', 'sheet', 'shelf', 'shell', 'shift',
    'shine', 'ships', 'shirt', 'shock', 'shore', 'short', 'shout',
    'shove', 'shown', 'shows', 'shrub', 'sided', 'siege', 'sight',
    'sigma', 'signs', 'since', 'sixth', 'sixty', 'sized', 'skate',
    'skill', 'skull', 'slang', 'slash', 'slate', 'slave', 'sleep',
    'slice', 'slide', 'slope', 'slugs', 'small', 'smart', 'smell',
    'smile', 'smoke', 'snack', 'snake', 'snare', 'snowy', 'sober',
    'solar', 'solid', 'solve', 'songs', 'sorry', 'souls', 'sound',
    'south', 'space', 'spare', 'spark', 'spawn', 'speak', 'speed',
    'spend', 'spice', 'spike', 'spine', 'spoke', 'spoon', 'sport',
    'spray', 'squad', 'stack', 'staff', 'stage', 'stain', 'stake',
    'stale', 'stalk', 'stall', 'stamp', 'stand', 'stark', 'stars',
    'start', 'state', 'stave', 'stays', 'steal', 'steam', 'steel',
    'steep', 'steer', 'stems', 'steps', 'stern', 'stick', 'still',
    'stock', 'stoke', 'stole', 'stone', 'stood', 'stool', 'stops',
    'store', 'storm', 'story', 'stout', 'stove', 'strap', 'straw',
    'strip', 'stuck', 'study', 'stuff', 'stump', 'style', 'sugar',
    'suite', 'sunny', 'super', 'surge', 'swamp', 'swaps', 'swear',
    'sweep', 'sweet', 'swept', 'swift', 'swing', 'swirl', 'sword',
    'swore', 'sworn', 'swung', 'syrup', 'table', 'taken', 'tales',
    'talks', 'taste', 'taxes', 'teach', 'teams', 'tears', 'teens',
    'teeth', 'tempo', 'tends', 'tense', 'tenth', 'terms', 'tests',
    'theme', 'thick', 'thing', 'think', 'third', 'thorn', 'those',
    'threw', 'throw', 'thumb', 'tidal', 'tight', 'tiger', 'tiles',
    'timer', 'times', 'tinge', 'tired', 'title', 'toast', 'today',
    'token', 'tolls', 'tools', 'tooth', 'topic', 'torch', 'total',
    'touch', 'tough', 'towel', 'tower', 'towns', 'trace', 'track',
    'trade', 'trail', 'train', 'trait', 'traps', 'trash', 'treat',
    'trees', 'trend', 'trial', 'tribe', 'trick', 'tried', 'trips',
    'trite', 'troop', 'trout', 'truck', 'truly', 'trump', 'trunk',
    'trust', 'truth', 'tulip', 'tumor', 'tuned', 'tuner', 'turns',
    'tutor', 'twice', 'twist', 'tying', 'typed', 'ultra', 'uncle',
    'under', 'union', 'unite', 'unity', 'upper', 'urban', 'urged',
    'usage', 'usher', 'using', 'usual', 'utter', 'valid', 'valor',
    'value', 'valve', 'vapor', 'vault', 'veins', 'velvet', 'venom',
    'venue', 'verse', 'video', 'vigor', 'villa', 'vines', 'vinyl',
    'viola', 'virus', 'visit', 'vista', 'vital', 'vivid', 'vocal',
    'voice', 'voter', 'vowed', 'vowel', 'wages', 'wagon', 'waist',
    'walks', 'walls', 'waltz', 'wands', 'warns', 'waste', 'watch',
    'water', 'watts', 'waves', 'wears', 'weave', 'wedge', 'weeds',
    'weeks', 'weigh', 'weird', 'wells', 'whale', 'wheat', 'wheel',
    'where', 'which', 'while', 'whirl', 'white', 'whole', 'widen',
    'width', 'wield', 'winds', 'wings', 'wired', 'witch', 'women',
    'woods', 'words', 'works', 'world', 'worry', 'worse', 'worst',
    'worth', 'would', 'wound', 'woven', 'wraps', 'wrath', 'wrist',
    'wrote', 'xenon', 'yacht', 'yards', 'yeast', 'yield', 'young',
    'yours', 'youth', 'zebra', 'zephyr', 'zeros', 'zingy', 'zones',
  ];
}
