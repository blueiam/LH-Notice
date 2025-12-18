import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'keyword_service.dart';
// import 'keyword_settings_page.dart';
import 'hidden_items_service.dart';
import 'main.dart';

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
  // List<String> _keywords = [];
  // bool _isFilterToggleOn = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _hiddenItemIds = {};

  @override
  void initState() {
    super.initState();
    // _loadKeywords();
    _loadHiddenItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Future<void> _loadKeywords() async {
  //   final keywords = await KeywordService.getKeywords(source: widget.source);
  //   setState(() {
  //     _keywords = keywords;
  //   });
  // }

  Future<void> _loadHiddenItems() async {
    final hiddenItems = await HiddenItemsService.getHiddenItems();
    setState(() {
      _hiddenItemIds = hiddenItems;
    });
  }

  // Future<void> _openKeywordSettings() async {
  //   await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => KeywordSettingsPage(source: widget.source),
  //     ),
  //   );
  //   _loadKeywords();
  // }

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

  // bool _matchesKeywords(String title) {
  //   if (!_isFilterToggleOn || _keywords.isEmpty) {
  //     return true;
  //   }
  //   return _keywords.any((keyword) => title.contains(keyword));
  // }

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

  IconData _getSectionIcon() {
    switch (widget.source) {
      case 'LH':
        return Icons.home;
      case 'KAMS':
        return Icons.palette;
      case 'Seoul':
        return Icons.location_city;
      case 'SeoulPublicArt':
        return Icons.brush;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 검색바 및 키워드 설정 영역 (AppBar 아래)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: MyApp.surfaceColor,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // 검색바
                  Container(
                    decoration: BoxDecoration(
                      color: MyApp.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      enableSuggestions: true,
                      autocorrect: true,
                      enableInteractiveSelection: true,
                      maxLines: 1,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: MyApp.textPrimary,
                      ),
                      inputFormatters: null,
                      decoration: InputDecoration(
                        hintText: '검색어를 입력하세요',
                        hintStyle: GoogleFonts.notoSansKr(
                          color: MyApp.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: MyApp.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: MyApp.textSecondary,
                                ),
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
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: MyApp.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: MyApp.surfaceColor,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onSubmitted: (value) {
                        // 검색 실행 (필요시 추가 로직)
                      },
                    ),
                  ),
                  // const SizedBox(height: 8),
                  // // 키워드 필터 토글 및 설정 버튼
                  // Row(
                  //   children: [
                  //     if (_keywords.isNotEmpty) ...[
                  //       Text(
                  //         '관심 키워드',
                  //         style: GoogleFonts.notoSansKr(
                  //           fontSize: 14,
                  //           fontWeight: FontWeight.w400,
                  //           color: MyApp.textPrimary,
                  //         ),
                  //       ),
                  //       const SizedBox(width: 8),
                  //       Switch(
                  //         value: _isFilterToggleOn,
                  //         onChanged: (value) {
                  //           setState(() {
                  //             _isFilterToggleOn = value;
                  //           });
                  //         },
                  //         activeColor: MyApp.primaryColor,
                  //         materialTapTargetSize:
                  //             MaterialTapTargetSize.shrinkWrap,
                  //       ),
                  //       const SizedBox(width: 16),
                  //     ],
                  //     TextButton.icon(
                  //       onPressed: _openKeywordSettings,
                  //       icon: Icon(
                  //         Icons.settings,
                  //         size: 18,
                  //         color: MyApp.primaryColor,
                  //       ),
                  //       label: Text(
                  //         '키워드 설정',
                  //         style: GoogleFonts.notoSansKr(
                  //           fontSize: 14,
                  //           fontWeight: FontWeight.w400,
                  //           color: MyApp.primaryColor,
                  //         ),
                  //       ),
                  //       style: TextButton.styleFrom(
                  //         padding: const EdgeInsets.symmetric(
                  //           horizontal: 12,
                  //           vertical: 8,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
            // 섹션 제목
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: MyApp.secondaryColor,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSectionIcon(),
                    color: MyApp.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.pageTitle,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: MyApp.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // 공고 리스트
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notices')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '오류 발생: ${snapshot.error}',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          color: MyApp.errorColor,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        '등록된 공고가 없습니다.\n크롤러를 실행해주세요.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(
                          color: MyApp.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  // 소스 필터링 (클라이언트 측에서)
                  final sourceFilteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final source = data['source'] ?? 'LH';
                    return source == widget.source;
                  }).toList();

                  // 날짜로 정렬 (클라이언트 측에서)
                  sourceFilteredDocs.sort((a, b) {
                    final dateA =
                        (a.data() as Map<String, dynamic>)['date'] ?? '';
                    final dateB =
                        (b.data() as Map<String, dynamic>)['date'] ?? '';
                    return dateB.compareTo(dateA); // 내림차순
                  });

                  // 숨김 아이템 필터링
                  final visibleDocs = sourceFilteredDocs.where((doc) {
                    return !_hiddenItemIds.contains(doc.id);
                  }).toList();

                  // 키워드 및 검색 필터링
                  final filteredDocs = visibleDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? '';
                    // return _matchesKeywords(title) && _matchesSearch(title);
                    return _matchesSearch(title);
                  }).toList();

                  if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
                    String message = '';
                    // if (_isFilterToggleOn && _searchQuery.isNotEmpty) {
                    //   message = '키워드와 검색어에 일치하는 공고가 없습니다.';
                    // } else if (_isFilterToggleOn) {
                    //   message = '등록된 키워드와 일치하는 공고가 없습니다.';
                    // } else if (_searchQuery.isNotEmpty) {
                    message = '"$_searchQuery" 검색 결과가 없습니다.';
                    // }

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
                            style: GoogleFonts.notoSansKr(
                              color: MyApp.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          // if (_isFilterToggleOn) ...[
                          //   const SizedBox(height: 8),
                          //   TextButton(
                          //     onPressed: _openKeywordSettings,
                          //     child: const Text('키워드 설정하기'),
                          //   ),
                          // ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data['title'] ?? '제목 없음';
                      String date = data['date'] ?? '날짜 없음';
                      final link = data['link'] ?? '';

                      // 날짜가 없으면 created_at에서 추출
                      if (date == '날짜 없음' || date.isEmpty) {
                        final createdAt = data['created_at'];
                        if (createdAt != null) {
                          try {
                            // Timestamp 객체인 경우
                            DateTime dateTime;
                            if (createdAt is Timestamp) {
                              dateTime = createdAt.toDate();
                            } else if (createdAt is Map) {
                              // Firestore에서 가져온 경우
                              final seconds =
                                  createdAt['_seconds'] ?? createdAt['seconds'];
                              if (seconds != null) {
                                dateTime = DateTime.fromMillisecondsSinceEpoch(
                                    seconds * 1000);
                              } else {
                                dateTime = DateTime.now();
                              }
                            } else {
                              dateTime = DateTime.now();
                            }
                            // YYYY-MM-DD 형식으로 변환
                            date =
                                '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
                          } catch (e) {
                            // 변환 실패 시 그대로 유지
                            date = '날짜 없음';
                          }
                        }
                      }

                      return Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: MyApp.errorColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        onDismissed: (direction) {
                          _hideItem(doc.id);
                        },
                        child: Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          color: MyApp.surfaceColor,
                          child: InkWell(
                            onTap: () {
                              if (link.isNotEmpty) {
                                _launchURL(link);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: MyApp.surfaceColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 섹션 제목과 날짜 배지 (같은 줄, 양쪽 정렬)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // 섹션 제목 배지
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: MyApp.secondaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.grey
                                                    .withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              widget.pageTitle,
                                              style: GoogleFonts.notoSansKr(
                                                color: MyApp.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // 날짜 배지
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: MyApp.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: MyApp.primaryColor
                                                    .withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            date,
                                            style: GoogleFonts.notoSansKr(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // 제목
                                    Text(
                                      title,
                                      style: GoogleFonts.notoSansKr(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        height: 1.5,
                                        color: MyApp.textPrimary,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 16),
                                    // 자세히 보기 버튼
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.shade100,
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (link.isNotEmpty) {
                                              _launchURL(link);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: MyApp.primaryColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '자세히 보기',
                                                style: GoogleFonts.notoSansKr(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
      ),
    );
  }
}

