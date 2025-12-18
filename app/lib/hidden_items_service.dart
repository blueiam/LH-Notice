import 'package:shared_preferences/shared_preferences.dart';

class HiddenItemsService {
  static const String _hiddenItemsKey = 'hidden_notice_ids';

  // 숨김 아이템 목록 가져오기
  static Future<Set<String>> getHiddenItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hiddenItemsString = prefs.getString(_hiddenItemsKey);
      if (hiddenItemsString == null || hiddenItemsString.isEmpty) {
        return {};
      }
      return hiddenItemsString.split(',').where((id) => id.isNotEmpty).toSet();
    } catch (e) {
      print('숨김 아이템 로드 오류: $e');
      return {};
    }
  }

  // 아이템 숨기기
  static Future<bool> hideItem(String itemId) async {
    try {
      final hiddenItems = await getHiddenItems();
      hiddenItems.add(itemId);
      return await _saveHiddenItems(hiddenItems);
    } catch (e) {
      print('아이템 숨기기 오류: $e');
      return false;
    }
  }

  // 숨김 아이템 목록 저장
  static Future<bool> _saveHiddenItems(Set<String> hiddenItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hiddenItemsString = hiddenItems.join(',');
      return await prefs.setString(_hiddenItemsKey, hiddenItemsString);
    } catch (e) {
      print('숨김 아이템 저장 오류: $e');
      return false;
    }
  }

  // 모든 숨김 아이템 삭제 (초기화)
  static Future<bool> clearAllHiddenItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_hiddenItemsKey);
    } catch (e) {
      print('숨김 아이템 전체 삭제 오류: $e');
      return false;
    }
  }
}


