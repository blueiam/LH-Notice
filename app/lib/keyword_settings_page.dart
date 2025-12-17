import 'package:flutter/material.dart';
import 'keyword_service.dart';

class KeywordSettingsPage extends StatefulWidget {
  const KeywordSettingsPage({super.key});

  @override
  State<KeywordSettingsPage> createState() => _KeywordSettingsPageState();
}

class _KeywordSettingsPageState extends State<KeywordSettingsPage> {
  List<String> _keywords = [];
  final TextEditingController _keywordController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKeywords();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadKeywords() async {
    setState(() => _isLoading = true);
    try {
      final keywords = await KeywordService.getKeywords();
      setState(() {
        _keywords = keywords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('키워드 로드 오류: $e');
    }
  }

  Future<void> _addKeyword() async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) {
      _showSnackBar('키워드를 입력해주세요.');
      return;
    }

    try {
      final success = await KeywordService.addKeyword(keyword);
      if (success) {
        _keywordController.clear();
        await _loadKeywords();
        _showSnackBar('키워드가 추가되었습니다.');
      } else {
        // 중복 체크를 위해 현재 키워드 목록 확인
        final currentKeywords = await KeywordService.getKeywords();
        if (currentKeywords.contains(keyword)) {
          _showSnackBar('이미 등록된 키워드입니다.');
        } else {
          _showSnackBar('키워드 저장에 실패했습니다. 다시 시도해주세요.');
        }
      }
    } catch (e) {
      _showSnackBar('오류가 발생했습니다: $e');
    }
  }

  Future<void> _deleteKeyword(String keyword) async {
    // 삭제 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('키워드 삭제'),
        content: Text('"$keyword" 키워드를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await KeywordService.deleteKeyword(keyword);
      if (success) {
        await _loadKeywords();
        _showSnackBar('키워드가 삭제되었습니다.');
      } else {
        _showSnackBar('키워드 삭제에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      _showSnackBar('오류가 발생했습니다: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관심 키워드 설정',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 키워드 입력 영역
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keywordController,
                    decoration: InputDecoration(
                      hintText: '키워드를 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _addKeyword(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addKeyword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('추가'),
                ),
              ],
            ),
          ),
          // 키워드 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _keywords.isEmpty
                    ? const Center(
                        child: Text(
                          '등록된 키워드가 없습니다.\n위에서 키워드를 추가해주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _keywords.length,
                        itemBuilder: (context, index) {
                          final keyword = _keywords[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                keyword,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                onPressed: () => _deleteKeyword(keyword),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
