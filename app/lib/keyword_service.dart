import 'package:shared_preferences/shared_preferences.dart';

class KeywordService {
  static const String _keywordsKey = 'saved_keywords';

  // 키워드 목록 가져오기
  static Future<List<String>> getKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keywordsString = prefs.getString(_keywordsKey);
      if (keywordsString == null || keywordsString.isEmpty) {
        return [];
      }
      return keywordsString.split(',').where((k) => k.isNotEmpty).toList();
    } catch (e) {
      print('키워드 로드 오류: $e');
      return [];
    }
  }

  // 키워드 추가
  static Future<bool> addKeyword(String keyword) async {
    try {
      if (keyword.trim().isEmpty) return false;

      final keywords = await getKeywords();
      final trimmedKeyword = keyword.trim();

      // 중복 체크
      if (keywords.contains(trimmedKeyword)) {
        return false;
      }

      keywords.add(trimmedKeyword);
      final success = await _saveKeywords(keywords);
      
      // 저장 후 검증
      if (success) {
        final savedKeywords = await getKeywords();
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

  // 키워드 삭제
  static Future<bool> deleteKeyword(String keyword) async {
    try {
      final keywords = await getKeywords();
      if (!keywords.contains(keyword)) {
        return false; // 키워드가 없으면 false 반환
      }
      
      keywords.remove(keyword);
      final success = await _saveKeywords(keywords);
      
      // 저장 후 검증
      if (success) {
        final savedKeywords = await getKeywords();
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

  // 키워드 목록 저장
  static Future<bool> _saveKeywords(List<String> keywords) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keywordsString = keywords.join(',');
      final success = await prefs.setString(_keywordsKey, keywordsString);
      
      if (success) {
        // 저장 성공 확인
        final saved = prefs.getString(_keywordsKey);
        return saved == keywordsString;
      }
      return false;
    } catch (e) {
      print('키워드 저장 오류: $e');
      return false;
    }
  }

  // 모든 키워드 삭제
  static Future<bool> clearAllKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_keywordsKey);
    } catch (e) {
      print('키워드 전체 삭제 오류: $e');
      return false;
    }
  }
}
