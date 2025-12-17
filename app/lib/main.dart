import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'keyword_service.dart';
import 'keyword_settings_page.dart';

void main() async {
  // 1. 플러터 엔진과 파이어베이스 초기화
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LH 공모 알림',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const NoticeListPage(),
    );
  }
}

class NoticeListPage extends StatefulWidget {
  const NoticeListPage({super.key});

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  List<String> _keywords = [];
  bool _isFilterToggleOn = false; // 토글 상태
  String _searchQuery = ''; // 검색어
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false; // 검색바 표시 여부

  @override
  void initState() {
    super.initState();
    _loadKeywords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKeywords() async {
    final keywords = await KeywordService.getKeywords();
    setState(() {
      _keywords = keywords;
      // 키워드가 있으면 토글을 켤 수 있도록 함
    });
  }

  Future<void> _openKeywordSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KeywordSettingsPage()),
    );
    // 설정 화면에서 돌아오면 키워드 다시 로드
    _loadKeywords();
  }

  // 키워드 필터링: 토글이 켜져있고 키워드가 있으면 필터링
  bool _matchesKeywords(String title) {
    // 토글이 꺼져있으면 모든 공고 표시
    if (!_isFilterToggleOn || _keywords.isEmpty) {
      return true;
    }
    // 등록된 키워드 중 하나라도 제목에 포함되어 있으면 표시
    return _keywords.any((keyword) => title.contains(keyword));
  }

  // 검색 필터링
  bool _matchesSearch(String title) {
    if (_searchQuery.isEmpty) {
      return true;
    }
    return title.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  // 링크 여는 함수
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // 링크 열기 실패 시 스낵바 표시
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
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '검색어를 입력하세요',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('LH 공모 알림',
                style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: !_isSearchVisible,
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          // 검색 버튼
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            tooltip: '검색',
          ),
          // 키워드 필터 토글 버튼
          if (_keywords.isNotEmpty)
            Row(
              children: [
                const Text(
                  '키워드',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _isFilterToggleOn,
                  onChanged: (value) {
                    setState(() {
                      _isFilterToggleOn = value;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          // 설정 버튼
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openKeywordSettings,
            tooltip: '키워드 설정',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 2. Firestore의 'notices' 컬렉션을 실시간 감시
        stream: FirebaseFirestore.instance
            .collection('notices')
            .orderBy('date', descending: true) // 최신 날짜순 정렬
            .snapshots(),
        builder: (context, snapshot) {
          // 로딩 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 에러가 났을 때
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          // 데이터가 없을 때
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '등록된 공고가 없습니다.\n크롤러를 실행해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // 3. 데이터가 있으면 리스트로 보여주기
          final docs = snapshot.data!.docs;

          // 키워드 필터링 및 검색 필터링 적용
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            // 키워드 필터링과 검색 필터링 모두 통과해야 표시
            return _matchesKeywords(title) && _matchesSearch(title);
          }).toList();

          if (filteredDocs.isEmpty && (_isFilterToggleOn || _searchQuery.isNotEmpty)) {
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
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
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

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                              horizontal: 8, vertical: 4),
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
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Icon(Icons.chevron_right,
                                size: 16, color: Colors.grey),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
