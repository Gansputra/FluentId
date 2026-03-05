import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String _xpKey = 'user_xp';
  static const String _masteredKeyPrefix = 'mastered_';

  // Save XP
  Future<void> addXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int currentXp = prefs.getInt(_xpKey) ?? 0;
    await prefs.setInt(_xpKey, currentXp + amount);
  }

  // Get XP
  Future<int> getXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_xpKey) ?? 0;
  }

  // Mark word as mastered
  Future<void> masterWord(String level, String wordId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> masteredList = prefs.getStringList('$_masteredKeyPrefix$level') ?? [];
    if (!masteredList.contains(wordId.toString())) {
      masteredList.add(wordId.toString());
      await prefs.setStringList('$_masteredKeyPrefix$level', masteredList);
      // Give XP bonus for mastering a word
      await addXp(10);
    }
  }

  // Get mastered count for a level
  Future<int> getMasteredCount(String level) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> masteredList = prefs.getStringList('$_masteredKeyPrefix$level') ?? [];
    return masteredList.length;
  }

  // Check if a word is mastered
  Future<bool> isWordMastered(String level, String wordId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> masteredList = prefs.getStringList('$_masteredKeyPrefix$level') ?? [];
    return masteredList.contains(wordId.toString());
  }
}
