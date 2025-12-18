import 'package:shared_preferences/shared_preferences.dart';

class KeywordService {
  static const String _keywordsKeyPrefix = 'saved_keywords_';

  // 소스별 키워드 키 생성
  static String _getKeyForSource(String source) {
    return '$_keywordsKeyPrefix$source';
  }

  // 키워드 목록 가져오기 (소스별)
  static Future<List<String>> getKeywords({String source = 'LH'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForSource(source);
      final keywordsString = prefs.getString(key);
      if (keywordsString == null || keywordsString.isEmpty) {
        return [];
      }
      return keywordsString.split(',').where((k) => k.isNotEmpty).toList();
    } catch (e) {
      print('키워드 로드 오류: $e');
      return [];
    }
  }

  // 키워드 추가 (소스별)
  static Future<bool> addKeyword(String keyword, {String source = 'LH'}) async {
    try {
      if (keyword.trim().isEmpty) return false;

      final keywords = await getKeywords(source: source);
      final trimmedKeyword = keyword.trim();

      // 중복 체크
      if (keywords.contains(trimmedKeyword)) {
        return false;
      }

      keywords.add(trimmedKeyword);
      final success = await _saveKeywords(keywords, source: source);

      // 저장 후 검증
      if (success) {
        final savedKeywords = await getKeywords(source: source);
        if (savedKeywords.contains(trimmedKeyword)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('키워드 추가 오류: $e');
      return false;
    }
  }

  // 키워드 삭제 (소스별)
  static Future<bool> deleteKeyword(String keyword,
      {String source = 'LH'}) async {
    try {
      final keywords = await getKeywords(source: source);
      if (!keywords.contains(keyword)) {
        return false; // 키워드가 없으면 false 반환
      }

      keywords.remove(keyword);
      final success = await _saveKeywords(keywords, source: source);

      // 저장 후 검증
      if (success) {
        final savedKeywords = await getKeywords(source: source);
        if (!savedKeywords.contains(keyword)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('키워드 삭제 오류: $e');
      return false;
    }
  }

  // 키워드 목록 저장 (소스별)
  static Future<bool> _saveKeywords(List<String> keywords,
      {String source = 'LH'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForSource(source);
      final keywordsString = keywords.join(',');
      final success = await prefs.setString(key, keywordsString);

      if (success) {
        // 저장 성공 확인
        final saved = prefs.getString(key);
        return saved == keywordsString;
      }
      return false;
    } catch (e) {
      print('키워드 저장 오류: $e');
      return false;
    }
  }

  // 모든 키워드 삭제 (소스별)
  static Future<bool> clearAllKeywords({String source = 'LH'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForSource(source);
      return await prefs.remove(key);
    } catch (e) {
      print('키워드 전체 삭제 오류: $e');
      return false;
    }
  }
}
