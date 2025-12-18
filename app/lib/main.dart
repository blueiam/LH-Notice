import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'notice_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공모 알림',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'source': 'LH',
      'title': 'LH 공모안내',
      'icon': Icons.home,
    },
    {
      'source': 'KAMS',
      'title': '예술경영지원센터',
      'icon': Icons.palette,
    },
    {
      'source': 'Seoul',
      'title': '서울특별시',
      'icon': Icons.location_city,
    },
    {
      'source': 'SeoulPublicArt',
      'title': '서울 공공미술 공모',
      'icon': Icons.brush,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '공모 알림',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false, // 왼쪽 햄버거 아이콘 제거
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '공모 알림',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '다양한 공모 정보를 한 곳에서',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ..._pages.asMap().entries.map((entry) {
              final index = entry.key;
              final page = entry.value;
              final isSelected = _currentIndex == index;

              return ListTile(
                leading: Icon(
                  page['icon'],
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
                title: Text(
                  page['title'],
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black,
                  ),
                ),
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('앱 정보'),
              subtitle: Text('버전 1.0.0'),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages.map((page) {
          return NoticeListPage(
            source: page['source'],
            pageTitle: page['title'],
          );
        }).toList(),
      ),
    );
  }
}
