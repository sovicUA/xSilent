/// Проста перевірка тексту оголошення на ненормативну лексику.
///
/// Мета — відповідність віковій категорії «до 18 / діти» в Google Play: текст
/// нагадування показується у сповіщенні й (за бажанням) синтезується вголос,
/// тож не має містити нецензурщини. Це не строгий модератор, а базовий фільтр
/// за коренями слів (укр. + рос. мат + поширена англ.), стійкий до типової
/// обфускації (лат. двійники, крапки/дефіси між літерами, повтори, розрядка).
class ProfanityFilter {
  const ProfanityFilter._();

  /// Корені лайливих слів. Збіг — якщо нормалізований токен *починається* з
  /// кореня (ловить словоформи: «блядь», «блядський», «наблядувати»…).
  /// Тримаємо перелік коротким і однозначним, щоб уникати хибних спрацювань.
  static const Set<String> _roots = {
    // укр./рос. мат
    'бляд', 'блят',
    'хуй', 'хуя', 'хує', 'хуе', 'хуё', 'хуи', 'хуї', 'хуйн', 'хуйл',
    'ахує', 'ахуе', 'охує', 'охуе', 'нахуй', 'нахуя', 'похуй', 'похую',
    'пизд', 'пізд',
    'єбан', 'ебан', 'їбан', 'єбат', 'ебат', 'їбат', 'єбав', 'ебал',
    'єбну', 'ебну', 'їбну', 'єбуч', 'ебуч', 'уєбо', 'уебо', 'уёбо',
    'йобан', 'йобн', 'заєб', 'заеб', 'наєб', 'наеб', 'виїб', 'виеб',
    'підар', 'підор', 'пидар', 'пидор', 'педрил',
    'гандон', 'гондон', 'мудак', 'мудил', 'мудач',
    'залуп', 'курва', 'курви', 'пиздюк', 'піздюк',
    'сука', 'суко', 'сучка', 'сучий', 'сученя', 'сучар',
    // англ.
    'fuck', 'shit', 'bitch', 'cunt', 'asshole', 'bastard',
    'motherf', 'nigger', 'faggot',
  };

  /// Лат. (та кілька цифрових) двійники → кирилиця. Застосовується як
  /// *додатковий* варіант токена — щоб зловити «xyй», «6лядь». Навмисно без
  /// поширених у англ. `u/n/h/s/r/g`, щоб не ламати звичайні англійські слова.
  static const Map<String, String> _homoglyphs = {
    'a': 'а', 'c': 'с', 'e': 'е', 'i': 'і', 'o': 'о', 'p': 'р', 'x': 'х',
    'y': 'у', 'k': 'к', 'm': 'м', 't': 'т', 'b': 'б', 'l': 'л',
    '0': 'о', '3': 'з', '6': 'б', '@': 'а',
  };

  static final RegExp _wordSplit = RegExp(r'\s+');
  static final RegExp _nonLetterRun = RegExp(r'\P{L}+', unicode: true);
  static final RegExp _edges = RegExp(r'^\P{L}+|\P{L}+$', unicode: true);

  /// Розрядка по літері: «х у й», «б л я д ь» (щонайменше 3 поодиноких літери).
  static final RegExp _spacedOut = RegExp(
    r'(?<!\p{L})(\p{L}(?:\s+\p{L}){2,})(?!\p{L})',
    unicode: true,
  );

  /// `true`, якщо текст містить лайливе слово.
  static bool containsProfanity(String text) {
    final lower = text.toLowerCase();

    for (final rawToken in lower.split(_wordSplit)) {
      if (rawToken.isEmpty) continue;
      final candidates = <String>{};
      for (final v in {rawToken, _deObfuscate(rawToken)}) {
        candidates
          ..add(_collapse(v.replaceAll(_edges, ''))) // обрізане по краях
          ..add(_collapse(v.replaceAll(_nonLetterRun, ''))); // «х.у.й» → «хуй»
      }
      if (_hasRootPrefix(candidates)) return true;
    }

    for (final m in _spacedOut.allMatches(lower)) {
      final joined =
          _collapse(_deObfuscate(m.group(1)!).replaceAll(_nonLetterRun, ''));
      if (_hasRootPrefix({joined})) return true;
    }

    return false;
  }

  static bool _hasRootPrefix(Iterable<String> candidates) {
    for (final c in candidates) {
      if (c.isEmpty) continue;
      for (final root in _roots) {
        if (c.startsWith(root)) return true;
      }
    }
    return false;
  }

  /// Стиснення повторів літер: «хууй» → «хуй».
  static String _collapse(String s) {
    final buf = StringBuffer();
    String? prev;
    for (final ch in s.split('')) {
      if (ch == prev) continue;
      buf.write(ch);
      prev = ch;
    }
    return buf.toString();
  }

  static String _deObfuscate(String s) {
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      buf.write(_homoglyphs[ch] ?? ch);
    }
    return buf.toString();
  }
}
