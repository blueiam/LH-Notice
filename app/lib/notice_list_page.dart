import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'keyword_service.dart';
import 'keyword_settings_page.dart';
import 'hidden_items_service.dart';

class NoticeListPage extends StatefulWidget {
  final String source;
  final String pageTitle;

  const NoticeListPage({
    super.key,
    required this.source,
    required this.pageTitle,
  });

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  List<String> _keywords = [];
  bool _isFilterToggleOn = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _hiddenItemIds = {};

  @override
  void initState() {
    super.initState();
    _loadKeywords();
    _loadHiddenItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKeywords() async {
    final keywords = await KeywordService.getKeywords(source: widget.source);
    setState(() {
      _keywords = keywords;
    });
  }

  Future<void> _loadHiddenItems() async {
    final hiddenItems = await HiddenItemsService.getHiddenItems();
    setState(() {
      _hiddenItemIds = hiddenItems;
    });
  }

  Future<void> _openKeywordSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KeywordSettingsPage(source: widget.source),
      ),
    );
    _loadKeywords();
  }

  Future<void> _hideItem(String docId) async {
    final success = await HiddenItemsService.hideItem(docId);
    if (success) {
      setState(() {
        _hiddenItemIds.add(docId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('항목이 숨겨졌습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  bool _matchesKeywords(String title) {
    if (!_isFilterToggleOn || _keywords.isEmpty) {
      return true;
    }
    return _keywords.any((keyword) => title.contains(keyword));
  }

  bool _matchesSearch(String title) {
    if (_searchQuery.isEmpty) {
      return true;
    }
    return title.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 검색바 및 키워드 설정 영역 (AppBar 아래)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // 검색바
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '검색어를 입력하세요',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                // 키워드 필터 토글 및 설정 버튼
                Row(
                  children: [
                    if (_keywords.isNotEmpty) ...[
                      const Text(
                        '관심 키워드',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isFilterToggleOn,
                        onChanged: (value) {
                          setState(() {
                            _isFilterToggleOn = value;
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 16),
                    ],
                    TextButton.icon(
                      onPressed: _openKeywordSettings,
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('키워드 설정'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 공고 리스트
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notices')
                  .where('source', isEqualTo: widget.source)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류 발생: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      '등록된 공고가 없습니다.\n크롤러를 실행해주세요.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                // 숨김 아이템 필터링
                final visibleDocs = docs.where((doc) {
                  return !_hiddenItemIds.contains(doc.id);
                }).toList();

                // 키워드 및 검색 필터링
                final filteredDocs = visibleDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? '';
                  return _matchesKeywords(title) && _matchesSearch(title);
                }).toList();

                if (filteredDocs.isEmpty &&
                    (_isFilterToggleOn || _searchQuery.isNotEmpty)) {
                  String message = '';
                  if (_isFilterToggleOn && _searchQuery.isNotEmpty) {
                    message = '키워드와 검색어에 일치하는 공고가 없습니다.';
                  } else if (_isFilterToggleOn) {
                    message = '등록된 키워드와 일치하는 공고가 없습니다.';
                  } else if (_searchQuery.isNotEmpty) {
                    message = '"$_searchQuery" 검색 결과가 없습니다.';
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        if (_isFilterToggleOn) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _openKeywordSettings,
                            child: const Text('키워드 설정하기'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? '제목 없음';
                    final date = data['date'] ?? '날짜 없음';
                    final link = data['link'] ?? '';

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      onDismissed: (direction) {
                        _hideItem(doc.id);
                      },
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (link.isNotEmpty) {
                              _launchURL(link);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 날짜 배지
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    date,
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 제목
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // 하단 링크 안내
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '자세히 보기',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
