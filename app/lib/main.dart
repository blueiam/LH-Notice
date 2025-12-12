import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DB 사용
import 'package:url_launcher/url_launcher.dart'; // 링크 열기 사용

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 알림 권한 및 구독
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  await FirebaseMessaging.instance.subscribeToTopic("lh_notice");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LH 공고 알리미',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const NoticeListScreen(),
    );
  }
}

class NoticeListScreen extends StatelessWidget {
  const NoticeListScreen({super.key});

  // 링크 여는 함수
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LH 공고 리스트'),
        centerTitle: true,
        elevation: 2,
      ),
      // StreamBuilder: DB가 바뀌면 화면도 자동으로 바뀜!
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .orderBy('date', descending: true) // 최신 날짜순 정렬
            .snapshots(),
        builder: (context, snapshot) {
          // 1. 데이터 가져오는 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. 에러 났을 때
          if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          }

          // 3. 데이터가 없을 때
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '저장된 공고가 없습니다.\n크롤러를 실행해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // 4. 데이터가 있을 때 리스트 만들기
          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? '제목 없음';
              final date = data['date'] ?? '날짜 없음';
              final link = data['link'] ?? '';

              return ListTile(
                leading: const Icon(Icons.article_outlined, color: Colors.blue),
                title: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  date,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (link.isNotEmpty) {
                    _launchURL(link);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
